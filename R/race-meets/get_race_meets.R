library(httr)
library(rvest)
library(lubridate)
library(tidyverse)


# .replace_empty_na <- function(val) {
#   if(length(val) == 0) {
#     val <- NA_character_
#   } else {
#     val <- val
#   }
#   return(val)
# }

Sys.setenv(TZ = "Australia/Melbourne")

.each_race_date <- function(each_date) {

  each_url <- paste0('https://api.beta.tab.com.au/v1/historical-results-service/VIC/racing/', each_date)

  history <- httr::RETRY("GET",
                         url = each_url,
                         times = 5, # the function has other params to tweak its behavior
                         pause_min = 5,
                         pause_base = 2)

  history_content <- suppressMessages(tryCatch(httr::content(history, "text"), error = function(e) NA_character_))

  meetings_list <- tryCatch(data.frame(jsonlite::fromJSON(history_content)$meetings), error = function(e) NA_character_)

  # need a while loop here as there were still times when the API was failing and returning a list of length zero
  # have arbitrarily set the max number of retries in the while-loop to 20 - might want to parameterise this later
  iter <- 1
  while(length(history_content) == 0 | is.na(history_content) | any(grepl("NOT_FOUND_ERROR", history_content))) {

    iter <- iter + 1
    stopifnot("The API is not accepting this request. Please try again." = iter <21)

    Sys.sleep(2)

    history <- httr::RETRY("GET",
                           url = each_url,
                           times = 5, # the function has other params to tweak its behavior
                           pause_min = 5,
                           pause_base = 2)


    history_content <- suppressMessages(tryCatch(httr::content(history, "text"), error = function(e) NA_character_))

    meetings_list <- tryCatch(data.frame(jsonlite::fromJSON(history_content)$meetings), error = function(e) NA_character_)

  }

  return(meetings_list)
}




get_race_meet_meta <- function(race_dates) {

  race_dates %>%
    purrr::map_df(.each_race_date)
}




dates <- seq(from = ymd("2021-01-01"), to=ymd("2022-09-03"), by=1) %>% as.character()

race_meets <- data.frame()


for(i in dates) {
  print(paste("scraping date:", i))
  # Sys.sleep(2)
  df <- get_race_meet_meta(i)
  race_meets <- bind_rows(race_meets, df)
}


race_meets21 <- race_meets %>%
  filter(grepl("2021-", meetingDate))

saveRDS(race_meets21, "data/race-meets/2021/race_meets_meta_2021.rds")


race_meets22 <- race_meets %>%
  filter(grepl("2022-", meetingDate))

saveRDS(race_meets22, "data/race-meets/2022/race_meets_meta_2022.rds")
