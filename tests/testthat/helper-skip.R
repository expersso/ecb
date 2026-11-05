# Skip tests that need the ECB API when it is not reachable.
skip_if_no_ecb_api <- function() {
  skip_on_cran()
  skip_if_offline("data-api.ecb.europa.eu")
}
