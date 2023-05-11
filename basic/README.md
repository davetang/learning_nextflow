Table of Contents
=================

* [README](#readme)
   * [Learning outcomes](#learning-outcomes)
   * [Environment setup](#environment-setup)
   * [Basic concepts](#basic-concepts)
   * [Hello](#hello)
   * [Channels](#channels)
      * [Channel factories](#channel-factories)
   * [Processes](#processes)
      * [Script](#script)
      * [Inputs](#inputs)
      * [Outputs](#outputs)
      * [When](#when)
      * [Directives](#directives)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->

# README

Check out the [Nextflow community training
portal](https://training.nextflow.io/) for training material. This directory
contains notes for the [Basic Nextflow Training
Workshop](https://training.nextflow.io/basic_training/).

## Learning outcomes

1. Be proficient in writing Nextflow workflows
2. Know the basic Nextflow concepts of Channels, Processes and Operators
3. Have an understanding of containerised workflows
4. Understand the different execution platforms supported by Nextflow
5. Be introduced to the Nextflow community and ecosystem

## Environment setup

Local setup requires:

1. Bash
2. Java 11 (or later, up to 18)
3. Git
4. Docker

Optional requirements include:

1. Singularity 2.5.x (or later)
2. Conda 4.5 (or later)
3. Graphviz
4. AWS CLI
5. A configured AWS Batch computing environment

Install Nextflow using
[mamba](https://github.com/davetang/learning_nextflow#installation) and confirm
installation.

```console
conda activate nextflow
nextflow info
#   Version: 22.10.6 build 5843
#   Created: 23-01-2023 23:20 UTC (24-01-2023 08:20 JDT)
#   System: Linux 3.10.0-1062.el7.x86_64
#   Runtime: Groovy 3.0.13 on OpenJDK 64-Bit Server VM 17.0.3-internal+0-adhoc..src
#   Encoding: UTF-8 (UTF-8)
```

Download the [training material](https://github.com/nextflow-io/training).

```console
git clone https://github.com/nextflow-io/training.git
```

## Basic concepts

Nextflow is both a workflow orchestration engine and domain-specific language
(DSL) that can be used to create computational workflows. Nextflow can be used
to define program interactions and a high-level parallel computational
environment. Nextflow's core features include:

* Workflow portability and reproducibility
* Scalability of parallelisation and deployment
* Integration of existing tools, systems, and industry standards

A Nextflow workflow is made up by joining together different processes. Each
`process` can be written in any scripting language that can be executed by
Linux.

Processes are executed independently and are isolated from each other. The only
way they can communicate is via asynchronous first-in, first-out (FIFO) queues,
called `channels`.

> [Asynchrony](https://en.wikipedia.org/wiki/Asynchrony_(computer_programming)),
> in computer programming, refers to the occurrence of events independent of the
> main program flow and ways to deal with such events. These may be "outside"
> events such as the arrival of signals, or actions instigated by a program that
> take place concurrently with program execution, without the program blocking to
> wait for results.

Any `process` can define one or more `channels` as an `input` and `output`. The
interaction between these processes is implicitly defined by these `input` and
`output` declarations.

The executor determines how a script is run on a target platform; the default
is to execute processes on the local computer. The local executor is useful for
workflow development and testing purposes but in a production setting, a
high-performance computing (HPC) or cloud platform is often used.

![Execution](img/execution_abstraction.png)

Nextflow implements a declarative DSL that serves as an extension of a
general-purpose programming language. Nextflow scripting is an extension of
Groovy, which is a super-set of Java. Groovy simplifies the writing of code and
is more approachable than Java.

## Hello

The `hello.nf` script takes an input string (a parameter called
`params.greeting`) and splits it into chunks of six characters in the first
process. The second process then converts the characters to upper case.

The use of the operator `.flatten()` in the workflow block is for splitting the
two files into two separate items to be put through the next process (or else
they would be treated as a single element).

```nextflow
#!/usr/bin/env nextflow

params.greeting = 'Hello world!'
greeting_ch = Channel.of(params.greeting)

process SPLITLETTERS {
    input:
    val x

    output:
    path 'chunk_*'

    """
    printf '$x' | split -b 6 - chunk_
    """
}

process CONVERTTOUPPER {
    input:
    path y

    output:
    stdout

    """
    cat $y | tr '[a-z]' '[A-Z]' 
    """
}

workflow {
    letters_ch = SPLITLETTERS(greeting_ch)
    results_ch = CONVERTTOUPPER(letters_ch.flatten())
    results_ch.view{ it }
}
```

Execute the script.

```console
nextflow run training/nf-training/hello.nf
# N E X T F L O W  ~  version 22.10.6
# Launching `training/nf-training/hello.nf` [mighty_mahavira] DSL2 - revision: 197a0e289a
# executor >  local (3)
# [ac/786da9] process > SPLITLETTERS (1)   [100%] 1 of 1 ✔
# [bc/908e8d] process > CONVERTTOUPPER (1) [100%] 2 of 2 ✔
# WORLD!
# HELLO
```

Note that `CONVERTTOUPPER` is executed twice because of `.flatten()`. The
hexadecimal numbers `ac/786da9` and `bc/908e8d` identify the unique process
execution, which is called a `task`; they are also the names of the directories
where each task was executed.

`CONVERTTOUPPER` actually produced two different work directories but only one
is displayed in the log because the log is dynamically refreshed and only the
last directory is shown. Use the following to output all relevant paths to the
screen:

```console
nextflow run training/nf-training/hello.nf -ansi-log false
```

Lastly, `CONVERTTOUPPER` is executed in parallel, so the output can differ
based on which task is executed first.

Nextflow keeps track of all the processes executed in a workflow. If a script
is modified, only the processes that are changed will be re-executed. The
execution of the processes that are not changed will be skipped and the cached
result will be used instead. Include the `-resume` option to enable this
behaviour.

```console
nextflow run training/nf-training/hello.nf -resume
N E X T F L O W  ~  version 22.10.6
Launching `training/nf-training/hello.nf` [astonishing_goldstine] DSL2 - revision: 197a0e289a
[ac/786da9] process > SPLITLETTERS (1)   [100%] 1 of 1, cached: 1 ✔
[bc/908e8d] process > CONVERTTOUPPER (1) [100%] 2 of 2, cached: 2 ✔
WORLD!
HELLO
```

Since nothing was changed, the cached result was used for both processes. The
workflow results are cached by default in `$PWD/work` and can take up a lot of
disk space.

Workflow parameters are declared by prepending the prefix `params` to a
variable name, separated by a period. Their value can be specified on the
command line by prefixing the parameter name with two hyphens. For example:

```console
nextflow run training/nf-training/hello.nf --greeting 'Bonjour le monde!'
# Launching `training/nf-training/hello.nf` [suspicious_meninsky] DSL2 - revision: 197a0e289a
# executor >  local (4)
# [6d/0bfe0a] process > SPLITLETTERS (1)   [100%] 1 of 1 ✔
# [19/300017] process > CONVERTTOUPPER (3) [100%] 3 of 3 ✔
# R LE M
# BONJOU
# ONDE!
```

## Channels

Channels are used to logically connect tasks to each other or to implement
functional style data transformations. Nextflow distinguishes two different
kinds of channels:

1. Queue channels
2. Value channels

A queue channel is an asynchronous unidirectional FIFO queue that connects two
processes or operators.

* Asynchronous means that operations are non-blocking.
* Unidirectional means that data flows from a producer to a consumer.
* FIFO (First In, First Out) means that the data is guaranteed to be delivered
  in the same order as it is produced.

A queue channel is implicitly created by process output definitions or using
channel factories such as `Channel.of` or `Channel.fromPath`.

```nextflow
ch = Channel.of(1, 2, 3)
println(ch) 
ch.view() 
```

Run.

```console
nextflow run channel_of.nf
# N E X T F L O W  ~  version 22.10.6
# Launching `channel_of.nf` [confident_varahamihira] DSL2 - revision: 6d727ba3c3
# DataflowBroadcast around DataflowStream[?]
# 1
# 2
# 3
```

A value channel (a.k.a. singleton channel) by definition is bound to a single
value and it can be read unlimited times without consuming its contents. A
`value` channel is created using the `value` channel factory or by operators
returning a single value, such as `first`, `last`, `collect`, `count`, `min`,
`max`, `reduce`, and `sum`.

### Channel factories

The following are Nextflow commands for creating channels that have implicit
expected inputs and functions.

* The `value` channel factory is used to create a value channel.
* The factory `Channel.of` allows the creation of a queue channel with the
  values specified as arguments.
* The `Channel.fromList` channel factory creates a channel emitting the
  elements in a list.
* The `fromPath` channel factory creates a queue channel emitting one or more
  files matching a specified glob.
* The `fromFilePairs` channel factory creates a channel emitting the file pairs
  matching a glob pattern.
* The `Channel.fromSRA` channel factory makes it possible to query the SRA and
  returns a channel emitting the FASTQ files matching the specified selection
	criteria. This requires an API key obtained by logging into your NCBI
	account. Use [secrets](https://www.nextflow.io/docs/latest/secrets.html) to
  store and use your key.
* The `splitText` operator allows you to split multi-line strings or text file
  items.
* The `splitCsv` operator allows you to parse text items in CSV (and TSV)
  files. For TSV files, use `sep: '\t'`.

It is also possible to parse JSON and YAML files using external libraries.

## Processes

In Nextflow, a `process` is the basic computing primitive to execute foreign
functions. The `process` definition starts with the keyword `process`, followed
by the process name and the process body in a curly bracket block. The
`process` name is commonly written in upper case by convention. A basic
`process`, only using the `script` definition block is shown below.

```nextflow
process SAYHELLO {
    script:
    """
    echo 'Hello world!'
    """
}
```

The process body can contain up to five definition blocks:

1. `Directives` are initial declarations that define optional settings.
2. `Input` defines the expected input channel(s).
3. `Output` defines the expected output channel(s).
4. `When` is an optional clause statement to allow conditional processes
5. `Script` is a string statement that defines the command to be executed by the process' task.

```nextflow
process < name > {
    [ directives ] 

    input: 
    < process inputs >

    output: 
    < process outputs >

    when: 
    < condition >

    [script|shell|exec]: 
    """
    < user script to be executed >
    """
}
```

### Script

The `script` block is a string statement that defines the command to be
executed by the process. A process can execute only one `script` block and it
must be the last statement when the process contains `input` and `output`
declarations.

The `script` block can be a single of a multi-line string. By default the
`process` command is interpreted as a Bash script. However any other scripting
language can be used by specifying the interpreter in the Shebang.

Script parameters (`params`) can be defined in the Nextflow script using
variable values.

```nextflow
params.data = 'World'

process FOO {
    script:
    """
    echo Hello $params.data
    """
}

workflow {
    FOO()
}
```

Of note is that since Nextflow uses the same Bash syntax for variable
substitutions in strings, Bash variables need to be escaped using `\`.
Alternatives include using a script string delimited by single-quote characters
but Nextflow variables are not interpolated and using a `shell` statement
instead of `script` and use `!{}` for Nextflow variables.

The process script can run steps conditionally using an `if` statement or any
other expression for evaluating a string value.

```nextflow
params.compress = 'gzip'
params.file2compress = "$baseDir/data/ggal/transcriptome.fa"

process FOO {
    input:
    path file

    script:
    if (params.compress == 'gzip')
        """
        gzip -c $file > ${file}.gz
        """
    else if (params.compress == 'bzip2')
        """
        bzip2 -c $file > ${file}.bz2
        """
    else
        throw new IllegalArgumentException("Unknown compressor $params.compress")
}

workflow {
    FOO(params.file2compress)
}
```

### Inputs

Nextflow process instances (tasks) are isolated from each other but communicate
with each other through channels. Inputs implicitly determine the dependencies
and the parallel execution of the process. The process execution starts each
time new data is available from the input channel.

The `input` block defines the names and qualifiers of variables that refer to
channel elements. You can only define one `input` block at a time and it must
contain one or more input declarations.

```nextflow
input:
<input qualifier> <input name>
```

The `val` qualifier allows you to receive data of any type as input.

```nextflow
num = Channel.of(1, 2, 3)

process BASICEXAMPLE {
    debug true

    input:
    val x

    script:
    """
    echo process job $x
    """
}

workflow {
    myrun = BASICEXAMPLE(num)
}
```

The `path` qualifier allows the handling of file values in the process
execution context. This means that Next will stage it in the process execution
directory and it can be accessed in the script by using the name specified in
the input declaration.

```nextflow
reads = Channel.fromPath('data/ggal/*.fq')

process FOO {
    debug true

    input:
    path sample

    script:
    """
    ls -lh $sample
    """
}

workflow {
    FOO(reads.collect())
}
```

A key feature of processes is the ability to handle inputs from multiple
channels. Use a `value` channel if the channels have different number of data.
This is because `value` channels can be consumed multiple times and do not
affect process termination.

```nextflow
input1 = Channel.value(1)
input2 = Channel.of('a', 'b', 'c')

process BAR {
    debug true

    input:
    val x
    val y

    script:
    """
    echo $x and $y
    """
}

workflow {
    BAR(input1, input2)
}
```

The `each` qualifier allows you to repeat the execution of a process for each
item in a collection every time new data is received.

```nextflow
sequences = Channel.fromPath('data/prots/*.tfa')
methods = ['regular', 'espresso', 'psicoffee']

process ALIGNSEQUENCES {
    debug true

    input:
    path seq
    each mode

    script:
    """
    echo t_coffee -in $seq -mode $mode
    """
}

workflow {
    ALIGNSEQUENCES(sequences, methods)
}
```

### Outputs

The `output` declaration block defines the channels used by the process to send
out the results. Only one `output` block, which can contain one or more output
declaration, can be defined. The `output` block has the following syntax:

```nextflow
output:
<output qualifier> <output name>, emit: <output channel>
```

When an output file name contains a wildcard character (`*` or `?`) it is
interpreted as a glob path matcher and allows multiple files to be captured
into a list object.

```nextflow
process SPLITLETTERS {
    output:
    path 'chunk_*'

    script:
    """
    printf 'Hola' | split -b 1 - chunk_
    """
}

workflow {
    letters = SPLITLETTERS()
    letters
        .flatMap()
        .view { "File: ${it.name} => ${it.text}" }
}
```

Of note on glob patterns:

* Input files are not included in the list of possible matches
* Glob pattern matches both files and directory paths
* When a two star pattern `**` is used to recourse across directories, only
  file paths are matched.

When an output file name needs to be expressed dynamically, it is possible to
define it using a dynamic string that references values defined in the input
declaration block or in the script context.

```nextflow
species = ['cat', 'dog', 'sloth']
sequences = ['AGATAG', 'ATGCTCT', 'ATCCCAA']

Channel
    .fromList(species)
    .set { species_ch }

process ALIGN {
    input:
    val x
    val seq

    output:
    path "${x}.aln"

    script:
    """
    echo align -in $seq > ${x}.aln
    """
}

workflow {
    genomes = ALIGN(species_ch, sequences)
    genomes.view()
}
```

Output (and input) declarations can be tuples if declared with a `tuple`
qualifier. This allows composite outputs (and inputs).

### When

The `when` declaration can be used for setting conditional behaviour.

```nextflow
params.dbtype = 'nr'
params.prot = 'data/prots/*.tfa'
proteins = Channel.fromPath(params.prot)

process FIND {
    debug true

    input:
    path fasta
    val type

    when:
    fasta.name =~ /^BB11.*/ && type == 'nr'

    script:
    """
    echo blastp -query $fasta -db nr
    """
}

workflow {
    result = FIND(proteins, params.dbtype)
}
```

### Directives

Directive declarations allow the definition of optional settings that affect
the execution of the current process without affecting the semantic of the task
itself. They must be entered at the top of the process body, before any other
declaration blocks.

Directives are commonly used to define the amount of computing resources to be
used or other meta directives that allow the definition of extra configuration
of logging information.

```nextflow
process FOO {
    cpus 2
    memory 1.GB
    container 'image/name'

    script:
    """
    echo your_command --this --that
    """
}
```

The `publishDir` directive is useful for storing workflow result files.

```nextflow
params.outdir = 'my-results'
params.prot = 'data/prots/*.tfa'
proteins = Channel.fromPath(params.prot)


process BLASTSEQ {
    publishDir "$params.outdir/bam_files", mode: 'copy'

    input:
    path fasta

    output:
    path ('*.txt')

    script:
    """
    echo blastp $fasta > ${fasta}_result.txt
    """
}

workflow {
    blast_ch = BLASTSEQ(proteins)
    blast_ch.view()
}
```

Multiple `publishDir` directives can be used to keep different outputs in
separate directories.

```nextflow
// snipped
process FOO {
    publishDir "$params.outdir/$sampleId/", pattern: '*.fq'
    publishDir "$params.outdir/$sampleId/counts", pattern: "*_counts.txt"
    publishDir "$params.outdir/$sampleId/outlooks", pattern: '*_outlook.txt'

// snipped
```
