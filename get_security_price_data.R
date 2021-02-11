#' ---
#' title: "Initializing Stock Database with 5 Years of Data"
#' author: "H. David Shea"
#' date: "11 February 2021"
#' output: github_document
#' ---
#'
#+ r setup, include = FALSE
library(DBI)
library(RSQLite)
library(tidyverse)
library(tidyquant)  # for quant work and security data access
#+

#' Connect to the SECDB database
#' 
base_dir <- here::here("")
db_file <- fs::path(base_dir, "SECDB")
if(dbCanConnect(RSQLite::SQLite(), db_file)) {
    secdb <- dbConnect(RSQLite::SQLite(), db_file)
}

#' These functions will be moved into a library .R file as we build them up
#' 
#' Basic SELECT statement wrapper returning results in a tibble
#' 
dbSelectData <- function( con, select_statement ) {
    res <- dbSendQuery(con, sql)
    rval <- tibble::tibble(dbFetch(res))
    dbClearResult(res)
    rm(res)
    rval
}

#' SELECT all security data from 
#' 
sql <- "SELECT  uid,
        symbol,
        name
FROM    security
WHERE   start_date <= DATE('now')
  AND   end_date > DATE('now')"
all_stocks <- dbSelectData(secdb, sql)

#' Test with first 100 uid
#' 
symbols <- all_stocks %>% 
    filter( between( uid, 1, 100) ) %>% 
    pull( symbol ) %>% 
    str_replace("\\.", "\\-" )

pricing_table <- tq_get(symbols, get = "tiingo", from = "1999-12-31", to = "2020-12-31") %>%
    select(symbol, date, close, adjusted, divCash, splitFactor)

save_pricing_table <- pricing_table
# pricing_table <- save_pricing_table

#' This iteration had errors on tq_get for BRK.B and BF.B - investigated appropriate notation for class B stock symbols.
#' The answer is that tiingo expects BRK-B and BF-B, so added the str_replace at the end of the pipe
#' 

adJ_pricing_table <- pricing_table %>% 
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

write_csv(pricing_table, fs::path(base_dir, "data", "pricing_table.csv"))
write_csv(adJ_pricing_table, fs::path(base_dir, "data", "adj_pricing_table.csv"))

#' Now the next 100 uid
#' 
symbols <- all_stocks %>% 
    filter( between( uid, 201, 300) ) %>% 
    pull( symbol ) %>% 
    str_replace("\\.", "\\-" )

pricing_table <- tq_get(symbols, get = "tiingo", from = "1999-12-31", to = "2020-12-31") %>%
    select(symbol, date, close, adjusted, divCash, splitFactor)

save_pricing_table <- pricing_table
# pricing_table <- save_pricing_table

#' This iteration had no errors on tq_get - but also had no tickers in X.B format
#' 

adJ_pricing_table <- pricing_table %>% 
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

write_csv(pricing_table, fs::path(base_dir, "data", "pricing_table.csv"), append = TRUE)
write_csv(adJ_pricing_table, fs::path(base_dir, "data", "adj_pricing_table.csv"), append = TRUE)

#' Now the next 100 uid
#' 
symbols <- all_stocks %>% 
    filter( between( uid, 301, 400) ) %>% 
    pull( symbol ) %>% 
    str_replace("\\.", "\\-" )

pricing_table <- tq_get(symbols, get = "tiingo", from = "1999-12-31", to = "2020-12-31") %>%
    select(symbol, date, close, adjusted, divCash, splitFactor)

save_pricing_table <- pricing_table
# pricing_table <- save_pricing_table

#' This iteration had no errors on tq_get - but also had no tickers in X.B format
#' 

adJ_pricing_table <- pricing_table %>% 
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

write_csv(pricing_table, fs::path(base_dir, "data", "pricing_table.csv"), append = TRUE)
write_csv(adJ_pricing_table, fs::path(base_dir, "data", "adj_pricing_table.csv"), append = TRUE)

#' Now the next 100 uid
#' 
symbols <- all_stocks %>% 
    filter( between( uid, 401, 500) ) %>% 
    pull( symbol ) %>% 
    str_replace("\\.", "\\-" )

pricing_table <- tq_get(symbols, get = "tiingo", from = "1999-12-31", to = "2020-12-31") %>%
    select(symbol, date, close, adjusted, divCash, splitFactor)

save_pricing_table <- pricing_table
# pricing_table <- save_pricing_table

#' This iteration had no errors on tq_get - but also had no tickers in X.B format
#' 

adJ_pricing_table <- pricing_table %>% 
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

write_csv(pricing_table, fs::path(base_dir, "data", "pricing_table.csv"), append = TRUE)
write_csv(adJ_pricing_table, fs::path(base_dir, "data", "adj_pricing_table.csv"), append = TRUE)

#' Now the remaining
#' 
symbols <- all_stocks %>% 
    filter( between( uid, 501, 600) ) %>% 
    pull( symbol ) %>% 
    str_replace("\\.", "\\-" )

#' add on BRK-B and BF-B - which shouldn't be required in the future
#' 
symbols <- c( symbols, "BRK-B", "BF-B" )
#' Lo and behold, this resulted in:
#' 
#' Warning messages:
#' 1: Download failure with ZBRA, removing. See full message below:
#'     lexical error: invalid char in json text.
#'     You have run over your 500 symb
#'     (right here) ------^
#'     
#' Exactly at 500 tickers ... good to know.  Will process these later
#' 


pricing_table <- tq_get(symbols, get = "tiingo", from = "1999-12-31", to = "2020-12-31") %>%
    select(symbol, date, close, adjusted, divCash, splitFactor)

save_pricing_table <- pricing_table
# pricing_table <- save_pricing_table

#' This iteration had no errors on tq_get - but also had no tickers in X.B format
#' 

adJ_pricing_table <- pricing_table %>% 
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

write_csv(pricing_table, fs::path(base_dir, "data", "pricing_table.csv"), append = TRUE)
write_csv(adJ_pricing_table, fs::path(base_dir, "data", "adj_pricing_table.csv"), append = TRUE)

