#' Read raw mode data
#'
#' @export
#' @param filename character or connection
#' @param tz character, the time zone for the location and time requested
#' @return list with
#' \itemize{
#'    \item{file, the name of the output file}
#'    \item{data, tibble of data, possible with 0 rows}
#' }
read_raw_mode <- function(filename, tz = "UTC"){
  origin <- as.POSIXct("1970-01-01 00:00Z", tz = 'UTC')
  d <- suppressMessages(readr::read_table(filename[1],
    col_names = c("datetime", "height"))) %>%
    dplyr::mutate(datetime = as.POSIXct(.data$datetime, origin = origin, tz = tz))
  list(file = filename,
       data = d)
}

#' Read plain mode data
#'
#' @export
#' @param filename character or connection
#' @param tz character, the time zone for the location and time requested
#' @return list with
#' \itemize{
#'    \item{location, the name of the location}
#'    \item{lonlat, numeric two element vector of [lon,lat]}
#'    \item{file, the name of the output file}
#'    \item{status, status code from calling the function - either zero (sucess) or non-zero}
#'    \item{moon, tibble of moon rise/set, possible with 0 rows}
#'    \item{sun, tibble of sun rise/set, possibly with 0 rows}
#'    \item{tide, tibble of tide height and stage, possibly with 0 rows}
#' }
read_plain_mode <- function(filename, tz = "UTC"){

  origin <- as.POSIXct("1970-01-01 00:00Z", tz = "UTC")
  txt <- readLines(filename[1], n = 2)
  location <- txt[[1]]
  latlon <- latlon_as_decimal(txt[[2]])
  colpos <- readr::fwf_positions(start = c(1, 25),
                               end = c(24, NA),
                               col_names = c("datetime", "event"))

  d <- suppressMessages(
      readr::read_fwf(filename[1],
                      skip = 4,
                      col_positions = colpos)) %>%
      dplyr::mutate(datetime = as.POSIXct(.data$datetime, origin = origin,
                                          format = "%Y-%m-%d %I:%M %p",
                                          tz = tz ))

  moon <- d %>%
    dplyr::filter(grepl("Moon", .data$event))
  sun <- d %>%
    dplyr::filter(grepl("Sun", .data$event))
  tide <- d %>%
    dplyr::filter(grepl("Tide", .data$event)) %>%
    dplyr::mutate(event = gsub(" feet  ", ",",.data$event, fixed = TRUE)) %>%
    tidyr::separate(.data$event,
                    into = c("height", "stage"),
                    sep = ",",
                    convert = TRUE) %>%
    dplyr::mutate(stage = trimws(tolower(gsub("Tide", "", .data$stage, fixed = TRUE)), which = "both"))

  list(location = location[1],
       lonlat = rev(latlon),
       file = filename,
       moon = moon,
       sun = sun,
       tide = tide)
}
