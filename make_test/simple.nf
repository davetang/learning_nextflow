#!/usr/bin/env nextflow

infile = "$HOME/github/learning_nextflow/data/num.txt"

process SORT {
    publishDir(
        path: "results",
        mode: 'copy'
    )

    input:
    path x

    output:
    path "${x.baseName}_sorted.txt"

    script:
    """
    sort -n $x > ${x.baseName}_sorted.txt
    """
}

process TOPN {
    publishDir(
        path: "results",
        mode: 'copy'
    )

    input:
    path x
    val n

    output:
    path "${x.baseName}_${n}.txt"

    script:
    """
    head -$n $x > ${x.baseName}_${n}.txt
    """
}

workflow {
    sort_ch = SORT(infile)
    topn_ch = TOPN(sort_ch, params.topn)
}
