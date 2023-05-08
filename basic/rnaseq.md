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

TBC.
