#!/usr/bin/env nextflow

infile = "$HOME/github/learning_nextflow/data/num.txt"
topn = 10

process SORT {
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
    input:
    path x
    val n

    output:
    stdout

    script:
    """
    head -$n $x
    """
}

workflow {
    sort_ch = SORT(infile)
    topn_ch = TOPN(sort_ch, topn).view { it }
}
