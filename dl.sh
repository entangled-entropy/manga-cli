#!/bin/bash

echo -e "scrapper for https://weebcentral.com/"
# Check if a URL is supplied
if [ "$#" -ne 1 ]; then
    echo -e "\nUsage: $0 <url>"
    echo -e "just go and grab an image link from the chapter u wanna download"
    echo -e "\nExample: \n./manga.sh https://hot.planeptune.us/manga/One-Piece/0001-001.png"
    echo -e "will download from that chapter u pasted to end of the manga"
    exit 1
fi

url=$1

# Directory to save the images
base_dir="$HOME/Downloads/Manga"
base_url="$(dirname "$url")"

echo Downloading in $base_dir ...
# Extract anime name and chapter
anime="$(dirname "$url" | sed 's/manga\// /g' | awk '{print $2}')"
chapter=$(echo "$url" | grep -oP '\K\d{4}' | head -1)

########################
# opening ranger to read
########################
st ranger $base_dir/$anime &

# Create the directory for the anime and chapter
chapter_dir="$base_dir/$anime/chapter_$chapter"
mkdir -p "$chapter_dir"

# Initialize image number
image=1

while true; do
    # Create an array to hold the background processes
    pids=()
    # Create an array to hold the files to be checked
    files_to_check=()

    # Download images in batches
    for ((i=0; i<20; i++)); do
        # Format the image number with leading zeros
        formatted_image=$(awk "BEGIN {printf \"%03d\", $image}")
        full_url="$base_url/$chapter-$formatted_image.png"
        save="$chapter_dir/$formatted_image.png"

        # Download the image using curl in the background
        curl -s "$full_url" -o "$save" &
        pids+=($!)  # Store the PID of the background process
        files_to_check+=("$save")  # Store the file path for checking later

        # Increment the image number
        image=$((image + 1))
    done

    # Wait for all background downloads to complete
    for pid in "${pids[@]}"; do
        wait "$pid"
    done

    # Check the file type of the downloaded images
    html_files=()  # Array to hold HTML files
    for file in "${files_to_check[@]}"; do
        file_type=$(file --mime-type -b "$file")
        if [[ $file_type == text/html ]]; then
            # echo "Encountered HTML at file $file. Marking it for removal."
            html_files+=("$file")  # Add HTML file to the removal list
        fi
    done

    # Remove all HTML files
    if [[ ${#html_files[@]} -gt 0 ]]; then
        # echo "Removing HTML files:"
        for html_file in "${html_files[@]}"; do
            # echo "Removing $html_file"
            rm -f "$html_file"  # Remove the HTML file
        done
    fi

    # Check if any HTML files were found
    if [[ ${#html_files[@]} -gt 0 ]]; then
        # Move to the next chapter
        chapter="$(awk "BEGIN {printf \"%04d\", $((10#$chapter + 1))}")"

        chapter_dir="$base_dir/$anime/chapter_$chapter"
        mkdir -p "$chapter_dir"
        image=1  # Reset image number

        formatted_image=$(awk "BEGIN {printf \"%03d\", $image}")
        full_url="$base_url/$chapter-$formatted_image.png"
        save="$chapter_dir/$formatted_image.png"

        # Download the first image of the new chapter
        curl -s "$full_url" -o "$save"
        
        # Check if the first image of the new chapter is HTML
        if [[ $? -ne 0 || ! -f "$save" ]]; then
            echo "Failed to download first image of chapter $chapter. Exiting."
            exit 1
        fi

        file_type=$(file --mime-type -b "$save")
        if [[ $file_type == text/html ]]; then
            echo "First image of chapter $chapter is HTML. Exiting."
            exit 1
        fi
    fi
done

