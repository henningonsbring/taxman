nextflow.enable.dsl=2

include { fastp_trim } from './modules/fastp.nf'
include { subsample_fastq } from './modules/subsample.nf'
include { spades_assemble } from './modules/spades.nf'

workflow {
    println "=" * 80
    println "WORKFLOW START"
    println "=" * 80
    println "Prefix: ${params.prefix}"
    println "Input directory: ${params.directory}"
    if (params.subsample_reads) {
        println "Subsample reads: ${params.subsample_reads}"
    }
    println ""

    // STEP 1: Find FASTQ files
    println "STEP 1: Identifying FASTQ files"
    println "-" * 40

    Channel
        .fromPath("${params.directory}/${params.prefix}_L*_R{1,2}_*.fastq.gz")
        .ifEmpty { error "No FASTQ files found" }
        .map { fq ->
            def parts = fq.getSimpleName().tokenize('_')
            tuple(parts[0..2].join('_'), fq)
        }
        .groupTuple()
        .set { fastq_files }

    fastq_files.subscribe { sample, files ->
        println "Sample: $sample"
        println "  Total files: ${files.size()}"
        files.sort().eachWithIndex { file, i ->
            println "    [${i+1}] ${file.getFileName()}"
        }
        println ""
    }

    // STEP 2: Trim with fastp
    println ""
    println "STEP 2: Running fastp trimming"
    println "-" * 40

    trimmed_fastqs = fastp_trim(fastq_files)

    // STEP 3: Optional subsampling
    if (params.subsample_reads) {
        println ""
        println "STEP 3: Subsampling to ${params.subsample_reads} reads"
        println "-" * 40

        trimmed_fastqs
            .map { sample, r1, r2 -> tuple(sample, r1, r2, params.subsample_reads) }
            .set { subsample_input }

        final_fastqs = subsample_fastq(subsample_input)
    } else {
        println ""
        println "STEP 3: Skipping subsampling"
        println "-" * 40
        final_fastqs = trimmed_fastqs
    }

    final_fastqs.subscribe { sample, r1, r2 ->
        println "Sample: $sample"
        println "  Final R1: ${r1.getFileName()}"
        println "  Final R2: ${r2.getFileName()}"
        println ""
    }

    // STEP 4: SPAdes assembly
    assembly_results = spades_assemble(final_fastqs)

    assembly_results.subscribe { sample, assembly_dir, transcripts_file ->
        println ""
        println "STEP 4: SPAdes assembly complete"
        println "-" * 40
        println "Sample: $sample"
        println "  Assembly directory: $assembly_dir"
        println "  Transcripts: ${transcripts_file.getFileName()}"
        println ""
    }

    println ""
    println "=" * 80
    println "WORKFLOW COMPLETE"
    println "=" * 80
}
