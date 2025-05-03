---@class OutputBuffer
---@field buf number
---@field win number
---@field ns_id number
OutputBuffer = {}
OutputBuffer.__index = OutputBuffer

function OutputBuffer:new(buf_name)
	local buf = vim.api.nvim_create_buf(false, true)
	local buffer_name = "[" .. buf_name .. "]"
	if vim.fn.bufexists(buffer_name) == 1 then
		vim.api.nvim_buf_delete(vim.fn.bufnr(buffer_name), { force = true })
	end

	vim.api.nvim_buf_set_name(buf, buffer_name)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "modifiable", true)

	-- Create a window to display the buffer
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = math.floor(vim.o.columns * 0.4),
		height = math.floor(vim.o.lines * 0.3),
		row = math.floor(vim.o.lines * 0.2),
		col = math.floor(vim.o.columns * 0.3),
		style = "minimal",
		border = "single",
	})

	-- Set window options
	vim.api.nvim_win_set_option(win, "wrap", true)
	vim.api.nvim_win_set_option(win, "cursorline", true)

	-- Set up syntax highlighting
	vim.api.nvim_buf_set_option(buf, "filetype", "git")

	-- Define custom highlight groups if they don't exist
	local function ensure_highlight(name, attributes)
		if vim.fn.hlexists(name) == 0 then
			vim.api.nvim_set_hl(0, name, attributes)
		end
	end

	ensure_highlight("GitOutputError", { fg = "#CC5555", bold = true })
	ensure_highlight("GitOutputWarning", { fg = "#FFCC00" })
	ensure_highlight("GitOutputSuccess", { fg = "#50FA7B", bold = true })
	ensure_highlight("GitOutputHeader", { fg = "#BD93F9", bold = true })
	ensure_highlight("GitOutputCommand", { fg = "#8BE9FD", italic = true })
	ensure_highlight("GitOutputInfo", { fg = "#8BA0FD", italic = true })

	-- Initialize namespace for highlighting
	local ns_id = vim.api.nvim_create_namespace("git_output")

	local instance = setmetatable({}, OutputBuffer)
	instance.buf = buf
	instance.win = win
	instance.ns_id = ns_id
	return instance
end

-- Helper function to highlight a line
function OutputBuffer:highlight_line(line_num, highlight_group)
	vim.api.nvim_buf_add_highlight(self.buf, self.ns_id, highlight_group, line_num, 0, -1)
end

function OutputBuffer:append(lines, highlight_group)
	if type(lines) == "string" then
		lines = { lines }
	end

	-- Filter out empty lines that come from jobstart
	local filtered = {}
	for _, line in ipairs(lines) do
		if line and line ~= "" then
			table.insert(filtered, line)
		end
	end

	if #filtered > 0 then
		vim.schedule(function()
			if vim.api.nvim_buf_is_valid(self.buf) then
				local line_count = vim.api.nvim_buf_line_count(self.buf)
				vim.api.nvim_buf_set_option(self.buf, "modifiable", true)
				vim.api.nvim_buf_set_lines(self.buf, line_count, line_count, false, filtered)

				-- Apply highlighting if specified
				if highlight_group then
					for i = 0, #filtered - 1 do
						self:highlight_line(line_count + i, highlight_group)
					end
				else
					-- Auto-detect errors and warnings
					for i = 0, #filtered - 1 do
						local line = filtered[i + 1]:lower()
						if line:match("error") or line:match("fatal") or line:match("failed") then
							self:highlight_line(line_count + i, "GitOutputError")
						elseif line:match("warning") or line:match("warn") then
							self:highlight_line(line_count + i, "GitOutputWarning")
						end
					end
				end

				vim.api.nvim_buf_set_option(self.buf, "modifiable", false)

				-- Scroll to the bottom if window is still valid
				if vim.api.nvim_win_is_valid(self.win) then
					vim.api.nvim_win_set_cursor(self.win, { line_count + #filtered, 0 })
				end
			end
		end)
	end
end

function OutputBuffer:append_error(lines)
	self:append(lines, "GitOutputError")
end

function OutputBuffer:append_warning(lines)
	self:append(lines, "GitOutputWarning")
end

function OutputBuffer:append_success(lines)
	self:append(lines, "GitOutputSuccess")
end

function OutputBuffer:append_header(lines)
	self:append(lines, "GitOutputHeader")
end

function OutputBuffer:append_command(lines)
	self:append(lines, "GitOutputCommand")
end

function OutputBuffer:append_info(lines)
	self:append(lines, "GitOutputInfo")
end

function OutputBuffer:stdout_handler()
	return function(_, data)
		if data then
			self:append_info(data)
		end
	end
end

function OutputBuffer:stderr_handler()
	return function(_, data)
		if data then
			self:append_error(data)
		end
	end
end

function OutputBuffer:finish(success)
	vim.schedule(function()
		-- Add a status line at the end
		local status = success and "✓ Completed successfully" or "✗ Failed"
		local highlight = success and "GitOutputSuccess" or "GitOutputError"

		if vim.api.nvim_buf_is_valid(self.buf) then
			vim.api.nvim_buf_set_option(self.buf, "modifiable", true)
			local line_count = vim.api.nvim_buf_line_count(self.buf)
			vim.api.nvim_buf_set_lines(self.buf, line_count, line_count, false, { "", status })

			-- Highlight the status line
			self:highlight_line(line_count + 1, highlight)

			vim.api.nvim_buf_set_option(self.buf, "modifiable", false)

			local keys = { "q", "<CR>" }
			for _, key in ipairs(keys) do
				vim.api.nvim_buf_set_keymap(self.buf, "n", key, "<cmd>close<cr>", {
					noremap = true,
					silent = true,
					desc = "Close git output window",
				})
			end

			self:append_info("Press q or enter to exit")

			-- Set buffer options for completed output
			vim.api.nvim_buf_set_option(self.buf, "modified", false)
		end
	end)
end

return OutputBuffer
