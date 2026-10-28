local mp = require("mp")
local utils = require("mp.utils")

local state_dir = os.getenv("HOME") .. "/.local/state/mpv"
local history_path = state_dir .. "/recent-files.txt"
local playlist_history_path = state_dir .. "/recent-playlists.json"

mp.command_native({
	name = "subprocess",
	args = { "mkdir", "-p", state_dir },
	playback_only = false,
})

local max_entries = 20
local visible_entries = 10
local osd_width = 1280
local osd_height = 720
local row_x = 180
local row_y = 132
local row_width = 920
local row_height = 50
local entries = {}
local selected = 1
local menu_visible = false
local menu_overlay = mp.create_osd_overlay("ass-events")
menu_overlay.res_x = osd_width
menu_overlay.res_y = osd_height

local function escape_ass(text)
	return text:gsub("\\", "\\e"):gsub("{", "\\{"):gsub("}", "\\}")
end

local function display_name(path)
	local name = path:match("([^/\\]+)$")
	return name or path
end

local function display_location(path)
	return path:match("^(.*)[/\\][^/\\]+$") or path
end

local function truncate(text, length)
	if #text <= length then
		return text
	end
	return "…" .. text:sub(-(length - 1))
end

local function rectangle(x, y, width, height, color, alpha)
	return string.format(
		"{\\an7\\pos(0,0)\\bord0\\shad0\\1c&H%s&\\1a&H%s&\\p1}m %d %d l %d %d l %d %d l %d %d{\\p0}",
		color,
		alpha,
		x,
		y,
		x + width,
		y,
		x + width,
		y + height,
		x,
		y + height
	)
end

local function normalize_path(path)
	if not path or path == "" then
		return nil
	end
	if path:match("^%a[%w+.-]*://") or path:match("^[/\\]") then
		return path
	end

	local working_directory = mp.get_property("working-directory")
	if working_directory and working_directory ~= "" then
		return working_directory .. "/" .. path
	end
	return path
end

local function read_history()
	entries = {}
	local file = io.open(history_path, "r")
	if not file then
		return
	end

	for line in file:lines() do
		if line ~= "" then
			entries[#entries + 1] = line
		end
	end
	file:close()
end

local function write_history()
	local file = io.open(history_path, "w")
	if not file then
		mp.msg.warn("Could not write recent-files history: " .. history_path)
		return
	end

	for _, path in ipairs(entries) do
		file:write(path, "\n")
	end
	file:close()
end

local function read_playlist_history()
	local file = io.open(playlist_history_path, "r")
	if not file then
		return {}
	end

	local contents = file:read("*a")
	file:close()
	local parsed = utils.parse_json(contents)
	return type(parsed) == "table" and parsed or {}
end

local function write_playlist_history(playlists)
	local file = io.open(playlist_history_path, "w")
	if not file then
		mp.msg.warn("Could not write recent playlist history: " .. playlist_history_path)
		return
	end
	file:write(utils.format_json(playlists))
	file:close()
end

local function render_menu()
	if not menu_visible then
		return
	end

	local parts = {
		rectangle(0, 0, osd_width, osd_height, "101010", "00"),
		"{\\an7\\pos(180,68)\\fs32\\b1\\1c&HFFFFFF&}Continue watching",
		"{\\an7\\pos(180,105)\\fs16\\b0\\1c&H999999&}Recently opened files",
	}

	if #entries == 0 then
		parts[#parts + 1] = "{\\an5\\pos(640,350)\\fs22\\1c&HAAAAAA&}No recently opened files yet"
		parts[#parts + 1] = "{\\an5\\pos(640,385)\\fs16\\1c&H777777&}Files you play will appear here"
	else
		local last = math.min(#entries, visible_entries)
		for index = 1, last do
			local y = row_y + (index - 1) * row_height
			local selected_row = index == selected
			local background = selected_row and "52351F" or "282828"
			local alpha = selected_row and "00" or "18"
			local title_color = selected_row and "FFFFFF" or "E6E6E6"
			local path_color = selected_row and "DCC5A8" or "999999"
			local path = entries[index]

			parts[#parts + 1] = rectangle(row_x, y, row_width, row_height - 5, background, alpha)
			parts[#parts + 1] = string.format(
				"{\\an7\\pos(%d,%d)\\fs20\\b1\\1c&H%s&}%s",
				row_x + 17,
				y + 5,
				title_color,
				escape_ass(truncate(display_name(path), 70))
			)
			parts[#parts + 1] = string.format(
				"{\\an7\\pos(%d,%d)\\fs13\\b0\\1c&H%s&}%s",
				row_x + 17,
				y + 28,
				path_color,
				escape_ass(truncate(display_location(path), 105))
			)
		end
		parts[#parts + 1] =
			"{\\an7\\pos(180,651)\\fs15\\1c&H888888&}Click to open   •   ↑/↓ select   •   Enter open   •   Esc close"
	end

	-- Each line is a separate ASS dialogue event. This is required because
	-- ASS permits only one absolute position per event.
	menu_overlay.data = table.concat(parts, "\n")
	menu_overlay:update()
end

local function hide_menu()
	if not menu_visible then
		return
	end

	menu_visible = false
	menu_overlay:remove()
	mp.remove_key_binding("recent-files-up")
	mp.remove_key_binding("recent-files-down")
	mp.remove_key_binding("recent-files-open")
	mp.remove_key_binding("recent-files-close")
	mp.remove_key_binding("recent-files-click")
end

local function move_selection(amount)
	if #entries == 0 then
		return
	end
	selected = ((selected - 1 + amount) % math.min(#entries, visible_entries)) + 1
	render_menu()
end

local function open_selected()
	local path = entries[selected]
	if not path then
		return
	end

	hide_menu()
	local saved = read_playlist_history()[path]
	if not saved or type(saved.items) ~= "table" or #saved.items < 2 then
		mp.commandv("loadfile", path, "replace")
		return
	end

	for index, item in ipairs(saved.items) do
		mp.commandv("loadfile", item, index == 1 and "replace" or "append")
	end
	local playlist_index = math.max(0, math.min(#saved.items - 1, (saved.current or 1) - 1))
	mp.set_property_number("playlist-pos", playlist_index)
end

local function clicked_entry()
	local mouse = mp.get_property_native("mouse-pos")
	local dimensions = mp.get_property_native("osd-dimensions")
	if
		not mouse
		or not dimensions
		or not dimensions.w
		or not dimensions.h
		or dimensions.w == 0
		or dimensions.h == 0
	then
		return nil
	end

	local x = mouse.x * osd_width / dimensions.w
	local y = mouse.y * osd_height / dimensions.h
	if x < row_x or x > row_x + row_width or y < row_y then
		return nil
	end

	local index = math.floor((y - row_y) / row_height) + 1
	if index < 1 or index > math.min(#entries, visible_entries) then
		return nil
	end
	if y > row_y + (index - 1) * row_height + row_height - 5 then
		return nil
	end
	return index
end

local function open_clicked()
	local index = clicked_entry()
	if not index then
		return
	end
	selected = index
	open_selected()
end

local function show_menu()
	if menu_visible then
		return
	end

	read_history()
	selected = 1
	menu_visible = true
	mp.add_forced_key_binding("UP", "recent-files-up", function()
		move_selection(-1)
	end)
	mp.add_forced_key_binding("DOWN", "recent-files-down", function()
		move_selection(1)
	end)
	mp.add_forced_key_binding("ENTER", "recent-files-open", open_selected)
	mp.add_forced_key_binding("ESC", "recent-files-close", hide_menu)
	mp.add_forced_key_binding("MBTN_LEFT", "recent-files-click", open_clicked)
	render_menu()
end

mp.add_forced_key_binding("Ctrl+r", "recent-files-toggle", function()
	if menu_visible then
		hide_menu()
	else
		show_menu()
	end
end)

local function remember_current_file()
	local path = normalize_path(mp.get_property("path"))
	if not path then
		return
	end

	read_history()
	for index = #entries, 1, -1 do
		if entries[index] == path then
			table.remove(entries, index)
		end
	end
	table.insert(entries, 1, path)
	while #entries > max_entries do
		table.remove(entries)
	end
	write_history()
end

local function remember_current_playlist()
	local playlist = mp.get_property_native("playlist")
	local current_path = normalize_path(mp.get_property("path"))
	if type(playlist) ~= "table" or #playlist == 0 or not current_path then
		return
	end

	local items = {}
	for _, item in ipairs(playlist) do
		local path = normalize_path(item.filename)
		if path then
			items[#items + 1] = path
		end
	end
	if #items == 0 then
		return
	end

	local playlists = read_playlist_history()
	if #items == 1 then
		playlists[current_path] = nil
	else
		local current = mp.get_property_number("playlist-pos", 0) + 1
		playlists[current_path] = { items = items, current = current }
	end

	local recent = {}
	for _, path in ipairs(entries) do
		recent[path] = true
	end
	for path in pairs(playlists) do
		if not recent[path] then
			playlists[path] = nil
		end
	end
	write_playlist_history(playlists)
end

mp.register_event("file-loaded", function()
	hide_menu()
	remember_current_file()
	remember_current_playlist()
end)

mp.observe_property("idle-active", "bool", function(_, idle)
	if idle then
		mp.add_timeout(0.1, function()
			if mp.get_property_bool("idle-active", false) then
				show_menu()
			end
		end)
	else
		hide_menu()
	end
end)
