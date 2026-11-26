local parsers = {
	"bash",
	"c",
	"cpp",
	"css",
	"diff",
	"dockerfile",
	"git_config",
	"gitcommit",
	"gitignore",
	"html",
	"idl",
	"ini",
	"java",
	"javascript",
	"json",
	"lua",
	"make",
	"markdown",
	"matlab",
	"objc",
	"php",
	"python",
	"query",
	"rust",
	"ssh_config",
	"swift",
	"toml",
	"tsx",
	"typescript",
	"vim",
	"vimdoc",
	"vue",
	"xml",
	"yaml",
	"zig",
}

return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		local treesitter = require("nvim-treesitter")

		treesitter.setup({})
		treesitter.install(parsers)

		vim.keymap.set({ "n", "x" }, "<C-Space>", function()
			vim.treesitter.select("parent", vim.v.count1)
		end, { desc = "Expand Tree-sitter selection" })

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
			pattern = "*",
			callback = function(args)
				local ok = pcall(vim.treesitter.start, args.buf)
				if ok then
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
}
