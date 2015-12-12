//+------------------------------------------------------------------+
//|                LowestLowReceivedEstablishingEligibilityRange.mq4 |
//|                                                    Daniel Sinnig |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "Trade.mq4"


enum ErrorType { ///Rename to OrderManager
   NO_ERROR,
   RETRIABLE_ERROR,
   NON_RETRIABLE_ERROR
};

class OrderManager {
public:
   static ErrorType analzeAndProcessResult(Trade* trade);
   static ErrorType submitNewOrder(int orderType, double entryPrice, double stopLoss, double takeProfit, double cancelPrice, double positionSize, Trade* trade);
   static ErrorType deleteOrder(int orderTicket, Trade* trade);
   static double getPipConversionFactor();
   static double getPipValue();
   static double getLotSize(double riskCapital, int riskPips);
};

static double OrderManager::getPipValue() {
      double point;
      if (Digits == 5)
         point = Point;
      else 
         point = Point / 10.0;
      Print ("TickSize: ", MarketInfo(Symbol(), MODE_TICKSIZE));
      Print ("TickValue: ", MarketInfo(Symbol(), MODE_TICKVALUE));
      return (MarketInfo(Symbol(), MODE_TICKVALUE) * point) / MarketInfo(Symbol(), MODE_TICKSIZE);
}

static double OrderManager::getLotSize(double riskCapital, int riskPips) {
   double pipValue = OrderManager::getPipValue();
   Print ("Pipvalue: ", pipValue);   
   return riskCapital / ((double) riskPips * pipValue);   
}

static double OrderManager::getPipConversionFactor() {
    //multiplier depending on YEN or non YEN pairs
    if (Digits == 5)
      return 100000.00;
    else
      return 10000.00;
}

static ErrorType OrderManager::submitNewOrder(int orderType, double _entryPrice, double _stopLoss, double _takeProfit, double _cancelPrice, double _positionSize, Trade* trade) {
   int maxSlippage = 4;
   int magicNumber = 0;
   datetime expiration = 0;
   color arrowColor = clrBlue;
   
   double entryPrice = NormalizeDouble(_entryPrice, Digits);
   double stopLoss = NormalizeDouble(_stopLoss, Digits);
   double takeProfit = NormalizeDouble(_takeProfit, Digits);
   double cancelPrice = NormalizeDouble(_cancelPrice, Digits);
   double positionSize = NormalizeDouble(_positionSize, 2);
      
   string orderTypeStr;
   string entryPriceStr = "";
   string stopLossStr = "";
   string takeProfitStr = "";
   string cancelPriceStr = "";
   string positionSizeStr = "";
   
   switch (orderType) {
      case OP_BUY: {orderTypeStr = "BUY Market Order"; break;}
      case OP_SELL: {orderTypeStr = "SELl Market Order"; break;}
      case OP_BUYLIMIT: {
         orderTypeStr = "BUY Limit Order"; 
         if (Ask - entryPrice < MarketInfo(Symbol(),MODE_STOPLEVEL)) {
            trade.addLogEntry("Desired entry price of " + DoubleToString(entryPrice) + " is too close to current Ask of " + DoubleToString(Ask) + " Adjusting to " + DoubleToString(Ask - MarketInfo(Symbol(),MODE_STOPLEVEL)), true);
            entryPrice = Ask - MarketInfo(Symbol(),MODE_STOPLEVEL);
         }
         break;
      }
      case OP_SELLLIMIT: {
         orderTypeStr = "SELL Limit Order"; 
         if (entryPrice - Bid < MarketInfo(Symbol(),MODE_STOPLEVEL)) {
            trade.addLogEntry("Desired entry price of " + DoubleToString(entryPrice) + " is too close to current Bid of " + DoubleToString(Bid) + " Adjusting to " + DoubleToString(Bid + MarketInfo(Symbol(),MODE_STOPLEVEL)), true);
            entryPrice = Bid + MarketInfo(Symbol(),MODE_STOPLEVEL);
         }
         break;
      }
      case OP_BUYSTOP: {
         orderTypeStr = "BUY Stop Order"; 
         //check if entryPrice is too close to market price and adjust accordingly
         
         if (entryPrice - Ask < MarketInfo(Symbol(),MODE_STOPLEVEL)) {
            trade.addLogEntry("Desired entry price of " + DoubleToString(entryPrice) + " is too close to current Ask of " + DoubleToString(Ask) + " Adjusting to " + DoubleToString(Ask + MarketInfo(Symbol(),MODE_STOPLEVEL)), true);
            entryPrice = Ask + MarketInfo(Symbol(),MODE_STOPLEVEL);
         }
         break;
      }
      case OP_SELLSTOP: {
         orderTypeStr = "SELL Stop Order"; 
         if (Bid - entryPrice < MarketInfo(Symbol(),MODE_STOPLEVEL)) {
            trade.addLogEntry("Desired entry price of " + DoubleToString(entryPrice) + " is too close to current Bid of " + DoubleToString(Bid) + " Adjusting to " + DoubleToString(Bid - MarketInfo(Symbol(),MODE_STOPLEVEL)), true);
            entryPrice = Bid - MarketInfo(Symbol(),MODE_STOPLEVEL);
         }
         break;
      }
      default: {trade.addLogEntry("Invalid Order Type. Abort Trade", true); return NON_RETRIABLE_ERROR;}
   }
   
   
   
   
   if (entryPrice != 0) entryPriceStr = "; entry price: " + DoubleToString(entryPrice, Digits);
   if (stopLoss != 0) stopLossStr = "; stop loss: " + DoubleToString(stopLoss, Digits);
   if (takeProfit != 0) takeProfitStr = "; take profit: " + DoubleToString(takeProfit, Digits);
   if (cancelPrice != 0) cancelPriceStr = "; cancel price: " + DoubleToString(cancelPrice, Digits);
   
   positionSizeStr = "; position size: " + DoubleToString(positionSize, 2) + " lots";
   
   trade.addLogEntry("Attemting to place " + orderTypeStr + entryPriceStr + stopLossStr + takeProfitStr + cancelPriceStr + positionSizeStr, true);
   
   int ticket = OrderSend(Symbol(), orderType, positionSize, entryPrice, maxSlippage, stopLoss, takeProfit, trade.getId(), magicNumber, expiration, arrowColor);
   
   ErrorType result = analzeAndProcessResult(trade); 
   
   if (result == NO_ERROR) {
      trade.setPlannedEntry(entryPrice);
      trade.setStopLoss(stopLoss);
      trade.setOriginalStopLoss(stopLoss);
      trade.setTakeProfit(takeProfit);
      trade.setCancelPrice(cancelPrice);
      trade.setPositionSize(positionSize);
      trade.setOrderTicket(ticket);
   }
   return result;
}


static ErrorType OrderManager::deleteOrder(int orderTicket, Trade* trade) {
   trade.addLogEntry("Attemting to delete Order (ticket number: " + IntegerToString(orderTicket) + ")", true);
   ResetLastError();
   bool success=OrderDelete(orderTicket,clrRed);  
   return analzeAndProcessResult(trade);
}


static ErrorType OrderManager::analzeAndProcessResult(Trade* trade) {
   int result=GetLastError();
   switch(result) {
      //No Error
      case 0: return(NO_ERROR);
      // Not crucial errors                  
      case  4:    Alert("Trade server is busy");
                  trade.addLogEntry("Trade server is busy. Waiting 3000ms and then re-try", true);
                  Sleep(3000);
                  return(RETRIABLE_ERROR);
      case 135:   Alert("Price changed. Refreshing Rates");
                  trade.addLogEntry("Price changed. Refreshing Rates and retry", true);
                  RefreshRates();
                  return(RETRIABLE_ERROR);
      case 136:   Alert("No prices. Refreshing Rates and retry");
                  trade.addLogEntry("No prices. Refreshing Rates and retry", true);
                  while(RefreshRates()==false)
                  Sleep(1);
                  return(RETRIABLE_ERROR);
      case 137:   Alert("Broker is busy");
                  trade.addLogEntry("Broker is busy. Waiting 3000ms and then re-try", true);
                  Sleep(3000);
                  return(RETRIABLE_ERROR);
      case 146:   Alert("Trading subsystem is busy.");
                  trade.addLogEntry("Trade system is busy. Waiting 500ms and then re-try", true);
                  Sleep(500);
                  return(RETRIABLE_ERROR);
      // Critical errors      
      case  2:    Alert("Common error.");
                  trade.addLogEntry("Common error. Abort trade", true);
                  return(NON_RETRIABLE_ERROR);
      case  5:    Alert("Old terminal version.");
                  trade.addLogEntry("Old terminal version. Abort trade", true);
                  return(NON_RETRIABLE_ERROR);
      case 64:    Alert("Account blocked.");
                  trade.addLogEntry("Account blocked. Abort trade", true);
                  return(NON_RETRIABLE_ERROR);
      case 133:   Alert("Trading forbidden.");
                  trade.addLogEntry("Trading forbidden. Abort trade", true);
                  return(NON_RETRIABLE_ERROR);
      case 134:   Alert("Not enough money to execute operation.");
                  trade.addLogEntry("Not enough money to execute operation. Abort trade", true);
                  return(NON_RETRIABLE_ERROR);
      case 4108:  Alert("Order ticket was not found. Abort trade");
                  trade.addLogEntry("Order ticket was not found. Abort trade", true);
      default:    Alert("Unknown error, error code: ",result);
                  return(NON_RETRIABLE_ERROR);
   } //end of switch
}
