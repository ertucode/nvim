return {
	"nvim-treesitter/nvim-treesitter-textobjects",
	branch = "main",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
	},
	config = function()
		require("nvim-treesitter-textobjects").setup({
			select = {
				lookahead = true,
				include_surrounding_whitespace = true,
			},
			move = {
				set_jumps = false,
			},
		})

		local select = require("nvim-treesitter-textobjects.select")
		local select_maps = {
			af = "@function.outer",
			["if"] = "@function.inner",
			aj = "@parameter.outer",
			ij = "@parameter.inner",
			aa = "@attribute.outer",
			ia = "@attribute.inner",
			ac = "@class.outer",
			ic = "@class.inner",
			ak = "@call.outer",
			ik = "@call.inner",
			["in"] = "@assignment.rhs",
			iv = "@assignment.lhs",
		}

		for lhs, query in pairs(select_maps) do
			local query_string = query
			vim.keymap.set({ "x", "o" }, lhs, function()
				select.select_textobject(query_string, "textobjects")
			end, { desc = "Select " .. query_string })
		end

		vim.keymap.set({ "x", "o" }, "as", function()
			select.select_textobject("@local.scope", "locals")
		end, { desc = "Select language scope" })

		local move = require("nvim-treesitter-textobjects.move")
		local move_maps = {
			goto_next_start = {
				["]f"] = { "@function.outer", "textobjects" },
				["]a"] = { "@attribute.outer", "textobjects" },
				["]o"] = { "@fold", "folds" },
				["]j"] = { "@parameter.inner", "textobjects" },
			},
			goto_next_end = {
				["]F"] = { "@function.outer", "textobjects" },
				["]A"] = { "@attribute.outer", "textobjects" },
				["]O"] = { "@fold", "folds" },
				["]J"] = { "@parameter.inner", "textobjects" },
			},
			goto_previous_start = {
				["[f"] = { "@function.outer", "textobjects" },
				["[a"] = { "@attribute.outer", "textobjects" },
				["[o"] = { "@fold", "folds" },
				["[j"] = { "@parameter.inner", "textobjects" },
			},
			goto_previous_end = {
				["[F"] = { "@function.outer", "textobjects" },
				["[A"] = { "@attribute.outer", "textobjects" },
				["[O"] = { "@fold", "folds" },
				["[J"] = { "@parameter.inner", "textobjects" },
			},
		}

		for method, mappings in pairs(move_maps) do
			local move_method = method
			for lhs, target in pairs(mappings) do
				local query, query_group = target[1], target[2]
				vim.keymap.set({ "n", "x", "o" }, lhs, function()
					move[move_method](query, query_group)
				end, { desc = move_method .. " " .. query })
			end
		end

		local repeat_move = require("nvim-treesitter-textobjects.repeatable_move")
		vim.keymap.set({ "n", "x", "o" }, ";", repeat_move.repeat_last_move_next)
		vim.keymap.set({ "n", "x", "o" }, ",", repeat_move.repeat_last_move_previous)
		vim.keymap.set({ "n", "x", "o" }, "f", repeat_move.builtin_f_expr, { expr = true })
		vim.keymap.set({ "n", "x", "o" }, "F", repeat_move.builtin_F_expr, { expr = true })
		vim.keymap.set({ "n", "x", "o" }, "t", repeat_move.builtin_t_expr, { expr = true })
		vim.keymap.set({ "n", "x", "o" }, "T", repeat_move.builtin_T_expr, { expr = true })
	end,
}
