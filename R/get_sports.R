library(httr)
library(jsonlite)
library(dplyr)
library(tidyr)


params = list(
  `jurisdiction` = 'VIC'
)

httr::set_config(httr::use_proxy(url = Sys.getenv("PROXY_URL"),
                                 port = as.numeric(Sys.getenv("PROXY_PORT")),
                                 username =Sys.getenv("PROXY_USERNAME"),
                                 password= Sys.getenv("PROXY_PASSWORD")))


res <- httr::GET(url = 'https://api.beta.tab.com.au/v1/tab-info-service/sports', query = params)

a <- httr::content(res)
b <- a$sports

all_data <- data.frame()

for(i in b) {
  each_sport <- jsonlite::toJSON(i) %>% jsonlite::fromJSON() %>% data.frame()

  all_data <- dplyr::bind_rows(all_data, each_sport)
}

all_data <- all_data %>%
  select(-X_links.self, -X_links.selfTemplate, -X_links.competitions, -X_links.footytab)
## here, we want to do soemthing with the FALSE results - expand those out:
which_to_change <- all_data$competitions.hasMarkets == TRUE

# idx <- grep(!which_to_change, which_to_change)
to_change <- all_data[!which_to_change, ]
# to_change <- .unlist_df_cols(to_change)


to_change <- to_change %>%
  select(id, name, displayName, spectrumId, competitions.tournaments, sameGame)

to_change <- tidyr::unnest(to_change,
                           cols = competitions.tournaments, names_sep = ".")

names(to_change) <- gsub(".tournaments", "", names(to_change))


to_change <- tidyr::unnest(to_change,
                           cols = c(competitions.id, competitions.name, competitions.spectrumId,
                                    competitions._links))



no_change <- all_data[which_to_change, ]

no_change <- no_change %>%
  dplyr::select(-competitions.tournaments, -competitions.hasMarkets, -competitions.sameGame)

no_change <- tidyr::unnest(no_change,
                           cols = c(competitions.id, competitions.name, competitions.spectrumId,
                                    competitions._links))

all_data <- bind_rows(no_change, to_change)


saveRDS(all_data, "data/sports_markets.rds")

all_data %>%
  select(id, name, displayName, competitions.id, competitions.name) %>%
  mutate(id = as.numeric(id),
         competitions.id = as.numeric(competitions.id)) %>%
  arrange(id, competitions.id) %>%
  write.csv("data/sports_markets.csv", row.names = FALSE)

rm(list = ls())


