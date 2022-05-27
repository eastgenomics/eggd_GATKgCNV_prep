<!-- dx-header -->
# Prepare target intervals for GATK gCNVcaller (DNAnexus Platform App)

Dx wrapper to run the GATK PreprocessIntervals and AnnotateIntervals.

This is the source code for an app that runs on the DNAnexus Platform.

<!-- Insert a description of your app here -->
## What does this app do?
Creates a Picard-style interval_list from a bed file and annotates it with GC content and optionally mappability and/or segmental duplication information.

## What are typical use cases for this app?
This app may be executed to generate a target interval list file to be used for germline CNV calling.

## What data are required for this app to run?
This app requires:
* GATK Docker image tar (`-iGATK_docker`)
* reference genome fasta and index tar (`-ireference_genome`) must have a `genome.fa` and `genome.fai` after unpacking the tar
* target regions BED file, sorted in chromosome order (`-ibed_file`)
* an output filename prefix (`-ifilename`)
* number of base pairs to pad regions with on either side (`-ipadding`)
* length of bins in which to determine CNV state (`-ibin_length`) (should only be used for WGS data)


Optional inputs:
* toAnnotateMap: can be set TRUE/FALSE depending on whether intervals should be annotated with mappability information
* if TRUE, must provide a mappability track bed file
* toAnnotateSegDup: can be set TRUE/FALSE depending on whether intervals should be annotated with segmental duplication information
* if TRUE, must provide a segmental duplication track bed file
* (exclusion BED file listing regions that should be excluded from CNV calling)  - not currently supported

## What does this app output?
* .interval_list in Picard-style format that can be used directly as input to the CNV calling app
* corresponding annotation.tsv that can be used directly as input to the CNV calling stage

## Dependencies
The app requires a tar.gz of the Docker image of GATK 4.2+ and a tar of the reference genome fasta and index files.

### This app was made by East GLH