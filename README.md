[![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/ecb)](http://cran.r-project.org/package=ecb)
[![Travis-CI Build
Status](https://travis-ci.org/expersso/ecb.svg?branch=master)](https://travis-ci.org/expersso/ecb)
[![Coverage
Status](https://img.shields.io/codecov/c/github/expersso/ecb/master.svg)](https://codecov.io/github/expersso/ecb?branch=master)
[![Cranlogs
Downloads](http://cranlogs.r-pkg.org/badges/grand-total/ecb)](http://cran.r-project.org/package=ecb)

### Introduction

The `ecb` package package provides an `R` interface to the [European
Central Bank’s Statistical Data Warehouse](https://sdw.ecb.europa.eu/).

To install the development version:

``` r
library(devtools)
install_github("expersso/ecb")
```

### Example usage

The following example extracts the last twelve observations of headline
and “core” HICP inflation for a number of countries available in the
`ICP` database. See details below on how to use the `filter` parameter
and how to find and use the SDW series keys.

``` r
library(ecb)
library(ggplot2)

key <- "ICP.M.DE+FR+ES+IT+NL+U2.N.000000+XEF000.4.ANR"
filter <- list(lastNObservations = 12, detail = "full")

hicp <- get_data(key, filter)

hicp$obstime <- convert_dates(hicp$obstime)

ggplot(hicp, aes(x = obstime, y = obsvalue, color = title)) +
  geom_line() +
  facet_wrap(~ref_area, ncol = 3) +
  theme_bw(8) +
  theme(legend.position = "bottom") +
  labs(x = NULL, y = "Percent per annum\n", color = NULL,
       title = "HICP - headline and core\n")
```

![](vignettes/hicp_plot-1.png)

### Details

#### The filter option

The `filter` option of `get_data()` takes a named list of key-value
pairs. If left blank, it returns all data for the current version.

Available filter parameters:

-   `startPeriod` & `endPeriod`
    -   `YYYY` for annual data (e.g. 2013)
    -   `YYYY-S[1-2]` for semi-annual data (e.g. 2013-S1)
    -   `YYYY-Q[1-4]` for quarterly data (e.g. 2013-Q1)
    -   `YYYY-MM` for monthly data (e.g. 2013-01)
    -   `YYYY-W[01-53]` for weekly data (e.g. 2013-W01)
    -   `YYYY-MM-DD` for daily data (e.g. 2013-01-01)
-   `updatedAfter`
    -   A timestamp to retrieve the latest version of changed values in
        the database since a certain point in time
    -   Example:
        `filter = list(updatedAfter = 2009-05-15T14:15:00+01:00)`
-   `firstNObservations` & `lastNObservations`
    -   Example: `filter = list(firstNObservations = 12)` retrieves the
        first 12 observations of all specified series
-   `detail`
    -   Possible options: `full/dataonly/serieskeysonly/nodata`
    -   `dataonly` is the default
    -   Use `serieskeysonly` or `nodata` to list series that match a
        certain query, without returning the actual data
    -   An alternative to using `serieskeys/nodata` is the convenience
        function `get_dimensions()`, which returns a list of dataframes
        with dimensions and explanations (see extended example below).
    -   `full` returns both the series values and all metadata. This
        entails retrieving much more data than with the `dataonly`
        option.
-   `includeHistory` (not currently implemented)
    -   `false` (default) returns only version currently in production
    -   `true` returns version currently in production, as well as all
        previous versions

See the [SDW API](https://sdw-wsrest.ecb.europa.eu/) for more details.

#### Using SDW keys

The easiest way to find and learn more about SDW series key is to browse
the [SDW website](https://sdw.ecb.europa.eu/). After finding the series
one is interested in, and applying the relevant filters (frequency,
geographic area, etc), one can just copy the key:

![screenshot](vignettes/screenshot.png)

The SDW website also has provides all the necessary metadata, so it is
much easier to explore data availability (in terms of available
breakdowns, time periods, etc) directly on the website than it is to do
it directly through the `ecb` package.

The `ecb` package supports using wildcards in the series key, which
takes the form of simply leaving the wildcard dimension empty. For
example, the key `ICP.M.DE.N.000000.4.ANR` retrieves HICP data for
Germany (`DE`), while leaving the third dimension empty -
`ICP.M..N.000000.4.ANR` - retrieves the same data for *all* available
countries and country groups.

Instead of wildcarding, one can use the `+` operator to specify multiple
values for a dimension. For example, `ICP.M.DE.N.000000+XEF000.4.ANR`
retrieves both headline inflation (`000000`) and core inflation
(`XEF000`). Learning that e.g. `XEF000` corresponds to core inflation
would be done by browsing the SDW website:

![screenshot2](vignettes/screenshot2.png)

To remind oneself of what different values for different dimensions
mean, one can use the `get_dimensions)` function, which returns a list
of dataframes:

``` r
dims <- get_dimensions("ICP.M.DE.N.000000+XEF000.4.ANR")
head(dims[[1]], 8)
```

    ##               dim                         value
    ## 1            FREQ                             M
    ## 2        REF_AREA                            DE
    ## 3      ADJUSTMENT                             N
    ## 4        ICP_ITEM                        000000
    ## 5 STS_INSTITUTION                             4
    ## 6      ICP_SUFFIX                           ANR
    ## 7     DOM_SER_IDS ICPT.M.VAL.HICP.RCH_A.DE.00.M
    ## 8       UNIT_MULT                             0

### Extended example

As a more extended example, we will retrieve data to plot the annual
change in wages against the annual change in unemployment. [Economic
theory](https://en.wikipedia.org/wiki/Phillips_curve) suggests a
negative relationship between these two variables.

We start by retrieving the two series, using wildcards for the
geographic area dimension:

``` r
unemp <- get_data("STS.A..N.UNEH.RTT000.4.AV3", 
                 filter = list(startPeriod = "2000"))

wages <- get_data("MNA.A.N..W2.S1.S1._Z.COM_HW._Z._T._Z.IX.V.N", 
                 filter = list(startPeriod = "2000"))

head(unemp)
```

    ## # A tibble: 6 x 9
    ##   freq  ref_area adjustment sts_concept sts_class sts_institution
    ##   <chr> <chr>    <chr>      <chr>       <chr>     <chr>          
    ## 1 A     AT       N          UNEH        RTT000    4              
    ## 2 A     AT       N          UNEH        RTT000    4              
    ## 3 A     AT       N          UNEH        RTT000    4              
    ## 4 A     AT       N          UNEH        RTT000    4              
    ## 5 A     AT       N          UNEH        RTT000    4              
    ## 6 A     AT       N          UNEH        RTT000    4              
    ## # ... with 3 more variables: sts_suffix <chr>, obstime <chr>,
    ## #   obsvalue <dbl>

``` r
head(wages)
```

    ## # A tibble: 6 x 16
    ##   freq  adjustment ref_area counterpart_area ref_sector counterpart_sector
    ##   <chr> <chr>      <chr>    <chr>            <chr>      <chr>             
    ## 1 A     N          AT       W2               S1         S1                
    ## 2 A     N          AT       W2               S1         S1                
    ## 3 A     N          AT       W2               S1         S1                
    ## 4 A     N          AT       W2               S1         S1                
    ## 5 A     N          AT       W2               S1         S1                
    ## 6 A     N          AT       W2               S1         S1                
    ## # ... with 10 more variables: accounting_entry <chr>, sto <chr>,
    ## #   instr_asset <chr>, activity <chr>, expenditure <chr>,
    ## #   unit_measure <chr>, prices <chr>, transformation <chr>, obstime <chr>,
    ## #   obsvalue <dbl>

To get a human-readable description of a series:

``` r
desc <- head(get_description("STS.A..N.UNEH.RTT000.4.AV3"), 3)
strwrap(desc, width = 80)
```

    ## [1] "Austria - Standardised unemployment, Rate, Total (all ages), Total (male and"   
    ## [2] "female); 3-year average; Eurostat; Neither seasonally nor working day adjusted,"
    ## [3] "percentage of civilian workforce"                                               
    ## [4] "Belgium - Standardised unemployment, Rate, Total (all ages), Total (male and"   
    ## [5] "female); 3-year average; Eurostat; Neither seasonally nor working day adjusted,"
    ## [6] "percentage of civilian workforce"                                               
    ## [7] "Bulgaria - Standardised unemployment, Rate, Total (all ages), Total (male and"  
    ## [8] "female); 3-year average; Eurostat; Neither seasonally nor working day adjusted,"
    ## [9] "percentage of civilian workforce"

We now join together the two data sets:

``` r
library(dplyr)
```

    ## 
    ## Attaching package: 'dplyr'

    ## The following objects are masked from 'package:stats':
    ## 
    ##     filter, lag

    ## The following objects are masked from 'package:base':
    ## 
    ##     intersect, setdiff, setequal, union

``` r
unemp <- unemp %>% select(ref_area, obstime, "unemp" = obsvalue)
wages <- wages %>% select(ref_area, obstime, "wage" = obsvalue)

df <- left_join(unemp, wages)
```

    ## Joining, by = c("ref_area", "obstime")

``` r
head(df)
```

    ## # A tibble: 6 x 4
    ##   ref_area obstime unemp  wage
    ##   <chr>    <chr>   <dbl> <dbl>
    ## 1 AT       2000     4.27  77.0
    ## 2 AT       2001     4.02  78.6
    ## 3 AT       2002     4.10  80.4
    ## 4 AT       2003     4.38  82.2
    ## 5 AT       2004     4.88  83.5
    ## 6 AT       2005     5.30  85.9

Finally, we plot the annual change in wages against the annual change in
unemployment for all countries:

``` r
library(ggplot2)

df %>% 
  filter(complete.cases(.)) %>% 
  group_by(ref_area) %>% 
  mutate(d_wage = c(NA, diff(wage)) / lag(wage),
         d_unemp = c(NA, diff(unemp))) %>% 
  ggplot(aes(x = d_unemp, y = d_wage)) +
  geom_point() +
  facet_wrap(~ref_area, scales = "free") +
  theme_bw(8) +
  theme(strip.background = element_blank()) +
  geom_smooth(method = "lm") +
  labs(x = "\nAnnual change in unemployment", y = "Annual change in wages\n",
       title = "Relationship between wages and unemployment\n")
```

![](vignettes/phillips_plot-1.png)

At a first glance, most countries indeed seem to follow the prediction
of a negative relationship between wages and unemployment.

### Disclaimer

This package is in no way officially related to, or endorsed by, the
ECB.
