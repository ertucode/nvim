require("ertu.remap")
require("ertu.set")
require("ertu.wsl")
require("ertu.ng-utils")

require("lazy").setup({ { import = "plugins" }, { import = "plugins.lsp" } }, {
	checker = {
		enabled = true,
		notify = false,
	},
	change_detection = {
		notify = false,
	},
})
