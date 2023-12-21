#!/bin/bash

read -p "Enter the video link: " video_link

if [ -z "$video_link" ]; then
    echo "Error: No video link provided. Exiting."
    exit 1
fi

cd ./raw
yt_dlp_command="yt-dlp --all-subs --no-check-certificate --extractor-args crunchyrollbeta:hardsub=none -f b --cookies ./cookies-crunchyroll-com.txt $video_link"

eval "$yt_dlp_command"

#Makes series folder 
for file in *.mp4; do
  series_folder=$(echo "$file" | grep -oP ".*(Season \d).")
  mkdir ../output/"$series_folder"
done

# Renames .mp4 and moves to Series folder
  for file in *.mp4; do
    mv "$file" ./"$random_folder"
    cd ./"$random_folder"
    if [[ $file =~ \(Season\ ([0-9]+)\) ]]; then
        perl-rename 's/(.+?) \(Season (\d+)\) Episode (\d+) – (.+) \[.*\]\.mp4/sprintf("%s - S%02dE%02d ⌊%s⌉.mp4", $1, $2, $3, $4)/e' *.mp4
    elif [[ $file =~ Episode\ ([0-9]+) ]]; then
        perl-rename 's/(.+?) Episode (\d+) – (.+?)(?: \[.*\])?\.mp4/sprintf("%s - S01E%02d ⌊%s⌉.mp4", $1, $2, $3)/e' *.mp4
    fi

    for file in *.mp4; do
        #ffmpeg -i "$file" -c:v libx265 -crf 20 -c:a copy ../output/"$series_folder"/"${file%.*}.mkv"
        rm "$file"
    cd ..
    done

# Rename .ass files to only the last five characters and add S##E## from the mp4 filename
find ./ -maxdepth 1 -type f -name "*.ass" -exec sed -i '/Original Script:/d' {} \;
random_folder=".temp_$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 8)"
    mkdir -p "$random_folder"

for file in *.ass; do
    id_lang_code=$(echo "$file" | awk -F'[".]' '{print $(NF-1)}')
    remove_lang_code=$(echo "$file" | sed 's/\(\.[a-z]\{2\}-[^.]*\)\(\.\)/\2/')

    # Moves the file to random folder and also removes language code
    mv "$file" ./"$random_folder"/"$remove_lang_code"
    cd ./"$random_folder"

    # Rename the file using rename and capture the output
    if [[ $remove_lang_code =~ \(Season\ ([0-9]+)\) ]]; then
        perl-rename 's/(.+?) \(Season (\d+)\) Episode (\d+) – (.+) \[.*\]\.ass/sprintf("%s - S%02dE%02d ⌊%s⌉.ass", $1, $2, $3, $4)/e' *.ass
    elif [[ $remove_lang_code =~ Episode\ ([0-9]+)]]; then
        perl-rename 's/(.+?) Episode (\d+) – (.+) \[.*\]\.ass/sprintf("%s - S01E%02d ⌊%s⌉.ass", $1, $2, $3)/e' *.ass
    fi

    test_name=$(ls *.ass)

    # Add "_sub_" and the language code before the file extension
    new_name="${test_name%.ass} sub ${id_lang_code}.ass"
    mv "$test_name" ../../output/"$series_folder"/"$new_name"
    cd ..
done

rm -r "$random_folder"
