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
    output:
        S3.remote(prefix + filename)
    input:
        S3.remote(prefix + "processed/CLIN.csv"),
        S3.remote(prefix + "processed/EXPR.csv"),
        S3.remote(prefix + "processed/cased_sequenced.csv"),
        S3.remote(prefix + "annotation/Gencode.v40.annotation.RData")
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
    output:
        S3.remote(prefix + "processed/CLIN.csv"),
        S3.remote(prefix + "processed/EXPR.csv"),
        S3.remote(prefix + "processed/cased_sequenced.csv")
    input:
        S3.remote(prefix + "download/NatureMed_GX_ph2_metadata.csv"),
        S3.remote(prefix + "download/PICI0002_Labs_2021-03-24.csv"),
        S3.remote(prefix + "download/PICI0002_ph2_clinical.csv"),
        S3.remote(prefix + "download/rnaseq.zip")
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
        S3.remote(prefix + "download/PICI0002_Labs_2021-03-24.csv"),
        S3.remote(prefix + "download/PICI0002_ph2_clinical.csv"),
        S3.remote(prefix + "download/rnaseq.zip")
    resources:
        mem_mb=2000
    shell:
        """
        wget {data_source}NatureMed_GX_ph2_metadata.csv -O {prefix}download/NatureMed_GX_ph2_metadata.csv
        wget {data_source}PICI0002_Labs_2021-03-24.csv -O {prefix}download/PICI0002_Labs_2021-03-24.csv
        wget {data_source}PICI0002_ph2_clinical.csv -O {prefix}download/PICI0002_ph2_clinical.csv
        wget {data_source}rnaseq.zip -O {prefix}download/rnaseq.zip
        """ 