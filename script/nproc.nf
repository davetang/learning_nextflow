#!/usr/bin/env nextflow

nextflow.enable.dsl=2

/*
    Usage:
       nextflow run nproc.nf -c my_config.yaml
*/

params.greeting = "Konnichiwa"

workflow {
    NUM_PROCESSORS()
    ECHO(params.greeting)
}

// process names are written in uppercase by convention.
process NUM_PROCESSORS {
    debug true
    label 'many_cpus'
    output:
    stdout

    script:
    """
    echo there are \$(nproc) processors available
    echo process NUM_PROCESSORS is using $task.cpus cpu/s
    """
}

process ECHO {
    input:
    val string

    debug true
    output:
    stdout

    script:
    """
    echo there are \$(nproc) processors available
    echo process ECHO is using $task.cpus cpu/s
    echo $string
    """
}
