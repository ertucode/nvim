return {
	{
		"nvim-treesitter/playground",
		cmd = "TSPlaygroundToggle",
	},

	{
		"kana/vim-textobj-entire",
		event = "BufRead",
		dependencies = { "kana/vim-textobj-user" },
	},
	{
		-- Enable when the trial ends. Clear device id and stuff. ~/Library/Preferences/com.apple.java.util.prefs.plist
		-- Or try removing the file
		-- https://gist.github.com/XGilmar/55f6727a40f78979a6a7f8d5885e3bdd?permalink_comment_id=5057636
		"darfink/vim-plist",
		enabled = false,
	},
}
