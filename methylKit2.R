#!/usr/bin/env Rscript


args <-  commandArgs(trailingOnly = T)
#setwd(args[2])

# check for required argument
if (length(args)==0) {
	system("echo ''")
	system("echo ''")
	system("echo '------------------------------------------------------------------------------------'")
    system("echo 'Usage = Rscript methylKit2.R < reference genome name >'")
    system("echo ''")
    system("echo '         Example: methylKit2.R hg38 '") 
    system("echo '------------------------------------------------------------------------------------'")
    system("echo ''")
    stop("Please supply the reference assembly name!!! \n", call.=FALSE)
}


#args <- "hg38"
suppressPackageStartupMessages(library(dplyr))

assembly <- function(assembly.name){
  bedPaths <- suppressWarnings(read.table("/Users/epigencare/Documents/genomes/bedPaths.csv", 
                                          header = T, sep = ",", stringsAsFactors = F) )
  bedPaths %>% 
    filter(assembly == assembly.name) %>% 
    select(bed.path)
}

bedFile <- assembly(args[1])

assemblyCPG <- function(assembly.name){
  bedPaths <- suppressWarnings(read.table("/Users/epigencare/Documents/genomes/bedPaths.csv", 
                                          header = T, sep = ",", stringsAsFactors = F) )
  bedPaths %>% 
    filter(assembly == assembly.name) %>% 
    select(cpg.bed.path)
}

cpgBed <- assemblyCPG(args[1])

outputPrefix <- "methylKit"
suppressPackageStartupMessages(library(methylKit))

##################################################################
##################################################################
## Import coverage files
##################################################################
##################################################################

#phenoData <- as.data.frame(read.csv(file = args[2] , header = T, sep = ","))
phenoData <- suppressWarnings(as.data.frame(read.csv(file = "inputFile.csv" , header = T, sep = ",")))

sampleNames <- as.character(phenoData$sample.name)
ID <- as.character(phenoData$sample.id)
treatment <- phenoData$treatment

file.list= as.list(sampleNames)
ID = as.list(ID)


myobj = methRead(file.list,
                 sample.id = ID,
                 pipeline = "bismarkCoverage",
                 assembly = args[1],
                 treatment = treatment, mincov = 1) # control 0

##################################################################
##################################################################
## QC, basic statistics
##################################################################
##################################################################
sink(file = "MethylationSummary.log")
for (i in 1:length(myobj)) {
  print(paste0(phenoData$sample.name[i], "_MethylationSummary:"))
  getMethylationStats(myobj[[i]], plot = F, both.strands = F)
}
sink()

##################################################################
##################################################################
## Plot HISTOGRAMS
##################################################################
##################################################################
suppressPackageStartupMessages(library("graphics"))
system("mkdir MethylationStatsPlots")
for (i in 1:length(myobj)) {
  jpeg(filename = paste0(phenoData$sample.name[i],".methylationStats.jpg"), width = 1080, height = 1080, res = 155)
  getMethylationStats(myobj[[i]], plot = T, both.strands = F)
  dev.off()
}
system("mv *.methylationStats.jpg MethylationStatsPlots")

system("mkdir CoverageStatsPlots")
for (i in 1:length(myobj)) {
  jpeg(filename = paste0(phenoData$sample.name[i],".coverageStats.jpg"), width = 1080, height = 1080, res = 155)
  getCoverageStats(myobj[[i]],plot=TRUE,both.strands=FALSE)
  dev.off()
}
system("mv *.coverageStats.jpg CoverageStatsPlots")

## filter out low quality reads (Optional)
##################################################################
# filtered.myobj <- filterByCoverage(myobj, lo.count = 10, lo.perc = NULL, hi.count = NULL, hi.perc = 99.9)
##################################################################

##################################################################
##################################################################
##  DIAGNOSTIC PLOTS
##################################################################
##################################################################

# sample corelation
meth <- unite(myobj, destrand = FALSE)
head(meth)

system("mkdir DiagnosticPlots")
jpeg(filename = paste0(outputPrefix,".SampleCorelationPlot" ,".jpg"), width = 1080, height = 1080, res = 155)
getCorrelation(meth, plot = T)
dev.off()
# cluster based on methyl profile
jpeg(filename = paste0(outputPrefix,".ClusterPlot" ,".jpg"), width = 1080, height = 1080, res = 155)
clusterSamples(meth, dist = "correlation", method = "ward", plot = TRUE)
dev.off()
hc <- clusterSamples(meth, dist = "correlation", method = "ward", plot = FALSE)
hc
# PCA
jpeg(filename = paste0(outputPrefix, ".PCA.plot" ,".jpg"), width = 1080, height = 1080, res = 155)
PCASamples(meth, screeplot = TRUE)
dev.off()
jpeg(filename = paste0(outputPrefix, ".PCA2.plot" ,".jpg"), width = 1080, height = 1080, res = 155)
PCASamples(meth)
dev.off()

system("mv *.jpg DiagnosticPlots")

##################################################################
##################################################################
##  Differential Methylation 
##################################################################
##################################################################

myDiff <- calculateDiffMeth(meth)
#write.csv(as(myDiff,"GRanges"), paste0(outputPrefix, "_DiffCalls.csv"), quote = F)

## CUSTOM 
# get all differentially methylated bases
# myDiff25p=getMethylDiff(myDiff,difference=25,qvalue=0.01)

##################################################################
##################################################################
##  Annotating DMB's 
##################################################################
##################################################################
suppressPackageStartupMessages(library(genomation))
gene.obj=readTranscriptFeatures(as.character(bedFile))


#
# annotate differentially methylated CpGs with 
# promoter/exon/intron using annotation data
#

diffAnn=annotateWithGeneParts(as(myDiff,"GRanges"),gene.obj)
diffAnn
diffAnn_TSS <- getAssociationWithTSS(diffAnn)
#head(diffAnn_TSS)
#write.csv(diffAnn_TSS, paste0(outputPrefix, "_AssociationsWithTSS.csv"), quote = F)

genomation::getTargetAnnotationStats(diffAnn,percentage=TRUE,precedence=TRUE)

jpeg(filename = paste0(outputPrefix, ".methylationAnnotation" ,".jpg"), width = 1080, height = 1080, res = 155)
genomation::plotTargetAnnotation(diffAnn,precedence=TRUE, main="differential methylation annotation")
dev.off()


# read the shores and flanking regions and name the flanks as shores 
# and CpG islands as CpGi
cpg.obj=readFeatureFlank(as.character(cpgBed), feature.flank.name=c("CpGi","shores"))
#
# convert methylDiff object to GRanges and annotate
diffCpGann=annotateWithFeatureFlank(as(myDiff,"GRanges"),
                                    cpg.obj$CpGi,cpg.obj$shores,
                                    feature.name="CpGi",flank.name="shores")
diffCpGann

jpeg(filename = paste0(outputPrefix, ".CPG_Annotation" ,".jpg"), width = 1080, height = 1080, res = 155)
genomation::plotTargetAnnotation(diffCpGann,col=c("green","gray","white"), main="differential methylation annotation")
dev.off()


suppressPackageStartupMessages(library(dplyr))
# DF from myDiff
rawDiff <- getData(myDiff)
# Primary List (w/o BedTools)
primeRawDiff <- data.frame(meth, rawDiff, diffAnn@members, diffCpGann@members)
# Set primary key for join
primeRawDiff$test <- as.integer(row.names(primeRawDiff))
joined <- right_join(primeRawDiff, diffAnn_TSS, by = c( "test" = "target.row"))
final.OUT <- joined[, ! names(joined) %in% c("chr.1", "start.1", "end.1", "strand.1", "test"), drop = F]
write.csv(final.OUT, paste0(outputPrefix, "_Final_DiffCalls.csv"), quote = F)

filtered.final.OUT <- final.OUT %>%
  filter(abs(meth.diff) > 20) %>%
  filter(pvalue <= 0.10)

write.csv(filtered.final.OUT, paste0(outputPrefix, "_Filtered_DiffCalls.csv"), quote = F)




save(cpg.obj,diffAnn, diffAnn_TSS, diffCpGann, file.list, gene.obj, hc,ID, meth, myDiff, myobj, phenoData , final.OUT, file = paste0(outputPrefix,".Rdata"))

system("mkdir AnnotationPlots dmrReports")
system("mv *.jpg AnnotationPlots")
system("mv *.log *Final_DiffCalls.csv *Filtered_DiffCalls.csv dmrReports")
system("mkdir DMR-results")
system ("mv CoverageStatsPlots DiagnosticPlots MethylationStatsPlots AnnotationPlots dmrReports *.Rdata DMR-results")
system("mv DMR-results ..")

