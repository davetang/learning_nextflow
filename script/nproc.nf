#!/usr/bin/env nextflow

nextflow.enable.dsl=2

/*
    Usage:
       nextflow run nproc.nf -c my_config.yaml
*/

workflow {
    NUM_PROCESSORS()
    HI()
}

// process names are written in uppercase by convention.
process NUM_PROCESSORS {
    debug true
    label 'many_cpus'
    output:
    stdout

    script:
    """
    nproc
    echo process NUM_PROCESSORS is using $task.cpus cpus
    """
}

process HI {
    debug true
    output:
    stdout

    script:
    """
    echo process HI is using $task.cpus cpus
    """
}
