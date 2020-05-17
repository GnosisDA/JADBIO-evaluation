
# Script for converting the metabolomics data

# set up
rm(list = ls())

#hard coded parameters
curationFile <- 'DatasetCuration.csv';
convertedFold <- 'MS_converted'
removedSamplesFold <- 'MS_converted_removed_samples'
datasetFold <- 'MS_datasets';

#loading the curation file
curatedFiles <- read.csv(curationFile, stringsAsFactors = FALSE, header = TRUE);
nCuratedFiles <- dim(curatedFiles)[1];

#files with samples to be removed
removenda <- dir(removedSamplesFold);

#read each file, and label the target as such (if identified)
for(i in 1:nCuratedFiles){
  
  #printing
  print(paste0(i, ' out of ', nCuratedFiles))
  
  #reading the data
  fileName <- curatedFiles$Study.ID[i];
  dataset <- tryCatch(suppressWarnings(
                        read.csv(file.path(convertedFold, paste0(fileName, '.txt')),
                               stringsAsFactors = FALSE, header = TRUE)
                        ),
                      error = function(e){''});
  
  #if not dataset, then proceed to the next 
  if(class(dataset)[1] == 'character'){
    next;
  }
  
  #first step: checking if the target name is in the column names.
  idTarget <- which(sub(pattern = ' ', replacement = '.', 
                        toupper(names(dataset)), fixed = TRUE) == 
                      sub(pattern = ' ', replacement = '.', 
                          toupper(curatedFiles$Class[i]), fixed = TRUE))
  if(length(idTarget) == 0){
    #no possible target, so next
    next;
  }
  
  #check if any sample to remove
  if(paste0(fileName, '.txt') %in% removenda){
    
    #loading the file
    removendum <- tryCatch(
                    suppressWarnings(
                      read.csv(file.path(removedSamplesFold, paste0(fileName, '.txt')), 
                        stringsAsFactors = FALSE, header = TRUE)
                    ), 
                    error = function(e){''}
                  );
    
    #target in the removendum file
    idTargetRemovendum <- which(sub(pattern = ' ', replacement = '.', 
                                    toupper(names(removendum)), fixed = TRUE) == 
                                  sub(pattern = ' ', replacement = '.', 
                                      toupper(curatedFiles$Class[i]), fixed = TRUE))

    #target value to keep
    valuesToKeep <- unique(removendum[[idTargetRemovendum]])
    
    #correction
    if(is.numeric(valuesToKeep) & min(valuesToKeep) == 2){
      valuesToKeep <- valuesToKeep - 1;
    }
    
    #selecting the sample to keep
    toKeep <- which(dataset[[idTarget]] %in% valuesToKeep)
    if(length(toKeep) == 0){
      stop('Something is wrong in the selection of the samples')
    }
    
    #refining the dataset
    dataset <- dataset[toKeep, ]
    
  }
  
  #having the target called... target 
  names(dataset)[idTarget] <- 'target';
  
  #writing
  write.csv(dataset, file.path(datasetFold, paste0(fileName, '.csv')), 
           row.names = FALSE, quote = FALSE, na = 'NaN')
  save(dataset, file = file.path(datasetFold, paste0(fileName, '.RData')))
  
}
