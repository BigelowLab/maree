
#' Convert longitude and latitude to decimal equivalents
#'
#' @export
#' @param x character, vector of one or two elements in the form of
#'   "43.6233° N, 70.2067° W" or ["43.6233° N", "70.2067° W"]
#' @param sep character or NA, if character the input is split
#'    if NA we assume that a two element vector is provided
#' @return a two element numeric of [lat, lon]
latlon_as_decimal <- function(x,
                              sep = c(",", NA)[1]){

  # x  = c("43.6233° N", " 70.2067° W")
  as_decimal <- function(x ){
    n <- nchar(x)
    y <- as.numeric(substring(x, 1, n - 3))
    sw <- Reduce(`|`, lapply("[SW]", grepl, x))
    y[sw] <- y[sw] * -1
    y
  }
  if (!is.na(sep[1])) x <- strsplit(x, sep)[[1]]
  if (length(x) != 2) stop("input must be 2 elements or split into 2 elements")
  as_decimal(x)
}
#' Retrieve an online listing of stations
#'
#' @export
#' @param uri character, url of the online locations listing
#' @param decimal logical, if TRUE convert Latitude and Longtitude to decimal
#' @param pattern character, a pattern to match in station name - possibly a
#'        regular expression or a fixed pattern. Passed to \code{base::grepl()}
#' @param ... further arguments for \code{base::grepl()} such as \code{fixed}
#' @return table of site locations
fetch_locations <- function(uri = "https://flaterco.com/xtide/locations.html",
                            decimal = TRUE,
                            pattern = NA, ...){
  x <- try(xml2::read_html(uri[1]))
  if (!inherits(x, 'xml_document')){
    stop("unable to read:", uri[1])
  }
  x <- x %>%
    rvest::html_table() %>%
    magrittr::extract2(1) %>%
    dplyr::as_tibble()

  if (!is.na(pattern)){
    ix <- grepl(pattern, x$Name, ...)
    x <- x %>%
      dplyr::filter(ix)
  }

  if (decimal){

    #as_decimal <- function(x = c("27.6970° N", "82.6325\\° W")){
    #  as.numeric(gsub("\\° [NSEW]","",  x))
    #}
    as_decimal <- function(x){
      n <- nchar(x)
      as.numeric(substring(x, 1, n - 3))
    }
    N <- as.numeric(grepl("N", x$Latitude, fixed = TRUE))
    N[N <= 0] <- -1
    W <- as.numeric(grepl("W", x$Longitude, fixed = TRUE))
    W[W > 0] <- -1
    x <- x %>%
      dplyr::mutate(Latitude = as_decimal(.data$Latitude) * N,
                    Longitude = as_decimal(.data$Longitude) * W)
  }
  x
}



