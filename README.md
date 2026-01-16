<p align="left">
  <img src="assets/taxman_logo.jpg" alt="Taxman logo" width="250">
</p>

# taxman

**taxman** is a Nextflow workflow for assembling paired-end FASTQ reads and generating taxonomic summaries using DIAMOND alignments against the NCBI NR database. An optional read downsampling step is included to enable fair cross-library comparisons.

The final step of the pipeline outputs a summary. Only the first few lines are shown below to illustrate the format:
```
TAXA QUANTIFICATION SUMMARY
 
Species                                       Count    Percent
 
Haemophilus influenzae                          715     49.41%
Cutibacterium acnes                              62      4.28%
Pasteurella multocida                            57      3.94%
```

## Input requirements

- Paired-end FASTQ files following this naming pattern: `*_R[12]_*.fastq.gz`

- A DIAMOND NR database built with taxonomy support

## Typical usage

```bash
nextflow run main.nf \
  --prefix SAMPLE_ID \
  --directory /path/to/fastq_directory \
  --outdir /path/to/output_directory \
  --subsample_reads NUM \
  --assembly_mode rna
```

See the supported assembly mode options in the [SPAdes documentation](https://github.com/ablab/spades).  
If the `--assembly_mode` flag is omitted, SPAdes will use its default assembly mode, which is genome assembly.

## Getting started

### 1. Install dependencies

The following tools must be installed and available on your system:

- **Nextflow** (DSL2) https://www.nextflow.io/docs/latest/install.html
- **fastp** https://github.com/OpenGene/fastp
- **seqtk** https://github.com/lh3/seqtk
- **SPAdes** https://github.com/ablab/spades/releases/tag/v4.2.0
- **DIAMOND aligner** https://github.com/bbuchfink/diamond/wiki

### 2. Configure executable paths

Ensure the following tools are available in your `PATH`:

- **fastp**
- **seqtk**
- **SPAdes**
- **DIAMOND aligner**

Alternatively, specify the full paths to these executables in nextflow.config.

### 3. Download database resources

Download the required NR and taxonomy files from NCBI:

```bash
wget ftp://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nr.gz
wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.gz
wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
```

Extract the taxonomy dump:
```bash
tar -xzf taxdump.tar.gz
```

### 4. Build the DIAMOND database

Create a DIAMOND NR database with taxonomy support:

```bash
diamond makedb \
  --no-parse-seqids \
  --in nr.gz \
  -d nr_diamond_taxonomy.db \
  --taxonmap prot.accession2taxid.gz \
  --taxonnodes taxdump/nodes.dmp \
  --taxonnames taxdump/names.dmp
```

### 5. Configure database path

Add the path to the generated DIAMOND database in `nextflow.config`.
