library(shiny)
library(ggvis)
library(tidyr)
library(tidyverse)
library(tourr)
library(jsonlite)
library(scagnostics)

#d <- read_csv("numbat.csv") #%>%
  #filter(group == "A")
#d <- data.frame( x1=rnorm(100), x2=rnorm(100), x3=c(rnorm(50, -2), rnorm(50, 2)), x4=c(rnorm(50, -2), rnorm(50, 2)), x5=rnorm(100), group=c(rep("A", 50), rep("B", 50)), stringsAsFactors = FALSE)
#dc <- subset(d[sample(1:nrow(d),500),])
# d <- read_csv("geozoo.csv")
# #d <- read_csv("tigs_music_seismic.csv")
# dc <- d
# mat <- rescale(as.matrix(dc[1:5]))
d <- read_csv("/Users/ulaa0001/bAnomalies/dataAndSampled.csv")
nums <- sapply(d, is.numeric)
groups <- sapply(d, is.character)
#browser()
#cl <- dc$group
