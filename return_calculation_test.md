Stock Database Price and Total Return Calculation Investigation
================
H. David Shea
1 February 2021

## AAPL as our example case

Use tidyqaunt to get price data from tiingo from 31 Dec 1999 through 31
Dec 2020

``` r
aapl_pricing_table <- tq_get("AAPL", get = "tiingo", from = "1999-12-31", to = "2020-12-31") %>%
    select(symbol, date, close, adjusted, divCash, splitFactor)
    
save_aapl_pricing_table <- aapl_pricing_table
# aapl_pricing_table <- save_aapl_pricing_table
#
# use the above for later iterations to avoid repeat hits to tiingo
```

AAPL has had 4 stock splits in that period

2 for 1 on 21 Jun 2000

2 for 1 on 28 Feb 2005

7 for 1 on 9 Jun 2014

4 for 1 on 31 Aug 2020

``` r
aapl_pricing_table %>% 
    filter(splitFactor != 1)
```

    ## # A tibble: 4 x 6
    ##   symbol date                close adjusted divCash splitFactor
    ##   <chr>  <dttm>              <dbl>    <dbl>   <dbl>       <dbl>
    ## 1 AAPL   2000-06-21 00:00:00  55.6    0.857       0        2   
    ## 2 AAPL   2005-02-28 00:00:00  44.9    1.38        0        2   
    ## 3 AAPL   2014-06-09 00:00:00  93.7   21.1         0        7.00
    ## 4 AAPL   2020-08-31 00:00:00 129.   129.          0        4

AAPL has paid regular quarterly (Feb, May, Aug, Nov) dividends since mid
2012

``` r
aapl_pricing_table %>% 
    filter(divCash != 0)
```

    ## # A tibble: 34 x 6
    ##    symbol date                close adjusted divCash splitFactor
    ##    <chr>  <dttm>              <dbl>    <dbl>   <dbl>       <dbl>
    ##  1 AAPL   2012-08-09 00:00:00 621.      19.2    2.65           1
    ##  2 AAPL   2012-11-07 00:00:00 558.      17.3    2.65           1
    ##  3 AAPL   2013-02-07 00:00:00 468.      14.6    2.65           1
    ##  4 AAPL   2013-05-09 00:00:00 457.      14.4    3.05           1
    ##  5 AAPL   2013-08-08 00:00:00 461.      14.6    3.05           1
    ##  6 AAPL   2013-11-06 00:00:00 521.      16.6    3.05           1
    ##  7 AAPL   2014-02-06 00:00:00 513.      16.4    3.05           1
    ##  8 AAPL   2014-05-08 00:00:00 588.      19.0    3.29           1
    ##  9 AAPL   2014-08-07 00:00:00  94.5     21.4    0.47           1
    ## 10 AAPL   2014-11-06 00:00:00 109.      24.8    0.47           1
    ## # … with 24 more rows

New data items:

prcAdjFactor adjustment to close for any date so that it can be compared
to any other adjusted close to get price return

totAdjFactor adjustment to close for any date so that it can be compared
to any other adjusted close to get total return

a few other values are left to make a proper check on adjusted price
calculations - fields into the database table update routines would be
(symbol, date, close, divCash, splitFactor, prcAdjFactor, totAdjFactor)

``` r
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
```

these should match entirely

``` r
aapl_pricing_table %>% 
    filter(date > '1999-12-31') %>% 
    mutate(my_adjusted = close / totAdjFactor) %>%
    tq_transmute(my_adjusted, periodReturn, period = "yearly", col_rename = "return")
```

    ## # A tibble: 21 x 2
    ##    date                return
    ##    <dttm>               <dbl>
    ##  1 2000-12-29 00:00:00 -0.734
    ##  2 2001-12-31 00:00:00  0.472
    ##  3 2002-12-31 00:00:00 -0.346
    ##  4 2003-12-31 00:00:00  0.491
    ##  5 2004-12-31 00:00:00  2.01 
    ##  6 2005-12-30 00:00:00  1.23 
    ##  7 2006-12-29 00:00:00  0.180
    ##  8 2007-12-31 00:00:00  1.33 
    ##  9 2008-12-31 00:00:00 -0.569
    ## 10 2009-12-31 00:00:00  1.47 
    ## # … with 11 more rows

``` r
aapl_pricing_table %>% 
    filter(date > '1999-12-31') %>% 
    tq_transmute(adjusted, periodReturn, period = "yearly", col_rename = "return")
```

    ## # A tibble: 21 x 2
    ##    date                return
    ##    <dttm>               <dbl>
    ##  1 2000-12-29 00:00:00 -0.734
    ##  2 2001-12-31 00:00:00  0.472
    ##  3 2002-12-31 00:00:00 -0.346
    ##  4 2003-12-31 00:00:00  0.491
    ##  5 2004-12-31 00:00:00  2.01 
    ##  6 2005-12-30 00:00:00  1.23 
    ##  7 2006-12-29 00:00:00  0.180
    ##  8 2007-12-31 00:00:00  1.33 
    ##  9 2008-12-31 00:00:00 -0.569
    ## 10 2009-12-31 00:00:00  1.47 
    ## # … with 11 more rows
