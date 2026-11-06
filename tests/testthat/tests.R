# Offline tests -----------------------------------------------------------

test_that("create_query_url builds the expected URL", {
  url <- create_query_url("ICP.M.U2.N.000000.4.ANR",
                          filter = list(lastNObservations = 12))
  expect_equal(
    url,
    paste0("https://data-api.ecb.europa.eu/service/data/ICP/",
           "M.U2.N.000000.4.ANR?lastNObservations=12")
  )
  expect_error(create_query_url("ICP.M.U2.N.000000.4.ANR", filter = list(a = 1, 2)),
               "must be named")
})

test_that("convert_dates handles common formats", {
  expect_equal(convert_dates("2024"), as.Date("2024-01-01"))
  expect_equal(convert_dates("2024-02"), as.Date("2024-02-01"))
  expect_equal(convert_dates("2024-02-15"), as.Date("2024-02-15"))
  expect_equal(convert_dates(character(0)), character(0))
  expect_warning(convert_dates("2024W01"), "format unknown")
  skip_if_not_installed("zoo")
  expect_equal(convert_dates("2024-Q1"), as.Date("2024-03-31"))
})

test_that("unreachable API fails gracefully with a message", {
  expect_message(res <- make_request("http://localhost:1/", "data"),
                 "Could not connect")
  expect_null(res)
})

# Online tests ------------------------------------------------------------

test_that("get_data returns a data frame", {
  skip_on_cran()
  skip_if_offline()

  key <- "ICP.M.DE.N.000000+XEF000.4.ANR"
  filter <- list(lastNObservations = 12)

  hicp <- get_data(key, filter)
  skip_if(is.null(hicp), "ECB Data Portal not available")

  expect_equal(class(hicp), c("tbl_df", "tbl", "data.frame"))
})

test_that("get_dataflows returns a data frame", {
  skip_on_cran()
  skip_if_offline()

  flows <- get_dataflows()
  skip_if(is.null(flows), "ECB Data Portal not available")

  expect_equal(class(flows), c("tbl_df", "tbl", "data.frame"))
})

test_that("get_dimensions returns a list of data frames", {
  skip_on_cran()
  skip_if_offline()

  dims <- get_dimensions("ICP.M.DE.N.000000+XEF000.4.ANR")
  skip_if(is.null(dims), "ECB Data Portal not available")

  expect_equal(class(dims), "list")
  dim_classes <- vapply(dims, function(x) class(x) == "data.frame", logical(1))
  expect_true(all(dim_classes))
})

test_that("malformed series key returns NULL with a 404 message", {
  skip_on_cran()
  skip_if_offline()

  key <- "ICP.M.DE.N.000000+XEF000.4.ANRs"
  expect_message(res <- get_data(key), regexp = "404")
  expect_null(res)
  expect_message(res <- get_dimensions(key), regexp = "404")
  expect_null(res)
  expect_message(res <- get_description(key), regexp = "404")
  expect_null(res)
})

test_that("get_description returns a character vector", {
  skip_on_cran()
  skip_if_offline()

  key <- "LFSI.M..S.UNEHRT.TOTAL0.15_74.T"
  desc <- get_description(key)
  skip_if(is.null(desc), "ECB Data Portal not available")

  expect_true(is.character(desc))
  expect_true(all(nchar(desc) > 0))
})

test_that("quarterly date conversion works", {
  skip_on_cran()
  skip_if_offline()

  key <- "MNA.Q.Y.DE.W2.S1.S1.B.B1GQ._Z._Z._Z.EUR.LR.N"
  gdp <- get_data(key)
  skip_if(is.null(gdp), "ECB Data Portal not available")

  gdp_dates <- convert_dates(gdp$obstime)
  expect_s3_class(gdp_dates, "Date")
  # correct format
  expect_false(anyNA(as.Date(as.character(gdp_dates), format = "%Y-%m-%d")))
  # end of quarter
  expect_true(all(grepl(pattern = "-(30|31)", gdp_dates)))
})
