#!/usr/bin/env nextflow
/*

Minimal working example that uses a simple CSV samplesheet

*/

nextflow.enable.dsl=2

params.outdir = 'results'

// https://www.nextflow.io/docs/latest/reference/operator.html#splitcsv
ch_samplesheet = Channel.fromPath("samplesheet.csv")
                    .splitCsv(header: true)
                    .map { row -> tuple(row.sample_id, row.sample_name, row.condition) }

process TEST {
    publishDir params.outdir, mode: 'copy'
    input:
    tuple val(sample_id), val(sample_name), val(condition)

    output:
    path "${sample_name}.txt"

    script:
    """
    echo "${sample_id} ${condition}" > ${sample_name}.txt
    """
}

workflow {
    test_ch = TEST(ch_samplesheet)
}
