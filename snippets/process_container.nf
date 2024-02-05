#!/usr/bin/env nextflow

process GETOS {
    // https://www.nextflow.io/docs/latest/process.html#container
    // this does not work with nextflow run snippets/process_container.nf
    // container "$HOME/github/learning_nextflow/debian_12.4.sif"
    container 'debian:12.4'

    output:
    stdout

    script:
    """
    cat /etc/os-release
    """
}

workflow {
    os_ch = GETOS().view { it }
}
