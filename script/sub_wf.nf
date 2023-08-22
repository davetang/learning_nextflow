#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include {STRING_TO_FILE;CAT_FILE} from './channel.nf'

workflow SUB_WORKFLOW {
    STRING_TO_FILE(params.string)
    CAT_FILE(STRING_TO_FILE.out)
    CAT_FILE.out.view()
}
