
# Script for selecing the datasets

# set up
rm(list = ls())
set.seed(123)
library(data.table)

#hard coded parameters
pathToCopyFrom <- 'MS_datasets'
pathToCopyTo <- 'MS_datasets_final'
sampleSizeLimit <- 40
singleClassLimit <- 10

#files to copy
files <- dir(pathToCopyFrom, pattern = '.csv')
nFiles <- length(files)

# ensuring the folder exists
dir.create(pathToCopyTo, showWarnings = FALSE)

# creating the metadata
metadata <- data.frame(files = files, nCases = NA, nControls = NA)
for(i in 1:nFiles){
  dataset <- fread(file.path(pathToCopyFrom, files[i]))
  metadata$nCases[i] <- sum(dataset$target)
  metadata$nControls[i] <- sum(dataset$target == 0)
}
metadata$nSamples <- metadata$nCases + metadata$nControls

# restricting to interesting datasets
metadata <- metadata[metadata$nSamples >= sampleSizeLimit & 
                       metadata$nCases >= singleClassLimit & 
                       metadata$nControls >= singleClassLimit, ]
files <- metadata$files
nFiles <- length(files)

#copy each file
for(i in 1:nFiles){
  file.copy(from = file.path(pathToCopyFrom, files[i]),
            to = file.path(pathToCopyTo, files[i]))
}

