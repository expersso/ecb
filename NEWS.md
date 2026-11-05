# ecb 0.4.4

* All functions that access the ECB Data Portal API now fail gracefully, as
  required by CRAN policy: if the API cannot be reached, returns an HTTP error,
  or returns a response that cannot be parsed, an informative message is shown
  and `NULL` is returned (invisibly) instead of an error being thrown.
  **Note:** HTTP errors such as 404 for an invalid series key previously threw
  an error; they now produce a message and return `NULL`.
* Requests now use a default timeout of 60 seconds, which can be changed with
  `options(ecb.timeout = <seconds>)` or by passing `httr::timeout()`.
* `get_description()` gains a `...` argument passed on to `httr::GET()`.
* Examples that use the API are wrapped in `\donttest{}`; `convert_dates()`
  has offline examples.
* The vignette checks whether the API is reachable and skips network-dependent
  code if it is not.
* Tests that need the API are skipped when it is unreachable; new offline
  tests were added.
