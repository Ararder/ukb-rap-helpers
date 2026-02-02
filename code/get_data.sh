#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: ./extract.sh <category_id>"
    exit 1
fi

Rscript get_data.R $1
DATASET=$(dx find data --name "app*.dataset" --brief | head -n 1)
dx extract_dataset "$DATASET" --list-fields | awk '{print $1}' > available_fields.txt
# FIELDS=$(paste -sd, selected_fields.txt)

# Match field IDs to available fields (with instances)
FIELDS=$(while read -r fid; do
    grep "participant.p${fid}_" available_fields.txt || grep "^participant.p${fid}$" available_fields.txt
done < selected_fields.txt | sort -u | paste -sd,)

rm available_fields.txt

dx extract_dataset "$DATASET" \
   --fields "participant.eid,$FIELDS" \
   --output "/home/rstudio-server/category_$1.csv"
