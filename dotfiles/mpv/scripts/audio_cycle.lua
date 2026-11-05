-- Cycle through available audio tracks without selecting the no-audio state.

local function next_audio_track()
    local audio_tracks = {}
    local selected_index

    for _, track in ipairs(mp.get_property_native("track-list", {})) do
        if track.type == "audio" then
            table.insert(audio_tracks, track)
            if track.selected then
                selected_index = #audio_tracks
            end
        end
    end

    if #audio_tracks == 0 then
        return
    end

    local next_index = (selected_index or 0) % #audio_tracks + 1
    mp.commandv("osd-auto", "set", "aid", tostring(audio_tracks[next_index].id))
end

mp.add_key_binding(nil, "next", next_audio_track)
