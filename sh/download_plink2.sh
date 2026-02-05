#!/bin/bash

# Download plink2 to software/ directory
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "${SCRIPT_DIR}/software"
wget https://s3.amazonaws.com/plink2-assets/plink2_linux_avx2_20260110.zip -O /tmp/plink2.zip
unzip -o /tmp/plink2.zip -d "${SCRIPT_DIR}/software"
rm /tmp/plink2.zip
chmod +x "${SCRIPT_DIR}/software/plink2"
echo "plink2 installed to ${SCRIPT_DIR}/software/plink2"
