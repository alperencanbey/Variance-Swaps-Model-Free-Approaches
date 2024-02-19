#Functions to choose relevant maturity to calculate VIX and VIX Futures

maturityfunc <- function(today) {
  matur <- as.matrix(subset(allmaturities, allmaturities > today + 10 & allmaturities < today + 366))
  datevector <- matrix(today,length(matur),1)
  dateofmatur = cbind(as.Date(datevector), as.Date(matur))
  dateofmatur <- as.data.frame(dateofmatur)
  datematur <- as.data.frame(paste(dateofmatur$V1,"-",dateofmatur$V2))
  return(dateofmatur = datematur)
}


maturityfunc <- function(today) {
  matur <- as.matrix(subset(allmaturities, allmaturities > today & allmaturities < today + 366))
  datevector <- matrix(today,length(matur),1)
  dateofmatur = cbind(as.Date(datevector), as.Date(matur))
  dateofmatur <- as.data.frame(dateofmatur)
  datematur <- as.data.frame(paste(dateofmatur$V1,"-",dateofmatur$V2))
  return(dateofmatur = datematur)
}

maturityCalibration <- function(today) {
  matur <- as.matrix(subset(allmaturities, allmaturities == today + 30))
  datevector <- matrix(today,length(matur),1)
  dateofmatur = cbind(as.Date(datevector), as.Date(matur))
  dateofmatur <- as.data.frame(dateofmatur)
  datematur <- as.data.frame(paste(dateofmatur$V1,"-",dateofmatur$V2))
  return(dateofmatur = datematur)
}


