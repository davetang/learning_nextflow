# Snippets
2024-01-12

- [Nextflow version](#nextflow-version)
- [Hello](#hello)
- [When](#when)

## Nextflow version

``` bash
nextflow -v
```

    nextflow version 23.10.0.5889

## Hello

Script.

``` bash
cat hello.nf
```

    #!/usr/bin/env nextflow

    params.greeting = 'Hello world!'
    greeting_ch = Channel.of(params.greeting)

    process SPLITLETTERS {
        input:
        val x

        output:
        path 'chunk_*'

        script:
        """
        printf '$x' | split -b 6 - chunk_
        """
    }

    process CONVERTTOUPPER {
        input:
        path y

        output:
        stdout

        script:
        """
        cat $y | tr '[a-z]' '[A-Z]'
        """
    }

    workflow {
        letters_ch = SPLITLETTERS(greeting_ch)
        results_ch = CONVERTTOUPPER(letters_ch.flatten())
        results_ch.view { it }
    }

Run.

``` bash
nextflow hello.nf
```

    N E X T F L O W  ~  version 23.10.0
    Launching `hello.nf` [distraught_poincare] DSL2 - revision: dff419936a
    executor >  local (1)
    [08/9ff307] process > SPLITLETTERS (1) [100%] 1 of 1 ✔
    [-        ] process > CONVERTTOUPPER   -

    executor >  local (3)
    [08/9ff307] process > SPLITLETTERS (1)   [100%] 1 of 1 ✔
    [f2/7bcc41] process > CONVERTTOUPPER (1) [100%] 2 of 2 ✔
    WORLD!
    HELLO 

## When

The [when](https://training.nextflow.io/basic_training/processes/#when)
declaration allows you to define a condition that must be verified in
order to execute the process. This can be any expression that evaluates
a Boolean value.

``` bash
cat when.nf
```

    params.dbtype = 'nr'
    params.prot = 'keratin.fa'
    proteins = Channel.fromPath(params.prot)

    process FIND {
        debug true

        input:
        path fasta
        val type

        when:
        fasta.name =~ /keratin/ && type == 'nr'

        script:
        """
        echo blastp -query $fasta -db nr
        """
    }

    workflow {
        result = FIND(proteins, params.dbtype)
    }

Run.

``` bash
nextflow when.nf
```

    N E X T F L O W  ~  version 23.10.0
    Launching `when.nf` [tender_torvalds] DSL2 - revision: 2916f6924a
    executor >  local (1)
    [b5/1100dd] process > FIND (1) [100%] 1 of 1 ✔
    blastp -query keratin.fa -db nr
