if [ -n "$1" ]; then
    file="$1"
else
    echo -e "You must supply a file"
    exit 1
fi

# Metadata file
mdfileorig="$(mktemp)"
ffmpeg -y -i "$1" -f ffmetadata "$mdfileorig" >/dev/null 2>&1
mdfile="$(mktemp)"
cp "$mdfileorig" "$mdfile"

$EDITOR "$mdfile"
if diff -q "$mdfile" "$mdfileorig"; then
    echo "No changes detected, exiting"
    exit 0
fi

newfile="$(mktemp --suffix="$file")"
ffmpeg -y -i "$file" -i "$mdfile" -map_metadata 1 -movflags use_metadata_tags -codec copy "$newfile" >/dev/null 2>&1
mv "$newfile" "$file"
