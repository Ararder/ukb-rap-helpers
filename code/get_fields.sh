#!/bin/bash
if [ $# -eq 0 ]; then
    echo "Usage: ./extract.sh <field_id1> [field_id2] [field_id3] ..."
    echo "Example: ./extract.sh 21001 31 34"
    exit 1
fi

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

# Convert to comma-separated, prepend eid
FIELDS_CSV=$(echo "$ALL_FIELDS" | paste -sd,)
OUTPUT_NAME="field_$(echo "$@" | tr ' ' '_').csv"

dx extract_dataset "$DATASET" \
   --fields "participant.eid,$FIELDS_CSV" \
   --output "/home/rstudio-server/$OUTPUT_NAME"

echo "Extracted to: /home/rstudio-server/$OUTPUT_NAME"