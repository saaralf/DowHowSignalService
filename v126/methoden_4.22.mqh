#ifndef DH126_METHODS
#define DH126_METHODS
//+------------------------------------------------------------------+
//| methoden_4.22.mqh                                                |
//+------------------------------------------------------------------+


#include <Trade/Trade.mqh>   // für CTrade

// Das CTrade-Objekt wird in der Hauptdatei definiert:  CTrade trade;
// Broker operations are outside SQLite stage 1.

input group "=====Money Management====="
input int riskMoney = 100; // Risk Amount in Account Currency

//+------------------------------------------------------------------+
//| Chart-Höhe in Pixel                                              |
//+------------------------------------------------------------------+
int getChartHeightInPixels(const long chartID = 0, const int subwindow = 0)
{
   long result = -1;
   ResetLastError();

   if(!ChartGetInteger(chartID, CHART_HEIGHT_IN_PIXELS, subwindow, result))
      Print(__FUNCTION__, ", Error Code = ", GetLastError());

   return (int)result;
}

//+------------------------------------------------------------------+
//| Chart-Breite in Pixel                                            |
//+------------------------------------------------------------------+
int getChartWidthInPixels(const long chartID = 0)
{
   long result = -1;
   ResetLastError();

   if(!ChartGetInteger(chartID, CHART_WIDTH_IN_PIXELS, 0, result))
      Print(__FUNCTION__, ", Error Code = ", GetLastError());

   return (int)result;
}

//+------------------------------------------------------------------+
//| Preis (double) von Objekt                                        |
//+------------------------------------------------------------------+
double Get_Price_d(const string name)
{
   return NormalizeDouble(ObjectGetDouble(0, name, OBJPROP_PRICE, 0), _Digits);
}

//+------------------------------------------------------------------+
//| Preis (string) von Objekt                                        |
//+------------------------------------------------------------------+
string Get_Price_s(const string name)
{
   return DoubleToString(ObjectGetDouble(0, name, OBJPROP_PRICE, 0), _Digits);
}

//+------------------------------------------------------------------+
//| Sabio-Preis-Text holen                                           |
//+------------------------------------------------------------------+
bool get_sabio_price(string &text, const long chart_ID=0, const string name="Edit")
{
   ResetLastError();
   if(!ObjectGetString(chart_ID, name, OBJPROP_TEXT, 0, text))
   {
      Print(__FUNCTION__, ": Konnte nicht den Text erhalten! Fehlercode = ", GetLastError());
      return false;
   }
   Print("ermittelter Sabio Preis: ", text);
   return true;
}

//+------------------------------------------------------------------+
//| Text updaten (korrekter Rückgabetyp: bool)                       |
//+------------------------------------------------------------------+
bool update_Text(const string name, const string val)
{
   return ObjectSetString(0, name, OBJPROP_TEXT, val);
}

//+------------------------------------------------------------------+
//| Lots berechnen                                                   |
//+------------------------------------------------------------------+
double calcLots(const double slDistance)
  {
   double tick=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double value=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   double minimum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maximum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   if(slDistance<=0 || riskMoney<=0 || tick<=0 || value<=0 || step<=0 || minimum<=0 || maximum<minimum) return 0;
   double raw=riskMoney/((slDistance/tick)*value);
   double lots=NormalizeDouble(MathFloor(MathMin(raw,maximum)/step)*step,8);
   if(lots<minimum || lots>maximum || lots>raw+step*0.000001) return 0;
   return lots;
  }
#endif
