def asString (args) {
    s = ""
    if (args.size()>0) {
        if (args[0] != 'none') {
            for (param in args.keySet().sort()){
                s = s + ",'"+param+"'='"+args[param]+"'"
            }
        }
    }
    return s
}
process DEFINE_CLONES {
    tag 'all_reps'

    label 'process_long_parallelized'
    label 'immcantation'

    conda (params.enable_conda ? "bioconda::r-enchantr=0.0.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-enchantr:0.0.3--r42hdfd78af_1':
        'quay.io/biocontainers/r-enchantr:0.0.3--r42hdfd78af_1' }"

    input:
    //tuple val(meta), path(tabs) // sequence tsv in AIRR format
    path(tabs)
    val threshold
    path imgt_base

    output:
    path("*/*clone-pass.tsv"), emit: tab, optional: true // sequence tsv in AIRR format
    path("*/*_command_log.txt"), emit: logs //process logs
    path "*_report"
    path "versions.yml", emit: versions


    script:
    def args = asString(task.ext.args) ?: ''
    """
    Rscript -e "enchantr::enchantr_report('define_clones', \\
                                        report_params=list('input'='${tabs.join(',')}', \\
                                        'imgt_db'='${imgt_base}', \\
                                        'cloneby'='${params.cloneby}', \\
                                        'threshold'=${threshold}, \\
                                        'singlecell'='${params.singlecell}','outdir'=getwd(), \\
                                        'nproc'=${task.cpus},\\
                                        'log'='all_reps_clone_command_log' ${args}))"

    echo "${task.process}": > versions.yml
    Rscript -e "cat(paste0('  enchantr: ',packageVersion('enchantr'),'\n'))" >> versions.yml

    mv enchantr 'all_reps_clone_report'
    """
}
