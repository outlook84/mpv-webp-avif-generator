-- Create animated webp/avif with mpv
-- Requires ffmpeg.
-- Adapted from https://github.com/DonCanjas/mpv-webp-generator
-- Usage: Set A-B loop in mpv, then press Ctrl+w to generate webp, or Alt+w to generate avif.

--  Note:
--     Requires FFmpeg in PATH environment variable or edit ffmpeg_path in the script options.
--     For example: "ffmpeg" or "C:\Programs\ffmpeg\bin\ffmpeg.exe" or "/usr/bin/ffmpeg"
--  Note:
--     A small circle at the top-right corner is a sign that creation is happening now.

require 'mp.options'
local msg = require 'mp.msg'
local utils = require "mp.utils"

-- Detect OS
local platform = mp.get_property('platform')
local os_type = (platform == "windows") and "windows" or "unix"     

local options = {
    ffmpeg_path = "ffmpeg",
    dir = (os_type == "windows") and "~~desktop/" or "~/",
    libplacebo = false,      -- Use libplacebo for scaling, requires libplacebo to be compiled with ffmpeg
    rez = 640,               -- Output resolution, in pixels, width, keep aspect ratio
    fps = 0,                 -- 0 means use source video fps
    max_fps = 0,             -- Max frame rate option, 0 means no limit
    lossless = 0,            -- webp compression parameter: 0=lossy, 1=lossless
    quality = 90,            -- webp compression parameter: 0-100, higher is better quality
    compression_level = 5,   -- webp compression parameter: 0-6, higher means smaller size but slower
    loop = 0,
    avif_quality = 30,       -- avif quality (corresponds to crf)
    avif_preset = 3          -- avif encoding preset
}

read_options(options, "webp")

-- Determine fps behavior
local function filters()
    local target_fps = tonumber(options.fps) or 0
    local max_fps = tonumber(options.max_fps) or 0

    -- Prefer container fps, fallback to codec fps
    local current_fps = tonumber(mp.get_property("container-fps")) or 0
    if current_fps == 0 then
        current_fps = tonumber(mp.get_property("fps")) or 0
    end

    if target_fps <= 0 then
        target_fps = 0
    end

    if target_fps == 0 and max_fps > 0 and current_fps > max_fps then
        target_fps = max_fps
    elseif max_fps > 0 and target_fps > max_fps then
        target_fps = max_fps
    end

    if options.libplacebo then
        local base = string.format("libplacebo=w=%s:h=-1", options.rez)
        local deband = ",libplacebo=deband=true"

        local mixer = ""
        if target_fps > 0 then
            mixer = string.format(",libplacebo=frame_mixer=mitchell_clamp:fps=%s", target_fps)
        end
        return base .. deband .. mixer .. ",setsar=1/1"
    else
        if target_fps == 0 then
            return string.format(
                "zscale='trunc(ih*dar/2)*2:trunc(ih/2)*2':f=spline36,setsar=1/1,zscale=%s:-1:f=spline36",
                options.rez
            )
        else
            return string.format(
                "fps=%s,zscale='trunc(ih*dar/2)*2:trunc(ih/2)*2':f=spline36,setsar=1/1,zscale=%s:-1:f=spline36",
                target_fps, options.rez
            )
        end
    end
end

-- Setup output directory
local output_directory = mp.command_native({ "expand-path", options.dir })
-- Create output_directory if it doesn't exist
if utils.readdir(output_directory) == nil then
    local args
    if os_type == "windows" then
        args = { 'powershell', '-NoProfile', '-Command', 'mkdir', output_directory }
    else
        args = { 'mkdir', '-p', output_directory }
    end
    local res = mp.command_native({name = "subprocess", capture_stdout = true, playback_only = false, args = args})
    if res.status ~= 0 then
        msg.error("Failed to create webp_dir save directory "..output_directory..". Error: "..(res.error or "unknown"))
        return
    end
end

start_time = -1
end_time = -1

function table_length(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function make_webp_internal(format)
    local start_time_l = start_time
    local end_time_l = end_time
    if start_time_l == -1 or end_time_l == -1 or start_time_l >= end_time_l then
        mp.osd_message("Invalid start/end time.")
        return
    end

    local ext = format == "avif" and "avif" or "webp"
    msg.info("Creating " .. ext .. ".")
    mp.osd_message("Creating " .. ext .. ".")

    local pathname = mp.get_property("path", "")
    local trim_filters = filters()
    local temp_symlink_path = nil -- To store the path of the temporary symlink for cleanup

    -- shell escape function
    local function esc_for_sub(s)
        s = string.gsub(s, [[\]], [[/]])
        s = string.gsub(s, '"', '"\\""')
        s = string.gsub(s, ":", [[\:]])
        s = string.gsub(s, "'", [[\'\']])
        s = string.gsub(s, "%[", "\\%[")
        s = string.gsub(s, "%]", "\\%]")
        return s
    end

    local sid = mp.get_property_number("sid", 0)

    if sid > 0 then
        -- Determine currently active sub track
        local i = 0
        local tracks_count = mp.get_property_number("track-list/count")
        local subs_array = {}
        local external_sub_path = nil
        local selected_sub_index = nil

        while i < tracks_count do
            local track_type = mp.get_property(string.format("track-list/%d/type", i))
            local selected = mp.get_property(string.format("track-list/%d/selected", i))
            local external = mp.get_property(string.format("track-list/%d/external", i))
            local external_filename = mp.get_property(string.format("track-list/%d/external-filename", i))

            if track_type == "sub" then
                local length = table_length(subs_array)
                if selected == "yes" then
                    selected_sub_index = length
                    if external == "yes" and external_filename and external_filename ~= "" then
                        external_sub_path = external_filename
                    end
                end
                subs_array[length] = selected == "yes"
            end
            i = i + 1
        end

        if table_length(subs_array) > 0 then
            local sub_path = pathname
            local sub_si = 0
            if external_sub_path then
                sub_path = external_sub_path
                sub_si = 0
            else
                -- Embedded subtitles
                for index, is_selected in pairs(subs_array) do
                    if is_selected then
                        sub_si = index
                    end
                end
            end
            if os_type == "windows" then
                 trim_filters = trim_filters .. string.format(",subtitles='%s':si=%s", esc_for_sub(sub_path), sub_si)
            else
                -- Unix: Use a symbolic link to avoid quoting issues with subtitle paths.
                temp_symlink_path = "/tmp/mpv_webp_tempsub_" .. math.floor(os.clock() * 1e6)

                local function get_full_path()
                    local rel_path = mp.get_property("path")
                    local working_dir = mp.get_property("working-directory")
                    if rel_path:find("^/") then
                        return rel_path
                    else 
                        return utils.join_path(working_dir, rel_path)
                    end
                end

                local full_path = get_full_path()
                local ln_args = {'ln', '-s', full_path, temp_symlink_path}
                local ln_res = mp.command_native({name = "subprocess", capture_stdout = true, playback_only = false, args = ln_args})

                if ln_res.status ~= 0 then
                    msg.error("Failed to create symbolic link for subtitles. Error: " .. (ln_res.error or "unknown"))
                    mp.osd_message("Error: Failed to create symlink for subs.")
                    return
                end

                -- Using filename=... is the most robust syntax for the subtitles filter.
                trim_filters = trim_filters .. string.format(",subtitles=filename=%s:si=%s", temp_symlink_path, sub_si)
            end
        end
    end

    local position = start_time_l
    local duration = end_time_l - start_time_l

    -- Generate filename and extension
    local filename = mp.get_property("filename/no-ext")
    local file_path = output_directory .. "/" .. filename

    -- Increment filename
    local outname
    for i=0,999 do
        local fn = string.format('%s_%03d.%s', file_path, i, ext)
        if not file_exists(fn) then
            outname = fn
            break
        end
    end
    if not outname then
        mp.osd_message('No available filenames!')
        return
    end

    -- Decide -ss -t parameter position
    local ss_pos, ss_out
    if sid > 0 then
        ss_pos = ""
        ss_out = string.format(" -ss %s -t %s", position, duration)
    else
        ss_pos = string.format(" -ss %s -t %s", position, duration)
        ss_out = ""
    end

    local screenx, screeny, aspect = mp.get_osd_size()
    mp.set_osd_ass(screenx, screeny, "{\\an9}● ")

    local res
    if os_type == "windows" then
        local cmd
        if format == "avif" then
            cmd = string.format(
                "%s -y -hide_banner -loglevel error%s%s -i \"%s\" -lavfi \"%s\" -c:v libsvtav1 -crf %s -preset %s -an%s -loop %s \"%s\"",
                options.ffmpeg_path,
                options.libplacebo and " -init_hw_device vulkan" or "",
                ss_pos,
                pathname,
                trim_filters,
                options.avif_quality,
                options.avif_preset,
                ss_out,
                options.loop,
                outname
            )
        else
            cmd = string.format(
                "%s -y -hide_banner -loglevel error%s%s -i \"%s\" -lavfi \"%s\" -lossless %s -q:v %s -compression_level %s -loop %s%s \"%s\"",
                options.ffmpeg_path,
                options.libplacebo and " -init_hw_device vulkan" or "",
                ss_pos,
                pathname,
                trim_filters,
                options.lossless,
                options.quality,
                options.compression_level,
                options.loop,
                ss_out,
                outname
            )
        end
        msg.info("FFmpeg command: " .. cmd)
        local args = { 'powershell', '-NoProfile', '-Command', cmd }
        res = mp.command_native({name = "subprocess", capture_stdout = true, playback_only = false, args = args})
    else -- unix
        local function split_args(str)
            local t = {}
            for arg in string.gmatch(str, "%S+") do
                table.insert(t, arg)
            end
            return t
        end

        local cmd_args = {options.ffmpeg_path, "-y", "-hide_banner", "-loglevel", "error"}

        if options.libplacebo then
            table.insert(cmd_args, "-init_hw_device")
            table.insert(cmd_args, "vulkan")
        end

        for _, v in ipairs(split_args(ss_pos)) do
            table.insert(cmd_args, v)
        end

        table.insert(cmd_args, "-i")
        table.insert(cmd_args, pathname)
        table.insert(cmd_args, "-lavfi")
        table.insert(cmd_args, trim_filters)

        if format == "avif" then
            table.insert(cmd_args, "-c:v")
            table.insert(cmd_args, "libsvtav1")
            table.insert(cmd_args, "-crf")
            table.insert(cmd_args, tostring(options.avif_quality))
            table.insert(cmd_args, "-preset")
            table.insert(cmd_args, tostring(options.avif_preset))
            table.insert(cmd_args, "-an")
            table.insert(cmd_args, "-loop")
            table.insert(cmd_args, tostring(options.loop))
        else
            table.insert(cmd_args, "-lossless")
            table.insert(cmd_args, tostring(options.lossless))
            table.insert(cmd_args, "-q:v")
            table.insert(cmd_args, tostring(options.quality))
            table.insert(cmd_args, "-compression_level")
            table.insert(cmd_args, tostring(options.compression_level))
            table.insert(cmd_args, "-loop")
            table.insert(cmd_args, tostring(options.loop))
        end

        for _, v in ipairs(split_args(ss_out)) do table.insert(cmd_args, v) end
        table.insert(cmd_args, outname)

        msg.info("FFmpeg command args: " .. table.concat(cmd_args, " "))
        res = mp.command_native({name = "subprocess", capture_stdout = true, playback_only = false, args = cmd_args})

        -- If a temporary symlink was created, remove it
        if temp_symlink_path then
            local rm_args = {'rm', '-f', temp_symlink_path}
            local rm_res = mp.command_native({name = "subprocess", capture_stdout = true, playback_only = false, args = rm_args})
        end
    end

    mp.set_osd_ass(screenx, screeny, "")
    if res.status ~= 0 then
        msg.info("Failed to create " .. ext .. ".")
        mp.osd_message("Error creating " .. ext .. ", check console for more info.")
        return
    end
    msg.info(ext .. " created.")
    mp.osd_message(ext .. " created.")
end

function file_exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end

function make_webp_from_abloop()
    local a = mp.get_property_number("ab-loop-a", -1)
    local b = mp.get_property_number("ab-loop-b", -1)
    if a == -1 or b == -1 or a >= b then
        mp.osd_message("A-B loop not set or invalid!")
        return
    end
    start_time = a
    end_time = b
    make_webp_internal("webp")
end

function make_avif_from_abloop()
    local a = mp.get_property_number("ab-loop-a", -1)
    local b = mp.get_property_number("ab-loop-b", -1)
    if a == -1 or b == -1 or a >= b then
        mp.osd_message("A-B loop not set or invalid!")
        return
    end
    start_time = a
    end_time = b
    make_webp_internal("avif")
end

mp.add_key_binding("Ctrl+w", "make_webp_from_abloop", make_webp_from_abloop)
mp.add_key_binding("Alt+w", "make_avif_from_abloop", make_avif_from_abloop)