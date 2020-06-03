
#### Script for running the autosklearn analyses ####

# Set up
# Looping over JAD runs:
#   Creating datasets and results folder
#   Creating the script
#   Adding the script to the queue

#### Set up ####

# cleaning environment, loading functions and libraries
rm(list = ls())
library('data.table')
source('autosklearn_bash.R')

# control panel
datasetsFolder <- '../datasets'
jadResultsFolder <- '../results_JADBIO'
tmpFolder <- './tmp'
n <- 20 # number of cores

# loading JAD results 
load(file.path(jadResultsFolder, 'JADBIO_results.RData')) # tabular data
JADBIO_results <- JADBIO_results[JADBIO_results$setting == '1_overall', ]

# information about the JAD results
nRuns <- dim(JADBIO_results)[1]
datasetNames <- JADBIO_results$datasetName
datasetTypes <- JADBIO_results$type
splits <- JADBIO_results$split
executionTimes <- JADBIO_results$executionTime

#### Looping over JAD runs ####
for(i in 1:nRuns){
  
  #### Creating datasets and results folder ####
  
  # current analysis
  datasetName <- datasetNames[i]
  datasetType <- datasetTypes[i]
  split_i <- splits[i]
  
  # check if dataset and results exists
  datasetFile <- file.path(datasetsFolder, paste0(datasetName, '.csv'))
  datasetResultsFolder <- file.path(jadResultsFolder, datasetName)
  if(!file.exists(datasetFile) | !file.exists(datasetResultsFolder)){
    next()
  }
  
  # retrieving the splitting information
  foldsInfo <- list()
  tmp <- readLines(file.path(datasetResultsFolder,'indices.csv'), warn = FALSE)
  foldsInfo$split1 <- as.numeric(strsplit(tmp[[1]], ',')[[1]][-1]) + 1
  foldsInfo$split2 <- as.numeric(strsplit(tmp[[2]], ',')[[1]][-1]) + 1
  
  # checking if data are already written
  if(!file.exists(file.path(tmpFolder, 'data', paste0(datasetName, '_', split_i, '.csv')))){
    
    # loading the data
    dataset <- fread(datasetFile)
    
    # ensuring status has two values
    if(is.character(dataset$status)){
      dataset$status <- as.numeric(factor(toupper(dataset$status)))
    }
    
    # splitting the data
    dataset_split1 <- dataset[foldsInfo$split1, ]
    dataset_split2 <- dataset[foldsInfo$split2, ]
    
    # writing the data
    fwrite(dataset_split1[, 2:ncol(dataset_split1)], file = file.path(tmpFolder, 'data', paste0(datasetName, '_split1.csv')), 
              row.names = FALSE, quote = FALSE)
    fwrite(dataset_split2[, 2:ncol(dataset_split2)], file = file.path(tmpFolder, 'data', paste0(datasetName, '_split2.csv')), 
              row.names = FALSE, quote = FALSE)
    
  }
  
  # creating the results folder
  dir.create(file.path(tmpFolder, 'results', paste0(datasetName, '_', split_i)), 
             recursive = TRUE, showWarnings = FALSE)

  #### Creating the script ####
  
  # training and test set
  if(split_i == 'split1'){
    a <- paste0(datasetName, '_split1')
    b <- paste0(datasetName, '_split2')
  }else{
    a <- paste0(datasetName, '_split2')
    b <- paste0(datasetName, '_split1')
  }
  
  # computational time
  cTime <- ceiling(executionTimes[i]);
  
  # writing the script
  bashFile <- file.path(tmpFolder, 'scripts', 
                        paste0(datasetName, '_', split_i, '.sh'))
  outputFile <- file.path(tmpFolder, 'results', 
                          paste0(datasetName, '_', split_i, '/out.txt'))
  errorFile <- file.path(tmpFolder, 'results', 
                          paste0(datasetName, '_', split_i, '/error.txt'))
  if(datasetType == 'methylation'){
    mem <- 300
  }else{
    mem <- 64
  }
  autosklearn_bash(bashFile = bashFile, 
                   a = a, 
                   b = b, 
                   cTime = cTime, 
                   n = n,
                   mem = mem)
  
  #### Adding the script to the queue ####
  system(paste('sbatch', '-o', outputFile, '-e', errorFile, bashFile, sep = ' '))
  
}
