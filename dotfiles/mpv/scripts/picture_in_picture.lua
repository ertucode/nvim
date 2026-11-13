local utils = require("mp.utils")

local pip_enabled = false
local original = nil
local geometry_timer = nil

local function cancel_geometry_timer()
    if geometry_timer then
        geometry_timer:kill()
        geometry_timer = nil
    end
end

-- System Events is used only to remember the exact user-positioned window.
-- mpv exposes the window size, but not its current screen coordinates.
local function get_macos_window_geometry()
    if jit and jit.os ~= "OSX" then return nil end

    local script = [[
on run argv
    set targetPID to (item 1 of argv) as integer
    tell application "System Events"
        tell (first process whose unix id is targetPID)
            set {windowX, windowY} to position of front window
            set {windowWidth, windowHeight} to size of front window
        end tell
    end tell
    return (windowX as text) & "," & (windowY as text) & "," & ¬
        (windowWidth as text) & "," & (windowHeight as text)
end run
]]
    local result = utils.subprocess({
        args = { "osascript", "-e", script, tostring(mp.get_property_number("pid", 0)) },
        cancellable = false,
    })
    if result.status ~= 0 then
        mp.msg.warn("Could not read the macOS window position: " .. (result.stderr or "unknown error"))
        return nil
    end

    local x, y, width, height = result.stdout:match("(-?%d+),(-?%d+),(%d+),(%d+)")
    if not x then return nil end
    return { x = tonumber(x), y = tonumber(y), width = tonumber(width), height = tonumber(height) }
end

local function restore_macos_window_geometry(geometry)
    if not geometry then return end

    local script = [[
on run argv
    set targetPID to (item 1 of argv) as integer
    set targetPosition to {(item 2 of argv) as integer, (item 3 of argv) as integer}
    set targetSize to {(item 4 of argv) as integer, (item 5 of argv) as integer}
    tell application "System Events"
        tell (first process whose unix id is targetPID)
            set size of front window to targetSize
            set position of front window to targetPosition
        end tell
    end tell
end run
]]
    local result = utils.subprocess({
        args = {
            "osascript", "-e", script, tostring(mp.get_property_number("pid", 0)),
            tostring(geometry.x), tostring(geometry.y),
            tostring(geometry.width), tostring(geometry.height),
        },
        cancellable = false,
    })
    if result.status ~= 0 then
        mp.msg.warn("Could not restore the macOS window position: " .. (result.stderr or "unknown error"))
    end
end

local function save_original_state()
    local fullscreen = mp.get_property_bool("fullscreen", false)
    return {
        fullscreen = fullscreen,
        maximized = mp.get_property_bool("window-maximized", false),
        ontop = mp.get_property_bool("ontop", false),
        border = mp.get_property_bool("border", true),
        keepaspect_window = mp.get_property_bool("keepaspect-window", true),
        force_window_position = mp.get_property_bool("force-window-position", false),
        autofit = mp.get_property("autofit", ""),
        autofit_larger = mp.get_property("autofit-larger", ""),
        autofit_smaller = mp.get_property("autofit-smaller", ""),
        geometry = mp.get_property("geometry", ""),
        window_geometry = not fullscreen and get_macos_window_geometry() or nil,
        width = mp.get_property_number("osd-width", 0),
        height = mp.get_property_number("osd-height", 0),
    }
end

local function set_enabled(enabled)
    pip_enabled = enabled
    mp.set_property_bool("user-data/picture-in-picture", enabled)
    mp.osd_message(enabled and "Picture in picture" or "Picture in picture off")
end

local function enable_pip()
    if pip_enabled then return end
    original = save_original_state()

    mp.set_property_bool("fullscreen", false)
    mp.set_property_bool("window-maximized", false)
    mp.set_property_bool("window-minimized", false)
    mp.set_property_bool("ontop", true)
    mp.set_property_bool("keepaspect-window", true)
    mp.set_property_bool("force-window-position", true)
    mp.set_property("autofit", "")
    mp.set_property("autofit-larger", "")
    mp.set_property("autofit-smaller", "")

    -- Use a fixed width and preserve the video's aspect ratio. The 100%
    -- offsets anchor the window at the bottom-right.
    local video_width = mp.get_property_number("dwidth", 16)
    local video_height = mp.get_property_number("dheight", 9)
    if video_width <= 0 or video_height <= 0 then
        video_width, video_height = 16, 9
    end
    local width = 1500
    local height = math.max(1, math.floor(width * video_height / video_width + 0.5))
    mp.set_property("geometry", string.format("%dx%d+100%%+100%%", width, height))
    set_enabled(true)
end

local function disable_pip()
    if not pip_enabled or not original then return end
    cancel_geometry_timer()
    local saved = original
    original = nil

    mp.set_property_bool("fullscreen", false)
    mp.set_property_bool("window-maximized", false)
    mp.set_property_bool("border", saved.border)
    mp.set_property_bool("keepaspect-window", saved.keepaspect_window)
    mp.set_property_bool("ontop", saved.ontop)
    mp.set_property("autofit", saved.autofit)
    mp.set_property("autofit-larger", saved.autofit_larger)
    mp.set_property("autofit-smaller", saved.autofit_smaller)
    mp.set_property("geometry", saved.geometry)
    mp.set_property_bool("force-window-position", saved.force_window_position)

    if saved.fullscreen then
        mp.set_property_bool("fullscreen", true)
    elseif saved.maximized then
        mp.set_property_bool("window-maximized", true)
    else
        geometry_timer = mp.add_timeout(0.1, function()
            geometry_timer = nil
            if saved.window_geometry then
                restore_macos_window_geometry(saved.window_geometry)
            elseif saved.width > 0 and saved.height > 0 then
                -- Portable fallback when exact coordinates are unavailable.
                mp.set_property("geometry", string.format("%dx%d+50%%+50%%", saved.width, saved.height))
            end
        end)
    end
    set_enabled(false)
end

local function toggle_pip()
    if pip_enabled then disable_pip() else enable_pip() end
end

mp.set_property_bool("user-data/picture-in-picture", false)
mp.add_key_binding(nil, "toggle", toggle_pip)
mp.register_script_message("toggle", toggle_pip)
