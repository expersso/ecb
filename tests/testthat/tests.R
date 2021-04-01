test_that("get_data returns a data frame", {
  skip_on_cran()

  key <- "ICP.M.DE.N.000000+XEF000.4.ANR"
  filter <- list(lastNObservations = 12)

  hicp <- get_data(key, filter)

  expect_equal(class(hicp), c("tbl_df", "tbl", "data.frame"))
})

test_that("get_dataflows returns a data frame", {
  skip_on_cran()
  expect_equal(class(get_dataflows()), c("tbl_df", "tbl", "data.frame"))
})

test_that("get_dimensions returns a list of data frames", {
  skip_on_cran()

  dims <- get_dimensions("ICP.M.DE.N.000000+XEF000.4.ANR")
  expect_equal(class(dims), "list")

  dim_classes <- vapply(dims, function(x) class(x) == "data.frame", logical(1))
  expect_true(all(dim_classes))
})

test_that("malformed series key returns 404 error", {
  skip_on_cran()

  key <- "ICP.M.DE.N.000000+XEF000.4.ANRs"
  expect_error(get_data(key), regexp = "404")
  expect_error(get_dimensions(key), regexp = "404")
  expect_error(get_description(key), regexp = "404")
})

test_that("get_description returns a character vector", {
  skip_on_cran()

  key <- "LFSI.M..S.UNEHRT.TOTAL0.15_74.T"
  desc <- get_description(key)
  expect_true(is.character(desc))

  desc_lengths <- vapply(desc, nchar, numeric(1))
  expect_true(all(desc > 0))
})

test_that("quarterly date conversion works", {
  skip_on_cran()

  key <- "MNA.Q.Y.DE.W2.S1.S1.B.B1GQ._Z._Z._Z.EUR.LR.N"
  gdp <- get_data(key)
  gdp_dates <- convert_dates(gdp$obstime)
  expect_is(gdp_dates, "Date")
  # correct format
  expect_false(anyNA(as.Date(as.character(gdp_dates), format = "%Y-%m-%d")))
  # end of quarter
  expect_true(all(grepl(pattern = "-(30|31)", gdp_dates)))
})
