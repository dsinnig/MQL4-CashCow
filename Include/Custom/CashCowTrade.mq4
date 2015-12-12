#property library
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "Trade.mq4"

class CashCowTrade: public Trade {
public: 
   CashCowTrade(int _lotDigits, string _logFileName) : Trade (_lotDigits, _logFileName) {
   }
};