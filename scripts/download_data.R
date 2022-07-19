args <- commandArgs(trailingOnly = TRUE)
work_dir <- args[1]

url <- 'https://raw.githubusercontent.com/ParkerICI/prince-trial-data/main/'
download.file(paste0(url, 'Clinical/', 'PICI0002_ph2_clinical.csv'), destfile=file.path(work_dir, 'PICI0002_ph2_clinical.csv'))
download.file(paste0(url, 'RNAseq/', 'NatureMed_GX_ph2_metadata.csv'), destfile=file.path(work_dir, 'NatureMed_GX_ph2_metadata.csv'))

rnaseq_files <- read.csv(file.path(work_dir, 'NatureMed_GX_ph2_metadata.csv'))
rnaseq_files <- rnaseq_files$Filename
dir.create(file.path(work_dir, 'rnaseq'), showWarnings = FALSE)
url <- 'https://github.com/ParkerICI/prince-trial-data/raw/main/RNAseq/Data/'
for(file in rnaseq_files){
  download.file(paste0(url, file), destfile=file.path(work_dir, 'rnaseq', file))
}

zip(
  zipfile=file.path(work_dir, 'rnaseq.zip'), 
  files=paste(work_dir, 'rnaseq', rnaseq_files, sep='/'),
  flags = '-r9Xj'
)

unlink(file.path(work_dir, 'rnaseq'), recursive = TRUE)