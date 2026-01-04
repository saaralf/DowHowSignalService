//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#ifndef __GUI__
#define __GUI__

// Overview panel internals (keine Abhängigkeit von #define in .mq5 nötig)
#ifndef TA_OVERVIEW_TXT_LONG
#define TA_OVERVIEW_TXT_LONG "TA_OVERVIEW_TXT_LONG"
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



/**
 * Beschreibung: Aktualisiert Long-Labels nur wenn Entry/SL sich geändert haben.
 * Parameter:    none
 * Rückgabewert: void
 * Hinweise:     Reduziert ObjectMove/ObjectSetString Spam pro Tick.
 * Fehlerfälle:  keine
 */
void CreateLabelsLong_IfChanged()
{
   static double last_entry = 0.0;
   static double last_sl    = 0.0;

   if(MathAbs(Entry_Price - last_entry) < (_Point*0.1) && MathAbs(SL_Price - last_sl) < (_Point*0.1))
      return;

   last_entry = Entry_Price;
   last_sl    = SL_Price;

   CreateLabelsLong();
}

/**
 * Beschreibung: Aktualisiert Short-Labels nur, wenn Entry/SL sich geändert haben.
 * Parameter:    -
 * Rückgabewert: void
 * Hinweise:     Reduziert UI-Updates pro Tick.
 * Fehlerfälle:  Keine (CreateLabelsShort() loggt intern falls nötig)
 */
void CreateLabelsShort_IfChanged()
{
   static double last_entry = 0.0;
   static double last_sl    = 0.0;

   if(MathAbs(Entry_Price - last_entry) < (_Point * 0.1) &&
      MathAbs(SL_Price    - last_sl)    < (_Point * 0.1))
      return;

   last_entry = Entry_Price;
   last_sl    = SL_Price;

   CreateLabelsShort();
}



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

      CLogger::Add(LOG_LEVEL_INFO, "__FUNCTION__ Error Code = "+ GetLastError());
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

      CLogger::Add(LOG_LEVEL_INFO, "__FUNCTION__ Error Code = "+ GetLastError());

     }
//--- Geben den Wert der Eigenschaft zurück
   return ((int)result);
  }

/**
 * Beschreibung: Setzt den Text eines Chart-Objekts robust (mit Logging).
 * Parameter:    name - Objektname
 *               val  - Text
 * Rückgabewert: bool - true wenn gesetzt, sonst false
 * Hinweise:     Für OBJ_BUTTON/OBJ_LABEL/OBJ_EDIT etc. nutzbar.
 * Fehlerfälle:  ObjectSetString==false -> Print/CLogger mit GetLastError
 */
bool update_Text(const string name, const string val)
  {
   if(ObjectFind(0, name) < 0)
     {
      CLogger::Add(LOG_LEVEL_WARNING, __FUNCTION__ + ": object not found: " + name);
      return false;
     }

   ResetLastError();
   if(!ObjectSetString(0, name, OBJPROP_TEXT, val))
     {
      CLogger::Add(LOG_LEVEL_ERROR,
                   __FUNCTION__ + ": ObjectSetString failed name=" + name +
                   " err=" + IntegerToString(GetLastError()));
      return false;
     }
   return true;
  }




// direction: "LONG"/"SHORT"
// kind: "entry"/"sl"/"tp"
bool UI_ParseTradePosFromName(const string name, string &direction, int &trade_no, int &pos_no, string &kind)
  {
   direction = "";
   kind = "";
   trade_no = 0;
   pos_no = 0;

   if(StringFind(name, "Entry_Long_") == 0)
     {
      direction="LONG";
      kind="entry";
     }
   else
      if(StringFind(name, "SL_Long_") == 0)
        {
         direction="LONG";
         kind="sl";
        }
      else

         if(StringFind(name, "Entry_Short_") == 0)
           {
            direction="SHORT";
            kind="entry";
           }
         else
            if(StringFind(name, "SL_Short_") == 0)
              {
               direction="SHORT";
               kind="sl";
              }
            else
               return false;

   string parts[];
   int n = StringSplit(name, '_', parts);
   if(n < 2)
      return false;

   trade_no = (int)StringToInteger(parts[n-2]);
   pos_no   = (int)StringToInteger(parts[n-1]);

   if(trade_no <= 0 || pos_no <= 0)
      return false;
   return true;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


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
      UI_ObjSetIntSafe(0, objName, OBJPROP_COLOR, clr);
      UI_ObjSetIntSafe(0, objName, OBJPROP_STYLE, STYLE_DASH);
      UI_ObjSetIntSafe(0, objName, OBJPROP_BACK, false);
      UI_ObjSetIntSafe(0, objName, OBJPROP_SELECTABLE, true);
      UI_ObjSetIntSafe(0, objName, OBJPROP_SELECTED, false);
      UI_RequestRedraw();

      return true;
     }

// neu erstellen
   if(!ObjectCreate(0, objName, OBJ_HLINE, 0, time1, price1))
     {

      CLogger::Add(LOG_LEVEL_INFO, "__FUNCTION__ : Failed to create "+ objName+ " err="+ GetLastError());
      return false;
     }

   UI_Reg_Add(objName); // Speichere Object im Array zum späteren löschen

   ObjectSetDouble(0, objName, OBJPROP_PRICE, price1);
   UI_ObjSetIntSafe(0, objName, OBJPROP_COLOR, clr);
   UI_ObjSetIntSafe(0, objName, OBJPROP_STYLE, STYLE_DASH);
   UI_ObjSetIntSafe(0, objName, OBJPROP_BACK, false);
   UI_ObjSetIntSafe(0, objName, OBJPROP_SELECTABLE, true);
   UI_ObjSetIntSafe(0, objName, OBJPROP_SELECTED, false);

   UI_RequestRedraw();
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
         CLogger::Add(LOG_LEVEL_INFO, "__FUNCTION__ : Failed to create "+ LABEL_NAME+ " Error Code: "+ GetLastError());

         return; // raus bei Fehler
        }

      UI_Reg_Add(LABEL_NAME); // Speichere Object im Array zum späteren löschen
      // Grund-Layout nur beim ersten Erzeugen
      UI_ObjSetIntSafe(0, LABEL_NAME, OBJPROP_COLOR, clr1);
      UI_ObjSetIntSafe(0, LABEL_NAME, OBJPROP_FONTSIZE, InpFontSize);
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

   CreateLabelsTPcolor_SLLines(LabelSLLong, "StoppLoss Long Trade", SL_Price, Tradecolor_SLLineLong);
   CreateLabelsTPcolor_SLLines(LabelEntryLong, "Entry Price Long Trade", Entry_Price, TradeEntryLineLong);

   update_Text(LabelSLLong, "SL Long Trade");
   update_Text(LabelEntryLong, "Entry Long Trade");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateLabelsShort()
  {

   CreateLabelsTPcolor_SLLines(LabelSLShort, "StoppLoss Short Trade", SL_Price, Tradecolor_SLLineShort);
   CreateLabelsTPcolor_SLLines(LabelEntryShort, "Entry Price Short Trade", Entry_Price, TradeEntryLineShort);

   update_Text(LabelSLShort, "SL Short Trade");
   update_Text(LabelEntryShort, "Entry Short Trade");
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteLinesandLabelsLong()
  {
// löscht alle Objekte, die zu LONG-Trade-Linien/Labels gehören (inkl. _1.._4)
   string prefixes[] = {SL_Long, Entry_Long, LabelSLLong, LabelEntryLong};
   int total = ObjectsTotal(0, -1, -1);
   for(int i = total - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i, -1, -1);
      for(int p = 0; p < ArraySize(prefixes); p++)
        {
         if(StringFind(name, prefixes[p]) == 0)
           {
            UI_Reg_DeleteOne(name);

            break;
           }
        }
     }
  }

// ============================================================================
// "Putzkommando": löscht ALLE Trade/Pos-Linien, die nach deinem Schema heißen:
//   Entry_Long_<trade>_<pos>  (+ optional _TAG)
//   SL_Long_<trade>_<pos>     (+ optional _TAG)
//   Entry_Short_<trade>_<pos> (+ optional _TAG)
//   SL_Short_<trade>_<pos>    (+ optional _TAG)
//
// Wichtig: löscht NICHT PR_HL / SL_HL (Basislinien) – nur die suf-Linien.
// Rückgabe: Anzahl gelöschter Objekte.
// ============================================================================

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int UI_DeleteAllTradePosLinesByScan()
  {
// Prefixe exakt so, dass nur suf-Objekte getroffen werden (weil suf mit "_" beginnt)
   string p1 = Entry_Long + "_";
   string p2 = SL_Long + "_";
   string p3 = Entry_Short + "_";
   string p4 = SL_Short + "_";

   int deleted = 0;

// sub_window = -1 => alle Subwindows, type = -1 => alle Typen
   int total = ObjectsTotal(0, -1, -1);

   for(int i = total - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i, -1, -1);
      if(name == "")
         continue;

      bool match =
         (StringFind(name, p1, 0) == 0) ||
         (StringFind(name, p2, 0) == 0) ||
         (StringFind(name, p3, 0) == 0) ||
         (StringFind(name, p4, 0) == 0);

      if(match)
        {
         if(UI_Reg_DeleteOne(name))
            deleted++;
        }
     }

   return deleted;
  }

//+------------------------------------------------------------------+
//| Create Trading Button                                                                 |
//+------------------------------------------------------------------+
bool createButton(string objName, string text, int xD, int yD, int xS, int yS, color clrTxt, color clrBG, int fontsize = 8, color clrBorder = clrNONE, string font = "Arial")
  {
   ResetLastError();
   if(!ObjectCreate(0, objName, OBJ_BUTTON, 0, 0, TimeCurrent()))
     {
      CLogger::Add(LOG_LEVEL_INFO, "create failed for "+ objName+ " err="+ GetLastError());


      return (false);
     }
   UI_Reg_Add(objName); // Speichere Object im Array zum späteren löschen
   UI_ObjSetIntSafe(0, objName, OBJPROP_XDISTANCE, xD);
   UI_ObjSetIntSafe(0, objName, OBJPROP_YDISTANCE, yD);
   UI_ObjSetIntSafe(0, objName, OBJPROP_XSIZE, xS);
   UI_ObjSetIntSafe(0, objName, OBJPROP_YSIZE, yS);
   UI_ObjSetIntSafe(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   UI_ObjSetIntSafe(0, objName, OBJPROP_FONTSIZE, InpFontSize);
   ObjectSetString(0, objName, OBJPROP_FONT, InpFont);
   UI_ObjSetIntSafe(0, objName, OBJPROP_COLOR, clrTxt);
   UI_ObjSetIntSafe(0, objName, OBJPROP_BGCOLOR, clrBG);
   UI_ObjSetIntSafe(0, objName, OBJPROP_BORDER_COLOR, clrBorder);
   UI_ObjSetIntSafe(0, objName, OBJPROP_BACK, false);
   UI_ObjSetIntSafe(0, objName, OBJPROP_STATE, false);
   UI_ObjSetIntSafe(0, objName, OBJPROP_SELECTABLE, false);
   UI_ObjSetIntSafe(0, objName, OBJPROP_SELECTED, false);
   UI_ObjSetIntSafe(0, objName, OBJPROP_ANCHOR, ANCHOR_CENTER);

   UI_RequestRedraw();
   return (true);
  }

/**
 * Beschreibung: Erzeugt oder aktualisiert eine Basis-HLine (z.B. PR_HL / SL_HL) zuverlässig.
 * Parameter:    objName - Objektname der Linie
 *               time1   - Referenzzeit (für OBJ_HLINE nicht relevant, wird nur bei Create mitgegeben)
 *               price1  - Preis der Linie
 *               clr     - Linienfarbe
 * Rückgabewert: true bei Erfolg, sonst false
 * Hinweise:     Setzt explizit Selectable/Zorder/Width, damit die Linie sicher anklickbar/dragbar ist.
 * Fehlerfälle:  ObjectCreate/ObjectSet* schlägt fehl -> Log via CLogger + GetLastError()
 */
bool createHL(string objName, datetime time1, double price1, color clr)
  {
   ResetLastError();

// Wenn Objekt existiert: updaten statt neu erzeugen (wichtig bei Reload)
   if(ObjectFind(0, objName) >= 0)
     {
      UI_Reg_Add(objName); // sicherstellen, dass Cleanup es später findet

      // Preis/Farbe aktualisieren
      ObjectSetDouble(0, objName, OBJPROP_PRICE, price1);
      UI_ObjSetIntSafe(0, objName, OBJPROP_COLOR, clr);

      // Bedienbarkeit & Sichtbarkeit
      UI_ObjSetIntSafe(0, objName, OBJPROP_SELECTABLE, true);
      UI_ObjSetIntSafe(0, objName, OBJPROP_SELECTED, false);
      UI_ObjSetIntSafe(0, objName, OBJPROP_HIDDEN, false);
      UI_ObjSetIntSafe(0, objName, OBJPROP_BACK, false);

      // "Trefferfläche" & Ebenen
      UI_ObjSetIntSafe(0, objName, OBJPROP_WIDTH, 2);
      UI_ObjSetIntSafe(0, objName, OBJPROP_STYLE, STYLE_SOLID);
      UI_ObjSetIntSafe(0, objName, OBJPROP_ZORDER, 10);

      return true;
     }

// Neu erzeugen
   if(!ObjectCreate(0, objName, OBJ_HLINE, 0, time1, price1))
     {
      CLogger::Add(LOG_LEVEL_INFO, __FUNCTION__ + ": create failed for " + objName +
                   " err=" + IntegerToString(GetLastError()));
      return false;
     }

   UI_Reg_Add(objName); // fürs Deinit-Cleanup

// Initiale Properties
   ObjectSetDouble(0, objName, OBJPROP_PRICE, price1);
   UI_ObjSetIntSafe(0, objName, OBJPROP_COLOR, clr);
   UI_ObjSetIntSafe(0, objName, OBJPROP_BACK, false);
   UI_ObjSetIntSafe(0, objName, OBJPROP_STYLE, STYLE_SOLID);

// KRITISCH: sonst ist SL_HL oft nicht greifbar
   UI_ObjSetIntSafe(0, objName, OBJPROP_SELECTABLE, true);
   UI_ObjSetIntSafe(0, objName, OBJPROP_SELECTED, false);
   UI_ObjSetIntSafe(0, objName, OBJPROP_HIDDEN, false);

   UI_ObjSetIntSafe(0, objName, OBJPROP_WIDTH, 2);
   UI_ObjSetIntSafe(0, objName, OBJPROP_ZORDER, 10);

   UI_RequestRedraw();
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SendButton()
  {
// optional aber empfohlen (OnInit ruft SendButton teils doppelt auf):
   del_SENDBTN_TRNB_POSNB();

   ObjectCreate(0, SENDTRADEBTN, OBJ_BUTTON, 0, 0, 0);
   UI_Reg_Add(SENDTRADEBTN); // Speichere Object im Array zum späteren löschen
   UI_ObjSetIntSafe(0, SENDTRADEBTN, OBJPROP_XDISTANCE, xd3 - 100);
   UI_ObjSetIntSafe(0, SENDTRADEBTN, OBJPROP_XSIZE, 100);
   UI_ObjSetIntSafe(0, SENDTRADEBTN, OBJPROP_YDISTANCE, yd3);
   UI_ObjSetIntSafe(0, SENDTRADEBTN, OBJPROP_YSIZE, 30);
   UI_ObjSetIntSafe(0, SENDTRADEBTN, OBJPROP_CORNER, 0);
   if(!SendOnlyButton)
     {
      ObjectSetString(0, SENDTRADEBTN, OBJPROP_TEXT, "T & S"); // label
      UI_ObjSetIntSafe(0, SENDTRADEBTN, OBJPROP_BGCOLOR, TSButton_bgcolor);
      UI_ObjSetIntSafe(0, SENDTRADEBTN, OBJPROP_COLOR, TSButton_font_color);
     }
   else
     {
      ObjectSetString(0, SENDTRADEBTN, OBJPROP_TEXT, "Send only"); // label
      UI_ObjSetIntSafe(0, SENDTRADEBTN, OBJPROP_BGCOLOR, SendOnlyButton_bgcolor);
      UI_ObjSetIntSafe(0, SENDTRADEBTN, OBJPROP_COLOR, SendOnlyButton_font_color);
     }

   ObjectSetString(0, SENDTRADEBTN, OBJPROP_FONT, InpFont);
   UI_ObjSetIntSafe(0, SENDTRADEBTN, OBJPROP_FONTSIZE, InpFontSize);

// TRNB (TradeNo) links
   ObjectCreate(0, TRNB, OBJ_EDIT, 0, 0, 0);
   UI_Reg_Add(TRNB); // Speichere Object im Array zum späteren löschen
   UI_ObjSetIntSafe(0, TRNB, OBJPROP_XDISTANCE, xd3 - 100);
   UI_ObjSetIntSafe(0, TRNB, OBJPROP_YDISTANCE, yd3 + 30);
   UI_ObjSetIntSafe(0, TRNB, OBJPROP_XSIZE, 60);
   UI_ObjSetIntSafe(0, TRNB, OBJPROP_YSIZE, 30);
   ObjectSetString(0, TRNB, OBJPROP_TEXT, "0");
   UI_ObjSetIntSafe(0, TRNB, OBJPROP_BGCOLOR, clrWhite);
   UI_ObjSetIntSafe(0, TRNB, OBJPROP_COLOR, clrBlack);
   UI_ObjSetIntSafe(0, TRNB, OBJPROP_ALIGN, ALIGN_CENTER);
   UI_ObjSetIntSafe(0, TRNB, OBJPROP_READONLY, false);

   ObjectSetString(0, TRNB, OBJPROP_FONT, InpFont);
   UI_ObjSetIntSafe(0, TRNB, OBJPROP_FONTSIZE, InpFontSize);

// POSNB (PosNo) rechts daneben
   ObjectCreate(0, POSNB, OBJ_EDIT, 0, 0, 0);
   UI_Reg_Add(POSNB); // Speichere Object im Array zum späteren löschen
   UI_ObjSetIntSafe(0, POSNB, OBJPROP_XDISTANCE, xd3 - 40);
   UI_ObjSetIntSafe(0, POSNB, OBJPROP_YDISTANCE, yd3 + 30);
   UI_ObjSetIntSafe(0, POSNB, OBJPROP_XSIZE, 40);
   UI_ObjSetIntSafe(0, POSNB, OBJPROP_YSIZE, 30);
   ObjectSetString(0, POSNB, OBJPROP_TEXT, "1");
   UI_ObjSetIntSafe(0, POSNB, OBJPROP_BGCOLOR, clrWhite);
   UI_ObjSetIntSafe(0, POSNB, OBJPROP_COLOR, clrBlack);
   UI_ObjSetIntSafe(0, POSNB, OBJPROP_ALIGN, ALIGN_CENTER);
   UI_ObjSetIntSafe(0, POSNB, OBJPROP_READONLY, false);
   ObjectSetString(0, POSNB, OBJPROP_FONT, InpFont);
   UI_ObjSetIntSafe(0, POSNB, OBJPROP_FONTSIZE, InpFontSize);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void del_SENDBTN_TRNB_POSNB()
  {
   UI_Reg_DeleteOne(SENDTRADEBTN);
   UI_Reg_DeleteOne(TRNB);
   UI_Reg_DeleteOne(POSNB);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SabioEdit()
  {
   del_sabiosl_sabioEntry();
// SabioSLEdit
   ObjectCreate(0, SabioSL, OBJ_EDIT, 0, 0, 0);
   UI_Reg_Add(SabioSL); // Speichere Object im Array zum späteren löschen
//--- Objektkoordinaten angeben
   UI_ObjSetIntSafe(0, SabioSL, OBJPROP_XDISTANCE, xd5);
   UI_ObjSetIntSafe(0, SabioSL, OBJPROP_YDISTANCE, yd5 + 30);
//--- Objektgröße setzen
   UI_ObjSetIntSafe(0, SabioSL, OBJPROP_XSIZE, 280);
   UI_ObjSetIntSafe(0, SabioSL, OBJPROP_YSIZE, 30);
//--- den Text setzen
   ObjectSetString(0, SabioSL, OBJPROP_TEXT, "SABIO SL: " + Get_Price_s(SL_HL));
//--- Schriftgröße setzen
   UI_ObjSetIntSafe(0, SabioSL, OBJPROP_BGCOLOR, clrWhite);
   UI_ObjSetIntSafe(0, SabioSL, OBJPROP_COLOR, clrBlack);

//--- aktivieren (true) oder deaktivieren (false) den schreibgeschützten Modus
   UI_ObjSetIntSafe(0, SabioSL, OBJPROP_READONLY, false);

// SabioEntryEdit
   ObjectCreate(0, SabioEntry, OBJ_EDIT, 0, 0, 0);
   UI_Reg_Add(SabioEntry); // Speichere Object im Array zum späteren löschen
//--- Objektkoordinaten angeben
   UI_ObjSetIntSafe(0, SabioEntry, OBJPROP_XDISTANCE, xd3);
   UI_ObjSetIntSafe(0, SabioEntry, OBJPROP_YDISTANCE, yd3 + 30);
//--- Objektgröße setzen
   UI_ObjSetIntSafe(0, SabioEntry, OBJPROP_XSIZE, 280);
   UI_ObjSetIntSafe(0, SabioEntry, OBJPROP_YSIZE, 30);
//--- den Text setzen
   ObjectSetString(0, SabioEntry, OBJPROP_TEXT, "SABIO ENTRY: " + Get_Price_s(PR_HL));
//--- Schriftgröße setzen
   UI_ObjSetIntSafe(0, SabioEntry, OBJPROP_BGCOLOR, clrWhite);
   UI_ObjSetIntSafe(0, SabioEntry, OBJPROP_COLOR, clrBlack);

//--- aktivieren (true) oder deaktivieren (false) den schreibgeschützten Modus
   UI_ObjSetIntSafe(0, SabioEntry, OBJPROP_READONLY, false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void del_sabiosl_sabioEntry()
  {
   UI_Reg_DeleteOne(SabioEntry);
   UI_Reg_DeleteOne(SabioSL);
  }
// ================= OVERVIEW PANEL (LONG | SHORT) =================
// Bestimmt die Y-Position unterhalb der Cancel-Buttons.
int UI_GetOverviewTopY()
  {
   int fallback_y = 170; // sinnvoller Default

// Prefer: Cancel Buttons
   int y_max = -1;
   string btns[] = {"ButtonCancelOrder", "ButtonCancelOrderSell"};
   for(int i = 0; i < ArraySize(btns); i++)
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
      for(int i = 0; i < ArraySize(lbls); i++)
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
   int panel_x = 100; // wie Cancel-Buttons
   int panel_y = UI_GetOverviewTopY();
   int panel_w = 330; // 150 + 30 + 150
   int panel_h = 220; // wird später ggf. dynamisch angepasst


   UI_ObjSetIntSafe(0,TA_OVERVIEW_BG, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   UI_ObjSetIntSafe(0, TA_OVERVIEW_BG, OBJPROP_XDISTANCE, panel_x);
   UI_ObjSetIntSafe(0, TA_OVERVIEW_BG, OBJPROP_YDISTANCE, panel_y);
   UI_ObjSetIntSafe(0, TA_OVERVIEW_BG, OBJPROP_XSIZE, panel_w);
   UI_ObjSetIntSafe(0, TA_OVERVIEW_BG, OBJPROP_YSIZE, panel_h);
   /*
      UI_ObjSetIntSafe(0, TA_OVERVIEW_BG, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      UI_ObjSetIntSafe(0, TA_OVERVIEW_BG, OBJPROP_XDISTANCE, panel_x);
      UI_ObjSetIntSafe(0, TA_OVERVIEW_BG, OBJPROP_YDISTANCE, panel_y);
      UI_ObjSetIntSafe(0, TA_OVERVIEW_BG, OBJPROP_XSIZE, panel_w);
      UI_ObjSetIntSafe(0, TA_OVERVIEW_BG, OBJPROP_YSIZE, panel_h);
   */
// Header (TA_OVERVIEW_TXT)
   if(ObjectFind(0, TA_OVERVIEW_TXT) >= 0)
     {
      UI_ObjSetIntSafe(0, TA_OVERVIEW_TXT, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      UI_ObjSetIntSafe(0, TA_OVERVIEW_TXT, OBJPROP_XDISTANCE, panel_x + 8);
      UI_ObjSetIntSafe(0, TA_OVERVIEW_TXT, OBJPROP_YDISTANCE, panel_y + 6);
     }

// Zwei Spalten
   int padding = 8;
   int gap = 10;
   int col_w = (panel_w - padding * 2 - gap) / 2;
   int x_long = panel_x + padding;
   int x_short = panel_x + padding + col_w + gap;
   int y_text = panel_y + 24;

   if(ObjectFind(0, TA_OVERVIEW_TXT_LONG) >= 0)
     {
      UI_ObjSetIntSafe(0, TA_OVERVIEW_TXT_LONG, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      UI_ObjSetIntSafe(0, TA_OVERVIEW_TXT_LONG, OBJPROP_XDISTANCE, x_long);
      UI_ObjSetIntSafe(0, TA_OVERVIEW_TXT_LONG, OBJPROP_YDISTANCE, y_text);
     }

   if(ObjectFind(0, TA_OVERVIEW_TXT_SHORT) >= 0)
     {
      UI_ObjSetIntSafe(0, TA_OVERVIEW_TXT_SHORT, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      UI_ObjSetIntSafe(0, TA_OVERVIEW_TXT_SHORT, OBJPROP_XDISTANCE, x_short);
      UI_ObjSetIntSafe(0, TA_OVERVIEW_TXT_SHORT, OBJPROP_YDISTANCE, y_text);
     }
  }

// --------- Globale Wrapper (einfach in OnInit/OnTick/OnDeinit nutzbar) ----------

bool g_TA_TradeListsCreated = false;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int UI_TradeLists_Height()
  {
   int ch = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
   int y = UI_TradeLists_TopY();
   int h = ch - y - 10;

   if(h < 160)
      h = 160;
   if(h > 360)
      h = 360;
   return h;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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



/**
 * Beschreibung: Setzt eine Integer-Property auf ein Objekt mit sauberem Error-Logging.
 * Parameter:    name  - Objektname
 *               prop  - OBJPROP_*
 *               value - Wert
 * Rückgabewert: bool - true wenn gesetzt, sonst false
 * Hinweise:     Verhindert stilles Scheitern (z.B. bei gelöschten Objekten).
 * Fehlerfälle:  ObjectSetInteger==false -> Print + GetLastError
 */
bool UI_ObjSetIntSafe(const int chartID, const string name, const ENUM_OBJECT_PROPERTY_INTEGER prop, const long value)
  {
   if(ObjectFind(chartID, name) < 0)
     {
      Print(__FUNCTION__, ": object not found: ", name);
      return false;
     }

   ResetLastError();
   if(!ObjectSetInteger(chartID, name, prop, value))
     {
      Print(__FUNCTION__, ": ObjectSetInteger failed name=", name, " prop=", (int)prop, " err=", GetLastError());
      return false;
     }
   return true;
  }







#endif // __GUI__
//+------------------------------------------------------------------+
