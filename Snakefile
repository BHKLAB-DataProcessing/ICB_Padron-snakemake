from snakemake.remote.S3 import RemoteProvider as S3RemoteProvider
S3 = S3RemoteProvider(
    access_key_id=config["key"], 
    secret_access_key=config["secret"],
    host=config["host"],
    stay_on_remote=False
)
prefix = config["prefix"]
filename = config["filename"]
data_source  = "https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Padron-data/main/"

rule get_MultiAssayExp:
    input:
        S3.remote(prefix + "processed/CLIN.csv"),
        S3.remote(prefix + "processed/EXPR.csv"),
        S3.remote(prefix + "processed/cased_sequenced.csv"),
        S3.remote(prefix + "annotation/Gencode.v40.annotation.RData")
    output:
        S3.remote(prefix + filename)
    resources:
        mem_mb=4000
    shell:
        """
        Rscript -e \
        '
        load(paste0("{prefix}", "annotation/Gencode.v40.annotation.RData"))
        source("https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Common/main/code/get_MultiAssayExp.R");
        saveRDS(
            get_MultiAssayExp(study = "Padron", input_dir = paste0("{prefix}", "processed")), 
            "{prefix}{filename}"
        );
        '
        """

rule download_annotation:
    output:
        S3.remote(prefix + "annotation/Gencode.v40.annotation.RData")
    shell:
        """
        wget https://github.com/BHKLAB-Pachyderm/Annotations/blob/master/Gencode.v40.annotation.RData?raw=true -O {prefix}annotation/Gencode.v40.annotation.RData 
        """

rule format_data:
    input:
        S3.remote(prefix + "download/NatureMed_GX_ph2_metadata.csv"),
        S3.remote(prefix + "download/PICI0002_ph2_clinical.csv"),
        S3.remote(prefix + "download/rnaseq.zip")
    output:
        S3.remote(prefix + "processed/CLIN.csv"),
        S3.remote(prefix + "processed/EXPR.csv"),
        S3.remote(prefix + "processed/cased_sequenced.csv")
    resources:
        mem_mb=2000
    shell:
        """
        unzip -d {prefix}download/rnaseq {prefix}/download/rnaseq.zip
        Rscript scripts/Format_Data.R {prefix}download {prefix}processed 
        rm -rf {prefix}download/rnaseq
        """

rule download_data:
    output:
        S3.remote(prefix + "download/NatureMed_GX_ph2_metadata.csv"),
        S3.remote(prefix + "download/PICI0002_ph2_clinical.csv"),
        S3.remote(prefix + "download/rnaseq.zip")
    resources:
        mem_mb=2000
    shell:
        """
        Rscript scripts/download_data.R {prefix}download
        """ 