# mpv-webp-avif-generator

[English README](README.md)

一个 [mpv](https://mpv.io/) 用户脚本，可以快速将任意视频选取片段导出为动画 **WebP** 或 **AVIF**，依赖 [FFmpeg](https://ffmpeg.org/)。

![sample](./少女革命ウテナ.アドゥレセンス黙示録.avif)

> **注意：** 本脚本现已支持 **Windows** 和 **Linux**。  
> macOS 我没有测试环境，欢迎 PR！

> **致谢原作者：** https://github.com/DonCanjas/mpv-webp-generator

## 功能

- 将当前设置的 A-B 循环导出为动画 WebP 或 AVIF。
- 输出分辨率、质量、编码参数可配置。
- 支持内嵌和外挂字幕。（已测试 SRT 和 ASS 字幕）
- 输出文件自动命名，默认保存到桌面（Windows）或用户主目录（Linux）。

## 依赖

- [mpv 播放器](https://mpv.io/)
- [FFmpeg](https://ffmpeg.org/)

### Windows 快速安装（推荐用 [Scoop](https://scoop.sh/)）

在 Windows 下，可以用 [Scoop](https://scoop.sh/) 一键安装依赖：

```powershell
scoop install mpv ffmpeg
```

## 安装

1. 下载脚本：[mpv-webp.lua](./mpv-webp.lua)
2. 把脚本放到 mpv 的 `scripts` 目录下：
   - **Windows:** `%APPDATA%\mpv\scripts\`
   - 如果你用 Scoop 安装 mpv，路径一般是：  
     `C:\Users\<你的用户名>\scoop\apps\mpv\current\portable_config\scripts\`
   - **Linux:** `~/.config/mpv/scripts/`
3. 确保 [FFmpeg](https://ffmpeg.org/) 已安装并加入系统 PATH。  
   或在配置文件中设置 `ffmpeg_path` 为 FFmpeg 的完整路径。

## 使用方法

1. **在 mpv 里用 `l` 键设置 A-B 循环**，A 为起点，B 为终点（`l` 是 mpv 默认的 A-B 循环按键）。
2. 按 **Ctrl+w** 导出动画 WebP。
3. 按 **Alt+w** 导出动画 AVIF。

导出时右上角会出现一个小圆点，导出完成后文件会自动保存到桌面（Windows）或主目录（Linux），或你设置的目录。

## 配置

在 `script-opts` 目录下新建或编辑 `webp.conf` 文件，配置参数：

```ini
ffmpeg_path=ffmpeg         # ffmpeg 可执行文件路径
dir=~~desktop/             # 输出目录（Windows 默认桌面，Linux 默认主目录）
libplacebo=no              # 是否启用 libplacebo 滤镜（yes = 启用，no = 禁用）
rez=640                    # 输出宽度（像素），自动保持比例
fps=0                      # 0 = 使用源视频帧率
max_fps=0                  # 最大输出帧率（0=不限制）
loop=0                     # 动画循环次数（0=无限循环）
lossless=0                 # WebP: 0=有损，1=无损
quality=90                 # WebP: 0-100（越高越清晰）
compression_level=5        # WebP: 0-6（越高体积越小，速度越慢）
avif_quality=30            # AVIF: CRF 数值（越低越清晰）
avif_preset=3              # AVIF: -preset 参数，0-13，数值越低质量越高但速度越慢
```
### libplacebo 选项说明

`libplacebo=yes`：启用 FFmpeg 中的 libplacebo 滤镜，它支持高级功能，例如：

- 去色带（Debanding）
- 帧率插值（例如：30fps → 60fps）

⚠️ 注意：使用 libplacebo 请确保：

- 你的 FFmpeg 构建版本包含启用了 frame_mixer 支持的 libplacebo，并且支持 Vulkan
- 如果你在 Windows 上通过 Scoop 安装 FFmpeg，它已经包含 libplacebo 支持。
- 在 Linux 上，你可以从以下链接下载包含 libplacebo 的静态构建版本 FFmpeg：
  👉 [https://github.com/yt-dlp/FFmpeg-Builds/releases/tag/latest](https://github.com/yt-dlp/FFmpeg-Builds/releases/tag/latest)

**示例配置文件路径：**  
- Windows: `%APPDATA%\mpv\script-opts\webp.conf`  
- Scoop: `C:\Users\<你的用户名>\scoop\apps\mpv\current\portable_config\script-opts\webp.conf`
- Linux: `~/.config/mpv/script-opts/webp.conf`

## 更改快捷键

你可以通过编辑 `input.conf` 文件自定义快捷键：

1. 找到你的 `input.conf` 文件：  
   - **Windows:** `%APPDATA%\mpv\input.conf`（默认）或 `C:\Users\<你的用户名>\scoop\apps\mpv\current\portable_config\input.conf`（Scoop 安装）
   - **Linux:** `~/.config/mpv/input.conf`
2. 添加或修改如下内容：

```
Ctrl+w script-binding make_webp_from_abloop
Alt+w script-binding make_avif_from_abloop
```

这样就可以把生成 webp 和 avif 的快捷键自定义为你喜欢的按键组合。  
更多用法请参考 [mpv input.conf 文档](https://mpv.io/manual/master/#input-conf)。

## 已知问题

- 关闭 mpv 后，脚本启动的 ffmpeg 进程不会自动退出。
- 如果 ffmpeg 卡住，需要手动结束正在运行的 `ffmpeg` 进程。