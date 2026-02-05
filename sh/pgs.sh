#!/bin/bash

# Polygenic score pipeline: runs plink2 --score across chromosomes 1-22 and combines results
# Usage: ./pgs.sh <score_file> [output_prefix]
#   score_file: 3-column file (SNP, allele, weight) with header
#   output_prefix: prefix for output files (default: pgs)

if [ -z "$1" ]; then
    echo "Usage: ./pgs.sh <score_file> [output_prefix]"
    exit 1
fi

SCORE_FILE="$1"
OUT_PREFIX="${2:-pgs}"
OUTDIR="/home/rstudio-server"
PLINK2="/home/rstudio-server/plink2"
BGEN_DIR="/mnt/project/Bulk/Imputation/UKB imputation from genotype"

# --- Validation ---

if [ ! -f "$SCORE_FILE" ]; then
    echo "Error: Score file not found: $SCORE_FILE"
    exit 1
fi

if [ ! -x "$PLINK2" ]; then
    echo "Error: plink2 not found or not executable at $PLINK2"
    echo "Download it with: sh/download_plink2.sh"
    exit 1
fi

if [ ! -f "${BGEN_DIR}/ukb22828_c22_b0_v3.bgen" ]; then
    echo "Error: BGEN genotype files not found — are you running on the RAP?"
    exit 1
fi

# --- Per-chromosome scoring ---

for CHR in $(seq 1 22); do
    BGEN_PATH="${BGEN_DIR}/ukb22828_c${CHR}_b0_v3"

    echo "Scoring chromosome ${CHR}..."
    $PLINK2 --bgen "${BGEN_PATH}.bgen" ref-first \
        --sample "${BGEN_PATH}.sample" \
        --lax-bgen-import \
        --score "$SCORE_FILE" 1 2 3 header cols=+scoresums \
        --out "${OUTDIR}/${OUT_PREFIX}_chr${CHR}"

    if [ $? -ne 0 ]; then
        echo "Warning: chromosome ${CHR} failed, skipping"
    fi
done

# --- Combine results ---

echo "Combining per-chromosome results..."
awk 'BEGIN {OFS="\t"}
    FNR == 1 {next}
    {
        key = $1 OFS $2
        allele_ct[key] += $3
        score_sum[key] += $5
    }
    END {
        print "#FID", "IID", "ALLELE_CT", "SCORE_SUM", "SCORE_AVG"
        for (key in allele_ct) {
            avg = score_sum[key] / allele_ct[key]
            print key, allele_ct[key], score_sum[key], avg
        }
    }' "${OUTDIR}/${OUT_PREFIX}"_chr*.sscore > "${OUTDIR}/${OUT_PREFIX}.sscore"

echo "Done: ${OUTDIR}/${OUT_PREFIX}.sscore"

# Uncomment to remove per-chromosome files:
# rm ${OUTDIR}/${OUT_PREFIX}_chr*.sscore ${OUTDIR}/${OUT_PREFIX}_chr*.log
