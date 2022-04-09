#' Provides a convenient look up table to decifer command line arguments
#'
#' @export
#' @return tibble of common argument descriptions
#' \itemize{
#' \item{-b "YYYY-MM-DD HH:MM", Specify the begin (start) time for predictions.}
#' \item{-e "YYYY-MM-DD HH:MM", Specify the end (stop) time for predictions.}
#' \item{-f "t", Specify output format as a table as CSV}
#' \item{-m "r", Specify mode to be raw}
#' \item{-o "/path/to/output", Redirect output to the specified file (appends).}
#' \item{-s "HH:MM", Specify the step interval, in hours and minutes, for raw mode predictions.}
#' \item{-v "", Print version string and exit.}
#' }
argument_lut <- function(){
  b <- Sys.time()
  e <- b + 4*(24 * 3600)
  list(
    "-b" = format(b, "%Y-%m-%d %H:%M"),
    "-e" = format(e, "%Y-%m-%d %H:%M"),
    "-f" =                         "t",
    "-l" =                  "Portland",
    "-m" =                         "r",
    "-o" =                  tempfile(),
    "-s" =                     "01:00",
    "-v" =                          "" )
}



#' Retrieve the raw tide values for a specified location
#'
#' @export
#' @param location the name of the location
#' @param time 2 element vector of POSIXct time to start and stop start <= time < stop.
#'        Defaults to [now, now + 4 days]
#' @param step character, time step as 'HH:MM'. Defaults tp "01:00"
#' @param ofile character, the output filename. Defaults to \code{tempfile()}
#' @param compress logical, if TRUE compress the file. Defaults to TRUE.
#' @param app the name of the application. Defaults to \code{Sys.which("/opt/bin/tide")}
#' @return list with
#' \itemize{
#'    \item{location, the name of the location}
#'    \item{file, the name of the output file}
#'    \item{data, tibble of data, possible with 0 rows}
#' }
get_raw_mode <- function(location = 'Portland',
                         time = c(Sys.time(), Sys.time() + 4*(24 * 3600)),
                         step = '01:00',
                         ofile = tempfile(),
                         compress = FALSE,
                         app = Sys.which("/opt/bin/tide")){

  if (FALSE){
    location = 'Portland'
    time = c(Sys.time(), Sys.time() + 4*(24 * 3600))
    step = '01:00'
    ofile = tempfile()
    compress = FALSE
    app = Sys.which("/opt/bin/tide")
  }
  args <- c(
    "-l", shQuote(location[1]),
    "-b", shQuote(format(time[1], "%Y-%m-%d %H:%M")),
    "-e", shQuote(format(time[2], "%Y-%m-%d %H:%M")),
    "-s", step[1],
    "-f", "t",
    "-m", "r",
    "-o", ofile[1])
  ok <- system2(app[1], args)

  if (ok == 0){
    if (compress) {
      k <- suppressMessages(system(paste("gzip -f", ofile[1])))
      if (k == 0){
        ofile <- paste0(ofile[1], ".gz")
      } else {
        stop("unable to compress file:", ofile[1])
      }
    }
    x <- c(location = location,
           read_raw_mode(ofile[1]))
  } else {
    warning("tide application had non-zero output status:", ok)
    x <- list(location = location[1],
              file = ofile,
              data = dplyr::tibble(datetime = Sys.time(), height=0.0) %>%
                dplyr::slice(-1))
  }
  x
}


#' Retrieve the tide events for a specified location
#'
#' @export
#' @param location the name of the location
#' @param time 2 element vector of POSIXct time to start and stop start <= time < stop.
#'        Defaults to [now, now + 4 days]
#' @param ofile character, the output filename. Defaults to \code{tempfile()}
#' @param compress logical, if TRUE compress the file. Defaults to TRUE.
#' @param app the name of the application. Defaults to \code{Sys.which("/opt/bin/tide")}
#' @return list with
#' \itemize{
#'    \item{location, the name of the location}
#'    \item{file, the name of the output file}
#'    \item{moon, tibble of moon rise/set, possible with 0 rows}
#'    \item{sun, tibble of sun rise/set, possibly with 0 rows}
#'    \item{tide, tibble of tide height and stage, possibly with 0 rows}
#' }
get_plain_mode <- function(location = 'Portland',
                         time = c(Sys.time(), Sys.time() + 4*(24 * 3600)),
                         ofile = tempfile(),
                         compress = FALSE,
                         app = Sys.which("/opt/bin/tide")){

  if (FALSE){
    location = 'Portland'
    time = c(Sys.time(), Sys.time() + 4*(24 * 3600))
    ofile = tempfile()
    compress = FALSE
    app = Sys.which("/opt/bin/tide")
  }
  origin <- as.POSIXct("1970-01-01 00:00Z")
  args <- c(
    "-l", location[1],
    "-b", shQuote(format(time[1], "%Y-%m-%d %H:%M")),
    "-e", shQuote(format(time[2], "%Y-%m-%d %H:%M")),
    "-f", "t",
    "-m", "p",
    "-o", ofile[1])
  ok <- system2(app[1], args)

  if (ok == 0){
    if (compress) {
      k <- system(paste("gzip -f", ofile[1]))
      if (k == 0){
        ofile <- paste0(ofile[1], ".gz")
      } else {
        stop("unable to compress file:", ofile[1])
      }
    }

    x <- read_plain_mode(ofile[1])
  } else {
    warning("tide application had non-zero output status:", ok)
    x <- list("location" = location[1],
              file = ofile,
              moon = dplyr::tibble(datetime = Sys.time(), event = "foo") %>%
                dplyr::slice(-1),
              sun = dplyr::tibble(datetime = Sys.time(), event = "foo") %>%
                dplyr::slice(-1),
              tide = dplyr::tibble(datetime = Sys.time(), height = 0.0, stage = "foo") %>%
                dplyr::slice(-1))
  }
  x
}

