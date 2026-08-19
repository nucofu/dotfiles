#!/bin/bash

# required dependencies
# xcolor, printf, xsel, dunst, date

# picking color
colorCode=$(xcolor -P 127 -S 6)
printf "$colorCode" | xsel --clipboard
dunstify "Copied to Clipboard" "your picked color is <span foreground='$colorCode'>$colorCode</span>."

# logging
dirloc="$HOME/.local/share/xcolor"
if [[ ! -d $dirloc ]]; then mkdir $dirloc; fi

filename="$dirloc/picked.log"
if [[ ! -f $filename ]]; then touch $filename; fi

printf "$(date "+%H:%M:%S %A, %d %B %Y") - $colorCode\n" >> $filename
