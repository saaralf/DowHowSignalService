//======================== trades_panel.mqh ========================
#ifndef __TRADES_PANEL_MQH__
#define __TRADES_PANEL_MQH__



#include "CDBService.mqh"
#include "trade_pos_line_registry.mqh"
#include "CDiscordClient.mqh"
#define TP_BG "TP_BG"

#define TP_LBL_LONG "TP_LBL_LONG"
#define TP_LBL_SHORT "TP_LBL_SHORT"

#define TP_BTN_ACTIVE_LONG "TP_BTN_ACTIVE_LONG"
#define TP_BTN_ACTIVE_SHORT "TP_BTN_ACTIVE_SHORT"

#define TP_BTN_CANCEL_LONG "TP_BTN_CANCEL_LONG"
#define TP_BTN_CANCEL_SHORT "TP_BTN_CANCEL_SHORT"

#define TP_ROW_LONG_TR_PREFIX "TP_ROW_LONG_TR_"   // TP_ROW_LONG_12 Tradesnummern!
#define TP_ROW_SHORT_TR_PREFIX "TP_ROW_SHORT_TR_" // TP_ROW_SHORT_12

#define TP_ROW_LONG_TR_Cancel_PREFIX "TP_ROW_LONG_TR_Cancel_"   // TP_ROW_LONG_12_c
#define TP_ROW_SHORT_TR_Cancel_PREFIX "TP_ROW_SHORT_TR_Cancel_" // TP_ROW_SHORT_12_c

#define TP_ROW_LONG_PREFIX "TP_ROW_LONG_"   // TP_ROW_LONG_3 Positionen
#define TP_ROW_SHORT_PREFIX "TP_ROW_SHORT_" // TP_ROW_SHORT_3 Positionen!

#define TP_ROW_LONG_Cancel_PREFIX "TP_ROW_LONG_Cancel_"   // TP_ROW_LONG_3_c
#define TP_ROW_SHORT_Cancel_PREFIX "TP_ROW_SHORT_Cancel_" // TP_ROW_SHORT_3_c

#define TP_ROW_LONG_hitSL_PREFIX "TP_ROW_LONG_sl_"   // TP_ROW_LONG_3_sl
#define TP_ROW_SHORT_hitSL_PREFIX "TP_ROW_SHORT_sl_" // TP_ROW_SHORT_3_sl



// ---- Layout (kompakt / Theme an Entry+SL angelehnt)
int TP_X = 10, TP_Y = 40, TP_W = 440, TP_H = 420;
int TP_PAD = 6, TP_GAP = 6;

int TP_HDR_H = 22;
int TP_BTN_H = 22;
int TP_ROW_H = 18;

// “Text”-Button Breite pro Spalte (Fallback; wird unten sauber berechnet)
int BTN_BREITE = 160;

// Mini-Buttons (C / S) kompakter
int BTN_C_W  = 18;
int BTN_SL_W = 18;

// Panel nicht “zu breit wie ein Billboard”
int TP_MAX_W      = 440;  // 0 = kein Cap
int TP_MIN_COL_W  = 140;  // Minimum für Lesbarkeit
int TP_MAX_COL_W  = 200;  // nicht übertreiben
const color LBL_LONG_COL  = (color)C'0,170,100';   // Grün (nicht Neon)
const color LBL_SHORT_COL = (color)C'220,70,70';   // Rot (angenehm)



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Del_TP_CreateRectBG(const string name)
  {
   if(!UI_Reg_DeleteOne(name))
      return false;

   return true;
  }




#ifndef OBJ_ALL_PERIODS
#define OBJ_ALL_PERIODS 0xFFFFFFFF
#endif

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
color TP_PanelBg()
  {
   if(ObjectFind(0, TP_BG) >= 0)
      return (color)ObjectGetInteger(0, TP_BG, OBJPROP_BGCOLOR);
   return clrBlack; // Fallback
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TP_SetButtonVisible(const string name, const bool visible, const string caption,
                         const color txt_col, const color bg_col, const color border_col)
  {
   g_tp.SetButtonVisible(name,  visible,  caption,
                         txt_col, bg_col,  border_col);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void showActive_long(bool show)
  {
   g_tp.SetButtonVisible(TP_BTN_ACTIVE_LONG, show, "Active Trade",
                         PriceButton_font_color, PriceButton_bgcolor, PriceButton_bgcolor);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void showActive_short(bool show)
  {
   g_tp.SetButtonVisible(TP_BTN_ACTIVE_SHORT, show, "Active Trade",
                         PriceButton_font_color, PriceButton_bgcolor, PriceButton_bgcolor);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void showCancel_long(bool show)
  {
   g_tp.SetButtonVisible(TP_BTN_CANCEL_LONG, show, "Cancel Trade",
                         SLButton_font_color, SLButton_bgcolor, SLButton_bgcolor);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void showCancel_short(bool show)
  {
   g_tp.SetButtonVisible(TP_BTN_CANCEL_SHORT, show, "Cancel Trade",
                         SLButton_font_color, SLButton_bgcolor, SLButton_bgcolor);
  }




// ============================================================================
// Löscht Entry/SL-Linien (und optional deren _TAG) für eine konkrete Trade/Pos.
// Passt exakt zu deinem Suffix-Schema: "_" + trade_no + "_" + pos_no
// Voraussetzung: Entry_Long, SL_Long, Entry_Short, SL_Short sind string-Constants.
// ============================================================================





/**
 * Beschreibung: Erstellt/aktualisiert ein Rectangle-Label als farbige Fläche (Header-Balken, Separator).
 * Parameter:    name   - Objektname
 *               x,y,w,h- Geometrie in Pixeln (Corner LEFT_UPPER)
 *               border - Randfarbe
 *               bg     - Hintergrundfarbe
 *               z      - ZOrder (kleiner als Buttons, größer als Panel-BG)
 * Rückgabewert: bool - true wenn OK, sonst false
 * Hinweise:     UI_Reg_Add wird genutzt, damit Deinit sauber aufräumt.
 * Fehlerfälle:  ObjectCreate schlägt fehl -> false (GetLastError im Log via UI_ObjSetIntSafe, falls aktiv)
 */

bool TP_CreateRect(const string name, const int x, const int y, const int w, const int h,
                   const color border, const color bg, const int z)
  {
   if(ObjectFind(0, name) < 0)
     {
      ResetLastError();
      if(!ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
        {
         Print(__FUNCTION__, ": ObjectCreate failed for '", name, "' err=", GetLastError());
         return false;
        }
     }

   UI_Reg_Add(name);

   UI_ObjSetIntSafe(0, name, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   UI_ObjSetIntSafe(0, name, OBJPROP_XDISTANCE, x);
   UI_ObjSetIntSafe(0, name, OBJPROP_YDISTANCE, y);
   UI_ObjSetIntSafe(0, name, OBJPROP_XSIZE,     w);
   UI_ObjSetIntSafe(0, name, OBJPROP_YSIZE,     h);

   UI_ObjSetIntSafe(0, name, OBJPROP_COLOR,   border);
   UI_ObjSetIntSafe(0, name, OBJPROP_BGCOLOR, bg);

   UI_ObjSetIntSafe(0, name, OBJPROP_SELECTABLE, false);
   UI_ObjSetIntSafe(0, name, OBJPROP_BACK,       false);
   UI_ObjSetIntSafe(0, name, OBJPROP_ZORDER,     z);

   return true;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SortRowsByTradePos(DB_PositionRow &arr[], const int cnt)
  {
   for(int i = 0; i < cnt - 1; i++)
     {
      for(int j = i + 1; j < cnt; j++)
        {
         bool swap = false;

         if(arr[j].trade_no < arr[i].trade_no)
            swap = true;
         else
            if(arr[j].trade_no == arr[i].trade_no && arr[j].pos_no < arr[i].pos_no)
               swap = true;

         if(swap)
           {
            DB_PositionRow tmp = arr[i];
            arr[i] = arr[j];
            arr[j] = tmp;
           }
        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool UI_ParseTradePosFromButtonName(const string name,
                                    const string prefix,
                                    int &trade_no,
                                    int &pos_no)
  {
   trade_no = 0;
   pos_no = 0;

   if(StringFind(name, prefix, 0) != 0)
      return false;

   string rest = StringSubstr(name, StringLen(prefix)); // erwartet "12_3"
   int sep = StringFind(rest, "_", 0);
   if(sep < 1)
      return false;

   trade_no = (int)StringToInteger(StringSubstr(rest, 0, sep));
   pos_no = (int)StringToInteger(StringSubstr(rest, sep + 1));

   return (trade_no > 0 && pos_no > 0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool UI_IsPriceVisible(const double price, const int subwin = 0)
  {
   double pmin = ChartGetDouble(0, CHART_PRICE_MIN, subwin);
   double pmax = ChartGetDouble(0, CHART_PRICE_MAX, subwin);

   double lo = MathMin(pmin, pmax);
   double hi = MathMax(pmin, pmax);

   if(hi <= lo || hi == 0.0)  // Chart noch nicht “ready”
      return true;

   return (price >= lo && price <= hi);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double UI_ChartMidPrice(const int subwin = 0)
  {
   double pmin = ChartGetDouble(0, CHART_PRICE_MIN, subwin);
   double pmax = ChartGetDouble(0, CHART_PRICE_MAX, subwin);

   double lo = MathMin(pmin, pmax);
   double hi = MathMax(pmin, pmax);

   if(hi <= lo || hi == 0.0)
      return SymbolInfoDouble(_Symbol, SYMBOL_BID);

   return (lo + hi) / 2.0; // entspricht “Chart-Höhe/2”
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double UI_DrawPriceOrMid(const double intended_price, const int subwin = 0)
  {
   if(UI_IsPriceVisible(intended_price, subwin))
      return intended_price;
   return UI_ChartMidPrice(subwin);
  }

// ============================================================================
// Löscht ALLE suf-Linien (Entry/SL Long/Short + optional _TAG) für EINEN Trade.
// Trifft Namen wie: Entry_Long_<trade>_<pos>, SL_Long_<trade>_<pos>, ...
// Rückgabe: Anzahl gelöschter Objekte.
// ============================================================================


/**
* Beschreibung: Setzt die Textfarbe eines OBJ_LABEL robust (mit Logging).
* Parameter:    name - Objektname (Label)
*               col  - gewünschte Textfarbe
* Rückgabewert: bool - true wenn gesetzt, sonst false
* Hinweise:     Nutzt ResetLastError/GetLastError für klare Diagnose.
* Fehlerfälle:  Label nicht gefunden oder ObjectSetInteger schlägt fehl -> Print.
*/
bool TP_SetLabelColorChecked(const string name, const color col)
  {
   if(ObjectFind(0, name) < 0)
     {
      Print(__FUNCTION__, ": label not found: ", name);
      return false;
     }

   ResetLastError();
   if(!ObjectSetInteger(0, name, OBJPROP_COLOR, (long)col))
     {
      Print(__FUNCTION__, ": ObjectSetInteger(OBJPROP_COLOR) failed for '", name,
            "' err=", GetLastError());
      return false;
     }

// Optional: aktuellen Farbwert loggen (hilft bei “wird wieder überschrieben”)
   color now = (color)ObjectGetInteger(0, name, OBJPROP_COLOR);
   Print(__FUNCTION__, ": label='", name, "' color now=", (int)now);

   return true;
  }




#ifndef OBJ_ALL_PERIODS
#define OBJ_ALL_PERIODS 0xFFFFFFFF
#endif


#endif // __TRADES_PANEL_MQH__
//====================== end trades_panel.mqh ======================
