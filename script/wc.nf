#!/usr/bin/env nextflow

nextflow.enable.dsl=2

/*
    Usage:
       nextflow run wc.nf --input <input_file>
*/


/*  Parameters are written as params.<parameter>. The input data is hardcoded
    in this example and this script should be run from the root directory. */
params.input = "data/data/yeast/reads/ref1_1.fq.gz"

//  workflow block
workflow {

    //  input data is received through channels
    input_ch = Channel.fromPath(params.input)

    /*  The script to execute is called by its process name,
        and input is provided between brackets. */
    NUM_LINES(input_ch)

    /*  Process output is accessed using the `out` channel.
        The channel operator view() is used to print
        process output to the terminal. */
    NUM_LINES.out.view()
}

// process names are written in uppercase by convention.
process NUM_LINES {

    input:
    path read

    output:
    stdout

    script:
    /* Triple-single-quoted strings may span multiple lines.
       The content of the string can cross line boundaries without the need to
       split the string in several pieces and without concatenation or newline
       escape characters. */
    """
    printf '${read} '
    gunzip -c ${read} | wc -l
    """
}
