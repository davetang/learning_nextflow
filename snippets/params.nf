#!/usr/bin/env nextflow

greeting_ch = Channel.of(params.greeting)

process HELLO {
    input:
    val x

    output:
    stdout

    script:
    """
    printf '$x'
    """
}

workflow {
    hello_ch = HELLO(greeting_ch).view { it }
}
