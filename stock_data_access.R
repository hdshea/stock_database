library(tidyverse)
library(rvest)
library(lubridate)

gics_url  <- "https://en.wikipedia.org/wiki/Global_Industry_Classification_Standard"
sp500_url <- "https://en.wikipedia.org/wiki/List_of_S%26P_500_companies"
sp400_url <- "https://en.wikipedia.org/wiki/List_of_S%26P_400_companies"
sp600_url <- "https://en.wikipedia.org/wiki/List_of_S%26P_600_companies"
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
        uid = NA_integer_,
        start_date = str_c(today(tz="UTC")),
        end_date = "9999-12-31",
        symbol = symbol,
        name = name,
        sub_industry_code = sub_industry_code
    )

# data for S&P 400 constituent table
# - the last step filters out any overlap with the SP500_tbl
sp400_tbl <- read_html(sp400_url) %>%
    html_element("#constituents") %>%
    html_table() %>%
    janitor::clean_names() %>%
    transmute(
        symbol = ticker_symbol,
        name = security,
        sub_industry_name = gics_sub_industry
    ) %>%
    left_join(gics_tbl, by = "sub_industry_name") %>%
    select(symbol, name, sub_industry_name, sub_industry_code) %>%
    transmute(
        uid = NA_integer_,
        start_date = str_c(today(tz="UTC")),
        end_date = "9999-12-31",
        symbol = symbol,
        name = name,
        sub_industry_code = sub_industry_code
    ) %>% 
    filter(!(symbol %in% (sp500_tbl %>% pull(symbol))))

# The SP600 data on wiki doesn't appear to be updated regularly.  Nonetheless,
# the symbol list, names and sub-industry data are useful for building out the
# security database.
#

# data for S&P 600 constituent table
# - the last two steps filters out any overlap with the sp500_tbl and sp400_tbl
sp600_tbl <- read_html(sp600_url) %>%
    html_element("#constituents") %>%
    html_table() %>%
    janitor::clean_names() %>%
    transmute(
        symbol = ticker_symbol,
        name = company,
        sub_industry_name = gics_sub_industry
    ) %>%
    group_by(symbol) %>% # these three steps required because there were a few duplicate symbols with name variations
    filter(row_number(symbol) == 1) %>% 
    ungroup() %>% 
    left_join(gics_tbl, by = "sub_industry_name") %>%
    select(symbol, name, sub_industry_name, sub_industry_code) %>%
    transmute(
        uid = NA_integer_,
        start_date = str_c(today(tz="UTC")),
        end_date = "9999-12-31",
        symbol = symbol,
        name = name,
        sub_industry_code = sub_industry_code
    ) %>% 
    filter(!(symbol %in% (sp500_tbl %>% pull(symbol)))) %>% 
    filter(!(symbol %in% (sp400_tbl %>% pull(symbol))))

sp1500_tbl <- union(sp500_tbl, sp400_tbl) %>% 
    union(sp600_tbl) %>% 
    mutate(
        uid = 1:n_distinct(symbol)
    )

#
#  https://robotwealth.com/how-to-get-historical-spx-constituents-data-for-free/
#
#  we don't need the full methodology from this site because we don't really need to 
#  know the constituents of the SP500, SP400 or SP600 - we really want a representative 
#  history of US listed stocks - the ticker list will help with this and with removing 
#  the backward looking bias caused by casting current constituents back in time.
#
#  note that only the SP500 and SP400 pages have a changes section.  The SP600 data
#  on wiki were current (at the time the page was made) and previous constituents
#

spx5changes <- read_html(sp500_url) %>%
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

spx4changes <- (read_html(sp400_url) %>%
    html_elements("table"))[[2]] %>% # on the SP400 wiki page the changes table doesn't have an id; it is the 2nd table in the doc
    html_table() %>%
    janitor::clean_names() %>%
    filter(row_number() > 1) %>%
    transmute(
        effective_date = mdy(str_replace(date, "\\[.*$", "")), # SP400 data has comments on some dates
        symbol_add = added,
        name_add = added_2,
        symbol_rem = removed,
        name_rem = removed_2,
        reason = reason
    )

spxchanges <- union(spx5changes,spx4changes)

spx_add <- spxchanges %>%
    filter(symbol_add != "") %>% 
    transmute(
        symbol = symbol_add,
        name = name_add
    ) %>% 
    filter(!(symbol %in% (sp1500_tbl %>% pull(symbol))))

spx_rem <- spxchanges %>%
    filter(symbol_rem != "") %>% 
    transmute(
        symbol = symbol_rem,
        name = name_rem
    ) %>% 
    filter(!(symbol %in% (sp1500_tbl %>% pull(symbol)))) %>% 
    filter(!(symbol %in% (spx_add %>% pull(symbol))))

older_sp_tbl <- union(spx_add,spx_rem) %>% 
    group_by(symbol) %>% 
    filter(row_number(symbol) == 1) %>% 
    ungroup() %>% 
    transmute(
        uid = 1:n_distinct(symbol),
        uid = uid + pull(count(sp1500_tbl)),
        start_date = str_c(today(tz="UTC")),
        end_date = "9999-12-31",
        symbol = symbol,
        name = name,
        sub_industry_code = NA_integer_
    )

sp1500_tbl <- union(sp1500_tbl, older_sp_tbl)

# The following is time consuming and did not turn out to gather additional sub_industry
# matches for those older securities missing sub_industry data - the Yahoo Finance code 
# is the slow part and did not match but 10+% of the missing data
#
getYFIndustry <- function( symbol.in ) {
    rval <- NA_character_
    sym <- str_replace(symbol.in, "\\.", "\\-" )
    url <- str_c("https://finance.yahoo.com/quote/", sym, "/profile?p=", sym, sep = "")

    # The Industry from the YF Profile pages is the text of the element right after the element whose text is "Industry"
    children <- read_html(url) %>% html_elements('p') %>% html_children()
    if( length(children) > 0 ) {
        for( x in 1:length(children) ) {
            if(is.na(rval) && ((children[x] %>% html_text()) == "Industry")) {
                rval <- children[x+1] %>% html_text()
            }
        }
    }
    rval
}

missing_subindustry <- sp1500_tbl %>%
    filter(is.na(sub_industry_code)) %>%
    select(uid, symbol) %>%
    mutate(industry = NA_character_)

for( idx in 1:pull(count(missing_subindustry)) ) {
    missing_subindustry[idx,]$industry <- getYFIndustry( missing_subindustry[idx,]$symbol )
}

# mapping of YF Industry classifications to GICS sub-industry classifications
# partial list for those found in security build up with missing sub_industry data
#
submap <- tribble(
    ~sub_industry_code, ~industry,
    40101015,"Banks—Regional",
    25101010,"Auto Parts",
    45103010,"Software—Application",
    45202030,"Computer Hardware",
    20107010,"Industrial Distribution",
    20101010,"Aerospace & Defense",
    40301040,"Insurance—Property & Casualty",
    20201060,"Business Equipment & Supplies",
    40204010,"Mortgage Finance",
    20201080,"Security & Protection Services",
    50201010,"Advertising Agencies",
    10101020,"Oil & Gas Equipment & Services",
    60101060,"REIT—Residential",
    55101010,"Utilities—Regulated Electric",
    50202020,"Electronic Gaming & Multimedia",
    15104010,"Aluminum",
    45102030,"Software—Infrastructure",
    15104020,"Other Industrial Metals & Mining",
    10102050,"Thermal Coal",
    20105010,"Shell Companies",
    25301010,"Gambling",
    35201010,"Biotechnology",
    10102030,"Oil & Gas Refining & Marketing",
    55105020,"Utilities—Renewable",
    40203010,"Asset Management",
    50203010,"Internet Content & Information",
    15101050,"Specialty Chemicals",
    15103010,"Packaging & Containers",
    30101010,"Pharmaceutical Retailers",
    25504040,"Specialty Retail",
    20201050,"Waste Management",
    10102020,"Oil & Gas E&P",
    40203030,"Capital Markets"
)

newsubs <- missing_subindustry %>% 
    filter(!is.na(industry)) %>% 
    left_join(submap, by = "industry") %>% 
    select(uid, sub_industry_code)

sp1500_tbl %>% 
    left_join(newsubs, by = "uid") %>% 
    mutate(
        sub_industry_code = ifelse(!is.na(sub_industry_code.x), sub_industry_code.x, sub_industry_code.y)
    ) %>% 
    select(uid, start_date, end_date, symbol, name, sub_industry_code)

# cleanup temp storage
rm(gics_tbl, older_sp_tbl, sp400_tbl, sp500_tbl, sp600_tbl, spxchanges, spx4changes, spx5changes, spx_add, spx_rem)
rm(missing_subindustry, submap, newsubs)
rm(djia_url, gics_url, sp400_url, sp500_url, sp600_url)
rm(getYFIndustry)
