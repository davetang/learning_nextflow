## README

Run `cpus.nf` workflow.

```console
nextflow run cpus.nf
```
```
 N E X T F L O W   ~  version 24.04.4

Launching `cpus.nf` [shrivelled_stone] DSL2 - revision: 3cce8bd686

executor >  local (2)
[82/d8e0f0] NUM_PROCESSORS       | 0 of 1
[3a/642cb4] NUM_PROCESSORS_LABEL | 0 of 1

executor >  local (2)
[82/d8e0f0] NUM_PROCESSORS       | 1 of 1 ✔
[3a/642cb4] NUM_PROCESSORS_LABEL | 1 of 1 ✔
there are 6 processors available
process NUM_PROCESSORS is using 1 cpu/s

there are 6 processors available
process NUM_PROCESSORS_LABEL is using 1 cpu/s
```

Use `-process.cpus=4` to control number of CPUs.

```console
nextflow run -process.cpus=4 cpus.nf
```
```
 N E X T F L O W   ~  version 24.04.4

Launching `cpus.nf` [confident_minsky] DSL2 - revision: 3cce8bd686

executor >  local (1)
[-        ] NUM_PROCESSORS       | 0 of 1
[ee/c9b444] NUM_PROCESSORS_LABEL | 0 of 1

executor >  local (2)
[dd/7c3ea6] NUM_PROCESSORS       | 1 of 1 ✔
[ee/c9b444] NUM_PROCESSORS_LABEL | 1 of 1 ✔
there are 6 processors available
process NUM_PROCESSORS is using 4 cpu/s

there are 6 processors available
process NUM_PROCESSORS_LABEL is using 4 cpu/s
```

Use `-process.cpus=4` and config file.

```console
nextflow run -process.cpus=4 -c base.config cpus.nf
```
```
there are 6 processors available
process NUM_PROCESSORS is using 4 cpu/s

there are 6 processors available
process NUM_PROCESSORS_LABEL is using 6 cpu/s
```
