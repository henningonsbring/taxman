process fastp_trim {

    tag "$sample"

    input:
    tuple val(sample), path(fqs)

    output:
    tuple val(sample), path("trimmed/${sample}_trimmed_R{1,2}.fq.gz")

    script:
    """
    mkdir -p trimmed

    fq1=\$(ls ${fqs} | grep '_R1_')
    fq2=\$(ls ${fqs} | grep '_R2_')

    fastp -i \$fq1 -I \$fq2 \
          -o trimmed/${sample}_trimmed_R1.fq.gz \
          -O trimmed/${sample}_trimmed_R2.fq.gz \
          --detect_adapter_for_pe \
          --thread 4
    """
}
