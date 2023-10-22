return function(prop_name)
	local query_tail = string.format(
		[[
    (decorator
        (call_expression
            (arguments
                (object
                    (pair
                        key: (property_identifier) @prop_name (#eq? @prop_name "%s")
                        value: (array) @value
                    )
                )
            )
        )
    )
]],
		prop_name
	)
	local query = vim.treesitter.query.parse(
		"typescript",

		string.format(
			[[
[
(
  class_declaration
    %s
)
(
  export_statement
    %s
)
]
    ]],
			query_tail,
			query_tail
		)
	)

	local get_root = function(bufnr)
		local parser = vim.treesitter.get_parser(bufnr, "typescript", {})
		local tree = parser:parse()[1]
		return tree:root()
	end

	return function()
		local root = get_root(0)

		local found = {}

		for id, node in query:iter_captures(root, 0, 0, -1) do
			if query.captures[id] == "value" then
				table.insert(found, node)
			end
		end

		local use = function(node)
			local row1, col1, row2, col2 = node:range() -- range of the capture
			local on_same_line = row1 == row2

			print()

			if on_same_line then
				vim.api.nvim_win_set_cursor(0, { row2 + 1, col2 - 1 })
				vim.cmd("startinsert")
				if node:child_count() ~= 2 then
					vim.api.nvim_input(", ")
				end
			else
				local line = vim.api.nvim_buf_get_lines(0, row2 - 1, row2 - 0, false)[1]
				local fill = string.sub(line, 0, string.find(line, "[^%s]", 0) - 1) .. " "
				vim.api.nvim_buf_set_lines(0, row2, row2, false, { fill })

				vim.api.nvim_win_set_cursor(0, { row2 + 1, #fill or 0 })
				vim.cmd("startinsert")
			end
		end

		if #found == 0 then
			-- insert
			return
		end

		if #found == 1 then
			use(found[1])
			return
		end

		local closest = nil
		local min = 1000000
		local cur_pos = vim.api.nvim_win_get_cursor(0)[1]
		for _, node in ipairs(found) do
			local row1, _, _, _ = node:range() -- range of the capture
			local dist = math.abs(row1 - cur_pos)
			if dist < min then
				min = dist
				closest = node
			end
		end

		if not closest == nil then
			use(closest)
		end
	end
end
