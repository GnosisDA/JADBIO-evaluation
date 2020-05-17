
# Script for converting the metabolomics data

# set up
rm(list = ls())

#hard coded parameters
startDataMatrix <- '_METABOLITE_DATA_START';
endDataMatrix <- '_METABOLITE_DATA_END';
sep <- '\t';
sepFactors <- '|';
dataFold <- 'MS';
convertedFold <- 'MS_converted'

#listing all files 
files <- dir(dataFold)
nFiles <- length(files)

#looping over the files
for(i in 1:nFiles){
  
  #print
  print(paste0('file ', files[i], ', ', i, ' of ', nFiles));
  
  #reading the file
  strings <- readLines(con = file.path(dataFold, files[i]))
  
  #identifying the matrix
  beginningID <- grep(startDataMatrix, strings)
  endID <- grep(endDataMatrix, strings)
  
  #skip if no data
  if(length(beginningID) == 0 || endID - beginningID <= 3){
    next;
  }
  
  #separating the first elements: sample names and factors
  sampleNames <- strsplit(x = strings[beginningID + 1], split = sep)[[1]]
  sampleNames <- sampleNames[which(sampleNames != 'Samples' & sampleNames != 'metabolite_name')]
  factors <- strsplit(x = strings[beginningID + 2], split = sep)[[1]]
  factors <- factors[which(factors != 'Factors')]; 
  
  #reading the metabolomics data
  newLine <- strsplit(x = strings[beginningID + 3], split = sep)[[1]];
  if(nchar(strings[beginningID + 3]) %in% gregexpr(sep, strings[beginningID + 3])[[1]]){
    newLine <- c(newLine, '');
  } 
  dataset <- matrix(newLine, 1, length(newLine))
  for(j in (beginningID + 4):(endID - 1)){
    newLine <- strsplit(x = strings[j], split = sep)[[1]];
    if(nchar(strings[j]) %in% gregexpr(sep, strings[j])[[1]]){
      newLine <- c(newLine, '');
    }
    #tryCatch({
    if(length(newLine) != dim(dataset)[2]){
      next;
    }else{
      dataset <- rbind(dataset, newLine);
    }
  }
  
  #dataset as dataframe
  dataset <- as.data.frame(dataset,stringsAsFactors = FALSE) 
  
  #extracting metabolite names
  metaboliteNames <- dataset[, 1]
  dataset[, 1] <- NULL
  
  #ensuring all columns are numeric
  #dataset <- tryCatch(sapply(dataset, as.numeric), warning = function(w){print(i); stop()})
  dataset <- sapply(dataset, as.numeric);
  
  #transposing and naming the columns
  dataset <- t(dataset);
  colnames(dataset) <- metaboliteNames
  
  #setting the min and log transformation
  dataset <- dataset - min(dataset, na.rm = TRUE) + 10;
  dataset <- log2(dataset);
  dataset <- as.data.frame(dataset)
  
  #eliminating all NA columns
  for(j in (dim(dataset)[2]):1){
    if(all(is.na(dataset[[j]]))){
      dataset[[j]] <- NULL;
    }
  }
  
  #removing constant values
  mins <- sapply(dataset, function(x){min(x, na.rm = TRUE)})
  maxs <- sapply(dataset, function(x){max(x, na.rm = TRUE)})
  toRemove <- which(mins == maxs);
  if(length(toRemove) > 0){
    dataset <- dataset[ , -toRemove];
  }
  
  #identifying the factors names
  factorNames <- strsplit(factors[1], split = '|', fixed = TRUE)[[1]]
  numFactors <- length(factorNames)
  for(j in 1:numFactors){
    factorNames[j] <- substr(factorNames[j], 1, regexpr(':', factorNames[j], fixed = TRUE)[1] - 1)
  }
  
  #creating the factor matrix
  numElements <- length(factors);
  factorMatrix <- matrix(NA, numElements, numFactors);
  for(j in 1:numElements){
    tmp <- strsplit(factors[j], split = '|', fixed = TRUE)[[1]]
    for(k in 1:numFactors){
      factorMatrix[j, k] <- substr(tmp[k], start = regexpr(':', tmp[k], fixed = TRUE)[1] + 1, stop = nchar(tmp[k]))
    }
  }
  colnames(factorMatrix) <- factorNames;
  factorMatrix <- as.data.frame(factorMatrix, stringsAsFactors = FALSE)
  
  #ensuring numeric factors are stored properly
  for(j in 1:numFactors){
    if(suppressWarnings(!any(is.na(as.numeric(factorMatrix[[j]]))))){
      factorMatrix[ ,j] <- as.numeric(factorMatrix[ ,j]);
    }else{
      factorMatrix[ ,j] <- as.numeric(as.factor(factorMatrix[[j]])) - 1;
    }
  }
  
  #complete dataset: sample names, factor matrix and metabolites data
  if(dim(dataset)[1] == length(sampleNames) & dim(dataset)[1] == dim(factorMatrix)[1]){
    dataset <- cbind(sample = sampleNames, factorMatrix, dataset)
  }else{
    print('No concordance between metabolites and phenotype dimension')
    next;
  }

  #writing
  write.csv(x = dataset, file = file.path(convertedFold, files[i]), quote = FALSE, row.names = FALSE)
  save(dataset, file = file.path(convertedFold, paste0(files[i], '.RData')));
  
}
