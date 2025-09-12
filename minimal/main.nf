#!/usr/bin/env nextflow
/*

Minimal working example that uses a simple CSV samplesheet

*/

nextflow.enable.dsl=2

params.outdir = 'results'

// https://www.nextflow.io/docs/latest/reference/operator.html#splitcsv
ch_samplesheet = Channel.fromPath("samplesheet.csv") // creates a channel and stores it a variable
    .splitCsv(header: true) // take result previous line and split the CSV
    .map { row -> // { starts a closure, a block of code that can be treated as a value
        // Validate required fields
        if (!row.sample_id || !row.fastq1 || !row.fastq2) {
            error "Missing required fields in samplesheet row: ${row}"
        }

        // create new variable called meta that is a map, i.e., dictionary
        // [key: value, key: value]
        def meta = [
            id: row.sample_id,
            sample_name: row.sample_name ?: row.sample_id, // use sample_name if it exists, if not, use sample_id
            condition: row.condition ?: 'unknown'
        ]

        // create new variable called reads that is a list with two items
        // [item1, item2]
        def reads = [file(row.fastq1, checkIfExists: true), // file object and check if it exists
                     file(row.fastq2, checkIfExists: true)]
        // return [metadata_map, [file1, file2]]
        return [meta, reads]
    }

// Define a computational step in your workflow using the `process` keyword
// The name of the process is by convention in ALL_CAPS
process EXAMPLE_PROCESS {
    publishDir params.outdir, mode: 'copy' // where to save the results and copy them instead of linking or moving

    // What data the process expects to receive
    // tuple = a grouped collection of items that travel together
    // val(meta) = expects a value (not a file) called meta
    // path(reads) = expects file(s) called reads; Nextflow will automatically handle the file paths
    input:
    tuple val(meta), path(reads)

    // declare what data this process will produce
    // output will also be a grouped collection with metadata and a file
    // val(meta) might seem confusing as an output but it is very common to pass through the same metadata that was received
    output:
    tuple val(meta), path("${meta.id}_output.txt")

    // actual commands that will be executed
    script:
    """
    echo "Processing ${meta.id} from condition ${meta.condition}" > ${meta.id}_output.txt
    """
}

workflow {
    example_process_ch = EXAMPLE_PROCESS(ch_samplesheet)
}
