process spades_assemble {

    tag "$sample"

    publishDir "${params.outdir ?: 'results'}/assemblies", mode: 'copy', pattern: "*.fasta"

    input:
    tuple val(sample), path(r1_file), path(r2_file)

    output:
    tuple val(sample), path("${sample}_assembly"), path("${sample}_assembly/transcripts.fasta")

    script:
    """
    # Create assembly directory
    mkdir -p ${sample}_assembly

    echo "Starting SPAdes assembly for sample: $sample"
    echo "Input R1: \$(basename ${r1_file})"
    echo "Input R2: \$(basename ${r2_file})"
    echo "Threads: ${params.spades_threads}"
    echo "Memory: ${params.spades_memory}GB"
    echo ""

    # Build SPAdes command
    ${params.spades_path} --rna \
        -t ${params.spades_threads} \
        -m ${params.spades_memory} \
        -1 $r1_file \
        -2 $r2_file \
        -o ${sample}_assembly

    echo ""
    echo "SPAdes assembly complete for sample: $sample"

    # Check transcripts output exists
    if [ ! -f "${sample}_assembly/transcripts.fasta" ]; then
        echo "ERROR: transcripts.fasta not found!"
        exit 1
    fi

    transcript_count=\$(grep -c '^>' ${sample}_assembly/transcripts.fasta)
    echo "Transcripts created: \$transcript_count sequences"
    """
}
