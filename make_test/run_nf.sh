#!/usr/bin/env bash

set -euo pipefail

nextflow run \
   --topn 10 \
   -c nextflow.config \
   simple.nf
