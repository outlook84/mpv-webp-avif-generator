# mpv-webp-avif-generator

[中文说明](README-CN.md)

A [mpv](https://mpv.io/) user script to quickly generate animated **WebP** or **AVIF** clips from any video segment using [FFmpeg](https://ffmpeg.org/).

![sample](./少女革命ウテナ.アドゥレセンス黙示録.avif)

> **Note:** This script now supports both **Windows** and **Linux**.  
> For macOS, I do not have a test environment. Contributions are welcome!

> **Thanks to the original author:** https://github.com/DonCanjas/mpv-webp-generator

## Features

- Export the currently set A-B loop as an animated WebP or AVIF.
- Output resolution, quality, and encoding options are configurable.
- Supports embedded and external subtitles. (Tested with SRT and ASS subtitles)
- Output files are automatically named and saved to your desktop (Windows) or home directory (Linux) by default.

## Requirements

- [mpv media player](https://mpv.io/)
- [FFmpeg](https://ffmpeg.org/)

### Quick Install (using [Scoop](https://scoop.sh/), Windows only)

On Windows, you can easily install mpv and FFmpeg using [Scoop](https://scoop.sh/):

```powershell
scoop install mpv ffmpeg
```

## Installation

1. Download the appropriate script for your platform:
   - **Windows:** `mpv-webp.lua`
   - **Linux:** `mpv-webp-linux.lua`
2. Place the script in your `scripts` directory:
   - **Windows:** `%APPDATA%\mpv\scripts\`
   - If you installed mpv with Scoop (Windows), the path is usually:  
     `C:\Users\<YourUser>\scoop\apps\mpv\current\portable_config\scripts\`
   - **Linux:** `~/.config/mpv/scripts/`
3. Ensure [FFmpeg](https://ffmpeg.org/) is installed and available in your system PATH.
   - Or edit the `ffmpeg_path` option to point to your FFmpeg executable.

## Usage

1. **Set the A-B loop** in mpv to mark the start (A) and end (B) of the segment you want to export.
   - Use `l` to set point A and `l` again to set point B (default mpv key binding for A-B loop).
2. Press **Ctrl+w** to generate an animated WebP.
3. Press **Alt+w** to generate an animated AVIF.

A small dot will appear in the top-right corner while the export is in progress. The resulting file will be saved to your desktop (Windows) or home directory (Linux), or the directory set in the script options.

## Options

You can configure these options in the `webp.conf` file located in your `script-opts` directory:

```ini
ffmpeg_path=ffmpeg         # Path to ffmpeg executable
dir=~~desktop/             # Output directory (default: desktop on Windows, ~ on Linux)
libplacebo=no              # GPU-based libplacebo filter (yes = enable, no = disable)
rez=640                    # Output width (pixels), keeps aspect ratio
fps=0                      # 0 = use source video fps
max_fps=0                  # Maximum output frame rate，0 = no limit
loop=0                     # Animation loop count (0 = infinite)
lossless=0                 # WebP: 0=lossy, 1=lossless
quality=90                 # WebP: 0-100 (higher = better quality)
compression_level=5        # WebP: 0-6 (higher = smaller size, slower)
avif_quality=30            # AVIF: CRF value (lower = better quality)
avif_preset=3              # AVIF: encoding preset, 0-13 (lower is higher quality and slower)
```

### libplacebo Option Explained

`libplacebo=yes`: Enables libplacebo filter in FFmpeg, which uses GPU acceleration via Vulkan. This enables advanced features such as:

  - Debanding
  - Frame interpolation (e.g., 30fps → 60fps)

  > ⚠️ **Note:** Using `libplacebo` requires hardware and driver support for Vulkan. Ensure that:
  >
  > - Your GPU supports Vulkan (most AMD, Intel, and NVIDIA GPUs released in the last 10 years do)
  > - GPU drivers with Vulkan support are properly installed on your system
  > - Your FFmpeg build includes `libplacebo` with frame_mixer support enabled and Vulkan support
  > - If you installs FFmpeg via Scoop on Windows，it already includes libplacebo support.
  > - On Linux, you can download static-built FFmpeg which includes libplacebo from here: 
      https://github.com/yt-dlp/FFmpeg-Builds/releases/tag/latest

**Example config file locations:**  
- Windows: `%APPDATA%\mpv\script-opts\webp.conf`  
- Scoop: `C:\Users\<YourUser>\scoop\apps\mpv\current\portable_config\script-opts\webp.conf`
- Linux: `~/.config/mpv/script-opts/webp.conf`

You can change the default hotkeys by editing your `input.conf` file.  
To do this:

1. Find your `input.conf` file:  
   - **Windows:** `%APPDATA%\mpv\input.conf`
   - **Scoop:** `C:\Users\<YourUser>\scoop\apps\mpv\current\portable_config\input.conf`  
   - **Linux:** `~/.config/mpv/input.conf`
2. Add or modify the following lines:

```
Ctrl+w script-binding make_webp_from_abloop
Alt+w script-binding make_avif_from_abloop
```

This allows you to customize the hotkeys for generating webp and avif to any key combination you prefer.  
See [mpv input.conf documentation](https://mpv.io/manual/master/#input-conf) for more details.

## Known Issues

- After closing mpv, any running ffmpeg processes started by this script will **not** automatically exit.
- If ffmpeg hangs or gets stuck, you will need to manually kill any running `ffmpeg` process.