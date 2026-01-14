process taxa_quantify {

    tag "$sample"

    publishDir "${params.outdir}/taxa_summary", mode: 'copy'

    input:
    tuple val(sample), path(diamond_tsv)

    output:
    tuple val(sample), path("${sample}_taxa_summary.txt"), path("${sample}_top_taxa.txt")

    script:
    """
    echo "Quantifying taxa for sample: $sample"
    echo "Input diamond file: \$(basename ${diamond_tsv})"
    echo ""

    # Run the taxa quantification script
    awk -F'\\t' '{
        # Extract the scientific name field
        split(\$4, entries, ";");
        first_entry = entries[1];

        # Get first two words (genus + species)
        split(first_entry, words, " ");
        if (length(words) >= 2) {
            print words[1] " " words[2];
        }
    }' ${diamond_tsv} \
    | sort \
    | uniq -c \
    | sort -k1,1nr \
    | awk 'BEGIN {
        total = 0;
        print " ";
        print "TAXA QUANTIFICATION SUMMARY";
        print " ";
        printf "%-40s %10s %10s\\n", "Species", "Count", "Percent";
        print " ";
    }
    {
        species = \$2 " " \$3;
        count = \$1;
        total += count;
        counts[species] = count;
        species_list[NR] = species;
    }
    END {
        # Print sorted by count (already sorted from pipe)
        for (i = 1; i <= NR; i++) {
            species = species_list[i];
            count = counts[species];
            printf "%-40s %10d %9.2f%%\\n", species, count, (count/total)*100;
        }
        print " ";
        printf "%-40s %10d %9.2f%%\\n", "TOTAL", total, 100.00;
    }' > ${sample}_taxa_summary.txt

    # Create sorted top taxa list (clean version)
    awk -F'\\t' '{
        split(\$4, entries, ";");
        first_entry = entries[1];
        split(first_entry, words, " ");
        if (length(words) >= 2) {
            print words[1] " " words[2];
        }
    }' ${diamond_tsv} \
    | sort \
    | uniq -c \
    | sort -k1,1nr \
    | awk '{printf "%-40s %6d\\n", \$2 " " \$3, \$1}' > ${sample}_top_taxa.txt

    echo ""
    echo "Taxa quantification complete for sample: $sample"
    echo "Summary saved to: ${sample}_taxa_summary.txt"
    echo "Top taxa list saved to: ${sample}_top_taxa.txt"
    """
}
