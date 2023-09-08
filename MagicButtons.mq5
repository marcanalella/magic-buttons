//+------------------------------------------------------------------+
//|                                                 MagicButtons.mq5 |
//|                                  Copyright 2023, Mario Canalella |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Mario Canalella"
#property link      ""
#property version   "1.01"
#include <Controls/Dialog.mqh>
#include <Controls/Button.mqh>
#include <Trade\SymbolInfo.mqh>
CSymbolInfo symbolInfo;
CAppDialog dialogWindow;
CButton sellButton, buyButton;
input double myProfit = 4.0;
input double myStop = 16.0;
input double riskPercentage = 1.0;
int magicNum = 16741;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   dialogWindow.Create(0, "dialogWindow", 0, 50, 50, 250, 130);
   dialogWindow.Caption("Magic Button");
   sellButton.Create(0, "sellButton", 0,20,10, 90, 40);
   sellButton.Text("Sell");
   dialogWindow.Add(sellButton) ;
   buyButton.Create(0, "buyButton", 0, 100,10,170,40) ;
   buyButton.Text("Buy");
   dialogWindow.Add(buyButton) ;
   dialogWindow.Run() ;
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---

}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {

   dialogWindow.OnEvent(id, lparam, dparam, sparam);
   if (sellButton.Contains((int) lparam, (int) dparam)) {
      sellButton.Pressed(true);
   } else {
      sellButton.Pressed(false);
   }

   if (buyButton.Contains((int) lparam, (int)dparam)) {
      buyButton.Pressed(true);
   } else {
      buyButton.Pressed(false);
   }

   if (id==CHARTEVENT_OBJECT_CLICK && sparam=="sellButton") {
      SendOrder(ORDER_TYPE_SELL, 0);
   }

   if (id==CHARTEVENT_OBJECT_CLICK && sparam=="buyButton") {
      SendOrder(ORDER_TYPE_BUY, 0);
   }
}

//+------------------------------------------------------------------+
//| Expert lot size calculator function                               |
//+------------------------------------------------------------------+
double CalculateLotSize() {
// Calculate the position size.
   double lotSize, lotSize2 = 0;

   double nTickValue = 1.0;
   if ((_Digits == 3) || (_Digits == 5) || (_Digits == 1)) {
      nTickValue = 10.0;
   }
// We apply the formula to calculate the position size and assign the value to the variable.
   lotSize = (AccountInfoDouble(ACCOUNT_BALANCE) * (riskPercentage / 100)) / (myStop * nTickValue);
   //lotSize2 = MathRound(lotSize / MarketInfo(Symbol(), MODE_LOTSTEP)) * MarketInfo(Symbol(), MODE_LOTSTEP);
   Print("lot size = " + (string)lotSize);
   //Print("lot size 2 = " + (string)lotSize2);
   return lotSize;
}

//+------------------------------------------------------------------+
void SendOrder(ENUM_ORDER_TYPE orderType, double price) export {
   MqlTradeRequest request;
   MqlTradeResult result;
   //Nel caso di quotazioni con 3 o con 5 decimali dovremmo moltiplicare per 10
   //i valori ottenuti dai calcoli precedenti
   int P = 1;
   if (_Digits == 5 || _Digits == 3 || _Digits == 1) {
      P = 10;
   }

   double SL;
   double TP;

   ZeroMemory(request);
   request.action = TRADE_ACTION_DEAL;
   request.type = orderType;
   request.magic = magicNum;
   request.symbol = _Symbol;
   if (orderType == ORDER_TYPE_SELL) {
      if(myStop != 0) {
         SL = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID) + myStop * _Point * P, _Digits);
         request.sl = SL;
      }

      if(myProfit != 0) {
         TP = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID) - myProfit * _Point * P, _Digits);
         request.tp = TP;
      }

      if(price != 0) {
         request.price = price;
      } else {
         request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      }
   } else {

      if(myStop != 0) {
         SL = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK) - myStop * _Point * P, _Digits);
         request.sl = SL;
      }

      if(myProfit != 0) {
         TP = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK) + myProfit * _Point * P, _Digits);
         request.tp = TP;
      }

      if(price != 0) {
         request.price = price;
      } else {
         request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      }
   }
   request.volume = CalculateLotSize();
   request.type_filling = ORDER_FILLING_IOC;
   request.deviation = 0;
   ZeroMemory(result);
   Print("[Positions Manager] - SendOrder:\n Type: " + (string)orderType);
   bool order = OrderSend(request, result);
}
//+------------------------------------------------------------------+
