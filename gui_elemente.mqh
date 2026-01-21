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


// Z-Order Konstanten
#define Z_LINES      50
#define Z_PANEL_BG   5000
#define Z_PANEL_UI   5100

// Panel nach vorne, Linien nach hinten (aber nicht "BACK" hinter Kerzen!)
void UI_ApplyZOrder()
  {
   int total = ObjectsTotal(0, 0, -1);
   for(int i=total-1; i>=0; --i)
     {
      string n = ObjectName(0, i, 0, -1);
      if(n == "")
         continue;

      // 1) Basis-HL Linien + TradePos Linien => hinten
      if(n == PR_HL || n == SL_HL || UI_IsTradePosLine(n))
        {
         ObjectSetInteger(0, n, OBJPROP_ZORDER, Z_LINES);
         ObjectSetInteger(0, n, OBJPROP_BACK, false); // wichtig
         continue;
        }

      // 2) Panel-Objekte (alles was mit TP_ beginnt) => vorne
      if(StringFind(n, "TP_", 0) == 0)
        {
         // Hintergrund etwas niedriger als Buttons/Labels (optional)
         int z = (n == "TP_BG" ? Z_PANEL_BG : Z_PANEL_UI);
         ObjectSetInteger(0, n, OBJPROP_ZORDER, z);
         ObjectSetInteger(0, n, OBJPROP_BACK, false);
         continue;
        }
     }
  }






/**
 * Beschreibung: Setzt den Text eines Chart-Objekts robust (mit Logging).
 * Parameter:    name - Objektname
 *               val  - Text
 * Rückgabewert: bool - true wenn gesetzt, sonst false
 * Hinweise:     Für OBJ_BUTTON/OBJ_LABEL/OBJ_EDIT etc. nutzbar.
 * Fehlerfälle:  ObjectSetString==false . Print/CLogger mit GetLastError
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






//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CreateEntryAndSLLines(string objName, datetime time1, double price1, color clr)
  {
   ResetLastError();

// existiert schon? . nur updaten
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






/**
 * Beschreibung: Setzt eine Integer-Property auf ein Objekt mit sauberem Error-Logging.
 * Parameter:    name  - Objektname
 *               prop  - OBJPROP_*
 *               value - Wert
 * Rückgabewert: bool - true wenn gesetzt, sonst false
 * Hinweise:     Verhindert stilles Scheitern (z.B. bei gelöschten Objekten).
 * Fehlerfälle:  ObjectSetInteger==false . Print + GetLastError
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
