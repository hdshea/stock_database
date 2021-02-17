library(tidyverse)  # for tidy/dplyr work
library(rvest)      # for web-scraping
library(lubridate)

gics_url  <- "https://en.wikipedia.org/wiki/Global_Industry_Classification_Standard"
sp500_url <- "https://en.wikipedia.org/wiki/List_of_S%26P_500_companies"
djia_url  <- "https://en.wikipedia.org/wiki/Dow_Jones_Industrial_Average"

# data for gics classifications table
gics_tbl <- read_html(gics_url) %>%
    html_element("table") %>%
    html_table() %>%
    janitor::clean_names() %>%
    transmute(
        sector_code = sector,
        sector_name = sector_2,
        industry_group_code = industry_group,
        industry_group_name = industry_group_2,
        industry_code = industry,
        industry_name = industry_2,
        sub_industry_code = sub_industry,
        sub_industry_name = sub_industry_2
    )
sct_tbl <- gics_tbl %>%
    distinct(sector_code, sector_name) %>% 
    transmute(
        code = sector_code,
        level = "SCT",
        name = sector_name
    )
igp_tbl <- gics_tbl %>%
    distinct(industry_group_code, industry_group_name) %>% 
    transmute(
        code = industry_group_code,
        level = "IGP",
        name = industry_group_name
    )
ind_tbl <- gics_tbl %>%
    distinct(industry_code, industry_name) %>% 
    transmute(
        code = industry_code,
        level = "IND",
        name = industry_name
    )
sub_tbl <- gics_tbl %>%
    distinct(sub_industry_code, sub_industry_name) %>% 
    transmute(
        code = sub_industry_code,
        level = "SUB",
        name = sub_industry_name
    )

# data for S&P 500 constituent table
sp500_tbl <- read_html(sp500_url) %>%
    html_element("#constituents") %>%
    html_table() %>%
    janitor::clean_names() %>%
    transmute(
        symbol = symbol,
        name = security,
        sub_industry_name = gics_sub_industry
    ) %>%
    left_join(gics_tbl, by = "sub_industry_name") %>%
    select(symbol, name, sub_industry_name, sub_industry_code) %>%
    transmute(
        uid = 1:n_distinct(symbol),
        start_date = str_c(today(tz="UTC")),
        end_date = "9999-12-31",
        symbol = symbol,
        name = name,
        sub_industry_code = sub_industry_code
    )

#
#  https://robotwealth.com/how-to-get-historical-spx-constituents-data-for-free/
#
#  we don't need the full methodology from this site because we don't really need to 
#  know the constituents of the SP500 - we really want a representative history of 
#  US listed larger stocks - the ticker list will help with this and with removing 
#  the backward looking bias caused by casting current SP500 constituents back in
#  time.
#

spxchanges <- read_html(sp500_url) %>%
    html_element("#changes") %>%
    html_table() %>%
    janitor::clean_names() %>%
    filter(row_number() > 1) %>%
    transmute(
        effective_date = mdy(date),
        symbol_add = added,
        name_add = added_2,
        symbol_rem = removed,
        name_rem = removed_2,
        reason = reason
    )

spx_add <- spxchanges %>%
    filter(symbol_add != "") %>% 
    transmute(symbol = symbol_add) %>% 
    filter(!(symbol %in% (sp500_tbl %>% pull(symbol))))

spx_rem <- spxchanges %>%
    filter(symbol_rem != "") %>% 
    transmute(symbol = symbol_rem) %>% 
    filter(!(symbol %in% (sp500_tbl %>% pull(symbol)))) %>% 
    filter(!(symbol %in% (spx_add %>% pull(symbol))))

older_sp500_tbl <- union(spx_add,spx_rem) %>% 
    transmute(
        uid = 1:n_distinct(symbol),
        uid = uid + pull(count(sp500_tbl)),
        start_date = str_c(today(tz="UTC")),
        end_date = "9999-12-31",
        symbol = symbol,
        name = "temp name",
        sub_industry_code = NA_integer_
    )

sp500_tbl <- union(sp500_tbl, older_sp500_tbl)

# data for DJIA constituent table
djia_tbl <- read_html(djia_url) %>%
    html_element("#constituents") %>%
    html_table() %>%
    janitor::clean_names() %>%
    transmute(
        symbol = str_remove(symbol, "^NYSE:\\s"),
        name = company,
        sub_industry_name = NA_character_,
        sub_industry_code = NA_integer_
    ) %>% 
    left_join(sp500_tbl, by = "symbol") %>%
    transmute(
        uid = uid,
        start_date = str_c(today(tz="UTC")),
        end_date = "9999-12-31",
        symbol = symbol,
        name = name.y,
        sub_industry_code = sub_industry_code.y
    )

# cleanup temp storage
rm(gics_tbl, spxchanges, spx_add, spx_rem, older_sp500_tbl)
