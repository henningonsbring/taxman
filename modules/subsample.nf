process subsample_fastq {

    tag "$sample"

    // Use a default value if params.outdir is not set
    publishDir "${params.outdir ?: 'results'}/subsampled", mode: 'copy'

    input:
    tuple val(sample), path(r1_file), path(r2_file), val(subsample_reads)

    output:
    tuple val(sample), path("subsampled/${sample}_subsampled_R1.fq.gz"), path("subsampled/${sample}_subsampled_R2.fq.gz")

    script:
    """
    mkdir -p subsampled

    echo "Subsampling ${sample} to ${subsample_reads} reads per file"
    echo "Input R1: \$(basename ${r1_file})"
    echo "Input R2: \$(basename ${r2_file})"

    # Set a fixed seed for reproducibility
    SEED=100

    # Subsample R1
    seqtk sample -s\${SEED} ${r1_file} ${subsample_reads} | gzip > subsampled/${sample}_subsampled_R1.fq.gz

    # Subsample R2
    seqtk sample -s\${SEED} ${r2_file} ${subsample_reads} | gzip > subsampled/${sample}_subsampled_R2.fq.gz

    echo "Subsampling complete"
    echo "Output R1: subsampled/${sample}_subsampled_R1.fq.gz"
    echo "Output R2: subsampled/${sample}_subsampled_R2.fq.gz"
    """
}
