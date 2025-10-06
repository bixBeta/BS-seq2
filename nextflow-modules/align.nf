nextflow.enable.dsl=2

// Project Params:
params.sheet            = "sample-sheet2.csv"

ch_sheet                    = channel.fromPath(params.sheet)

meta_ch = ch_sheet
        |  splitCsv( header:true )
        |  map { row -> [row.label, [file(row.fastq1), file(row.fastq2)]] }
        |  view


process BISMARK {
    maxForks 1
    tag "$id"
    label 'process_bismark'
    
    publishDir "bismark_bams"           , mode: "symlink", overwrite: true, pattern: "*.bam"
    // publishDir "bismark_logs"           , mode: "symlink", overwrite: true, pattern: "*txt"

    input:
        tuple val(id), path(trimmed)
    
    output:
        tuple val(id), path("*bam")       , emit: bams
    
        
    script:

        """
        bismark --score_min L,0,-0.6 --non_directional --multicore 10 --genome /SSD/fa286/DIGITAL_STORM/rrbs-14/genome -1 ${trimmed[0]} -2 ${trimmed[1]} 
        
        """


}

process SORT{

    tag "$id"
    maxForks 5
    label 'process_bismark'
    
    publishDir "bismark_sorted_bams"           , mode: "symlink", overwrite: true, pattern: "*.{sorted.bam,sorted.bam.bai}"
    

    input:
    tuple val(id), path(bam)

    output:
    tuple val(id), path("*.sorted.bam")    , emit: sorted_bams

    script:

    """

    samtools sort ${bam} > ${id}.sorted.bam
    samtools index ${id}.sorted.bam

    """


}

process COVGS {

    tag "$id"
    maxForks 5
    label 'process_bismark'
    
    publishDir "bismark_downstream"           , mode: "symlink", overwrite: true, pattern: "*.{cov.gz,txt,bedGraph.gz,html,zip}"
    

    input:
    tuple val(id), path(bam)

    output:
    tuple val(id), path("*cov.gz")                  , emit: covg
    tuple val(id), path("*bedGraph.gz")             , emit: bg
    tuple val(id), path("*html")                    , emit: html
    tuple val(id), path("*zip")                     , emit: zip

    script:

    """

    bismark_methylation_extractor --ignore 9 --multicore 8 --bedGraph --cutoff 5 ${bam}
    bismark2report . 

    """


}





workflow {
    
    BISMARK(meta_ch)
    bams_ch = BISMARK.out.bams
                | view
    SORT(bams_ch)
}
