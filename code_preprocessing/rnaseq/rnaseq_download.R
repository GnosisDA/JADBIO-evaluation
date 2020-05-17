
# Script for downloading rna-seq datasets from dataome

# set up
rm(list = ls())
library(data.table)
library(recount)
options(download.file.method = 'wget')
defaultLibrarySize <- 4*10^7 # https://f1000research.com/articles/6-1558/v1

# control panel
platform <- 'GPL11154'
sampleSizeLimit <- 40
singleClassLimit <- 10
dateToday <- format(Sys.time(), format='%Y-%m-%d')

# creating destination folder
destinationFolder <- dateToday
dir.create(destinationFolder, recursive = TRUE, showWarnings = FALSE)

# datasets available in dataome
metadata <- read.csv('../metadata.csv', stringsAsFactors = FALSE)
metadata$gse <- trimws(metadata$gse)
metadata$dataset <- trimws(metadata$dataset)
metadata$annotation <- trimws(metadata$annotation)

# keep the ones measured with the chosen platform and sample size limit
metadata <- metadata[trimws(as.character(metadata$technology)) == platform, ]
metadata <- metadata[metadata$samples >= sampleSizeLimit, ]
nDatasets <- dim(metadata)[1]

# fetching the information on the number of cases and controls
metadata$nCases <- NA
metadata$nControls <- NA
for(i in 1:nDatasets){
  
  # printing info
  print(paste0('Dataset: ', i))
  
  # try catch for safety
  tryCatch({
    
    # download
    annotation <- NULL
    suppressWarnings(annotation <- fread(metadata$annotation[i]))
    if(is.null(annotation)){
      next
    }
    
    #transforming the class in numerical and calling it target
    metadata$nCases[i] <- sum(annotation$class != 'control')
    metadata$nControls[i] <- sum(annotation$class == 'control')
    
    # if error, it prints what went wrong
  }, error = function(e){print(paste0('Something wrong with ', metadata$gse[i]))})
  
}

#restricting to datasets with singleClassLimit samples for each class
metadata <- metadata[which(metadata$nCases >= 10 & metadata$nControls >= 10), ]
nDatasets <- dim(metadata)[1]

# looping over the datasets
for(i in 1:nDatasets){
  
  # printing info
  print(paste0('Dataset: ', i, ' out of ', nDatasets))
  
  # try catch for safety
  tryCatch({
    
    # download the gene-level RangedSummarizedExperiment data
    download_study(metadata$gse[i], outdir = './tmp')
    
    # load the data
    load(file.path('./tmp', 'rse_gene.Rdata'))
    
    # scale counts by taking into account the total coverage per sample
    rse <- scale_counts(rse_gene)
    
    # extracting the counts
    dataset <- assay(rse)
    
    # scale against the library size
    librarySizes <- colSums(dataset)
    libraryAdjust <- rep(defaultLibrarySize, ncol(dataset)) / librarySizes 
    dataset <- t(apply(dataset, 1, function(x){x * libraryAdjust}))
    
    # log2 transformation
    dataset <- log2(dataset + 1)
    
    # download annotation
    annotation <- fread(metadata$annotation[i])
    
    # keeping only the class from the annotation
    #annotation  <- annotation[ , c('samples', 'class', 'relation')]
    annotation  <- annotation[ , c('samples', 'class')]
    
    # transforming the class in numerical and calling it target
    annotation$class[annotation$class != 'control'] <- '1'
    annotation$class[annotation$class == 'control'] <- '0'
    annotation$target <- as.numeric(annotation$class)
    annotation$class <- NULL
    
    # harmonizing sample ids
    recountAnnotation <- colData(rse)
    if(!all(recountAnnotation$run == colnames(dataset))){
      stop(paste0('Something wrong with alignment in ', metadata$gse[i]))
    }
    colnames(dataset) <- recountAnnotation$geo_accession

    # transposing the dataset
    dataset <- t(dataset)
    dataset <- data.frame(samples = rownames(dataset), dataset)
    
    #merging
    toWrite <- merge(dataset, annotation, by = 'samples')
    
    #writing
    fwrite(toWrite, file = file.path(destinationFolder, 
                                     paste0(metadata$gse[i], '.csv')), 
           quote = FALSE, row.names = FALSE);
    
    # if error, it prints what went wrong
  }, error = function(e){print(paste0('Something wrong with ', metadata$gse[i]))})
  
}
