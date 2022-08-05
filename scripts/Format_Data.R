library(data.table)

args <- commandArgs(trailingOnly = TRUE)
input_dir <- args[1]
output_dir <- args[2]

source("https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Common/main/code/Get_Response.R")
source("https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Common/main/code/format_clin_data.R")

#############################################################################
#############################################################################
## Get Clinical data


clin = read.table( file = file.path(input_dir, "PICI0002_ph2_clinical.csv") , sep="," , header=TRUE , stringsAsFactors=FALSE )
clin$Deidentified.ID = paste0( 'P' , clin$Deidentified.ID )
rownames( clin ) = clin$Deidentified.ID

clin[ , "clinical.observation.os.event" ] <- ifelse( as.character( clin[ , "clinical.observation.os.event" ] ) %in% "TRUE" , 1 , 
              ifelse( as.character( clin[ , "clinical.observation.os.event" ] ) == "FALSE" , 0 , NA ) )
clin[ , "clinical.observation.pfs.event" ] <- ifelse( as.character( clin[ , "clinical.observation.pfs.event" ] ) %in% "TRUE" , 1 , 
              ifelse( as.character( clin[ , "clinical.observation.pfs.event" ] ) == "FALSE" , 0 , NA ) )

clin[ , "clinical.observation.os" ] <- as.numeric( as.character( clin[ , "clinical.observation.os" ] ) ) / 30.5
clin[ , "clinical.observation.pfs" ] <- as.numeric( as.character( clin[ , "clinical.observation.pfs" ] ) ) / 30.5

clin = clin[ clin$Arm %in% c( "A1" , "C2") , ]

clin_original <- clin
selected_cols <- c( "Deidentified.ID" , "Sex" , "Age" , "clinical.observation.os", "clinical.observation.os.event", "clinical.observation.pfs", "clinical.observation.pfs.event" ) 
clin = as.data.frame( cbind( clin[ , selected_cols ] , "PD-1/PD-L1" , "Pancreas" , NA , NA , NA , NA , NA , NA , NA , NA ) )
colnames(clin) = c( "patient" , "sex" , "age" , "t.os" , "os" , "t.pfs" , "pfs" , "drug_type" , "primary" , "response" , "recist" , "histo" , "response" , "stage" , "response.other.info" , "dna" , "rna" )

clin$patient = sapply( clin$patient , function( x ){ paste( unlist( strsplit( x , "-" , fixed = TRUE )) , collapse = "." ) } ) 

rownames(clin) = clin$patient

clin$response = Get_Response( data=clin )

clin$rna = "tpm"
clin = clin[ , c("patient" , "sex" , "age" , "primary" , "histo" , "stage" , "response.other.info" , "recist" , "response" , "drug_type" , "dna" , "rna" , "t.pfs" , "pfs" , "t.os" , "os" ) ]

clin <- format_clin_data(clin_original, 'Deidentified.ID', selected_cols, clin)

#####################################################################
#####################################################################

meta_rnaseq = read.table( file = file.path(input_dir, "NatureMed_GX_ph2_metadata.csv") , sep="," , header=TRUE , stringsAsFactors=FALSE )
meta_rnaseq$Deidentified.ID = paste0( 'P' , meta_rnaseq$Deidentified.ID )
rownames( meta_rnaseq ) = meta_rnaseq$Deidentified.ID

tpm = read.table( file = file.path( input_dir, "rnaseq", meta_rnaseq$Filename[1] ) , sep="\t" , header=TRUE , stringsAsFactors=FALSE )$Gene.Symbol
for( i in 1:nrow(meta_rnaseq) ){
  rnaseq = read.table( file = file.path( input_dir, "rnaseq" , meta_rnaseq$Filename[i] ) , sep="\t" , header=TRUE , stringsAsFactors=FALSE )
  tpm = cbind( tpm , rnaseq$TPM )
}
colnames( tpm ) = c( "geneID" , rownames( meta_rnaseq ) )
rownames( tpm ) = tpm[ , 1 ]
expr = as.data.frame( tpm[ , -1 ] )

#####################################################################
#####################################################################

patient = intersect( colnames(expr) , rownames(clin) )
clin = clin[ patient , ]
expr =  expr[ , patient ]
rows <- rownames(expr)
expr <- sapply(expr, as.numeric)
expr <- log2(expr + 0.001)
rownames(expr) <- rows

# save( clin , expr , file=file.path(output_dir, "Padron.RData") )

case = cbind( patient , 0 , 0 , 1 )
colnames(case ) = c( "patient" , "snv" , "cna" , "expr" )

write.table( case , file = file.path(output_dir, "cased_sequenced.csv") , sep = ";" , quote = FALSE , row.names = FALSE)
write.table( clin , file = file.path(output_dir, "CLIN.csv") , sep = ";" , quote = FALSE , row.names = FALSE)
write.table( expr , file= file.path(output_dir, "EXPR.csv") , quote=FALSE , sep=";" , col.names=TRUE , row.names=TRUE )
