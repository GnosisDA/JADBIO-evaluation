#### Script for producing Supplementary Figure 2 (auto-sklearn results) ####

#### Setup ####

# loading libraries and functions
rm(list = ls())
library(ggplot2)
library(grid)
source('../ancillaryFunctions.R')

# results folder
resultsFolder <- '../'

# JADBIO settings to consider
settings <- c('1_overall', '5_FS')

# auto-sklearn model to use
aslModelToUse <- 'ensemblAUC'

#### Plotting ####

# looping over settings
setting <- settings[1]
for(setting in settings){
  
  # load data
  load(file.path(resultsFolder, 'JADBIO_results.RData'))
  load(file.path(resultsFolder, 'auto-sklearn_results.RData'))

  # chosen setting
  JADBIO_results <- JADBIO_results[JADBIO_results$setting == setting, ]
  
  # adding id
  JADBIO_results$id <- paste(JADBIO_results$datasetName, '_', JADBIO_results$split, sep = '')
  autosklearn_results$id <- paste(autosklearn_results$datasetName, '_', autosklearn_results$split, sep = '')
  
  #aligning the data
  toKeep <- intersect(JADBIO_results$id, autosklearn_results$id) 
  JADBIO_results <- JADBIO_results[JADBIO_results$id %in% toKeep, ]
  JADBIO_results <- JADBIO_results[order(JADBIO_results$id), ];
  autosklearn_results <- autosklearn_results[autosklearn_results$id %in% toKeep, ]
  autosklearn_results <- autosklearn_results[order(autosklearn_results$id), ];
  
  # data to plot
  toPlot <- data.frame(percPerformances = JADBIO_results[ , 'holdoutEstimate'] / 
                         autosklearn_results[ , aslModelToUse], 
                       percVars =  log10((as.numeric(autosklearn_results$numInitialVars) + 1)/ 
                                           (as.numeric(JADBIO_results$numSelectedVars) + 1) ));
  
  # median and mean values
  meanValue <- mean(toPlot$percPerformances, na.rm = TRUE)
  print('Mean value performance ratio:')
  print(meanValue)
  print('t-test:')
  print(t.test(toPlot$percPerformances, mu = 1))
  lessE10 <- sum(as.numeric(JADBIO_results$numSelectedVars) <= 10) / 
                                                dim(JADBIO_results)[1]
  print('Percentage of JADBIO runs with <= 10 vars:')
  print(lessE10)
  lessE25 <- sum(as.numeric(JADBIO_results$numSelectedVars) <= 25) / 
                                                dim(JADBIO_results)[1] # note: 32% is obtained considering datasets where most probably dummy variables were removed
  print('Percentage of JADBIO runs with <= 25 vars:')
  print(lessE25)
  print('############')
  
  # plotting
  dataset = toPlot;
  xIndex = 1;
  yIndex = 2;
  xLabel = 'Performance ratio';
  xLabels = c(seq(from = 0.2, to = 0.8, by = 0.2),  
              1, 
              seq(from = 1.2, to = 3.7, by = 0.2));
  yLabel = 'Log 10 compression rate';
  yLabels <- c(1, 5, 10, 50, 100, 500, 1000, 2500, 5000, 10000, 25000, 50000, 100000, 250000)
  xLine = 1;
  xLimits <- c(-0.5, 4);
  yLimits <- log10(c(1, 250000))
  colorPalette <- c("darkblue", "#E31A1C", "green4", "#6A3D9A");
  
  # names of the elements to plot
  xName <- names(dataset)[xIndex];
  yName <- names(dataset)[yIndex];
  
  # main plot
  p <- ggplot(dataset, aes_string(x = xName, y = yName)) + 
    geom_point(color = 'darkblue', alpha = 0.5) + 
    theme_bw() + 
    theme(legend.position = "none", 
          panel.grid.minor = element_blank()) +
    scale_x_continuous(name = xLabel, 
                       breaks = xLabels) +
    scale_y_continuous(name = yLabel, 
                       breaks = log10(yLabels), 
                       labels = format(yLabels))
  
  # line at 1
  p <- p + geom_vline(xintercept = xLine,
                      size = 0.75, color = 'darkgrey', linetype = 'dashed')
  
  # line at median
  p <- p + geom_vline(xintercept = meanValue, 
                      size = 0.75, color = "#E31A1C")
  
  # x-axis plot
  pX <- ggplot(dataset, aes_string(x = xName)) + 
    geom_density(colour = "darkblue", fill = 'darkblue') + 
    scale_y_continuous(breaks = c(0,2,4,6), 
                       labels = rep(250000,4)) +
    theme_minimal() + 
    theme(legend.position = "none", 
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_text(color = 'white')) +
    ylab('')
  
  # y-axis plot
  pY <- ggplot(dataset, aes_string(x = yName)) + 
    geom_density(colour = "darkblue", fill = 'darkblue') + 
    coord_flip() + 
    theme_minimal() + 
    theme(legend.position = "none", 
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.y = element_blank(),
          axis.text.y = element_blank(),
          axis.text.x = element_text(color = 'white')) +
    ylab('')
  
  # empty plot
  emptyPlot <- ggplot(data.frame()) + 
    geom_blank() + 
    theme(panel.background = element_blank(), 
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank());
  
  # final plot
  if(setting == '1_overall'){
    filename <- 'Panel_a.png'
  }else{
    filename <- 'Panel_b.png'
  }
  png(filename = filename, 
      width = 2100, height = 2100, res = 300)
  p <- grid.arrange(arrangeGrob(pX, emptyPlot, p, pY, nrow=2, 
                                widths=unit.c(unit(0.8, "npc"), unit(0.2, "npc")), 
                                heights=unit.c(unit(0.2, "npc"), unit(0.8, "npc"))))
  dev.off()
  
}

