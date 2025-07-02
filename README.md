# mpv-webp-avif-generator

[中文说明](README-CN.md)

A [mpv](https://mpv.io/) user script to quickly generate animated **WebP** or **AVIF** clips from any video segment using [FFmpeg](https://ffmpeg.org/).

![sample](./少女革命ウテナ.アドゥレセンス黙示録.avif)

> **Note:** This script is intended for **Windows**.  
> Support for Linux/Mac is not difficult to add, but I do not have an environment to test.  PRs are welcome!

> **Thanks to the original author:** https://github.com/DonCanjas/mpv-webp-generator

## Features

- Export the currently set A-B loop as an animated WebP or AVIF.
- Output resolution, quality, and encoding options are configurable.
- Supports embedded and external subtitles. (Only tested with SRT and ASS subtitles)
- Output files are automatically named and saved to your desktop (by default).

## Requirements

- [mpv media player](https://mpv.io/)
- [FFmpeg](https://ffmpeg.org/)

### Quick Install (using [Scoop](https://scoop.sh/))

On Windows, you can easily install mpv and FFmpeg using [Scoop](https://scoop.sh/):

```powershell
scoop install mpv ffmpeg
```

## Installation

1. Download `mpv-webp.lua` and place it in your `scripts` directory:
   - Windows: `%APPDATA%\mpv\scripts\`
   - If you installed mpv with Scoop, the path is usually: 

     `C:\Users\<YourUser>\scoop\apps\mpv\current\portable_config\scripts\`

2. Ensure [FFmpeg](https://ffmpeg.org/) is installed and available in your system PATH.
   - Or edit the `ffmpeg_path` option in the script to point to your FFmpeg executable.

## Usage

1. **Set the A-B loop** in mpv to mark the start (A) and end (B) of the segment you want to export.
   - Use `l` to set point A and `l` again to set point B (default mpv key binding for A-B loop).
2. Press **Ctrl+w** to generate an animated WebP.
3. Press **Ctrl+a** to generate an animated AVIF.

A small dot will appear in the top-right corner while the export is in progress. The resulting file will be saved to your desktop (or the directory set in the script options).

## Options

You can configure these options in the `webp.conf` file located in your `script-opts` directory:

```ini
ffmpeg_path=ffmpeg         # Path to ffmpeg executable
dir=~~desktop/             # Output directory (default: desktop)
rez=640                    # Output width (pixels), keeps aspect ratio
fps=0                      # 0 = use source video fps
lossless=0                 # WebP: 0=lossy, 1=lossless
quality=90                 # WebP: 0-100 (higher = better quality)
compression_level=5        # WebP: 0-6 (higher = smaller size, slower)
loop=0                     # WebP: animation loop count (0 = infinite)
avif_quality=30            # AVIF: CRF value (lower = better quality)
avif_preset=3              # AVIF: encoding preset, 0-13 (lower is higher quality and slower)
```
**Example path:**  
- `%APPDATA%\mpv\script-opts\webp.conf`  
- Scoop: `C:\Users\<YourUser>\scoop\apps\mpv\current\portable_config\script-opts\webp.conf`

You can change the default hotkeys by editing your `input.conf` file.  
To do this:

1. Find your `input.conf` file (usually in `%APPDATA%\mpv\input.conf` or `portable_config\input.conf`).
2. Add or modify the following lines:

```
Ctrl+w script-binding make_webp_from_abloop
Ctrl+a script-binding make_avif_from_abloop
```

This allows you to customize the hotkeys for generating webp and avif to any key combination you prefer.  
See [mpv input.conf documentation](https://mpv.io/manual/master/#input-conf) for more details.

## Known Issues

- After closing mpv, any running ffmpeg processes started by this script will **not** automatically exit.
- If ffmpeg hangs or gets stuck, you will need to manually kill any running `ffmpeg.exe` process.

