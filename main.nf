nextflow.enable.dsl=2

params.prefix         = ""
params.directory      = ""
params.outdir         = "results"
params.subsample_reads = null  // Optional parameter

include { fastp_trim } from './modules/fastp.nf'
include { subsample_fastq } from './modules/subsample.nf'

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

    // ------------------------------------------------------------
    // STEP 1: Find and collect FASTQ files
    // ------------------------------------------------------------
    println "STEP 1: Identifying FASTQ files"
    println "-" * 40

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

    // Print files immediately using subscribe
    fastq_files.subscribe { sample, files ->
        def r1_count = files.count { it.toString().contains('_R1_') }
        def r2_count = files.count { it.toString().contains('_R2_') }
        def lanes = files.collect {
            def m = it.toString() =~ /L(\d{3})/
            m ? m[0][1] : 'unknown'
        }.unique().sort().join(', ')

        // Format output
        println "Sample: $sample"
        println "  Total files: ${files.size()} (R1: $r1_count, R2: $r2_count)"
        println "  Lanes detected: $lanes"
        println ""
        println "  Input FASTQ files:"

        // Sort files for consistent display
        def sortedFiles = files.sort { a, b ->
            def aLane = (a.toString() =~ /L(\d{3})/)[0][1]
            def bLane = (b.toString() =~ /L(\d{3})/)[0][1]
            def aRead = a.toString().contains('_R1_') ? 1 : 2
            def bRead = b.toString().contains('_R1_') ? 1 : 2

            aLane <=> bLane ?: aRead <=> bRead
        }

        sortedFiles.each { file ->
            def fileName = file.getFileName().toString()
            def lane = (fileName =~ /L(\d{3})/)[0][1]
            def read = fileName.contains('_R1_') ? 'R1' : 'R2'
            println "    L${lane}_${read}: $fileName"
        }
        println ""  // Add blank line
    }

    // ------------------------------------------------------------
    // STEP 2: Run fastp trimming
    // ------------------------------------------------------------
    println ""
    println "STEP 2: Running fastp trimming"
    println "-" * 40

    trimmed_fastqs = fastp_trim(fastq_files)

    // ------------------------------------------------------------
    // STEP 3: Optional subsampling
    // ------------------------------------------------------------
    Channel
        .from(params.subsample_reads)
        .set { subsample_param }

    // Check if subsampling is requested
    if (params.subsample_reads) {
        println ""
        println "STEP 3: Subsampling trimmed reads to ${params.subsample_reads} reads per file"
        println "-" * 40

        // Create a channel with the subsample parameter for each sample
        trimmed_fastqs
            .combine(subsample_param)
            .set { subsample_input }

        final_fastqs = subsample_fastq(subsample_input)

        // Subscribe to subsampled output
        final_fastqs.subscribe { sample, r1_file, r2_file ->
            println "Sample: $sample"
            println "  Output subsampled files:"
            println "    Subsample R1: ${r1_file.getFileName()}"
            println "    Subsample R2: ${r2_file.getFileName()}"
            println ""  // Add blank line
        }
    } else {
        println ""
        println "STEP 3: Skipping subsampling (--subsample-reads not specified)"
        println "-" * 40

        // If no subsampling, just pass through the trimmed files
        final_fastqs = trimmed_fastqs

        // Subscribe to trimmed output
        final_fastqs.subscribe { sample, r1_file, r2_file ->
            println "Sample: $sample"
            println "  Output trimmed files (no subsampling):"
            println "    Trimmed R1: ${r1_file.getFileName()}"
            println "    Trimmed R2: ${r2_file.getFileName()}"
            println ""  // Add blank line
        }
    }

    // ------------------------------------------------------------
    // Workflow summary
    // ------------------------------------------------------------
    println ""
    println "=" * 80
    println "WORKFLOW COMPLETE"
    println "=" * 80

    // Final output channel (for downstream processes if needed)
    emit:
    final_fastqs
}
