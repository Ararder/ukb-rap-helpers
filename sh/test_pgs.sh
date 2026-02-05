#!/bin/bash

# Test the PGS pipeline on chromosome 21 only
# Creates a dummy score file with known chr21 variants, runs scoring, and checks output
# Usage: ./test_pgs.sh

set -euo pipefail

OUTDIR="/home/rstudio-server"
OUT_PREFIX="test_pgs"
PLINK2="/home/rstudio-server/plink2"
BGEN_DIR="/mnt/project/Bulk/Imputation/UKB imputation from genotype"
BGEN_PATH="${BGEN_DIR}/ukb22828_c21_b0_v3"
SCORE_FILE="${OUTDIR}/test_score_chr21.tsv"

# --- Validation ---

if [ ! -x "$PLINK2" ]; then
    echo "Error: plink2 not found at $PLINK2"
    echo "Download it with: sh/download_plink2.sh"
    exit 1
fi

if [ ! -f "${BGEN_PATH}.bgen" ]; then
    echo "Error: chr21 BGEN not found — are you running on the RAP?"
    exit 1
fi

# --- Create dummy score file with common chr21 variants ---

cat > "$SCORE_FILE" <<'EOF'
SNP	A1	WEIGHT
rs2823093	G	0.05
rs2835246	T	-0.03
rs9982601	C	0.08
rs757081	A	0.02
rs2834440	G	-0.01
EOF

echo "Created test score file: $SCORE_FILE"

# --- Run plink2 on chr21 ---

echo "Scoring chromosome 21..."
$PLINK2 --bgen "${BGEN_PATH}.bgen" ref-first \
    --sample "${BGEN_PATH}.sample" \
    --lax-bgen-import \
    --score "$SCORE_FILE" 1 2 3 header cols=+scoresums \
    --out "${OUTDIR}/${OUT_PREFIX}_chr21"

if [ $? -ne 0 ]; then
    echo "FAIL: plink2 scoring failed"
    exit 1
fi

# --- Check output ---

SSCORE="${OUTDIR}/${OUT_PREFIX}_chr21.sscore"

if [ ! -f "$SSCORE" ]; then
    echo "FAIL: output file not created: $SSCORE"
    exit 1
fi

N_LINES=$(wc -l < "$SSCORE")
N_COLS=$(head -1 "$SSCORE" | awk '{print NF}')

echo "Output: $SSCORE"
echo "  Lines: $N_LINES (including header)"
echo "  Columns: $N_COLS"
echo "  Header: $(head -1 "$SSCORE")"
echo "  First 3 rows:"
head -4 "$SSCORE" | tail -3

if [ "$N_LINES" -lt 2 ]; then
    echo "FAIL: output file is empty"
    exit 1
fi

# --- Test the awk aggregation step (single chromosome, so output ≈ input) ---

echo ""
echo "Testing aggregation step..."
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
    }' "$SSCORE" > "${OUTDIR}/${OUT_PREFIX}.sscore"

COMBINED="${OUTDIR}/${OUT_PREFIX}.sscore"
N_COMBINED=$(wc -l < "$COMBINED")

echo "Combined output: $COMBINED"
echo "  Lines: $N_COMBINED (including header)"
echo "  First 3 rows:"
head -4 "$COMBINED" | tail -3

if [ "$N_COMBINED" -lt 2 ]; then
    echo "FAIL: combined output is empty"
    exit 1
fi

echo ""
echo "PASS: chr21 test completed successfully"

# Uncomment to clean up test files:
# rm "$SCORE_FILE" "$SSCORE" "${OUTDIR}/${OUT_PREFIX}_chr21.log" "$COMBINED"
