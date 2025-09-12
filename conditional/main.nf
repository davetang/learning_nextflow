#!/usr/bin/env nextflow
/*

Minimal working example that uses a conditional step

*/

nextflow.enable.dsl = 2

params.samplesheet = "samplesheet.csv"
params.outdir = "results"

process PROCESS_1 {
    publishDir "${params.outdir}/process1", mode: 'copy'

    input:
    tuple val(meta), path(input_file)

    output:
    tuple val(meta), path("${meta.id}.processed"), emit: processed // emit: processed names output for use with other processes

    // Here's the magic: this process only runs if the condition is true
    when:
    meta.data_type == 'raw'

    script:
    """
    # Your processing commands for raw data
    echo "Processing raw data for ${meta.id}" > ${meta.id}.processed
    # Add your actual processing commands here
    """
}

process PROCESS_2 {
    publishDir "${params.outdir}/process2", mode: 'copy'

    input:
    tuple val(meta), path(input_file)

    output:
    tuple val(meta), path("${meta.id}.result"), emit: result

    script:
    """
    # Your processing commands for processed data
    echo "Final processing for ${meta.id}" > ${meta.id}.result
    # Add your actual processing commands here
    """
}

workflow {
    // Read samplesheet
    ch_samplesheet = Channel.fromPath(params.samplesheet)
        .splitCsv(header: true)
        .map { row ->
            def meta = [
                id: row.sample_id,
                sample_name: row.sample_name,
                condition: row.condition,
                data_type: row.data_type
            ]
            def input_file = file(row.input_file, checkIfExists: true)
            return [meta, input_file]
        }

    // Split channels based on data type
    ch_samplesheet.branch { meta, _file -> // splits the data into different paths based on conditions
        raw: meta.data_type == 'raw' // creates a "raw" branch for samples where data_type equals "raw"
        processed: meta.data_type == 'processed' // creates a "processed" branch for samples where data_type equals "processed"
    }.set { branched_data } // stores the split data in a variable called "branched_data"

    // Process raw data through PROCESS_1 first
    PROCESS_1(branched_data.raw)

    // Combine processed data from PROCESS_1 with already processed data
    // gets the output from PROCESS_1 (we named it "processed")
    // .mix combines the PROCESS_1 output with the already-processed samples
    // stores the combined data in a new variable called ch_for_process2
    ch_for_process2 = PROCESS_1.out.processed.mix(branched_data.processed)

    // Run PROCESS_2 on all data
    PROCESS_2(ch_for_process2)
}
