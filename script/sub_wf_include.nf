#!/usr/bin/env nextflow

nextflow.enable.dsl=2

/*
    Usage:
       nextflow run sub_wf_include.nf --string <input_string>
*/

include {SUB_WORKFLOW} from './sub_wf.nf'

workflow {
    SUB_WORKFLOW()
}
