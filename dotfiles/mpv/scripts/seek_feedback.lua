-- Show the actual distance and destination whenever configured seek keys run.

local generation = 0

local function format_delta(seconds)
    local sign = seconds >= 0 and "+" or "-"
    local amount = math.abs(seconds)

    if math.abs(amount - math.floor(amount + 0.5)) < 0.05 then
        return string.format("%s%ds", sign, math.floor(amount + 0.5))
    end

    return string.format("%s%.1fs", sign, amount)
end

local function show_result(before, attempt, request)
    if request ~= generation then
        return
    end

    local after = mp.get_property_number("time-pos")
    if after and math.abs(after - before) > 0.01 then
        mp.osd_message(string.format(
            "Seek %s  →  %s",
            format_delta(after - before),
            mp.format_time(after, "%H:%M:%S")
        ), 3)
        return
    end

    if attempt < 10 then
        mp.add_timeout(0.03, function()
            show_result(before, attempt + 1, request)
        end)
    else
        mp.osd_message("No seek target", 2)
    end
end

local function run_seek(command, value)
    local before = mp.get_property_number("time-pos")
    if not before then
        return
    end

    generation = generation + 1
    local request = generation
    mp.commandv(command, tostring(value))
    mp.add_timeout(0, function()
        show_result(before, 0, request)
    end)
end

mp.add_key_binding(nil, "forward", function()
    run_seek("seek", 5)
end, {repeatable = true})

mp.add_key_binding(nil, "backward", function()
    run_seek("seek", -5)
end, {repeatable = true})

mp.add_key_binding(nil, "next-subtitle", function()
    run_seek("sub-seek", 1)
end, {repeatable = true})

mp.add_key_binding(nil, "previous-subtitle", function()
    run_seek("sub-seek", -1)
end, {repeatable = true})
