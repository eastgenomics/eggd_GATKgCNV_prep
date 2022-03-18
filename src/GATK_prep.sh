#!/bin/bash
# GATK_prepIntervals_dev

# Exit at any point if there is any error and output each line as it is executed (for debugging)
set -e -x -o pipefail

main() {

    # Load the GATK docker image
    dx download "$GATK_docker" -o GATK.tar.gz
    docker load -i GATK.tar.gz
    GATK_image=$(docker images --format="{{.Repository}} {{.ID}}" | grep "^broad" | cut -d' ' -f2)

    ## Create folder to collect input files:
    mkdir inputs
    cd inputs

    # Reference genome fasta, fai, dict
    dx download "$reference_genome" -o ref_gen.fasta-index.tar.gz
    tar -xvzf ref_gen.fasta-index.tar.gz

    # Intervals file (either capture bed or targeted exons bed)
    dx download "$bed_file" -o capture.bed
    sed -i 's/^chr//' capture.bed
    sort -k1V -k2n capture.bed > capture_targets.bed

    # Add annotation to intervals if requested and annotation bed file is provided
    # Mappability
    if $toAnnotateMap; then
        if [[ ! -z $mappability_bed ]]; then
            echo "Mappability track is provided as '$mappability_bed'"
            dx download "$mappability_bed" -o mappability.bed
            sed -i 's/^chr//' mappability.bed
            sort -k1V -k2n mappability.bed > mappability_merged.bed
            # sorted bed file needs to be indexed by GATK for later use
            docker run -v /home/dnanexus/inputs:/data $GATK_image gatk IndexFeatureFile \
                -I /data/mappability_merged.bed
        else
            dx download project-FzyfP204Z5qXBp6696jG5g10:file-G44VKQ84Z5qZJ3fx9x4GVJ4G -o mappability_merged.bed
            dx download project-FzyfP204Z5qXBp6696jG5g10:file-G44VKX84Z5qffyfq1yBk6Gk3 -o mappability_merged.bed.idx
        fi
        map_track="--mappability-track /data/mappability_merged.bed"
    else
        map_tracks=""
    fi

    # Segmental duplication
    if $toAnnotateSegDup; then
        if [[ ! -z $segdup_bed ]]; then
            echo "Segmental duplication track is provided as '$segdup_bed'"
            dx download "$segdup_bed" -o segdup.bed
            sed -i 's/^chr//' segdup.bed
            sort -k1V -k2n segdup.bed > segmental_duplication.bed
        else
            dx download project-FzyfP204Z5qXBp6696jG5g10:file-G44VP9Q4Z5qf3jVP4p5K482v -o beds/segdup.bed
            sort -k1V -k2n segdup.bed > segmental_duplication.bed
        fi
        # sorted bed file needs to be indexed by GATK for later use
        docker run -v /home/dnanexus/inputs:/data $GATK_image gatk IndexFeatureFile \
            -I /data/segmental_duplication.bed
        segdup_track="--segmental-duplication-track /data/segmental_duplication.bed"
    else
        segdup_track=""
    fi

    echo "All input files have downloaded to inputs/"
    cd ..

    # A. Run PreprocessIntervals:
    # takes the capture bed file and pads the regions by optional number of bases
    echo "Running PreprocessIntervals for the input bed"
    /usr/bin/time -v docker run -v /home/dnanexus/inputs:/data $GATK_image gatk PreprocessIntervals \
        -R /data/genome.fa \
        -L /data/capture_targets.bed -imr OVERLAPPING_ONLY \
        --bin-length $bin_length --padding $padding \
        -O /data/preprocessed.interval_list

    # B. Run AnnotateIntervals: --verbosity DEBUG
    echo "Running AnnotateIntervals for the preprocessed interval list"
    /usr/bin/time -v docker run -v /home/dnanexus/inputs:/data $GATK_image gatk AnnotateIntervals \
        -R /data/genome.fa \
        -L /data/preprocessed.interval_list -imr OVERLAPPING_ONLY \
        $map_track $segdup_track \
        -O /data/annotated_intervals.tsv

    echo "All scripts finished successfully, collecting output files to be uploaded to dx"

    ## Create outdir and move result files in to be uploaded
    cp inputs/preprocessed.interval_list "$filename".interval_list
    interval_list=$(dx upload "$filename".interval_list --brief)
    dx-jobutil-add-output interval_list "$interval_list" --class=file

    cp inputs/annotated_intervals.tsv "$filename"_annotation.tsv
    interval_annotation=$(dx upload "$filename"_annotation.tsv --brief)
    dx-jobutil-add-output interval_annotation "$interval_annotation" --class=file

}