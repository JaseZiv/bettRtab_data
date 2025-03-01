library(httr)
library(lubridate)
library(dplyr)
library(bettRtab)



httr::set_config(httr::use_proxy(url = Sys.getenv("PROXY_URL"),
                                 port = as.numeric(Sys.getenv("PROXY_PORT")),
                                 username =Sys.getenv("PROXY_USERNAME"),
                                 password= Sys.getenv("PROXY_PASSWORD")))


Sys.setenv(TZ = "Australia/Melbourne")




existing_df <- readRDS("data/race-meets/2024/race_meets_meta_2025.rds")

# now we want to get updated data - take te day after the latest last scrape, up to the day before today
# (as typically there won't be today's race meet data available)
dates <- seq(from = lubridate::ymd(max(existing_df$meetingDate))+1, to=lubridate::today()-1, by=1) %>% as.character()

# it appears that Christmas day is a race-free day so we'll need to remove that day:
# dates <- dates[-grep("2024-12-25", dates)]



# Start scraping loop -----------------------------------------------------

race_meets <- data.frame()


for(i in dates) {
  Sys.sleep(2)
  print(paste("scraping date:", i))
  df <- bettRtab::get_race_meet_meta(i)
  race_meets <- dplyr::bind_rows(race_meets, df)
}


existing_df <- existing_df %>% dplyr::bind_rows(race_meets)

saveRDS(existing_df, "data/race-meets/2025/race_meets_meta_2025.rds")

rm(list = ls())

