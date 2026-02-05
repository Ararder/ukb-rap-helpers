DS=$(dx find data --name "app*.dataset" --brief | head -n 1)
FIELDS=$(dx extract_dataset $DS --list-fields | grep "p20002" | awk '{print $1}' | paste -sd "," -)




# SEL_FIELDS=$(echo "$FIELDS" | tr ',' '\n' | grep "_i0_" | paste -sd,)
# 
# dx extract_dataset $DS --fields "participant.eid,$SEL_FIELDS" --output "/home/rstudio-server/f20002_all.csv"

SEL_FIELDS=$(echo "$FIELDS" | tr ',' '\n' | grep "_i0_")

echo "$SEL_FIELDS" | split -l 15 - /tmp/batch_

BATCH=1
for f in /tmp/batch_*; do
    BATCH_FIELDS=$(paste -sd, "$f")
    dx extract_dataset "$DS" \
       --fields "participant.eid,$BATCH_FIELDS" \
       --output "/home/rstudio-server/f20002_batch${BATCH}.csv"
    BATCH=$((BATCH + 1))
    rm "$f"
done