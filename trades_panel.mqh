//======================== trades_panel.mqh ========================
#ifndef __TRADES_PANEL_MQH__
#define __TRADES_PANEL_MQH__
#include "db_service.mqh"

#include "discord_client.mqh"
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

/**
 * Beschreibung: Setzt Theme-Farben für Buttons (Text/BG/Border).
 * Parameter:    name - Button-Objektname
 *               txt  - Textfarbe
 *               bg   - Hintergrundfarbe
 *               brd  - Randfarbe
 * Rückgabewert: void
 * Hinweise:     Wird nach TP_CreateButton() aufgerufen.
 * Fehlerfälle:  ObjectFind<0 -> keine Aktion.
 */
void TP_StyleBtn(const string name, const color txt, const color bg, const color brd)
  {
   if(ObjectFind(0, name) < 0)
      return;

   UI_ObjSetIntSafe(0, name, OBJPROP_COLOR,        txt);
   UI_ObjSetIntSafe(0, name, OBJPROP_BGCOLOR,      bg);
   UI_ObjSetIntSafe(0, name, OBJPROP_BORDER_COLOR, brd);
  }


// ================= Helpers =================
void TP_DeleteByPrefix(const string prefix)
  {
   int total = ObjectsTotal(0, -1, -1);
   for(int i = total - 1; i >= 0; --i)
     {
      string n = ObjectName(0, i);
      if(StringFind(n, prefix, 0) == 0)
         UI_Reg_DeleteOne(n);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TP_CreateRectBG(const string name, const int x, const int y, const int w, const int h)
  {
   if(ObjectFind(0, name) < 0)
      if(!ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
         return false;
   UI_Reg_Add(name); // Speichere Object im Array zum späteren löschen

   UI_ObjSetIntSafe(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   UI_ObjSetIntSafe(0, name, OBJPROP_XDISTANCE, x);
   UI_ObjSetIntSafe(0, name, OBJPROP_YDISTANCE, y);
   UI_ObjSetIntSafe(0, name, OBJPROP_XSIZE, w);
   UI_ObjSetIntSafe(0, name, OBJPROP_YSIZE, h);



   UI_ObjSetIntSafe(0, name, OBJPROP_ZORDER, 10000);     // ganz nach vorne


// Border = Entry-Farbe, Background = dunkel (passt zu Entry/SL Buttons)
   UI_ObjSetIntSafe(0, name, OBJPROP_COLOR,   PriceButton_bgcolor);
   UI_ObjSetIntSafe(0, name, OBJPROP_BGCOLOR, clrBlack);

   UI_ObjSetIntSafe(0, name, OBJPROP_SELECTABLE, false);
   UI_ObjSetIntSafe(0, name, OBJPROP_BACK, false);

// Panel muss hinter Buttons/Labels bleiben -> kleiner als Button-ZORDER
   UI_ObjSetIntSafe(0, name, OBJPROP_ZORDER, 9990);

   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Del_TP_CreateRectBG(const string name)
  {
   if(!UI_Reg_DeleteOne(name))
      return false;

   return true;
  }
/**
 * Beschreibung: Erstellt oder aktualisiert ein OBJ_LABEL sicher.
 * Parameter:    name - Objektname
 *               x,y  - Position (Corner LEFT_UPPER)
 *               w,h  - Größe (für Label nur begrenzt relevant, aber ok für Layout)
 *               txt  - anzuzeigender Text
 * Rückgabewert: bool - true wenn OK, sonst false
 * Hinweise:     Wenn bereits ein Objekt gleichen Namens existiert, aber NICHT OBJ_LABEL ist,
 *              wird es gelöscht und als OBJ_LABEL neu erstellt (verhindert “geerbte” Button/Rect-Reste).
 * Fehlerfälle:  ObjectCreate/ObjectSet* schlägt fehl -> Print + false
 */
bool TP_CreateLabel(const string name, const int x, const int y, const int w, const int h, const string txt)
{
   // Wenn Objekt existiert: Typ prüfen (sonst kann ein alter Button/Rect den Label-Look kapern)
   if(ObjectFind(0, name) >= 0)
   {
      long t = ObjectGetInteger(0, name, OBJPROP_TYPE);
      if((ENUM_OBJECT)t != OBJ_LABEL)
      {
         ResetLastError();
         if(!ObjectDelete(0, name))
         {
            Print(__FUNCTION__, ": ObjectDelete failed for non-label '", name, "' err=", GetLastError());
            return false;
         }
         UI_Reg_Remove(name); // falls in Registry
      }
   }

   // Erstellen falls nötig
   if(ObjectFind(0, name) < 0)
   {
      ResetLastError();
      if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
      {
         Print(__FUNCTION__, ": ObjectCreate OBJ_LABEL failed '", name, "' err=", GetLastError());
         return false;
      }
      UI_Reg_Add(name); // nur einmal registrieren (neu erstellt)
   }

   // Geometrie
   UI_ObjSetIntSafe(0, name, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   UI_ObjSetIntSafe(0, name, OBJPROP_XDISTANCE, x);
   UI_ObjSetIntSafe(0, name, OBJPROP_YDISTANCE, y);

   // Font/Größe explizit setzen -> garantiert sichtbar (nicht Default-mini)
   ObjectSetString(0, name, OBJPROP_FONT, InpFont);
   UI_ObjSetIntSafe(0, name, OBJPROP_FONTSIZE, 10);

   // Text
   ObjectSetString(0, name, OBJPROP_TEXT, txt);


   UI_ObjSetIntSafe(0, name, OBJPROP_SELECTABLE, false);

   // Ganz nach vorne, damit nichts drüber liegt
   UI_ObjSetIntSafe(0, name, OBJPROP_ZORDER, 20000);

   return true;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TP_CreateButton(const string name, const int x, const int y, const int w, const int h, const string txt,
                     const int fontsize = 8)
  {
   if(ObjectFind(0, name) < 0)
      if(!ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0))
         return false;

   UI_Reg_Add(name); // Speichere Object im Array zum späteren löschen
   UI_ObjSetIntSafe(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   UI_ObjSetIntSafe(0, name, OBJPROP_XDISTANCE, x);
   UI_ObjSetIntSafe(0, name, OBJPROP_YDISTANCE, y);
   UI_ObjSetIntSafe(0, name, OBJPROP_XSIZE, w);
   UI_ObjSetIntSafe(0, name, OBJPROP_YSIZE, h);

   ObjectSetString(0, name, OBJPROP_TEXT, txt);
   UI_ObjSetIntSafe(0, name, OBJPROP_FONTSIZE, InpFontSize);
   ObjectSetString(0, name, OBJPROP_FONT, InpFont);
   UI_ObjSetIntSafe(0, name, OBJPROP_SELECTABLE, false);
   UI_ObjSetIntSafe(0, name, OBJPROP_STATE, 0);
   UI_ObjSetIntSafe(0, name, OBJPROP_ZORDER, 10010);


   return true;
  }

// ================= API: Create / Destroy / Rebuild =================
bool UI_TradesPanel_Create(const int x, const int y, const int w, const int h)
  {
   TP_X = x;
   TP_Y = y;
   TP_H = h;

// gewünschte Breite cappen (wenn aktiv)
   int desired_w = w;
   if(TP_MAX_W > 0)
      desired_w = MathMin(desired_w, TP_MAX_W);
   TP_W = desired_w;

// Spaltenbreite aus gewünschter Breite ableiten (statt “fix 200”)
   int overhead = 2*TP_PAD + TP_GAP + 2*(TP_GAP + BTN_C_W + TP_GAP + BTN_SL_W);
   int col_w = (TP_W - overhead) / 2;
   col_w = MathMax(TP_MIN_COL_W, MathMin(col_w, TP_MAX_COL_W));

   int block_w = col_w + (TP_GAP + BTN_C_W + TP_GAP + BTN_SL_W);

   int xL = TP_X + TP_PAD;
   int xR = xL + block_w + TP_GAP;

// tatsächliche Panelbreite “sauber” setzen (passt exakt zum Layout)
   TP_W = 2*TP_PAD + block_w + TP_GAP + block_w;

// BG
   if(!TP_CreateRectBG(TP_BG, TP_X, TP_Y, TP_W, TP_H))
      return false;

// Header Labels
   int y1 = TP_Y + TP_PAD;
   TP_CreateLabel(TP_LBL_LONG,  xL, y1, col_w, TP_HDR_H, "LONG:");
   TP_CreateLabel(TP_LBL_SHORT, xR, y1, col_w, TP_HDR_H, "SHORT:");
// LONG/SHORT Label-Farben (grün/rot, gut lesbar)

// LONG/SHORT Label-Farben (grün/rot) – NACH dem CreateLabel setzen, sonst wird’s überschrieben
const color LBL_LONG_COL  = (color)C'0,170,100';   // Grün (nicht Neon)
const color LBL_SHORT_COL = (color)C'220,70,70';   // Rot (angenehm)

// Falls du die Labels oben neutral lassen willst, aber trotzdem LONG/SHORT farbig:
UI_ObjSetIntSafe(0, TP_LBL_LONG,  OBJPROP_COLOR, LBL_LONG_COL);
UI_ObjSetIntSafe(0, TP_LBL_SHORT, OBJPROP_COLOR, LBL_SHORT_COL);



// Buttons
   int y2 = y1 + TP_HDR_H + 6;
   TP_CreateButton(TP_BTN_ACTIVE_LONG,  xL, y2, block_w, TP_BTN_H, "Active Trade", InpFontSize);
   TP_CreateButton(TP_BTN_ACTIVE_SHORT, xR, y2, block_w, TP_BTN_H, "Active Trade", InpFontSize);

   showActive_short(false);
   showActive_long(false);

   int y3 = y2 + TP_BTN_H + 6;
   TP_CreateButton(TP_BTN_CANCEL_LONG,  xL, y3, block_w, TP_BTN_H, "Cancel Trade", InpFontSize);
   TP_CreateButton(TP_BTN_CANCEL_SHORT, xR, y3, block_w, TP_BTN_H, "Cancel Trade", InpFontSize);

   showCancel_long(false);
   showCancel_short(false);

   UI_RequestRedraw();
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
   if(ObjectFind(0, name) < 0)
      return;

   if(visible)
     {
      UI_ObjSetIntSafe(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
      ObjectSetString(0, name, OBJPROP_TEXT, caption);

      UI_ObjSetIntSafe(0, name, OBJPROP_COLOR,        txt_col);
      UI_ObjSetIntSafe(0, name, OBJPROP_BGCOLOR,      bg_col);
      UI_ObjSetIntSafe(0, name, OBJPROP_BORDER_COLOR, border_col);
     }
   else
     {
      // wirklich unsichtbar
      UI_ObjSetIntSafe(0, name, OBJPROP_TIMEFRAMES, 0);

      // optional: gegen “Rahmen-Flicker”
      color bg = TP_PanelBg();
      ObjectSetString(0, name, OBJPROP_TEXT, "");
      UI_ObjSetIntSafe(0, name, OBJPROP_COLOR,        bg);
      UI_ObjSetIntSafe(0, name, OBJPROP_BGCOLOR,      bg);
      UI_ObjSetIntSafe(0, name, OBJPROP_BORDER_COLOR, bg);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void showActive_long(bool show)
  {
   TP_SetButtonVisible(TP_BTN_ACTIVE_LONG, show, "Active Trade",
                       PriceButton_font_color, PriceButton_bgcolor, PriceButton_bgcolor);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void showActive_short(bool show)
  {
   TP_SetButtonVisible(TP_BTN_ACTIVE_SHORT, show, "Active Trade",
                       PriceButton_font_color, PriceButton_bgcolor, PriceButton_bgcolor);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void showCancel_long(bool show)
  {
   TP_SetButtonVisible(TP_BTN_CANCEL_LONG, show, "Cancel Trade",
                       SLButton_font_color, SLButton_bgcolor, SLButton_bgcolor);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void showCancel_short(bool show)
  {
   TP_SetButtonVisible(TP_BTN_CANCEL_SHORT, show, "Cancel Trade",
                       SLButton_font_color, SLButton_bgcolor, SLButton_bgcolor);
  }




// ============================================================================
// Löscht Entry/SL-Linien (und optional deren _TAG) für eine konkrete Trade/Pos.
// Passt exakt zu deinem Suffix-Schema: "_" + trade_no + "_" + pos_no
// Voraussetzung: Entry_Long, SL_Long, Entry_Short, SL_Short sind string-Constants.
// ============================================================================



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool UI_DeleteObjectIfExists(const string name)
  {
   if(ObjectFind(0, name) >= 0)
      return UI_Reg_DeleteOne(name);
   UI_Reg_Remove(name); // falls nur Registry-Rest
   return true;

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool UI_DeleteLineAndTag(const string line_name)
  {
   bool ok = true;

   ok = UI_DeleteObjectIfExists(line_name) && ok;

   string tag_name = line_name + LINE_TAG_SUFFIX;
   ok = UI_DeleteObjectIfExists(tag_name) && ok;

   return ok;
  }

// Löscht die 4 möglichen Linien-Namen für genau diese Trade/Pos
// (LONG: Entry_Long_#_# und SL_Long_#_#) + (SHORT: Entry_Short_#_# und SL_Short_#_#)
// -> sicher, auch wenn nur LONG oder nur SHORT existiert.
bool UI_DeleteTradePosLines(const int trade_no, const int pos_no)
  {
   if(trade_no <= 0 || pos_no <= 0)
      return false;

   string suf = "_" + IntegerToString(trade_no) + "_" + IntegerToString(pos_no);

   bool ok = true;
   ok = UI_DeleteLineAndTag(Entry_Long + suf) && ok;
   ok = UI_DeleteLineAndTag(SL_Long + suf) && ok;
   ok = UI_DeleteLineAndTag(Entry_Short + suf) && ok;
   ok = UI_DeleteLineAndTag(SL_Short + suf) && ok;

   return ok;
  }



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

/**
 * Beschreibung: Setzt Farben für ein Button-Objekt (Text/BG/Border) ohne Sichtbarkeitslogik.
 * Parameter:    name   - Button-Objektname
 *               txtCol - Textfarbe
 *               bgCol  - Hintergrundfarbe
 *               brdCol - Randfarbe
 * Rückgabewert: void
 * Hinweise:     Aufrufen NACH TP_CreateButton().
 * Fehlerfälle:  Objekt existiert nicht -> keine Aktion.
 */
void TP_StyleButton(const string name, const color txtCol, const color bgCol, const color brdCol)
  {
   if(ObjectFind(0, name) < 0)
      return;

   UI_ObjSetIntSafe(0, name, OBJPROP_COLOR,        txtCol);
   UI_ObjSetIntSafe(0, name, OBJPROP_BGCOLOR,      bgCol);
   UI_ObjSetIntSafe(0, name, OBJPROP_BORDER_COLOR, brdCol);
  }

/**
 * Beschreibung: Baut das Trades-Panel komplett neu auf (Header + Buttons + Positions-Rows).
 * Parameter:    none
 * Rückgabewert: void
 * Hinweise:     - Panel wird kompakter berechnet (col_w abhängig von TP_W, mit Max-Cap)
 *              - Farben werden an PriceButton (Entry) und SLButton angelehnt
 *              - DB-Logik / Restore Lines bleibt bestehen
 * Fehlerfälle:  DB Load liefert 0 -> Panel zeigt nur Header; keine Exception.
 */
/*
void UI_TradesPanel_RebuildRows()
{
  // ----------------------------------------------------------------
  // 0) Kompaktes Layout berechnen
  // ----------------------------------------------------------------
  const int PANEL_MAX_W     = 460; // "nicht so breit" (bei Bedarf kleiner/größer)
  const int COL_MIN_W       = 140; // Lesbarkeit
  const int COL_MAX_W       = BTN_BREITE; // nutzt dein bestehendes Limit (200)

  // TP_W kommt aus Create() – wir cappen hier nur nach oben
  int desired_w = TP_W;
  if(desired_w > PANEL_MAX_W)
     desired_w = PANEL_MAX_W;

  // Panelbreite = 2*PAD + 2*col_w + GAP(zwischen Blöcken)
  //             + 2*(GAP + C + GAP + S)
  int overhead = 2*TP_PAD + TP_GAP + 2*(TP_GAP + BTN_C_W + TP_GAP + BTN_SL_W);
  int col_w = (desired_w - overhead) / 2;

  if(col_w < COL_MIN_W) col_w = COL_MIN_W;
  if(col_w > COL_MAX_W) col_w = COL_MAX_W;

  int block_w = col_w + TP_GAP + BTN_C_W + TP_GAP + BTN_SL_W;

  int xL = TP_X + TP_PAD;
  int xR = xL + block_w + TP_GAP;

  // tatsächliche Panel-Breite exakt passend setzen
  TP_W = 2*TP_PAD + block_w + TP_GAP + block_w;

  // ----------------------------------------------------------------
  // 1) Header / Panel-BG + Separator + Header-Balken
  // ----------------------------------------------------------------
  TP_CreateRectBG(TP_BG, TP_X, TP_Y, TP_W, TP_H);

  // Panel-Rahmen optisch an Entry/PriceButton koppeln
  UI_ObjSetIntSafe(0, TP_BG, OBJPROP_COLOR,   PriceButton_bgcolor);
  UI_ObjSetIntSafe(0, TP_BG, OBJPROP_BGCOLOR, clrBlack);

  int y1 = TP_Y + TP_PAD;

  // Separator (visuelle Trennung zwischen LONG und SHORT)
  TP_CreateRect(TP_SEP, xL + block_w, TP_Y, TP_GAP, TP_H, clrDimGray, clrDimGray, 10005);

  // Header-Balken (LONG = Entry/PriceTheme, SHORT = SLTheme)
  TP_CreateRect(TP_HDR_LONG_BG,  xL, y1, block_w, TP_HDR_H, PriceButton_bgcolor, PriceButton_bgcolor, 10006);
  TP_CreateRect(TP_HDR_SHORT_BG, xR, y1, block_w, TP_HDR_H, SLButton_bgcolor,    SLButton_bgcolor,    10006);

  // Header Labels (über Balken)
  TP_CreateLabel(TP_LBL_LONG,  xL + 6, y1 + 4, block_w, TP_HDR_H, "LONG");
  TP_CreateLabel(TP_LBL_SHORT, xR + 6, y1 + 4, block_w, TP_HDR_H, "SHORT");

  // Textfarben passend zum Balken
  UI_ObjSetIntSafe(0, TP_LBL_LONG,  OBJPROP_COLOR, clrBlack);
  UI_ObjSetIntSafe(0, TP_LBL_SHORT, OBJPROP_COLOR, clrWhite);

  // Header Buttons (über volle Blockbreite – wirkt "aufgeräumter")
  int y2 = y1 + TP_HDR_H + 6;
  TP_CreateButton(TP_BTN_ACTIVE_LONG,  xL, y2, block_w, TP_BTN_H, "Active Trade", 9);
  TP_CreateButton(TP_BTN_ACTIVE_SHORT, xR, y2, block_w, TP_BTN_H, "Active Trade", 9);

  int y3 = y2 + TP_BTN_H + 6;
  TP_CreateButton(TP_BTN_CANCEL_LONG,  xL, y3, block_w, TP_BTN_H, "Cancel Trade", 9);
  TP_CreateButton(TP_BTN_CANCEL_SHORT, xR, y3, block_w, TP_BTN_H, "Cancel Trade", 9);

  // Theme-Farben setzen (sichtbar/unsichtbar regelt später TP_SetButtonVisible)
  TP_StyleButton(TP_BTN_ACTIVE_LONG,  PriceButton_font_color, PriceButton_bgcolor, PriceButton_bgcolor);
  TP_StyleButton(TP_BTN_ACTIVE_SHORT, PriceButton_font_color, PriceButton_bgcolor, PriceButton_bgcolor);

  TP_StyleButton(TP_BTN_CANCEL_LONG,  SLButton_font_color, SLButton_bgcolor, SLButton_bgcolor);
  TP_StyleButton(TP_BTN_CANCEL_SHORT, SLButton_font_color, SLButton_bgcolor, SLButton_bgcolor);

  // ----------------------------------------------------------------
  // 2) Rows löschen (nur dynamische Rows)
  // ----------------------------------------------------------------
  TP_DeleteByPrefix(TP_ROW_LONG_PREFIX);
  TP_DeleteByPrefix(TP_ROW_SHORT_PREFIX);
  TP_DeleteByPrefix(TP_ROW_LONG_TR_PREFIX);
  TP_DeleteByPrefix(TP_ROW_SHORT_TR_PREFIX);
  TP_DeleteByPrefix(TP_ROW_LONG_Cancel_PREFIX);
  TP_DeleteByPrefix(TP_ROW_SHORT_Cancel_PREFIX);
  TP_DeleteByPrefix(TP_ROW_LONG_hitSL_PREFIX);
  TP_DeleteByPrefix(TP_ROW_SHORT_hitSL_PREFIX);

  // ----------------------------------------------------------------
  // 3) Listbereich
  // ----------------------------------------------------------------
  int yTop = y3 + TP_BTN_H + 10;
  int yBottom = TP_Y + TP_H - TP_PAD;

  int maxRows = (yBottom - yTop) / TP_ROW_H;
  if(maxRows < 1)
     maxRows = 1;

  // ----------------------------------------------------------------
  // 4) DB laden + in LONG/SHORT filtern (inkl. Restore Lines)
  // ----------------------------------------------------------------
  DB_PositionRow rows[];
  int n = g_DB.LoadPositions(_Symbol, (ENUM_TIMEFRAMES)_Period, rows);

  DB_PositionRow longRows[];
  DB_PositionRow shortRows[];
  int nL = 0, nS = 0;

  int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

  for(int i = 0; i < n; i++)
  {
     if(StringFind(rows[i].status, "CLOSED", 0) == 0)
        continue;

     // Restore Entry/SL Lines (pro Position)
     if(rows[i].was_sent == 1 && rows[i].pos_no >= 1 && rows[i].status != "CLOSED")
     {
        int trade_no = rows[i].trade_no;
        int pos_no   = rows[i].pos_no;
        string suf   = "_" + IntegerToString(trade_no) + "_" + IntegerToString(pos_no);

        double entry_draw = UI_DrawPriceOrMid(rows[i].entry, 0);
        double sl_draw    = UI_DrawPriceOrMid(rows[i].sl, 0);

        if(rows[i].direction == "LONG")
        {
           CreateEntryAndSLLines(Entry_Long + suf, TimeCurrent(), entry_draw, TradeEntryLineLong);
           UI_CreateOrUpdateLineTag(Entry_Long + suf);

           CreateEntryAndSLLines(SL_Long + suf, TimeCurrent(), sl_draw, Tradecolor_SLLineLong);
           UI_CreateOrUpdateLineTag(SL_Long + suf);

           g_TradeMgr.SaveTradeLines(suf);
        }
        else
        if(rows[i].direction == "SHORT")
        {
           CreateEntryAndSLLines(Entry_Short + suf, TimeCurrent(), entry_draw, TradeEntryLineShort);
           UI_CreateOrUpdateLineTag(Entry_Short + suf);

           CreateEntryAndSLLines(SL_Short + suf, TimeCurrent(), sl_draw, Tradecolor_SLLineShort);
           UI_CreateOrUpdateLineTag(SL_Short + suf);

           g_TradeMgr.SaveTradeLines(suf);
        }
     }

     if(rows[i].direction == "LONG")
     {
        ArrayResize(longRows, nL + 1);
        longRows[nL] = rows[i];
        nL++;
     }
     else
     if(rows[i].direction == "SHORT")
     {
        ArrayResize(shortRows, nS + 1);
        shortRows[nS] = rows[i];
        nS++;
     }
  }

  // ----------------------------------------------------------------
  // 5) Sortieren (Trade zuerst, dann Position)
  // ----------------------------------------------------------------
  if(nL > 1) SortRowsByTradePos(longRows, nL);
  if(nS > 1) SortRowsByTradePos(shortRows, nS);

  // ----------------------------------------------------------------
  // 6) LONG Seite zeichnen (Trade-Header über den Positionen)
  // ----------------------------------------------------------------
  int  idxL       = 0;
  int  lastTradeL = -1;
  bool anyLong    = false;

  for(int i = 0; i < nL; i++)
  {
     if(idxL >= maxRows)
        break;

     int trade_no = longRows[i].trade_no;
     int pos_no   = longRows[i].pos_no;

     if(trade_no != lastTradeL)
     {
        string txt_tr  = StringFormat("Trade: T%d", trade_no);
        string name_tr = StringFormat("%s%d", TP_ROW_LONG_TR_PREFIX, trade_no);

        TP_CreateButton(name_tr, xL, yTop + idxL * TP_ROW_H, col_w, TP_ROW_H, txt_tr, 8);
        TP_StyleButton(name_tr, clrBlack, PriceButton_bgcolor, PriceButton_bgcolor);

        idxL++;
        if(idxL >= maxRows) break;

        lastTradeL = trade_no;
     }

     string txt = StringFormat("P%d  %s  E:%s SL:%s",
                               pos_no, longRows[i].status,
                               DoubleToString(longRows[i].entry, digits),
                               DoubleToString(longRows[i].sl, digits));

     string name   = StringFormat("%s%d_%d", TP_ROW_LONG_PREFIX,       trade_no, pos_no);
     string name_c = StringFormat("%s%d_%d", TP_ROW_LONG_Cancel_PREFIX, trade_no, pos_no);
     string name_s = StringFormat("%s%d_%d", TP_ROW_LONG_hitSL_PREFIX,  trade_no, pos_no);

     TP_CreateButton(name,   xL,                  yTop + idxL * TP_ROW_H, col_w,   TP_ROW_H, txt, 8);
     TP_CreateButton(name_c, xL + col_w + TP_GAP, yTop + idxL * TP_ROW_H, BTN_C_W, TP_ROW_H, "C", 8);
     TP_CreateButton(name_s, xL + col_w + TP_GAP + BTN_C_W + TP_GAP, yTop + idxL * TP_ROW_H, BTN_SL_W, TP_ROW_H, "S", 8);

     // Row Theme: dunkel + Mini-Buttons rot (SL-Theme)
     TP_StyleButton(name,   clrWhite, clrDarkSlateGray, clrDimGray);
     TP_StyleButton(name_c, clrWhite, SLButton_bgcolor, clrWhite);
     TP_StyleButton(name_s, clrWhite, SLButton_bgcolor, clrWhite);

     idxL++;
     anyLong = true;
  }

  // ----------------------------------------------------------------
  // 7) SHORT Seite zeichnen
  // ----------------------------------------------------------------
  int  idxR       = 0;
  int  lastTradeS = -1;
  bool anyShort   = false;

  for(int i = 0; i < nS; i++)
  {
     if(idxR >= maxRows)
        break;

     int trade_no = shortRows[i].trade_no;
     int pos_no   = shortRows[i].pos_no;

     if(trade_no != lastTradeS)
     {
        string txt_tr  = StringFormat("Trade: T%d", trade_no);
        string name_tr = StringFormat("%s%d", TP_ROW_SHORT_TR_PREFIX, trade_no);

        TP_CreateButton(name_tr, xR, yTop + idxR * TP_ROW_H, col_w, TP_ROW_H, txt_tr, 8);
        TP_StyleButton(name_tr, clrWhite, SLButton_bgcolor, SLButton_bgcolor);

        idxR++;
        if(idxR >= maxRows) break;

        lastTradeS = trade_no;
     }

     string txt = StringFormat("P%d  %s  E:%s SL:%s",
                               pos_no, shortRows[i].status,
                               DoubleToString(shortRows[i].entry, digits),
                               DoubleToString(shortRows[i].sl, digits));

     string name   = StringFormat("%s%d_%d", TP_ROW_SHORT_PREFIX,       trade_no, pos_no);
     string name_c = StringFormat("%s%d_%d", TP_ROW_SHORT_Cancel_PREFIX, trade_no, pos_no);
     string name_s = StringFormat("%s%d_%d", TP_ROW_SHORT_hitSL_PREFIX,  trade_no, pos_no);

     TP_CreateButton(name,   xR,                  yTop + idxR * TP_ROW_H, col_w,   TP_ROW_H, txt, 8);
     TP_CreateButton(name_c, xR + col_w + TP_GAP, yTop + idxR * TP_ROW_H, BTN_C_W, TP_ROW_H, "C", 8);
     TP_CreateButton(name_s, xR + col_w + TP_GAP + BTN_C_W + TP_GAP, yTop + idxR * TP_ROW_H, BTN_SL_W, TP_ROW_H, "S", 8);

     TP_StyleButton(name,   clrWhite, clrDarkSlateGray, clrDimGray);
     TP_StyleButton(name_c, clrWhite, SLButton_bgcolor, clrWhite);
     TP_StyleButton(name_s, clrWhite, SLButton_bgcolor, clrWhite);

     idxR++;
     anyShort = true;
  }

  // ----------------------------------------------------------------
  // 8) Active/Cancel Sichtbarkeit (mit THEME Farben)
  //     (wir rufen TP_SetButtonVisible direkt, damit alte showActive_* Farben egal sind)
  // ----------------------------------------------------------------
  if(anyLong)
  {
     TP_SetButtonVisible(TP_BTN_ACTIVE_LONG, true, "Active Trade",
                         PriceButton_font_color, PriceButton_bgcolor, PriceButton_bgcolor);
     TP_SetButtonVisible(TP_BTN_CANCEL_LONG, true, "Cancel Trade",
                         SLButton_font_color, SLButton_bgcolor, SLButton_bgcolor);
  }
  else
  {
     TP_SetButtonVisible(TP_BTN_ACTIVE_LONG, false, "", clrBlack, clrBlack, clrBlack);
     TP_SetButtonVisible(TP_BTN_CANCEL_LONG, false, "", clrBlack, clrBlack, clrBlack);
  }

  if(anyShort)
  {
     TP_SetButtonVisible(TP_BTN_ACTIVE_SHORT, true, "Active Trade",
                         PriceButton_font_color, PriceButton_bgcolor, PriceButton_bgcolor);
     TP_SetButtonVisible(TP_BTN_CANCEL_SHORT, true, "Cancel Trade",
                         SLButton_font_color, SLButton_bgcolor, SLButton_bgcolor);
  }
  else
  {
     TP_SetButtonVisible(TP_BTN_ACTIVE_SHORT, false, "", clrBlack, clrBlack, clrBlack);
     TP_SetButtonVisible(TP_BTN_CANCEL_SHORT, false, "", clrBlack, clrBlack, clrBlack);
  }

  UI_UpdateAllLineTags();

  // keine “Hard-Redraw-Orgie” – dein System kann throttlen
  UI_RequestRedraw();
}
*/
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



/**
* Beschreibung: Zentraler Click-Dispatcher für das Trades-Panel.
* Parameter:    id     - ChartEvent-ID (wir reagieren nur auf OBJECT_CLICK)
*               lparam - vom ChartEvent (ungenutzt)
*               dparam - vom ChartEvent (ungenutzt)
*               sparam - Objektname, der geklickt wurde
* Rückgabewert: bool - true, wenn Event behandelt wurde, sonst false
* Hinweise:     Keine doppelte Logik; Header-Buttons + Row-Buttons sauber getrennt.
* Fehlerfälle:  Parsing-Fehler bei Row-Buttons -> kein Close/Notify, aber Event gilt als behandelt.
*/
bool UI_TradesPanel_OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(id != CHARTEVENT_OBJECT_CLICK)
      return false;

// ------------------------------------------------------------
// 1) Header-Buttons
// ------------------------------------------------------------

// Active-Buttons sind derzeit reine Status-Anzeige -> Klick "schlucken"
   if(sparam == TP_BTN_ACTIVE_LONG || sparam == TP_BTN_ACTIVE_SHORT)
      return true;


   if(sparam == TP_BTN_CANCEL_LONG)
     {
      UI_CancelActiveTrade("LONG");
      UI_TradesPanel_RebuildRows();
      UI_RequestRedraw();
      return true;
     }

   if(sparam == TP_BTN_CANCEL_SHORT)
     {
      UI_CancelActiveTrade("SHORT");
      UI_TradesPanel_RebuildRows();
      UI_RequestRedraw();
      return true;
     }

// ------------------------------------------------------------
// 2) Row-Buttons (Cancel / HitSL) je TradeNo + PosNo
// ------------------------------------------------------------
   int trade_no = 0, pos_no = 0;

// LONG Cancel
   if(StringFind(sparam, TP_ROW_LONG_Cancel_PREFIX, 0) == 0)
     {
      if(UI_ParseTradePosFromButtonName(sparam, TP_ROW_LONG_Cancel_PREFIX, trade_no, pos_no))
        {
         UI_CloseOnePositionAndNotify("CANCEL", "LONG", trade_no, pos_no);
         UI_TradesPanel_RebuildRows();
         UI_RequestRedraw();
        }
      return true;
     }

// LONG HitSL
   if(StringFind(sparam, TP_ROW_LONG_hitSL_PREFIX, 0) == 0)
     {
      if(UI_ParseTradePosFromButtonName(sparam, TP_ROW_LONG_hitSL_PREFIX, trade_no, pos_no))
        {
         UI_CloseOnePositionAndNotify("HIT_SL", "LONG", trade_no, pos_no);
         UI_TradesPanel_RebuildRows();
         UI_RequestRedraw();
        }
      return true;
     }

// SHORT Cancel
   if(StringFind(sparam, TP_ROW_SHORT_Cancel_PREFIX, 0) == 0)
     {
      if(UI_ParseTradePosFromButtonName(sparam, TP_ROW_SHORT_Cancel_PREFIX, trade_no, pos_no))
        {
         UI_CloseOnePositionAndNotify("CANCEL", "SHORT", trade_no, pos_no);
         UI_TradesPanel_RebuildRows();
         UI_RequestRedraw();
        }
      return true;
     }

// SHORT HitSL
   if(StringFind(sparam, TP_ROW_SHORT_hitSL_PREFIX, 0) == 0)
     {
      if(UI_ParseTradePosFromButtonName(sparam, TP_ROW_SHORT_hitSL_PREFIX, trade_no, pos_no))
        {
         UI_CloseOnePositionAndNotify("HIT_SL", "SHORT", trade_no, pos_no);
         UI_TradesPanel_RebuildRows();
         UI_RequestRedraw();
        }
      return true;
     }

   return false;
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int UI_DeleteTradeLinesByTradeNo(const int trade_no)
  {
   if(trade_no <= 0)
      return 0;

// Muster: Prefix + "_" + trade_no + "_"
   string mid = "_" + IntegerToString(trade_no) + "_";

   string p1 = Entry_Long + mid;
   string p2 = SL_Long + mid;
   string p3 = Entry_Short + mid;
   string p4 = SL_Short + mid;

   int deleted = 0;

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

  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool UI_DeleteLineAndAllKnownTags(const string line_name)
  {
   bool ok = true;

   ok = UI_DeleteObjectIfExists(line_name) && ok;
   ok = UI_DeleteObjectIfExists(line_name + LINE_TAG_SUFFIX) && ok;

// Legacy: LabelEntry*/LabelSL* mit gleichem Suffix (falls mal erzeugt)
// Suffix aus line_name extrahieren (alles ab letztem "Entry_*" / "SL_*" bleibt gleich)
// Einfacher: Kandidaten auf Basis der bekannten Prefixe:
// Entry_Long_1_2  ->  LabelEntryLong_1_2
   string suf = "";
   int p = StringFind(line_name, "_", 0);
// robust: nimm die letzten 2 "_<trade>_<pos>" Teile
   string parts[];
   int n = StringSplit(line_name, '_', parts);
   if(n >= 3)
      suf = "_" + parts[n-2] + "_" + parts[n-1];

   if(suf != "")
     {
      if(StringFind(line_name, "Entry_Long_", 0) == 0)
         ok = UI_DeleteObjectIfExists(LabelEntryLong  + suf) && ok;
      if(StringFind(line_name, "SL_Long_", 0)    == 0)
         ok = UI_DeleteObjectIfExists(LabelSLLong     + suf) && ok;
      if(StringFind(line_name, "Entry_Short_",0) == 0)
         ok = UI_DeleteObjectIfExists(LabelEntryShort + suf) && ok;
      if(StringFind(line_name, "SL_Short_", 0)   == 0)
         ok = UI_DeleteObjectIfExists(LabelSLShort    + suf) && ok;
     }

   return ok;
  }

/**
 * Beschreibung: Baut das Trades-Panel komplett neu auf (Header + Active/Cancel + Rows).
 * Parameter:    keine
 * Rückgabewert: void
 * Hinweise:     - Panel wird kompakter berechnet (Max-Breite gecappt).
 *              - LONG/SHORT Header-Look ist neutral (keine Blau/Rot Labels).
 *              - Action-Buttons (Active/Cancel) verwenden Entry/SL Theme-Farben.
 *              - Rows werden neu erzeugt, Trade-Linien können aus DB restored werden.
 * Fehlerfälle:  DB Load kann 0 liefern -> Panel zeigt nur Header/Buttons, keine Rows.
 */
void UI_TradesPanel_RebuildRows()
  {
// ----------------------------------------------------------------
// 0) Kompaktes Layout berechnen (schmaler als vorher)
// ----------------------------------------------------------------
   const int PANEL_MAX_W = 460;  // <== hier stellst du "nicht so breit" ein
   const int COL_MIN_W   = 140;  // Minimum für Lesbarkeit
   const int COL_MAX_W   = BTN_BREITE; // nutzt deinen aktuellen Limit-Wert (z.B. 200)

// Wunschbreite aus TP_W, aber nach oben cappen
   int desired_w = TP_W;
   if(desired_w > PANEL_MAX_W)
      desired_w = PANEL_MAX_W;

// 2 Blöcke: [TextSpalte + GAP + C + GAP + S] + MitteGAP + PADs
   int overhead = 2*TP_PAD + TP_GAP + 2*(TP_GAP + BTN_C_W + TP_GAP + BTN_SL_W);
   int col_w = (desired_w - overhead) / 2;

   if(col_w < COL_MIN_W)
      col_w = COL_MIN_W;
   if(col_w > COL_MAX_W)
      col_w = COL_MAX_W;

   int block_w = col_w + TP_GAP + BTN_C_W + TP_GAP + BTN_SL_W;

   int xL = TP_X + TP_PAD;
   int xR = xL + block_w + TP_GAP;

// Panelbreite exakt passend setzen (verhindert "zu breit")
   TP_W = 2*TP_PAD + block_w + TP_GAP + block_w;

// ----------------------------------------------------------------
// 1) Panel Background + neutraler Header (LONG/SHORT nicht blau/rot)
// ----------------------------------------------------------------
   TP_CreateRectBG(TP_BG, TP_X, TP_Y, TP_W, TP_H);

// Panel Theme: Border an Entry-Farbe anlehnen, Background dunkel
   UI_ObjSetIntSafe(0, TP_BG, OBJPROP_COLOR,   PriceButton_bgcolor);
   UI_ObjSetIntSafe(0, TP_BG, OBJPROP_BGCOLOR, clrBlack);

// Zusätzliche Header/Separator-Objekte (lokale Namen, keine Defines nötig)
   const string TP_HDR_LONG_BG  = "TP_HDR_LONG_BG";
   const string TP_HDR_SHORT_BG = "TP_HDR_SHORT_BG";
   const string TP_SEP          = "TP_SEP";

   const color HDR_BG     = (color)C'22,22,22';      // Anthrazit
   const color HDR_BORDER = (color)C'70,70,70';      // dezenter Rahmen
   const color HDR_TXT    = (color)C'230,230,230';   // helles Grau (clean)

   int y1 = TP_Y + TP_PAD;

// Separator zwischen LONG/SHORT (dezente Trennung)
   TP_CreateRectBG(TP_SEP, xL + block_w, TP_Y, TP_GAP, TP_H);
   UI_ObjSetIntSafe(0, TP_SEP, OBJPROP_COLOR,   clrDimGray);
   UI_ObjSetIntSafe(0, TP_SEP, OBJPROP_BGCOLOR, clrDimGray);
   UI_ObjSetIntSafe(0, TP_SEP, OBJPROP_ZORDER,  10002);

// Header-Balken (neutral, KEIN blau/rot)
   TP_CreateRectBG(TP_HDR_LONG_BG,  xL, y1, block_w, TP_HDR_H);
   UI_ObjSetIntSafe(0, TP_HDR_LONG_BG, OBJPROP_COLOR,   HDR_BORDER);
   UI_ObjSetIntSafe(0, TP_HDR_LONG_BG, OBJPROP_BGCOLOR, HDR_BG);
   UI_ObjSetIntSafe(0, TP_HDR_LONG_BG, OBJPROP_ZORDER,  10003);

   TP_CreateRectBG(TP_HDR_SHORT_BG, xR, y1, block_w, TP_HDR_H);
   UI_ObjSetIntSafe(0, TP_HDR_SHORT_BG, OBJPROP_COLOR,   HDR_BORDER);
   UI_ObjSetIntSafe(0, TP_HDR_SHORT_BG, OBJPROP_BGCOLOR, HDR_BG);
   UI_ObjSetIntSafe(0, TP_HDR_SHORT_BG, OBJPROP_ZORDER,  10003);

// Header Labels (neutral)
   TP_CreateLabel(TP_LBL_LONG,  xL + 6, y1 + 6, block_w, TP_HDR_H, "LONG");
   TP_CreateLabel(TP_LBL_SHORT, xR + 6, y1 + 6, block_w, TP_HDR_H, "SHORT");
   // Header Labels (neutral) + Farben in einem Schritt
   TP_CreateLabelStyled(TP_LBL_LONG,  xL + 6, y1 + 6, block_w, TP_HDR_H, "LONG",  LBL_LONG_COL);
   TP_CreateLabelStyled(TP_LBL_SHORT, xR + 6, y1 + 6, block_w, TP_HDR_H, "SHORT", LBL_SHORT_COL);

// LONG/SHORT Label-Farben (grün/rot, gut lesbar)
   const color LBL_LONG_COL  = (color)C'0,170,100';   // Grün (nicht Neon)
   const color LBL_SHORT_COL = (color)C'220,70,70';   // Rot (angenehm)

   UI_ObjSetIntSafe(0, TP_LBL_LONG,  OBJPROP_COLOR, LBL_LONG_COL);
   UI_ObjSetIntSafe(0, TP_LBL_SHORT, OBJPROP_COLOR, LBL_SHORT_COL);



// Active/Cancel Buttons (Theme Entry/SL)
   int y2 = y1 + TP_HDR_H + 6;
   TP_CreateButton(TP_BTN_ACTIVE_LONG,  xL, y2, block_w, TP_BTN_H, "Active Trade", 9);
   TP_CreateButton(TP_BTN_ACTIVE_SHORT, xR, y2, block_w, TP_BTN_H, "Active Trade", 9);

   int y3 = y2 + TP_BTN_H + 6;
   TP_CreateButton(TP_BTN_CANCEL_LONG,  xL, y3, block_w, TP_BTN_H, "Cancel Trade", 9);
   TP_CreateButton(TP_BTN_CANCEL_SHORT, xR, y3, block_w, TP_BTN_H, "Cancel Trade", 9);

// Erstmal unsichtbar; wird am Ende je nach Content sichtbar geschaltet
   TP_SetButtonVisible(TP_BTN_ACTIVE_LONG,  false, "", clrBlack, clrBlack, clrBlack);
   TP_SetButtonVisible(TP_BTN_ACTIVE_SHORT, false, "", clrBlack, clrBlack, clrBlack);
   TP_SetButtonVisible(TP_BTN_CANCEL_LONG,  false, "", clrBlack, clrBlack, clrBlack);
   TP_SetButtonVisible(TP_BTN_CANCEL_SHORT, false, "", clrBlack, clrBlack, clrBlack);

// ----------------------------------------------------------------
// 2) Dynamische Rows löschen
// ----------------------------------------------------------------
   TP_DeleteByPrefix(TP_ROW_LONG_PREFIX);
   TP_DeleteByPrefix(TP_ROW_SHORT_PREFIX);
   TP_DeleteByPrefix(TP_ROW_LONG_TR_PREFIX);
   TP_DeleteByPrefix(TP_ROW_SHORT_TR_PREFIX);
   TP_DeleteByPrefix(TP_ROW_LONG_Cancel_PREFIX);
   TP_DeleteByPrefix(TP_ROW_SHORT_Cancel_PREFIX);
   TP_DeleteByPrefix(TP_ROW_LONG_hitSL_PREFIX);
   TP_DeleteByPrefix(TP_ROW_SHORT_hitSL_PREFIX);

// ----------------------------------------------------------------
// 3) Listbereich / maxRows
// ----------------------------------------------------------------
   int yTop    = y3 + TP_BTN_H + 10;
   int yBottom = TP_Y + TP_H - TP_PAD;

   int maxRows = (yBottom - yTop) / TP_ROW_H;
   if(maxRows < 1)
      maxRows = 1;

// ----------------------------------------------------------------
// 4) DB laden + LONG/SHORT filtern + Lines restoren
// ----------------------------------------------------------------
   DB_PositionRow rows[];
   int n = g_DB.LoadPositions(_Symbol, (ENUM_TIMEFRAMES)_Period, rows);

   DB_PositionRow longRows[];
   DB_PositionRow shortRows[];
   int nL = 0, nS = 0;

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   for(int i = 0; i < n; i++)
     {
      if(StringFind(rows[i].status, "CLOSED", 0) == 0)
         continue;

      // Restore Entry/SL Lines (pro Position)
      if(rows[i].was_sent == 1 && rows[i].pos_no >= 1 && rows[i].status != "CLOSED")
        {
         int trade_no = rows[i].trade_no;
         int pos_no   = rows[i].pos_no;
         string suf   = "_" + IntegerToString(trade_no) + "_" + IntegerToString(pos_no);

         double entry_draw = UI_DrawPriceOrMid(rows[i].entry, 0);
         double sl_draw    = UI_DrawPriceOrMid(rows[i].sl, 0);

         if(rows[i].direction == "LONG")
           {
            CreateEntryAndSLLines(Entry_Long + suf, TimeCurrent(), entry_draw, TradeEntryLineLong);
       
            CreateEntryAndSLLines(SL_Long + suf, TimeCurrent(), sl_draw, Tradecolor_SLLineLong);
     

            g_TradeMgr.SaveTradeLines(suf);
           }
         else
            if(rows[i].direction == "SHORT")
              {
               CreateEntryAndSLLines(Entry_Short + suf, TimeCurrent(), entry_draw, TradeEntryLineShort);
    

               CreateEntryAndSLLines(SL_Short + suf, TimeCurrent(), sl_draw, Tradecolor_SLLineShort);
              

               g_TradeMgr.SaveTradeLines(suf);
              }
        }

      // Filtern
      if(rows[i].direction == "LONG")
        {
         ArrayResize(longRows, nL + 1);
         longRows[nL] = rows[i];
         nL++;
        }
      else
         if(rows[i].direction == "SHORT")
           {
            ArrayResize(shortRows, nS + 1);
            shortRows[nS] = rows[i];
            nS++;
           }
     }

// Sortieren (TradeNo/PosNo)
   if(nL > 1)
      SortRowsByTradePos(longRows, nL);
   if(nS > 1)
      SortRowsByTradePos(shortRows, nS);

// ----------------------------------------------------------------
// 5) LONG Rows zeichnen
// ----------------------------------------------------------------
   int  idxL       = 0;
   int  lastTradeL = -1;
   bool anyLong    = false;

   for(int i = 0; i < nL; i++)
     {
      if(idxL >= maxRows)
         break;

      int trade_no = longRows[i].trade_no;
      int pos_no   = longRows[i].pos_no;

      // Trade-Header (LONG) -> grün + Text enthält "LONG"
      if(trade_no != lastTradeL)
        {
         const color TR_LONG_BG   = (color)C'0,150,90';   // angenehmes Grün (nicht Neon)
         const color TR_LONG_TXT  = clrWhite;
         const color TR_LONG_BRD  = (color)C'0,120,70';

         string txt_tr  = StringFormat("LONG  T%d", trade_no);
         string name_tr = StringFormat("%s%d", TP_ROW_LONG_TR_PREFIX, trade_no);

         TP_CreateButton(name_tr, xL, yTop + idxL * TP_ROW_H, col_w, TP_ROW_H, txt_tr, 8);

         // Theme setzen
         UI_ObjSetIntSafe(0, name_tr, OBJPROP_COLOR,        TR_LONG_TXT);
         UI_ObjSetIntSafe(0, name_tr, OBJPROP_BGCOLOR,      TR_LONG_BG);
         UI_ObjSetIntSafe(0, name_tr, OBJPROP_BORDER_COLOR, TR_LONG_BRD);

         idxL++;
         if(idxL >= maxRows)
            break;

         lastTradeL = trade_no;
        }


      string txt = StringFormat("P%d  %s  E:%s SL:%s",
                                pos_no, longRows[i].status,
                                DoubleToString(longRows[i].entry, digits),
                                DoubleToString(longRows[i].sl, digits));

      string name   = StringFormat("%s%d_%d", TP_ROW_LONG_PREFIX,        trade_no, pos_no);
      string name_c = StringFormat("%s%d_%d", TP_ROW_LONG_Cancel_PREFIX, trade_no, pos_no);
      string name_s = StringFormat("%s%d_%d", TP_ROW_LONG_hitSL_PREFIX,  trade_no, pos_no);

      TP_CreateButton(name,   xL,                    yTop + idxL * TP_ROW_H, col_w,   TP_ROW_H, txt, 8);
      TP_CreateButton(name_c, xL + col_w + TP_GAP,   yTop + idxL * TP_ROW_H, BTN_C_W, TP_ROW_H, "C", 8);
      TP_CreateButton(name_s, xL + col_w + TP_GAP + BTN_C_W + TP_GAP, yTop + idxL * TP_ROW_H, BTN_SL_W, TP_ROW_H, "S", 8);

      // Row Theme: dunkel + Mini-Buttons SL-Farbe (visuell konsistent)
      UI_ObjSetIntSafe(0, name,   OBJPROP_COLOR,        clrWhite);
      UI_ObjSetIntSafe(0, name,   OBJPROP_BGCOLOR,      clrDarkSlateGray);
      UI_ObjSetIntSafe(0, name,   OBJPROP_BORDER_COLOR, clrDimGray);

      UI_ObjSetIntSafe(0, name_c, OBJPROP_COLOR,        SLButton_font_color);
      UI_ObjSetIntSafe(0, name_c, OBJPROP_BGCOLOR,      SLButton_bgcolor);
      UI_ObjSetIntSafe(0, name_c, OBJPROP_BORDER_COLOR, clrWhite);

      UI_ObjSetIntSafe(0, name_s, OBJPROP_COLOR,        SLButton_font_color);
      UI_ObjSetIntSafe(0, name_s, OBJPROP_BGCOLOR,      SLButton_bgcolor);
      UI_ObjSetIntSafe(0, name_s, OBJPROP_BORDER_COLOR, clrWhite);

      idxL++;
      anyLong = true;
     }

// ----------------------------------------------------------------
// 6) SHORT Rows zeichnen
// ----------------------------------------------------------------
   int  idxR       = 0;
   int  lastTradeS = -1;
   bool anyShort   = false;

   for(int i = 0; i < nS; i++)
     {
      if(idxR >= maxRows)
         break;

      int trade_no = shortRows[i].trade_no;
      int pos_no   = shortRows[i].pos_no;

      // Trade-Header (SHORT) -> rot + Text enthält "SHORT"
      if(trade_no != lastTradeS)
        {
         const color TR_SHORT_BG  = (color)C'200,60,60';  // angenehmes Rot
         const color TR_SHORT_TXT = clrWhite;
         const color TR_SHORT_BRD = (color)C'160,40,40';

         string txt_tr  = StringFormat("SHORT T%d", trade_no);
         string name_tr = StringFormat("%s%d", TP_ROW_SHORT_TR_PREFIX, trade_no);

         TP_CreateButton(name_tr, xR, yTop + idxR * TP_ROW_H, col_w, TP_ROW_H, txt_tr, 8);

         // Theme setzen
         UI_ObjSetIntSafe(0, name_tr, OBJPROP_COLOR,        TR_SHORT_TXT);
         UI_ObjSetIntSafe(0, name_tr, OBJPROP_BGCOLOR,      TR_SHORT_BG);
         UI_ObjSetIntSafe(0, name_tr, OBJPROP_BORDER_COLOR, TR_SHORT_BRD);

         idxR++;
         if(idxR >= maxRows)
            break;

         lastTradeS = trade_no;
        }


      string txt = StringFormat("P%d  %s  E:%s SL:%s",
                                pos_no, shortRows[i].status,
                                DoubleToString(shortRows[i].entry, digits),
                                DoubleToString(shortRows[i].sl, digits));

      string name   = StringFormat("%s%d_%d", TP_ROW_SHORT_PREFIX,        trade_no, pos_no);
      string name_c = StringFormat("%s%d_%d", TP_ROW_SHORT_Cancel_PREFIX, trade_no, pos_no);
      string name_s = StringFormat("%s%d_%d", TP_ROW_SHORT_hitSL_PREFIX,  trade_no, pos_no);

      TP_CreateButton(name,   xR,                    yTop + idxR * TP_ROW_H, col_w,   TP_ROW_H, txt, 8);
      TP_CreateButton(name_c, xR + col_w + TP_GAP,   yTop + idxR * TP_ROW_H, BTN_C_W, TP_ROW_H, "C", 8);
      TP_CreateButton(name_s, xR + col_w + TP_GAP + BTN_C_W + TP_GAP, yTop + idxR * TP_ROW_H, BTN_SL_W, TP_ROW_H, "S", 8);

      UI_ObjSetIntSafe(0, name,   OBJPROP_COLOR,        clrWhite);
      UI_ObjSetIntSafe(0, name,   OBJPROP_BGCOLOR,      clrDarkSlateGray);
      UI_ObjSetIntSafe(0, name,   OBJPROP_BORDER_COLOR, clrDimGray);

      UI_ObjSetIntSafe(0, name_c, OBJPROP_COLOR,        SLButton_font_color);
      UI_ObjSetIntSafe(0, name_c, OBJPROP_BGCOLOR,      SLButton_bgcolor);
      UI_ObjSetIntSafe(0, name_c, OBJPROP_BORDER_COLOR, clrWhite);

      UI_ObjSetIntSafe(0, name_s, OBJPROP_COLOR,        SLButton_font_color);
      UI_ObjSetIntSafe(0, name_s, OBJPROP_BGCOLOR,      SLButton_bgcolor);
      UI_ObjSetIntSafe(0, name_s, OBJPROP_BORDER_COLOR, clrWhite);

      idxR++;
      anyShort = true;
     }

// ----------------------------------------------------------------
// 7) Active/Cancel sichtbar schalten (Theme Entry/SL)
// ----------------------------------------------------------------
   if(anyLong)
     {
      TP_SetButtonVisible(TP_BTN_ACTIVE_LONG, true, "Active Trade",
                          PriceButton_font_color, PriceButton_bgcolor, PriceButton_bgcolor);

      TP_SetButtonVisible(TP_BTN_CANCEL_LONG, true, "Cancel Trade",
                          SLButton_font_color, SLButton_bgcolor, SLButton_bgcolor);
     }

   if(anyShort)
     {
      TP_SetButtonVisible(TP_BTN_ACTIVE_SHORT, true, "Active Trade",
                          PriceButton_font_color, PriceButton_bgcolor, PriceButton_bgcolor);

      TP_SetButtonVisible(TP_BTN_CANCEL_SHORT, true, "Cancel Trade",
                          SLButton_font_color, SLButton_bgcolor, SLButton_bgcolor);
     }

   UI_UpdateAllLineTags();



   // Letzter Schritt: Header-Labels "hart" einfärben (falls später irgendwas wieder auf Weiß setzt)
   TP_SetLabelColorChecked(TP_LBL_LONG,  LBL_LONG_COL);
   TP_SetLabelColorChecked(TP_LBL_SHORT, LBL_SHORT_COL);

// Kein hartes ChartRedraw hier -> throttling über UI_RequestRedraw/OnChartEvent
   UI_RequestRedraw();
  }


#ifndef OBJ_ALL_PERIODS
#define OBJ_ALL_PERIODS 0xFFFFFFFF
#endif

/**
 * Beschreibung: Erstellt/updated ein Label und setzt sofort Style (Farbe + Sichtbarkeit).
 * Parameter:    name - Objektname
 *               x,y,w,h - Position/Größe
 *               txt  - Text
 *               txt_color - Textfarbe
 * Rückgabewert: bool - true wenn OK
 * Hinweise:     Verhindert “wird wieder weiß” durch spätere Default-Styles.
 * Fehlerfälle:  TP_CreateLabel scheitert -> false + Print aus TP_CreateLabel.
 */
bool TP_CreateLabelStyled(const string name,
                          const int x, const int y,
                          const int w, const int h,
                          const string txt,
                          const color txt_color)
{
   if(!TP_CreateLabel(name, x, y, w, h, txt))
      return false;

   // Auf allen Perioden sichtbar (robust bei TF-Wechsel)
   ResetLastError();
   ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, (long)OBJ_ALL_PERIODS);

   // Farbe setzen (explizit, weil TP_CreateLabel default = clrWhite)
   ResetLastError();
   ObjectSetInteger(0, name, OBJPROP_COLOR, (long)txt_color);

   return true;
}

#endif // __TRADES_PANEL_MQH__
//====================== end trades_panel.mqh ======================
