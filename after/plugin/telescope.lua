local status, telescope = pcall(require, "telescope")

if not status then
	return
end

local actions = require("telescope.actions")

telescope.setup({
	defaults = {
		path_display = { "truncate" },
		mappings = {
			i = {
				["<C-j>"] = actions.cycle_history_next,
				["<C-k>"] = actions.cycle_history_next,
			},
		},
		layout_config = {
			height = 0.95,
			width = 0.9,
		},
	},
})

local builtin = require("telescope.builtin")

require("telescope").load_extension("fzf")

local function set(mapping, fn, desc)
	vim.keymap.set("n", mapping, fn, { desc = desc })
end

set("<leader>frp", builtin.resume, "[F]ind [R]e[P]eat")

local themes = require("telescope.themes")
set("<leader>ff", builtin.find_files, "[F]ind [F]iles")

set("<leader>fs", builtin.live_grep, "[F]ind [S]tring")
set("<leader>fcw", builtin.grep_string, "[F]ind [C]urrent [W]ord")
set("<leader>fb", builtin.buffers, "[F]ind [B]uffers")

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

local entry_maker = require("utils.telescope-filename").find_files_entry_maker

set("<C-p>", function()
	local opts = {
		entry_maker = entry_maker(),
		sorting_strategy = "ascending",
		layout_strategy = "center",
		border = true,
		borderchars = {
			prompt = { "─", "│", " ", "│", "╭", "╮", "│", "│" },
			results = { "─", "│", "─", "│", "├", "┤", "╯", "╰" },
			preview = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
		},
		layout_config = {
			width = 0.8,
			height = 0.6,
		},
		results_title = false,
		previewer = false,
	}

	opts.show_untracked = true

	local succ = pcall(builtin.git_files, opts)

	if not succ then
		builtin.find_files(opts)
	end
end, "[F]ind [G]itfiles, or [F]ind [F]iles")
