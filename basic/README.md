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
