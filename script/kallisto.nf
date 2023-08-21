#!/usr/bin/env nextflow

nextflow.enable.dsl=2

/*
    Usage:
       nextflow run kallisto.nf -params-file kallisto.yaml --samples <input_file>

*/

// https://github.com/nextflow-io/patterns/blob/master/docs/process-per-csv-record.md

process quant {
    debug true
    input:
    tuple val(sampleId), file(fastq1), file(fastq2)

    script:
    """
    echo kallisto quant \
       -i ${params.index} \
       -t ${params.threads} \
       -o ${sampleId} \
       -b ${params.num_bootstrap} <(zcat ${fastq1}) <(zcat ${fastq2})
    """
}

workflow {
    Channel.fromPath(params.samples) \
        | splitCsv(header:false, sep:"\t") \
        | map { row-> tuple(row[0], file(row[1]), file(row[2])) } \
        | quant
}
