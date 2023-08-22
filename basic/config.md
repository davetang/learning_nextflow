# Nextflow configuration

Based on the [basic training
material](https://training.nextflow.io/basic_training/config/).

Nextflow looks for a file named `nextflow.config` in the current directory and
in the script base directory when a workflow script is launched. Next it checks
for the file `$HOME/.nextflow/config`. If both these files exist they are
  merged with a higher precedence for the first file. In addition, a config
  file can be specified using the option `-c <config file>`.

The config file is a simple text file containing a set of properties defined
using the following syntax:

```
name = value
```

Note that values are typed, so `'1'` and `1` are different; the former will be
interpreted as a string (strings need to be wrapped in quotes) and the latter a
number. Numbers and booleans (`true` and `false`) do not need quotes.

Configuration properties can be used as variables in the configuration file. In
addition, environment variables such as `PATH`, `HOME`, `PWD`, etc. can be
used.

```nf
// comments work the same as a Nextflow script
propertyOne = 'world'
anotherProp = "Hello $propertyOne"
customPath = "$PATH:/my/app/folder"
```

Settings can be organised into different scopes by dot prefixing the property
names with a **scope** identifier or grouping with curly braces.

```nf
alpha.x  = 1
alpha.y  = 'string value..'

// no comma between the two names
beta {
  p = 2
  q = 'another string ..'
}
```

The scope `params` allows the definition of workflow parameters that
**override** the values defined in the main workflow script. Below is the order
of priority (highest to lowest):

1. Parameters specified on the command line (`--something value`)
2. Parameters provided using the `-params-file` option
3. Config file specified using the `-c my_config` option
4. The config file named `nextflow.config` in the current directory
5. The config file named `nextflow.config` in the workflow project directory
6. The config file `$HOME/.nextflow/config`
7. Values defined within the pipeline script itself

The `env` scope allows the definition of variables that will be exported into
the environment where the workflow tasks will be executed.

```nf
env.ALPHA = 'some value'
env.BETA = "$HOME/some/path"
```

## Config process

Process directives are used to specify settings for the process execution such
as `cpus`, `memory`, `container`, and other resources in the workflow script.

The `process` scope allows the setting of any `process` directive. Some useful
ones are:

* `cache`
* `clusterOptions`
* `conda` (Nextflow automatically sets up an environment!)
* `container` (Docker)
* `containerOptions`
* `debug` (forward `STDOUT` to the shell)
* `errorStrategy` and `maxErrors`
* `executor`
* `label` (annotate processes)
* `module` (Environment Modules)
* `publishDir` (publish output files to specified folder)
* `storeDir` (define directory for use as a permanent cache)
* `tag` (label for log file)

The following config sets the directives for **all processes** in the workflow
script.

```nf
process {
    cpus = 10
    memory = 8.GB
    container = 'biocontainers/bamtools:v2.4.0_cv3'
}
```

The [process
selector](https://www.nextflow.io/docs/latest/config.html#process-selectors)
can be used to apply configurations to a specific process or group of
processes. Use `withLabel` to configure processes annotated with a `label`
directive.

```nf
process {
    withLabel: big_mem {
        cpus = 16
        memory = 64.GB
        queue = 'long'
    }
}
```

## Conda

The use of a Conda environment can also be provided in the config file.

```nf
process.conda = "/home/ubuntu/miniconda2/envs/nf-tutorial"
```
