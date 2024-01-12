# Snippets
2024-01-12

- [Nextflow version](#nextflow-version)
- [Hello](#hello)

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
    Launching `hello.nf` [tender_majorana] DSL2 - revision: dff419936a
    executor >  local (1)
    [5f/129772] process > SPLITLETTERS (1) [100%] 1 of 1 ✔
    [-        ] process > CONVERTTOUPPER   -

    executor >  local (3)
    [5f/129772] process > SPLITLETTERS (1)   [100%] 1 of 1 ✔
    [30/8e370b] process > CONVERTTOUPPER (2) [100%] 2 of 2 ✔
    HELLO 
    WORLD!
