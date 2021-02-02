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
aapl_pricing_table <- tq_get("AAPL", get = "tiingo", from = "1999-12-31", to = "2020-12-31")
save_aapl_pricing_table <- aapl_pricing_table
# aapl_pricing_table <- save_aapl_pricing_table

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
#'   daily divFactor which can be used to adjust returns for dividend impacts
#'   
#'   daily totFactor which accounts for splist and dividend impact in one factor (needed for total return)
#'   
#'   prcAdjFactor adjustment to close for any date so that it can be compared to any other adjusted close to get price return
#'   
#'   totAdjFactor adjustment to close for any date so that it can be compared to any other adjusted close to get total return
#'   
#'   prcReturn which is adjusted one day price return for that date
#'   
#'   totReturn which is adjusted one day total return for that date
aapl_pricing_table <- aapl_pricing_table %>% 
    arrange(desc(date)) %>% 
    mutate(
        divFactor = 1 + (divCash / close),
        totFactor = divFactor * splitFactor,
        prcAdjFactor = cumprod(splitFactor),
        totAdjFactor = cumprod(totFactor),
        cTotAdjFactor = close / adjusted
    ) %>% 
    arrange(date)

aapl_2020 <- aapl_pricing_table %>% 
    filter(date >= '2019-12-31')

View(filter(aapl_2020, month(date) %in% c(8, 9)))

View(filter(aapl_2020, !near(adjusted, my_adjTot)))






#' figure out what is wrong here
#' 
aapl_pricing_table %>% 
    filter(date >= '2019-12-31') %>%
    mutate(totReturn = 1 + totReturn) %>% 
    select(totReturn) %>% 
    prod()


#' figure out what is wrong here
#' 
aapl_pricing_table %>% 
    filter(date >= '2019-12-31') %>%
    tq_transmute(adjusted, periodReturn, period = "yearly", col_rename = "return")

