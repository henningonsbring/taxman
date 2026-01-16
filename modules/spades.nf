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
    echo "Assembly mode: ${params.assembly_mode ?: 'default (no mode flag)'}"
    echo ""

    # Build SPAdes command
    CMD="${params.spades_path}"

    # Add assembly mode if specified
    if [ -n "${params.assembly_mode}" ]; then
        CMD="\$CMD --${params.assembly_mode}"
    fi

    CMD="\$CMD -t ${params.spades_threads}"
    CMD="\$CMD -m ${params.spades_memory}"
    CMD="\$CMD -1 $r1_file"
    CMD="\$CMD -2 $r2_file"
    CMD="\$CMD -o ${sample}_assembly"

    # Add k-mer sizes if specified (and not 'auto')
    if [ "${params.spades_k}" != "auto" ]; then
        CMD="\$CMD -k ${params.spades_k}"
    fi

    echo "Running command:"
    echo "\$CMD"
    echo ""

    # Execute SPAdes
    eval \$CMD

    echo ""
    echo "SPAdes assembly complete for sample: $sample"

    # Check output file name based on mode
    if [ "${params.assembly_mode}" = "rna" ] || [ "${params.assembly_mode}" = "rnaviral" ]; then
        OUTPUT_FILE="transcripts.fasta"
    else
        OUTPUT_FILE="contigs.fasta"
    fi

    if [ ! -f "${sample}_assembly/\$OUTPUT_FILE" ]; then
        echo "ERROR: \$OUTPUT_FILE not found!"
        echo "Files in ${sample}_assembly/:"
        ls -la "${sample}_assembly/"
        exit 1
    fi

    transcript_count=\$(grep -c '^>' ${sample}_assembly/\$OUTPUT_FILE)
    echo "Sequences created: \$transcript_count"
    """
}
