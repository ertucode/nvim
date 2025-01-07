local M = {}

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local plugins = require("ertu.utils.array").map(require("lazy").plugins(), function(tbl)
	return tbl.name
end)

local last_reloaded = ""

M.reload_plugin = function()
	pickers
		.new({}, {
			prompt_title = "Plugins",
			finder = finders.new_table({
				results = plugins,
			}),
			sorter = conf.generic_sorter({}),

			attach_mappings = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					last_reloaded = selection[1]
					vim.cmd("Lazy reload " .. selection[1])
				end)
				return true
			end,
		})
		:find()
end

M.reload_last_plugin = function()
	vim.cmd("Lazy reload " .. last_reloaded)
end

return M
