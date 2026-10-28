-- Keep mpv's normal subtitle selection, but prefer an SDH variant of the
-- automatically selected language. Manual changes made afterward are untouched.

local function normalized_language(language)
    language = (language or ""):lower():match("^[^-_]+") or ""

    if language == "en" then
        return "eng"
    elseif language == "tr" then
        return "tur"
    end

    return language
end

local function is_sdh(track)
    if track["hearing-impaired"] then
        return true
    end

    local title = (track.title or ""):lower()
    return title:match("%f[%a]sdh%f[%A]") ~= nil
        or title:find("hearing impaired", 1, true) ~= nil
        or title:find("hearing-impaired", 1, true) ~= nil
end

local function is_primary_selected_subtitle(track)
    return track.type == "sub"
        and track.selected
        and (track["main-selection"] == nil or track["main-selection"] == 0)
end

local function candidate_score(track)
    local score = 0

    -- Preserve mpv's normal tie-breaking preferences among SDH tracks.
    if track.external then score = score + 8 end
    if not track["auto-loaded"] then score = score + 4 end
    if track.default then score = score + 2 end

    -- Lower track IDs win otherwise.
    return score * 100000 - (tonumber(track.id) or 99999)
end

local function prefer_sdh()
    local tracks = mp.get_property_native("track-list", {})
    local selected

    for _, track in ipairs(tracks) do
        if is_primary_selected_subtitle(track) then
            selected = track
            break
        end
    end

    -- Let mpv handle files where its normal rules selected no subtitle.
    if not selected or is_sdh(selected) then
        return
    end

    local selected_language = normalized_language(selected.lang)
    if selected_language == "" then
        return
    end

    local best
    local best_score
    for _, track in ipairs(tracks) do
        if track.type == "sub"
            and normalized_language(track.lang) == selected_language
            and track.forced == selected.forced
            and is_sdh(track)
        then
            local score = candidate_score(track)
            if not best or score > best_score then
                best = track
                best_score = score
            end
        end
    end

    if best then
        mp.set_property_number("sid", best.id)
        mp.msg.info(string.format(
            "preferred SDH subtitle: %s (sid=%s)",
            best.title or best.lang or "untitled",
            tostring(best.id)
        ))
    end
end

mp.register_event("file-loaded", function()
    -- Run after mpv's built-in language/default selection has settled.
    mp.add_timeout(0, prefer_sdh)
end)

mp.register_script_message("apply", prefer_sdh)
