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

#ifndef SL_HL
#define SL_HL "SL_HL"
#endif
#ifndef PR_HL
#define PR_HL "PR_HL"
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

// Name bauen: ButtonSLHit_LONG_2_1
string UI_SLHitName(const string direction, const int trade_no, const int pos_no)
  {
   return SLHIT_PREFIX + direction + "_" + IntegerToString(trade_no) + "_" + IntegerToString(pos_no);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string update_Text(string name, string val)
  {
   return (string)ObjectSetString(0, name, OBJPROP_TEXT, val);
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
      ObjectSetInteger(0, LABEL_NAME, OBJPROP_FONTSIZE, InpFontSize);
      ObjectSetString(0, LABEL_NAME, OBJPROP_FONT, InpFont);
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
   string prefixes[] = { "SL_Short", "Entry_Short",  "LabelSLShort", "LabelEntryShort"};
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
   string prefixes[] = { "SL_Long", "Entry_Long", "LabelSLLong", "LabelEntryLong"};
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
bool createButton(string objName, string text, int xD, int yD, int xS, int yS, color clrTxt, color clrBG, int fontsize = 8, color clrBorder = clrNONE, string font = "Arial")
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
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, InpFontSize);
   ObjectSetString(0, objName, OBJPROP_FONT, InpFont);
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
   
   ObjectSetString(0, SENDTRADEBTN, OBJPROP_FONT, InpFont);
   ObjectSetInteger(0, SENDTRADEBTN, OBJPROP_FONTSIZE, InpFontSize);

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
   
   ObjectSetString(0, TRNB, OBJPROP_FONT, InpFont);
   ObjectSetInteger(0, TRNB, OBJPROP_FONTSIZE, InpFontSize);

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
      ObjectSetString(0, POSNB, OBJPROP_FONT, InpFont);
   ObjectSetInteger(0, POSNB, OBJPROP_FONTSIZE, InpFontSize);

   
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


// --------- Globale Wrapper (einfach in OnInit/OnTick/OnDeinit nutzbar) ----------

bool g_TA_TradeListsCreated = false;

int UI_TradeLists_TopY()
{
   // unter das bestehende Overview-Panel (falls vorhanden)
   if(ObjectFind(0, TA_OVERVIEW_BG) >= 0)
   {
      int y = (int)ObjectGetInteger(0, TA_OVERVIEW_BG, OBJPROP_YDISTANCE);
      int h = (int)ObjectGetInteger(0, TA_OVERVIEW_BG, OBJPROP_YSIZE);
      return y + h + 10;
   }
   // fallback: unter Cancel Buttons / Active Labels
   return UI_GetOverviewTopY() + 10;
}

int UI_TradeLists_Height()
{
   int ch = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
   int y  = UI_TradeLists_TopY();
   int h  = ch - y - 10;

   if(h < 160) h = 160;
   if(h > 360) h = 360;
   return h;
}


void UI_TradeLists_Deinit(const int reason)
{
   if(!g_TA_TradeListsCreated)
      return;

   g_TA_TradeListsCreated = false;
}



// optional: in OnTick aufrufen (throttled)
void UI_TradeLists_AutoRefresh()
{
   static uint last_ms = 0;
   uint now_ms = GetTickCount();
   if(now_ms - last_ms < 1500)
      return;

   last_ms = now_ms;
  
}


#endif // __GUI__
//+------------------------------------------------------------------+
