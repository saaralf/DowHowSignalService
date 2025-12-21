//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#ifndef __GUI__
#define __GUI__


// Overview panel internals (keine Abhängigkeit von #define in .mq5 nötig)
#ifndef TA_OVERVIEW_TXT_LONG
   #define TA_OVERVIEW_TXT_LONG  "TA_OVERVIEW_TXT_LONG"
#endif
#ifndef TA_OVERVIEW_TXT_SHORT
   #define TA_OVERVIEW_TXT_SHORT "TA_OVERVIEW_TXT_SHORT"
#endif
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
string update_Text(string name, string val)
  {
   return (string)ObjectSetString(0, name, OBJPROP_TEXT, val);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createEntryAndSLLinien()
  {

   xd3 = getChartWidthInPixels() -DistancefromRight-10;
   yd3 = getChartHeightInPixels()/2;
   xs3 = 280;
   ys3= 30;
   datetime dt_tp = iTime(_Symbol, 0, 0), dt_sl = iTime(_Symbol, 0, 0), dt_prc = iTime(_Symbol, 0, 0);
   double price_tp = iClose(_Symbol, 0, 0), price_sl = iClose(_Symbol, 0, 0), price_prc = iClose(_Symbol, 0, 0);
   int window = 0;

   ChartXYToTimePrice(0, xd3, yd3 + ys3, window, dt_prc, price_prc);
   ChartXYToTimePrice(0, xd5, yd5 + ys5, window, dt_sl, price_sl);

   EnsureHLine(PR_HL, price_prc,color_EntryLine);
   SetPriceOnObject(PR_HL, price_prc);


//createHL(PR_HL, dt_prc, price_prc, EntryLine);

   createButton(EntryButton, "", xd3, yd3, xs3, ys3, PriceButton_font_color, PriceButton_bgcolor, PriceButton_font_size, clrNONE, "Arial Black");

// SL Button
   xd5 = xd3;
   yd5 = yd3 + 100;
   xs5 = xs3;
   ys5 = 30;

   ChartXYToTimePrice(0, xd5, yd5 + ys5, window, dt_sl, price_sl);

   createHL(SL_HL, dt_sl, price_sl, color_SLLine);

   ObjectMove(0, EntryButton, 0, dt_prc, price_prc);


//   DrawHL();
   if(Sabioedit)
     {
      SabioEdit();
     }

   SendButton();
   if(!SendOnlyButton)
     {
      ObjectSetString(0, SENDTRADEBTN, OBJPROP_TEXT, "T & S"); // label
      ObjectSetInteger(0, SENDTRADEBTN, OBJPROP_BGCOLOR, TSButton_bgcolor);
      ObjectSetInteger(0, SENDTRADEBTN, OBJPROP_COLOR, TSButton_font_color);
     }


   createButton(SLButton, "", xd5, yd5, xs5, ys5, SLButton_font_color, SLButton_bgcolor, SLButton_font_size, clrNONE, "Arial Black");
   ObjectMove(0, SLButton, 0, dt_sl, price_sl);

   update_Text(EntryButton, "Buy Stop @ " + Get_Price_s(PR_HL) + " | Lot: " + DoubleToString(NormalizeDouble(calcLots(SL_Price - Entry_Price), 2), 2));
   update_Text(SLButton, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   ChartRedraw(0);
  }





//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MessageButton()
  {

   ObjectCreate(0, "ButtonCancelOrder", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_XDISTANCE, 100);          // X position
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_XSIZE, 150);              // width
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_YDISTANCE, 90 + 30 + 10); // Y position
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_YSIZE, 30);               // height
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_CORNER, 0);               // chart corner
   ObjectSetString(0, "ButtonCancelOrder", OBJPROP_TEXT, "Cancel Buy Order"); // label
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_BGCOLOR, ButtonCancelOrder_bgcolor);
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_COLOR, ButtonCancelOrder_font_color);
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_FONTSIZE, ButtonCancelOrder_font_size);
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_SELECTED, false);
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_COLOR, clrGreen);

   ObjectCreate(0, "ButtonCancelOrderSell", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_XDISTANCE, 100 + 150 + 30); // X position
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_XSIZE, 150);                // width
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_YDISTANCE, 90 + 30 + 10);   // Y position
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_YSIZE, 30);                 // height
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_CORNER, 0);                 // chart corner
   ObjectSetString(0, "ButtonCancelOrderSell", OBJPROP_TEXT, "Cancel Sell Order");  // label
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_BGCOLOR, ButtonCancelOrder_bgcolor);
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_COLOR, ButtonCancelOrder_font_color);
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_FONTSIZE, ButtonCancelOrder_font_size);
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_SELECTED, false);
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_COLOR, clrRed);
  }

//+------------------------------------------------------------------+
//|   Delete all objects                                 |
//+------------------------------------------------------------------+
void deleteObjects()
  {

   ObjectDelete(0, EntryButton);
   ObjectDelete(0, SLButton);

   ObjectDelete(0, SL_HL);
   ObjectDelete(0, PR_HL);
   ObjectDelete(0, "SendOnlyButton");

   ObjectDelete(0, "ButtonStoppedout");
   ObjectDelete(0, "ButtonCancelOrder");

   ObjectDelete(0, "ButtonStoppedoutSell");
   ObjectDelete(0, "ButtonCancelOrderSell");
   ObjectDelete(0, "EingabeTrade");
   ObjectDelete(0, "SabioEntry");

   ObjectDelete(0, "SabioSL");
   ObjectDelete(0, "InfoButtonCancelOrder");
   ObjectDelete(0, "ActiveShortTrade");
   ObjectDelete(0, "InfoButtonStoppedoutSell");
   ObjectDelete(0, "InfoButtonCancelOrderSell");
   ObjectDelete(0, "ActiveLongTrade");
   ObjectDelete(0, "InfoButtonStoppedout");

   ObjectDelete(0, "SL_Long");

   ObjectDelete(0, "SL_Short");

   ObjectDelete(0, "LabelSLLong");

   ObjectDelete(0, "LabelSLShort");
   ObjectDelete(0, "LabelTradenummer");
   ObjectDelete(0, "NotizEdit");
   ObjectDelete(0, "Entry_Long");
   ObjectDelete(0, "Entry_Short");
   ObjectDelete(0, "LabelEntryLong");
   ObjectDelete(0, "LabelEntryShort");

   ChartRedraw(0);
  }
// ================= PERSIST / RESTORE LINE PRICES (SQLite Meta) =================
void DB_SaveLinePrices()
  {
   double p;
   if(ObjectFind(0, PR_HL) >= 0)
     {
      p = ObjectGetDouble(0, PR_HL, OBJPROP_PRICE);
      DB_SetMetaText(DB_Key("price_entry"), DoubleToString(p, _Digits));
     }

   if(ObjectFind(0, SL_HL) >= 0)
     {
      p = ObjectGetDouble(0, SL_HL, OBJPROP_PRICE);
      DB_SetMetaText(DB_Key("price_sl"), DoubleToString(p, _Digits));
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CreateEntryAndSLLines(string objName, datetime time1, double price1, color clr)
  {
   ResetLastError();

// existiert schon? -> nur updaten
   if(ObjectFind(0, objName) >= 0)
     {
      ObjectSetDouble(0, objName, OBJPROP_PRICE, price1);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(0, objName, OBJPROP_BACK, false);
      ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
      ChartRedraw(0);
      return true;
     }

// neu erstellen
   if(!ObjectCreate(0, objName, OBJ_HLINE, 0, time1, price1))
     {
      Print(__FUNCTION__, ": Failed to create ", objName, " err=", GetLastError());
      return false;
     }

   ObjectSetDouble(0, objName, OBJPROP_PRICE, price1);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);

   ChartRedraw(0);
   return true;
  }

//+------------------------------------------------------------------+
//| Create Line Labels
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateLabelsTPcolor_SLLines(string LABEL_NAME, string text, double price2, color clr1)
  {
   ResetLastError();

// Nur erzeugen, wenn das Objekt noch nicht existiert
   if(ObjectFind(0, LABEL_NAME) < 0)
     {
      if(!ObjectCreate(0, LABEL_NAME, OBJ_TEXT, 0, TimeCurrent(), price2))
        {
         Print(__FUNCTION__, ": Failed to create ", LABEL_NAME, " Error Code: ", GetLastError());
         return; // raus bei Fehler
        }

      // Grund-Layout nur beim ersten Erzeugen
      ObjectSetInteger(0, LABEL_NAME, OBJPROP_COLOR, clr1);
      ObjectSetInteger(0, LABEL_NAME, OBJPROP_FONTSIZE, 12);
      ObjectSetString(0, LABEL_NAME, OBJPROP_TEXT, " ");
     }
   else
     {
      // Falls sich der Preis geändert hat: Label-Position anpassen
      ObjectMove(0, LABEL_NAME, 0, TimeCurrent(), price2);
     }

// Kein ChartRedraw() hier – das ist auf Dauer zu teuer.
// Text wird wie bisher über update_Text() gesetzt.
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateLabelsLong()
  {

   CreateLabelsTPcolor_SLLines(LabelSLLong, "SL Long Trade", SL_Price, Tradecolor_SLLineLong);
   CreateLabelsTPcolor_SLLines(LabelEntryLong, "Entry Long Trade", Entry_Price, TradeEntryLineLong);

   update_Text(LabelSLLong, "SL Long Trade");
   update_Text(LabelEntryLong, "Entry Long Trade");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateLabelsShort()
  {

   CreateLabelsTPcolor_SLLines(LabelSLShort, "SL Short Trade", SL_Price, Tradecolor_SLLineShort);
   CreateLabelsTPcolor_SLLines(LabelEntryShort, "Entry Short Trade", Entry_Price, TradeEntryLineShort);

   update_Text(LabelSLShort, "SL Short Trade");
   update_Text(LabelEntryShort, "Entry Short Trade");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetLinePrice(const string name, double price)
  {
   ObjectSetDouble(0, name, OBJPROP_PRICE, price);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteLinesandLabelsShort()
  {
// löscht alle Objekte, die zu SHORT-Trade-Linien/Labels gehören (inkl. _1.._4)
   string prefixes[] = {"TP_Short", "SL_Short", "Entry_Short", "LabelTPShort", "LabelSLShort", "LabelEntryShort"};
   int total = ObjectsTotal(0, -1, -1);
   for(int i = total - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i, -1, -1);
      for(int p = 0; p < ArraySize(prefixes); p++)
        {
         if(StringFind(name, prefixes[p]) == 0)
           {
            ObjectDelete(0, name);
            break;
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteLinesandLabelsLong()
  {
// löscht alle Objekte, die zu LONG-Trade-Linien/Labels gehören (inkl. _1.._4)
   string prefixes[] = {"TP_Long", "SL_Long", "Entry_Long", "LabelTPLong", "LabelSLLong", "LabelEntryLong"};
   int total = ObjectsTotal(0, -1, -1);
   for(int i = total - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i, -1, -1);
      for(int p = 0; p < ArraySize(prefixes); p++)
        {
         if(StringFind(name, prefixes[p]) == 0)
           {
            ObjectDelete(0, name);
            break;
           }
        }
     }
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteBuyStopOrderForCurrentChart()
  {
   string current_symbol = Symbol(); // Aktuelles Symbol des Charts

   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong order_ticket = OrderGetTicket(i);
      if(OrderSelect(order_ticket))
        {
         string symbol = OrderGetString(ORDER_SYMBOL);
         long type = OrderGetInteger(ORDER_TYPE);

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
         long type = OrderGetInteger(ORDER_TYPE);

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
//| Create Trading Button                                                                 |
//+------------------------------------------------------------------+
bool createButton(string objName, string text, int xD, int yD, int xS, int yS, color clrTxt, color clrBG, int fontsize = 12, color clrBorder = clrNONE, string font = "Calibri")
  {
   ResetLastError();
   if(!ObjectCreate(0, objName, OBJ_BUTTON, 0, 0, TimeCurrent()))
     {
      Print(__FUNCTION__, ": Failed to create Btn: Error Code: ", GetLastError());
      return (false);
     }
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, xD);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, yD);
   ObjectSetInteger(0, objName, OBJPROP_XSIZE, xS);
   ObjectSetInteger(0, objName, OBJPROP_YSIZE, yS);
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, fontsize);
   ObjectSetString(0, objName, OBJPROP_FONT, font);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrTxt);
   ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, clrBG);
   ObjectSetInteger(0, objName, OBJPROP_BORDER_COLOR, clrBorder);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_STATE, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_CENTER);

   ChartRedraw(0);
   return (true);
  }

//+------------------------------------------------------------------+
//| Create Preislinien Trading Buttton                                                                 |
//+------------------------------------------------------------------+
bool createHL(string objName, datetime time1, double price1, color clr)
  {
   ResetLastError();
   if(!ObjectCreate(0, objName, OBJ_HLINE, 0, time1, price1))
     {
      Print(__FUNCTION__, ": Failed to create HL: Error Code: ", GetLastError());
      return (false);
     }
   ObjectSetInteger(0, objName, OBJPROP_TIME, time1);
   ObjectSetDouble(0, objName, OBJPROP_PRICE, price1);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);

   ChartRedraw(0);
   return (true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SendButton()
  {
// optional aber empfohlen (OnInit ruft SendButton teils doppelt auf):
   ObjectDelete(0, SENDTRADEBTN);
   ObjectDelete(0, TRNB);
   ObjectDelete(0, POSNB);

   ObjectCreate(0, SENDTRADEBTN, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, SENDTRADEBTN, OBJPROP_XDISTANCE, xd3 - 100);
   ObjectSetInteger(0, SENDTRADEBTN, OBJPROP_XSIZE, 100);
   ObjectSetInteger(0, SENDTRADEBTN, OBJPROP_YDISTANCE, yd3);
   ObjectSetInteger(0, SENDTRADEBTN, OBJPROP_YSIZE, 30);
   ObjectSetInteger(0, SENDTRADEBTN, OBJPROP_CORNER, 0);
   if(!SendOnlyButton)
     {
      ObjectSetString(0, SENDTRADEBTN, OBJPROP_TEXT, "T & S"); // label
      ObjectSetInteger(0, SENDTRADEBTN, OBJPROP_BGCOLOR, TSButton_bgcolor);
      ObjectSetInteger(0, SENDTRADEBTN, OBJPROP_COLOR, TSButton_font_color);
     }
   else
     {
      ObjectSetString(0, SENDTRADEBTN, OBJPROP_TEXT, "Send only"); // label
      ObjectSetInteger(0, SENDTRADEBTN, OBJPROP_BGCOLOR, SendOnlyButton_bgcolor);
      ObjectSetInteger(0, SENDTRADEBTN, OBJPROP_COLOR, SendOnlyButton_font_color);
     }
   ObjectSetInteger(0, SENDTRADEBTN, OBJPROP_FONTSIZE, SendOnlyButton_font_size);

// TRNB (TradeNo) links
   ObjectCreate(0, TRNB, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, TRNB, OBJPROP_XDISTANCE, xd3 - 100);
   ObjectSetInteger(0, TRNB, OBJPROP_YDISTANCE, yd3 + 30);
   ObjectSetInteger(0, TRNB, OBJPROP_XSIZE, 60);
   ObjectSetInteger(0, TRNB, OBJPROP_YSIZE, 30);
   ObjectSetString(0, TRNB, OBJPROP_TEXT, "0");
   ObjectSetInteger(0, TRNB, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, TRNB, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, TRNB, OBJPROP_ALIGN, ALIGN_CENTER);
   ObjectSetInteger(0, TRNB, OBJPROP_READONLY, false);

// POSNB (PosNo) rechts daneben
   ObjectCreate(0, POSNB, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, POSNB, OBJPROP_XDISTANCE, xd3 - 40);
   ObjectSetInteger(0, POSNB, OBJPROP_YDISTANCE, yd3 + 30);
   ObjectSetInteger(0, POSNB, OBJPROP_XSIZE, 40);
   ObjectSetInteger(0, POSNB, OBJPROP_YSIZE, 30);
   ObjectSetString(0, POSNB, OBJPROP_TEXT, "1");
   ObjectSetInteger(0, POSNB, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, POSNB, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, POSNB, OBJPROP_ALIGN, ALIGN_CENTER);
   ObjectSetInteger(0, POSNB, OBJPROP_READONLY, false);

   ObjectCreate(0, "ActiveLongTrade", OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_XDISTANCE, 100);
   ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_YDISTANCE, 90);
//--- Objektgröße setzen
   ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_XSIZE, 150);
   ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_YSIZE, 30);
//--- den Text setzen
   ObjectSetString(0, "ActiveLongTrade", OBJPROP_TEXT, "");
//--- Schriftgröße setzen
   ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_BGCOLOR, clrNONE);
   ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_COLOR, clrNONE);
   ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_FONTSIZE, InfoTradenummerFontSize);
   ObjectSetString(0, "ActiveLongTrade", OBJPROP_FONT, "Arial");

// Info Button ActiveShortTrade
   ObjectCreate(0, "ActiveShortTrade", OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_XDISTANCE, 100 + 150 + 30);
   ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_YDISTANCE, 90);
//--- Objektgröße setzen
   ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_XSIZE, 150);
   ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_YSIZE, 30);
//--- den Text setzen
   ObjectSetString(0, "ActiveShortTrade", OBJPROP_TEXT, "");
//--- Schriftgröße setzen
   ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_BGCOLOR, clrNONE);
   ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_COLOR, clrNONE);
   ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_FONTSIZE, InfoTradenummerFontSize);
   ObjectSetString(0, "ActiveShortTrade", OBJPROP_FONT, "Arial");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SabioEdit()
  {

// SabioSLEdit
   ObjectCreate(0, SabioSL, OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0, SabioSL, OBJPROP_XDISTANCE, xd5);
   ObjectSetInteger(0, SabioSL, OBJPROP_YDISTANCE, yd5 + 30);
//--- Objektgröße setzen
   ObjectSetInteger(0, SabioSL, OBJPROP_XSIZE, 280);
   ObjectSetInteger(0, SabioSL, OBJPROP_YSIZE, 30);
//--- den Text setzen
   ObjectSetString(0, SabioSL, OBJPROP_TEXT, "SABIO SL: " + Get_Price_s(SL_HL));
//--- Schriftgröße setzen
   ObjectSetInteger(0, SabioSL, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, SabioSL, OBJPROP_COLOR, clrBlack);

//--- aktivieren (true) oder deaktivieren (false) den schreibgeschützten Modus
   ObjectSetInteger(0, TRNB, OBJPROP_READONLY, false);

// SabioEntryEdit
   ObjectCreate(0, SabioEntry, OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0, SabioEntry, OBJPROP_XDISTANCE, xd3);
   ObjectSetInteger(0, SabioEntry, OBJPROP_YDISTANCE, yd3 + 30);
//--- Objektgröße setzen
   ObjectSetInteger(0, SabioEntry, OBJPROP_XSIZE, 280);
   ObjectSetInteger(0, SabioEntry, OBJPROP_YSIZE, 30);
//--- den Text setzen
   ObjectSetString(0, SabioEntry, OBJPROP_TEXT, "SABIO ENTRY: " + Get_Price_s(PR_HL));
//--- Schriftgröße setzen
   ObjectSetInteger(0, SabioEntry, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, SabioEntry, OBJPROP_COLOR, clrBlack);

//--- aktivieren (true) oder deaktivieren (false) den schreibgeschützten Modus
   ObjectSetInteger(0, TRNB, OBJPROP_READONLY, false);
  }


// ================= OVERVIEW PANEL (LONG | SHORT) =================
// Bestimmt die Y-Position unterhalb der Cancel-Buttons.
int UI_GetOverviewTopY()
  {
   int fallback_y = 170; // sinnvoller Default

   // Prefer: Cancel Buttons
   int y_max = -1;
   string btns[] = {"ButtonCancelOrder", "ButtonCancelOrderSell"};
   for(int i=0;i<ArraySize(btns);i++)
     {
      if(ObjectFind(0, btns[i]) >= 0)
        {
         int y = (int)ObjectGetInteger(0, btns[i], OBJPROP_YDISTANCE);
         int h = (int)ObjectGetInteger(0, btns[i], OBJPROP_YSIZE);
         y_max = MathMax(y_max, y + h);
        }
     }

   // Fallback: ActiveTrade Labels
   if(y_max < 0)
     {
      string lbls[] = {"ActiveLongTrade", "ActiveShortTrade"};
      for(int i=0;i<ArraySize(lbls);i++)
        {
         if(ObjectFind(0, lbls[i]) >= 0)
           {
            int y = (int)ObjectGetInteger(0, lbls[i], OBJPROP_YDISTANCE);
            int h = (int)ObjectGetInteger(0, lbls[i], OBJPROP_YSIZE);
            y_max = MathMax(y_max, y + h);
           }
        }
     }

   if(y_max < 0)
      return fallback_y;

   return y_max + 10; // Abstand nach unten
  }

// Positioniert BG + Labels konsistent unter den Cancel-Buttons.
void UI_PositionOverviewPanel()
  {
   if(ObjectFind(0, TA_OVERVIEW_BG) < 0)
      return;

   // an Cancel-Buttons ausrichten
   int panel_x = 100;          // wie Cancel-Buttons
   int panel_y = UI_GetOverviewTopY();
   int panel_w = 330;          // 150 + 30 + 150
   int panel_h = 220;          // wird später ggf. dynamisch angepasst

   ObjectSetInteger(0, TA_OVERVIEW_BG, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, TA_OVERVIEW_BG, OBJPROP_XDISTANCE, panel_x);
   ObjectSetInteger(0, TA_OVERVIEW_BG, OBJPROP_YDISTANCE, panel_y);
   ObjectSetInteger(0, TA_OVERVIEW_BG, OBJPROP_XSIZE, panel_w);
   ObjectSetInteger(0, TA_OVERVIEW_BG, OBJPROP_YSIZE, panel_h);

   // Header (TA_OVERVIEW_TXT)
   if(ObjectFind(0, TA_OVERVIEW_TXT) >= 0)
     {
      ObjectSetInteger(0, TA_OVERVIEW_TXT, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, TA_OVERVIEW_TXT, OBJPROP_XDISTANCE, panel_x + 8);
      ObjectSetInteger(0, TA_OVERVIEW_TXT, OBJPROP_YDISTANCE, panel_y + 6);
     }

   // Zwei Spalten
   int padding = 8;
   int gap     = 10;
   int col_w   = (panel_w - padding*2 - gap) / 2;
   int x_long  = panel_x + padding;
   int x_short = panel_x + padding + col_w + gap;
   int y_text  = panel_y + 24;

   if(ObjectFind(0, TA_OVERVIEW_TXT_LONG) >= 0)
     {
      ObjectSetInteger(0, TA_OVERVIEW_TXT_LONG, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, TA_OVERVIEW_TXT_LONG, OBJPROP_XDISTANCE, x_long);
      ObjectSetInteger(0, TA_OVERVIEW_TXT_LONG, OBJPROP_YDISTANCE, y_text);
     }

   if(ObjectFind(0, TA_OVERVIEW_TXT_SHORT) >= 0)
     {
      ObjectSetInteger(0, TA_OVERVIEW_TXT_SHORT, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, TA_OVERVIEW_TXT_SHORT, OBJPROP_XDISTANCE, x_short);
      ObjectSetInteger(0, TA_OVERVIEW_TXT_SHORT, OBJPROP_YDISTANCE, y_text);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UI_CreateOrUpdateOverviewPanel()
  {
   if(ObjectFind(0, TA_OVERVIEW_BG) < 0)
     {
      ObjectCreate(0, TA_OVERVIEW_BG, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, TA_OVERVIEW_BG, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, TA_OVERVIEW_BG, OBJPROP_XDISTANCE, 100);
      ObjectSetInteger(0, TA_OVERVIEW_BG, OBJPROP_YDISTANCE, UI_GetOverviewTopY());
      ObjectSetInteger(0, TA_OVERVIEW_BG, OBJPROP_XSIZE, 330);
      ObjectSetInteger(0, TA_OVERVIEW_BG, OBJPROP_YSIZE, 220);
      ObjectSetInteger(0, TA_OVERVIEW_BG, OBJPROP_BGCOLOR, clrBlack);
      ObjectSetInteger(0, TA_OVERVIEW_BG, OBJPROP_COLOR, clrGray);
      // UI-Panel soll IM Vordergrund sein
      ObjectSetInteger(0, TA_OVERVIEW_BG, OBJPROP_BACK, false);
      ObjectSetInteger(0, TA_OVERVIEW_BG, OBJPROP_HIDDEN, true);
     }

   if(ObjectFind(0, TA_OVERVIEW_TXT) < 0)
     {
      ObjectCreate(0, TA_OVERVIEW_TXT, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, TA_OVERVIEW_TXT, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, TA_OVERVIEW_TXT, OBJPROP_XDISTANCE, 108);
      ObjectSetInteger(0, TA_OVERVIEW_TXT, OBJPROP_YDISTANCE, UI_GetOverviewTopY()+6);
      ObjectSetInteger(0, TA_OVERVIEW_TXT, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, TA_OVERVIEW_TXT, OBJPROP_FONTSIZE, 10);
      ObjectSetString(0,  TA_OVERVIEW_TXT, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, TA_OVERVIEW_TXT, OBJPROP_HIDDEN, true);
     }

   // LONG column
   if(ObjectFind(0, TA_OVERVIEW_TXT_LONG) < 0)
     {
      ObjectCreate(0, TA_OVERVIEW_TXT_LONG, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, TA_OVERVIEW_TXT_LONG, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, TA_OVERVIEW_TXT_LONG, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, TA_OVERVIEW_TXT_LONG, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0,  TA_OVERVIEW_TXT_LONG, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(0, TA_OVERVIEW_TXT_LONG, OBJPROP_HIDDEN, true);
     }

   // SHORT column
   if(ObjectFind(0, TA_OVERVIEW_TXT_SHORT) < 0)
     {
      ObjectCreate(0, TA_OVERVIEW_TXT_SHORT, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, TA_OVERVIEW_TXT_SHORT, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, TA_OVERVIEW_TXT_SHORT, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, TA_OVERVIEW_TXT_SHORT, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0,  TA_OVERVIEW_TXT_SHORT, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(0, TA_OVERVIEW_TXT_SHORT, OBJPROP_HIDDEN, true);
     }

   UI_PositionOverviewPanel();
  }
//+--------------

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UI_UpdateOverviewPanel()
  {
   DB_PositionRow rows[];
   int n = DB_LoadPositions(_Symbol, (ENUM_TIMEFRAMES)_Period, rows);

   UI_CreateOrUpdateOverviewPanel();

   // Panel unter Cancel-Buttons ausrichten
   UI_PositionOverviewPanel();

   // Aktive Tradenummern aus DB ableiten (Status nicht CLOSED*)
   int activeLong = 0;
   int activeShort = 0;
   for(int i = 0; i < n; i++)
     {
      if(rows[i].was_sent <= 0 && rows[i].is_pending <= 0)
         continue;
      if(StringFind(rows[i].status, "CLOSED") == 0)
         continue;

      if(rows[i].direction == "LONG")
         activeLong = MathMax(activeLong, rows[i].trade_no);
      else if(rows[i].direction == "SHORT")
         activeShort = MathMax(activeShort, rows[i].trade_no);
     }

   // Column-Texts sammeln
   string longLines[32];
   string shortLines[32];
   int longCnt = 0, shortCnt = 0;

   longLines[longCnt++]   = (activeLong > 0)  ? StringFormat("LONG  T%d", activeLong)  : "LONG  (kein aktiver Trade)";
   shortLines[shortCnt++] = (activeShort > 0) ? StringFormat("SHORT T%d", activeShort) : "SHORT (kein aktiver Trade)";

   // Positionen für die aktiven Trades auflisten
   for(int i = 0; i < n; i++)
     {
      if(rows[i].was_sent <= 0 && rows[i].is_pending <= 0)
         continue;

      // LONG
      if(activeLong > 0 && rows[i].direction == "LONG" && rows[i].trade_no == activeLong && rows[i].pos_no > 0)
        {
         if(longCnt < ArraySize(longLines))
            longLines[longCnt++] = StringFormat("P%d %s  E%s  SL%s", rows[i].pos_no, rows[i].status,
                                                DoubleToString(rows[i].entry, _Digits),
                                                DoubleToString(rows[i].sl, _Digits));
        }

      // SHORT
      if(activeShort > 0 && rows[i].direction == "SHORT" && rows[i].trade_no == activeShort && rows[i].pos_no > 0)
        {
         if(shortCnt < ArraySize(shortLines))
            shortLines[shortCnt++] = StringFormat("P%d %s  E%s  SL%s", rows[i].pos_no, rows[i].status,
                                                 DoubleToString(rows[i].entry, _Digits),
                                                 DoubleToString(rows[i].sl, _Digits));
        }
     }

   // Panel-Layout
   int panel_x = (int)ObjectGetInteger(0, TA_OVERVIEW_BG, OBJPROP_XDISTANCE);
   int panel_y = (int)ObjectGetInteger(0, TA_OVERVIEW_BG, OBJPROP_YDISTANCE);
   int panel_w = (int)ObjectGetInteger(0, TA_OVERVIEW_BG, OBJPROP_XSIZE);
   if(panel_w <= 0) panel_w = 330;

   int padding = 8;
   int gap     = 10;
   int col_w   = (panel_w - padding*2 - gap) / 2;
   int x_long  = panel_x + padding;
   int x_short = panel_x + padding + col_w + gap;
   int y0      = panel_y + 26;   // unter Titel
   int line_h  = 14;

   int rowsNeeded = MathMax(longCnt, shortCnt);
   if(rowsNeeded < 1) rowsNeeded = 1;

   // Panelhöhe dynamisch
   int new_h = (y0 - panel_y) + rowsNeeded * line_h + 8;
   ObjectSetInteger(0, TA_OVERVIEW_BG, OBJPROP_YSIZE, new_h);

   // Titel setzen
   ObjectSetString(0, TA_OVERVIEW_TXT, OBJPROP_TEXT, "Pyramiden-Übersicht");

   // Zeilen setzen (jede Zeile ist EIN eigenes Label -> garantiert untereinander)
   for(int r = 0; r < rowsNeeded; r++)
     {
      string lt = (r < longCnt)  ? longLines[r]  : "";
      string st = (r < shortCnt) ? shortLines[r] : "";
      int yy = y0 + r * line_h;
      UI_SetOverviewRow(true,  r, x_long,  yy, lt);
      UI_SetOverviewRow(false, r, x_short, yy, st);
     }
  }

// --- OVERVIEW PANEL: Row-Labels (statt \n in einem Label) ---
string UI_OverviewRowName(const bool isLong, const int idx)
  {
   return StringFormat("TA_OV_%s_%d", (isLong ? "L" : "S"), idx);
  }
void UI_CreateOrUpdateOverviewRowLabel(const string name)
  {
   if(ObjectFind(0, name) >= 0)
      return;

   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetString(0, name, OBJPROP_TEXT, "");
  }
void UI_SetOverviewRow(const bool isLong, const int idx, const int x, const int y, const string text)
  {
   string name = UI_OverviewRowName(isLong, idx);
   UI_CreateOrUpdateOverviewRowLabel(name);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
  }
#endif // __GUI__
//+------------------------------------------------------------------+
