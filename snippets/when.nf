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
