## Video Clip Extraction Script

This script allows you to download a specific section of a YouTube video and save it as a separate clip using `yt-dlp` and `ffmpeg`.

### Usage

Usage: `$(basename "$0") [OPTIONS]`
Options:

- `-u`, `--url` YouTube URL of the video you want to download (required)
- `-s`, `--start-time` Timecode of the start of the clip to extract in format HH:MM:SS (required)
- `-e`, `--end-time` Timecode of the end of the clip to extract in format HH:MM:SS (required)
- `-o`, `--output` Output filename for the clip (required)
- `-h`, `--help` Show this help message and exit

### Installation

Before using the script, make sure you have the following packages installed:

- `yt-dlp`
- `ffmpeg`

You can install these packages using your package manager:

For Debian/Ubuntu-based systems (using `apt`):

```bash
sudo apt update
sudo apt install yt-dlp ffmpeg
```

For Arch-based systems (using pacman):

```bash
sudo pacman -S yt-dlp ffmpeg
```

For Fedora (using yum):

```bash
sudo dnf install yt-dlp ffmpeg
```

For Windows users, you can install `yt-dlp` using `choco` (Chocolatey package manager):

```bash
choco install yt-dlp ffmpeg
```

## Examples

Download a clip from a YouTube video:

```bash
bash youtube_clip_edit.sh -u "https://www.youtube.com/watch?v=your_video_id" -s "00:02:30" -e "00:03:45" -o "output_clip.mp4"
```

This will download the video from the given URL and extract the segment between 2 minutes 30 seconds and 3 minutes 45 seconds and save it as output_clip.mp4.

## Get help

```bash
./youtube_clip_edit.sh -h
```

## Notes



The script automatically checks if `yt-dlp` and `ffmpeg` are installed and will prompt you to install any missing packages.

The time format for the start and end times should be in `HH:MM:SS` format.

Please ensure you have the necessary permissions to install packages and access the output directory.

Enjoy extracting clips from your favorite YouTube videos!
