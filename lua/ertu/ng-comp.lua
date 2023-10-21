vim.keymap.set("n", "<leader>ngc", function()
	local folder = vim.api.nvim_buf_get_name(0):gsub("oil://", "")
	local res = vim.fn.input("Component name: ")
	local comp_folder = folder .. res

	os.execute("mkdir " .. comp_folder)

	local without_ext = comp_folder .. "/" .. res
	local ts = without_ext .. ".ts"
	local html = without_ext .. ".html"
	local scss = without_ext .. ".scss"

	os.execute("touch " .. ts .. " " .. html .. " " .. scss)

	require("oil.actions").refresh.callback()

	local ts_file = io.open(ts, "w")
	if ts_file == nil then
		print("There was a problem writing to ts file")
		return
	end

	local stringUtils = require("ertu.utils.string")
	local content = string.format(
		[[
import { CommonModule } from "@angular/common"
import { Component, Input } from "@angular/core"
import { LocalizationModule } from "@sipaywalletgate/ngx-sipay/localization"

@Component({
  selector: "%s",
  imports: [LocalizationModule, CommonModule],
  styleUrls: ["./%s.component.scss"],
  templateUrl: "./%s.component.html",
  standalone: true,
})
export class %sComponent {
  @Input() input: string

  constructor() {}
}
]],
		res,
		res,
		res,
		stringUtils.camelToCapital(res)
	)

	ts_file:write(content)
	ts_file:close()

	local html_file = io.open(html, "w")
	if html_file == nil then
		print("There was a problem writing to html file")
		return
	end

	html_file:write([[
<ng-container *localize="let t">
</ng-container>
    ]])
	html_file:close()
end)

local query_tail = [[
    (decorator
        (call_expression
            (arguments
                (object
                    (pair
                        key: (property_identifier) @imports (#eq? @imports "imports")
                        value: (array) @value
                    )
                )
            )
        )
    )
]]
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

vim.keymap.set("n", "<leader>ngi", function()
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

		if on_same_line then
			vim.api.nvim_win_set_cursor(0, { row2 + 1, col2 - 1 })
			vim.cmd("startinsert")
			vim.api.nvim_input(", ")
		else
			local line = vim.api.nvim_buf_get_lines(0, row2 - 1, row2 - 0, false)[1]
			local fill = string.sub(line, 0, string.find(line, "[^%s]", 0) - 1) .. " "
			vim.api.nvim_buf_set_lines(0, row2, row2, false, { fill })

			vim.api.nvim_win_set_cursor(0, { row2 + 1, #fill or 0 })
			vim.cmd("startinsert")
		end
	end

	if #found == 0 then
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
end)
