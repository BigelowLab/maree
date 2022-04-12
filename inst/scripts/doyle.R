suppressPackageStartupMessages({
  library(maree)
  library(dplyr)
})

name <- "Doyle"
locs <- fetch_locations()
loc <- locs |> filter(grepl(name, Name, fixed = TRUE))
# A tibble: 1 × 5
# `Station ID` Name                          Type  Latitude Longitude
# <chr>        <chr>                         <chr>    <dbl>     <dbl>
#   1 8417874      Doyle Point, Casco Bay, Maine Sub       43.8      70.1

# may2018 and one for october 2021

model_dates <- c("2018")