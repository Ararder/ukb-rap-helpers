# 1. Define the correctly formatted fields
FIELDS="participant.eid,participant.p31,participant.p22001,participant.p22006,participant.p22019,participant.p22020,participant.p22027"

# 2. Grab dataset and extract
DS=$(dx find data --name "app*.dataset" --brief | head -n 1)
dx extract_dataset $DS --fields "$FIELDS" --output "/home/rstudio-server/qc_metadata.csv"