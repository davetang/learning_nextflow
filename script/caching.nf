#!/usr/bin/env nextflow

// https://training.nextflow.io/basic_training/cache_and_resume/

nextflow.enable.dsl=2

/*
    Usage:
       nextflow run caching.nf -resume
*/

workflow {
    SHUF()
}

/*
    Caching does not seem to work as expected when using storeDir; the workflow
    does not re-run. However, when I omit storeDir and change the process
    script, the workflow re-runs the process, as expected.
*/
process SHUF {
    debug true
    cache true
    //storeDir '/tmp/nextflow_cache'

    output:
    path "shuffled.txt"

    script:
    """
    for i in {1..10000}; do echo \$i; done | shuf > shuffled.txt
    """
}
