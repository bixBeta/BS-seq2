nextflow.enable.dsl=2

// Project Params:
params.sheet            = "sample-sheet.csv"

ch_sheet                    = channel.fromPath(params.sheet)

meta_ch = ch_sheet
        |  splitCsv( header:true )
        |  map { row -> [row.label, [file("fastqs/" + row.fastq1), file("fastqs/" + row.fastq2)]] }
        |  view

process TRIMG {
    maxForks 3
    tag "$id"
    label 'process_high'
    
    publishDir "trimmed_fastqs"         , mode: "symlink", overwrite: true , pattern: "*.gz" 
    publishDir "trim_galore_logs"       , mode: "symlink", overwrite: true , pattern: "*_trimming_report.txt"
    
    input:
        tuple val(id), path(reads)
    
    output:
        tuple val(id), path("*gz")       , emit: trimmed_fqs
        path "*_trimming_report.txt" 
    
        
    script:

        """
        trim_galore -q 20 --rrbs --non_directional -j 8 --paired ${reads[0]} ${reads[1]}
        
        """


}


workflow {
  
    TRIMG(meta_ch)

}
