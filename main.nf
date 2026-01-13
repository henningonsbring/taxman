nextflow.enable.dsl=2

include { fastp_trim } from './modules/fastp.nf'

params.prefix    = ""
params.directory = ""
params.outdir    = "results"

process print_fastqs {
    tag "$sample"

    input:
    tuple val(sample), path(fqs)

    output:
    stdout emit: files_list

    script:
    """
    echo "FASTQ files detected for sample $sample:"
    for fq in ${fqs}; do
        echo "\$fq"
    done
    """
}

workflow {

    println "Prefix: ${params.prefix}"
    println "Input directory: ${params.directory}"

    // Channel with all FASTQs for the prefix
    Channel
        .fromPath("${params.directory}/${params.prefix}_L*_R{1,2}_*.fastq.gz")
        .ifEmpty { error "No FASTQ files found for prefix ${params.prefix} in ${params.directory}" }
        .map { fq ->
            def parts = fq.getSimpleName().tokenize('_')
            def sample = parts[0..2].join('_')
            tuple(sample, fq)
        }
        .groupTuple()
        .set { fastq_files }

    // Step 1: print FASTQs
    print_fastqs(fastq_files)

    // Step 2: run fastp trimming (will handle all R1/R2 files)
    trimmed_fastqs = fastp_trim(fastq_files)

    // View trimmed files
    trimmed_fastqs.view()
}
