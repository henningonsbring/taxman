nextflow.enable.dsl=2

include { fastp_trim } from './modules/fastp.nf'

params.prefix    = ""
params.directory = ""
params.outdir    = "results"

workflow {

    println "=" * 80
    println "WORKFLOW START"
    println "=" * 80
    println "Prefix: ${params.prefix}"
    println "Input directory: ${params.directory}"
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

    // Subscribe to trimmed output
    trimmed_fastqs.subscribe { sample, r1_file, r2_file ->
        println "Sample: $sample"
        println "  Output trimmed files:"
        println "    Trimmed R1: ${r1_file.getFileName()}"
        println "    Trimmed R2: ${r2_file.getFileName()}"
        println ""  // Add blank line
    }

    // ------------------------------------------------------------
    // Workflow summary
    // ------------------------------------------------------------
    println ""
    println "=" * 80
    println "WORKFLOW COMPLETE"
    println "=" * 80
}
