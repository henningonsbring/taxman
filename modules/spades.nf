process spades_assemble {

    tag "$sample"

    publishDir "${params.outdir}/assemblies", mode: 'copy'

    input:
    tuple val(sample), path(r1_file), path(r2_file)

    output:
    tuple val(sample), path("${sample}_assembly")

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

    echo "SPAdes assembly complete for sample: $sample"
    echo "Output directory: ${sample}_assembly"
    """
}
