
#### Script for producing the scatterplots panels reported in Figure 4 ####

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
xLine <- 0.5 
yLine <- 0.5
diagonalLine <- list(intercept = 0, slope = 1)
xLimits <- c(0.15, 1)
yLimits <- c(0.15, 1)
colorPalette <- c("darkblue", "#E31A1C", "green4", "#6A3D9A");

#### Plotting ####

#looing over sample sizes
sampleSize = sampleSizes[1]
for(sampleSize in sampleSizes){
  
  # load JADBIO results
  load(file.path(resultsFolder, 'JADBIO_results.RData'))
  
  #selecting the data
  toPlot1 <- JADBIO_results[JADBIO_results$setting ==  settingToPlot,
                         c(xName1, yName, 'sampleSizeTrain')];
  toPlot1[[factorName]] <- 'BBC-CV'
  names(toPlot1)[1] <- xName
  toPlot2 <- JADBIO_results[JADBIO_results$setting ==  settingToPlot,
                         c(xName2, yName, 'sampleSizeTrain')];
  toPlot2[[factorName]] <- 'CV'
  names(toPlot2)[1] <- xName
  toPlot <- rbind(toPlot1, toPlot2)
  
  # selecing according to sample size
  if(sampleSize == 'above'){
    filename <- paste0('scatterPlot_datasets_above_', sampleSizeThreshold, '_samples.png')
    toPlot <- toPlot[toPlot$sampleSizeTrain >= sampleSizeThreshold, ]
  }
  if(sampleSize == 'below'){
    filename <- paste0('scatterPlot_datasets_below_', sampleSizeThreshold, '_samples.png')
    toPlot <- toPlot[toPlot$sampleSizeTrain < sampleSizeThreshold, ]
  }
  if(sampleSize == 'all'){
    filename <- 'scatterPlot_all_datasets.png'
  }
  
  #main plot
  p <- ggplot(toPlot, aes_string(x = xName, 
                                 y = yName,
                                 color = factorName)) + 
    geom_point(size = 1, alpha = 0.2) + 
    xlab(xLabel) + 
    ylab(yLabel) + 
    xlim(xLimits) + 
    ylim(yLimits) +
    scale_color_manual(values = colorPalette, name = 'Protocol') +
    theme_bw() + 
    theme(panel.grid.major = element_blank(),
          panel.grid.minor = element_blank())
  
  # adding lines to the main plot
  p <- p + stat_smooth(aes_string(color = factorName),
                       se = TRUE, 
                       span = 1.5,
                       method = 'loess')
  p <- p + geom_abline(slope = diagonalLine$slope, 
                       intercept = diagonalLine$intercept, 
                       size = 1, color = 'darkgrey', linetype="dashed")
  p <- p + geom_vline(xintercept = xLine, 
                      size = 1, color = 'darkgrey',
                      linetype="dashed")
  p <- p + geom_hline(yintercept = yLine, 
                      size = 1, color = 'darkgrey',
                      linetype="dashed")
  
  
  #x-axis plot
  pX <- ggplot(toPlot, aes_string(x = xName, group = factorName, fill = factorName)) + 
    geom_density(colour = 'white', alpha = 0.5) + 
    theme_minimal() + 
    theme(legend.position = "none", 
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.text.x =element_blank(),
          axis.text.y = element_text(color="white")) +
    scale_fill_manual(values = colorPalette) +
    ylab('')
  if(!is.null(xLimits)){
    pX <- pX + xlim(xLimits);
  }
  
  #y-axis plot
  pY <- ggplot(toPlot, aes_string(x = yName, group = factorName, fill = factorName)) + 
    geom_density(colour = 'white', alpha = 0.5) + 
    coord_flip() + 
    theme_minimal() + 
    theme(legend.position = "none", 
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.y = element_blank(),
          axis.text.y = element_blank(),
          axis.text.x = element_text(color="white")) + 
    scale_fill_manual(values = colorPalette) +
    ylab('')
  if(!is.null(yLimits)){
    pY <- pY + xlim(yLimits);
  }
  
  #empty plot
  emptyPlot <- ggplot(data.frame()) + 
    geom_blank() + 
    theme(panel.background = element_blank(), 
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank());
  
  #legend 
  uniqueLegend <- g_legend(p);
  p <- p + theme(legend.position = "none")
  
  #final plot
  png(filename = filename, width = 2100, height = 2100, res = 300)
  p <- grid.arrange(arrangeGrob(pX, uniqueLegend, p, pY, nrow=2, 
                                widths=unit.c(unit(0.8, "npc"), unit(0.2, "npc")), 
                                heights=unit.c(unit(0.2, "npc"), unit(0.8, "npc"))))
  dev.off()
  
}

