local status, comment = pcall(require, "Comment")

if not status then
	return
end

comment.setup({
	opleader = {
		line = "gc",
		block = "gb",
	},
	mappings = {
		-- gcc line comment
		-- gcb block comment
		-- gc[count][motion] line comment region contained in motion
		-- gb[count][motion] block comment region contained in motion
		basic = true,
		-- gco, gcO, gcA
		extra = true,
	},
	toggler = {
		line = "gcc",
		block = "gbc",
	},
})
