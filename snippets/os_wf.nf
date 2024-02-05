include { GETOS } from './os.nf'
include { GETOS as GETOS2 } from './os.nf'

workflow {
    GETOS().view { it }
    GETOS2().view { it }
}
