//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include "discord.mqh" // alles rund ums senden an Discord

input group "=====Money Management====="
input int riskMoney = 250;                                        // Risk Amount in Account Currency


//+------------------------------------------------------------------+
//| Die Funktion erhält den Wert der Höhe des Charts in Pixeln       |
//+------------------------------------------------------------------+
int getChartHeightInPixels(const long chartID = 0, const int subwindow = 0)
  {
//--- Bereiten wir eine Variable, um den Wert der Eigenschaft zu erhalten
   long result = -1;
//--- Setzen den Wert des Fehlers zurück
   ResetLastError();
//--- Erhalten wir den Wert der Eigenschaft
   if(!ChartGetInteger(chartID, CHART_HEIGHT_IN_PIXELS, 0, result))
     {
      //--- Schreiben die Fehlermeldung in den Log "Experten"
      Print(__FUNCTION__ + ", Error Code = ", GetLastError());
     }
//--- Geben den Wert der Eigenschaft zurück
   return ((int)result);
  }

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Die Funktion erhält den Wert der Breite des Charts in Pixeln     |
//+------------------------------------------------------------------+
int getChartWidthInPixels(const long chart_ID = 0)
  {
//--- Bereiten wir eine Variable, um den Wert der Eigenschaft zu erhalten
   long result = -1;
//--- Setzen den Wert des Fehlers zurück
   ResetLastError();
//--- Erhalten wir den Wert der Eigenschaft
   if(!ChartGetInteger(chart_ID, CHART_WIDTH_IN_PIXELS, 0, result))
     {
      //--- Schreiben die Fehlermeldung in den Log "Experten"
      Print(__FUNCTION__ + ", Error Code = ", GetLastError());
     }
//--- Geben den Wert der Eigenschaft zurück
   return ((int)result);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Get_Price_d(string name)
  {
//   return ObjectGetDouble(0, name, OBJPROP_PRICE);
return NormalizeDouble(ObjectGetDouble(0, name, OBJPROP_PRICE, 0), _Digits);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string Get_Price_s(string name)
  {
   return DoubleToString(ObjectGetDouble(0, name, OBJPROP_PRICE), _Digits);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool get_sabio_price(string      &text,        // Text
                     const long   chart_ID=0,  // ID des Charts
                     const string name="Edit") // Objektname
  {
//--- Setzen den Wert des Fehlers zurück
   ResetLastError();
//--- erhalten wir den Text des Objektes
   if(!ObjectGetString(chart_ID,name,OBJPROP_TEXT,0,text))
     {
      Print(__FUNCTION__,
            ": Konnte nicht den Text erhalten! Fehlercode = ",GetLastError());
      return(false);
     }
     Print ("ermittelter Sabio Preis: " + text);
//--- die erfolgreiche Umsetzung
   return(true);
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string update_Text(string name, string val)
  {
   return (string)ObjectSetString(0, name, OBJPROP_TEXT, val);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calcLots(double slDistance)
  {
   double ticksize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickvalue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double lotstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(ticksize == 0 || tickvalue == 0 || lotstep == 0)
     {
      Print(__FUNCTION__, "> Lotsize cannot be calculated");
      return 0;
     }

// double riskMoney = AccountInfoDouble(ACCOUNT_EQUITY) * DefaultRisk / 100;
   double moneyLotstep = (slDistance / ticksize) * tickvalue * lotstep;
   if(moneyLotstep == 0)
     {
      Print(__FUNCTION__, "> Lotsize cannot be calculated");
      return 0;
     }
   double lots = MathFloor(riskMoney / moneyLotstep) * lotstep;
   lots = NormalizeDouble(lots, 2);

   return lots;
  }

  
void DeleteBuyStopOrderForCurrentChart()
  {
   string current_symbol = Symbol(); // Aktuelles Symbol des Charts

   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong order_ticket = OrderGetTicket(i);
      if(OrderSelect(order_ticket))
        {
         string symbol = OrderGetString(ORDER_SYMBOL);
         int type = OrderGetInteger(ORDER_TYPE);

         // Überprüfen, ob die Order zum aktuellen Chart gehört und ein Buy Stop ist
         if(symbol == current_symbol && type == ORDER_TYPE_BUY_STOP)
           {
            // Pending Order löschen
            if(!trade.OrderDelete(order_ticket))
              {
               Print("Fehler beim Löschen der Buy Stop Order. Fehler: ", GetLastError());
              }
            else
              {
               Print("Buy Stop Order für ", symbol, " erfolgreich gelöscht.");
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteSellStopOrderForCurrentChart()
  {
   string current_symbol = Symbol(); // Aktuelles Symbol des Charts

   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong order_ticket = OrderGetTicket(i);
      if(OrderSelect(order_ticket))
        {
         string symbol = OrderGetString(ORDER_SYMBOL);
         int type = OrderGetInteger(ORDER_TYPE);

         // Überprüfen, ob die Order zum aktuellen Chart gehört und ein Buy Stop ist
         if(symbol == current_symbol && type == ORDER_TYPE_SELL_STOP)
           {
            // Pending Order löschen
            if(!trade.OrderDelete(order_ticket))
              {
               Print("Fehler beim Löschen der Sell Stop Order. Fehler: ", GetLastError());
              }
            else
              {
               Print("Sell Stop Order für ", symbol, " erfolgreich gelöscht.");
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
