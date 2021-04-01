# library(tidyverse)
#
# qrtr_to_date <- . %>%
#   str_replace("-?Q1", "-01") %>%
#   str_replace("-?Q2", "-04") %>%
#   str_replace("-?Q3", "-07") %>%
#   str_replace("-?Q4", "-10") %>%
#   paste0("-01") %>%
#   as.Date()
#
# get_historical <- function(series_key, days = 100) {
#   url <- sprintf(
#     paste0("http://sdw/export.do?history=true&historyDays=%s&node=HISTORY&",
#            "SERIES_KEY=%s&seriesId=%s&exportType=csv"),
#     days, series_key, series_key
#   )
#
#   tmp <- tempfile(fileext = ".csv")
#   on.exit(unlink(tmp))
#
#   download.file(url, tmp)
#   readr::read_csv(tmp, skip = 4)
# }
#
# df <- get_historical("ICP.M.U2.N.000000.4.ANR", 10000) %>%
#   gather(change_date, obs_value, -Period) %>%
#   mutate(current_value = change_date == "Current value",
#          change_date = if_else(
#            change_date == "Current value", Sys.time(),
#            lubridate::ymd_hms(change_date, tz = "CET", quiet = TRUE)),
#          Period = qrtr_to_date(Period)
#   ) %>%
#   rename("obs_date" = Period)
#
# df <- get_historical("ICP.M.U2.N.000000.4.ANR", 10000) %>%
#   gather(change_date, obs_value, -Period) %>%
#   mutate(current_value = change_date == "Current value",
#          change_date = if_else(
#            change_date == "Current value", Sys.time(),
#            lubridate::ymd_hms(change_date, tz = "CET", quiet = TRUE))
#   ) %>%
#   rename("obs_date" = Period)
#
# df$obs_date <- df$obs_date %>% paste0("01") %>% as.Date("%Y%b%d")
# df$obs_value <- as.numeric(df$obs_value)
#
# ggplot(df, aes(x = obs_date, y = obs_value, color = factor(change_date))) +
#   geom_line(show.legend = FALSE)
