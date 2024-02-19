#Organization of data: interest rates, spx closing prices, vix and vix futures closing prices, options
getwd()

setwd("C:/Users/Alperen Canbey/Desktop/Academia 3/MRes Thesis/yedek")


library(tidyquant)
library(tidyverse)
library(plotly)
library(fs)


#scraping the yields ##########################################
library(xml2)
library(XML)
library(rvest)

filenames <- list.files("C:/Users/Alperen Canbey/Desktop/yedek/yields", full.names=TRUE)
#yields <- vector(mode = "list", length = 17)
rates <- NA
for (i in c(1:17)){
  page <-read_html(filenames[i])
  persons<-html_nodes(page, xpath = "//*")
  
  fieldnames<-xml_name(xml_find_all(persons, ".//*"))
  fields<-xml_text(xml_find_all(persons, ".//*"))
  df<-data.frame(fieldnames, fields)
  
  
  rates_3m <- subset(df, df$fieldnames == "bc_3month" | df$fieldnames == "new_date")
  rates_new <- as.data.frame(matrix(NA,as.numeric(count(rates_3m))/2,2))
  colnames(rates_new)  <- c("date", "rate")
  
  
  for (j in c(1:length(rates_new[,1]))) {
    rates_new[j,1] <- rates_3m[2*j-1,2]
    rates_new[j,2] <- rates_3m[2*j,2]
  }
  
  rates <- rbind(rates,rates_new)
}

rates <- rates[-1,]
yields <- rates[order(rates$date),]
yields$date <- as.Date(yields$date)
yields$rate <- round(as.numeric(yields$rate),3)

saveRDS(yields, file = "tbills.rds")
###############################################################



#spx prices from yahoo finance#################################
spx_prices  <- tq_get("^GSPC", get = "stock.prices", from = "2004-01-02")
saveRDS(spx_prices, file = "spx_underlying.rds")


spx_prices <- subset(spx_prices, spx_prices$date >=  "2020-01-01")
###############################################################


#CBOE VIX from yahoo finance#################################
vix  <- tq_get("^VIX", get = "stock.prices", from = "2004-01-02", to = "2021-01-01")
saveRDS(vix, file = "vix.rds")
###############################################################




#optiondata from OptionMetrics#################################
install.packages("bit")
library(bit)
library(RSQLite)
library(sqldf)
library(bigmemory)
library(biganalytics)
library(bigtabulate)
library("data.table")
library("readr")

optiondata2000 <- read.csv("optiondata2000.csv")


optiondata <- fread("optiondata.csv",skip = "01/03/2011",
                    select = c("V2", "V3", "V5", "V6", "V7","V8", "V9", "V10", "V11","V12", "V13", "V14", "V15", "V16", "V17"))
colnames(optiondata) <- c("date", "symbol", "exdate", "last_date", "cp_flag", "strike_price", "best_bid", "best_offer"," volume","open_interest", "impl_volatility", "delta","gamma", "vega", "theta")
saveRDS(optiondata, file = "optiondata.rds")
#optiondata.rds 2004 ten beri open interest ve sondaki 3 greek olmadan. 2011 den sonra sumboller kolaylas?yo

optiondata_filtered <- optiondata[!grepl("SPXPM", optiondata$symbol),]
colnames(optiondata_filtered) <- c("date", "symbol", "exdate", "last_date", "cp_flag", "strike_price", "best_bid", "best_offer","volume","open_interest", "impl_volatility", "delta","gamma", "vega", "theta")
optiondata_filtered <- subset(optiondata_filtered, optiondata_filtered$volume > 5)
optiondata_filtered <- subset(optiondata_filtered, optiondata_filtered$date == optiondata_filtered$last_date)

optiondata_filtered$exdate <- as.Date(optiondata_filtered$exdate, format = "%m/%d/%Y")
optiondata_filtered$date <- as.Date(optiondata_filtered$date, format = "%m/%d/%Y")

optiondata_filtered <- optiondata_filtered[!grepl("SPXQ", optiondata_filtered$symbol),]
optiondata_filtered <- optiondata_filtered[!grepl("SPXW", optiondata_filtered$symbol),]
###############################################################




#data for forwards#############################################
library(sqldf)
library(bigmemory)
library(biganalytics)
library(bigtabulate)
library("data.table")
library("readr")

optiondata <- readRDS(file = "optiondata.rds")

optiondata_filtered <- optiondata[grepl("SPXW" | "SPXQ" | "SPXPM" , optiondata$symbol),]
#optiondata_filtered <- optiondata_filtered[!grepl("SPXQ", optiondata_filtered$symbol),]
#optiondata_filtered <- optiondata_filtered[!grepl("SPXPM", optiondata_filtered$symbol),]
colnames(optiondata_filtered) <- c("date", "symbol", "exdate", "last_date", "cp_flag", "strike_price", "best_bid", "best_offer","volume", "impl_volatility", "delta")
optiondata_filtered <- subset(optiondata_filtered, optiondata_filtered$volume > 5)
optiondata_filtered <- subset(optiondata_filtered, optiondata_filtered$date == optiondata_filtered$last_date)

optiondata_filtered$exDates <- as.Date(optiondata_filtered$exdate, format = "%m/%d/%Y")
optiondata_filtered$dates <- as.Date(optiondata_filtered$date, format = "%m/%d/%Y")

saveRDS(optiondata_filtered, file = "optiondata_filtered_new_wVIX.rds")
###############################################################




#extracting the futures data###################################
setwd("C:/Users/Alperen Canbey/Desktop/yedek/VIXfutures")

filenames <- list.files("C:/Users/Alperen Canbey/Desktop/yedek/VIXfutures", full.names=TRUE)
#futures <- vector(mode = "list", length = 108)
futures <- NA
for (i in c(1:108)){
  future <- read.csv(filenames[i])
  futures <- rbind(futures,future)
}

futures <- futures[-1,]
futures <- futures[order(futures$Trade.Date),]
#futures$date <- as.Date(futures$date)
#futures$rate <- round(as.numeric(yields$rate),3)

saveRDS(futures, file = "VIXfutures.rds")
###############################################################