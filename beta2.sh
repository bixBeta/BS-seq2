#!/bin/sh
#  beta2.sh
#
#  bismark2Bedtools for targeted pbat based fastq library files

#  Created by Faraz Ahmed on 05/23/19
#


source ~/.bash_profile

process(){
	# cd $1
	for i in *.gz; do iSUB=`echo $i | cut -d '.' -f1`; mkdir $iSUB; mv $i $iSUB; done
}


non_directional(){	
	# cd $1
	for i in */
	do
		cd $i

			echo $i
			mkdir Trimmed_Reads_clip9

			for i in *.gz; do
			trim_galore --fastqc -q 20 --rrbs -o ./Trimmed_Reads_clip9 $i 			# Trim poor quality reads and 9N from 5' end
			mv $i ..
			done

			cd Trimmed_Reads_clip9

			for i in *trimmed*; do
			bismark --score_min L,0,-0.6 --non_directional --multicore 2 --samtools_path /Users/epigencare/bin/samtools-1.9/samtools --genome /Users/epigencare/Documents/genomes/hg38.bs.ucsc/ -se $i
			done

			for i in *.bam
			#do
			#deduplicate_bismark --bam $i 												# recommended for pbat extractions
			#done

			#for i in *.deduplicated.bam

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
			for i in *.cov; do sort -k1,1 -k2,2n $i > $i.sorted.cov; done
			for i in *.sorted.cov; do bedtools intersect -a $i -b /Users/epigencare/bin/markerList.bed -wa -wb > $i.annotated.bed; done
			for i in *.annotated.bed ; do cat /Users/epigencare/bin/headerInfo.txt $i > `echo $i | cut -d '.' -f1`.FINAL.txt; done
			mkdir Target-Results .temp
			mv *.FINAL.txt Target-Results
			mv *.sorted.cov *.annnotated.bed .temp
			mv Target-Results ../

			cd ../../

		cd ..

	done
}

directional(){	
	# cd $1
	for i in */
	do
		cd $i

			echo $i
			mkdir Trimmed_Reads_clip9

			for i in *.gz; do
			trim_galore --fastqc -q 20 --rrbs -o ./Trimmed_Reads_clip9 $i 			# Trim poor quality reads and 9N from 5' end
			mv $i ..
			done

			cd Trimmed_Reads_clip9

			for i in *trimmed*; do
			bismark --score_min L,0,-0.6 --multicore 2 --samtools_path /Users/epigencare/bin/samtools-1.9/samtools --genome /Users/epigencare/Documents/genomes/hg38.bs.ucsc/ -se $i
			done

			for i in *.bam
			#do
			#deduplicate_bismark --bam $i 												# recommended for pbat extractions
			#done

			#for i in *.deduplicated.bam

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
			for i in *.cov; do sort -k1,1 -k2,2n $i > $i.sorted.cov; done
			for i in *.sorted.cov; do bedtools intersect -a $i -b /Users/epigencare/bin/markerList.bed -wa -wb > $i.annotated.bed; done
			for i in *.annotated.bed ; do cat /Users/epigencare/bin/headerInfo.txt $i > `echo $i | cut -d '.' -f1`.FINAL.txt; done
			mkdir Target-Results .temp
			mv *.FINAL.txt Target-Results
			mv *.sorted.cov *.annnotated.bed .temp
			mv Target-Results ../

			cd ../../

		cd ..

	done
}

pbat(){	
	# cd $1
	for i in */
	do
		cd $i

			echo $i
			mkdir Trimmed_Reads_clip9

			for i in *.gz; do
			trim_galore --fastqc -q 20 --rrbs -o ./Trimmed_Reads_clip9 $i 			# Trim poor quality reads and 9N from 5' end
			mv $i ..
			done

			cd Trimmed_Reads_clip9

			for i in *trimmed*; do
			bismark --score_min L,0,-0.6 --pbat --multicore 2 --samtools_path /Users/epigencare/bin/samtools-1.9/samtools --genome /Users/epigencare/Documents/genomes/hg38.bs.ucsc/ -se $i
			done

			for i in *.bam
			do
			deduplicate_bismark --bam $i 												# recommended for pbat extractions
			done

			for i in *.deduplicated.bam

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
			for i in *.cov; do sort -k1,1 -k2,2n $i > $i.sorted.cov; done
			for i in *.sorted.cov; do bedtools intersect -a $i -b /Users/epigencare/bin/markerList.bed -wa -wb > $i.annotated.bed; done
			for i in *.annotated.bed ; do cat /Users/epigencare/bin/headerInfo.txt $i > `echo $i | cut -d '.' -f1`.FINAL.txt; done
			mkdir Target-Results .temp
			mv *.FINAL.txt Target-Results
			mv *.sorted.cov *.annnotated.bed .temp
			mv Target-Results ../

			cd ../../

		cd ..

	done
}

usage(){

	echo "bash" $0 " < PATH > < directional > < non_directional > or < pbat >" 
}


while getopts "hp:d:" opt; do
  case ${opt} in
    h)  

		echo
		echo
   		usage
   		echo
   		echo

   	;;

   	p)
		
		DIR=$OPTARG
		cd $DIR
	;;

    d )
		
		MODE=$OPTARG
   		
   		if [[ $MODE = "pbat" ]]; then
   			
   			process
   			pbat

   		elif [[ $MODE = "directional" ]]; then
   			
   			process
   			directional

   		else 
   			
   			process
   			non_directional	

   		fi
   	;;	


    \? )
    	echo
		usage
		echo

     ;;
  esac
done
