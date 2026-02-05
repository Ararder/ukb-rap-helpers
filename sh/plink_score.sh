# Assign the path (Note: No backslashes needed inside double quotes)
CHR=21
BGEN_PATH="/mnt/project/Bulk/Imputation/UKB imputation from genotype/ukb22828_c${CHR}_b0_v3"
plink2="/home/rstudio-server/plink2"

$plink2 --bgen "$BGEN_PATH" -ref-first --score chr21.tsv 1 2 3 header --out test



plink2 --bgen "$BGEN_PATH".bgen ref-first \
 --sample "$BGEN_PATH".sample \
 --lax-bgen-import \
 --score chr21.tsv 1 2 3 header \
 --out test
