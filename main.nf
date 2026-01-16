nextflow.enable.dsl=2

include { fastp_trim } from './modules/fastp.nf'
include { subsample_fastq } from './modules/subsample.nf'
include { spades_assemble } from './modules/spades.nf'
include { diamond_blastx } from './modules/diamond.nf'
include { taxa_quantify } from './modules/taxa_quantify.nf'

workflow {
    if (!params.directory) error "Please specify --directory"
    if (!params.prefix) error "Please specify --prefix"
    if (!params.outdir) error "Please specify --outdir"

    println "=" * 80
    println "WORKFLOW START"
    println "=" * 80
    println "Prefix: ${params.prefix}"
    println "Input directory: ${params.directory}"
    if (params.subsample_reads) {
        println "Subsample reads: ${params.subsample_reads}"
    }
    if (params.assembly_mode) {
        println "Assembly mode: ${params.assembly_mode}"
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
    println ""
    println "STEP 4: Running SPAdes assembly"
    println "-" * 40

    assembly_results = spades_assemble(final_fastqs)

    assembly_results.subscribe { sample, assembly_dir ->
        println "Sample: $sample"
        println "  Assembly directory: $assembly_dir"
        println ""
    }

    // STEP 5: Diamond blastx
    println ""
    println "STEP 5: Running diamond blastx"
    println "-" * 40

    diamond_input = assembly_results.map { sample, assembly_dir ->
        // Get the assembly file based on mode
        def assembly_file
        if (params.assembly_mode == "rna" || params.assembly_mode == "rnaviral") {
            assembly_file = "${assembly_dir}/transcripts.fasta"
        } else {
            assembly_file = "${assembly_dir}/contigs.fasta"
        }
        tuple(sample, file(assembly_file))
    }

    diamond_results = diamond_blastx(diamond_input)

    diamond_results.subscribe { sample, diamond_output ->
        println "Sample: $sample"
        println "  Diamond output: ${diamond_output.getFileName()}"
        println ""
    }

    // STEP 6: Taxa quantification
    println ""
    println "STEP 6: Quantifying taxa"
    println "-" * 40

    taxa_results = taxa_quantify(diamond_results)

    // Direct subscribe now works with tuple output
    taxa_results.subscribe { sample, summary_file, top_taxa_file ->
        println "Sample: $sample"
        println "  Taxa summary: ${summary_file.getFileName()}"
        println "  Top taxa list: ${top_taxa_file.getFileName()}"
        println ""

        // Optional: Print a preview of top taxa
        println "  Top 5 taxa preview:"
        def top_file = top_taxa_file.toString()
        def lines = new File(top_file).readLines().take(5)
        lines.each { line ->
            println "    $line"
        }
        println ""
    }

    println ""
    println "=" * 80
    println "WORKFLOW COMPLETE"
    println "=" * 80
}
