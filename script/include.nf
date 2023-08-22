#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include {STRING_TO_FILE;CAT_FILE} from './channel.nf'

/*
    Usage:
       nextflow run include.nf --string <input_string>
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
