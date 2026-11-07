local mp = require("mp")

local osd_width = 1280
local osd_height = 720
local row_x = 0
local row_y = 9
local row_width = osd_width
local row_height = 78
local visible_rows = 9
local thumbnail_width = 140
local thumbnail_overlay_id = 43

local overlay = mp.create_osd_overlay("ass-events")
overlay.res_x = osd_width
overlay.res_y = osd_height

local cues = {}
local subtitle_cues = {}
local selected = 1
local first_visible = 1
local menu_visible = false
local paused_before_menu = nil
local loading = false
local load_generation = 0
local thumbnail_generation = 0
local thumbnail_sequence = 0
local thumbnail_cache = {}
local thumbnail_queue = {}
local thumbnail_inflight = {}
local thumbnail_requests = {}
local thumbnail_workers = 0
local thumbnail_use_counter = 0
local thumbnail_dimensions_key = nil
local max_thumbnail_workers = 2
local thumbnail_cache_limit = visible_rows * 3

local function escape_ass(text)
    return (text or ""):gsub("\\", "\\e"):gsub("{", "\\{"):gsub("}", "\\}")
end

local function truncate(text, length)
    if #text <= length then
        return text
    end

    local result = text:sub(1, length - 3)
    while #result > 0 do
        local byte = result:byte(-1)
        if not byte or byte < 128 or byte >= 192 then
            break
        end
        result = result:sub(1, -2)
    end
    return result .. "…"
end

local function wrap_text(text, line_length, maximum_lines)
    local lines = {}
    local remaining = text:match("^%s*(.-)%s*$")
    while remaining ~= "" and #lines < maximum_lines do
        if #remaining <= line_length then
            lines[#lines + 1] = remaining
            break
        end
        if #lines == maximum_lines - 1 then
            lines[#lines + 1] = truncate(remaining, line_length)
            break
        end

        local candidate = remaining:sub(1, line_length)
        local split = candidate:match("^.*()%s")
        if not split then
            lines[#lines + 1] = truncate(remaining, line_length)
            break
        end
        lines[#lines + 1] = candidate:sub(1, split - 1)
        remaining = remaining:sub(split + 1):match("^%s*(.*)$")
    end

    for index, line in ipairs(lines) do
        lines[index] = escape_ass(line)
    end
    return table.concat(lines, "\\N"), #lines
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

local function format_time(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor(seconds / 60) % 60
    local secs = math.floor(seconds) % 60
    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, secs)
    end
    return string.format("%02d:%02d", minutes, secs)
end

local function active_cue_index()
    local position = mp.get_property_number("time-pos", 0)
    local low, high = 1, #cues
    local result = 1
    while low <= high do
        local middle = math.floor((low + high) / 2)
        if cues[middle].start <= position then
            result = middle
            low = middle + 1
        else
            high = middle - 1
        end
    end
    return result
end

local function keep_selected_visible()
    if selected < first_visible then
        first_visible = selected
    elseif selected >= first_visible + visible_rows then
        first_visible = selected - visible_rows + 1
    end
    first_visible = math.max(1, math.min(first_visible, math.max(1, #cues - visible_rows + 1)))
end

local function thumbnail_source_index(index)
    local cue = cues[index]
    if not cue then
        return index
    end
    local source = index
    for previous = index - 1, 1, -1 do
        if cue.start - cues[previous].start > 2 then
            break
        end
        source = previous
    end
    return source
end

local function clear_thumbnails()
    thumbnail_generation = thumbnail_generation + 1
    for request in pairs(thumbnail_requests) do
        mp.abort_async_command(request)
    end
    for row = 0, visible_rows - 1 do
        mp.commandv("overlay-remove", tostring(thumbnail_overlay_id + row))
    end
    for _, thumbnail in pairs(thumbnail_cache) do
        os.remove(thumbnail.path)
    end
    thumbnail_cache = {}
    thumbnail_queue = {}
    thumbnail_inflight = {}
    thumbnail_requests = {}
    thumbnail_workers = 0
    thumbnail_dimensions_key = nil
end

local function video_source()
    local source = mp.get_property("stream-open-filename") or mp.get_property("path")
    if not source or source == "" then
        return nil
    end
    if not source:match("^%a[%w+.-]*://") and not source:match("^[/\\]") then
        local working_directory = mp.get_property("working-directory")
        source = working_directory and (working_directory .. "/" .. source) or source
    end
    return source
end

local function selected_video_stream()
    for _, track in ipairs(mp.get_property_native("track-list") or {}) do
        if track.type == "video" and track.selected then
            return track["ff-index"]
        end
    end
    return nil
end

local function thumbnail_geometry()
    local source = video_source()
    local stream = selected_video_stream()
    local dimensions = mp.get_property_native("osd-dimensions")
    if not source or stream == nil or not dimensions or not dimensions.w or not dimensions.h then
        return nil
    end
    local width = math.max(2, math.floor(thumbnail_width * dimensions.w / osd_width + 0.5))
    local height = math.max(2, math.floor(row_height * dimensions.h / osd_height + 0.5))
    local content_height = math.max(2, math.floor((row_height - 6) * dimensions.h / osd_height + 0.5))
    width = width - (width % 2)
    height = height - (height % 2)
    content_height = content_height - (content_height % 2)
    return {
        source = source,
        stream = stream,
        width = width,
        height = height,
        content_height = content_height,
        x = math.floor(row_x * dimensions.w / osd_width + 0.5),
        y = math.floor(row_y * dimensions.h / osd_height + 0.5),
        key = string.format("%dx%d", width, height),
    }
end

local function display_cached_thumbnails(geometry)
    if not menu_visible then
        return
    end
    for row = 0, visible_rows - 1 do
        local overlay_id = thumbnail_overlay_id + row
        local index = first_visible + row
        local thumbnail = thumbnail_cache[thumbnail_source_index(index)]
        if thumbnail and index <= #cues then
            thumbnail_use_counter = thumbnail_use_counter + 1
            thumbnail.last_used = thumbnail_use_counter
            mp.commandv(
                "overlay-add", tostring(overlay_id), tostring(geometry.x), tostring(geometry.y + row * geometry.height),
                thumbnail.path, "0", "bgra", tostring(geometry.width), tostring(geometry.height),
                tostring(geometry.width * 4), tostring(geometry.width), tostring(geometry.height)
            )
        else
            mp.commandv("overlay-remove", tostring(overlay_id))
        end
    end
end

local function evict_old_thumbnails()
    local protected = {}
    local first = math.max(1, first_visible - visible_rows)
    local last = math.min(#cues, first_visible + visible_rows * 2 - 1)
    for index = first, last do
        protected[thumbnail_source_index(index)] = true
    end
    local count = 0
    for _ in pairs(thumbnail_cache) do
        count = count + 1
    end
    while count > thumbnail_cache_limit do
        local oldest_index, oldest_use
        for index, thumbnail in pairs(thumbnail_cache) do
            if not protected[index] and (not oldest_use or thumbnail.last_used < oldest_use) then
                oldest_index = index
                oldest_use = thumbnail.last_used
            end
        end
        if not oldest_index then
            return
        end
        os.remove(thumbnail_cache[oldest_index].path)
        thumbnail_cache[oldest_index] = nil
        count = count - 1
    end
end

local start_thumbnail_jobs

local function generate_thumbnail(index, geometry)
    local cue = cues[index]
    if not cue then
        return
    end
    local generation = thumbnail_generation
    thumbnail_sequence = thumbnail_sequence + 1
    local temporary = os.getenv("TMPDIR") or "/tmp"
    local output = string.format(
        "%s/mpv-subtitle-timeline-%s-%d-%d.bgra",
        temporary:gsub("/$", ""),
        tostring(mp.get_property_number("pid", 0)),
        generation,
        thumbnail_sequence
    )
    local filter = string.format(
        "scale=%d:%d:force_original_aspect_ratio=decrease,pad=%d:%d:(ow-iw)/2:0:color=0x181818,format=bgra",
        geometry.width,
        geometry.content_height,
        geometry.width,
        geometry.height
    )
    local request
    thumbnail_workers = thumbnail_workers + 1
    thumbnail_inflight[index] = true
    request = mp.command_native_async({
        name = "subprocess",
        args = {
            "ffmpeg", "-nostdin", "-v", "error", "-ss", string.format("%.3f", cue.start),
            "-i", geometry.source, "-map", "0:" .. tostring(geometry.stream), "-vf", filter,
            "-frames:v", "1", "-f", "rawvideo", "-pix_fmt", "bgra", "-y", output,
        },
        playback_only = true,
    }, function(success, result)
        thumbnail_requests[request] = nil
        thumbnail_inflight[index] = nil
        thumbnail_workers = math.max(0, thumbnail_workers - 1)
        if generation ~= thumbnail_generation or not menu_visible then
            os.remove(output)
        elseif success and result and result.status == 0 then
            thumbnail_use_counter = thumbnail_use_counter + 1
            thumbnail_cache[index] = { path = output, last_used = thumbnail_use_counter }
            evict_old_thumbnails()
            display_cached_thumbnails(geometry)
        else
            os.remove(output)
            mp.msg.error("Could not generate subtitle timeline frame")
        end
        start_thumbnail_jobs(geometry)
    end)
    thumbnail_requests[request] = true
end

start_thumbnail_jobs = function(geometry)
    while thumbnail_workers < max_thumbnail_workers and #thumbnail_queue > 0 do
        local index = table.remove(thumbnail_queue, 1)
        if not thumbnail_cache[index] and not thumbnail_inflight[index] and cues[index] then
            generate_thumbnail(index, geometry)
        end
    end
end

local function schedule_thumbnails()
    if not menu_visible or loading or #cues == 0 then
        return
    end
    local geometry = thumbnail_geometry()
    if not geometry then
        return
    end
    if thumbnail_dimensions_key and thumbnail_dimensions_key ~= geometry.key then
        clear_thumbnails()
    end
    thumbnail_dimensions_key = geometry.key
    display_cached_thumbnails(geometry)

    thumbnail_queue = {}
    local queued = {}
    local function enqueue(index)
        if index >= 1 and index <= #cues then
            local source = thumbnail_source_index(index)
            if not thumbnail_cache[source] and not thumbnail_inflight[source] and not queued[source] then
                thumbnail_queue[#thumbnail_queue + 1] = source
                queued[source] = true
            end
        end
    end
    for row = 0, visible_rows - 1 do
        enqueue(first_visible + row)
    end
    for row = 0, visible_rows - 1 do
        enqueue(first_visible + visible_rows + row)
        enqueue(first_visible - visible_rows + row)
    end
    start_thumbnail_jobs(geometry)
end

local function render_menu()
    if not menu_visible then
        return
    end

    local parts = {}

    if loading then
        table.insert(parts, 1, rectangle(0, 0, osd_width, osd_height, "101010", "08"))
        parts[#parts + 1] = "{\\an5\\pos(640,350)\\fs22\\1c&HAAAAAA&}Loading subtitles…"
    elseif #cues == 0 then
        table.insert(parts, 1, rectangle(0, 0, osd_width, osd_height, "101010", "08"))
        parts[#parts + 1] = "{\\an5\\pos(640,340)\\fs22\\1c&HAAAAAA&}No text subtitles available"
        parts[#parts + 1] = "{\\an5\\pos(640,375)\\fs16\\1c&H777777&}Select a subtitle track and try again"
    else
        local last = math.min(#cues, first_visible + visible_rows - 1)
        local row_count = last - first_visible + 1
        local slot_x = row_x
        local slot_right = slot_x + thumbnail_width
        local rows_bottom = row_y + row_count * row_height
        table.insert(parts, 1, rectangle(0, 0, osd_width, row_y, "101010", "08"))
        parts[#parts + 1] = rectangle(0, rows_bottom, osd_width, osd_height - rows_bottom, "101010", "08")
        parts[#parts + 1] = rectangle(slot_right, row_y, osd_width - slot_right, rows_bottom - row_y, "101010", "08")
        for index = first_visible, last do
            local visible_index = index - first_visible
            local y = row_y + visible_index * row_height
            local is_selected = index == selected
            local background = is_selected and "3B3B3B" or "242424"
            local time_color = is_selected and "6E6EFF" or "999999"
            local text_color = cues[index].frame_only and "777777" or (is_selected and "FFFFFF" or "E0E0E0")
            local display_text = cues[index].frame_only and "Video frame" or cues[index].text
            local text_length = #display_text
            local font_size = text_length <= 60 and 24 or (text_length <= 115 and 20 or 17)
            local line_length = font_size == 24 and 60 or (font_size == 20 and 72 or 86)
            local wrapped_text, line_count = wrap_text(display_text, line_length, 2)
            local text_y = line_count > 1 and y + 9 or y + 21

            parts[#parts + 1] = rectangle(
                row_x + thumbnail_width,
                y,
                row_width - thumbnail_width,
                row_height - 6,
                background,
                is_selected and "00" or "18"
            )
            parts[#parts + 1] = string.format(
                "{\\an7\\pos(%d,%d)\\fs22\\b1\\1c&H%s&}%s",
                row_x + thumbnail_width + 14,
                y + 23,
                time_color,
                format_time(cues[index].start)
            )
            parts[#parts + 1] = string.format(
                "{\\an7\\pos(%d,%d)\\fs%d\\b0\\1c&H%s&}%s",
                row_x + thumbnail_width + 92,
                text_y,
                font_size,
                text_color,
                wrapped_text
            )
        end

    end
    overlay.data = table.concat(parts, "\n")
    overlay:update()
end

local function remove_menu_bindings()
    for _, name in ipairs({
        "subtitle-timeline-up",
        "subtitle-timeline-down",
        "subtitle-timeline-page-up",
        "subtitle-timeline-page-down",
        "subtitle-timeline-window-up",
        "subtitle-timeline-window-down",
        "subtitle-timeline-open",
        "subtitle-timeline-click",
        "subtitle-timeline-current",
        "subtitle-timeline-close",
    }) do
        mp.remove_key_binding(name)
    end
end

local function hide_menu()
    if not menu_visible then
        return
    end
    menu_visible = false
    load_generation = load_generation + 1
    clear_thumbnails()
    overlay:remove()
    remove_menu_bindings()
    if paused_before_menu ~= nil then
        mp.set_property_bool("pause", paused_before_menu)
        paused_before_menu = nil
    end
end

local function move_selection(amount)
    if #cues == 0 then
        return
    end
    local previous_first = first_visible
    selected = math.max(1, math.min(#cues, selected + amount))
    keep_selected_visible()
    render_menu()
    if first_visible ~= previous_first then
        schedule_thumbnails()
    end
end

local function move_window(amount)
    if #cues == 0 then
        return
    end
    local row = selected - first_visible
    local maximum_first = math.max(1, #cues - visible_rows + 1)
    local next_first = math.max(1, math.min(maximum_first, first_visible + amount))
    if next_first == first_visible then
        return
    end
    first_visible = next_first
    selected = math.min(#cues, first_visible + row)
    render_menu()
    schedule_thumbnails()
end

local function seek_selected()
    local cue = cues[selected]
    if not cue then
        return
    end
    mp.commandv("seek", tostring(cue.start), "absolute", "exact")
    hide_menu()
end

local function select_current_cue()
    if #cues == 0 then
        return
    end
    selected = active_cue_index()
    first_visible = math.max(1, selected - math.floor(visible_rows / 2))
    keep_selected_visible()
    render_menu()
    schedule_thumbnails()
end

local function clicked_cue()
    local mouse = mp.get_property_native("mouse-pos")
    local dimensions = mp.get_property_native("osd-dimensions")
    if not mouse or not dimensions or not dimensions.w or not dimensions.h or dimensions.w == 0 or dimensions.h == 0 then
        return nil
    end

    local x = mouse.x * osd_width / dimensions.w
    local y = mouse.y * osd_height / dimensions.h
    if x < row_x or x > row_x + row_width or y < row_y then
        return nil
    end

    local row = math.floor((y - row_y) / row_height)
    if row < 0 or row >= visible_rows or y > row_y + row * row_height + row_height - 6 then
        return nil
    end
    local index = first_visible + row
    return index <= #cues and index or nil
end

local function open_clicked()
    local index = clicked_cue()
    if not index then
        return
    end
    selected = index
    seek_selected()
end

local function timestamp_seconds(hours, minutes, seconds, fraction)
    local milliseconds = tonumber(fraction) or 0
    if #fraction == 1 then
        milliseconds = milliseconds * 100
    elseif #fraction == 2 then
        milliseconds = milliseconds * 10
    elseif #fraction > 3 then
        milliseconds = tonumber(fraction:sub(1, 3)) or 0
    end
    return tonumber(hours) * 3600 + tonumber(minutes) * 60 + tonumber(seconds) + milliseconds / 1000
end

local function parse_srt(contents)
    local parsed = {}
    contents = (contents or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
    for block in (contents .. "\n\n"):gmatch("(.-)\n%s*\n") do
        local h, m, s, fraction, end_h, end_m, end_s, end_fraction =
            block:match("(%d+):(%d+):(%d+)[,.](%d+)%s*%-%->%s*(%d+):(%d+):(%d+)[,.](%d+)")
        local text = block:match("%-%->[^\n]*\n(.+)") or ""
        if h then
            text = text:gsub("<[^>]->", ""):gsub("{[^}]-}", ""):gsub("\n", " "):gsub("%s+", " ")
            text = text:match("^%s*(.-)%s*$")
            parsed[#parsed + 1] = {
                start = timestamp_seconds(h, m, s, fraction),
                finish = timestamp_seconds(end_h, end_m, end_s, end_fraction),
                text = text ~= "" and text or "Subtitle",
            }
        end
    end
    table.sort(parsed, function(a, b)
        return a.start < b.start
    end)
    return parsed
end

local function is_valid_utf8(contents)
    local index = 1
    while index <= #contents do
        local first = contents:byte(index)
        local length = first < 0x80 and 1
            or (first >= 0xC2 and first <= 0xDF and 2)
            or (first >= 0xE0 and first <= 0xEF and 3)
            or (first >= 0xF0 and first <= 0xF4 and 4)
            or 0
        if length == 0 or index + length - 1 > #contents then
            return false
        end
        for offset = 1, length - 1 do
            local byte = contents:byte(index + offset)
            if byte < 0x80 or byte > 0xBF then
                return false
            end
        end
        index = index + length
    end
    return true
end

local function add_gap_frames(subtitles)
    local timeline = {}
    for index, subtitle in ipairs(subtitles) do
        timeline[#timeline + 1] = subtitle
        local following = subtitles[index + 1]
        if following then
            local time = subtitle.finish + 5
            while time < following.start do
                timeline[#timeline + 1] = {
                    start = time,
                    finish = time,
                    text = "",
                    frame_only = true,
                }
                time = time + 5
            end
        end
    end
    return timeline
end

local function timeline_with_subtitle_delay(subtitles)
    local delay = mp.get_property_number("sub-delay", 0)
    local delayed = {}
    for _, subtitle in ipairs(subtitles) do
        delayed[#delayed + 1] = {
            start = math.max(0, subtitle.start + delay),
            finish = math.max(0, subtitle.finish + delay),
            text = subtitle.text,
        }
    end
    return add_gap_frames(delayed)
end

local function rebuild_timeline()
    clear_thumbnails()
    cues = timeline_with_subtitle_delay(subtitle_cues)
    selected = #cues > 0 and active_cue_index() or 1
    first_visible = math.max(1, selected - math.floor(visible_rows / 2))
    keep_selected_visible()
    render_menu()
    schedule_thumbnails()
end

local function normalize_path(path)
    if not path or path == "" or path:match("^%a[%w+.-]*://") or path:match("^[/\\]") then
        return path
    end
    local working_directory = mp.get_property("working-directory")
    return working_directory and (working_directory .. "/" .. path) or path
end

local function selected_subtitle()
    local tracks = mp.get_property_native("track-list") or {}
    for _, track in ipairs(tracks) do
        if track.type == "sub" and track.selected then
            return track
        end
    end
    return nil
end

local function load_cues()
    local track = selected_subtitle()
    if not track then
        loading = false
        subtitle_cues = {}
        cues = {}
        render_menu()
        return
    end

    local source = track["external-filename"] or mp.get_property("path")
    source = normalize_path(source)
    if not source then
        loading = false
        subtitle_cues = {}
        cues = {}
        render_menu()
        return
    end

    local map = track["external-filename"] and "0:s:0" or ("0:" .. tostring(track["ff-index"] or "s:0"))
    local generation = load_generation
    local function finish_loading(contents)
        if generation ~= load_generation or not menu_visible then
            return
        end
        loading = false
        subtitle_cues = parse_srt(contents or "")
        rebuild_timeline()
    end

    if track["external-filename"] and track.codec == "subrip" then
        local file = io.open(source, "rb")
        local contents = file and file:read("*a") or ""
        if file then
            file:close()
        end
        if is_valid_utf8(contents) then
            finish_loading(contents)
            return
        end
        mp.command_native_async({
            name = "subprocess",
            args = { "iconv", "-f", "WINDOWS-1254", "-t", "UTF-8", source },
            capture_stdout = true,
            capture_stderr = true,
            playback_only = true,
        }, function(success, result)
            finish_loading(success and result and result.stdout or contents)
        end)
        return
    end

    mp.command_native_async({
        name = "subprocess",
        args = { "ffmpeg", "-nostdin", "-v", "error", "-i", source, "-map", map, "-f", "srt", "-" },
        capture_stdout = true,
        capture_stderr = true,
        playback_only = true,
    }, function(success, result)
        finish_loading(success and result and result.stdout or "")
    end)
end

local function show_menu()
    if menu_visible then
        return
    end
    paused_before_menu = mp.get_property_bool("pause", false)
    mp.set_property_bool("pause", true)
    menu_visible = true
    loading = true
    cues = {}
    selected = 1
    first_visible = 1
    load_generation = load_generation + 1

    mp.add_forced_key_binding("UP", "subtitle-timeline-up", function() move_selection(-1) end, { repeatable = true })
    mp.add_forced_key_binding("DOWN", "subtitle-timeline-down", function() move_selection(1) end, { repeatable = true })
    mp.add_forced_key_binding("WHEEL_UP", "subtitle-timeline-page-up", function() move_selection(-3) end)
    mp.add_forced_key_binding("WHEEL_DOWN", "subtitle-timeline-page-down", function() move_selection(3) end)
    mp.add_forced_key_binding("LEFT", "subtitle-timeline-window-up", function() move_window(-visible_rows) end, { repeatable = true })
    mp.add_forced_key_binding("RIGHT", "subtitle-timeline-window-down", function() move_window(visible_rows) end, { repeatable = true })
    mp.add_forced_key_binding("ENTER", "subtitle-timeline-open", seek_selected)
    mp.add_forced_key_binding("MBTN_LEFT", "subtitle-timeline-click", open_clicked)
    mp.add_forced_key_binding("c", "subtitle-timeline-current", select_current_cue)
    mp.add_forced_key_binding("ESC", "subtitle-timeline-close", hide_menu)
    render_menu()
    load_cues()
end

mp.add_key_binding(nil, "toggle", function()
    if menu_visible then
        hide_menu()
    else
        show_menu()
    end
end)

mp.observe_property("sub-delay", "number", function()
    if menu_visible and not loading and #subtitle_cues > 0 then
        rebuild_timeline()
    end
end)

mp.register_event("file-loaded", hide_menu)
