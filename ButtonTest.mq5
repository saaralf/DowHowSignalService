//+------------------------------------------------------------------+
//|                                                   ButtonTest.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


#include "discord.mqh"
#include "methoden.mqh"



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  
  if(checkDiscord())
  {
     return(INIT_FAILED);
  }
  
  
  
  
//--- create timer
   EventSetTimer(60);
   
    int x_position = ChartWidthInPixels() - 500 - 20;
    int y_position = ChartHeightInPixelsGet() / 2;
   
   
    ObjectCreate(0, "Button2", OBJ_BUTTON, 0, 0, 0);
        ObjectSetInteger(0, "Button2", OBJPROP_XDISTANCE, x_position); // X position
        ObjectSetInteger(0, "Button2", OBJPROP_XSIZE, 100);                    // width
        ObjectSetInteger(0, "Button2", OBJPROP_YDISTANCE, (int)y_position);       // Y position
        ObjectSetInteger(0, "Button2", OBJPROP_YSIZE, 30);                     // height
        ObjectSetInteger(0, "Button2", OBJPROP_CORNER, 0);                     // chart corner
        ObjectSetString(0, "Button2", OBJPROP_TEXT, "Send only");              // label
        ObjectSetInteger(0, "Button2", OBJPROP_COLOR, clrBlack);
        ObjectSetInteger(0, "Button2", OBJPROP_FONTSIZE, 12);
        ObjectSetInteger(0, "Button2", OBJPROP_BGCOLOR, clrGreen);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  SendDiscordMessageTest("```\nEA stopped. Reason code: " +
                      IntegerToString(reason) + "```");
//--- destroy timer
   EventKillTimer();
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//| TesterInit function                                              |
//+------------------------------------------------------------------+
void OnTesterInit()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| TesterPass function                                              |
//+------------------------------------------------------------------+
void OnTesterPass()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| TesterDeinit function                                            |
//+------------------------------------------------------------------+
void OnTesterDeinit()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---


if (id ==CHARTEVENT_OBJECT_CLICK )
{

   if (sparam=="Button2")
   {
                      ObjectSetInteger(0,"Button2", OBJPROP_BGCOLOR,clrDarkOrange);// Farbe vorübergehend ändern - zur Verdeutlichung, dass der Klick angekommen ist
        Print("senden an Discord");
            SendWebhook();
          
          
           ObjectSetInteger(0,"Button2", OBJPROP_BGCOLOR,clrGreen);// Farbe vorübergehend ändern - zur Verdeutlichung, dass der Klick angekommen ist
   }

}
   
  }
//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
  {
//---
   
  }
//+------------------------------------------------------------------+
