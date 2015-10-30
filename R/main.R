#' Retrieve data frame of all datasets in the ECB Statistical Data Warehouse
#'
#' @return A dataframe
#' @export
#'
#' @examples
#' df <- get_dataflows()
#' head(df)
get_dataflows <- function() {
  url <- "https://sdw-wsrest.ecb.europa.eu/service/dataflow"

  response <- httr::GET(url, httr::add_headers(
    "Accept" = "application/vnd.sdmx.structure+xml;version=2.1"))

  content <- httr::content(response, "raw")

  page <- xml2::read_xml(content, verbose = TRUE)
  ecb_ns <- xml_ns(page)

  data_flows_nodes <- xml2::xml_find_all(page, "//str:Dataflow", ecb_ns)
  name_nodes <- xml_find_all(xml_children(data_flows), "//com:Name", ecb_ns)

  flow_ref <- xml_attr(data_flows_nodes, "id")
  title <- xml_text(name_nodes)
  df <- data.frame(flow_ref, title, stringsAsFactors = FALSE)
  class(df) <- c("tbl_df", "tbl", "data.frame")
  df
}

#' Retrieve data from the ECB Statistical Data Warehouse API
#'
#' @param key A character string identifying the series to be retrieved
#' @param filter A named list with additional filters (see \code{details})
#'
#' @return A data frame
#' @export
#'
#' @examples
#' # Get monthly data on annualized euro area headline HICP
#' hicp <- get_data("ICP.M.U2.N.000000.4.ANR")
#' head(hicp)
get_data <- function(key, filter = NULL) {
  url <- "https://sdw-wsrest.ecb.europa.eu/service/data"

  flow_ref <- regmatches(key, regexpr("^[[:alnum:]]+", key))
  key <- regmatches(key, regexpr("^[[:alnum:]]+\\.", key),
                    invert = TRUE)[[1]][2]

  if(!"detail" %in% names(filter)) {
    filter <- c(filter, "detail" = "dataonly")
  }

  if(any(names(filter) == "")) {
    stop("All filter parameters must be named!")
  }
  names <- curl::curl_escape(names(filter))
  values <- curl::curl_escape(as.character(filter))
  query <- paste0(names, "=", values, collapse = "&")
  query <- paste0("?", query)

  url <- paste(url, flow_ref, key, query, sep = "/")

  df <- as.data.frame(rsdmx::readSDMX(url))
  names(df) <- tolower(names(df))

  # Parse obstime
  if(grepl("^[0-9]{4}$", df$obstime[1])) {
    df$obstime <- as.numeric(df$obstime)
  }
  if(grepl("^[0-9]{4}-[0-9]{2}$", df$obstime[1])) {
    df$obstime <- paste0(df$obstime, "-01")
    df$obstime <- as.Date(df$obstime, "%Y-%m-%d")
  }

  df
}