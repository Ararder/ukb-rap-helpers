#!/bin/bash

# Extract UKB fields in batches of 10, then column-bind into a single CSV
# Usage: ./get_fields_batched.sh <field_id1> [field_id2] [field_id3] ...
# Example: ./get_fields_batched.sh 21001 31 34 50 20116 20510 22006 22001 22020 22027 22019

if [ $# -eq 0 ]; then
    echo "Usage: ./get_fields_batched.sh <field_id1> [field_id2] ..."
    exit 1
fi

BATCH_SIZE=10

DATASET=$(dx find data --name "app*.dataset" --brief | head -n 1)

if [ -z "$DATASET" ]; then
    echo "Error: No dataset found"
    exit 1
fi

# Build field list for all requested field IDs
ALL_FIELDS=""
for FIELD_ID in "$@"; do
    MATCHED=$(dx extract_dataset "$DATASET" --list-fields | \
              awk '{print $1}' | \
              grep -E "participant\.p${FIELD_ID}_|^participant\.p${FIELD_ID}$")

    if [ -z "$MATCHED" ]; then
        echo "Warning: No fields found for field ID $FIELD_ID"
    else
        if [ -z "$ALL_FIELDS" ]; then
            ALL_FIELDS="$MATCHED"
        else
            ALL_FIELDS="$ALL_FIELDS"$'\n'"$MATCHED"
        fi
    fi
done

if [ -z "$ALL_FIELDS" ]; then
    echo "Error: No valid fields found for any input"
    exit 1
fi

FIELD_COUNT=$(echo "$ALL_FIELDS" | wc -l)
echo "Found $FIELD_COUNT matched fields"

# Split fields into batches
echo "$ALL_FIELDS" | split -l "$BATCH_SIZE" - /tmp/fields_batch_

BATCH=1
BATCH_FILES=""
OUTPUT_NAME="field_$(echo "$@" | tr ' ' '_').csv"

for f in /tmp/fields_batch_*; do
    BATCH_FIELDS=$(paste -sd, "$f")
    OUTPUT_FILE="/home/rstudio-server/fields_batch${BATCH}.csv"

    echo "Extracting batch $BATCH..."
    dx extract_dataset "$DATASET" \
       --fields "participant.eid,$BATCH_FIELDS" \
       --output "$OUTPUT_FILE"

    BATCH_FILES="$BATCH_FILES $OUTPUT_FILE"
    BATCH=$((BATCH + 1))
    rm "$f"
done

echo "Extraction complete: $((BATCH - 1)) batches"

# Join batches on participant.eid — avoids row-order assumptions from paste
MERGED="/home/rstudio-server/$OUTPUT_NAME"

python3 - <<PYEOF "$MERGED" $BATCH_FILES
import sys, pandas as pd
out, *files = sys.argv[1:]
dfs = [pd.read_csv(f) for f in files]
merged = dfs[0]
for df in dfs[1:]:
    merged = merged.merge(df, on="participant.eid", how="inner")
merged.to_csv(out, index=False)
print(f"Extracted to: {out}")
PYEOF

# Uncomment to remove batch files after merge:
rm $BATCH_FILES
