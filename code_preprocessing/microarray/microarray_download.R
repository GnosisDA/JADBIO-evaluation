
# Script for downloading microarray datasets from dataome

# set up
rm(list = ls())
library(data.table)
options(download.file.method = 'wget')

# control panel
platform <- 'GPL570'
sampleSizeLimit <- 40
singleClassLimit <- 10
dateToday <- format(Sys.time(), format='%Y-%m-%d')

# creating destination folder
destinationFolder <- dateToday
dir.create(destinationFolder, recursive = TRUE, showWarnings = FALSE)

# datasets available in dataome
metadata <- read.csv('../metadata.csv', stringsAsFactors = FALSE)
metadata <- metadata[grep('GSE', metadata$gse), ]
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
metadata <- metadata[metadata$nCases >= 10 & metadata$nControls >= 10, ]
nDatasets <- dim(metadata)[1]

# looping over the datasets
for(i in 1:nDatasets){

  # printing info
  print(paste0('Dataset: ', i, ' out of ', nDatasets))
  
  # try catch for safety
  tryCatch({
    
    # download
    dataset <- fread(metadata$dataset[i])
    annotation <- fread(metadata$annotation[i])
    
    #keeping only the class from the annotation
    annotation  <- annotation[ , c('samples', 'class')]
    
    #transforming the class in numerical and calling it target
    annotation$class[annotation$class != 'control'] <- '1'
    annotation$class[annotation$class == 'control'] <- '0'
    annotation$target <- as.numeric(annotation$class)
    annotation$class <- NULL
    
    #merging
    if(grepl('GSE', metadata$gse[i])){
      toWrite <- merge(dataset, annotation, by = 'samples')
    }else{
      stop(paste0('Something wrong with ', metadata$gse[i]))
    }
  
    #writing
    fwrite(toWrite, file = file.path(destinationFolder, 
                                     paste0(metadata$gse[i], '.csv')), 
           quote = FALSE, row.names = FALSE);
    
    # if error, it prints what went wrong
  }, error = function(e){print(paste0('Something wrong with ', metadata$gse[i]))})

}
