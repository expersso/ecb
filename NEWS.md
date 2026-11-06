# ecb 0.4.4

- All functions that query the ECB Data Portal now fail gracefully, as required
  by CRAN policy. If the API cannot be reached, returns an HTTP error, or
  returns a response that cannot be parsed, an informative message is shown
  and `NULL` is returned invisibly instead of throwing an error.
- Requests now use a default timeout of 60 seconds, which can be overridden by
  passing `httr::timeout()` through `...`.
- `get_description()` gains a `...` argument passed on to `httr::GET()`.
- `get_data()` now passes `...` on to `get_dimensions()` when `detail` is
  `"serieskeysonly"` or `"nodata"`.
- `convert_dates()` returns zero-length input unchanged.
- Examples that access the internet are wrapped in `\donttest{}`, and the
  vignette skips code that depends on downloaded data if the API is
  unavailable.
- Added offline tests; online tests now skip if the API is unavailable.
