library(reticulate)
library(lubridate)
library(tidyverse)
library(sazedR)
library(SimilarityMeasures)

use_python("/usr/local/bin/python3")
np <-import("numpy")

flights <- c()
filename <- c()
for (p in Sys.glob('data/652/*.npz', dirmark = FALSE)[1:2]) {
  flights <- append(flights, np$load(p))
  filename <- append(filename, basename(p))
}

add_timestamp <- function(file_name, rate, series) {
  milliseconds_rate <- 1000/rate
  
  tail_number <- substr(file_name, 1,3)
  year <- substr(file_name, 4,7)
  month <- substr(file_name, 8,9)
  day <- substr(file_name, 10,11)
  hour <- substr(file_name, 12,13)
  minute <- substr(file_name, 14,15)
  
  start_time <- mdy_hm(paste(month, "/",day,"/",year, " ", hour,":",minute, sep=""))
  timestamp <- start_time + milliseconds(sapply(1:nrow(series), function(x) x*milliseconds_rate))
  
  tibble(timestamp = timestamp, data = series)
}

rate <- catalog[catalog$X1 == 'ALT',]$rate
flight1_alt <- add_timestamp(filename[[1]], rate, flights[[1]]$f$ALT)
flight2_alt <- add_timestamp(filename[[2]], rate, flights[[2]]$f$ALT)

rate <- catalog[catalog$X1 == 'OIP.1',]$rate
flight1_oip1 <- add_timestamp(filename[[1]], rate, flights[[1]]$f$OIP_1)
flight2_oip1 <- add_timestamp(filename[[2]], rate, flights[[2]]$f$OIP_1)



ggplot() +
  geom_point(data = flight1_oip1, aes(x = timestamp, y = data, group = 1), fill = NA, color = "red") +
  geom_point(data = flight2_oip1, aes(x = timestamp, y = data, group = 1), fill = NA, color = "blue")
  #geom_polygon(data = usa, aes(x=long, y = lat, group = group), fill = NA, color = "blue")



ggplot(economics, aes(x=timestamp)) + 
  geom_line(aes(y = psavert), color = "darkred") + 
  geom_line(aes(y = uempmed), color="steelblue", linetype="twodash")

LCSS(matrix(flight1_oip1$data), matrix(flight2_oip1$data))
