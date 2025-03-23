#!/usr/bin/env nextflow

nextflow.enable.dsl=2

/*
    Usage:
       nextflow run cpus.nf
*/

workflow {
    NUM_PROCESSORS()
    NUM_PROCESSORS_LABEL()
}

// process names are written in uppercase by convention.
process NUM_PROCESSORS {
    debug true
    output:
    stdout

    script:
    """
    echo there are \$(nproc) processors available
    echo process NUM_PROCESSORS is using $task.cpus cpu/s
    """
}

// process names are written in uppercase by convention.
process NUM_PROCESSORS_LABEL {
    debug true
    label 'process_medium'
    output:
    stdout

    script:
    """
    echo there are \$(nproc) processors available
    echo process NUM_PROCESSORS_LABEL is using $task.cpus cpu/s
    """
}
