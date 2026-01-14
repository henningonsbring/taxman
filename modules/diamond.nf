process diamond_blastx {

    tag "$sample"

    publishDir "${params.outdir}/diamond", mode: 'copy'

    input:
    tuple val(sample), path(transcripts_file)

    output:
    tuple val(sample), path("${sample}_vs_nr.tsv")

    script:
    """
    echo "Running diamond blastx for sample: $sample"
    echo "Input transcripts: \$(basename ${transcripts_file})"
    echo "Database: ${params.diamond_db}"
    echo "Threads: ${params.diamond_threads}"
    echo ""

    ${params.diamond_path} blastx \
        --threads ${params.diamond_threads} \
        --evalue ${params.diamond_evalue} \
        --max-target-seqs ${params.diamond_max_target_seqs} \
        --outfmt 6 qseqid sseqid staxids sscinames sskingdoms skingdoms sphylums bitscore evalue \
        -d ${params.diamond_db} \
        -q ${transcripts_file} \
        -o ${sample}_vs_nr.tsv

    echo "Diamond blastx complete for sample: $sample"
    echo "Output: ${sample}_vs_nr.tsv"
    """
}
