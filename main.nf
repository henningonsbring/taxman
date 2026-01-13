nextflow.enable.dsl=2

// User parameters
params.prefix = ""      // e.g., "ABCD_12_t0"
params.directory = ""   // e.g., "/path/to/test_fastqs"
params.outdir = "results"

process print_fastqs {
    input:
    path fq_files

    output:
    stdout

    script:
    """
    echo "FASTQ files detected:"
    ls $fq_files
    """
}

workflow {
    println "Prefix: ${params.prefix}"
    println "Input directory: ${params.directory}"

    // Channel for paired-end FASTQs matching the prefix
    Channel.fromPath("${params.directory}/${params.prefix}_L*_R{1,2}_*.fastq.gz")
           .ifEmpty { error "No FASTQ files found for prefix ${params.prefix} in ${params.directory}" }
           .set { fastq_files }

    print_fastqs(fastq_files)
}
