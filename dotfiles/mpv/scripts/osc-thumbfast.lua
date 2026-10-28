-- Connect mpv's built-in OSC thumbnail-preview API to Thumbfast.

local function draw_preview(_, request)
    if type(request) ~= "table" then
        mp.commandv("script-message-to", "thumbfast", "clear")
        return
    end

    local time = tonumber(request["hover-sec"])
    local x = tonumber(request.x)
    local y = tonumber(request.y)
    if not time or not x or not y then
        return
    end

    -- Thumbfast's decoded frame can be taller than the OSC's reserved box on
    -- HiDPI displays, so leave extra clearance above the timeline.
    y = math.max(0, y - 100)

    mp.commandv(
        "script-message-to", "thumbfast", "thumb",
        tostring(time), tostring(x), tostring(y)
    )
end

mp.observe_property("user-data/osc/draw-preview", "native", draw_preview)
