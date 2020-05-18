#### Script for producing Supplementary Figure 1 ####

#### Setup ####

# loading libraries and functions
rm(list = ls())
library(ggplot2)
library(grid)
source('../ancillaryFunction.R')

# results folder
resultsFolder <- '../'

#### Plotting ####

# load data
load(file.path(resultsFolder, 'JADBIO_results.RData'))

# restricting only to forced feature selection
JADBIO_results <- JADBIO_results[JADBIO_results$setting == '5_FS', ]

#sample size vs. num signatures
toPlot <- data.frame(sampleSize = log2(JADBIO_results$sampleSizeTrain), 
                     numSign = log2(JADBIO_results$numSigns));

# graph info
xName <- names(toPlot)[1]
yName <- names(toPlot)[2]
xLabel <- 'Training sample size'
yLabel <- 'Number of equivalent signatures'
xBreaks <- c(2^min(toPlot$sampleSize), 
             2^(5:8), 
             2^max(toPlot$sampleSize))
yBreaks <- c(2^min(toPlot$numSign), 
             2^(1:16), 
             2^max(toPlot$numSign))

#main plot
p <- ggplot(toPlot, aes_string(x = xName, y = yName)) + 
  geom_point(color = 'darkblue', alpha = 0.5) + 
  theme_bw() + 
  theme(legend.position = "none", 
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
  ) +
  scale_x_continuous(name = xLabel, 
                     limits = log2(c(min(xBreaks), max(xBreaks))),
                     breaks = log2(xBreaks),
                     labels = xBreaks) +
  scale_y_continuous(name = yLabel,
                     limits = c(-0.002, 17.5),
                     breaks = log2(yBreaks),
                     labels = yBreaks
  )

# lines
p <- p + geom_smooth(color = "#E31A1C",
                     se = TRUE,
                     method = 'loess')

# x-axis plot
pX <- ggplot(toPlot, aes_string(x = xName)) + 
  geom_density(colour = "darkblue", fill = 'darkblue') + 
  scale_y_continuous(breaks = c(0,2,4,6), 
                      labels = rep(250000,4)) +
  theme_minimal() + 
  theme(legend.position = "none", 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.text.y = element_text(color="white")) +
  ylab('')

# y-axis plot
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

png(filename = 'S_Figure_1.png', 
    width = 2100, height = 2100, res = 300)
p <- grid.arrange(arrangeGrob(pX, emptyPlot, p, pY, nrow=2, 
                              widths=unit.c(unit(0.8, "npc"), unit(0.2, "npc")),
                              heights=unit.c(unit(0.2, "npc"), unit(0.8, "npc"))))
dev.off()
