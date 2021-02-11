#' ---
#' title: "Other tidyquant Functions to Review"
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

#' tq_index() returns the stock symbol, company name, weight, and sector of every stock in an index. The source is www.ssga.com.
#' 
#' tq_index_options() returns a list of stock indexes you can choose from.
#' 
#' tq_exchange() returns the stock symbol, company, last sale price, market capitalization, sector and industry of every stock in an exchange. Three stock exchanges are available (AMEX, NASDAQ, and NYSE).
#' 
#' tq_exchange_options() returns a list of stock exchanges you can choose from. The options are AMEX, NASDAQ and NYSE.
#' 

#' Important concept: Performance is based on the statistical properties of returns, and as a result this function uses stock or portfolio returns as opposed to stock prices.
#' 
#' tq_performance is a wrapper for various PerformanceAnalytics functions that return portfolio statistics. The main advantage is the ability to scale with the tidyverse.
#' 
#' Ra and Rb are the columns containing asset and baseline returns, respectively. These columns are mapped to the PerformanceAnalytics functions. Note that Rb is not always required, and in these instances the argument defaults to Rb = NULL. The user can tell if Rb is required by researching the underlying performance function.
#' 
#' ... are additional arguments that are passed to the PerformanceAnalytics function. Search the underlying function to see what arguments can be passed through.
#' 
#' tq_performance_fun_options returns a list of compatible PerformanceAnalytics functions that can be supplied to the performance_fun argument.
#' 

#' tq_portfolio is a wrapper for PerformanceAnalytics::Returns.portfolio. The main advantage is the results are returned as a tibble and the function can be used with the tidyverse.
#' 
#' assets_col and returns_col are columns within data that are used to compute returns for a portfolio. The columns should be in "long" format (or "tidy" format) meaning there is only one column containing all of the assets and one column containing all of the return values (i.e. not in "wide" format with returns spread by asset).
#' 
#' weights are the weights to be applied to the asset returns. Weights can be input in one of three options:
#' 
#'- Single Portfolio: A numeric vector of weights that is the same length as unique number of assets. The weights are applied in the order of the assets.
#'     
#'- Single Portfolio: A two column tibble with assets in the first column and weights in the second column. The advantage to this method is the weights are mapped to the assets and any unlisted assets default to a weight of zero.
#'
#'- Multiple Portfolios: A three column tibble with portfolio index in the first column, assets in the second column, and weights in the third column. The tibble must be grouped by portfolio index.
#'
#'tq_repeat_df is a simple function that repeats a data frame n times row-wise (long-wise), and adds a new column for a portfolio index. The function is used to assist in Multiple Portfolio analyses, and is a useful precursor to tq_portfolio.
#'

