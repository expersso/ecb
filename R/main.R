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

#   response <- httr::GET(url, httr::add_headers(
#     "Accept" = "application/vnd.sdmx.structure+xml;version=2.1"))
#
#   content <- httr::content(response, "raw")

  page <- xml2::read_xml(url, verbose = TRUE)
  ecb_ns <- xml2::xml_ns(page) # xml namespace

  data_flows_nodes <- xml2::xml_find_all(page, "//str:Dataflow", ecb_ns)
  name_nodes <- xml2::xml_find_all(xml2::xml_children(data_flows_nodes),
                                   "//com:Name", ecb_ns)

  flow_ref <- xml2::xml_attr(data_flows_nodes, "id")
  title <- xml2::xml_text(name_nodes)

  df <- data.frame(flow_ref, title, stringsAsFactors = FALSE)
  structure(df, class = c("tbl_df", "tbl", "data.frame"))
}

create_query_url <- function(key, filter = NULL) {

  url <- "https://sdw-wsrest.ecb.europa.eu/service/data"

  # Get flow reference (= dataset abbreviation, e.g. ICP or BOP)
  flow_ref <- regmatches(key, regexpr("^[[:alnum:]]+", key))
  key_q <- regmatches(key, regexpr("^[[:alnum:]]+\\.", key),
                      invert = TRUE)[[1]][2]

  if(any(names(filter) == "")) {
    stop("All filter parameters must be named!")
  }

  if(!is.null(filter$updatedAfter)) {
    filter$updatedAfter <- curl::curl_escape(filter$updatedAfter)
  }

  # Create parameter part of query string
  names <- curl::curl_escape(names(filter))
  values <- curl::curl_escape(as.character(filter))
  query <- paste0(names, "=", values, collapse = "&")
  query <- paste0("?", query)

  query_url <- paste(url, flow_ref, key_q, query, sep = "/")
  query_url
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

  if(!"detail" %in% names(filter)) {
    filter <- c(filter, "detail" = "dataonly")
  }

  if(!filter[["detail"]] %in% c("full", "dataonly")) {
    return(get_dimensions(key))
  }

  query_url <- create_query_url(key, filter = filter)

  result <- rsdmx::readSDMX(query_url)

  df <- as.data.frame(result)
  df <- structure(df,
                  class = c("tbl_df", "tbl", "data.frame"),
                  names = tolower(names(df)))

  # Parse annual obstime
  if(grepl("^[0-9]{4}$", df$obstime[1])) {
    df$obstime <- paste0(df$obstime, "-01-01")
    df$obstime <- as.Date(df$obstime, "%Y-%m-%d")
  }

  # Parse monthly obstime
  if(grepl("^[0-9]{4}-[0-9]{2}$", df$obstime[1])) {
    df$obstime <- paste0(df$obstime, "-01")
    df$obstime <- as.Date(df$obstime, "%Y-%m-%d")
  }

  # Parse daily obstime
  if(grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", df$obstime[1])) {
    df$obstime <- as.Date(df$obstime, "%Y-%m-%d")
  }

  df
}

#' Retrieve dimensions of a series in the ECB's SDW
#'
#' @param key A character string identifying the series to be retrieved
#'
#' @return A list of data frames, one for each series retrieved
#' @export
#'
#' @examples
#' hicp_dims <- get_dimensions("ICP.M.U2.N.000000.4.ANR")
#' hicp_dims[[1]]
get_dimensions <- function(key) {

  query_url <- create_query_url(key, filter = list("detail" = "nodata"))

  # Used in creating names (series_names) below
  flow_ref <- regmatches(key, regexpr("^[[:alnum:]]+", key))

  skeys <- xml2::read_xml(query_url, verbose = TRUE)
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