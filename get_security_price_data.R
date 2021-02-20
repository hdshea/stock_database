#' ---
#' title: "Initializing Stock Database with 20+ Years of Data"
#' author: "H. David Shea"
#' date: "11 February 2021"
#' output: github_document
#' ---
#'
#+ r setup, include = FALSE
library(DBI)
library(RSQLite)
library(tidyverse)
library(tidyquant)
#+

#' Connect to the SECDB database
#' 
base_dir <- here::here("")
db_file <- fs::path(base_dir, "SECDB")
if(dbCanConnect(RSQLite::SQLite(), db_file)) {
    secdb <- dbConnect(RSQLite::SQLite(), db_file)
}
source(fs::path(base_dir, "database_functions.R"))

#' SELECT all security data from SECDB
#' 
#' This currently pulls data for the 1500+ stocks in the SP1500.
#' Executing this notebook assumes that you have a POWER license for tiingo with 
#' the ability to access this much data in a single pass.
#' 
#' Note the following call assumes that the security table is newly initialized
#' and specifically that ALL securities are "current".  There will be different 
#' update procedures for getting pricing data on an on-going basis.
#' 
all_stocks <- db_get_security_current(secdb)

symbols <- all_stocks %>% 
    pull( symbol ) %>% 
    str_replace("\\.", "\\-" ) # wiki has B share tickers in this form stk.B, tiingo wants them in this form stk-B

pricing_table <- tq_get(symbols, get = "tiingo", from = "1998-12-31", to = "2021-02-18") %>% 
  mutate( symbol = str_replace(symbol, "\\-", "\\.") )

write_csv(pricing_table, fs::path(base_dir, "data", "pricing_table.csv"))

#' Saving all of the the pulled data to a data file for later use if necessary just for convenience.
#' The tq_get on 20+ years of >500 securities takes awhile to complete.
#' 

#' Now create the data structure to populate security_price
#' 
adJ_pricing_table <- pricing_table %>% 
  left_join(all_stocks, by = "symbol") %>% 
  select(uid, date, close, volume, divCash, splitFactor, adjusted) %>% 
  group_by(uid) %>% 
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
  mutate(
    prcReturn = 100 * (((close / prcAdjFactor) / (lag(close, 1) / lag(prcAdjFactor, 1))) - 1),
    totReturn = 100 * (((close / totAdjFactor) / (lag(close, 1) / lag(totAdjFactor, 1))) - 1)
  ) %>% 
  transmute(
    uid = uid, 
    effective_date = str_c(date), 
    closing_price = close, 
    volume = volume,
    price_return = prcReturn,
    total_return = totReturn,
    price_return_factor = prcAdjFactor,
    total_return_factor = totAdjFactor,
    dividend = divCash,
    split_factor = splitFactor
  ) %>% 
  ungroup()

write_csv(adJ_pricing_table, fs::path(base_dir, "data", "adj_pricing_table.csv"))

#' Saving all of the the adjusted data to a data file for later use if necessary just for convenience.
#' Even though the adjustment calculations on 20+ years of >500 securities are pretty fast.
#' 

#' Now, wholesale insert adj_price_table data into security_price
#' 
#' Note the conversion in the last transmute above to appropriately named and ordered fields to match the table definition.
#' Also note the conversion of the dttm formatted date field to the character formatted effective_date field.  SQLite does some
#' odd conversion on dttm formats.
#' 
dbAppendTable(secdb, "security_price", adJ_pricing_table)

#' Wrap up by disconnecting from database
#' 
dbDisconnect(secdb)
