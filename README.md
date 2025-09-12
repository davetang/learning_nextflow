## Table of Contents

  - [TL;DR](#tldr)
  - [WDL versus Nextflow](#wdl-versus-nextflow)
  - [Installation](#installation)
  - [Quick demo](#quick-demo)
    - [Run a project from GitHub](#run-a-project-from-github)
  - [Set up for testing purposes only](#set-up-for-testing-purposes-only)
  - [Nextflow tutorial](#nextflow-tutorial)
    - [Processes, channels, and workflows](#processes-channels-and-workflows)
    - [First script](#first-script)
  - [nf-core](#nf-core)
    - [tools](#tools)
    - [Reference genomes](#reference-genomes)
    - [Sarek](#sarek)
  - [Quick reference](#quick-reference)
    - [Workflow execution](#workflow-execution)
    - [Input parameters](#input-parameters)
    - [Read samplesheet](#read-samplesheet)
    - [Resource allocation](#resource-allocation)
    - [Singularity](#singularity)
  - [Troubleshooting](#troubleshooting)

## TL;DR

[Nextflow](https://www.nextflow.io/) enables scalable and reproducible scientific workflows using software containers. To learn more about Nextflow check out the [Nextflow community training portal](https://training.nextflow.io/latest/).

A simple workflow that sorts a file numerically and outputs the beginning of the sorted list.

```nf
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
```
```console
nextflow run snippets/simple.nf
```
```
N E X T F L O W  ~  version 23.10.1
Launching `snippets/simple.nf` [compassionate_baekeland] DSL2 - revision: 9f2812f5c5
executor >  local (2)
[51/9c24ee] process > SORT [100%] 1 of 1 ?
[10/f6db22] process > TOPN [100%] 1 of 1 ?
1
2
3
4
5
6
7
8
9
10
```

For those coming from WDL (like myself), here's a summary.

A Nextflow workflow is made by joining together different [processes](https://www.nextflow.io/docs/latest/process.html) (WDL tasks).

```nf
process < name > {

  [ directives ]

  input:
    < process inputs >

  output:
    < process outputs >

  when:
    < condition >

  [script|shell|exec]:
    < user script to be executed >

}
```

The [process](https://training.nextflow.io/basic_training/processes/) body can contain up to five definition blocks:

1. **Directives** are initial declarations that define optional settings
2. **Input** defines the expected input channel(s)
3. **Output** defines the expected output channel(s)
4. **When** is an optional clause statement to allow conditional processes
5. **Script** is a string statement that defines the command to be executed by the process' task

Directives are like the `runtime` options in WDL but are declared inside the process.

In WDL:

```wdl
runtime {
  cpu: 2
}
```

In Nextflow:

```nf
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

To set the resource usage for all processes in the workflow script use the code below in a config file.

```nf
process {
    cpus = 10
    memory = 8.GB
    container = 'biocontainers/bamtools:v2.4.0_cv3'
}
```

Use a [process selector](https://www.nextflow.io/docs/latest/config.html#process-selectors) to apply configurations to specific processes or group of processes.

[Configure process by name](https://training.nextflow.io/basic_training/executors/#configure-process-by-name).

```nf
process {
    executor = 'slurm'
    queue = 'short'
    memory = '10 GB'
    time = '30 min'
    cpus = 4

    withName: PROCESSNAME {
        cpus = 2
        memory = '20 GB'
        queue = 'short'
    }
}
```

[Configure process by label](https://training.nextflow.io/basic_training/executors/#configure-process-by-labels).

```nf
process TASK1 {
    label 'long'

    script:
    """
    first_command --here
    """
}
```

Config.

```nf
process {
    executor = 'slurm'

    withLabel: 'long' {
        cpus = 8
        memory = '32 GB'
        queue = 'omega'
        container = 'some/image:x'
    }
}

docker.enabled = true
```

The [workflow](https://www.nextflow.io/docs/latest/dsl2.html#workflow) keyword allows the definition of sub-workflow components that enclose the invocation of one or more processes and operators.

```nf
workflow my_pipeline {
    take: data
    main:
        foo(data)
        bar(foo.out)
}
```

Processes are executed independently and are isolated from each other; they communicate with each other through `channels`. Any `process` can define one or more `channels` as an `input` and `output`.

Output of a process is accessed using the `out` channel, instead of using the defined output in WDL.

```nf
workflow {
    STRING_TO_FILE(params.string)
    CAT_FILE(STRING_TO_FILE.out)
    CAT_FILE.out.view()
}
```

However, the process output definition allows the use of the `emit` statement to define a named identifier that can be used to reference the channel in the external scope (but `out` still needs to be used as the prefix).

```nf
process CONVERTTOUPPER {
    input:
    path y

    output:
    stdout emit: upper

    script:
    """
    cat $y | tr '[a-z]' '[A-Z]'
    """
}

workflow {
    greeting_ch = Channel.of(params.greeting)
    SPLITLETTERS(greeting_ch)
    CONVERTTOUPPER(SPLITLETTERS.out.flatten())
    CONVERTTOUPPER.out.upper.view { it }
}
```

Pipeline results are also stored in directories with random names (hashes) but process results are not named by the process name (WDL task outputs are stored in directories named with `call-task_name`). `STDOUT` and `STDERR` are also saved but as hidden files in Nextflow.

Use a YAML (JSON in WDL) file to specify parameters. Parameters used with `nextflow run` are referenced using `params.argv` in the Nextflow script.

```console
nextflow run kallisto.nf -params-file kallisto.yaml --samples <input_file>
```

Nextflow keeps track of all the processes executed in your workflow. If you modify some parts of your script, only the processes that are changed will be re-executed. No need to setup call caching like for WDL/Cromwell; just include a `cache` directive in the process to store the process results to a local cache and launch the pipeline with `-resume`.

```console
nextflow run hello.nf -resume
```

Sub-workflows are [also supported in Nextflow](https://carpentries-incubator.github.io/workflows-nextflow/11-subworkflows/index.html); use `include` (`import` in WDL). Give a (sub-)workflow a name and then you can include it in another script.

```nf
# sub_wf.nf
workflow SUB_WORKFLOW {
    STRING_TO_FILE(params.string)
    CAT_FILE(STRING_TO_FILE.out)
    CAT_FILE.out.view()
}

# sub_wf_include.nf
include {SUB_WORKFLOW} from './sub_wf.nf'

workflow {
    SUB_WORKFLOW()
}
```

Use `-c my_config` to specify a [config file](https://www.nextflow.io/docs/latest/config.html) (`-o cromwell_options.txt` in Cromwell). As I understand from the [Nextflow configuration](https://training.nextflow.io/basic_training/config/) guide, the execution settings and workflow parameter settings can be stored into a single file. Though I think it's better separate the two; use the `-params-file` option to specify the file with the workflow parameters and `-c` to specify the file with the workflow execution parameters.

## WDL versus Nextflow

The following is generated by Seqera AI (but my formatting) with the following prompt:

> I used to develop workflows using WDL and Cromwell. However I would like to start writing workflows using Nextflow. What would be the best way to transition from WDL + Cromwell to Nextflow?

Based on my search results, I can provide you with a comprehensive guide for transitioning from WDL + Cromwell to Nextflow. Here's the best approach:

Key Conceptual Differences to Understand

1. Data Flow Philosophy
    * WDL: Uses explicit task invocation and scatter functions for batch processing
    * Nextflow: Uses channels for implicit data flow between processes, inspired by Unix pipeline philosophy
2. Parallelization Approach
    * WDL: Explicit scatter functions for parallel execution
    * Nextflow: Automatic parallelization through channels - when data flows through channels, Nextflow automatically parallelizes execution
3. Language Structure
    * WDL: Tasks + workflows with explicit connections
    * Nextflow: Processes + workflows with channel-based connections

Recommended Learning Path

Step 1: Start with Hello Nextflow Tutorial

Begin with the Hello Nextflow tutorial series at training.nextflow.io. This web-based training uses Gitpod and doesn't require installing anything on your computer. It covers:

* Part 1: Hello World (basic process and workflow structure)
* Part 2: Hello Channels (understanding data flow)
* Part 3: Hello Workflow (connecting processes)
* Part 4: Hello Modules (modularization)
* Part 5: Hello Containers (containerization)
* Part 6: Hello Config (configuration management)

Step 2: Understand Core Nextflow Concepts

Channels (most important difference from WDL):

* Think of channels as data streams that automatically handle parallelization
* No need for explicit scatter operations like in WDL
* Channels can hold single values, lists, or result sets

Processes vs Tasks:

* Nextflow processes are essentially equivalent to WDL tasks
* Both define computational steps with inputs, outputs, and commands

Operators:

* Nextflow has powerful operators like map, flatMap, filter for data manipulation
* These replace much of the explicit data handling you'd do in WDL

Step 3: Migration Strategy

1. Start Simple: Convert one WDL task to a Nextflow process
2. Focus on Data Flow: Replace WDL scatter operations with Nextflow channels
3. Leverage Existing Pipelines: Check if there's already an nf-core pipeline for your use case
4. Use Containers: Both WDL and Nextflow support containers - this part should be familiar

Step 4: Advanced Training

After mastering the basics, proceed to the Fundamentals Training which covers:

* Advanced channel operations
* Configuration management
* Deployment scenarios
* Troubleshooting

Key Advantages You'll Gain

1. Simpler Parallelization: No need for explicit scatter/gather - channels handle this automatically
2. More Compact Code: Channel operators allow for more concise, readable scripts
3. Better Resume Capability: Nextflow's caching and resume functionality is very robust
4. Rich Ecosystem: Access to nf-core pipelines and modules
5. Flexible Deployment: Easy deployment across different compute environments

Practical Tips for WDL Users

1. Don't overthink channels initially - start with simple examples and build complexity gradually
2. Use the `-resume` flag liberally during development - it's more powerful than Cromwell's call caching
3. Leverage nf-core modules instead of writing everything from scratch
4. Configuration is more flexible - you can override almost anything without modifying the main script

Getting Help

* Nextflow Slack: Active community for questions
* Seqera Community Forum: For more detailed discussions
* Documentation: Comprehensive docs at nextflow.io

The transition from WDL to Nextflow is very manageable, especially since you already understand workflow concepts. The main learning curve is understanding channels, but once that clicks, you'll likely find Nextflow more intuitive and powerful for complex data processing pipelines.

> It seems like the channel concept is the most important to understand. Can you provide a nice summary that focuses on the most important aspects to understand with respect to a channel or channels?

What Are Channels?

*Channels are asynchronous data streams* that connect processes in your workflow. Think of them as "pipes" that carry data between different steps of your pipeline.

Key Concepts to Understand

1. Automatic Parallelization (The Big Difference from WDL)

    * In WDL: You explicitly use `scatter` to parallelize tasks
    * In Nextflow: When data flows through a channel, Nextflow automatically parallelizes the execution
    * If a channel contains 5 items, and you connect it to a process, that process will run 5 times in parallel automatically

2. Asynchronous Nature

    * You cannot directly access channel contents like a regular variable
    * You can only interact with channels through operators or by passing them to processes
    * The order of outputs is not guaranteed because of parallel execution

3. Channel Types

Queue Channels (most common):

* Can be consumed multiple times
* Automatically fork when connected to multiple processes
* Example: `Channel.of(1, 2, 3)`

Value Channels:

* Hold a single value
* Can be read multiple times without being consumed
* Example: `Channel.value("hello")`

Essential Channel Operations

Channel Factories (Creating Channels)

```nextflow
// From values
Channel.of('sample1', 'sample2', 'sample3')

// From files
Channel.fromPath('data/*.fastq')

// From file pairs
Channel.fromFilePairs('data/*_{1,2}.fastq')
```

Channel Operators (Transforming Channels)

```nextflow
Channel.of('hello', 'world')
    .map { it.toUpperCase() }        // Transform each item
    .filter { it.length() > 4 }      // Keep only items that match condition
    .view()                          // Print each item (for debugging)
```

Connecting to Processes

```nextflow
process EXAMPLE {
    input:
    val sample_name    // Channel input

    script:
    """
    echo "Processing ${sample_name}"
    """
}

workflow {
    Channel.of('sample1', 'sample2', 'sample3') | EXAMPLE
}
```

The Mental Model Shift

WDL Thinking:

```wdl
scatter (sample in samples) {
    call process { input: sample_name = sample }
}
```

Nextflow Thinking:

```nextflow
Channel.of(samples) | process
// Nextflow automatically runs 'process' for each item in the channel
```

Practical Examples

Simple Data Flow

```nextflow
Channel.of('sample1', 'sample2', 'sample3')
    .map { sample -> [sample, "${sample}.fastq"] }  // Create [name, file] pairs
    .view { name, file -> "Sample: ${name}, File: ${file}" }
```

File Processing

```nextflow
Channel.fromPath('*.fastq')
    .map { file -> [file.baseName, file] }  // [sample_name, file_path]
    | PROCESS_FASTQ
```

Key Debugging Tool: `.view()`

* Always use `.view()` to inspect what's flowing through your channels:

```nextflow
Channel.of('a', 'b', 'c')
    .view { "Before map: ${it}" }
    .map { it.toUpperCase() }
    .view { "After map: ${it}" }
```

Common Patterns

CSV Input Processing

```nextflow
Channel.fromPath('samples.csv')
    .splitCsv(header: true)
    .map { row -> [row.sample_id, row.fastq_1, row.fastq_2] }
    | PROCESS_SAMPLES
```

Combining Channels

```nextflow
samples_ch = Channel.of('sample1', 'sample2')
reference_ch = Channel.value('reference.fa')

samples_ch.combine(reference_ch)  // Each sample paired with reference
```

The Power of This Approach

1. Implicit Parallelization: No need to explicitly manage parallel execution
2. Automatic Scaling: Works the same whether you have 1 sample or 1000
3. Clean Syntax: Data flow is visually clear in your code
4. Fault Tolerance: Failed tasks can be retried without affecting others

Remember:

* Channels are streams, not variables
* Parallelization happens automatically
* Use operators to transform data as it flows
* Use `.view()` liberally for debugging
* The order of parallel outputs is not guaranteed

Once you internalize that channels are *data streams that automatically parallelize your work*, the rest of Nextflow becomes much more intuitive. The channel concept is what makes Nextflow particularly powerful for bioinformatics workflows where you often need to process many samples in parallel.

## Installation

On Debian 11 install the Java Runtime Environment and simply download/run the
install script.

```console
sudo apt install default-jre
curl -fsSL get.nextflow.io | bash
```

Otherwise [Conda](https://docs.conda.io/en/latest/) is another way of
installing [Nextflow](https://anaconda.org/bioconda/nextflow). I would
recommend using [Mamba](https://github.com/mamba-org/mamba), which is a faster
version of Conda, to install Nextflow.

```console
mamba create -y \
   -n nextflow \
   -c Bioconda -c conda-forge \
   nextflow

conda activate nextflow

nextflow -version
#
#       N E X T F L O W
#       version 22.10.6 build 5843
#       created 23-01-2023 23:20 UTC (24-01-2023 08:20 JDT)
#       cite doi:10.1038/nbt.3820
#       http://nextflow.io
#

java -version
# openjdk version "17.0.3-internal" 2022-04-19
# OpenJDK Runtime Environment (build 17.0.3-internal+0-adhoc..src)
# OpenJDK 64-Bit Server VM (build 17.0.3-internal+0-adhoc..src, mixed mode, sharing)
```

## Quick demo

Get [training material](https://training.nextflow.io/basic_training/setup/#training-material).

```console
git clone https://github.com/nextflow-io/training.git
```

Run a simple RNA-seq workflow with [metrics and reporting](https://training.nextflow.io/basic_training/rnaseq_pipeline/#metrics-and-reports).

```console
cd training/nf-training/
nextflow run rnaseq-nf -with-docker -with-report -with-trace -with-timeline -with-dag dag.png
```

![](assets/quick_demo_dag.png)

### Run a project from GitHub

Nextflow allows the execution of a workflow project directly from a
[GitHub](https://training.nextflow.io/basic_training/rnaseq_pipeline/#metrics-and-reports)
repository (or similar services, e.g., BitBucket and GitLab).

This simplifies the sharing and deployment of complex projects and tracking
changes in a consistent manner.

Use `info` to show the project information:

```console
nextflow info nextflow-io/rnaseq-nf
```
```
 project name: nextflow-io/rnaseq-nf
 repository  : https://github.com/nextflow-io/rnaseq-nf
 local path  : /home/dtang/.nextflow/assets/nextflow-io/rnaseq-nf
 main script : main.nf
 description : Proof of concept of a RNA-seq pipeline implemented with Nextflow
 author      : Paolo Di Tommaso
 revisions   :
 * master (default)
   dev
   dsl2
   enum
   fix-schema
   hybrid
   json-schema-test
   k8s-demo
   programmatic-api
   properties
   sra-demo
   wave
   v1.0 [t]
   v1.1 [t]
   v1.2 [t]
   v2.0 [t]
   v2.1 [t]
   v2.2 [t]
   v2.3 [t]
```

Revision are defined by using Git tags or branches defined in the project
repository. Tags enable precise control of the changes in your project files
and dependencies over time.

Nextflow allows the execution of a specific revision of your project by using
the `-r` command line option.

```console
nextflow run nextflow-io/rnaseq-nf -r v2.3 -with-docker
```

## Set up for testing purposes only

1. Java 11 or later is required (up to 19 is supported);
   `script/install_openjdk.sh` will install OpenJDK 19 into `bin`. Do not
   install version 20 or you will get the following error:

    ERROR: Cannot find Java or it's a wrong version -- please make sure that Java 8 or later (up to 19) is installed

```console
script/install_openjdk.sh

bin/jdk-19.0.2/bin/java -version
# openjdk version "19.0.2" 2023-01-17
# OpenJDK Runtime Environment (build 19.0.2+7-44)
# OpenJDK 64-Bit Server VM (build 19.0.2+7-44, mixed mode, sharing)
```

2. Install Nextflow.

```console
export PATH=$(pwd)/bin/jdk-19.0.2/bin:$PATH
curl -s https://get.nextflow.io | bash
# snipped
#       N E X T F L O W
#       version 23.04.0 build 5857
#       created 01-04-2023 21:09 UTC (02-04-2023 06:09 JDT)
#       cite doi:10.1038/nbt.3820
#       http://nextflow.io
#
# Nextflow installation completed. Please note:
# - the executable file `nextflow` has been created in the folder: /home/dtang/github/learning_nextflow
# - you may complete the installation by moving it to a directory in your $PATH

mv nextflow bin/jdk-19.0.2/bin/
```

3. Hello world example.

```console
nextflow run hello
# N E X T F L O W  ~  version 23.04.0
# Pulling nextflow-io/hello ...
#  downloaded from https://github.com/nextflow-io/hello.git
# Launching `https://github.com/nextflow-io/hello` [fervent_mendel] DSL2 - revision: 1d71f857bb [master]
# executor >  local (4)
# [ae/272202] process > sayHello (4) [100%] 4 of 4 ✔
# Bonjour world!
#
# Ciao world!
#
# Hello world!
#
# Hola world!
```

## Nextflow tutorial

[Introduction to Bioinformatics workflows with Nextflow and
nf-core](https://carpentries-incubator.github.io/workflows-nextflow/index.html) lesson objectives:

1. The learner will understand the fundamental components of a Nextflow script,
   including channels, processes and operators.
2. The learner will write a multi-step workflow script to align, quantify, and
   perform QC on an RNA-Seq data in Nextflow DSL.
3. The learner will be able to write a Nextflow configuration file to alter the
   computational resources allocated to a process.
4. The learner will use nf-core to run a community curated pipeline, on an
   RNA-Seq dataset.

Nextflow is a workflow management system that combines a runtime environment,
software that is designed to run other software, and a programming domain
specific language (DSL) that eases the writing of computational pipelines.

Nextflow is built around the idea that Linux is the _lingua franca_ of data
science. Nextflow follows Linux's "small pieces loosely joined" philosophy, in
which many simple but powerful command-line and scripting tools, when chained
together, facilitate more complex data manipulations.

Nextflow extends this approach, adding the ability to define complex program
interactions and an accessible (high-level) parallel computational environment
based on the dataflow programming model, whereby `processes` are connected via
their `outputs` and `inputs` to other `processes`, and run as soon as they
receive an input.

The Nextflow scripting language is an extension of the Groovy programming
language, which in turn is a superset of the Java programming language. Groovy
simplifies the writing of code and is more approachable than Java; see Groovy's
[semantics](https://groovy-lang.org/semantics.html).

Nextflow (version > 20.07.1) provides a revised syntax to the original DSL,
known as DSL2. This feature is enabled by the following directive at the
beginning of a workflow script:

    nextflow.enable.dsl=2

### Processes, channels, and workflows

Nextflow workflows have three main parts:

1. Processes - describe a task to be run and can be written in any scripting
	 language that can be executed on Linux (e.g. Bash, Perl, Python, etc.). They
   define inputs and outputs for a task. Processes spawn a task for each complete
   input set and each task is executed independently and cannot interact with
	 another task. The only way data can be passed between process tasks is via
   asynchronous queues, called channels.
2. Channels - channels are used to manipulate the flow of data from one process
   to the next.
3. Workflows - this section is used to explicitly define the interaction
   between processes and the pipeline execution flow.

![Nextflow process flow diagram](img/channel-process_fqc.png)

In the example above we have a `samples` channel containing three input FASTQ
files. The `fastqc` process takes the `samples` channel as input and since the
channel has three elements, three independent instances (tasks) of that process
are run in parallel. Each task generates an output, which is passed to the
`out_ch` channel and is used as input for the `multiqc` process.

While a `process` defines what command or script has to be executed, the
`executor` determines how that script will be run in the target system. The
default is to execute processes on the local computer, which is useful for
pipeline development, testing, and small scale workflows. For large scale
computational pipelines, a High Performance Cluster (HPC) or Cloud platform is
desired.

![Nextflow executors](img/executor.png)

Nextflow provides a separation between the pipeline's functional logic and the
underlying execution platform. This makes it easy to execute a pipeline on
various platforms without modifying the workflow and is achieved by defining
the target execution platform in a configuration file.

Nextflow provides [native
support](https://www.nextflow.io/docs/latest/executor.html) for major batch
schedulers and cloud platforms including SGE, SLURM, AWS, and Kubernetes.

### First script

The `wc.nf` script counts the number of lines in a FASTQ file.

```console
nextflow run script/wc.nf
# N E X T F L O W  ~  version 23.04.0
# Launching `script/wc.nf` [stoic_easley] DSL2 - revision: 9cef523068
# executor >  local (1)
# [6b/286e0b] process > NUM_LINES (1) [100%] 1 of 1 ✔
# ref1_1.fq.gz 58708
```

## nf-core

A [community effort](https://nf-co.re/) to collect a curated set of analysis
pipelines built using Nextflow.

### tools

The nf-core companion [tool](https://nf-co.re/tools) can be used to help with
common tasks.

```console
mamba create --name nf-core -c bioconda python=3.11 nf-core nextflow
```

List workflows.

```console
nf-core list | less
```

Set [$NXF_SINGULARITY_CACHEDIR](https://nf-co.re/tools#singularity-cache-directory):

>If found, the tool will fetch the Singularity images to this directory first before copying to the target output archive / directory. Any images previously fetched will be found there and copied directly - this includes images that may be shared with other pipelines or previous pipeline version downloads or download attempts.

Set the cache directory and download nf-core/sarek workflow.

```console
export NXF_SINGULARITY_CACHEDIR=/some/dir

nf-core download sarek -r 3.4.0 --outdir nf-core-sarek --compress none --container-system singularity -p 4
```

The `create` subcommand makes a new pipeline using the nf-core base template. With a given pipeline name, description and author, it makes a starter pipeline which follows nf-core best practices.

After creating the files, the command initialises the folder as a git repository and makes an initial commit. This first "vanilla" commit which is identical to the output from the templating tool is important, as it allows us to keep your pipeline in sync with the base template in the future.

The workflow name needs to be lowercase without punctuation. The `--plain` option will run the pipeline creation process silently with the nf-core template.

```console
nf-core create -n xyzseq -d "This pipeline analyses data generated from method xyz" -a "Dave Tang" --plain
```
```
INFO     Creating new nf-core pipeline: 'nf-core/xyzseq'
INFO     Initialising pipeline git repository
INFO     Done. Remember to add a remote and push to GitHub:
          cd /home/dtang/tmp/nf-core-xyzseq
          git remote add origin git@github.com:USERNAME/REPO_NAME.git
          git push --all origin
INFO     This will also push your newly created dev branch and the TEMPLATE branch for syncing.
INFO     !!!!!! IMPORTANT !!!!!!

         If you are interested in adding your pipeline to the nf-core community,
         PLEASE COME AND TALK TO US IN THE NF-CORE SLACK BEFORE WRITING ANY CODE!

         Please read: https://nf-co.re/developers/adding_pipelines#join-the-community
```

Template structure.

```console
tree --charset ascii -L 1 nf-core-xyzseq/
```
```
nf-core-xyzseq/
|-- assets
|-- CHANGELOG.md
|-- CITATIONS.md
|-- CODE_OF_CONDUCT.md
|-- conf
|-- docs
|-- LICENSE
|-- main.nf
|-- modules
|-- modules.json
|-- nextflow.config
|-- nextflow_schema.json
|-- pyproject.toml
|-- README.md
|-- subworkflows
|-- tower.yml
`-- workflows

7 directories, 11 files
```

The nf-core `create` command comes with a number of options that allow you to customise the creation of a pipeline if you intend to not publish it as an nf-core pipeline. This can be done in two ways:

1. By using interactive prompts, or
2. By supplying a template.yml file using the `--template-yaml` <file> option.

Both options allow you to specify a custom pipeline prefix to use instead of the common nf-core, as well as selecting parts of the template to be excluded during pipeline creation. The interactive prompts will guide you through the pipeline creation process. An example of a template.yml file is shown below.

```yaml
name: coolpipe
description: A cool pipeline
author: me
prefix: myorg
skip:
  - github
  - ci
  - github_badges
  - igenomes
  - nf_core_configs
```

This will create a pipeline called coolpipe in the directory myorg-coolpipe (<prefix>-<name>) with me as the author. It will exclude all possible parts of the template:

* github: removed all files required for GitHub hosting of the pipeline. Specifically, the .github folder and .gitignore file.
* ci: removes the GitHub continuous integration tests from the pipeline. Specifically, the .github/workflows/ folder.
* github_badges: removes GitHub badges from the README.md file.
* igenomes: removes pipeline options related to iGenomes. Including the conf/igenomes.config file and all references to it.
* nf_core_configs: excludes nf_core/configs repository options, which make multiple config profiles for various institutional clusters available.

### Reference genomes

<https://nf-co.re/docs/usage/reference_genomes>

> To make the use of reference genomes easier, Illumina has developed a centralised resource called iGenomes. The most commonly used reference genome files are organised in a consistent structure for multiple genomes.
>
> We have uploaded a copy of iGenomes onto AWS S3 and nf-core pipelines are configured to use this by default. AWS iGenomes is hosted by Amazon as part of the Registry of Open Data and are free to use.
>
> Downloading reference genome files takes time and bandwidth so, if possible, we recommend storing a local copy of your relevant iGenomes references which is outlined at https://ewels.github.io/AWS-iGenomes/.
>
> To use a local version of iGenomes, the variable params.igenomes_base must be set to the path of the local iGenomes folder to reflect what is defined in conf/igenomes.config.

To download using AWSCLI, for example:

```console
mkdir -p ./references/Homo_sapiens/GATK/GRCh38/
aws s3 --no-sign-request --region eu-west-1 sync s3://ngi-igenomes/igenomes/Homo_sapiens/GATK/GRCh38/ ./references/Homo_sapiens/GATK/GRCh38/
```

The config file `conf/igenomes.config` looks like this:

```
'GATK.GRCh38' {
            ascat_alleles           = "${params.igenomes_base}/Homo_sapiens/GATK/GRCh38/Annotation/ASCAT/G1000_alleles_hg38.zip"
            ascat_genome            = 'hg38'
            ascat_loci              = "${params.igenomes_base}/Homo_sapiens/GATK/GRCh38/Annotation/ASCAT/G1000_loci_hg38.zip"
            ascat_loci_gc           = "${params.igenomes_base}/Homo_sapiens/GATK/GRCh38/Annotation/ASCAT/GC_G1000_hg38.zip"
            ascat_loci_rt           = "${params.igenomes_base}/Homo_sapiens/GATK/GRCh38/Annotation/ASCAT/RT_G1000_hg38.zip"
            bwa                     = "${params.igenomes_base}/Homo_sapiens/GATK/GRCh38/Sequence/BWAIndex/"
```

> The iGenomes config file uses params.igenomes_base to make it possible to use a local copy of iGenomes. However, as custom config files are loaded after nextflow.config and the igenomes.config has already been imported and parsed, setting params.igenomes_base in a custom config file has no effect and the pipeline will use the s3 locations by default. To overcome this you can specify a local iGenomes path by either:

Specifying an `--igenomes_base` path in your execution command.

```console
nextflow run nf-core/<pipeline> --input <input> -c <config> -profile <profile> --igenomes_base <path>/<to>/<data>/igenomes
```

Specifying the igenomes_base parameter in a parameters file provided with `-params-file` in YAML or JSON format.

```console
nextflow run nf-core/<pipeline> -profile <profile> -params-file params.yml
```

Where the `params.yml` file contains the pipeline params:

```
input: '/<path>/<to>/<data>/input'
igenomes_base: '/<path>/<to>/<data>/igenomes'
```

### Sarek

[nf-core/sarek](https://nf-co.re/sarek) is a Nextflow workflow for calling
variants on whole genome, exome, or targeted sequencing data.

In the directory where we [downloaded Sarek](#tools), run the following; set `NXF_SINGULARITY_CACHEDIR` (where Singularity images are downloaded) and `IGENOMES_BASE` (where the reference files were downloaded) accordingly.

```console
export NXF_SINGULARITY_CACHEDIR=/dir/to/images
IGENOMES_BASE=/data/references
nextflow run main.nf -profile test,singularity --outdir test_out --igenomes_base ${IGENOMES_BASE}

# snipped
# -[nf-core/sarek] Pipeline completed successfully-
# snipped
```

See the [usage page](https://nf-co.re/sarek/usage) for more information. I have a full example in another [repo](https://github.com/davetang/vcf_example).

## Quick reference

Notes for common tasks that I regularly forget!

### Workflow execution

Useful parameters to include when running a workflow.

```console
nextflow run \
   -resume \                               # caching results
   -with-report execution_report.html \    # provenance
   -with-trace \                           # resource usage
   -with-dag flowchart.html \              # Mermaid workflow graph
   -params-file params.yml \               # input parameters
   -c nextflow.config \                    # execution settings
   script.nf                               # Nextflow script
```

### Input parameters

[When](https://www.nextflow.io/docs/latest/config.html) a pipeline script is launched, Nextflow looks for configuration files in multiple locations. Since each configuration file may contain conflicting settings, they are applied in the following order (from lowest to highest priority):

1. (lowest priority) Parameters defined in pipeline scripts (e.g. `main.nf`)
2. The config file `$HOME/.nextflow/config`
3. The config file `nextflow.config` in the project directory
4. The config file `nextflow.config` in the launch directory
5. Config file specified using the `-c <config-file>` option
6. Parameters specified in a params file (`-params-file` option)
7. (highest priority) Parameters specified on the command line (`--something` value)

Store parameters in JSON or YAML and reference with `params` prefix in Nextflow script.

```console
nextflow run -params-file params.yml snippets/params.nf
```
```
N E X T F L O W  ~  version 23.10.1
Launching `snippets/params.nf` [admiring_newton] DSL2 - revision: 96ae723ae2
executor >  local (1)
[a4/e89bf9] process > HELLO (1) [100%] 1 of 1 ?
Hello, how are you?
```

A parameter file has higher priority than a parameter set in the script.

```console
nextflow run script/nproc.nf
```
```
snipped
there are 4 processors available
process ECHO is using 1 cpu/s
Konnichiwa
```

Use parameter in `params.yml`.

```console
nextflow run -params-file params.yml script/nproc.nf
```
```
snipped
there are 4 processors available
process ECHO is using 1 cpu/s
Hello, how are you?
```

Use parameter and config file.

```console
nextflow run -params-file params.yml -c example.config script/nproc.nf
```
```
snipped
there are 4 processors available
process ECHO is using 2 cpu/s
Hello, how are you?
```

Pass parameter from the command line, which has the highest priority.

```console
nextflow run -params-file params.yml -c example.config --greeting "Highest priority" script/nproc.nf
```
```
snipped
there are 6 processors available
process ECHO is using 2 cpu/s
Highest priority
```

### Read samplesheet

Use the [splitCsv](https://www.nextflow.io/docs/latest/operator.html#splitcsv)
operator.

```nf
Channel
    .fromPath("$HOME/github/learning_nextflow/basic/samplesheet.csv")
    .splitCsv(header: ['sample_name', 'first', 'second'])
    // row is a list object
    .view { row -> "${row.first} ${row.second}" }
```

Run.

```console
nextflow run basic/script/split_csv.nf
```
```
N E X T F L O W  ~  version 23.10.1
Launching `basic/script/split_csv.nf` [cranky_boltzmann] DSL2 - revision: 54308421ee
normal_1.fq.gz normal_2.fq.gz
tumour_1.fq.gz tumour_2.fq.gz
```

### Resource allocation

A pipeline may fail due to a particular step of the pipeline requesting more resources than you have on your system. To avoid these failures, all nf-core pipelines check pipeline-step resource requests against [parameters](https://nf-co.re/docs/usage/configuration#max-resources) called `--max_cpus`, `--max_memory` and `--max_time`. These should represent the maximum possible resources of a machine or node.

### Singularity

[Run with Singularity](https://www.nextflow.io/docs/latest/singularity.html).

    nextflow run <your script> -with-singularity [singularity image file]

```console
singularity pull docker://debian:12.4
singularity pull docker://debian:11.8
nextflow run snippets/os.nf -with-singularity debian_12.4.sif
```
```
N E X T F L O W  ~  version 23.10.1
Launching `snippets/os.nf` [soggy_church] DSL2 - revision: 9c2a106435
executor >  local (1)
[26/92c571] process > GETOS [100%] 1 of 1 ?
PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"
NAME="Debian GNU/Linux"
VERSION_ID="12"
VERSION="12 (bookworm)"
VERSION_CODENAME=bookworm
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
```

Define in the Nextflow configuration file `nextflow.config`:

    process.container = '/path/to/singularity.img'
    singularity.enabled = true

Define multiple containers in `nextflow_os.config`. Note that the executor is set to `sge` (Sun Grid Engine or equivalent); change this to `local` and remove the `clusterOptions` line if you do not have a grid engine queuing system. (The cluster option explicitly states the use of `/bin/bash`; my queue has been set to use `/bin/sh`, which I can change using `qconf -mq`, but perhaps it is better use the cluster option since not everyone has permission to modify the queue settings.)

```nf
process {
    withName:GETOS {
        container = "$HOME/github/learning_nextflow/debian_12.4.sif"
    }
    withName:GETOS2 {
        container = "$HOME/github/learning_nextflow/debian_11.8.sif"
    }

    executor = 'sge'
    clusterOptions = '-S /bin/bash'
}
singularity {
    enabled = true
}
```

Run.

```console
nextflow run snippets/os_wf.nf -c nextflow_os.config
```
```
N E X T F L O W  ~  version 23.10.1
Launching `snippets/os_wf.nf` [fervent_babbage] DSL2 - revision: 889a3d08d5
executor >  sge (2)
[c7/9d8d9c] process > GETOS  [100%] 1 of 1
[7e/ce8b28] process > GETOS2 [100%] 1 of 1
PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"
NAME="Debian GNU/Linux"
VERSION_ID="12"
VERSION="12 (bookworm)"
VERSION_CODENAME=bookworm
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"

PRETTY_NAME="Debian GNU/Linux 11 (bullseye)"
NAME="Debian GNU/Linux"
VERSION_ID="11"
VERSION="11 (bullseye)"
VERSION_CODENAME=bullseye
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
```

## Troubleshooting

When using `sge`:

```
Command output:
  Unable to run job: "job" denied: use parallel environments instead of requesting slots explicitly
  Exiting.
```

This is because the queue uses the following parallel settings.

```console
qconf -sq all.q | grep pe_list
```
```
pe_list               make smp mpi
```

In `nextflow.config` use the following:

```
process {
    executor = 'sge'
    penv = 'smp'
    clusterOptions = '-S /bin/bash'
}
```

The demo in <https://github.com/davetang/learning_nextflow/tree/main/cpus> shows that using `-process.cpus=4` does not work when a process has a label that corresponds to a setting in a config file. This was suspected when I was trying to [set up](https://github.com/davetang/immune_repertoire?tab=readme-ov-file#troubleshooting) `nf-core/airrflow` and confirmed with the demo.
