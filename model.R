library(reticulate)
library(lubridate)
library(tidyverse)
library(dplyr)
library(padr)
library(rdist)

library(SimilarityMeasures)  # ts similarity

# add timestamp function
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


# upse python to load npz files
use_python("/usr/local/bin/python3")
np <-import("numpy")

#select flights and feature
set.seed(42)
flight_sample_size <- 10
data_sample_rate = '1 min'
flights <- list()
for (p in sample(Sys.glob('data/652/*.npz'), 10)) {
  flight <- np$load(p)
  filename <- basename(p)

  rate <- catalog[catalog$X1 == 'OIP.1',]$rate
  flight <- add_timestamp(filename, rate, flight$f$OIP_1) %>%
    thicken(data_sample_rate, colname = 'group') %>%
    group_by(group) %>%
    summarize(data = mean(data), .groups='keep')

  flights <- append(flights, list(flight))
}
remove(p, flight, filename)


# compute pairwise distance matrix
distances = matrix(nrow = length(flights), ncol = length(flights))
grid_indicies <- expand.grid(a=1:length(flights), b=1:length(flights))
for (i in 1:nrow(grid_indicies)) {
  ai <- grid_indicies[i, 'a']
  bi <- grid_indicies[i, 'b']

  if (ai <= bi) next

  a <- flights[[ai]]
  b <- flights[[bi]]

  distance <- Frechet(matrix(c(1:nrow(a), a$data), nrow(a)),
                      matrix(c(1:nrow(b), b$data), nrow(b)))

  distances[ai, bi] <- distance
}
remove(a, b, i, ai, bi, distance)
distances
