library(forecast)
library(tseries)
library(openxlsx)
library(ggplot2)
library(quantmod)
library(rusquant)
library(rugarch)
library(rmgarch)
library(HARModel)
library(dplyr)
library(tidyr)

# install.packages('sandwich')
# packageurl <- "https://cran.r-project.org/src/contrib/Archive/HARModel/HARModel_1.0.tar.gz"
# install.packages(packageurl, repos=NULL, type="source")

# загрузка пятиминутных данных по котировкам акции Сбер
intradayData = getSymbols.Moex('SBER', period="5min", from="2020-01-01")

# выделение отдельного поля только даты без времени
intradayData$date <- as.Date(format(intradayData$timestamp, format="%d-%m-%Y"),
                             format="%d-%m-%Y")

# выгрузка в файл, для последующего анализа данных в Rython
write.csv(intradayData, "dataSber.csv")

# добавление колонки с доходностью
intradayData$returns <- c(1, diff(log(intradayData$close)))

# создание датафрейма с дневными данными
dailyDF <- data.frame(date=unique(intradayData$date), RV=0, RQ=0, BPV=0)

# расчет дневной реализованный волатильности
for (i in 1:nrow(dailyDF)){
  thisDate <- dailyDF$date[i]
  tmp <- intradayData[intradayData$date == thisDate, ]
  r <- diff(log(tmp$close))
  
  dailyDF$RV[i] <- sqrt(sum(r^2))
  dailyDF$RQ[i] <- sum(r^4)
  
  rr<-lag(r)
  rr<- rr*r
  rr[1] <- 0
  dailyDF$BPV[i] <-sum(rr)
  
}

plot(intradayData$begin, intradayData$returns, xlab="Дата", ylab="Доходность",
     type = "l", main="Доходность акций Сбера", col="blue", lwd = 2)

## Модель, которую потом будем считать наивным прогнозом
########## sGARCH with norm
# большие хвосты
# Akaike       -9.9299
# Bayes        -9.9295
# Shibata      -9.9299
# Hannan-Quinn -9.9297

spec <- ugarchspec(
  variance.model = list(model="sGARCH", garchOrder = c(1,1)), 
  mean.model = list(armaOrder=c(0, 0)), 
  distribution.model = 'norm'
)
m <- ugarchfit(spec=spec, data=ts(intradayData$returns))
plot(m, which="all")


### перебор основных моделей
metrics <- c("norm", "snorm", "sstd")
#garchModels <- c("GARCH", "TGARCH", "NAGARCH")
garchModels <- c("GARCH")
# Цикл for по каждому элементу списка

for (gar in garchModels) {
  for (metric in metrics) {
    spec <- ugarchspec(variance.model = list(model="fGARCH",
                                          submodel=gar,
                                          garchOrder = c(1,1)), 
                    mean.model = list(armaOrder=c(1, 1)), 
                    distribution.model = metric)
    m <- ugarchfit(spec=spec, data=ts(intradayData$returns))
    print(gar)
    print(metric)
    print(infocriteria(m))
  }
}

# NAGARCH
for (metric in metrics) {
  spec <- ugarchspec(variance.model = list(model="fGARCH",
                                           submodel="NAGARCH",
                                           garchOrder = c(1,1)), 
                     mean.model = list(armaOrder=c(0, 0)), 
                     distribution.model = metric)
  m <- ugarchfit(spec=spec, data=ts(intradayData$returns))
  print(gar)
  print(metric)
  print(infocriteria(m))
}

# eGARCH
for (metric in metrics) {
  spec <- ugarchspec(variance.model = list(model="eGARCH",
                                           garchOrder = c(1,1)), 
                     mean.model = list(armaOrder=c(1, 0)), 
                     distribution.model = metric)
  m <- ugarchfit(spec=spec, data=ts(intradayData$returns))
  print("eGARCH")
  print(metric)
  print(infocriteria(m))
}

### посмотеть на большие хвосты распределений
s <- ugarchspec(variance.model = list(model="sGARCH", garchOrder = c(1,1)), 
                mean.model = list(armaOrder=c(0, 0)), 
                distribution.model = 'snorm')
m <- ugarchfit(spec=s, data=ts(intradayData$returns))
plot(m)

### посмотреть на нормальные хвосты
spec <- ugarchspec(variance.model = list(model="fGARCH",
                                         submodel="TGARCH",
                                         garchOrder = c(1,1)), 
                   mean.model = list(armaOrder=c(1, 0)), 
                   distribution.model = "norm")
m <- ugarchfit(spec=spec, data=ts(intradayData$returns))
plot(m)


### посмотреть на одинаковое влияние новостей
s <- ugarchspec(variance.model = list(model="sGARCH", garchOrder = c(1,1)), 
                mean.model = list(armaOrder=c(0, 0)), 
                distribution.model = 'norm')
m <- ugarchfit(spec=s, data=ts(intradayData$returns))
plot(m, which=12)

### посмотреть на неравномерное влияние новостей
spec <- ugarchspec(variance.model = list(model="fGARCH",
                                         submodel="TGARCH",
                                         garchOrder = c(1,1)), 
                   mean.model = list(armaOrder=c(1, 0)), 
                   distribution.model = "norm")
m <- ugarchfit(spec=spec, data=ts(intradayData$returns))
plot(m)




f <- ugarchforecast(fitORspec = m, n.ahead = 250)
# сонстанта, так как мы заложили это в модели
plot(fitted(f))
# модель ожидает, что волатильность будет расти
plot(sigma(f))

# имея sigma(f) например можно получать вес активка в портфеле 
# в зависимости от его волатильности sqrt(252) * sigma(m)
# вес 0.05 делить на результат где 0.05 волатильность которую мы готовы принять

########## sGARCH with snorm
# Akaike       -1.3834
# Bayes        -1.3826
# Shibata      -1.3834
# Hannan-Quinn -1.3831
# хвосты вообще разлителись
s <- ugarchspec(variance.model = list(model="sGARCH", garchOrder = c(1,1)), 
                mean.model = list(armaOrder=c(0, 0)), 
                distribution.model = 'snorm')
m <- ugarchfit(spec=s, data=ts(intradayData$returns))
m
plot(m, which="all")


# GARCH with sstd
# стали более нормальные хвосты и вырос информационный критерий
s <- ugarchspec(variance.model = list(model="sGARCH", garchOrder = c(1,1)), 
                mean.model = list(armaOrder=c(0, 0)), 
                distribution.model = 'sstd')
m <- ugarchfit(spec=s, data=ts(intradayData$returns))
m
plot(m, which="all")


# sGJR-GARCH with 'sstd'
# модель показывает, что негативные новости влияют на прогноз 
# более существенно, чем позитивные
# Akaike       -1.6271
# Bayes        -1.6260
# Shibata      -1.6271
# Hannan-Quinn -1.6268
s <- ugarchspec(variance.model = list(model="gjrGARCH", garchOrder = c(1,1)), 
                mean.model = list(armaOrder=c(0, 0)), 
                distribution.model = 'sstd')
m <- ugarchfit(spec=s, data=ts(intradayData$returns))
m
plot(m, which="all")


# AR(1) GJR-GARCH with 'sstd'
# ar1 окзаался значимым, качество стало получе но незначитльено
# Akaike       -1.6318
# Bayes        -1.6306
# Shibata      -1.6318
# Hannan-Quinn -1.6315
s <- ugarchspec(variance.model = list(model="gjrGARCH", garchOrder = c(1,1)), 
                mean.model = list(armaOrder=c(1, 0)), 
                distribution.model = 'sstd')
m <- ugarchfit(spec=s, data=ts(intradayData$returns))
m
plot(m, which="all")


# AR(1) TGARCH with 'sstd'
# Akaike       -1.6379
# Bayes        -1.6367
# Shibata      -1.6379
# Hannan-Quinn -1.6376
s <- ugarchspec(variance.model = list(model="fGARCH",
                                      submodel="TGARCH",
                                      garchOrder = c(1,1)), 
                mean.model = list(armaOrder=c(1, 0)), 
                distribution.model = 'sstd')
m <- ugarchfit(spec=s, data=ts(intradayData$returns))
m
plot(m, which="all")
################################


spec <- ugarchspec(variance.model = list(model = "sGARCH", garchOrder = c(1, 1)),
                   mean.model = list(armaOrder = c(0, 0), include.mean = TRUE))

# Подготовка параметров для скользящего окна
window_size <- 10000  # Размер скользящего окна
step_size <- 10000    # Шаг, с которым будет двигаться окно
total_obs <- length(intradayData$returns)

# Инициализация векторов для хранения прогнозов и фактических значений
predictions <- numeric((total_obs - window_size)/step_size)
actuals <- numeric((total_obs - window_size)/step_size)






# Инициализация векторов для хранения прогнозов и фактических значений
predictGARCH <- numeric(5)
actualsGARCH <- numeric(5)

startDate <- as.Date("2024-11-25")
endDate   <- as.Date("2024-11-29")

# выбрать даты, на кторых будем строить прогноз
datesToPredict <- subset(dailyDF, date >= startDate & date <= endDate)
datesToPredict <- datesToPredict$date

# Скользящее прогнозирование с заданным шагом
for (i in seq(1, length(datesToPredict), by = 1)) {

  datesToTrain <- subset(intradayData, date < datesToPredict[i])
  datesToTrain <- datesToTrain$date
  
  oservationsToTrain <- intradayData[intradayData$date  %in% datesToTrain, "returns"]
  
  dateToEstimate <- datesToPredict[i]
  oservationsToTest <- intradayData[intradayData$date  == dateToEstimate, "returns"]
  
  cat(i, " Train size ", length(oservationsToTrain$returns)," Date: ", datesToPredict[i], "\n")
  
  spec <- ugarchspec(variance.model = list(model="fGARCH",
                                           submodel="GARCH",
                                           garchOrder = c(1,1)), 
                     mean.model = list(armaOrder=c(0, 0)), 
                     distribution.model = "norm")
  
  
  fit_roll <- ugarchfit(spec, oservationsToTrain)
  forecast <- ugarchforecast(fit_roll, n.ahead = length(oservationsToTest$returns))
  
  # реализованная волатильность факт
  RV_fact <- sqrt(sum((oservationsToTest)^2))
  # реализованная волатильность прогноз
  RV_predict <- sqrt(sum((forecast@forecast$seriesFor)^2))
  
  predictGARCH[i] <- RV_predict
  actualsGARCH[i] <- RV_fact
}


mae <- mean(abs(predictGARCH - actualsGARCH))
mae
mse <- mean(abs(predictGARCH - actualsGARCH)^2)
mse
mape <- mean(abs(predictGARCH - actualsGARCH)/actualsGARCH)
mape


plot()

plot(forecast)




# Скользящее прогнозирование с заданным шагом
for (i in seq(1, total_obs - window_size, by = step_size)) {
  print(i)
  
  tmp <- ts(intradayData[i:(i + window_size - 1), "returns"]) 
  testDF <- ts(intradayData[(i + window_size - 1):(i + window_size +99) , "returns"])

  fit_roll <- ugarchfit(spec, tmp)
  

  
  RV <- sqrt(sum(log(testDF)^2))
  print(RV)
  # Прогноз следующего значения
  forecast <- ugarchforecast(fit_roll, n.ahead = 100)
  
  #sum(forecast@forecast$seriesFor^2)
  
  # Сохранение прогнозов и фактических значений
  predictions[(i - 1) / step_size + 1] <- as.numeric(sqrt(sum(log(forecast@forecast$seriesFor)^2)))
  actuals[(i - 1) / step_size + 1] <- as.numeric(RV) 
}

# Расчет MAE
mae <- mean(abs(predictions - actuals)/fact)

# Вывод MSE
print(mae)



### Прогноз для HAR
################################


####################
## прогноз модели HAR
DF_RV <- as.xts(dailyDF$RV, order.by = dailyDF$date)

ForecastHAR = HARForecast(DF_RV, periods = c(1,5,22),
                          nRoll = 30, 
                          nAhead = 50, 
                          type = "HAR",
                          windowType="expanding")
plot(ForecastHAR)


ForecastHAR@forecast

# наблидения реальные out-of-sample
factHAR <- ForecastHAR@data$forecastComparison

# прогноз на out-of-sample
predictHAR <- getForc(ForecastHAR)

maeHAR = mean(abs(factHAR-predictHAR))
maeHAR
mseHAR = mean(abs(factHAR-predictHAR)^2)
mseHAR
mapeHAR = mean(abs(factHAR-predictHAR)/factHAR)
mapeHAR

### прогноз модели HARQ
DF_RQ <- as.xts(dailyDF$RQ, order.by = dailyDF$date)
DF_RV <- as.xts(dailyDF$RV, order.by = dailyDF$date)

ForecastHARQ = HARForecast(DF_RV,
                          RQ=DF_RQ,
                          periods = c(1,5,22), 
                          periodsRQ = c(1,5,22),
                          nRoll = 30,
                          nAhead = 50,
                          type ="HARQ",
                          windowType="expanding")

plot(ForecastHARQ)


ForecastHARQ@forecast

# наблидения реальные out-of-sample
factHARQ <- ForecastHARQ@data$forecastComparison

# прогноз на out-of-sample
predictHARQ <- getForc(ForecastHARQ)

maeHARQ = mean(abs(factHARQ-predictHARQ))
maeHARQ
mseHARQ = mean(abs(factHARQ-predictHARQ)^2)
mseHARQ
mapeHARQ = mean(abs(factHARQ-predictHARQ)/factHARQ)
mapeHARQ


### HAR J
DF_RQ <- as.xts(dailyDF$RQ, order.by = dailyDF$date)
DF_RV <- as.xts(dailyDF$RV, order.by = dailyDF$date)
DF_BPV <- as.xts(dailyDF$BPV, order.by = dailyDF$date)


ForecastHARJ = HARForecast(DF_RV, BPV = DF_BPV, periods = c(1,5,22),
                           periodsJ = c(1,5,22) ,nRoll = 30,
                           nAhead = 50, type = "HARJ")

plot(ForecastHARJ)

# наблидения реальные out-of-sample
factHARJ <- ForecastHARJ@data$forecastComparison

# прогноз на out-of-sample
predictHARJ <- getForc(ForecastHARJ)

maeHARJ = mean(abs(factHARJ-predictHARJ))
maeHARJ
mseHARJ = mean(abs(factHARJ-predictHARJ)^2)
mseHARJ
mapeHARJ = mean(abs(factHARJ-predictHARJ)/factHARJ)
mapeHARJ





########################################
# проверить на более волатильных данных
########################################

# загрузка пятиминутных данных по котировкам акции Сбер
intradayDataCovid = getSymbols.Moex('SBER', period="5min", to="2020-03-25", from="2017-01-01")

# выделение отдельного поля только даты без времени
intradayDataCovid$date <- as.Date(format(intradayDataCovid$timestamp, format="%d-%m-%Y"),
                             format="%d-%m-%Y")

# выгрузка в файл, для последующего анализа данных в Rython
write.csv(intradayDataCovid, "dataSber.csv")

# добавление колонки с доходностью
intradayDataCovid$returns <- c(1, diff(log(intradayDataCovid$close)))

# создание датафрейма с дневными данными
dailyDFCovid <- data.frame(date=unique(intradayDataCovid$date), RV=0, RQ=0, BPV=0)

# расчет дневной реализованный волатильности
for (i in 1:nrow(dailyDFCovid)){
  thisDate <- dailyDFCovid$date[i]
  tmp <- intradayDataCovid[intradayDataCovid$date == thisDate, ]
  r <- diff(log(tmp$close))
  
  dailyDFCovid$RV[i] <- sqrt(sum(r^2))
  dailyDFCovid$RQ[i] <- sum(r^4)
  
  rr<-lag(r)
  rr<- rr*r
  rr[1] <- 0
  dailyDFCovid$BPV[i] <-sum(rr)
  
}

####################################################################
### прогноз модели HARQ
DF_RQ <- as.xts(dailyDFCovid$RQ, order.by = dailyDFCovid$date)
DF_RV <- as.xts(dailyDFCovid$RV, order.by = dailyDFCovid$date)
ForecastHARQ = HARForecast(DF_RV,
                           RQ=DF_RQ,
                           periods = c(1,5,22), 
                           periodsRQ = c(1,5,22),
                           nRoll = 30,
                           nAhead = 1,
                           type ="HARQ",
                           windowType="expanding")

plot(ForecastHARQ)

# наблидения реальные out-of-sample
factHARQ <- ForecastHARQ@data$forecastComparison

# прогноз на out-of-sample
predictHARQ <- getForc(ForecastHARQ)

maeHARQ = mean(abs(factHARQ-predictHARQ))
maeHARQ
mseHARQ = mean(abs(factHARQ-predictHARQ)^2)
mseHARQ
mapeHARQ = mean(abs(factHARQ-predictHARQ)/factHARQ)
mapeHARQ
###################################################################

###################################################################
### прогноз HAR
DF_RV <- as.xts(dailyDFCovid$RV, order.by = dailyDFCovid$date)
ForecastHAR = HARForecast(DF_RV, periods = c(1,5,22),
                          nRoll = 30, 
                          nAhead = 50, 
                          type = "HAR",
                          windowType="expanding")
plot(ForecastHAR)
# наблидения реальные out-of-sample
factHAR <- ForecastHAR@data$forecastComparison
# прогноз на out-of-sample
predictHAR <- getForc(ForecastHAR)
maeHAR = mean(abs(factHAR-predictHAR))
maeHAR
mseHAR = mean(abs(factHAR-predictHAR)^2)
mseHAR
mapeHAR = mean(abs(factHAR-predictHAR)/factHAR)
mapeHAR
###################################################################


###################################################################
### HAR J
DF_RQ <- as.xts(dailyDFCovid$RQ, order.by = dailyDFCovid$date)
DF_RV <- as.xts(dailyDFCovid$RV, order.by = dailyDFCovid$date)
DF_BPV <- as.xts(dailyDFCovid$BPV, order.by = dailyDFCovid$date)


ForecastHARJ = HARForecast(DF_RV, BPV = DF_BPV, periods = c(1,5,22),
                           periodsJ = c(1,5,22) ,nRoll = 30,
                           nAhead = 50, type = "HARJ")

plot(ForecastHARJ)

# наблидения реальные out-of-sample
factHARJ <- ForecastHARJ@data$forecastComparison

# прогноз на out-of-sample
predictHARJ <- getForc(ForecastHARJ)

maeHARJ = mean(abs(factHARJ-predictHARJ))
maeHARJ
mseHARJ = mean(abs(factHARJ-predictHARJ)^2)
mseHARJ
mapeHARJ = mean(abs(factHARJ-predictHARJ)/factHARJ)
mapeHARJ
#####################################################################


maeHARQ / maeHAR

#####################################################################
#Посмотреть прогноз GARCH на час вперед










