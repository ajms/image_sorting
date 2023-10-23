#!/bin/bash
process_image() {
    local original_file="$1"
    local source_dir="$2"
    local destination_dir="$3"
    local filename="$(basename "$original_file")"
    local date_pattern="[0-9]{8}"
    local min_size="$4"

    # Early return if the file is smaller than min_size
    if [ $(identify -format "%w" "$original_file") -lt "$min_size" ] || [ $(identify -format "%h" "$original_file") -lt "$min_size" ]; then
        return 0
    fi

    if [[ "$filename" =~ $date_pattern ]]; then
        # Extract the first occurrence of "YYYYMMDD" pattern from the filename
        local matched_date
        matched_date=$(echo "$filename" | grep -oE '[0-9]{8}' | head -n 1)
    else
        matched_date="00000000"
    fi

    if (( 10#${matched_date:0:4} >= 2000 && 10#${matched_date:0:4} <= 2023 && 10#${matched_date:4:2} >= 1 && 10#${matched_date:4:2} <= 12 && 10#${matched_date:6:2} >= 1 && 10#${matched_date:6:2} <= 31 )); then
        local yearmonth="$destination_dir/${matched_date:0:6}"
        local file_prefix="$matched_date"
    else
        local yearmonth="$destination_dir/$(date -r "$original_file" "+%Y%m")"
        local file_prefix=$(date -r "$original_file" "+%Y%m%d_%H%M%S")
    fi

    mkdir -p "$yearmonth"
    local destination_file="$yearmonth/$file_prefix_$(basename "$original_file")"
    echo "Copying: $original_file to $destination_file"
    cp "$original_file" "$destination_file"
}


export -f process_image

# Set the source and destination directories
source_dir="$1"
destination_dir="$2"

# Set the minimum image size (width and height)
min_size=640

# Create the destination directory if it doesn't exist
echo "COPYING FROM $source_dir -> $destination_dir"
mkdir -p "$destination_dir"

# process_image /home/albert/Pictures/Backup_Handy/20210220_Moto5/Android/data/org.telegram.messenger/cache/257908565_24224.jpg $source_dir $destination_dir $min_size
find "$source_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) -exec bash -c "process_image \"{}\" \"$source_dir\" \"$destination_dir\" $min_size" \;
