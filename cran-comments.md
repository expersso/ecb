## Resubmission / update

This release responds to the CRAN team's request of 2026-11-05 to make the
package fail gracefully when the ECB Data Portal API is unavailable or has
changed (CRAN policy on packages using Internet resources).

Changes:

* All functions that access the API now catch connection errors, timeouts,
  HTTP errors and unparseable responses, emit an informative message and
  return `NULL` instead of throwing an error.
* Examples that access the API are in `\donttest{}` and cope with a `NULL`
  result.
* The vignette checks API availability and does not evaluate
  network-dependent code if the API cannot be reached.
* Tests that need the API are skipped on CRAN and when offline.

## Test environments
* Ubuntu 24.04, R 4.3.3 (with and without network access to the API)
* GitHub Actions: macOS, Windows, Ubuntu (devel, release, oldrel-1)
* win-builder (release and devel)

## R CMD check results
0 errors | 0 warnings | 0 notes
