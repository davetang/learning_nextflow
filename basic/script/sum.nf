#!/usr/bin/env nextflow
//
// Understand difference between value and queue channels. A process will only
// instantiate a task when there are elements to be consumed from all the
// channels provided as input to it. Because ch1 and ch2 are queue channels,
// and the single element of ch2 has been consumed, no new process instances
// will be launched, even if there are other elements to be consumed in ch1.
//
// To "recycle" ch2, use `first()`.
//

ch1 = Channel.of(1, 2, 3)
ch2 = Channel.of(1)

process SUM {
    input:
    val x
    val y

    output:
    stdout

    script:
    """
    echo \$(($x+$y))
    """
}

workflow {
    // SUM(ch1, ch2).view()
    SUM(ch1, ch2.first()).view()
}
