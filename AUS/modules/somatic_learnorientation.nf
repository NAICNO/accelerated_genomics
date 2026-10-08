/*
 * learnorientation: GATK LearnReadOrientationModel on MUTECTCALLER's F1R2
 * counts (spec C3, §3.4.2). The model feeds FilterMutectCalls --ob-priors,
 * which applies the read-orientation (FFPE / OxoG) artifact filter -- GATK
 * Best Practices, and the only consumer of the CPU command's --f1r2-tar-gz.
 * CPU, GATK container. Runs only when params.mutect_orientation_filter.
 *
 * Collaborator confirmation that their FilterMutectCalls uses --ob-priors is
 * still pending (spec D6) -- set --mutect_orientation_filter false to match a
 * CPU pipeline that doesn't.
 */

process LEARNORIENTATION {
    tag "${tumor_id}_vs_${normal_id}"
    label 'leaf_process'
    container params.gatk_container

    input:
    tuple val(tumor_id), val(normal_id), path(f1r2)

    output:
    tuple val(tumor_id), val(normal_id), path("${tumor_id}.read-orientation-model.tar.gz"), emit: model

    script:
    """
    gatk LearnReadOrientationModel \\
        -I ${f1r2} \\
        -O ${tumor_id}.read-orientation-model.tar.gz
    """
}
