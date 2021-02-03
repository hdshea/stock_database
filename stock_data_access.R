library(tidyverse)  # for tidy/dplyr work
library(rvest)      # for web-scraping

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
    select(symbol, name, sub_industry_name, sub_industry_code)

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
        symbol = symbol,
        name = name.y,
        sub_industry_name = sub_industry_name.y,
        sub_industry_code = sub_industry_code.y
    )

