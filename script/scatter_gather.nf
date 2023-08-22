#!/usr/bin/env nextflow

// https://github.com/nextflow-io/patterns/blob/master/docs/process-per-file-output.md

nextflow.enable.dsl=2

/*
    Usage:
       nextflow run scatter_gather.nf --infile <input_file>
*/

params.num_split = 10

// see https://www.nextflow.io/docs/latest/operator.html
workflow {
    input_ch = Channel.fromPath(params.infile)
    SCATTER(input_ch, params.num_split)
    PROCESS(SCATTER.out.flatten())
    GATHER(PROCESS.out.collect())
}

process SCATTER {
    input:
    path infile
    val num_split

    output:
    path("split.*.txt")

    """
    split \
       --suffix-length=3 \
       --lines=${num_split} \
       --numeric-suffixes=1 \
       --additional-suffix=.txt \
       ${infile} split.
    """
}

process PROCESS {
    debug true
    input:
    path x

    output:
    path '*.processed.txt'

    """
    echo processing $x
    sed 's/^/Number /' $x > ${x.baseName}.processed.txt
    """
}

process GATHER {
    publishDir 'output', mode: 'move'

    input:
    path x

    output:
    path 'merged.txt'

    """
    cat $x | sort -V > merged.txt
    """
}
