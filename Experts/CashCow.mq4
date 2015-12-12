//+------------------------------------------------------------------+
//|                                                      CashCow.mq4 |
//|                                                    Daniel Sinnig |
//|                                            http://www.biiuse.com |
//+------------------------------------------------------------------+
#property copyright "Daniel Sinnig"
#property link      "http://www.biiuse.com"
#property version   "1.00"
#property strict

#include "../Include/Custom/CashCowTrade.mq4"
#include "../Include/Custom/OrderManager.mq4"

input double minMomentumIncrease = 0.001; //Min Momentumzuwachs (KAUFEN)
input string intervalMomentumBUY = "0-5"; //Momentum: Interval als String in format t1-t2 (KAUFEN)

input double minStochasticStart = 30.0; //Min Stochastic bei t1 (KAUFEN)
input string intervalStochasticBUY = "0-5"; //Stochastic: Interval als String in format t1-t2 (KAUFEN)


input string intervalBollingerFallsBUY = "0-5"; //Bollinger sinkt: Interval als String in format t1-t2 (KAUFEN)
input double maxBollingerDistanceBUY = 0.001; //Maximale Distanz (bei t2) des unteren Boll. Bands zum Kurs (KAUFEN)
input int candleBollingerNearPriceBUY = 0; //Kerzenindex wo das Bollinger band in der naehe des Kurses sein muss (KAUFEN)
input int candleBollingerThroughCandleBUY = 1; //Kerzenindex wo das Bollinger band durch die Kerze gehen muss (KAUFEN)

input double maxRSIStart = 30; //Max RSI bei t1 (KAUFEN)
input string intervalRSIBUY = "0-5"; //RSI: Interval als String in format t1-t2 (KAUFEN)

input int requiredHammerFormations = 2; //Anzahl der gruenen Hammerformationen (KAUFEN)
input string intervalHammerFormationsBUY = "1-5"; //Hammerformationen: Interval als String in format t1-t2 (KAUFEN)

input int requiredDojiFormationsBUY = 2; //Anzahl der gruenen Dojiformationen (KAUFEN)
input string intervalDojiFormationsBUY = "1-5"; //Dojiformationen: Interval als String in format t1-t2 (KAUFEN)

input double minMomentumDecrease = 0.001; //Min Momentumverlust in (VERKAUFEN)
input string intervalMomentumSELL = "0-3"; //Momentum: Interval als String in format t5-t6 (VERKAUFEN)

input double maxStochasticStart = 70.0; //Max Stochastic bei t5 (VERKAUFEN)
input string intervalStochasticSELL = "0-3"; //Stochastic: Interval als String in format t5-t6 (VERKAUFEN)

input string intervalBollingerIncreasesSELL = "0-5"; //Bollinger steigt: Interval als String in format t5-t6 (VERKAUFEN)
input double maxBollingerDistanceSELL = 0.001; //Maximale Distanz (bei t2) des unteren Boll. Bands zum Kurs (VERKAUFEN)
input int candleBollingerNearPriceSELL = 0; //Kerzenindex wo das Bollinger band in der naehe des Kurses sein muss (VERKAUFEN)
input int candleBollingerThroughCandleSELL = 1; //Kerzenindex wo das Bollinger band durch die Kerze gehen muss (VERKAUFEN)

input double minRSIStart = 70; //Min RSI bei t5 (VERKAUFEN)
input string intervalRSISELL = "0-3"; //Interval als String in format t5-t6 (VERKAUFEN)

input int requiredHangingManFormations = 2; //Anzahl der roten HangingManformationen (VERKAUFEN)
input string intervalHangingManFormationsSELL = "1-5"; //HangingManformationen: Interval als String in format t5-t6 (VERKAUFEN)

input int requiredDojiFormationsSELL = 2; //Anzahl der roten Dojiformationen (VERKAUFEN)
input string intervalDojiFormationsSELL = "1-5"; //Dojiformationen: Interval als String in format t5-t6 (VERKAUFEN)

input int weightMomentum_BUY = 20; //Wichtung Momentum Kauf
input int weightStochastic_BUY = 20; //Wichtung Stochastic Kauf
input int weightBollingerFalls_BUY = 20; //Wichtung Bollinger Sinkt Kauf
input int weightBollingerNearPrice_BUY = 10; //Wichtung Bollinger ist in Naehe des Kurses Kauf
input int weightBollingerThroughCandle_BUY = 10;  //Wichtung Bollinger geht durch Kerze Kauf
input int weightRSI_BUY = 20; //Wichting RSI Kauf 
input int weightHammer_BUY = 20;
input int weightDoji_BUY = 10;


input int weightMomentum_SELL = 20; //Wichtung Momentum Verkauf
input int weightStochastic_SELL = 20; //Wichtung Stochastic Verkauf
input int weightBollingerIncreases_SELL = 20; //Wichtung Bollinger Sinkt Verkauf
input int weightBollingerNearPrice_SELL = 10; //Wichtung Bollinger ist in Naehe des Kurses Verkauf
input int weightBollingerThroughCandle_SELL = 10;  //Wichtung Bollinger geht durch Kerze Verkauf
input int weightRSI_SELL = 20; //Wichting RSI Verkauf 
input int weightHangingMan_SELL = 20;
input int weightDoji_SELL = 10;


input int buyLimit = 50; //min Punktzahl zum Kaufen
input int sellLimit = 50; //min Punktzahl zum Verkaufen

input double lotSize = 1; // Position size in lots
input double stopLossPips = 500; //Stop loss

string logFileName = Symbol()+"_"+IntegerToString(Period())+"_"+TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS);

int lotDigits = 1; 
Trade* currentLongTrade;
Trade* currentShortTrade;

bool isBullishDoji(int index) {
   const int percentBody = 10;
   if ((MathAbs(Open[index] - Close[index]) <= (High[index] - Low[index]) * percentBody * .01) && (Open[index] < Close[index]))
      return true;
	else return false;
}

bool isBearishDoji(int index) {
   const int percentBody = 10;
   if ((MathAbs(Open[index] - Close[index]) <= (High[index] - Low[index]) * percentBody * .01) && (Close[index] < Open[index]))
      return true;
	else return false;
}

bool isHammer(int index) {
   const double length = 14;
   const double factor = 2; 
   
   double medianPrice = (High[index] - Low[index]) *0.5; 
   double bodyHi = MathMax( Close[index], Open[index]);
   double bodyLo = MathMin( Close[index], Open[index]);
   double body = bodyHi - bodyLo ;

   double priceAvg = 0; 
   
   for (int i = 0; i < length; i++) {
      priceAvg += Close[index+i];
   }
   priceAvg = priceAvg / length;
   
   double bodyAvg = 0;
   
   for (int i = 0; i < length; ++i) {
      double bHi = MathMax( Close[index+i], Open[index+i]);
      double bLo = MathMin( Close[index+i], Open[index+i]);
      double bd = bHi - bLo ;
      bodyAvg += bd;
   }

   bodyAvg = bodyAvg / length;
   
   if ((body < bodyAvg) && // BODY SMALL
       (body > 0) && // ...BUT NOT ZERO...
		 (bodyLo > medianPrice) && // ...AND IN UPPER HALF OF RANGE 
       (bodyLo - Low[index] > factor * body) && //  LOWER SHADOW MUCH LARGER THAN BODY 
       (High[index] - bodyHi < body) && //  UPPER SHADOW SMALLER THAN BODY 
       (Close[index] < priceAvg)) //TREND IS DOWN
   return true; 
   else return false;
}

bool isHangingMan(int index) {
   const double length = 14;
   const double factor = 2; 
   double medianPrice = (High[index] - Low[index]) *0.5; 
   double bodyHi = MathMax( Close[index], Open[index]);
   double bodyLo = MathMin( Close[index], Open[index]);
   double body = bodyHi - bodyLo ;

   double priceAvg = 0; 
   
   for (int i = 0; i < length; i++) {
      priceAvg += Close[index+i];
   }
   priceAvg = priceAvg / length;
   
   double bodyAvg = 0;
   
   for (int i = 0; i < length; ++i) {
      double bHi = MathMax( Close[index+i], Open[index+i]);
      double bLo = MathMin( Close[index+i], Open[index+i]);
      double bd = bHi - bLo ;
      bodyAvg += bd;
   }

   bodyAvg = bodyAvg / length;
   
   if ((body < bodyAvg) && // BODY SMALL
       (body > 0) && // ...BUT NOT ZERO...
		 (bodyLo > medianPrice) && // ...AND IN UPPER HALF OF RANGE 
       (bodyLo - Low[index] > factor * body) && //  LOWER SHADOW MUCH LARGER THAN BODY 
       (High[index] - bodyHi < body) && //  UPPER SHADOW SMALLER THAN BODY 
       (Close[index] > priceAvg)) //TREND IS DOWN
   return true; 
   else return false;
}


int OnInit() {
   currentLongTrade = NULL;
   currentShortTrade = NULL;
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
   delete currentLongTrade;
   delete currentShortTrade;
}

double getMommentum(int shift) {
   return iCustom(NULL, 0, "TSMomentum", 14, 0, shift);
}

double getStochastic(int shift) {
   return iStochastic(NULL, 0, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, shift);
}

double getBollinger(int mode, int shift) {
   return iBands(NULL, 0, 20, 2, 0, PRICE_LOW, mode, shift);
}

double getRSI(int shift) {
   return iRSI(NULL, 0, 14, PRICE_CLOSE, shift);
   
}

void splitInterval(string interval, int& start, int& end) {
   ushort u_sep = StringGetCharacter("-", 0);
   string result[]; 
   int k=StringSplit(interval,u_sep,result);
   start = StrToInteger(result[0]);
   end = StrToInteger(result[1]);
   
}

int sufficentHammerFormationsBUY() {
   int count = 0; 
   int start; 
   int end; 
   splitInterval(intervalHammerFormationsBUY, start, end);
   
   for (int i = start;  i<= end; ++i) {
      if (isHammer(i)) count ++;
   }
   
   if (count >= requiredHammerFormations) {
      Print (count, " Hammerformationen gefunden zwischen Kerzen ", start, " und ", end, " OK");
      return true;
   } else {
      Print (count, " Hammerformationen gefunden zwischen Kerzen ", start, " und ", end, " NO");
      return false; 
   }
}

int sufficentDojiFormationsBUY() {
   int count = 0; 
   int start; 
   int end; 
   splitInterval(intervalDojiFormationsBUY, start, end);
   
   for (int i = start;  i<= end; ++i) {
      if (isBullishDoji(i)) count ++;
   }
   
   if (count >= requiredDojiFormationsBUY) {
      Print (count, " Dojiformationen gefunden zwischen Kerzen ", start, " und ", end, " OK");
      return true;
   } else {
      Print (count, " Dojiformationen gefunden zwischen Kerzen ", start, " und ", end, " NO");
      return false; 
   }
}




int momentumIncreaseBUY() {
   int start; 
   int end; 
   splitInterval(intervalMomentumBUY, start, end);
   double momentum_t1 = getMommentum(end);
   double momentum_t2 = getMommentum(start);
   double diff = momentum_t2 - momentum_t1;
   if ((momentum_t1 < 0) && (momentum_t2 > momentum_t1) && (diff > minMomentumIncrease)) {
      Print ("Mom_t1(", end, "): ", DoubleToString(momentum_t1,5), " Mom_t2(", start, "): ", DoubleToString(momentum_t2,5), " Diff: ", DoubleToString(diff,5), " OK");
      return 1;   
   } else {
      Print ("Mom_t1(", end, "): ", DoubleToString(momentum_t1,5), " Mom_t2(", start, "): ", DoubleToString(momentum_t2,5), " Diff: ", DoubleToString(diff,5), " NO");
      return 0;
   }
}

int stochasticSlowIncreaseBUY() {
   int start; 
   int end; 
   splitInterval(intervalStochasticBUY, start, end);
      
   double stochastic_t1 = getStochastic(end);
   double stochastic_t2 = getStochastic(start);
   
   if ((stochastic_t1 < minStochasticStart) && (stochastic_t1 < stochastic_t2)) {
      Print ("Stoch_t1(", end, "): ", DoubleToString(stochastic_t1,2), " Stoch_t2(", start, "): ", DoubleToString(stochastic_t2,2), " OK");
      return 1;
   } else {
      Print ("Stoch_t1(", end, "): ", DoubleToString(stochastic_t1,2), " Stoch_t2(", start, "): ", DoubleToString(stochastic_t2,2), " NO");
      return 0;
   }
}

int lowerBollingerFallsBUY() {
  int start; 
  int end; 
  splitInterval(intervalBollingerFallsBUY, start, end); 
  double lowerBollinger_t1 = getBollinger(MODE_LOWER, end);
  double lowerBollinger_t2 = getBollinger(MODE_LOWER, start);
  if (lowerBollinger_t2 < lowerBollinger_t1) {
      Print ("Bol_t1(", end, "): ", DoubleToString(lowerBollinger_t1,5), " Bol_t2(", start, "): ", DoubleToString(lowerBollinger_t2,5), " OK");
      return 1;
   } else {
      Print ("Bol_t1(", end, "): ", DoubleToString(lowerBollinger_t1,5), " Bol_t2(", start, "): ", DoubleToString(lowerBollinger_t2,5), " NO");
      return 0;
   }
}

int lowerBollingerNearPriceBUY() {
  double lowerBollinger = getBollinger(MODE_LOWER, candleBollingerNearPriceBUY);
  if ((MathAbs(Open[candleBollingerNearPriceBUY]-lowerBollinger) < maxBollingerDistanceBUY)) {
      Print ("Bol(", candleBollingerNearPriceBUY, "): ", DoubleToString(lowerBollinger,5), " Diff_to_Price: ", DoubleToString(MathAbs(Open[candleBollingerNearPriceBUY]-lowerBollinger),5), " OK");
      return 1;
   } else {
      Print ("Bol(", candleBollingerNearPriceBUY, "): ", DoubleToString(lowerBollinger,5), " Diff_to_Price: ", DoubleToString(MathAbs(Open[candleBollingerNearPriceBUY]-lowerBollinger),5), " NO");
      return 0;
   }
}


int lowerBollingerFallsAndThroughLastCandleBUY() {
  double lowerBollinger = getBollinger(MODE_LOWER, candleBollingerThroughCandleBUY);
  if ((High[candleBollingerThroughCandleBUY] > lowerBollinger) && (Low[candleBollingerThroughCandleBUY] < lowerBollinger)) {
      Print ("Bol(", candleBollingerThroughCandleBUY, "): ", DoubleToString(lowerBollinger,5), " High: ", DoubleToString(High[candleBollingerThroughCandleBUY],5), " Low: ", DoubleToString(Low[candleBollingerThroughCandleBUY],5), " OK");
      return 1;
   } else {
      Print ("Bol(", candleBollingerThroughCandleBUY, "): ", DoubleToString(lowerBollinger,5), " High: ", DoubleToString(High[candleBollingerThroughCandleBUY],5), " Low: ", DoubleToString(Low[candleBollingerThroughCandleBUY],5), " NO");
      return 0;
   }
}


int RSIIncreaseBUY() {
  int start; 
  int end; 
  splitInterval(intervalRSIBUY, start, end);
   double RSI_t1 = getRSI(end);
   double RSI_t2 = getRSI(start);
   
   if ((RSI_t1 < maxRSIStart) && (RSI_t2 > RSI_t1)) {
      Print ("RSI_t1(", end, "): ", RSI_t1, " RSI_t2(", start, "): ", RSI_t2, " OK");
      return 1; 
   } else {
      Print ("RSI_t1(", end, "): ", RSI_t1, " RSI_t2(", start, "): ", RSI_t2, " NO");
      return 0;
   }
}

int momentumDecreaseSELL() {
   int start; 
   int end; 
   splitInterval(intervalMomentumSELL, start, end);
   double momentum_t5 = getMommentum(end);
   double momentum_t6 = getMommentum(start);
   double diff = momentum_t5 - momentum_t6;
   
   if ((momentum_t5 > 0) && (momentum_t5 > momentum_t6) && (diff > minMomentumDecrease)) {
      Print ("Mom_t5(", end, "): ", DoubleToString(momentum_t5,5), " Mom_t6(", start, "): ", DoubleToString(momentum_t6,5), " Diff: ", DoubleToString(diff,5), " OK");
      return 1;   
   } else {
      Print ("Mom_t5(", end, "): ", DoubleToString(momentum_t5,5), " Mom_t6(", start, "): ", DoubleToString(momentum_t6,5), " Diff: ", DoubleToString(diff,5), " NO");
      return 0;
   }
}

int stochasticSlowDecreaseSELL() {
   int start; 
   int end; 
   splitInterval(intervalStochasticSELL, start, end);
   
   double stochastic_t5 = getStochastic(end);
   double stochastic_t6 = getStochastic(start);
   if ((stochastic_t5 > maxStochasticStart) && (stochastic_t6 < stochastic_t5)) {
      Print ("Stoch_t5(", end, "): ", DoubleToString(stochastic_t5,2), " Stoch_t6(", start, "): ", DoubleToString(stochastic_t6,2), " OK");
      return 1;
   } else {
      Print ("Stoch_t5(", end, "): ", DoubleToString(stochastic_t5,2), " Stoch_t6(", start, "): ", DoubleToString(stochastic_t6,2), " NO");
      return 0;
   }
}

int upperBollingerIncreasesSELL() {
  int start; 
  int end; 
  splitInterval(intervalBollingerIncreasesSELL, start, end); 
  double lowerBollinger_t5 = getBollinger(MODE_UPPER, end);
  double lowerBollinger_t6 = getBollinger(MODE_UPPER, start);
  if (lowerBollinger_t6 > lowerBollinger_t5) {
      Print ("Bol_t5(", end, "): ", DoubleToString(lowerBollinger_t5,5), " Bol_t6(", start, "): ", DoubleToString(lowerBollinger_t6,5), " OK");
      return 1;
   } else {
      Print ("Bol_t5(", end, "): ", DoubleToString(lowerBollinger_t5,5), " Bol_t6(", start, "): ", DoubleToString(lowerBollinger_t6,5), " NO");
      return 0;
   }
}

int upperBollingerNearPriceSELL() {
  double lowerBollinger = getBollinger(MODE_UPPER, candleBollingerNearPriceSELL);
  if ((MathAbs(Open[candleBollingerNearPriceSELL]-lowerBollinger) < maxBollingerDistanceSELL)) {
      Print ("Bol(", candleBollingerNearPriceSELL, "): ", DoubleToString(lowerBollinger,5), " Diff_to_Price: ", DoubleToString(MathAbs(Open[candleBollingerNearPriceSELL]-lowerBollinger),5), " OK");
      return 1;
   } else {
      Print ("Bol(", candleBollingerNearPriceSELL, "): ", DoubleToString(lowerBollinger,5), " Diff_to_Price: ", DoubleToString(MathAbs(Open[candleBollingerNearPriceSELL]-lowerBollinger),5), " NO");
      return 0;
   }
}


int upperBollingerFallsAndThroughLastCandleSELL() {
  double lowerBollinger = getBollinger(MODE_LOWER, candleBollingerThroughCandleSELL);
  if ((High[candleBollingerThroughCandleSELL] > lowerBollinger) && (Low[candleBollingerThroughCandleSELL] < lowerBollinger)) {
      Print ("Bol(", candleBollingerThroughCandleSELL, "): ", DoubleToString(lowerBollinger,5), " High: ", DoubleToString(High[candleBollingerThroughCandleSELL],5), " Low: ", DoubleToString(Low[candleBollingerThroughCandleSELL],5), " OK");
      return 1;
   } else {
      Print ("Bol(", candleBollingerThroughCandleSELL, "): ", DoubleToString(lowerBollinger,5), " High: ", DoubleToString(High[candleBollingerThroughCandleSELL],5), " Low: ", DoubleToString(Low[candleBollingerThroughCandleSELL],5), " NO");
      return 0;
   }
}

int RSIDecreaseSELL() {
   int start; 
   int end; 
   splitInterval(intervalRSISELL, start, end);
   double RSI_t5 = getRSI(end);
   double RSI_t6 = getRSI(start);
   
   if ((RSI_t5 > minRSIStart) && (RSI_t6 < RSI_t5)) {
      Print ("RSI_t5(", end, "): ", RSI_t5, " RSI_t6(", start, "): ", RSI_t6, " OK");
      return 1; 
   } else {
      Print ("RSI_t5(", end, "): ", RSI_t5, " RSI_t6(", start, "): ", RSI_t6, " NO");
      return 0;
   }
}

int sufficentHangingManFormationsSELL() {
   int count = 0; 
   int start; 
   int end; 
   splitInterval(intervalHangingManFormationsSELL, start, end);
   
   for (int i = start;  i<= end; ++i) {
      if (isHangingMan(i)) count ++;
   }
   
   if (count >= requiredHangingManFormations) {
      Print (count, " Hanging Man formationen gefunden zwischen Kerzen ", start, " und ", end, " OK");
      return true;
   } else {
      Print (count, " Hanging Man gefunden zwischen Kerzen ", start, " und ", end, " NO");
      return false; 
   }
}

int sufficentDojiFormationsSELL() {
   int count = 0; 
   int start; 
   int end; 
   splitInterval(intervalDojiFormationsSELL, start, end);
   
   for (int i = start;  i<= end; ++i) {
      if (isBearishDoji(i)) count ++;
   }
   
   if (count >= requiredDojiFormationsSELL) {
      Print (count, " Dojiformationen gefunden zwischen Kerzen ", start, " und ", end, " OK");
      return true;
   } else {
      Print (count, " Dojiformationen gefunden zwischen Kerzen ", start, " und ", end, " NO");
      return false; 
   }
}



void OnTick() {
   
   if (currentLongTrade != NULL) {
      //check of stopped out
      bool success=OrderSelect(currentLongTrade.getOrderTicket(),SELECT_BY_TICKET);
      if(OrderCloseTime()!=0) {
         delete GetPointer(currentLongTrade);
         currentLongTrade = NULL;
      }
   }
   
   if (isNewBar()) {
      //nicht im Markt
      if (currentLongTrade == NULL) {
         int score = momentumIncreaseBUY() * weightMomentum_BUY + 
                     stochasticSlowIncreaseBUY() * weightStochastic_BUY +
                     lowerBollingerFallsBUY() * weightBollingerFalls_BUY +
                     lowerBollingerNearPriceBUY() * weightBollingerNearPrice_BUY +
                     lowerBollingerFallsAndThroughLastCandleBUY() * weightBollingerThroughCandle_BUY +
                     RSIIncreaseBUY() * weightRSI_BUY + 
                     sufficentHammerFormationsBUY() * weightHammer_BUY +
                     sufficentDojiFormationsBUY() * weightDoji_BUY;
         
         Print ("Score: ", score);
         if (score >= buyLimit) {
            currentLongTrade = new CashCowTrade(lotDigits, logFileName);
            double factor = OrderManager::getPipConversionFactor(); 
            double stopLoss = Ask - stopLossPips / factor;
            ErrorType result = OrderManager::submitNewOrder(OP_BUY, Ask, stopLoss, 0, 0, lotSize, currentLongTrade);
         }
         
      } else {
         int score = momentumDecreaseSELL() * weightMomentum_SELL + 
                     stochasticSlowDecreaseSELL() * weightStochastic_SELL +
                     upperBollingerIncreasesSELL() * weightBollingerIncreases_SELL +
                     upperBollingerNearPriceSELL() * weightBollingerNearPrice_SELL +
                     upperBollingerFallsAndThroughLastCandleSELL() * weightBollingerThroughCandle_SELL +
                     RSIDecreaseSELL() * weightRSI_SELL +
                     sufficentHangingManFormationsSELL() * weightHangingMan_SELL +
                     sufficentDojiFormationsSELL() * weightDoji_SELL; 
         Print ("Score: ", score);
         if (score >= sellLimit) {
            bool successClose = OrderClose(currentLongTrade.getOrderTicket(), currentLongTrade.getPositionSize(), Bid, 10);
            currentLongTrade.setRealizedPL(OrderProfit());
            currentLongTrade.setOrderCommission(OrderCommission());
            currentLongTrade.setOrderSwap(OrderSwap());
      
            currentLongTrade.setActualClose(OrderClosePrice());
            currentLongTrade.writeLogToCSV();
            delete GetPointer(currentLongTrade);
            currentLongTrade = NULL;
         }                  
      }
   }
}

bool isNewBar() {
   //return true;
   static datetime lastbar=0;
   datetime curbar=Time[0];
   if(lastbar!=curbar) {
      lastbar=curbar;
      return (true);
   }
   else {
      return(false);
   }
}
