#!/bin/sh

# RRBS workflow DOS (add ref genome support; add --cutoff 5; add case esac based flow )
#  Created by Faraz Ahmed on 1/28/19.
# latest commit 08/04/19

source ~/.bash_profile

usage(){

  echo "Usage: bash" $0 "-h -d [workdir] -p [processing mode] -g [reference genome]"
  echo
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "[-h] --> Display Help"
  echo "[-d] --> Working Directory"
  echo "[-p] --> Processing MODE < pbat, directional, non_directional > "
  echo "[-g] --> Reference Genome < human, mouse, rat, bovine >"
  echo "---------------------------------------------------------------------------------------------------------------"

}

trim(){

  mkdir Trimmed_Reads_clip9

  for i in *.gz
  do
    trim_galore --fastqc -q 20 -o ./Trimmed_Reads_clip9 --clip_R1 9 $i # Trim poor quality reads and 9N from 5' end
  done

}


# declare -A genomeDir

# genomeDir=( ["human"]="/Users/epigencare/Documents/genomes/hg38.bs.ucsc/" \
# ["mouse"]="/Users/epigencare/Documents/genomes/hg38.bs.ucsc/" \
# ["rat"]="/Users/epigencare/Documents/genomes/hg38.bs.ucsc/" \
# ["bovine"]="/Users/epigencare/Documents/genomes/hg38.bs.ucsc/" )

pbat(){

  cd Trimmed_Reads_clip9

  ls -1 *trimmed* > .Reads.list

  fastqs=( `cat ".Reads.list" `) 										# array of all fastq files

  for i in "${fastqs[@]}"												# loop over array elements
  do
    a=`echo "$i" | cut -d ',' -f1`
    bismark --score_min L,0,-0.6 --pbat --multicore 2 --genome /Users/epigencare/Documents/genomes/${GENOME}.bs.ucsc/ -se $a
  done
  rm .Reads.list

}

directional(){

  cd Trimmed_Reads_clip9

  ls -1 *trimmed* > .Reads.list

  fastqs=( `cat ".Reads.list" `) 										# array of all fastq files

  for i in "${fastqs[@]}"												# loop over array elements
  do
    a=`echo "$i" | cut -d ',' -f1`
    bismark --score_min L,0,-0.6 --multicore 2 --genome /Users/epigencare/Documents/genomes/${GENOME}.bs.ucsc/ -se $a
  done

}

non_directional(){

  cd Trimmed_Reads_clip9

  ls -1 *trimmed* > .Reads.list

  fastqs=( `cat ".Reads.list" `) 										# array of all fastq files

  for i in "${fastqs[@]}"												# loop over array elements
  do
    a=`echo "$i" | cut -d ',' -f1`
    bismark --score_min L,0,-0.6 --non_directional --multicore 2 --genome /Users/epigencare/Documents/genomes/${GENOME}.bs.ucsc/ -se $a
  done

}

downstream(){
    # for i in *.bam
    # do
    #   deduplicate_bismark --bam $i 										# recommended for pbat extractions
    # done

    # for i in *.deduplicated.bam
    for i in *.bam
    do
      bismark_methylation_extractor --ignore 9 --multicore 2 --bedGraph --cutoff 5 $i
    done

    bismark2report .

    mkdir BAMS COVG_Stats BEDS COVGS HTML_Reports FASTQs
    mv *.bam BAMS
    mv *.txt COVG_Stats
    mv *.cov.gz COVGS
    mv *.bedGraph.gz BEDS
    mv *.html *.zip HTML_Reports
    mv *.fq.gz FASTQs
    rm *.temp*

    cd COVGS
    for i in *.gz; do gunzip $i; done

    cd ../BAMS
    for i in *.bam ; do samtools sort $i > ${i}.sorted.bam ; done
    for i in *.sorted.bam ; do samtools index -b $i; done
    cd ..
    pwd
}

###################################################################################
###################################################################################
###################################################################################

while getopts "hd:p:g:" opt; do
    case ${opt} in
    h)

    echo
    echo
    usage
    echo
    echo

    ;;

    d)

    DIR=$OPTARG
    cd $DIR
    pwd
    ;;

    g)

    GENOME=$OPTARG
    echo $GENOME referene selected
    ;;

    p)

    MODE=$OPTARG

    ;;

    \?)
    echo
    usage
    echo

    ;;
    esac

done



if [[ ! -z "${MODE+x}" ]]; then
	if [[ $MODE = "pbat" ]]; then

      echo pbat mode selected

      trim
      pbat
      downstream

    elif [[ $MODE = "directional" ]]; then

      echo directional mode selected

      trim
      directional
      downstream

    else

      echo non_directional mode selected

      trim
      non_directional
      downstream

	fi
fi










if [[ -z $1 ]] || [[  $1 = "help"  ]] ; then
	#statements
	echo
	echo
	usage
	echo
	echo
	exit 1

fi
