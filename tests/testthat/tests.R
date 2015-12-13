test_that("get_data returns a data frame", {

  key <- "ICP.M.DE.N.000000+XEF000.4.ANR"
  filter <- list(lastNObservations = 12)

  hicp <- get_data(key, filter)

  expect_equal(class(hicp), c("tbl_df", "tbl", "data.frame"))
})

test_that("malformed series key returns 404 error", {
  key <- "ICP.M.DE.N.000000+XEF000.4.ANRs"
  expect_error(get_data(key), regexp = "404")
  expect_error(get_dimensions(key), regexp = "404")
  expect_error(get_description(key), regexp = "404")
})