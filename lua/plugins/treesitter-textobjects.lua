return {
	"nvim-treesitter/nvim-treesitter-textobjects",
	config = function()
		require("nvim-treesitter.configs").setup({
			textobjects = {
				select = {
					enable = true,
					lookahead = true,
					keymaps = {
						["af"] = "@function.outer",
						["if"] = "@function.inner",
						["aj"] = "@parameter.outer",
						["ij"] = "@parameter.inner",
						["aa"] = "@attribute.outer",
						["ia"] = "@attribute.inner",
						["ac"] = "@class.outer",
						["ic"] = "@class.inner",
						["ak"] = "@call.outer",
						["ik"] = "@call.inner",
						["in"] = "@assignment.rhs",
						["iv"] = "@assignment.lhs",
						-- You can also use captures from other query groups like `locals.scm`
						["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
					},
					-- You can choose the select mode (default is charwise 'v')
					--
					-- Can also be a function which gets passed a table with the keys
					-- * query_string: eg '@function.inner'
					-- * method: eg 'v' or 'o'
					-- and should return the mode ('v', 'V', or '<c-v>') or a table
					-- mapping query_strings to modes.
					-- selection_modes = {
					-- 	["@parameter.outer"] = "v", -- charwise
					-- 	["@function.outer"] = "V", -- linewise
					-- 	["@class.outer"] = "<c-v>", -- blockwise
					-- },
					-- If you set this to `true` (default is `false`) then any textobject is
					-- extended to include preceding or succeeding whitespace. Succeeding
					-- whitespace has priority in order to act similarly to eg the built-in
					-- `ap`.
					--
					-- Can also be a function which gets passed a table with the keys
					-- * query_string: eg '@function.inner'
					-- * selection_mode: eg 'v'
					-- and should return true of false
					include_surrounding_whitespace = true,
				},
				-- swap = {
				-- 	enable = true,
				-- 	swap_next = {
				-- 		["<leader>a"] = "@parameter.inner",
				-- 	},
				-- 	swap_previous = {
				-- 		["<leader>A"] = "@parameter.inner",
				-- 	},
				-- },
				move = {
					enable = true,
					set_jumps = false,
					goto_next_start = {
						-- ["]f"] = "@function.outer",
						["]a"] = "@attribute.outer",
						["]o"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
						["]j"] = "@parameter.inner",
						--
						-- You can use regex matching (i.e. lua pattern) and/or pass a list in a "query" key to group multiple queires.
						-- ["]o"] = "@loop.*",
						-- ["]o"] = { query = { "@loop.inner", "@loop.outer" } }
						--
						-- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path.
						-- Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and indent.scm.
						-- ["]s"] = { query = "@scope", query_group = "locals", desc = "Next scope" }, -- Didnt work
					},
					goto_next_end = {
						["]F"] = "@function.outer",
						["]A"] = "@attribute.outer",
						["]O"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
						["]J"] = "@parameter.inner",
					},
					goto_previous_start = {
						-- ["[f"] = "@function.outer",
						["[a"] = "@attribute.outer",
						["[o"] = { query = "@fold", query_group = "folds", desc = "Previous fold" },
						["[j"] = "@parameter.inner",
					},
					goto_previous_end = {
						["[F"] = "@function.outer",
						["[A"] = "@attribute.outer",
						["[O"] = { query = "@fold", query_group = "folds", desc = "Previous fold" },
						["[J"] = "@parameter.inner",
					},
					goto_next = {
						["]]"] = "@class.outer",
					},
					goto_previous = {
						["[["] = "@class.outer",
					},
				},
			},
		})

		local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")

		-- Repeat movement with ; and ,
		-- ensure ; goes forward and , goes backward regardless of the last direction
		vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next)
		vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous)

		vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
		vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
		vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
		vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })
	end,
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
	},
}
