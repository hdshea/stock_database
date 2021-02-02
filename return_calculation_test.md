Stock Database Price and Total Return Calculation Investigation
================
H. David Shea
1 February 2021

## AAPL as our example case

Use tidyqaunt to get price data from tiingo from 31 Dec 1999 through 31
Dec 2020

``` r
aapl_pricing_table <- tq_get("AAPL", get = "tiingo", from = "1999-12-31", to = "2020-12-31")
```

AAPL has had 4 stock splits in that period

2 for 1 on 21 Jun 2000 2 for 1 on 28 Feb 2005 7 for 1 on 9 Jun 2014 4
for 1 on 31 Aug 2020

``` r
aapl_pricing_table %>% 
    filter(splitFactor != 1)
```

    ## # A tibble: 4 x 14
    ##   symbol date                 open  high   low close volume adjusted adjHigh
    ##   <chr>  <dttm>              <dbl> <dbl> <dbl> <dbl>  <int>    <dbl>   <dbl>
    ## 1 AAPL   2000-06-21 00:00:00  50.5  56.9  50.3  55.6 4.38e6    0.857   0.877
    ## 2 AAPL   2005-02-28 00:00:00  44.7  45.1  44.0  44.9 1.16e7    1.38    1.39 
    ## 3 AAPL   2014-06-09 00:00:00  92.7  93.9  91.8  93.7 7.54e7   21.1    21.2  
    ## 4 AAPL   2020-08-31 00:00:00 128.  131   126   129.  2.24e8  129.    131.   
    ## # … with 5 more variables: adjLow <dbl>, adjOpen <dbl>, adjVolume <dbl>,
    ## #   divCash <dbl>, splitFactor <dbl>

AAPL has paid regular quarterly (Feb, May, Aug, Nov) dividends since mid
2012

``` r
aapl_pricing_table %>% 
    filter(divCash != 0)
```

    ## # A tibble: 34 x 14
    ##    symbol date                 open  high   low close volume adjusted adjHigh
    ##    <chr>  <dttm>              <dbl> <dbl> <dbl> <dbl>  <int>    <dbl>   <dbl>
    ##  1 AAPL   2012-08-09 00:00:00 618.  622.  618.  621.  7.92e6     19.2    19.2
    ##  2 AAPL   2012-11-07 00:00:00 574.  575.  556.  558.  2.83e7     17.3    17.9
    ##  3 AAPL   2013-02-07 00:00:00 463.  470   454.  468.  2.52e7     14.6    14.7
    ##  4 AAPL   2013-05-09 00:00:00 460.  463   456.  457.  1.42e7     14.4    14.6
    ##  5 AAPL   2013-08-08 00:00:00 464.  464.  458.  461.  9.13e6     14.6    14.7
    ##  6 AAPL   2013-11-06 00:00:00 524.  525.  518.  521.  7.98e6     16.6    16.7
    ##  7 AAPL   2014-02-06 00:00:00 510.  514.  508.  513.  9.21e6     16.4    16.5
    ##  8 AAPL   2014-05-08 00:00:00 588.  594.  586.  588.  8.22e6     19.0    19.2
    ##  9 AAPL   2014-08-07 00:00:00  94.9  96.0  94.1  94.5 4.67e7     21.4    21.8
    ## 10 AAPL   2014-11-06 00:00:00 109.  109.  108.  109.  3.50e7     24.8    24.8
    ## # … with 24 more rows, and 5 more variables: adjLow <dbl>, adjOpen <dbl>,
    ## #   adjVolume <dbl>, divCash <dbl>, splitFactor <dbl>

New data items:

daily divFactor which can be used to adjust returns for dividend impacts

daily totFactor which accounts for splist and dividend impact in one
factor (needed for total return)

prcAdjFactor adjustment to close for any date so that it can be compared
to any other adjusted close to get price return

totAdjFactor adjustment to close for any date so that it can be compared
to any other adjusted close to get total return

prcReturn which is adjusted one day price return for that date

totReturn which is adjusted one day total return for that date

``` r
aapl_pricing_table <- aapl_pricing_table %>% 
    arrange(desc(date)) %>% 
    mutate(
        divFactor = 1 + divCash / close,
        totFactor = divFactor * splitFactor,
        prcAdjFactor = cumprod(splitFactor),
        totAdjFactor = cumprod(totFactor)
    ) %>% 
    arrange(date) %>% 
    mutate(
        prcReturn = 1 + (((close / prcAdjFactor) / (lag(close / prcAdjFactor, 1))) - 1),
        totReturn = 1 + (((close / totAdjFactor) / (lag(close / totAdjFactor, 1))) - 1)
    )
```

figure out what is wrong here

``` r
aapl_pricing_table %>% 
    filter(date >= '2019-12-31') %>%
    select(totReturn) %>%
    prod() - 1
```

    ## [1] 0.8230921

figure out what is wrong here

``` r
aapl_pricing_table %>% 
    filter(date >= '2019-12-31') %>%
    tq_transmute(adjusted, periodReturn, period = "yearly", col_rename = "return")
```

    ## # A tibble: 1 x 2
    ##   date                return
    ##   <dttm>               <dbl>
    ## 1 2020-12-31 00:00:00  0.782
