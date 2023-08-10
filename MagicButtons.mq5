//+------------------------------------------------------------------+
//|                                                 MagicButtons.mq5 |
//|                                  Copyright 2023, Mario Canalella |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Mario Canalella"
#property link      ""
#property version   "1.00"
#include <Controls/Dialog.mqh>
#include <Controls/Button.mqh>
#include <Trade\SymbolInfo.mqh>
CSymbolInfo symbolInfo;
CAppDialog dialogWindow;
CButton sellButton, buyButton;
input double TP = 4.0;
input double SL = 16.0;
input double riskPercentage = 1.0;
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
      OpenSell();
   }

   if (id==CHARTEVENT_OBJECT_CLICK && sparam=="buyButton") {
      OpenBuy();
   }
}

//+------------------------------------------------------------------+
//| Expert open sell order function                                  |
//+------------------------------------------------------------------+
void OpenSell() {
   double nTickValue = 1.0;
   if ((_Digits == 3) || (_Digits == 5) || (_Digits == 1)) {
      nTickValue = 10.0;
   }
   Print("nTickValue = " + (string)nTickValue);
   
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   request.action = TRADE_ACTION_DEAL;
   request.type = ORDER_TYPE_SELL;
   request.magic = 16384;
   request.symbol = _Symbol;
   request.price = NormalizeDouble(symbolInfo.Bid(), _Digits);
   request.sl = NormalizeDouble(symbolInfo.Ask() + SL * _Point * nTickValue, _Digits);
   request.tp = NormalizeDouble(symbolInfo.Ask() - TP * _Point * nTickValue, _Digits);
   request.volume = CalculateLotSize();
   request.deviation = 0;
   ZeroMemory(result);
   bool ticket = OrderSend(request, result);
   if(!ticket) {
      Print("OrderSend failed with error #", GetLastError());
   } else {
      Print("OrderSend placed successfully at price= " + (string)request.price + ", lotSize = " + (string)CalculateLotSize() + ", stoploss = " + (string)request.sl + ", takeProfit = " + (string)request.tp);
   }
}

//+------------------------------------------------------------------+
//| Expert open buy order function                                   |
//+------------------------------------------------------------------+
void OpenBuy() {
   double nTickValue = 1.0;
   if ((_Digits == 3) || (_Digits == 5) || (_Digits == 1)) {
      nTickValue = 10.0;
   }
   Print("nTickValue = " + (string)nTickValue);
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   request.action = TRADE_ACTION_DEAL;
   request.type = ORDER_TYPE_BUY;
   request.magic = 16384;
   request.symbol = _Symbol;
   request.price = NormalizeDouble(symbolInfo.Ask(), _Digits);
   request.sl = NormalizeDouble(symbolInfo.Bid() - SL * _Point * nTickValue, _Digits);
   request.tp = NormalizeDouble(symbolInfo.Bid() + TP * _Point * nTickValue, _Digits);
   request.volume = CalculateLotSize();
   request.deviation = 0;
   ZeroMemory(result);
   bool ticket = OrderSend(request, result);
   if(!ticket) {
      Print("OrderSend failed with error #", GetLastError());
   } else {
      Print("OrderSend placed successfully at price= " + (string)request.price + ", lotSize = " + (string)CalculateLotSize() + ", stoploss = " + (string)request.sl + ", takeProfit = " + (string)request.tp);
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
   lotSize = (AccountInfoDouble(ACCOUNT_BALANCE) * (riskPercentage / 100)) / (SL * nTickValue);
   //lotSize2 = MathRound(lotSize / MarketInfo(Symbol(), MODE_LOTSTEP)) * MarketInfo(Symbol(), MODE_LOTSTEP);
   Print("lot size = " + (string)lotSize);
   //Print("lot size 2 = " + (string)lotSize2);
   return lotSize;
  }