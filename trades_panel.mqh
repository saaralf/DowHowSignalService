//======================== trades_panel.mqh ========================
#ifndef __TRADES_PANEL_MQH__
#define __TRADES_PANEL_MQH__

#include "db_state.mqh"   // DB_LoadPositions(), DB_PositionRow

// ---- Object names
#define TP_BG                 "TP_BG"

#define TP_LBL_LONG           "TP_LBL_LONG"
#define TP_LBL_SHORT          "TP_LBL_SHORT"

#define TP_BTN_ACTIVE_LONG    "TP_BTN_ACTIVE_LONG"
#define TP_BTN_ACTIVE_SHORT   "TP_BTN_ACTIVE_SHORT"

#define TP_BTN_CANCEL_LONG    "TP_BTN_CANCEL_LONG"
#define TP_BTN_CANCEL_SHORT   "TP_BTN_CANCEL_SHORT"

#define TP_ROW_LONG_PREFIX    "TP_ROW_LONG_"    // TP_ROW_LONG_12_3
#define TP_ROW_SHORT_PREFIX   "TP_ROW_SHORT_"   // TP_ROW_SHORT_12_3

#define TP_ROW_LONG_Cancel_PREFIX    "TP_ROW_LONG_Cancel_"    // TP_ROW_LONG_12_3_c
#define TP_ROW_SHORT_Cancel_PREFIX   "TP_ROW_SHORT_Cancel_"   // TP_ROW_SHORT_12_3_c


#define TP_ROW_LONG_hitSL_PREFIX    "TP_ROW_LONG_sl_"    // TP_ROW_LONG_12_3_sl
#define TP_ROW_SHORT_hitSL_PREFIX   "TP_ROW_SHORT_sl_"   // TP_ROW_SHORT_12_3_sl


// ---- Layout (anpassen nach Bedarf)
int TP_X=10, TP_Y=40, TP_W=520, TP_H=500;
int TP_PAD=8, TP_GAP=10;
int TP_HDR_H=30;
int TP_BTN_H=26;
int TP_ROW_H=20;

// ================= Helpers =================
void TP_DeleteByPrefix(const string prefix)
  {
   int total = ObjectsTotal(0, -1, -1);
   for(int i=total-1; i>=0; --i)
     {
      string n = ObjectName(0, i);
      if(StringFind(n, prefix, 0) == 0)
         ObjectDelete(0, n);
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

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);

   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, name, OBJPROP_COLOR,   clrDimGray);
   ObjectSetInteger(0, name, OBJPROP_BACK,    false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TP_CreateLabel(const string name, const int x, const int y, const int w, const int h, const string txt)
  {
   if(ObjectFind(0, name) < 0)
      if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
         return false;

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);

   ObjectSetString(0, name, OBJPROP_TEXT, txt);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TP_CreateButton(const string name, const int x, const int y, const int w, const int h, const string txt,
                     const int fontsize=8)
  {
   if(ObjectFind(0, name) < 0)
      if(!ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0))
         return false;

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);

   ObjectSetString(0, name, OBJPROP_TEXT, txt);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontsize);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_STATE, 0);
   return true;
  }

// ================= API: Create / Destroy / Rebuild =================
bool UI_TradesPanel_Create(const int x, const int y, const int w, const int h)
  {
   TP_X=x;
   TP_Y=y;
   TP_W=w;
   TP_H=h;

   int col_w = (TP_W - 2*TP_PAD - TP_GAP) / 2;
   int xL = TP_X + TP_PAD;
   int xR = xL + col_w + TP_GAP;

// BG
   if(!TP_CreateRectBG(TP_BG, TP_X, TP_Y, TP_W, TP_H))
      return false;

// 1) Labels LONG / SHORT
   int y1 = TP_Y + TP_PAD;
   TP_CreateLabel(TP_LBL_LONG,  xL, y1, col_w, TP_HDR_H, "LONG:");
   TP_CreateLabel(TP_LBL_SHORT, xR, y1, col_w, TP_HDR_H, "SHORT:");

// 2) ActiveTrade Buttons
   int y2 = y1 + TP_HDR_H + 6;
   TP_CreateButton(TP_BTN_ACTIVE_LONG,  xL, y2, col_w, TP_BTN_H, "Active Trade", 9);
   TP_CreateButton(TP_BTN_ACTIVE_SHORT, xR, y2, col_w, TP_BTN_H, "Active Trade", 9);

   
   showActive_short(false);
   showActive_long(false);


// 3) CancelTrade Buttons
   int y3 = y2 + TP_BTN_H + 6;
   TP_CreateButton(TP_BTN_CANCEL_LONG,  xL, y3, col_w, TP_BTN_H, "Cancel Trade", 9);
   TP_CreateButton(TP_BTN_CANCEL_SHORT, xR, y3, col_w, TP_BTN_H, "Cancel Trade", 9);

   showCancel_long(false);
   showCancel_short(false);




   ChartRedraw(0);
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void showCancel_long(bool show)
  {

   if(show)
     {
      ObjectSetInteger(0, TP_BTN_CANCEL_LONG, OBJPROP_COLOR, clrBlack);
      ObjectSetInteger(0, TP_BTN_CANCEL_LONG, OBJPROP_BGCOLOR, clrWhite);
      ObjectSetInteger(0, TP_BTN_CANCEL_LONG, OBJPROP_BORDER_COLOR, clrBlack);

     }

   else
     {
      ObjectSetInteger(0, TP_BTN_CANCEL_LONG, OBJPROP_COLOR, clrBlack);
      ObjectSetInteger(0, TP_BTN_CANCEL_LONG, OBJPROP_BGCOLOR, clrBlack);
      ObjectSetInteger(0, TP_BTN_CANCEL_LONG, OBJPROP_BORDER_COLOR, clrBlack);

     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void showActive_long(bool show)
  {

   if(show)
     {
      ObjectSetInteger(0, TP_BTN_ACTIVE_LONG, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, TP_BTN_ACTIVE_LONG, OBJPROP_BGCOLOR, clrRed);
      ObjectSetInteger(0, TP_BTN_ACTIVE_LONG, OBJPROP_BORDER_COLOR, clrWhite);

     }

   else
     {
      ObjectSetInteger(0, TP_BTN_ACTIVE_LONG, OBJPROP_COLOR, clrNONE);
      ObjectSetInteger(0, TP_BTN_ACTIVE_LONG, OBJPROP_BGCOLOR, clrBlack);
      ObjectSetInteger(0, TP_BTN_ACTIVE_LONG, OBJPROP_BORDER_COLOR, clrBlack);

     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void showCancel_short(bool show)
  {

   if(show)
     {
      ObjectSetInteger(0, TP_BTN_CANCEL_SHORT, OBJPROP_COLOR, clrBlack);
      ObjectSetInteger(0, TP_BTN_CANCEL_SHORT, OBJPROP_BGCOLOR, clrWhite);
      ObjectSetInteger(0, TP_BTN_CANCEL_SHORT, OBJPROP_BORDER_COLOR, clrBlack);

     }

   else
     {
      ObjectSetInteger(0, TP_BTN_CANCEL_SHORT, OBJPROP_COLOR, clrBlack);
      ObjectSetInteger(0, TP_BTN_CANCEL_SHORT, OBJPROP_BGCOLOR, clrBlack);
      ObjectSetInteger(0, TP_BTN_CANCEL_SHORT, OBJPROP_BORDER_COLOR, clrBlack);

     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void showActive_short(bool show)
  {

   if(show)
     {
      ObjectSetInteger(0, TP_BTN_ACTIVE_SHORT, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, TP_BTN_ACTIVE_SHORT, OBJPROP_BGCOLOR, clrRed);
      ObjectSetInteger(0, TP_BTN_ACTIVE_SHORT, OBJPROP_BORDER_COLOR, clrWhite);

     }

   else
     {
      ObjectSetInteger(0, TP_BTN_ACTIVE_SHORT, OBJPROP_COLOR, clrNONE);
      ObjectSetInteger(0, TP_BTN_ACTIVE_SHORT, OBJPROP_BGCOLOR, clrBlack);
      ObjectSetInteger(0, TP_BTN_ACTIVE_SHORT, OBJPROP_BORDER_COLOR, clrBlack);

     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UI_TradesPanel_Destroy()
  {
   TP_DeleteByPrefix(TP_ROW_LONG_PREFIX);
   TP_DeleteByPrefix(TP_ROW_SHORT_PREFIX);

   ObjectDelete(0, TP_BG);
   ObjectDelete(0, TP_LBL_LONG);
   ObjectDelete(0, TP_LBL_SHORT);

   ObjectDelete(0, TP_BTN_ACTIVE_LONG);
   ObjectDelete(0, TP_BTN_ACTIVE_SHORT);

   ObjectDelete(0, TP_BTN_CANCEL_LONG);
   ObjectDelete(0, TP_BTN_CANCEL_SHORT);

   ChartRedraw(0);
  }
// 4) je ein Button pro Trade/Pos pro Seite (LONG links / SHORT rechts)
// + Header-Buttons (Active/Cancel) werden hier ebenfalls neu gesetzt/positioniert
void UI_TradesPanel_RebuildRows()
{
   // 0) Safety: Header-Controls sicherstellen (falls aus irgendeinem Grund weg)
   int col_w = (TP_W - 2*TP_PAD - TP_GAP) / 2;
   int xL    = TP_X + TP_PAD;
   int xR    = xL + col_w + TP_GAP;

   // BG + Labels + Header-Buttons (neu setzen/positionieren)
   TP_CreateRectBG(TP_BG, TP_X, TP_Y, TP_W, TP_H);

   int y1 = TP_Y + TP_PAD;
   TP_CreateLabel(TP_LBL_LONG,  xL, y1, col_w, TP_HDR_H, "LONG");
   TP_CreateLabel(TP_LBL_SHORT, xR, y1, col_w, TP_HDR_H, "SHORT");

   int y2 = y1 + TP_HDR_H + 6;
   TP_CreateButton(TP_BTN_ACTIVE_LONG,  xL, y2, col_w, TP_BTN_H, "Active Trade", 9);
   TP_CreateButton(TP_BTN_ACTIVE_SHORT, xR, y2, col_w, TP_BTN_H, "Active Trade", 9);

   int y3 = y2 + TP_BTN_H + 6;
   TP_CreateButton(TP_BTN_CANCEL_LONG,  xL, y3, col_w, TP_BTN_H, "Cancel Trade", 9);
   TP_CreateButton(TP_BTN_CANCEL_SHORT, xR, y3, col_w, TP_BTN_H, "Cancel Trade", 9);

   // 1) alte Rows löschen
   TP_DeleteByPrefix(TP_ROW_LONG_PREFIX);
   TP_DeleteByPrefix(TP_ROW_SHORT_PREFIX);

   // 2) Listbereich berechnen
   int yTop    = y3 + TP_BTN_H + 10;      // nach Cancel-Zeile
   int yBottom = TP_Y + TP_H - TP_PAD;

   int maxRows = (yBottom - yTop) / TP_ROW_H;
   if(maxRows < 1) maxRows = 1;

   // 3) DB laden & Rows bauen
   DB_PositionRow rows[];
   int n = DB_LoadPositions(_Symbol, (ENUM_TIMEFRAMES)_Period, rows);

   int idxL=0, idxR=0;
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   for(int i=0; i<n; i++)
   {
      if(StringFind(rows[i].status,"CLOSED",0)==0)
         continue;

      string txt = StringFormat("T%d P%d  %s  E:%s SL:%s",
                                rows[i].trade_no, rows[i].pos_no, rows[i].status,
                                DoubleToString(rows[i].entry, digits),
                                DoubleToString(rows[i].sl, digits));

      if(rows[i].direction == "LONG")
      {
         if(idxL >= maxRows) continue;
         string name = StringFormat("%s%d_%d", TP_ROW_LONG_PREFIX, rows[i].trade_no, rows[i].pos_no);
         TP_CreateButton(name, xL, yTop + idxL*TP_ROW_H, col_w, TP_ROW_H, txt, 8);
         
         string name_c = StringFormat("%s%d_%d", TP_ROW_LONG_Cancel_PREFIX, rows[i].trade_no, rows[i].pos_no);
         TP_CreateButton(name_c, xL+col_w +10, yTop + idxL*TP_ROW_H, 20, TP_ROW_H, "C", 8);
         string name_s = StringFormat("%s%d_%d", TP_ROW_LONG_hitSL_PREFIX, rows[i].trade_no, rows[i].pos_no);
         TP_CreateButton(name_s, xL+col_w +10+20+10, yTop + idxL*TP_ROW_H, 20, TP_ROW_H, "S", 8);
         
         idxL++;
         showActive_long(true);
         showCancel_long(true);
         
      }
      else if(rows[i].direction == "SHORT")
      {
         if(idxR >= maxRows) continue;
         string name = StringFormat("%s%d_%d", TP_ROW_SHORT_PREFIX, rows[i].trade_no, rows[i].pos_no);
         TP_CreateButton(name, xR, yTop + idxR*TP_ROW_H, col_w, TP_ROW_H, txt, 8);
        
         string name_c = StringFormat("%s%d_%d", TP_ROW_SHORT_Cancel_PREFIX, rows[i].trade_no, rows[i].pos_no);
         TP_CreateButton(name_c, xL+col_w +10, yTop + idxL*TP_ROW_H, 20, TP_ROW_H, "C", 8);
         string name_s = StringFormat("%s%d_%d", TP_ROW_SHORT_hitSL_PREFIX, rows[i].trade_no, rows[i].pos_no);
         TP_CreateButton(name_s, xL+col_w +10+20+10, yTop + idxL*TP_ROW_H, 20, TP_ROW_H, "S", 8);
         
         idxR++;
         showActive_short(true);
         showCancel_short(true);
      }
   }

   ChartRedraw(0);
}


// ================= Optional: Click handling (Rows + Header Buttons) =================
bool UI_TradesPanel_OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(id != CHARTEVENT_OBJECT_CLICK)
      return false;

// Header-Buttons
   if(sparam == TP_BTN_ACTIVE_LONG)
     {
      Print("Active LONG clicked");
      return true;
     }
   if(sparam == TP_BTN_ACTIVE_SHORT)
     {
      Print("Active SHORT clicked");
      return true;
     }
   if(sparam == TP_BTN_CANCEL_LONG)
     {
      Print("Cancel LONG clicked");

      if(is_long_trade)
        {
         // 1) Discord nur EINMAL senden
         DB_PositionRow r;
         r.symbol    = _Symbol;
         r.tf        = TF_ToString((ENUM_TIMEFRAMES)_Period);
         r.direction = "LONG";
         r.trade_no  = active_long_trade_no;
         r.pos_no    = 0;

         string message = FormatCancelTradeMessage(r);
         bool ret = SendDiscordMessage(message);

         // 2) DB: Trade sauber "geschlossen" markieren, damit OnInit ihn NICHT wieder aktiviert
         DB_UpdatePositionStatus(_Symbol, (ENUM_TIMEFRAMES)_Period, "LONG", active_long_trade_no, 0, "CLOSED_CANCEL", 0);

         // 3) Broker-Pending löschen (falls vorhanden)
         DeleteBuyStopOrderForCurrentChart();

         // 4) Runtime-State komplett zurücksetzen
         is_long_trade       = false;
         HitEntryPriceLong   = false;

         // WICHTIG: aktive Tradenummer löschen, sonst "reanimiert" OnInit das wieder
         active_long_trade_no = 0;
         DB_SetMetaInt(DB_Key("active_long_trade_no"), active_long_trade_no);

         // UI cleanup
         ObjectSetInteger(0, TP_BTN_ACTIVE_LONG, OBJPROP_COLOR, clrBlack);
         ObjectSetInteger(0, TP_BTN_ACTIVE_LONG, OBJPROP_BGCOLOR, clrBlack);
         DeleteLinesandLabelsLong();

         // optional: Panels refresh
         UI_UpdateNextTradePosUI();

         UI_RebuildSLHitButtons();
         UI_TradesPanel_RebuildRows();
        }

      return true;
     }
   if(sparam == TP_BTN_CANCEL_SHORT)
     {
      Print("Cancel SHORT clicked");
      if(is_sell_trade)
        {
         DB_PositionRow r;
         r.symbol    = _Symbol;
         r.tf        = TF_ToString((ENUM_TIMEFRAMES)_Period);
         r.direction = "SHORT";
         r.trade_no  = active_short_trade_no;
         r.pos_no    = 0;

         string message = FormatCancelTradeMessage(r);
         bool ret = SendDiscordMessage(message);

         DB_UpdatePositionStatus(_Symbol, (ENUM_TIMEFRAMES)_Period, "SHORT", active_short_trade_no, 0, "CLOSED_CANCEL", 0);

         DeleteSellStopOrderForCurrentChart();

         is_sell_trade         = false;
         is_sell_trade_pending = false;
         HitEntryPriceShort    = false;

         active_short_trade_no = 0;
         DB_SetMetaInt(DB_Key("active_short_trade_no"), active_short_trade_no);

         ObjectSetInteger(0, TP_BTN_ACTIVE_SHORT, OBJPROP_COLOR, clrNONE);
         ObjectSetInteger(0, TP_BTN_ACTIVE_SHORT, OBJPROP_BGCOLOR, clrNONE);
         DeleteLinesandLabelsShort();

         UI_UpdateNextTradePosUI();

         UI_RebuildSLHitButtons();
         UI_TradesPanel_RebuildRows();
        }

      return true;
     }

// Row Buttons
   if(StringFind(sparam, TP_ROW_LONG_PREFIX, 0) == 0)
     {
      Print("Row LONG clicked: ", sparam);
      return true;
     }
   if(StringFind(sparam, TP_ROW_SHORT_PREFIX, 0) == 0)
     {
      Print("Row SHORT clicked: ", sparam);
      return true;
     }

 if(StringFind(sparam, TP_ROW_LONG_Cancel_PREFIX, 0) == 0)
     {
      Print("Row LONG clicked: ", sparam);
      return true;
     }
 if(StringFind(sparam, TP_ROW_LONG_hitSL_PREFIX, 0) == 0)
     {
      Print("Row LONG clicked: ", sparam);
      return true;
     }
   return false;
  }

#endif // __TRADES_PANEL_MQH__
//====================== end trades_panel.mqh ======================
