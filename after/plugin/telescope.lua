local builtin = require("telescope.builtin")

local function set(mapping, fn, desc)
	vim.keymap.set("n", mapping, fn, { desc = desc })
end

set("<leader>ff", builtin.find_files, "[F]ind [F]iles")

set("<leader>fs", function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") })
end, "[F]ind [S]tring")

set("<C-p>", function()
	builtin.git_files({ show_untracked = true })
end, "Find gitfiles")

set("<leader>fd", builtin.diagnostics, "[F]ind [D]iagnostics")
set("<leader>fh", builtin.help_tags, "[F]ind [H]elp")
set("<leader>ft", builtin.builtin, "[F]ind [T]elescope")
set("<leader>fk", builtin.keymaps, "[F]ind [K]eymap")
