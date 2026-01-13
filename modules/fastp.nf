process fastp_trim {

    tag "$sample"

    input:
    tuple val(sample), path(fqs)

    output:
    tuple val(sample), path("trimmed/${sample}_trimmed_R1.fq.gz"), path("trimmed/${sample}_trimmed_R2.fq.gz")

    script:
    """
    mkdir -p trimmed

    # Use find to get files in a reliable way
    R1_FILES=\$(find . -maxdepth 1 -name "*_R1_*.fastq.gz" -o -name "*_R1_*.fq.gz" | sort)
    R2_FILES=\$(find . -maxdepth 1 -name "*_R2_*.fastq.gz" -o -name "*_R2_*.fq.gz" | sort)

    if [ -z "\$R1_FILES" ] || [ -z "\$R2_FILES" ]; then
        echo "ERROR: Could not find R1 and/or R2 files"
        echo "Files in directory:"
        ls -la
        exit 1
    fi

    echo "Processing R1 files: \$R1_FILES"
    echo "Processing R2 files: \$R2_FILES"

    # Run fastp with all files
    fastp -i \$R1_FILES -I \$R2_FILES \
          -o trimmed/${sample}_trimmed_R1.fq.gz \
          -O trimmed/${sample}_trimmed_R2.fq.gz \
          -y \
          --detect_adapter_for_pe \
          --thread 4
    """
}
