require("telescope").setup({
	defaults = {
		path_display = { "truncate" },
	},
})

local builtin = require("telescope.builtin")

require("telescope").load_extension("fzf")

local function set(mapping, fn, desc)
	vim.keymap.set("n", mapping, fn, { desc = desc })
end

set("<leader>frp", builtin.resume, "[F]ind [R]e[P]eat")

set("<leader>ff", builtin.find_files, "[F]ind [F]iles")

set("<leader>fs", builtin.live_grep, "[F]ind [S]tring")
set("<leader>fcw", builtin.grep_string, "[F]ind [C]urrent [W]ord")
set("<leader>fbs", builtin.current_buffer_fuzzy_find, "[F]ind [B]uffer [S]tring")

set("<C-p>", function()
	local succ = pcall(builtin.git_files, { show_untracked = true })

	if not succ then
		builtin.find_files()
	end
end, "[F]ind [G]itfiles, or [F]ind [F]iles")

set("<leader>fd", builtin.diagnostics, "[F]ind [D]iagnostics")
set("<leader>fh", builtin.help_tags, "[F]ind [H]elp")
set("<leader>ft", builtin.builtin, "[F]ind [T]elescope")
set("<leader>fk", builtin.keymaps, "[F]ind [K]eymap")

set("<leader>fgb", builtin.git_branches, "[F]ind [G]it [B]ranches")
set("<leader>fgs", builtin.git_status, "[F]ind [G]it [S]tatus")
set("<leader>fcm", builtin.commands, "[F]ind [C]o[M]mands")
set("<leader>fch", builtin.command_history, "[F]ind [C]ommand [H]istory")
set("<leader>frs", builtin.registers, "[F]ind [R]egistered [S]trings")

set("<leader>flr", builtin.lsp_references, "[F]ind [L]sp [R]eferences")
set("<leader>fli", builtin.lsp_implementations, "[F]ind [L]sp [I]mplementations")
set("<leader>fld", builtin.lsp_document_symbols, "[F]ind [L]sp [D]ocument Symbols")
set("<leader>flw", builtin.lsp_workspace_symbols, "[F]ind [L]sp [W]orkspace Symbols")
set("<leader>fac", builtin.autocommands, "[F]ind [A]uto [C]ommands")
