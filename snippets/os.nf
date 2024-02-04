#!/usr/bin/env nextflow

process GETOS {
    output:
    stdout

    script:
    """
    cat /etc/os-release
    """
}

workflow {
    os_ch = GETOS()
    os_ch.view { it }
}
