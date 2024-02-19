
fairvolatility_byprice_func_Fukasawa <- function(input) {
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
  colnames(call_filtered) <- colnames(callordered)
  call_filtered[1,] <- callordered[1,]

  
  k=0
  for (i in c(1:as.numeric(count(callordered)-1) )) {
    if (callordered[(i-k),]$d2 > callordered[i+1,]$d2) {
      call_filtered[(i+1-k),] <- callordered[i+1,]
    }
    else {k= k+1}
  }
  
  
  calls <- as.matrix(call_filtered$strike_price)
  
  
  if (length(puts) > 5 & length(calls) > 5) {
 
 all_options <- rbind(put_filtered, call_filtered)
 all_options <- all_options[order(all_options$d2),]
 
 all_options$impl_variance <- all_options$impl_volatility^2



 
 x <- all_options$d2
 y <- all_options$impl_variance
 
 M <- as.numeric(count(all_options))
 
 
 yx <- vector(mode = "double", M)
 c <- vector(mode = "double", M)
 d <- vector(mode = "double", M)
 l <- vector(mode = "double", M)
 
 A<- vector(mode = "double", M)
 B <- vector(mode = "double", M)
 C<- vector(mode = "double", M)
 D<- vector(mode = "double", M)
 
 sum <- vector(mode = "double", M)
 
 sum[1] <- 0
 yx[1] <- 0
 yx[M] <- 0

 
 for (i in c(2:(M-1))) {
   l[i] <- sqrt( (x[i]-x[i-1])^2 + (y[i]-y[i-1])^2 )
   l[i+1] <- sqrt( (x[i+1]-x[i])^2 + (y[i+1]-y[i])^2 )
   yx[i] <- -( (x[i+1]-x[i])/ l[i+1] - (x[i]-x[i-1])/ l[i]  ) / ( (y[i+1]-y[i])/ l[i+1] - (y[i]-y[i-1])/ l[i]  )

   c[i] <- ( 3*(y[i+1]-y[i]) - (x[i+1]-x[i])*yx[i+1] - 2*(x[i+1]-x[i])*yx[i] ) / (x[i+1]^2-x[i]^2)
   d[i] <- (  (y[i+1]-y[i]) - (x[i+1]-x[i])*yx[i] - c[i]* (x[i+1]^2-x[i]^2) ) /  (x[i+1]^3-x[i]^3)
   
    A[i] <- pnorm(x[i+1]) - pnorm(x[i])
    B[i] <- -( dnorm(x[i+1]) - dnorm(x[i]) ) - x[i]*( pnorm(x[i+1]) - pnorm(x[i]) )
    C[i] <- - ( x[i+1]*dnorm(x[i+1]) - x[i]*dnorm(x[i]) ) + 2*x[i]*( dnorm(x[i+1]) -dnorm(x[i]) )+ (1+x[i]^2)*( pnorm(x[i+1]) - pnorm(x[i]) )
    D[i] <- (1-x[i+1]^2)*dnorm(x[i+1]) - (1-x[i]^2)*dnorm(x[i]) +3*x[i]*( x[i+1]*dnorm(x[i+1]) -x[i]*dnorm(x[i]) ) - 3*(1+x[i]^2) * ( dnorm(x[i+1]) -dnorm(x[i]) ) - x[i]* (3+x[i]^2)*( pnorm(x[i+1]) - pnorm(x[i]) )
   
    sum[i] <- sum[i-1] + abs(y[i]*A[i] + yx[i]*B[i] + c[i]*C[i] + d[i]*D[i])
    
 }
 

 
 i=1
 
value <- sum[M-1] + abs(y[i+1]*pnorm(x[i+1])) + abs(y[M]*(1-pnorm(x[M])))


#Use equation (29) to find total weighted cost of portfolio
portfolio_cost <- value

#Use equation (27) to find fair rate for variance swap
fairprice <- (2/diff)* ( rate*diff  - (underlying*exp(rate*diff)/forward-1) - log(forward/underlying))  + portfolio_cost
#Anaytical estimate of fair volatility
fairvol		   <- 100*(fairprice^0.5)


  
    fair_vol_Fukasawa <- fairvol
  }
  
  else {fair_vol_Fukasawa <- NA}
  
  
  }
  
  else {fair_vol_Fukasawa <- NA}
  
  }
  
  else {fair_vol_Fukasawa <- NA}
  
  }
  
  else {fair_vol_Fukasawa <- NA}
  
  
  DM_vol <- as.data.frame(cbind(as.Date(today), as.Date(maturity), as.numeric(fair_vol_Fukasawa)))
  DM_volatility <- as.data.frame(paste(DM_vol$V1, "-", DM_vol$V2, "-", DM_vol$V3))
  return(DM_volatility_Fukasawa = DM_volatility)
  
  
  #NA gelmesi gerek data maturity e?le?meyenlerden de
}




#Fukasawa

inputt  <- as.matrix(input)
date_maturity_fairvol_Fukasawa<- list()
date_maturity_fairvol_Fukasawa <- sapply(inputt, fairvolatility_byprice_func_Fukasawa)

# baz?lar? NA baz?lar NAN?? if NA dont return




trio_Fukasawa <- as.data.frame(unlist(date_maturity_fairvol_Fukasawa))




fairvolatility_fukasawa <- matrix(NA, length(datelist), length(allmaturities)) 
rownames(fairvolatility_fukasawa) <- as.character(as.Date(datelist, format = "%Y-%m-%d"))
colnames(fairvolatility_fukasawa) <- as.character(as.Date(allmaturities, format = "%Y-%m-%d"))
fairvolatility_fukasawa <- as.data.frame(fairvolatility_fukasawa)


inputtable <- as.matrix(trio_Fukasawa)

for (i in c(1:length(inputtable))) {
  input2 <- as.data.frame(inputtable[i,])
  colnames(input2) <- "data"
  
  newinput <- separate(input2, data, into =  c("date", "maturity", "fairvolatility_fukasawa") , sep = " - ")
  today <- newinput$date
  maturity <- newinput$maturity
  fair_volatility <- newinput$fairvolatility_fukasawa
  
  today <- as.Date(as.numeric(today))
  maturity <- as.Date(as.numeric(maturity))
  fair_volatility <- as.numeric(fair_volatility)
  
  fairvolatility_fukasawa[as.character(today),as.character(maturity)] <- fair_volatility
  
}
