return {
	"stevearc/oil.nvim",
	lazy = false,
	priority = 100000,
	-- tag = "v2.2.0",
	config = function()
		local status, oil = pcall(require, "oil")

		if not status then
			return
		end

		oil.setup({
			skip_confirm_for_simple_edits = true,
			-- lsp_file_methods = {
			-- 	enabled = true,
			-- },
			keymaps = {
				["<C-p>"] = false,
				["<C-s>"] = false,
			},
			watch_for_changes = true,
			lsp_file_methods = {
				autosave_changes = "unmodified",
			},
			view_options = {
				is_hidden_file = function(name, _)
					local m = name:match("^%.")
					if m == nil then
						return false
					end
					if vim.startswith(name, ".env") then
						return false
					end
					return true
				end,
			},
		})

		vim.keymap.set("n", "-", require("oil").open, { desc = "Open parent directory" })

		local augroup = vim.api.nvim_create_augroup("myoil", { clear = true })
		vim.api.nvim_create_autocmd("User", {
			pattern = "OilActionsPost",
			group = augroup,
			callback = function(e)
				if e.data.actions == nil then
					return
				end
				for _, action in ipairs(e.data.actions) do
					if action.entry_type == "file" and action.type == "delete" then
						local file = action.url:sub(7)
						local bufnr = vim.fn.bufnr(file)

						if bufnr >= 0 then
							vim.api.nvim_buf_delete(bufnr, { force = true })
						end
					end
				end
			end,
		})
	end,
}

-- return {
--   'echasnovski/mini.files', version = false,
--   config = function()
--     local mini = require('mini.files')
--     mini.setup({
--       mappings = {
--         go_in_plus  = '<CR>',
--         go_in       = '<C-l>',
--         go_out      = '<C-h>',
--       },
--     })
--
--     vim.keymap.set("n", "-", function ()
--       -- mini.open()
--       mini.open(vim.api.nvim_buf_get_name(0))
--     end, { desc = "Open parent directory" })
--
--     vim.api.nvim_create_autocmd("User", {
--       pattern = "TelescopeFindPre",
--       callback = function()
--         local ok, mini_files = pcall(require, "mini.files")
--         if ok then
--           mini_files.close()
--         end
--       end
--     })
--   end,
-- }
