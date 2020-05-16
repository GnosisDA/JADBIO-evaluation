
#### Script for producing the lineplots panels reported in Figure 4 ####

#### Setup ####

# loading libraries and functions
rm(list = ls())
library(ggplot2)
library(ggExtra)
library(MASS)
library(grid)
library(cowplot)
library(viridis)
source('../ancillaryFunctions.R')

# results folder
resultsFolder <- '../'

# setting to plot
settingToPlot <- '1_overall';

# sample sizes
sampleSizes <- c('all', 'above', 'below')
sampleSizeThreshold <- 40

# info for the graphs
xName <- 'aucEstimate'
xName1 <- 'trainEstimate'
xName2 <- 'uncorrEstimate'
yName <- 'holdoutEstimate'
factorName <- 'estimatesType'
xLabel <- 'AUC estimates on training data'
yLabel <- 'AUC estimates on holdout data'
aucThresholds <- seq(from = 0.5, to = 1, by = 0.1)
nAucThresholds <- length(aucThresholds)
colorPalette <- c("darkblue", "#E31A1C", "green4", "#6A3D9A");

#### Plotting ####

#looing over sample sizes
sampleSize = sampleSizes[1]
for(sampleSize in sampleSizes){
  
  # load JADBIO results
  load(file.path(resultsFolder, 'JADBIO_results.RData'))
  
  # selecting the data
  if(sampleSize == 'all'){
    filename <- 'linePlot_all_datasets.png'
    idx <- 1:dim(JADBIO_results)[1]
  }else{
    if(sampleSize == 'above'){
      filename <- paste0('linePlot_datasets_above_', sampleSizeThreshold, '_samples.png')
      idx <- JADBIO_results$sampleSizeTrain > sampleSizeThreshold
    }else{
      filename <- paste0('linePlot_datasets_below_', sampleSizeThreshold, '_samples.png')
      idx <- JADBIO_results$sampleSizeTrain <= sampleSizeThreshold
    }
  }
  JADBIO_results1 <- JADBIO_results[idx,  ]
  JADBIO_results1 <- JADBIO_results1[JADBIO_results1$setting ==  settingToPlot,
                               c(xName1, yName, 'sampleSizeTrain')];
  JADBIO_results1[[factorName]] <- 'Bootstrap-based'
  names(JADBIO_results1)[1] <- xName
  JADBIO_results2 <- JADBIO_results[idx,  ]
  JADBIO_results2 <- JADBIO_results2[JADBIO_results2$setting ==  settingToPlot,
                               c(xName2, yName, 'sampleSizeTrain')];
  JADBIO_results2[[factorName]] <- 'Cross-validated'
  names(JADBIO_results2)[1] <- xName
  
  # computing the quantities to plot
  
  # initializing the data frame to plot
  numElements <- 2 * nAucThresholds
  toPlotNames <- c('type', 'aucLabel', 'aucValue', 
                   'bias', 'sd', 'n')
  toPlot <- data.frame(matrix(NA, numElements, length(toPlotNames)))
  colnames(toPlot) <- toPlotNames
  count <- 1
  
  # looping over the auc thresholds
  for(j in 1:nAucThresholds){
    
    # selecting the results for each AUC bin
    if(j == 1){
      bbcIdx <- JADBIO_results1$aucEstimate <= aucThresholds[j]
      cvIdx <- JADBIO_results2$aucEstimate <= aucThresholds[j]
    }else{
      bbcIdx <- JADBIO_results1$aucEstimate > aucThresholds[j-1] &
        JADBIO_results1$aucEstimate <= aucThresholds[j]
      cvIdx <- JADBIO_results2$aucEstimate > aucThresholds[j-1] &
        JADBIO_results2$aucEstimate <= aucThresholds[j]
    }
    
    # filling the data frame to plot
    toPlot[count, 'type'] <- 'BBC-CV'
    toPlot[count + 1, 'type'] <- 'CV'
    toPlot[count, 'aucLabel'] <- ifelse(j == 1, paste0('AUC', intToUtf8(8804), aucThresholds[j]), 
                                        paste0(aucThresholds[j-1], '< AUC ', intToUtf8(8804), aucThresholds[j]))
    toPlot[count + 1, 'aucLabel'] <- toPlot[count, 'aucLabel']
    toPlot[count, 'aucValue'] <- aucThresholds[j]
    toPlot[count + 1, 'aucValue'] <- toPlot[count, 'aucValue']
    if(sum(bbcIdx) >= 5){
      toPlot[count, 'bias'] <- mean(JADBIO_results1$holdoutEstimate[bbcIdx] - JADBIO_results1$aucEstimate[bbcIdx])
      toPlot[count, 'sd'] <- sd(JADBIO_results1$holdoutEstimate[bbcIdx] - JADBIO_results1$aucEstimate[bbcIdx])
    }
    if(sum(cvIdx) >= 5){
      toPlot[count + 1, 'bias'] <- mean(JADBIO_results2$holdoutEstimate[cvIdx] - JADBIO_results2$aucEstimate[cvIdx])
      toPlot[count + 1, 'sd'] <- sd(JADBIO_results2$holdoutEstimate[cvIdx] - JADBIO_results2$aucEstimate[cvIdx])
    }
    toPlot[count, 'n'] <- sum(bbcIdx)
    toPlot[count + 1, 'n'] <- sum(cvIdx)
    count <- count + 2
    
  }
  
  # plotting average bias
  p <- ggplot(data = toPlot, mapping = aes(x = aucValue, y = bias,
                                           group = type, color = type)) + 
    geom_errorbar(aes(ymin = (bias-sd), ymax = (bias+sd), color = type), 
                  position = position_dodge(width = 0.01)) +
    geom_line(size = 1) +
    geom_point() +
    scale_x_continuous(name = 'AUC estimated on training data',
                       breaks = toPlot$aucValue,
                       labels = toPlot$aucLabel) +
    scale_y_continuous(name = 'Average AUC bias',
                       limits = c(-0.3, 0.25),
                       breaks = seq(from = -0.3, to = 0.25, by = 0.1), 
                       labels = format(round(seq(from = -0.3, to = 0.25, by = 0.1), 
                                             digits = 2), scientific = FALSE)) +
    scale_color_manual(values = colorPalette, name = 'Protocol') +
    geom_hline(yintercept = 0,
               size = 1, color = 'darkred',
               linetype="dashed") +
    theme_bw() +
    guides(fill = FALSE)
  png(filename = filename, 
      width = 2500, height = 1500, res = 300)
  suppressWarnings(plot(p))
  dev.off()
  
}

