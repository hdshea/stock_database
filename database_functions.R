#' ---
#' title: "SQLite and SECDB specific function library"
#' author: "H. David Shea"
#' date: "15 February 2021"
#' output: github_document
#' ---
#'
#+ r setup, include = FALSE
library(DBI)
library(RSQLite)
library(tidyverse)
#+

#' Connect to the SECDB database - for testing code only
#' 
#' base_dir <- here::here("")
#' db_file <- fs::path(base_dir, "SECDB")
#' if(dbCanConnect(RSQLite::SQLite(), db_file)) {
#'     secdb <- dbConnect(RSQLite::SQLite(), db_file)
#' }

#' Basic SELECT statement wrapper returning results in a tibble
#' 
db_select_data <- function(con, select_statement ) {
    res <- dbSendQuery(con, select_statement)
    rval <- tibble::tibble(dbFetch(res))
    dbClearResult(res)
    rm(res)
    rval
}

#' Simple generic SELECT from base tables
#' 
db_get_from_table <- function(con, table, where = NULL) {
    db_select_data(con, str_c("SELECT * FROM", table, where, sep = " ") )
}

#' Simple table specific SELECTs from base tables - some with common WHERE clause components
#' 
db_get_universe <- function(con, ...) {
    db_get_from_table(con, "universe", ...)
}

db_get_universe_by_name <- function(con, name) {
    db_get_from_table(con, "universe", where = str_c("WHERE name = '", name, "'", sep = ""))
}

db_get_gics <- function(con, ...) {
    db_get_from_table(con, "gics", ...)
}

db_get_gics_sct <- function(con) {
    db_get_from_table(con, "gics", where = "WHERE level = 'SCT'")
}

db_get_gics_igp <- function(con) {
    db_get_from_table(con, "gics", where = "WHERE level = 'IGP'")
}

db_get_gics_ind <- function(con) {
    db_get_from_table(con, "gics", where = "WHERE level = 'IND'")
}

db_get_gics_sub <- function(con) {
    db_get_from_table(con, "gics", where = "WHERE level = 'SUB'")
}

db_get_security <- function(con, ...) {
    db_get_from_table(con, "security", ...)
}

db_get_security_current <- function(con) {
    db_get_from_table(con, "security", where = "WHERE start_date <= DATE('now') AND end_date > DATE('now')")
}

db_get_security_by_symbol <- function(con, symbol, current = TRUE) {
    date_clause <- NULL
    if(current) { date_clause = "AND start_date <= DATE('now') AND end_date > DATE('now')"}
    symbol_clause <- str_c("symbol = '", symbol, "'", sep = "")
    db_get_from_table(con, "security", 
                      where = str_c("WHERE", symbol_clause, date_clause, sep = " ")
    )
}

db_get_security_price <- function(con, ...) {
    db_get_from_table(con, "security_price", ...)
}

db_get_security_price_by_date <- function(con, date) {
    db_get_from_table(con, "security_price", where = str_c("WHERE effective_date = '", date, "'", sep = ""))
}

db_get_security_price_by_symbol <- function(con, symbol) {
    uid <- db_get_security_by_symbol(con, symbol) %>% pull(uid)
    db_get_from_table(con, "security_price", where = str_c("WHERE uid =", uid, sep = " "))
}

db_get_factor <- function(con, ...) {
    db_get_from_table(con, "factor", ...)
}

db_get_factor_by_name <- function(con, name) {
    db_get_from_table(con, "factor", where = str_c("WHERE name = '", name, "'", sep = ""))
}

db_get_factor_data <- function(con, ...) {
    db_get_from_table(con, "factor_data", ...)
}

db_get_universe_constituent <- function(con, ...) {
    db_get_from_table(con, "universe_constituent", ...)
}

db_get_universe_constituent_by_name <- function(con, name) {
    uid <- db_get_universe_by_name(con, name) %>% pull(uid)
    db_get_from_table(con, "universe_constituent", where = str_c("WHERE universe_uid =", uid, sep = " "))
}

db_get_adjusted_price <- function(con, ...) {
    db_get_from_table(con, "adjusted_price", ...)
}

db_get_adjusted_price_by_date <- function(con, date) {
    db_get_from_table(con, "adjusted_price", where = str_c("WHERE effective_date = '", date, "'", sep = ""))
}

db_get_adjusted_price_by_symbol <- function(con, symbol) {
    uid <- db_get_security_by_symbol(con, symbol) %>% pull(uid)
    db_get_from_table(con, "adjusted_price", where = str_c("WHERE uid =", uid, sep = " "))
}

db_get_gics_matrix <- function(con) {
    sql <- "SELECT  sct.code AS sector_code,
                    igp.code AS industry_group_code,
                    ind.code AS industry_code,
                    sub.code AS sub_industry_code,
                    sct.name AS sector,
                    igp.name AS industry_group,
                    ind.name AS industry,
                    sub.name AS sub_industry
            FROM    gics SUB,
                    (SELECT code, name FROM gics WHERE level = 'IND') IND,
                    (SELECT code, name FROM gics WHERE level = 'IGP') IGP,
                    (SELECT code, name FROM gics WHERE level = 'SCT') SCT
            WHERE   SUB.level = 'SUB'
              AND   SCT.code  = SUBSTR(SUB.code,1,2)
              AND   IGP.code  = SUBSTR(SUB.code,1,4)
              AND   IND.code  = SUBSTR(SUB.code,1,6)
            ORDER BY sub_industry_code;"
    db_select_data(con, sql)
}

#' Holder over function from Citi, Putnam, CRC where we defined peer groups as GICS industry_group
#' except for Energy (10) and Materials (15) where we used GICS industry because there is no differentiation
#' for these two groups at the industry_group level - i.e., they are still Energy and Materials, respectively.
#' 
db_get_peer_group <- function(con) {
    db_get_gics_matrix(con) %>%
        transmute(
            sub_industry_code = sub_industry_code,
            peer_group = ifelse(sector_code %in% c(10, 15), industry, industry_group)
        )
}

db_get_peers_by_symbol <- function(con, in.symbol) {
    db_get_security_current(con) %>% 
        select(-start_date, -end_date) %>% 
        left_join(db_get_peer_group(con), by = "sub_industry_code") %>% 
        filter(peer_group == (.) %>% filter(symbol == in.symbol) %>% pull(peer_group))
}


#' Disconnect from the SECDB database - for testing code only
#' 
# dbDisconnect(secdb)
