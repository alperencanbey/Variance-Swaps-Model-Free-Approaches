#ATM Approach 

fairstrikevol_ATM_func <- function(input) {
  input <- as.data.frame(input)
  colnames(input) <- "data"
  
  newinput <- separate(input, data, into =  c("date", "maturity") , sep = " - ")
  today <- newinput$date
  maturity <- newinput$maturity
  
  today <- as.Date(as.numeric(today))
  maturity <- as.Date(as.numeric(maturity))
  rate <- as.numeric(select(subset(rates, rates$date == today), "rate")) / 100
  diff <- as.numeric(maturity-today) / 365
  underlying <- as.numeric(select(subset(spx_prices, spx_prices$date == today), "close"))
  #forward <- underlying * exp(rate*diff)
  
  options <- subset(optiondata_filtered, optiondata_filtered$exDates == maturity
                    & optiondata_filtered$dates == today
                    & optiondata_filtered$date == last_date
                    & optiondata_filtered$impl_volatility > 0)
  
  options$strike_price <- options$strike_price/1000
  options$price <- (options$best_bid + options$best_offer) /2
  
  
  closingprice <- select(spx_prices, "date")
  closingprice2 <- select(spx_prices, "close")
  closingprice <-  cbind(closingprice ,closingprice2)
  colnames(closingprice) <- c("dates", "close")
  
  
  options <- merge(options, closingprice, by = "dates")
  options$ATM <- options$strike_price - options$close
  
  
  options <- subset(options, abs(options$ATM) < 20) 
  fair_strike <- options[which.min(abs(options$ATM)),]$strike_price
  fair_vol <- options[which.min(abs(options$ATM)),]$impl_volatility*100
  accuracy <- min(abs(options$ATM))
  
  
  datematur_vol <- as.data.frame(cbind(as.Date(today), as.Date(maturity), as.numeric(fair_strike), as.numeric(fair_vol),  as.numeric(accuracy) ))
  datematur_strike <- as.data.frame(paste(datematur_vol$V1, "-", datematur_vol$V2, "-", datematur_vol$V3, "-", datematur_vol$V4, "-", datematur_vol$V5))
  return(datematur_strike = datematur_strike)
  
  #NA gelmesi gerek data maturity e?le?meyenlerden de
}


#ATM

inputt  <- as.matrix(input)
date_maturity_fairstrike_vol_ATM<- list()
date_maturity_fairstrike_vol_ATM <- sapply(inputt, fairstrikevol_ATM_func)

# baz?lar? NA baz?lar NAN?? if NA dont return




five_ATM <- as.data.frame(unlist(date_maturity_fairstrike_vol_ATM))


fairvolatility_ATM <- matrix(NA, length(datelist), length(allmaturities)) 
rownames(fairvolatility_ATM) <- as.character(as.Date(datelist, format = "%Y-%m-%d"))
colnames(fairvolatility_ATM) <- as.character(as.Date(allmaturities, format = "%Y-%m-%d"))
fairvolatility_ATM <- as.data.frame(fairvolatility_ATM)


inputtable_ATM <- as.matrix(five_ATM)

for (i in c(1:length(inputtable_ATM))) {
  input2 <- as.data.frame(inputtable_ATM[i,])
  colnames(input2) <- "data"
  
  newinput <- separate(input2, data, into =  c("date", "maturity", "fairstrike_ATM", "fairvolatility_ATM", "accuracy") , sep = " - ")
  today <- newinput$date
  maturity <- newinput$maturity
  fair_volatility <- newinput$fairvolatility_ATM
  
  today <- as.Date(as.numeric(today))
  maturity <- as.Date(as.numeric(maturity))
  fair_volatility <- as.numeric(fair_volatility)
  
  fairvolatility_ATM[as.character(today),as.character(maturity)] <- fair_volatility
  
}