#### Script for producing panel a from Figure 5 ####

#### Setup ####

# loading libraries and functions
rm(list = ls())
library(ggplot2)
library(grid)
library(gridExtra)
source('../ancillaryFunction.R')

# results folder
resultsFolder <- '../'

#### Plotting ####

# load data
load(file.path(resultsFolder, 'JADBIO_results.RData'))

# data with and without feature selection
fsData <- JADBIO_results[JADBIO_results$setting == '5_FS', ]
fsData$id <- paste(fsData$datasetName, '_', fsData$split, sep = '')
noFsData <- JADBIO_results[JADBIO_results$setting == '3_NOFS', ]
noFsData$id <- paste(noFsData$datasetName, '_', noFsData$split, sep = '')

# aligning the data
toKeep <- intersect(fsData$id, noFsData$id) 
fsData <- fsData[fsData$id %in% toKeep, ]
fsData <- fsData[order(fsData$id), ];
noFsData <- noFsData[noFsData$id %in% toKeep, ]
noFsData <- noFsData[order(noFsData$id), ];

# data to plot
toPlot <- data.frame(percPerformances = fsData[ , 'holdoutEstimate'] / 
                                          noFsData[ , 'holdoutEstimate'], 
                     percVars =  log10((as.numeric(noFsData$numSelectedVars) + 1) / 
                                         (as.numeric(fsData$numSelectedVars) + 1)));

# median value
medianValue <- median(toPlot$percPerformances)

#plotting
dataset = toPlot;
xIndex = 1;
yIndex = 2;
xLabel = 'Performance ratio';
yLabel = 'Log 10 compression rate';
yLabels <- c(5, 10, 50, 100, 500, 
             1000, 2500, 5000, 10000, 
             25000, 50000, 100000, 
             250000, 500000)
xLine = 1;
colorPalette <- c("darkblue", "#E31A1C", "green4", "#6A3D9A", 
                  "#FF7F00", "gold1", "skyblue2", "#FB9A99", 
                  "palegreen2", "#CAB2D6", "#FDBF6F", "gray70", 
                  "khaki2", "maroon","orchid1","deeppink1");

# names of the elements to plot
xName <- names(dataset)[xIndex];
yName <- names(dataset)[yIndex];

#main plot
p <- ggplot(dataset, aes_string(x = xName, y = yName)) + 
  geom_point(color = 'darkblue', alpha = 0.5) + 
  theme_bw() + 
  theme(legend.position = "none") +
  scale_x_continuous(name = xLabel, 
                     #limits = xLimits, 
                     breaks = seq(from = 0, by = 0.5, to = 5)) +
  scale_y_continuous(name = yLabel, 
                     breaks = log10(yLabels), 
                     labels = format(yLabels))

#line at 1
p <- p + geom_vline(xintercept = xLine, 
                    size = 0.75, color = 'darkgrey', 
                    linetype="dashed")

#line at median
p <- p + geom_vline(xintercept = medianValue, 
                    size = 0.75, color = "#E31A1C")

#x-axis plot
pX <- ggplot(toPlot, aes_string(x = xName)) + 
  geom_density(colour = "darkblue", fill = 'darkblue') + 
  scale_y_continuous(breaks = c(0,2,4,6), 
                     labels = rep(250000,4)) +
  theme_minimal() + 
  theme(legend.position = "none", 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.text.y = element_text(color="white")) +
  ylab('')
  
#y-axis plot
pY <- ggplot(toPlot, aes_string(x = yName)) + 
  geom_density(colour = "darkblue", fill = 'darkblue') + 
  coord_flip() + 
  theme_minimal() + 
  theme(legend.position = "none", 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        axis.title.y =element_blank(),
        axis.text.y =element_blank(),
        axis.text.x = element_text(color="white")) +
  ylab('')

#empty plot
emptyPlot <- ggplot(data.frame()) + 
  geom_blank() + 
  theme(panel.background = element_blank(), 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank());

png(filename = 'Panel_a.png', 
    width = 2100, height = 2100, res = 300)
p <- grid.arrange(arrangeGrob(pX, emptyPlot, p, pY, nrow=2, 
                              widths=unit.c(unit(0.8, "npc"), unit(0.2, "npc")),
                              heights=unit.c(unit(0.2, "npc"), unit(0.8, "npc"))))
dev.off()
