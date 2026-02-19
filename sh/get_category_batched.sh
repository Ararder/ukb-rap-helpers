#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: ./extract.sh <category_id>"
    exit 1
fi

BATCH_SIZE=${2:-50}  # Optional second argument, default 50 fields per batch

Rscript get_data.R "$1"

DATASET=$(dx find data --name "app*.dataset" --brief | head -n 1)

if [ -z "$DATASET" ]; then
    echo "Error: No dataset found"
    exit 1
fi

dx extract_dataset "$DATASET" --list-fields | awk '{print $1}' > available_fields.txt

# Match field IDs to available fields (with instances)
FIELDS=$(while read -r fid; do
    grep "participant\.p${fid}_" available_fields.txt || grep "^participant\.p${fid}$" available_fields.txt
done < selected_fields.txt | sort -u)

rm available_fields.txt

if [ -z "$FIELDS" ]; then
    echo "Error: No matching fields found for category $1"
    exit 1
fi

FIELD_COUNT=$(echo "$FIELDS" | wc -l)
echo "Found $FIELD_COUNT fields for category $1"

# Split fields into batches
echo "$FIELDS" | split -l "$BATCH_SIZE" - /tmp/cat${1}_batch_

BATCH=1
BATCH_FILES=""

for f in /tmp/cat${1}_batch_*; do
    BATCH_FIELDS=$(paste -sd, "$f")
    OUTPUT_FILE="/home/rstudio-server/category_${1}_batch${BATCH}.csv"
    
    echo "Extracting batch $BATCH..."
    dx extract_dataset "$DATASET" \
       --fields "participant.eid,$BATCH_FIELDS" \
       --output "$OUTPUT_FILE"
    
    BATCH_FILES="$BATCH_FILES $OUTPUT_FILE"
    BATCH=$((BATCH + 1))
    rm "$f"
done

echo "Extraction complete: $((BATCH - 1)) batches created"

# Optional: merge batches into single file
if [ $((BATCH - 1)) -gt 1 ]; then
    echo "Merging batches..."
    FIRST=true
    for bf in $BATCH_FILES; do
        if $FIRST; then
            cp "$bf" "/home/rstudio-server/category_$1.csv"
            FIRST=false
        else
            # Join on eid column (assumes eid is first column, files are sorted)
            paste -d, "/home/rstudio-server/category_$1.csv" <(cut -d, -f2- "$bf") > /tmp/merged.csv
            mv /tmp/merged.csv "/home/rstudio-server/category_$1.csv"
        fi
    done
    echo "Merged file: /home/rstudio-server/category_$1.csv"
    rm $BATCH_FILES
else
    mv "$BATCH_FILES" "/home/rstudio-server/category_$1.csv"
    echo "Single batch: /home/rstudio-server/category_$1.csv"
fi