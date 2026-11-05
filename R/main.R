#' Retrieve data frame of all datasets in the ECB Statistical Data Warehouse
#'
#' @param ... Arguments passed to GET (e.g. timeout(10) to add maximum request time)
#'
#' @return A dataframe, or \code{NULL} (invisibly) with an informative
#'   message if the ECB API cannot be reached or returns an error.
#' @export
#'
#' @examples
#' \donttest{
#' df <- get_dataflows()
#' head(df)
#' }
get_dataflows <- function(...) {

  query_url <- "https://data-api.ecb.europa.eu/service/dataflow"

  req <- make_request(query_url, "metadata", ...)
  if (is.null(req)) return(invisible(NULL))

  res <- parse_xml(req)
  if (is.null(res)) return(invisible(NULL))

  ecb_ns <- xml2::xml_ns(res) # xml namespace

  data_flows_nodes <- xml2::xml_find_all(res, "//str:Dataflow", ecb_ns)
  name_nodes <- xml2::xml_find_all(xml2::xml_children(data_flows_nodes),
                                   "//com:Name", ecb_ns)

  flow_ref <- xml2::xml_attr(data_flows_nodes, "id")
  title <- xml2::xml_text(name_nodes)

  df <- data.frame(flow_ref, title, stringsAsFactors = FALSE)
  structure(df, class = c("tbl_df", "tbl", "data.frame"))
}

#' Retrieve data from the ECB Statistical Data Warehouse API
#'
#' @param key A character string identifying the series to be retrieved
#' @param filter A named list with additional filters (see \code{details})
#' @param ... Arguments passed to GET (e.g. timeout(10) to add maximum request time)
#'
#' @details
#' The \code{filter} option of \code{get_data()} takes a named list of key-value pairs.
#' If left blank, it returns all data for the current version.
#'
#' Available filter parameters:
#'
#' \itemize{
#' \item \code{startPeriod} & \code{endPeriod}
#'  \itemize{
#'    \item \code{YYYY} for annual data (e.g.: 2013)
#'    \item \code{YYYY-S[1-2]} for semi-annual data (e.g.: 2013-S1)
#'    \item \code{YYYY-Q[1-4]} for quarterly data (e.g.: 2013-Q1)
#'    \item \code{YYYY-MM} for monthly data (e.g.: 2013-01)
#'    \item \code{YYYY-W[01-53]} for weekly data (e.g.: 2013-W01)
#'    \item \code{YYYY-MM-DD} for daily data (e.g.: 2013-01-01)
#'    }
#' \item \code{updatedAfter}
#'  \itemize{
#'    \item A timestamp to retrieve the latest version of changed values in the database since a certain point in time
#'    \item Example: \code{filter = list(updatedAfter = 2009-05-15T14:15:00+01:00)}
#'    }
#' \item \code{firstNObservations} & \code{lastNObservations}
#'  \itemize{
#'    \item Example: \code{filter = list(firstNObservations = 12)} retrieves the first 12 observations of all specified series
#'    }
#' \item \code{detail}
#'  \itemize{
#'    \item Possible options: \code{full/dataonly/serieskeysonly/nodata}
#'    \item \code{dataonly} is the default
#'    \item Use \code{serieskeysonly} or \code{nodata} to list series that match a certain query, without returning the actual data
#'    \item An alternative to using \code{serieskeys/nodata} is the convenience function \code{get_dimensions()}, which returns a list of dataframes with dimensions and explanations (see extended example below).
#'    \item \code{full} returns both the series values and all metadata. This entails retrieving much more data than with the `dataonly` option.
#'    }
#' \item \code{includeHistory} (not currently implemented)
#'  \itemize{
#'    \item \code{false} (default) returns only version currently in production
#'    \item \code{true} returns version currently in production, as well as all previous versions
#'    }
#' }
#' See the \href{https://data.ecb.europa.eu/help/api/overview}{ECB Data Portal API}
#' for more details.
#'
#' @return A data frame, or \code{NULL} (invisibly) with an informative
#'   message if the ECB API cannot be reached or returns an error.
#' @export
#'
#' @examples
#' \donttest{
#' # Get monthly data on annualized euro area headline HICP
#' hicp <- get_data("ICP.M.U2.N.000000.4.ANR")
#' head(hicp)
#' }
get_data <- function(key, filter = NULL, ...) {

  if(!"detail" %in% names(filter)) {
    filter <- c(filter, "detail" = "dataonly")
  }

  if(!filter[["detail"]] %in% c("full", "dataonly")) {
    return(get_dimensions(key, ...))
  }

  query_url <- create_query_url(key, filter = filter)

  req <- make_request(query_url, "data", ...)
  if (is.null(req)) return(invisible(NULL))

  tmp <- tempfile()
  on.exit(unlink(tmp), add = TRUE)

  df <- tryCatch({
    writeLines(httr::content(req, "text", encoding = "utf-8"), tmp)
    as.data.frame(rsdmx::readSDMX(tmp, FALSE))
  }, error = function(e) {
    message("Could not parse the response from the ECB API ",
            "(the data format may have changed):\n", conditionMessage(e))
    NULL
  })
  if (is.null(df)) return(invisible(NULL))

  df <- structure(df,
                  class = c("tbl_df", "tbl", "data.frame"),
                  names = tolower(names(df)))
  df
}

#' Retrieve dimensions of series in the ECB's SDW
#'
#' @param key A character string identifying the series to be retrieved
#' @param ... Arguments passed to GET (e.g. timeout(10) to add maximum request time)
#'
#' @return A list of data frames, one for each series retrieved, or
#'   \code{NULL} (invisibly) with an informative message if the ECB API cannot
#'   be reached or returns an error.
#' @export
#'
#' @examples
#' \donttest{
#' hicp_dims <- get_dimensions("ICP.M.U2.N.000000.4.ANR")
#' hicp_dims[[1]]
#' }
get_dimensions <- function(key, ...) {

  query_url <- create_query_url(key, filter = list("detail" = "nodata"))

  # Used in creating names (series_names) below
  flow_ref <- regmatches(key, regexpr("^[[:alnum:]]+", key))

  req <- make_request(query_url, "metadata", ...)
  if (is.null(req)) return(invisible(NULL))

  skeys <- parse_xml(req)
  if (is.null(skeys)) return(invisible(NULL))

  skeys_ns <- xml2::xml_ns(skeys) # xml namespace

  series <- xml2::xml_find_all(skeys, "//generic:Series", skeys_ns)

  series_list <- lapply(series, xml2::xml_children)

  # Concatenate dimensions to recreate series code
  series_names <- vapply(series_list, function(x) {

      attrs <- xml2::xml_attr(xml2::xml_children(x[1]), "value")
      name <- paste0(attrs, collapse = ".")
      paste(flow_ref, name, sep = ".")

    }, character(1))

  # Return list of dataframes, one for each series, with dimension-value pairs
  df_dim <- lapply(series_list, function(nodeset) {

    data.frame(dim = xml2::xml_attr(xml2::xml_children(nodeset), "id"),
               value = xml2::xml_attr(xml2::xml_children(nodeset), "value"),
               stringsAsFactors = FALSE)
  })

  names(df_dim) <- series_names
  df_dim
}

#' Get full, human-readable description of a series
#'
#' @param key A character string identifying the series to be retrieved
#' @param ... Arguments passed to GET (e.g. timeout(10) to add maximum request time)
#'
#' @return A character vector, or \code{NULL} (invisibly) with an informative
#'   message if the ECB API cannot be reached or returns an error.
#' @export
#'
#' @examples
#' \donttest{
#' get_description("ICP.M.DE.N.000000+XEF000.4.ANR")
#' }
get_description <- function(key, ...) {
  dims <- get_dimensions(key, ...)
  if (is.null(dims)) return(invisible(NULL))
  vapply(dims, function(x) {
    title <- x$value[x$dim == "TITLE_COMPL"]
    if (length(title) == 0) NA_character_ else title[1]
  }, character(1))
}

#' Format date variable retrieved from the SDW into a proper date variable
#'
#' @param x A vector of dates
#'
#' @return A date-formatted vector
#' @export
#'
#' @examples
#' convert_dates(c("2023", "2024"))
#' convert_dates(c("2024-01", "2024-02"))
#' convert_dates(c("2024-01-15", "2024-01-16"))
#' if (requireNamespace("zoo", quietly = TRUE)) {
#'   convert_dates(c("2024-Q1", "2024-Q2"))
#' }
#'
#' \donttest{
#' hicp <- get_data("ICP.M.U2.N.000000.4.ANR")
#' if (!is.null(hicp)) {
#'   hicp$obstime <- convert_dates(hicp$obstime)
#'   str(hicp)
#' }
#' }
convert_dates <- function(x) {

  # Annual
  if(grepl("^[0-9]{4}$", x[1])) {
    return(as.Date(paste0(x, "-01-01"), "%Y-%m-%d"))
  }

  # Monthly
  if(grepl("^[0-9]{4}-[0-9]{2}$", x[1])) {
    return(as.Date(paste0(x, "-01"), "%Y-%m-%d"))
  }

  # Monthly
  if(grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", x[1])) {
    return(as.Date(x, "%Y-%m-%d"))
  }

  # Quarterly
  if(grepl("^[0-9]{4}-Q[1-4]{1}$", x[1])) {
    stopifnot(requireNamespace("zoo", quietly = TRUE))
    x <- sub("Q", "", x)
    # frac = 1 for end-of-quarter dates
    return(zoo::as.Date(zoo::as.yearqtr(x), frac = 1))
  }
  warning("Could not convert dates - format unknown.")
  x
}

create_query_url <- function(key, filter = NULL) {

  url <- "https://data-api.ecb.europa.eu/service/data"

  # Get flow reference (= dataset abbreviation, e.g. ICP or BOP)
  flow_ref <- regmatches(key, regexpr("^[[:alnum:]]+", key))
  key_q <- regmatches(key, regexpr("^[[:alnum:]]+\\.", key),
                      invert = TRUE)[[1]][2]

  if(length(filter) > 0 &&
     (is.null(names(filter)) || any(is.na(names(filter)) | names(filter) == ""))) {
    stop("All filter parameters must be named!")
  }

  if("updatedAfter" %in% names(filter)) {
    filter$updatedAfter <- curl::curl_escape(filter$updatedAfter)
  }

  # Create parameter part of query string
  names <- curl::curl_escape(names(filter))
  values <- curl::curl_escape(as.character(filter))
  query <- paste0(names, "=", values, collapse = "&")
  query <- paste0("?", query)

  query_url <- paste(url, flow_ref, key_q, sep = "/")
  query_url <- paste0(query_url, query)
  query_url
}

# Perform a GET request against the ECB API.
#
# Never throws on network or HTTP problems: per CRAN policy, failures are
# reported with an informative message and NULL is returned, so callers can
# fail gracefully.
make_request <- function(query_url, header_type, ...) {

  accept_headers <-
    c("metadata" = "application/vnd.sdmx.genericdata+xml;version=2.1",
      "data" = "application/vnd.sdmx.structurespecificdata+xml;version=2.1")

  if (!curl::has_internet()) {
    message("No internet connection. Could not retrieve data from the ECB API.")
    return(invisible(NULL))
  }

  req <- tryCatch(
    httr::GET(query_url,
              httr::timeout(getOption("ecb.timeout", 60)),
              httr::add_headers(
                "Accept" = accept_headers[[header_type]],
                "Accept-Encoding" = "gzip, deflate"),
              ...),
    error = function(e) {
      message("Could not connect to the ECB API (", query_url, "):\n",
              conditionMessage(e))
      NULL
    }
  )

  if (is.null(req) || !check_status(req)) return(invisible(NULL))
  req
}

# Returns TRUE if the request succeeded; otherwise emits an informative
# message and returns FALSE.
check_status <- function(req) {
  if (httr::status_code(req) < 400) return(TRUE)

  body <- tryCatch(httr::content(req, "text", encoding = "utf-8"),
                   error = function(e) "")
  if (is.na(body)) body <- ""
  body <- substr(trimws(body), 1, 500)

  message("The ECB API request failed with HTTP status ",
          httr::status_code(req), " (",
          httr::http_status(req)$reason, ").",
          if (nzchar(body)) paste0("\n", body) else "",
          "\nThe series key or filter may be invalid, or the service may ",
          "be temporarily unavailable.")
  FALSE
}

# Parse an XML response, returning NULL with a message on failure.
parse_xml <- function(req) {
  tryCatch(
    xml2::read_xml(httr::content(req, "text", encoding = "utf-8")),
    error = function(e) {
      message("Could not parse the response from the ECB API ",
              "(the data format may have changed):\n", conditionMessage(e))
      NULL
    }
  )
}
