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

#restricting only to forced feature selection
JADBIO_results <- JADBIO_results[JADBIO_results$setting == '5_FS', ]

# keeping only elements with > 1 signature
JADBIO_results <- JADBIO_results[JADBIO_results$numSigns > 1, ]

#sample size vs. signature Coefficient of Variation (CV)
toPlot <- data.frame(sampleSize = log2(JADBIO_results$sampleSizeTrain), 
                     signCV = JADBIO_results$signCV);

# graphic info
xName <- names(toPlot)[1]
yName <- names(toPlot)[2]
xLabel <- 'Training sample size'
yLabel <- 'Signatures\' coefficient of variation (CoV) for holdout AUC'
xBreaks <- c(2^min(toPlot$sampleSize), 2^(5:9))

#main plot
p <- ggplot(toPlot, aes_string(x = xName, y = yName)) + 
  geom_point(color = 'darkblue', alpha = 0.5) + 
  theme_bw() + 
  theme(legend.position = "none", 
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()) +
  scale_x_continuous(name = xLabel, 
                     breaks = log2(xBreaks),
                     labels = xBreaks) +
  scale_y_continuous(name = yLabel,
                     limits = c(-0.002, 0.7),
                     breaks = seq(from = 0.0, to = 0.7, by = 0.1))

#lines
p <- p + geom_smooth(color = "#E31A1C",
                     se = TRUE, 
                     method = 'loess')

#x-axis plot
pX <- ggplot(toPlot, aes_string(x = xName)) + 
  geom_density(colour = "darkblue", fill = 'darkblue') + 
  theme_minimal() + 
  theme(legend.position = "none", 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        axis.title.x = element_blank(),
        axis.text.x = element_blank(),
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
        axis.title.y = element_blank(),
        axis.text.y = element_blank(),
        axis.text.x = element_text(color="white")) +
  ylab('')

#empty plot
emptyPlot <- ggplot(data.frame()) + 
  geom_blank() + 
  theme(panel.background = element_blank(), 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank());

# plotting
png(filename = 'Panel_b.png', 
    width = 2100, height = 2100, res = 300)
p <- grid.arrange(arrangeGrob(pX, emptyPlot, p, pY, nrow=2, 
                              widths=unit.c(unit(0.8, "npc"), unit(0.2, "npc")),
                              heights=unit.c(unit(0.2, "npc"), unit(0.8, "npc"))))
dev.off()
