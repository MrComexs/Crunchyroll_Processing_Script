#!/bin/bash

# check if required_packages are installed
required_packages=("ffmpeg" "yt-dlp" "perl-rename" "mkvmerge")

for package in "${required_packages[@]}"; do
    if ! command -v "$package" &> /dev/null; then
        echo
        echo "Error: $package is not installed."

        read -p "Do you want to continue? (y/n): " answer
        case "$answer" in
            [yY]|[yY][eE][sS])
                echo
                ;;
            *)
                echo "Exiting the script."
                echo
                exit 1
                ;;
        esac
    fi
done

read -p "Enter the video link: " video_link

if [ -z "$video_link" ]; then
    echo "Error: No video link provided. Exiting."
    exit 1
fi

root_path=$(pwd)
raw_path="$root_path/raw"
output_path="$root_path/output"

mkdir "$output_path"
mkdir "$raw_path"
cd "$raw_path"

yt_dlp_command="yt-dlp --all-subs --no-check-certificate --extractor-args crunchyrollbeta:hardsub=none -f b --cookies-from-browser firefox --user-agent 'Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0' $video_link"

#eval "$yt_dlp_command"

random_folder=".temp_$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 8)"
mkdir -p "$random_folder"
random_folder_path="$raw_path/$random_folder"

# Make series folder 
series_folder=""
for file in *.mp4; do
    if [[ "$file" =~ Season\ ([0-9]+) ]]; then
        season_ns=${BASH_REMATCH[1]}
        new_file=$(echo "$file" | sed "s/Season $season_ns/(Season $season_ns)/")
        mv "$file" "$new_file"
    else
        # If there is no season number, default to "S01"
        season_ns="01"
    fi 

    # Ensure season_ns has leading zero if less than 10
    season_ns=$(printf "%02d" "$season_ns")

    # Extract series name until "Season #" or "Episode"
    series_name=$(echo "$file" | sed -E "s/( Season [0-9]+| Episode [0-9]+).*//i")
    
    series_folder="${series_name} S${season_ns}"
    
    echo
    echo -e "\e[1;32m$series_name\e[0m"
    echo -e "\e[1;32m$series_folder\e[0m"
    echo -e "\e[1;32m$season_ns\e[0m"
    echo
done

mkdir -p ../output/"$series_folder"
series_folder_path="$output_path"/"$series_folder"

# Process video files
for file in *.mp4; do
    cd "$raw_path"
    mv "$raw_path"/"$file" "$random_folder_path"
    cd "$random_folder_path"
    if [[ $file =~ \(Season\ ([0-9]+)\) ]]; then
        perl-rename 's/(.+?) \(Season (\d+)\) Episode (\d+) – (.+) \[.*\]\.mp4/sprintf("%s - S%02dE%02d ⌊%s⌉.mp4", $1, $2, $3, $4)/e' *.mp4
    elif [[ $file =~ Episode\ ([0-9]+) ]]; then
        perl-rename 's/(.+?) Episode (\d+) – (.+?)(?: \[.*\])?\.mp4/sprintf("%s - S01E%02d ⌊%s⌉.mp4", $1, $2, $3)/e' *.mp4
    fi

    for mp4file in *.mp4; do
        ffmpeg -i "$random_folder_path"/"$mp4file" -c:v libx265 -crf 20 -c:a copy "$series_folder_path"/"${mp4file%.*}.mkv"
        rm "$random_folder_path"/"$mp4file"
    done
done


# Rename .ass files to only the last five characters and add S##E## from the mp4 filename
cd "$raw_path"
find ./ -maxdepth 1 -type f -name "*.ass" -exec sed -i '/Original Script:/d' {} \;

for file in *.ass; do
    if [[ "$file" =~ Season\ ([0-9]+) ]]; then
        season_ns=${BASH_REMATCH[1]}
        new_file=$(echo "$file" | sed "s/Season $season_ns/(Season $season_ns)/")
        mv "$file" "$new_file"
    fi
done



for file in *.ass; do
    id_lang_code=$(echo "$file" | awk -F'[".]' '{print $(NF-1)}')
    remove_lang_code=$(echo "$file" | sed 's/\(\.[a-z]\{2\}-[^.]*\)\(\.\)/\2/')

    # Moves the file to random folder and also removes language code
    mv "$raw_path"/"$file" "$random_folder_path"/"$remove_lang_code"
    cd "$random_folder_path"

    # Rename the file using rename and capture the output
    if [[ $remove_lang_code =~ \(Season\ ([0-9]+)\) ]]; then
        perl-rename 's/(.+?) \(Season (\d+)\) Episode (\d+) – (.+) \[.*\]\.ass/sprintf("%s - S%02dE%02d ⌊%s⌉.ass", $1, $2, $3, $4)/e' *.ass
    elif [[ $remove_lang_code =~ Episode\ ([0-9]+) ]]; then
        perl-rename 's/(.+?) Episode (\d+) – (.+) \[.*\]\.ass/sprintf("%s - S01E%02d ⌊%s⌉.ass", $1, $2, $3)/e' *.ass
    fi

    test_name=$(ls *.ass)

    # Add "_sub_" and the language code before the file extension
    new_name="${test_name%.ass} sub ${id_lang_code}.ass"
    mv "$random_folder_path"/"$test_name" "$series_folder_path"/"$new_name"
done

rm -r "$random_folder_path"

 
