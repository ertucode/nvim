-- Tap Space to toggle pause; hold it and use live modifiers for temporary speedup.

local hold_delay = 0.25
local key_down = false
local holding = false
local hold_timer = nil
local modifier_timer = nil
local binding_speed = 2
local active_speed = nil
local previous_speed = nil
local previously_paused = nil

local overlay_speed = nil
local speed_overlay = mp.create_osd_overlay("ass-events")
speed_overlay.res_x = 1280
speed_overlay.res_y = 720
speed_overlay.z = 1000

local function show_speed_overlay(speed)
    if overlay_speed == speed then
        return
    end

    overlay_speed = speed
    speed_overlay.data = string.format(
        "{\\an8\\pos(640,45)\\fs34\\bord2\\shad0\\b1}%dx",
        speed
    )
    speed_overlay:update()
end

local function clear_speed_overlay()
    overlay_speed = nil
    speed_overlay.data = ""
    speed_overlay:update()
end

-- mpv does not expose standalone modifier key events. On macOS, query their
-- live state so Control and Option can change speed while Space remains held.
local get_modifier_speed = nil
do
    local ok_ffi, ffi = pcall(require, "ffi")
    local ok_bit, bit = pcall(require, "bit")
    if ok_ffi and ok_bit then
        local ok_framework, framework = pcall(function()
            ffi.cdef([[
                typedef unsigned long long CGEventFlags;
                CGEventFlags CGEventSourceFlagsState(int stateID);
            ]])
            return ffi.load("/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices")
        end)

        if ok_framework then
            local control_mask = 0x40000
            local option_mask = 0x80000
            get_modifier_speed = function()
                local flags = tonumber(framework.CGEventSourceFlagsState(0))
                if bit.band(flags, option_mask) ~= 0 then
                    return 4
                elseif bit.band(flags, control_mask) ~= 0 then
                    return 3
                end
                return 2
            end
        end
    end
end

local function selected_speed()
    return get_modifier_speed and get_modifier_speed() or binding_speed
end

local function update_speed()
    if not holding then
        return
    end

    local speed = selected_speed()
    if speed ~= active_speed then
        active_speed = speed
        mp.set_property_number("speed", speed)
        show_speed_overlay(speed)
    end
end

local function cancel_hold_timer()
    if hold_timer then
        hold_timer:kill()
        hold_timer = nil
    end
end

local function begin_hold()
    hold_timer = nil
    if not key_down then
        return
    end

    holding = true
    previous_speed = mp.get_property_number("speed", 1)
    previously_paused = mp.get_property_native("pause", false)
    mp.set_property_native("pause", false)
    update_speed()
    modifier_timer = mp.add_periodic_timer(0.03, update_speed)
end

local function finish_press()
    if not key_down then
        return
    end

    key_down = false
    cancel_hold_timer()

    if holding then
        if modifier_timer then
            modifier_timer:kill()
            modifier_timer = nil
        end
        mp.set_property_number("speed", previous_speed or 1)
        mp.set_property_native("pause", previously_paused or false)
        clear_speed_overlay()
        holding = false
        active_speed = nil
        previous_speed = nil
        previously_paused = nil
    else
        mp.commandv("cycle", "pause")
    end
end

local function handle_space(event, initial_speed)
    if event.event == "down" then
        if key_down then
            return
        end

        binding_speed = initial_speed
        key_down = true
        hold_timer = mp.add_timeout(hold_delay, begin_hold)
    elseif event.event == "up" then
        finish_press()
    elseif event.event == "press" then
        -- Some input sources provide a complete press rather than down/up.
        mp.commandv("cycle", "pause")
    end
end

local function add_hold_binding(name, initial_speed)
    mp.add_key_binding(nil, name, function(event)
        handle_space(event, initial_speed)
    end, {complex = true})
end

add_hold_binding("hold-speed-2x", 2)
add_hold_binding("hold-speed-3x", 3)
add_hold_binding("hold-speed-4x", 4)
