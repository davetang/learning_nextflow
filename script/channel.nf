#!/usr/bin/env nextflow

nextflow.enable.dsl=2

/*
    Usage:
       nextflow run channel.nf --string <input_string>
*/

workflow {
    /*  The script to execute is called by its process name,
        and input is provided between brackets. */
    STRING_TO_FILE(params.string)

    //  Process output is accessed using the `out` channel.
    CAT_FILE(STRING_TO_FILE.out)

    /* The channel operator view() is used to print process output to the
       terminal. */
    CAT_FILE.out.view()
}

// process names are written in uppercase by convention.
process STRING_TO_FILE {
    // The val qualifier accepts any data type
    input:
    val string

    output:
    path "word.txt"

    script:
    """
    echo $string > word.txt
    """
}

process CAT_FILE {
    input:
    path infile

    output:
    stdout

    script:
    """
    cat $infile
    """
}
