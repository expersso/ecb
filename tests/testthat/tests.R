test_that("get_data returns a data frame", {
  skip_if_no_ecb_api()

  key <- "ICP.M.DE.N.000000+XEF000.4.ANR"
  filter <- list(lastNObservations = 12)

  hicp <- get_data(key, filter)

  expect_equal(class(hicp), c("tbl_df", "tbl", "data.frame"))
})

test_that("get_dataflows returns a data frame", {
  skip_if_no_ecb_api()
  expect_equal(class(get_dataflows()), c("tbl_df", "tbl", "data.frame"))
})

test_that("get_dimensions returns a list of data frames", {
  skip_if_no_ecb_api()

  dims <- get_dimensions("ICP.M.DE.N.000000+XEF000.4.ANR")
  expect_equal(class(dims), "list")

  dim_classes <- vapply(dims, function(x) class(x) == "data.frame", logical(1))
  expect_true(all(dim_classes))
})

test_that("malformed series key returns NULL with an informative message", {
  skip_if_no_ecb_api()

  key <- "ICP.M.DE.N.000000+XEF000.4.ANRs"
  expect_message(res <- get_data(key), regexp = "404")
  expect_null(res)
  expect_message(res <- get_dimensions(key), regexp = "404")
  expect_null(res)
  expect_message(res <- get_description(key), regexp = "404")
  expect_null(res)
})

test_that("get_description returns a character vector", {
  skip_if_no_ecb_api()

  key <- "LFSI.M..S.UNEHRT.TOTAL0.15_74.T"
  desc <- get_description(key)
  expect_true(is.character(desc))

  desc_lengths <- vapply(desc, nchar, numeric(1))
  expect_true(all(desc > 0))
})

test_that("quarterly date conversion works", {
  skip_if_no_ecb_api()
  skip_if_not_installed("zoo")

  key <- "MNA.Q.Y.DE.W2.S1.S1.B.B1GQ._Z._Z._Z.EUR.LR.N"
  gdp <- get_data(key)
  gdp_dates <- convert_dates(gdp$obstime)
  expect_is(gdp_dates, "Date")
  # correct format
  expect_false(anyNA(as.Date(as.character(gdp_dates), format = "%Y-%m-%d")))
  # end of quarter
  expect_true(all(grepl(pattern = "-(30|31)", gdp_dates)))
})

# Offline tests -------------------------------------------------------------

test_that("unreachable host fails gracefully with a message", {
  expect_message(res <- ecb:::make_request("https://ecb-api.invalid/x", "data"))
  expect_null(res)
})

test_that("create_query_url builds the expected URL", {
  url <- ecb:::create_query_url("ICP.M.U2.N.000000.4.ANR",
                                filter = list(lastNObservations = 12))
  expect_equal(url, paste0("https://data-api.ecb.europa.eu/service/data/ICP/",
                           "M.U2.N.000000.4.ANR?lastNObservations=12"))
  expect_error(ecb:::create_query_url("ICP.M", filter = list(1)), "named")
})

test_that("convert_dates handles annual, monthly and daily formats", {
  expect_equal(convert_dates("2020"), as.Date("2020-01-01"))
  expect_equal(convert_dates("2020-03"), as.Date("2020-03-01"))
  expect_equal(convert_dates("2020-03-15"), as.Date("2020-03-15"))
  skip_if_not_installed("zoo")
  expect_equal(convert_dates("2020-Q1"), as.Date("2020-03-31"))
})
