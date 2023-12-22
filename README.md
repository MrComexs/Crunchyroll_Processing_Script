# Crunchyroll\_Processing\_Script
This is a bash script that automates the process of ripping an anime from Crunchyroll. This is what is does. This only works on linux.
- Downloads anime using yt-dlp with preset setting
- Converts Crunchyroll's mp4 h.264 anime into mkv h.265
- automaticly makes Season folder `Title - S01`
- Renames video files in this format `Title - S01E01 ⌊Title of Episode⌉.mkv`
- Removes the `Original Script:` line from subtitles files do to subtitle scaling bug with VLC
- Renames subtitles files in this format `Title - S01E01 ⌊Title of Episode⌉ sub en-US.mkv`
## Feature that are in development
- support multiple Downloads in one script session by adding it to download\_list.txt `v1.1`
- browser select for cookies pass though `v1.1`
- automate video and subtitle merging uising mkvmerge `v2.0`
- support playlist
## Installation and usage
1. install dependencies
- firefox or chrome
- yt-dlp
- ffmpeg
- perl-rename
<!-- mkvmerge `v2.0`-->
2. Download the the main.sh from the [Release page](https://github.com/MrComexs/Crunchyroll_Processing_Script/releases).
- or `git clone` repo
3. Run script
```bash
bash main.sh
```
4. Insert Crunchyroll link
## Features wish list
- more features
