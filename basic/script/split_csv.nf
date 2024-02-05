#!/usr/bin/env nextflow

Channel
    .fromPath("$HOME/github/learning_nextflow/basic/samplesheet.csv")
    .splitCsv(header: ['sample_name', 'first', 'second'])
    // row is a list object
    .view { row -> "${row.first} ${row.second}" }
