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
