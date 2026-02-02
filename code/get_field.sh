#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: ./extract.sh <field_id>"
    exit 1
fi

DATASET=$(dx find data --name "app*.dataset" --brief | head -n 1)

FIELDS=$(dx extract_dataset "$DATASET" --list-fields | awk '{print $1}' | grep -E "participant\.p$1_|^participant\.p$1$" | paste -sd,)

if [ -z "$FIELDS" ]; then
    echo "Error: No fields found for field ID $1"
    exit 1
fi

dx extract_dataset "$DATASET" \
   --fields "participant.eid,$FIELDS" \
   --output "/home/rstudio-server/field_$1.csv"