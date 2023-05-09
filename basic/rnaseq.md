Table of Contents
=================

* [A simple RNA-seq workflow](#a-simple-rna-seq-workflow)
   * [Workflow parameters](#workflow-parameters)
   * [Transcriptome index](#transcriptome-index)
   * [Collect files by pairs](#collect-files-by-pairs)
   * [Expression quantification](#expression-quantification)
   * [Quality control](#quality-control)
   * [MultiQC report](#multiqc-report)
   * [Handle completion event](#handle-completion-event)
   * [Miscellaneous](#miscellaneous)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

# A simple RNA-seq workflow

This workflow is made up of seven scripts (`script1.nf` to `script7.nf`) and
will:

1. Index a transcriptome file
2. Perform quality control steps (using FastQC)
3. Perform quantification (using Salmon)
4. Creates a MultiQC report (using MultiQC)

## Workflow parameters

Parameters are inputs and options that can be changed when a workflow is run.

The script `script1.nf` defines the workflow input parameters.

```nextflow
params.reads = "$projectDir/data/ggal/gut_{1,2}.fq"
params.transcriptome_file = "$projectDir/data/ggal/transcriptome.fa"
params.multiqc = "$projectDir/multiqc"

println "reads: $params.reads"
```

Run the script.

```console
nextflow run training/nf-training/script1.nf
# N E X T F L O W  ~  version 22.10.6
# Launching `training/nf-training/script1.nf` [spontaneous_yalow] DSL2 - revision: 86d466d737
# reads: /home/dtang/github/learning_nextflow/basic/training/nf-training/data/ggal/gut_{1,2}.fq
```

The `log.info` command can be used to print information, which is also saved in
the execution log file.

```nextflow
log.info """\
    R N A S E Q - N F   P I P E L I N E
    ===================================
    transcriptome: ${params.transcriptome_file}
    reads        : ${params.reads}
    outdir       : ${params.outdir}
    """
    .stripIndent(true)
```

## Transcriptome index

Nextflow allows the execution of any command or script by using a `process`
definition. A `process` is defined by providing three main declarations:

1. `input`
2. `output`
3. `script`

The following Nextflow script creates a transcriptome index using `salmon`.

```nextflow
/*
 * pipeline input parameters
 */
params.reads = "$projectDir/data/ggal/gut_{1,2}.fq"
params.transcriptome_file = "$projectDir/data/ggal/transcriptome.fa"
params.multiqc = "$projectDir/multiqc"
params.outdir = "results"

log.info """\
    R N A S E Q - N F   P I P E L I N E
    ===================================
    transcriptome: ${params.transcriptome_file}
    reads        : ${params.reads}
    outdir       : ${params.outdir}
    """
    .stripIndent(true)

/*
 * define the `index` process that creates a binary index
 * given the transcriptome file
 */
process INDEX {
    input:
    path transcriptome

    output:
    path 'salmon_index'

    script:
    """
    salmon index --threads $task.cpus -t $transcriptome -i salmon_index
    """
}

workflow {
    index_ch = INDEX(params.transcriptome_file)
}
```

The `params.transcriptome_file` parameter is used as input for `INDEX`, which
creates `salmon_index` as its output and is passed as output to the `index_ch`
channel.

The input declaration defines a `transcriptome` path variable, which is used in
the `script` section as the reference using the dollar symbol.

Run the workflow using Docker.

```console
nextflow run training/nf-training/script2.nf -with-docker
# N E X T F L O W  ~  version 22.10.6
# Launching `training/nf-training/script2.nf` [lonely_hoover] DSL2 - revision: 7f0ffa46ee
# R N A S E Q - N F   P I P E L I N E
# ===================================
# transcriptome: /home/dtang/github/learning_nextflow/basic/training/nf-training/data/ggal/transcriptome.fa
# reads        : /home/dtang/github/learning_nextflow/basic/training/nf-training/data/ggal/gut_{1,2}.fq
# outdir       : results
# 
# executor >  local (1)
# [fc/d1835f] process > INDEX [100%] 1 of 1 ✔
# Completed at: 08-May-2023 14:22:53
# Duration    : 1m 53s
# CPU hours   : (a few seconds)
# Succeeded   : 1
```

To use Docker each time, add the following line to `nextflow.config`.

```
docker.enabled = true
```

## Collect files by pairs

Add `read_pairs_ch.view()` to the end of `script3.nf` (after `read_pairs_ch =
Channel.fromFilePairs(params.reads)`)

```nextflow

/*
 * pipeline input parameters
 */
params.reads = "$projectDir/data/ggal/gut_{1,2}.fq"
params.transcriptome_file = "$projectDir/data/ggal/transcriptome.fa"
params.multiqc = "$projectDir/multiqc"
params.outdir = "results"

log.info """\
    R N A S E Q - N F   P I P E L I N E
    ===================================
    transcriptome: ${params.transcriptome_file}
    reads        : ${params.reads}
    outdir       : ${params.outdir}
    """
    .stripIndent()

read_pairs_ch = Channel.fromFilePairs(params.reads, checkIfExists: true)
read_pairs_ch.view()
```

Run the script.

```console
nextflow run training/nf-training/script3.nf
# N E X T F L O W  ~  version 22.10.6
# Launching `training/nf-training/script3.nf` [reverent_meucci] DSL2 - revision: e80c63f732
# R N A S E Q - N F   P I P E L I N E
# ===================================
# transcriptome: /home/dtang/github/learning_nextflow/basic/training/nf-training/data/ggal/transcriptome.fa
# reads        : /home/dtang/github/learning_nextflow/basic/training/nf-training/data/ggal/gut_{1,2}.fq
# outdir       : results
# 
# [gut, [/home/dtang/github/learning_nextflow/basic/training/nf-training/data/ggal/gut_1.fq, /home/dtang/github/learning_nextflow/basic/training/nf-training/data/ggal/gut_2.fq]]
```

## Expression quantification

`script4.nf` adds a gene expression quantification process, which requires the
index transcriptome and FASTQ files.

```nextflow
/*
 * pipeline input parameters
 */
params.reads = "$projectDir/data/ggal/gut_{1,2}.fq"
params.transcriptome_file = "$projectDir/data/ggal/transcriptome.fa"
params.multiqc = "$projectDir/multiqc"
params.outdir = "results"

log.info """\
    R N A S E Q - N F   P I P E L I N E
    ===================================
    transcriptome: ${params.transcriptome_file}
    reads        : ${params.reads}
    outdir       : ${params.outdir}
    """
    .stripIndent()

/*
 * define the `index` process that creates a binary index
 * given the transcriptome file
 */
process INDEX {
    input:
    path transcriptome

    output:
    path 'salmon_index'

    script:
    """
    salmon index --threads $task.cpus -t $transcriptome -i salmon_index
    """
}

process QUANTIFICATION {
    input:
    path salmon_index
    tuple val(sample_id), path(reads)

    output:
    path "$sample_id"

    script:
    """
    salmon quant --threads $task.cpus --libType=U -i $salmon_index -1 ${reads[0]} -2 ${reads[1]} -o $sample_id
    """
}

workflow {
    Channel
        .fromFilePairs(params.reads, checkIfExists: true)
        .set { read_pairs_ch }

    index_ch = INDEX(params.transcriptome_file)
    quant_ch = QUANTIFICATION(index_ch, read_pairs_ch)
}
```

In the `workflow` block, `read_pairs_ch` is a [tuple](#collect-files-by-pairs)
containing the sample ID (generated from the FASTQ file) and an array
containing the read pairs.

`index_ch` contains the output of the `INDEX` process and `quant_ch` contains
the output of `QUANTIFICATION`. The first input channel for `QUANTIFICATION` is
`index_ch` and the second input channel is `read_pairs_ch`.

```console
nextflow run training/nf-training/script4.nf -resume -with-docker
# N E X T F L O W  ~  version 22.10.6
# Launching `training/nf-training/script4.nf` [sad_mahavira] DSL2 - revision: 3fb91764d4
# R N A S E Q - N F   P I P E L I N E
# ===================================
# transcriptome: /home/dtang/github/learning_nextflow/basic/training/nf-training/data/ggal/transcriptome.fa
# reads        : /home/dtang/github/learning_nextflow/basic/training/nf-training/data/ggal/gut_{1,2}.fq
# outdir       : results
# 
# executor >  local (2)
# [6a/47783b] process > INDEX              [100%] 1 of 1 ✔
# [e2/611a40] process > QUANTIFICATION (1) [100%] 1 of 1 ✔
```

Run the workflow on more reads.

```console
ls training/nf-training/data/ggal/*_{1,2}.fq
# training/nf-training/data/ggal/gut_1.fq    training/nf-training/data/ggal/liver_2.fq
# training/nf-training/data/ggal/gut_2.fq    training/nf-training/data/ggal/lung_1.fq
# training/nf-training/data/ggal/liver_1.fq  training/nf-training/data/ggal/lung_2.fq

nextflow run training/nf-training/script4.nf -resume -with-docker --reads 'training/nf-training/data/ggal/*_{1,2}.fq'
# N E X T F L O W  ~  version 22.10.6
# Launching `training/nf-training/script4.nf` [focused_volta] DSL2 - revision: 3fb91764d4
# R N A S E Q - N F   P I P E L I N E
# ===================================
# transcriptome: /home/dtang/github/learning_nextflow/basic/training/nf-training/data/ggal/transcriptome.fa
# reads        : training/nf-training/data/ggal/*_{1,2}.fq
# outdir       : results
# 
# executor >  local (2)
# [6a/47783b] process > INDEX              [100%] 1 of 1, cached: 1 ✔
# [45/9e32a0] process > QUANTIFICATION (3) [100%] 3 of 3, cached: 1 ✔
```

Add a [tag](https://www.nextflow.io/docs/latest/process.html#tag) directive to
provide a more readable execution log. For example, add the following in the
`QUANTIFICATION` process just before the `input` declaration:

```nextflow
process QUANTIFICATION {
    tag "Salmon on $sample_id"
    input:
```

Add a [publishDir](https://www.nextflow.io/docs/latest/process.html#publishdir)
directive to store the process results in a directory of choice. For example,
add the following in the `QUANTIFICATION` process just before the `input`
declaration:

```nextflow
process QUANTIFICATION {
    tag "Salmon on $sample_id"
    publishDir params.outdir, mode: 'copy'
    input:
```

Available modes include a `symlink`, which creates an absolute symbolic link
instead of copying the files.

## Quality control

`script5.nf` adds a quality control step, which is shown below.

```nextflow
# snipped

process FASTQC {
    tag "FASTQC on $sample_id"

    input:
    tuple val(sample_id), path(reads)

    output:
    path "fastqc_${sample_id}_logs"

    script:
    """
    mkdir fastqc_${sample_id}_logs
    fastqc -o fastqc_${sample_id}_logs -f fastq -q ${reads}
    """
}

workflow {
    Channel
        .fromFilePairs(params.reads, checkIfExists: true)
        .set { read_pairs_ch }

    index_ch = INDEX(params.transcriptome_file)
    quant_ch = QUANTIFICATION(index_ch, read_pairs_ch)
    fastqc_ch = FASTQC(read_pairs_ch)
}
```

Note that `reads` in the `FASTQC` process is an array containing the first and
second read pairs. Nextflow DSL2 can split the `reads_pair_ch` into two
identical channels. In the `QUANTIFICATION` process, the reads are referenced
individually by their array index.

```console
nextflow run training/nf-training/script5.nf -resume -with-docker --reads 'training/nf-training/data/ggal/*_{1,2}.fq'
# N E X T F L O W  ~  version 22.10.6
# Launching `training/nf-training/script5.nf` [fervent_ampere] DSL2 - revision: 6f91f91251
# R N A S E Q - N F   P I P E L I N E
# ===================================
# transcriptome: /home/dtang/github/learning_nextflow/basic/training/nf-training/data/ggal/transcriptome.fa
# reads        : training/nf-training/data/ggal/*_{1,2}.fq
# outdir       : results
# 
# executor >  local (3)
# [6a/47783b] process > INDEX                          [100%] 1 of 1, cached: 1 ✔
# [e2/611a40] process > QUANTIFICATION (Salmon on gut) [100%] 3 of 3, cached: 3 ✔
# [16/1ce4cc] process > FASTQC (FASTQC on gut)         [100%] 3 of 3 ✔
```

## MultiQC report

`script6.nf` adds a MultiQC process, which collects the outputs from the
`QUANTIFICATION` and `FASTQC` processes to create a QC report.

```nextflow
# snipped

process MULTIQC {
    publishDir params.outdir, mode:'copy'

    input:
    path '*'

    output:
    path 'multiqc_report.html'

    script:
    """
    multiqc .
    """
}

workflow {
    Channel
        .fromFilePairs(params.reads, checkIfExists: true)
        .set { read_pairs_ch }

    index_ch = INDEX(params.transcriptome_file)
    quant_ch = QUANTIFICATION(index_ch, read_pairs_ch)
    fastqc_ch = FASTQC(read_pairs_ch)
    MULTIQC(quant_ch.mix(fastqc_ch).collect())
}
```

The [mix](https://www.nextflow.io/docs/latest/operator.html#mix) and
[collect](https://www.nextflow.io/docs/latest/operator.html#collect) operators
are chained together to gather the outputs of the `QUANTIFICATION` and `FASTQC`
processes as a single input.
[Operators](https://www.nextflow.io/docs/latest/operator.html) can be used to
combine and transform channels.

```console
nextflow run training/nf-training/script6.nf -resume -with-docker --reads 'training/nf-training/data/ggal/*_{1,2}.fq'
# N E X T F L O W  ~  version 22.10.6
# Launching `training/nf-training/script6.nf` [hungry_tesla] DSL2 - revision: ba6662b2e1
# R N A S E Q - N F   P I P E L I N E
# ===================================
# transcriptome: /home/dtang/github/learning_nextflow/basic/training/nf-training/data/ggal/transcriptome.fa
# reads        : training/nf-training/data/ggal/*_{1,2}.fq
# outdir       : results
# 
# executor >  local (1)
# [6a/47783b] process > INDEX                          [100%] 1 of 1, cached: 1 ✔
# [e2/611a40] process > QUANTIFICATION (Salmon on gut) [100%] 3 of 3, cached: 3 ✔
# [10/1ae6d7] process > FASTQC (FASTQC on lung)        [100%] 3 of 3, cached: 3 ✔
# [6e/7b8f1e] process > MULTIQC                        [100%] 1 of 1 ✔
```

## Handle completion event

`script7.nf` adds a `workflow.onComplete` event handler to print a confirmation
message when the workflow completes.

```nextflow
workflow.onComplete {
    log.info ( workflow.success ? "\nDone! Open the following report in your browser --> $params.outdir/multiqc_report.html\n" : "Oops .. something went wrong" )
}
```

Run the workflow.

```console
nextflow run training/nf-training/script7.nf -resume -with-docker --reads 'training/nf-training/data/ggal/*_{1,2}.fq'
# N E X T F L O W  ~  version 22.10.6
# Launching `training/nf-training/script7.nf` [fabulous_ride] DSL2 - revision: 7c1e827ae3
# R N A S E Q - N F   P I P E L I N E
# ===================================
# transcriptome: /home/dtang/github/learning_nextflow/basic/training/nf-training/data/ggal/transcriptome.fa
# reads        : training/nf-training/data/ggal/*_{1,2}.fq
# outdir       : results
# 
# [6a/47783b] process > INDEX                           [100%] 1 of 1, cached: 1 ✔
# [45/9e32a0] process > QUANTIFICATION (Salmon on lung) [100%] 3 of 3, cached: 3 ✔
# [e7/168af7] process > FASTQC (FASTQC on liver)        [100%] 3 of 3, cached: 3 ✔
# [6e/7b8f1e] process > MULTIQC                         [100%] 1 of 1, cached: 1 ✔
# 
# Done! Open the following report in your browser --> results/multiqc_report.html
```

## Miscellaneous

See the [mail
documentation](https://www.nextflow.io/docs/latest/mail.html#mail-configuration)
for setting up email notifications.

To use custom scripts, create a `bin` directory in the workflow project root
and place the scripts inside. The `bin` directory is automatically added to the
workflow execution `PATH`; make sure the scripts are executable.

Nextflow can produce multiple reports and charts providing runtime metrics and
execution information.

```console
nextflow run training/nf-training/script7.nf \
   -with-docker \
   --reads 'training/nf-training/data/ggal/*_{1,2}.fq' \
   -with-report \
   -with-trace \
   -with-timeline \
   -with-dag dag.png
```

* `-with-report` - enables the creation of the workflow execution report.
* `-with-trace` - enables the creation of a tab separated value (TSV) file
  containing runtime information for each executed task.
* `-with-timeline` - enables the creation of the workflow timeline report
  showing how processes were executed over time.
* `-with-dag` - enables the rendering of the workflow execution direct acyclic
  graph representation. Note: This feature requires the installation of
  [Graphviz](https://www.graphviz.org/) on your computer.

Nextflow allows the execution of a workflow project directly from a GitHub,
BitBucket, and GitLab repository.
