#!/bin/bash

echo -n "search manga: "
read manga_name 
# echo "you searched for: $manga_name"

encoded=$(echo $manga_name | sed -e 's/ /%20/g')
filter="&sort=Best%20Match&order=Ascending&official=Any&anime=Any&adult=Any&display_mode=Full%20Display"
url="https://weebcentral.com/search/data?author=&text=$encoded$filter"

rm -r .data/
mkdir -p .data/coverimgs

# Manga links
# filter="grep https://weebcentral.com/series/ | grep -v class"
# linkFilter="tr '\"' ' ' | awk '{print $3}'"
curl -s $url | grep https://weebcentral.com/series/ | grep -v class | tr '"' ' ' | awk '{print $3}' > .data/searchlinks.txt

# create cover image links:
cat .data/searchlinks.txt | tr '/' ' ' | awk '{print "https://temp.compsci88.com/cover/normal/"$4".webp"}' > .data/coverlinks.txt 

# Manga Cover
# dont forget to implement wait
xargs -n 1 -P 10 curl -s -O --output-dir .data/coverimgs/ < .data/coverlinks.txt 
# echo downloaded cover links
# sleep 2
# while read url; do
#     curl -O --output-dir coverimgs/ "$url" &
# done < coverlinks.txt
# wait  # Waits for all background jobs to complete
# echo "got em!"


# view Cover
# feh --action "echo %f; pkill -P $$" coverimgs/*
hash=$(feh --action "echo %f; kill \$PPID" .data/coverimgs/* | sed 's/.data\/\|coverimgs\/\|.webp//g')
# echo "$hash"
# go to the selected manga 
curl -s $(grep $hash .data/searchlinks.txt) > .data/$hash.html
# works fine upto this




############################
# needs rework
############################
# cat $hash.html | grep "last_read_chapter\|Chapter "| sed 's/<span class="">\|<\/span>\|<span class="flex gap-1 items-center link-info" x-show="last_read_chapter ===\|">//g' | grep -v class | sed "s/'//g" | paste -d ' ' - - > chapters.txt

# grab starting hash
firstHash=$(cat .data/$hash.html | grep "last_read_chapter" | sed 's/<span class="flex gap-1 items-center link-info" x-show="last_read_chapter ===\|">//g' | sed "s/'//g" | tail -n1 | awk '{print $1}')

# echo $firstHash

# curl https://weebcentral.com/series/$firstHash/chapter-select?current_chapter=$firstHash > .data/chapters.html

# curl https://weebcentral.com/series/$firstHash/chapter-select?current_chapter=$firstHash > .data/chapters.html

# cat .data/chapters.html | sed 's/<a href="\|class="w-full btn bg-base-200">\|<\/a>//g'| sed 's/"//g' > .data/chapters.txt 

# sed "s|<button id=selected_chapter class=w-full btn bg-base-300>|https://weebcentral.com/chapters/$firstHash |g" .data/chapters.txt | sed 's|</button>||g'| grep http > .data/chapterlinks.txt
#
# selected_chap=$(awk '{print $2 " " $3}' .data/chapterlinks.txt |sort -k2 -n | dmenu)
# chapter_link=$(grep -w "$selected_chap" .data/chapterlinks.txt | awk '{print $1}')
# imagelink=$(curl $chapter_link  | grep https://hot.planeptune.us | sed 's/" as="image">\|<link rel="preload" href="//g')

############################


#### AS OF NOW USE THIS ######
# firstChapter="https://weebcentral.com/chapters/$firstHash"
curl -s "https://weebcentral.com/chapters/$firstHash" > .data/firstchapter.html
imagelink=$(grep png .data/firstchapter.html | sed 's/<link rel="preload" href="\|" as="image">//g' | grep planeptune)

echo image link: $imagelink
# read -p "wanna download from the chapter u seleted??"
# echo either way im gonna download, cuz code is incomplete
./dl.sh $imagelink 

