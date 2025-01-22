
//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#define REC1 "REC1"
#define REC3 "REC3"
#define REC5 "REC5"
#define BTN1 "Button1"
#define BTN2 "Send_Only"
#define BTN3 "Trade_n_Send"
#define TP_HL "TP_HL"
#define SL_HL "SL_HL"
#define PR_HL "PR_HL"

#include <Trade/Trade.mqh>
#include "VirtualTrade.mqh"
#include "methoden.mqh" // Funktionen/Methoden ausgelagert in eine eigene Datei
// Strategy Parameters


bool isWebRequestEnabled = false;
datetime lastMessageTime = 0;


// Discord webhook URL - Replace with your webhook URL
string discord_webhook = LinkChannelM5;
string discord_webhook_test = "https://discord.com/api/webhooks/1328803943068860416/O7dsN4wcNk-vSA9sQQx1ZFzZUAhx8NsPe4JFPxQ4MuQtiOx1BWepkXqSz00ZkCrqiDHw";

//string discord_webhook = "https://discord.com/api/webhooks/1313603118768062575/TPHxceiomoSnyZmp4RZnKtwzM2U4ptc-lTCcnUxj4qqpo1UdXedoyRQaB_Gv-gE9JDSP";
//string discord_webhook_test = "https://discord.com/api/webhooks/1328803943068860416/O7dsN4wcNk-vSA9sQQx1ZFzZUAhx8NsPe4JFPxQ4MuQtiOx1BWepkXqSz00ZkCrqiDHw";


input double DefaultRisk = 0.5; // Risk in %

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



/*
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Get_Price_d(string name)
  {
   return ObjectGetDouble(0, name, OBJPROP_PRICE);
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
string update_Text(string name, string val)
  {
   return (string)ObjectSetString(0, name, OBJPROP_TEXT, val);
  }
*/
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

   double riskMoney = AccountInfoDouble(ACCOUNT_EQUITY) * DefaultRisk / 100;
   double moneyLotstep = (slDistance / ticksize) * tickvalue * lotstep;
   if(moneyLotstep == 0)
     {
      Print(__FUNCTION__, "> Lotsize cannot be calculated");
      return 0;
     }
   double lots = MathFloor(riskMoney / moneyLotstep) * lotstep;
   lots = NormalizeDouble(lots, 2);
   Print(lots);

   return lots;
  }






  
  
  
  /*

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SendDiscordMessageTest(string message, bool isError = false)
  {

   string discord_webhook_save = discord_webhook;
   string discord_webhook =discord_webhook_test;

   return SendDiscordMessage(message,  false);

  }
*/
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getPeriodText()
  {


   if(EnumToString(Period()) == "PERIOD_M2")
      return "M2";

   if(EnumToString(Period()) == "PERIOD_M5")
      return "M5";

   return "H1";

  }


/*
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string FormatSLMessage(VirtualTrade& trade)
  {
   string  message = "@everyone\n";
   message += "**Note:** "+trade.symbol+" Trade "+trade.trade_id+" - has been stopped out\n";

   return message;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string FormatTPMessage(VirtualTrade& trade)
  {
   string  message = "@everyone\n";
   message += "**Note:** "+trade.symbol+" Trade "+trade.trade_id+" - target reached :dollar: \n";

   return message;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string FormatCancelTradeMessage(VirtualTrade& trade)
  {
   string  message = "@everyone\n";
   message += "**Attention:** "+trade.symbol+" Trade "+trade.trade_id+" - cancel the order cause trend is broken\n";

   return message;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string FormatUpdateTradeMessage(VirtualTrade& trade)
  {
   string  message = "@everyone\n";
//message += "**Attention:** "+trade.symbol+" Trade "+trade.trade_id+" - I trail my SL price down to "+trade.stop_loss+" (Sabio: "+tradeInfo.sl+") - Target new: "+tradeInfo.tp+" (Sabio:  "+tradeInfo.tp +")\n";

   return message;
  }
*/
// Gibt den korrekten Webhook für die Zeiteinheit zurück, damit die Messages an den richtigen Discord Server gesendet werden
string get_discord_webhook()
  {
   if(Period()==PERIOD_M2)
     {
      return LinkChannelM2;
     }
   if(Period()==PERIOD_M5)
     {
      return LinkChannelM5;
     }

   Print("Falsche Zeiteinheit "+ EnumToString(Period())+" eingestellt:. Derzeit nur M2 und M5 definiert!");
   return discord_webhook_test;
  }



//+------------------------------------------------------------------+


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
