#!/usr/bin/env nextflow
/*

Minimal working example that uses a simple CSV samplesheet

*/

nextflow.enable.dsl=2

params.outdir = 'results'

// https://www.nextflow.io/docs/latest/reference/operator.html#splitcsv
ch_samplesheet = Channel.fromPath("samplesheet.csv")
    .splitCsv(header: true)
    .map { row ->
        // Validate required fields
        if (!row.sample_id || !row.fastq1 || !row.fastq2) {
            error "Missing required fields in samplesheet row: ${row}"
        }

        def meta = [
            id: row.sample_id,
            sample_name: row.sample_name ?: row.sample_id,
            condition: row.condition ?: 'unknown'
        ]
        def reads = [file(row.fastq1, checkIfExists: true),
                     file(row.fastq2, checkIfExists: true)]
        return [meta, reads]
    }

process EXAMPLE_PROCESS {
    publishDir params.outdir, mode: 'copy'
    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}_output.txt")

    script:
    """
    echo "Processing ${meta.id} from condition ${meta.condition}" > ${meta.id}_output.txt
    """
}

workflow {
    example_process_ch = EXAMPLE_PROCESS(ch_samplesheet)
}
