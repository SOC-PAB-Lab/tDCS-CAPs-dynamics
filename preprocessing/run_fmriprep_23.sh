#!/bin/bash

# Define directories
BIDS_DIR="${BIDS_DIR:-/path/to/bids_dir}"
OUTPUT_DIR="${OUTPUT_DIR:-/path/to/fmriprep_output}"
FS_LICENSE="${FS_LICENSE:-/path/to/license.txt}"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Run fmriprep-docker
fmriprep-docker \
    "$BIDS_DIR" \
    "$OUTPUT_DIR" \
    participant \
    --fs-license-file "$FS_LICENSE" \
    --nthreads 24 \
    --omp-nthreads 24 \
    --use-syn-sdc warn
