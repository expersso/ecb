## Resubmission

This version addresses the check failures reported by the CRAN team on
<https://cran.r-project.org/web/checks/check_results_ecb.html> (examples and
vignette erroring with "HTTP failure: 504" when the ECB Data Portal API was
unavailable).

* All functions that access the ECB Data Portal now fail gracefully with an
  informative message and return `NULL` if the resource is unavailable,
  returns an HTTP error, or has changed so that the response cannot be parsed.
* Examples that access the internet are wrapped in `\donttest{}` and handle a
  `NULL` result.
* The vignette only evaluates code that depends on downloaded data if the
  download succeeded.
* Tests that access the internet use `skip_on_cran()` and skip if the API is
  unavailable.

## Test environments

* local macOS, R 4.5.1

## R CMD check results

0 errors | 0 warnings | 0 notes
