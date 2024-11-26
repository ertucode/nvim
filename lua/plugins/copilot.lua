return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	build = ":Copilot auth",
	event = "InsertEnter",
	enabled = false,
	config = function()
		require("copilot").setup({
			panel = {
				enabled = false,
			},
			suggestion = {
				enabled = true,
				auto_trigger = true,
				auto_refresh = true,
				debounce = 75,
				keymap = {
					accept = "<M-l>",
					dismiss = "<M-;>",
					accept_word = false,
					accept_line = false,
					next = "<M-o>",
					prev = "<M-i>",
				},
			},
			filetypes = {
				markdown = true,
			},
			copilot_node_command = "node", -- Node.js version must be > 18.x
			server_opts_overrides = {},
		})
	end,
}
