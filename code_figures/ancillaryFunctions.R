
# Functions useful for plotting

# setup
library(ggplot2)
library(grid)
library(gridExtra)

# function returning the legend of a ggplot
g_legend<-function(a.gplot){
  tmp <- ggplot_gtable(ggplot_build(a.gplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  return(legend)
}

# Get density of points in 2 dimensions.
# @param x A numeric vector.
# @param y A numeric vector.
# @param n Create a square n by n grid to compute density.
# @return The density within each square.
get_density <- function(x, y, ...) {
  dens <- MASS::kde2d(x, y, ...)
  ix <- findInterval(x, dens$x)
  iy <- findInterval(y, dens$y)
  ii <- cbind(ix, iy)
  return(dens$z[ii])
}

#function for plotting scatterplots with marginal densities
scatterWithMarginals <- function(dataset, xIndex, yIndex, factorIndex = NULL, 
                                 xLabel = names(dataset)[xIndex], 
                                 yLabel = names(dataset)[yIndex], 
                                 xLimits = NULL,
                                 yLimits = NULL,
                                 factorLabel = switch(is.null(factorIndex) + 2, 
                                                      '', 
                                                      names(dataset)[factorIndex],
                                                      NULL), 
                                 factorElements = NULL,
                                 xLine = NULL,
                                 yLine = NULL,
                                 diagonalLine1 = NULL,
                                 diagonalLine2 = NULL,
                                 loessLine = FALSE, 
                                 loessSE = TRUE,
                                 marginals = TRUE){
  
  #high contrast color palette, from: http://stackoverflow.com/questions/9563711/r-color-palettes-for-many-data-classes
  #colorPalete <- c("dodgerblue2", "#E31A1C", "green4", "#6A3D9A", "#FF7F00", "gold1", "skyblue2", "#FB9A99", "palegreen2", "#CAB2D6", "#FDBF6F", "gray70", "khaki2", "maroon","orchid1","deeppink1");
  colorPalette <- c("darkblue", "#E31A1C", "green4", "#6A3D9A", "#FF7F00", "gold1", "skyblue2", "#FB9A99", "palegreen2", "#CAB2D6", "#FDBF6F", "gray70", "khaki2", "maroon","orchid1","deeppink1");
  
  #names of the elements to plot
  xName <- names(dataset)[xIndex];
  yName <- names(dataset)[yIndex];
  
  #if no factor, they simpler plot
  if(is.null(factorIndex) || dim(dataset)[2] < factorIndex){
    
    #main plot
    p <- ggplot(dataset, aes_string(x = xName, y = yName)) + 
      geom_point(color = 'darkblue', size = 1) + 
      xlab(ifelse(is.null(xLabel), xName, xLabel)) + 
      ylab(ifelse(is.null(yLabel), yName, yLabel)) + 
      theme_bw() + 
      theme(legend.position = "none", 
            panel.grid.major = element_blank(),
            panel.grid.minor = element_blank())
    
    #options
    if(loessLine){
      p <- p + geom_smooth(se = loessSE, method = 'loess', color =' red')
    }
    if(!is.null(diagonalLine1)){
      p <- p + geom_abline(slope = diagonalLine1$slope, size = 1, 
                           intercept = diagonalLine1$intercept, 
                           color = 'red',  linetype="dashed")
    }
    if(!is.null(diagonalLine2)){
      p <- p + geom_abline(slope = diagonalLine2$slope, size = 1, 
                           intercept = diagonalLine2$intercept, 
                           color = 'darkgrey',  linetype="dashed")
    }
    if(!is.null(xLine)){
      p <- p + geom_vline(xintercept = xLine, 
                          size = 1, color = 'darkgrey',
                          linetype="dashed")
    }
    if(!is.null(yLine)){
      p <- p + geom_hline(yintercept = yLine, 
                          size = 1, color = 'darkgrey',
                          linetype="dashed")
    }
    if(!is.null(xLimits)){
      p <- p + xlim(xLimits);
    }
    if(!is.null(yLimits)){
      p <- p + ylim(yLimits);
    }
    
    #marginals
    if(marginals){
      
      #x-axis plot
      pX <- ggplot(dataset, aes_string(x = xName)) + 
        geom_density(colour = 'white', alpha = 0.5, fill = 'darkblue') + 
        theme_minimal() + 
        theme(legend.position = "none",
              panel.grid.major = element_blank(),
              panel.grid.minor = element_blank(),
              axis.title.x=element_blank(),
              axis.text.x=element_blank()) +
        ylab('')
      if(!is.null(xLimits)){
        pX <- pX + xlim(xLimits);
      }
      
      #y-axis plot
      pY <- ggplot(dataset, aes_string(x = yName)) + 
        geom_density(colour = 'white', alpha = 0.5, fill = 'darkblue') + 
        coord_flip() + 
        theme_minimal() + 
        theme(legend.position = "none", 
              panel.grid.major = element_blank(),
              panel.grid.minor = element_blank(),
              axis.title.y=element_blank(), 
              axis.text.y=element_blank()) +
        ylab('');
      if(!is.null(yLimits)){
        pY <- pY + xlim(yLimits);
      }
      
      #empty plot
      emptyPlot <- ggplot(data.frame()) + 
        geom_blank() + 
        theme(panel.background = element_blank(), 
              panel.grid.major = element_blank(), 
              panel.grid.minor = element_blank());
      
      #final plot
      p <- grid.arrange(arrangeGrob(pX, emptyPlot, p, pY, nrow=2, 
                                    widths=unit.c(unit(0.75, "npc"), unit(0.25, "npc")), 
                                    heights=unit.c(unit(0.25, "npc"), unit(0.75, "npc"))))
      
    }else{
      #this is done automatically in grid.arrange(arrangeGrob())
      plot(p)
    }
  
  }else{
    
    #names of the elements to plot
    factorName <- names(dataset)[factorIndex];
    
    #main plot
    p <- ggplot(dataset, aes_string(x = xName, y = yName, colour = factorName)) + 
      geom_point() + 
      xlab(ifelse(is.null(xLabel), xName, xLabel)) + 
      ylab(ifelse(is.null(yLabel), yName, yLabel)) + 
      theme_bw() + 
      theme(panel.background = element_blank(), 
            panel.grid.major = element_blank(), 
            panel.grid.minor = element_blank())
    if(is.factor(dataset[[factorIndex]])){
      p <- p + scale_color_manual(values = colorPalette)
    }else{
      p <- p + scale_color_continuous(low = "grey", high = "darkblue")
    }

    #options
    if(loessLine){
      p <- p + geom_smooth(se = loessSE, method = 'loess', color =' red')
    }
    if(!is.null(diagonalLine1)){
      p <- p + geom_abline(slope = diagonalLine1$slope, size = 1, 
                           intercept = diagonalLine1$intercept, 
                           color = 'red',  linetype="dashed")
    }
    if(!is.null(diagonalLine2)){
      p <- p + geom_abline(slope = diagonalLine2$slope, size = 1, 
                           intercept = diagonalLine2$intercept, 
                           color = 'red',  linetype="dashed")
    }
    if(!is.null(xLine)){
      p <- p + geom_vline(xintercept = xLine, 
                          size = 1, color = 'red',  
                          linetype="dashed")
    }
    if(!is.null(yLine)){
      p <- p + geom_hline(yintercept = yLine, 
                          size = 1, color = 'red', 
                          linetype="dashed")
    }
    if(!is.null(xLimits)){
      p <- p + xlim(xLimits);
    }
    if(!is.null(yLimits)){
      p <- p + ylim(yLimits);
    }
    
    #marginals
    if(marginals){
      
      #x-axis plot
      if(is.factor(dataset[[factorIndex]])){
        pX <- ggplot(dataset, aes_string(x = xName, group = factorName, fill = factorName)) + 
          geom_density(colour = 'white', alpha = 0.5) + 
          theme_minimal() + 
          theme(legend.position = "none", 
                panel.grid.major = element_blank(), 
                panel.grid.minor = element_blank(),
                axis.title.x=element_blank(),
                axis.text.x=element_blank()) +
          scale_fill_manual(values = colorPalette) +
          ylab('')
      }else{
        pX <- ggplot(dataset, aes_string(x = xName)) + 
          geom_density(fill = 'darkblue', alpha = 0.5, colour = 'white') + 
          theme_minimal() + 
          theme(legend.position = "none", 
                panel.grid.major = element_blank(),
                panel.grid.minor = element_blank(),
                axis.title.x=element_blank(),
                axis.text.x=element_blank()) +
          ylab('')
      }
      if(!is.null(xLimits)){
        pX <- pX + xlim(xLimits);
      }
      
      #y-axis plot
      if(is.factor(dataset[[factorIndex]])){
        pY <- ggplot(dataset, aes_string(x = yName, group = factorName, fill = factorName)) + 
          geom_density(colour = 'white', alpha = 0.5) + 
          coord_flip() + 
          theme_minimal() + 
          theme(legend.position = "none", 
                panel.grid.major = element_blank(), 
                panel.grid.minor = element_blank(),
                axis.title.y = element_blank(),
                axis.text.y = element_blank()) + 
        scale_fill_manual(values = colorPalette) +
          ylab('')
      }else{
        pY <- ggplot(dataset, aes_string(x = yName)) + 
          geom_density(fill = 'darkblue', alpha = 0.5, colour = 'white') + 
          coord_flip() + 
          theme_minimal() + 
          theme(legend.position = "none", 
                panel.grid.major = element_blank(),
                panel.grid.minor = element_blank(),
                axis.title.y = element_blank(),
                axis.text.y = element_blank()) +
          ylab('')
      }
      if(!is.null(yLimits)){
        pY <- pY + xlim(xLimits);
      }
      
      #legend 
      uniqueLegend <- g_legend(p);
      p <- p + theme(legend.position = "none")
      
      #final plot
      p <- grid.arrange(arrangeGrob(pX, uniqueLegend, p, pY, nrow=2, 
                                    widths=unit.c(unit(0.75, "npc"), unit(0.25, "npc")), 
                                    heights=unit.c(unit(0.25, "npc"), unit(0.75, "npc"))))
      
    }
    
  }
  
  #return
  return(p)
  
}

#function for plotting density plots with marginal densities
densityWithMarginals <- function(dataset, xIndex, yIndex,
                                 xLabel = names(dataset)[xIndex], 
                                 yLabel = names(dataset)[yIndex], 
                                 xLimits = NULL,
                                 yLimits = NULL,
                                 xLine = NULL,
                                 yLine = NULL,
                                 diagonalLine1 = NULL,
                                 diagonalLine2 = NULL,
                                 loessLine = FALSE, 
                                 marginals = TRUE){
  
  #names of the elements to plot
  xName <- names(dataset)[xIndex];
  yName <- names(dataset)[yIndex];
  
  #main plot
  p <- ggplot(dataset, aes_string(x = xName, y = yName)) + 
    geom_density_2d() + 
    stat_density_2d(geom = "raster", aes(fill = ..density..), contour = FALSE)+
    scale_fill_continuous(low = "white", high = "darkblue", guide = FALSE) +
    xlab(ifelse(is.null(xLabel), xName, xLabel)) + 
    ylab(ifelse(is.null(yLabel), yName, yLabel)) + 
    theme_bw() + 
    theme(legend.position = "none", 
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank())
  
  #options
  if(loessLine){
    p <- p + geom_smooth(se = loessSE, method = 'loess', color =' red')
  }
  if(!is.null(diagonalLine1)){
    p <- p + geom_abline(slope = diagonalLine1$slope, size = 1, 
                         intercept = diagonalLine1$intercept, 
                         color = 'red',  linetype="dashed")
  }
  if(!is.null(diagonalLine2)){
    p <- p + geom_abline(slope = diagonalLine2$slope, size = 1, 
                         intercept = diagonalLine2$intercept, 
                         color = 'red',  linetype="dashed")
  }
  if(!is.null(xLine)){
    p <- p + geom_vline(xintercept = xLine, 
                                      size = 1, color = 'red',  
                                      linetype="dashed")
  }
  if(!is.null(yLine)){
    p <- p + geom_hline(yintercept = yLine, 
                                      size = 1, color = 'red', 
                                      linetype="dashed")
  }
  if(!is.null(xLimits)){
    p <- p + xlim(xLimits);
  }
  if(!is.null(yLimits)){
    p <- p + ylim(yLimits);
  }
  
  #marginals
  if(marginals){
  
    #x-axis plot
    pX <- ggplot(dataset, aes_string(x = xName)) + 
      geom_density(fill = 'darkblue', alpha = 0.5, colour = 'white') + 
      theme_minimal() + 
      theme(legend.position = "none", 
            panel.grid.major = element_blank(),
            panel.grid.minor = element_blank(),
            axis.title.x=element_blank(),
            axis.text.x=element_blank()) +
      ylab('')

    #y-axis plot
    pY <- ggplot(dataset, aes_string(x = yName)) + 
      stat_density(fill = 'darkblue', alpha = 0.5, colour = 'white') + 
      coord_flip() + 
      theme_minimal() + 
      theme(legend.position = "none", 
            panel.grid.major = element_blank(),
            panel.grid.minor = element_blank(),
            axis.title.y=element_blank(),
            axis.text.y=element_blank()) +
      ylab('')
    
    #empty plot
    emptyPlot <- ggplot(data.frame()) + 
      geom_blank() + 
      theme(panel.background = element_blank(), 
            panel.grid.major = element_blank(), 
            panel.grid.minor = element_blank());
    
    #final plot
    p <- grid.arrange(arrangeGrob(pX, emptyPlot, p, pY, nrow=2, 
                                  widths=unit.c(unit(0.75, "npc"), unit(0.25, "npc")), 
                                  heights=unit.c(unit(0.25, "npc"), unit(0.75, "npc"))))
    
  }else{
    #this is done automatically in grid.arrange(arrangeGrob())
  plot(p)
  }
  
  #return
  return(p)

}
# 
# #test
# dataset <- cars
# dataset$group <- factor(c(rep('a', 25), rep('b',25)))
# xIndex <- 1
# yIndex <- 2
# factorIndex <- 3
# xLine = 10
# yLine = 50
# diagonalLine = list(intercept = 10, slope = 1)
# loessLine = TRUE
# marginals = TRUE
# densityWithMarginals(dataset = dataset, 
#                      xIndex = xIndex, 
#                      yIndex = yIndex, 
#                      xLine = xLine, 
#                      yLine = yLine, 
#                      diagonalLine = diagonalLine, 
#                      #loessLine = loessLine,
#                      loessLine = FALSE,
#                      marginals = marginals);
# 
# scatterWithMarginals(dataset = dataset, 
#                      xIndex = xIndex, 
#                      yIndex = yIndex, 
#                      xLine = xLine, 
#                      yLine = yLine, 
#                      diagonalLine = diagonalLine, 
#                      loessLine = loessLine,
#                      marginals = marginals);
# 
# scatterWithMarginals(dataset = dataset, 
#                      xIndex = xIndex, 
#                      yIndex = yIndex, 
#                      factorIndex = factorIndex,
#                      xLine = xLine, 
#                      yLine = yLine, 
#                      diagonalLine = diagonalLine, 
#                      loessLine = loessLine,
#                      marginals = marginals);
# 
# dataset$group <- runif(50)
# scatterWithMarginals(dataset = dataset, 
#                      xIndex = xIndex, 
#                      yIndex = yIndex, 
#                      factorIndex = factorIndex,
#                      xLine = xLine, 
#                      yLine = yLine, 
#                      diagonalLine = diagonalLine, 
#                      loessLine = loessLine,
#                      marginals = marginals);
