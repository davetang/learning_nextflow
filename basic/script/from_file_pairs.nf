#!/usr/bin/env nextflow
/*
When flat is true (default is false) a single list is created instead of a list
of list
*/

Channel
   .fromFilePairs('../training/nf-training/data/ggal/*_{1,2}.fq', flat: true)
   .view()
