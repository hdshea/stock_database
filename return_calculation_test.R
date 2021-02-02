#' ---
#' title: "Stock Database Price and Total Return Calculation Investigation"
#' author: "H. David Shea"
#' date: "1 February 2021"
#' output: github_document
#' ---
#'
#+ r setup, include = FALSE
library(tidyverse)  # for tidy/dplyr work
library(rvest)      # for web-scraping
library(tidyquant)  # for quant work and security data access
#+

#' ## AAPL as our example case
#' 
#' Use tidyqaunt to get price data from tiingo from 31 Dec 1999 through 31 Dec 2020
#' 
aapl_pricing_table <- tq_get("AAPL", get = "tiingo", from = "1999-12-31", to = "2020-12-31") %>%
    select(symbol, date, close, adjusted, divCash, splitFactor)
    
save_aapl_pricing_table <- aapl_pricing_table
# aapl_pricing_table <- save_aapl_pricing_table
#
# use the above for later iterations to avoid repeat hits to tiingo

#' AAPL has had 4 stock splits in that period
#' 
#' 2 for 1 on 21 Jun 2000
#' 
#' 2 for 1 on 28 Feb 2005
#' 
#' 7 for 1 on  9 Jun 2014
#' 
#' 4 for 1 on 31 Aug 2020
#' 
aapl_pricing_table %>% 
    filter(splitFactor != 1)

#' AAPL has paid regular quarterly (Feb, May, Aug, Nov) dividends since mid 2012
#' 
aapl_pricing_table %>% 
    filter(divCash != 0)

#' New data items:
#' 
#'   prcAdjFactor adjustment to close for any date so that it can be compared to any other adjusted close to get price return
#'   
#'   totAdjFactor adjustment to close for any date so that it can be compared to any other adjusted close to get total return
#'   
#'   a few other values are left to make a proper check on adjusted price calculations - fields into the database table 
#'   update routines would be (symbol, date, close, divCash, splitFactor, prcAdjFactor, totAdjFactor)
#'   
aapl_pricing_table <- aapl_pricing_table %>% 
    group_by(symbol) %>% 
    arrange(desc(date)) %>% 
    mutate(
        divFactor = 1 + (divCash / close),
        totFactor = divFactor * splitFactor,
        splitAdjust = lag(splitFactor, 1),
        totAdjust = lag(totFactor, 1),
        splitAdjust = ifelse(is.na(splitAdjust), 1, splitAdjust),
        totAdjust = ifelse(is.na(totAdjust), 1, totAdjust),
        prcAdjFactor = cumprod(splitAdjust),
        totAdjFactor = cumprod(totAdjust)
    ) %>% 
    arrange(date) %>% 
    select(symbol, date, close, adjusted, divCash, splitFactor, prcAdjFactor, totAdjFactor) %>% 
    ungroup()

#' these should match entirely
#' 
aapl_pricing_table %>% 
    filter(date > '1999-12-31') %>% 
    mutate(my_adjusted = close / totAdjFactor) %>%
    tq_transmute(my_adjusted, periodReturn, period = "yearly", col_rename = "return")

aapl_pricing_table %>% 
    filter(date > '1999-12-31') %>% 
    tq_transmute(adjusted, periodReturn, period = "yearly", col_rename = "return")

