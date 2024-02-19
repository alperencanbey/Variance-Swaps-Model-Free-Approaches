

VarSwap_byprice_CBOE <- function(S, puts, calls, price_put, price_call, r, T, SQ, strike) {
  
  
  nc <- c( max(dim(calls)) )
  np <- c( max(dim(puts)) )
  
  calls_strikes <- matrix(0, 1, nc)
  weight_calls  <- matrix(0, 1, nc)
 
  puts_strikes <- matrix(0, 1, np)
  weight_puts  <- matrix(0, 1, np)
   
  for (i in 2:max( dim(calls) )) {
    weight_calls[i] <- (calls[i] - calls[i-1])/ calls[i]^2
  } 
  
  
  for (i in 1:(max( dim(puts) )-1)) {
    weight_puts[i] <- (puts[i] - puts[i+1])/ puts[i]^2
  } 
  
  x <- max( dim(puts) )
  
  weight_calls[1]<- (calls[1] - puts[1]) / calls[1]^2
  weight_puts[x] <- (puts[x-1] - puts[x])/ puts[x]^2
  
  
  
  #Total value of call portfolio
  call_cost <- c(0)
  
  for ( i in 1:max(dim(calls)) ){
    X <- calls[i]
    price <- price_call[i]
    call_cost <- c( call_cost + price*weight_calls[i] )
   }
  
  
  
  #Total value of put portfolio
  put_cost <- c( 0 )
  
  for (i in (1:max(dim(puts))) ){
    X <- puts[i]
    price <- price_put[i]
    put_cost <- c( put_cost+price*weight_puts[i] )
  }
  
  
  #Use equation (29) to find total weighted cost of portfolio
  portfolio_cost <- put_cost + call_cost
  
  #Use equation (27) to find fair rate for variance swap
  fairprice 	   <- (2/T)*portfolio_cost - (1/T) *(SQ/strike-1)^2
  
  #Anaytical estimate of fair volatility
  fairvol		   <- 100*(fairprice^0.5)
  
  
  return( list(fairvol=fairvol, fairprice=fairprice, total_cost=10000*portfolio_cost, 
               puts_strikes=puts_strikes, puts_weight=weight_puts, 
               calls_strikes=calls_strikes, calls_weight=weight_calls) )
  
}






fairvolatility_byprice_func_CBOE <- function(input) {
  input <- as.data.frame(input)
  colnames(input) <- "data"
  
  newinput <- separate(input, data, into =  c("date", "maturity") , sep = " - ")
  today <- newinput$date
  maturity <- newinput$maturity
  
  today <- as.Date(as.numeric(today))
  maturity <- as.Date(as.numeric(maturity))
  rate <- as.numeric(select(subset(rates, rates$date == today), "rate")) /100
  diff <- as.numeric(maturity-today) /365
  underlying <- as.numeric(select(subset(spx_prices, spx_prices$date == today), "close"))
  
  #to calculate forward > put call parity
  options <- subset(optiondata_filtered, optiondata_filtered$exDates == maturity
                    & optiondata_filtered$dates == today
                    & optiondata_filtered$date == last_date
                    & optiondata_filtered$impl_volatility > 0
                    & optiondata_filtered$best_offer - optiondata_filtered$best_bid < 2)
  options$strike_price <- options$strike_price/1000
  options$price <- (options$best_bid + options$best_offer) /2
  
  farkCP <- vector( mode = "double", as.numeric(count(options)))
  
  if (as.numeric(count(options)) > 0) {
    
    for (i in c(1:as.numeric(count(options)))) {
      pricecomp <- subset(options, options$strike_price == options$strike_price[i])
      farkCP[i] <- abs(pricecomp$price[1] - pricecomp$price[2])
    }
    
    ATMstrike <- options[which.min(farkCP),]$strike_price
    
    c <- subset(options, options$cp_flag == "C" & options$strike_price == ATMstrike) 
    p <- subset(options, options$cp_flag == "P" & options$strike_price == ATMstrike) 
    
    forward <- ATMstrike + exp(rate*diff)*(c[1,]$price  - p[1,]$price)
    if (length(forward) == 1 & diff > 0) {
      #NA geliyosa i?lemi yapma emri verilebilir
      
      putoptions <- subset(optiondata_filtered, optiondata_filtered$exDates == maturity 
                           & cp_flag == "P" 
                           & dates == today
                           & date == last_date 
                           & strike_price/1000 <= ATMstrike
                           & best_bid > 0
                           & best_offer > 0 
                           & best_offer - best_bid < 2
                           & optiondata_filtered$impl_volatility > 0)
      putoptions$strike_price <- putoptions$strike_price/1000
      putoptions$price <- (putoptions$best_bid + putoptions$best_offer) /2
       
      putoptions$d2 <- - ( log(putoptions$strike_price/forward) / (putoptions$impl_volatility*sqrt(diff)) ) - (putoptions$impl_volatility*sqrt(diff) /2)
      
      putoptions <- subset(putoptions, abs(putoptions$d2) > 0)
      
      calloptions <- subset(optiondata_filtered, optiondata_filtered$exDates == maturity 
                            & cp_flag == "C" 
                            & dates == today
                            & date == last_date 
                            & strike_price/1000 > ATMstrike                   
                            & best_bid > 0
                            & best_offer > 0 
                            & best_offer - best_bid < 2
                            & optiondata_filtered$impl_volatility > 0)
      
      calloptions$strike_price <- calloptions$strike_price/1000
      calloptions$price <- (calloptions$best_bid + calloptions$best_offer) /2
      
      calloptions$d2 <- - ( log(calloptions$strike_price/forward) / (calloptions$impl_volatility*sqrt(diff)) ) - (calloptions$impl_volatility*sqrt(diff) /2)
      # parantezler yanl?? calloptions$d2 <- ( (log(underlying/calloptions$strike_price) + (rate -(calloptions$impl_volatility^2)/2)*diff) / calloptions$impl_volatility*sqrt(diff) ) *10
      
      calloptions <- subset(calloptions, abs(calloptions$d2) > 0)
      
      
      if (as.numeric(count(calloptions)) > 2 & as.numeric(count(putoptions)) > 2) {
        
        
        putordered <- putoptions[order(putoptions$strike_price, decreasing = TRUE),]
        put_filtered <- as.data.frame( matrix(NA, nrow = 1, ncol= length(putordered[1,]) ) )
        
        
        callordered <- calloptions[order(calloptions$strike_price),]
        call_filtered <- as.data.frame( matrix(NA, nrow = 1, ncol= length(callordered[1,])) )
        
        
        
        
        
        colnames(put_filtered) <- colnames(putordered)
        
        put_filtered[1,] <- putordered[1,]
        
        
        
        
        
        
        k=0
        for (i in c(1:as.numeric(count(putordered)-1) )) {
          if (putordered[(i-k),]$d2 < putordered[i+1,]$d2) {
            put_filtered[(i+1-k),] <- putordered[i+1,]
          }
          else {k= k+1}
        }
        
        
        
        puts <- as.matrix(put_filtered$strike_price)
        vol_put <- as.matrix(put_filtered$impl_volatility)
        price_put <- as.matrix(put_filtered$price)
        
        
        
        
        colnames(call_filtered) <- colnames(callordered)
        #call_filtered <- callordered
        call_filtered[1,] <- callordered[1,]
        
        
        k=0
        for (i in c(1:as.numeric(count(callordered)-1) )) {
          if (callordered[(i-k),]$d2 > callordered[i+1,]$d2) {
            call_filtered[(i+1-k),] <- callordered[i+1,]
          }
          else {k= k+1}
        }
        
        
        
        
        calls <- as.matrix(call_filtered$strike_price)
        vol_call <- as.matrix(call_filtered$impl_volatility)
        price_call <-  as.matrix(call_filtered$price)
        
        
        
        if (length(puts) > 5 & length(calls) > 5) {
          fair_vol_CBOE <- VarSwap_byprice_CBOE(underlying, puts, calls, price_put, price_call, rate, diff, forward, ATMstrike)$fairvol
        }
        
        else {fair_vol_CBOE <- NA}
        
      }
      
      else {fair_vol_CBOE <- NA}
      
    }
    
    else {fair_vol_CBOE <- NA}
    
    
  }
  
  else {fair_vol_CBOE <- NA}
  
  
  DM_vol <- as.data.frame(cbind(as.Date(today), as.Date(maturity), as.numeric(fair_vol_CBOE)))
  DM_volatility <- as.data.frame(paste(DM_vol$V1, "-", DM_vol$V2, "-", DM_vol$V3))
  return(DM_volatility_CL = DM_volatility)
  
  
}



inputt  <- as.matrix(input)
date_maturity_fairvol_CBOE<- list()
date_maturity_fairvol_CBOE <- sapply(inputt, fairvolatility_byprice_func_CBOE)


trio_CBOE <- as.data.frame(unlist(date_maturity_fairvol_CBOE))


fairvolatility_byprice_CBOE <- matrix(NA, length(datelist), length(allmaturities)) 
rownames(fairvolatility_byprice_CBOE) <- as.character(as.Date(datelist, format = "%Y-%m-%d"))
colnames(fairvolatility_byprice_CBOE) <- as.character(as.Date(allmaturities, format = "%Y-%m-%d"))
fairvolatility_byprice_CBOE <- as.data.frame(fairvolatility_byprice_CBOE)


inputtable_CBOE <- as.matrix(trio_CBOE)

for (i in c(1:length(inputtable_CBOE))) {
  input2 <- as.data.frame(inputtable_CBOE[i,])
  colnames(input2) <- "data"
  
  newinput <- separate(input2, data, into =  c("date", "maturity", "fairvolatility_byprice") , sep = " - ")
  today <- newinput$date
  maturity <- newinput$maturity
  fair_volatility <- newinput$fairvolatility_byprice
  
  today <- as.Date(as.numeric(today))
  maturity <- as.Date(as.numeric(maturity))
  fair_volatility <- as.numeric(fair_volatility)
  
  fairvolatility_byprice_CBOE[as.character(today),as.character(maturity)] <- fair_volatility
  
}


