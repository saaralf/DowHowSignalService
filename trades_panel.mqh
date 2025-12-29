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

#define TP_ROW_LONG_TR_PREFIX    "TP_ROW_LONG_TR_"    // TP_ROW_LONG_12 Tradesnummern!
#define TP_ROW_SHORT_TR_PREFIX   "TP_ROW_SHORT_TR_"   // TP_ROW_SHORT_12


#define TP_ROW_LONG_TR_Cancel_PREFIX    "TP_ROW_LONG_TR_Cancel_"    // TP_ROW_LONG_12_c
#define TP_ROW_SHORT_TR_Cancel_PREFIX   "TP_ROW_SHORT_TR_Cancel_"   // TP_ROW_SHORT_12_c

#define TP_ROW_LONG_PREFIX    "TP_ROW_LONG_"    // TP_ROW_LONG_3 Positionen
#define TP_ROW_SHORT_PREFIX   "TP_ROW_SHORT_"   // TP_ROW_SHORT_3 Positionen!


#define TP_ROW_LONG_Cancel_PREFIX    "TP_ROW_LONG_Cancel_"    // TP_ROW_LONG_3_c
#define TP_ROW_SHORT_Cancel_PREFIX   "TP_ROW_SHORT_Cancel_"   // TP_ROW_SHORT_3_c


#define TP_ROW_LONG_hitSL_PREFIX    "TP_ROW_LONG_sl_"    // TP_ROW_LONG_3_sl
#define TP_ROW_SHORT_hitSL_PREFIX   "TP_ROW_SHORT_sl_"   // TP_ROW_SHORT_3_sl


// ---- Layout (anpassen nach Bedarf)
int TP_X=10, TP_Y=40, TP_W=520, TP_H=500;
int TP_PAD=8, TP_GAP=10;
int TP_HDR_H=30;
int TP_BTN_H=26;
int TP_ROW_H=20;
int BTN_BREITE=200;

int BTN_C_W=20;//Breite der C Buttons
int BTN_SL_W=20; // Breite der S Buttons
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

   ObjectSetInteger(0, name, OBJPROP_COLOR,   clrDimGray);

   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrBlack);   // NICHT clrNONE
   ObjectSetInteger(0, name, OBJPROP_BACK,    false);      // Vordergrund
   ObjectSetInteger(0, name, OBJPROP_ZORDER,  10000);      // ganz nach vorne

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
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 10010);
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
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, InpFontSize);
   ObjectSetString(0, name, OBJPROP_FONT, InpFont);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_STATE, 0);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 10010);
   return true;
  }

// ================= API: Create / Destroy / Rebuild =================
bool UI_TradesPanel_Create(const int x, const int y, const int w, const int h)
  {
   TP_X=x;
   TP_Y=y;
   TP_W=w;

   TP_H=h;

   int col_w = BTN_BREITE; // col_w ist die BZN Breite
   int xL = TP_X + TP_PAD;
   int xR = xL + col_w + TP_GAP;

   TP_W = xL + col_w + TP_GAP+BTN_C_W+TP_GAP+BTN_SL_W+TP_GAP;
   TP_W = TP_W + col_w + TP_GAP+BTN_C_W+TP_GAP+BTN_SL_W;
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
/*void UI_TradesPanel_RebuildRows()
{
   // 0) Safety: Header-Controls sicherstellen (falls aus irgendeinem Grund weg)
   int col_w = (TP_W - 2*(TP_PAD - TP_GAP-10-20-10-TP_GAP)) / 2;
   col_w=BTN_BREITE;
   int xL    = TP_X + TP_PAD;
   int xR    = xL + col_w + TP_GAP+BTN_C_W+TP_GAP+BTN_SL_W+TP_GAP;

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

     // ---- Restore Entry/SL Lines für diese Position
if(rows[i].was_sent == 1 && rows[i].pos_no >= 1 && rows[i].pos_no <= 4)
{
   int trade_no = rows[i].trade_no;
   int pos_no   = rows[i].pos_no;

   string suf = "_" + IntegerToString(trade_no) + "_" + IntegerToString(pos_no);

   double entry_draw = UI_DrawPriceOrMid(rows[i].entry, 0);
   double sl_draw    = UI_DrawPriceOrMid(rows[i].sl,    0);

   if(rows[i].direction == "LONG")
   {
      CreateEntryAndSLLines(Entry_Long + suf, TimeCurrent(), entry_draw, TradeEntryLineLong);
      CreateEntryAndSLLines(SL_Long    + suf, TimeCurrent(), sl_draw,    Tradecolor_SLLineLong);
   }
   else if(rows[i].direction == "SHORT")
   {
      CreateEntryAndSLLines(Entry_Short + suf, TimeCurrent(), entry_draw, TradeEntryLineShort);
      CreateEntryAndSLLines(SL_Short    + suf, TimeCurrent(), sl_draw,    Tradecolor_SLLineShort);
   }
}



      string txt_tr = StringFormat("Tradenummer: T%d ",
                                rows[i].trade_no);

      string txt = StringFormat("P%d  %s  E:%s SL:%s",
                                 rows[i].pos_no, rows[i].status,
                                DoubleToString(rows[i].entry, digits),
                                DoubleToString(rows[i].sl, digits));


      if(rows[i].direction == "LONG")
      {
         if(idxL >= maxRows) continue;
         string name_tr = StringFormat("%s%d", TP_ROW_LONG_TR_PREFIX, rows[i].trade_no);
         TP_CreateButton(name_tr, xL, yTop + idxL*TP_ROW_H, col_w, TP_ROW_H, txt_tr, 8);
         idxL++;
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
              string name_tr = StringFormat("%s%d", TP_ROW_SHORT_TR_PREFIX, rows[i].trade_no);
         TP_CreateButton(name_tr, xR, yTop + idxR*TP_ROW_H, col_w, TP_ROW_H, txt_tr, 8);
         idxR++;
         string name = StringFormat("%s%d_%d", TP_ROW_SHORT_PREFIX, rows[i].trade_no, rows[i].pos_no);
         TP_CreateButton(name, xR, yTop + idxR*TP_ROW_H, col_w, TP_ROW_H, txt, 8);

         string name_c = StringFormat("%s%d_%d", TP_ROW_SHORT_Cancel_PREFIX, rows[i].trade_no, rows[i].pos_no);
         TP_CreateButton(name_c, xR+col_w +10, yTop + idxR*TP_ROW_H, 20, TP_ROW_H, "C", 8);
         string name_s = StringFormat("%s%d_%d", TP_ROW_SHORT_hitSL_PREFIX, rows[i].trade_no, rows[i].pos_no);
         TP_CreateButton(name_s, xR+col_w +10+20+10, yTop + idxR*TP_ROW_H, 20, TP_ROW_H, "S", 8);

         idxR++;
         showActive_short(true);
         showCancel_short(true);
      }
   }

   ChartRedraw(0);
}
*/
void UI_TradesPanel_RebuildRows()
  {
// 0) Header / Panel
   int col_w = (TP_W - 2*(TP_PAD - TP_GAP-10-20-10-TP_GAP)) / 2;
   col_w = BTN_BREITE;

   int xL = TP_X + TP_PAD;
   int xR = xL + col_w + TP_GAP + BTN_C_W + TP_GAP + BTN_SL_W + TP_GAP;

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

// 1) Rows löschen
   TP_DeleteByPrefix(TP_ROW_LONG_PREFIX);
   TP_DeleteByPrefix(TP_ROW_SHORT_PREFIX);
   TP_DeleteByPrefix(TP_ROW_LONG_TR_PREFIX);
   TP_DeleteByPrefix(TP_ROW_SHORT_TR_PREFIX);
   TP_DeleteByPrefix(TP_ROW_LONG_Cancel_PREFIX);
   TP_DeleteByPrefix(TP_ROW_SHORT_Cancel_PREFIX);
   TP_DeleteByPrefix(TP_ROW_LONG_hitSL_PREFIX);
   TP_DeleteByPrefix(TP_ROW_SHORT_hitSL_PREFIX);

// 2) Listbereich
   int yTop    = y3 + TP_BTN_H + 10;
   int yBottom = TP_Y + TP_H - TP_PAD;

   int maxRows = (yBottom - yTop) / TP_ROW_H;
   if(maxRows < 1)
      maxRows = 1;

// 3) DB laden
   DB_PositionRow rows[];
   int n = DB_LoadPositions(_Symbol, (ENUM_TIMEFRAMES)_Period, rows);

// 3.1) In LONG/SHORT Arrays filtern (und Lines restoren)
   DB_PositionRow longRows[];
   DB_PositionRow shortRows[];
   int nL=0, nS=0;

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   for(int i=0; i<n; i++)
     {
      if(StringFind(rows[i].status,"CLOSED",0)==0)
         continue;

      // Restore Entry/SL Lines (pro Position)
      if(rows[i].was_sent == 1 && rows[i].pos_no >= 1 && rows[i].pos_no <= 4)
        {
         int trade_no = rows[i].trade_no;
         int pos_no   = rows[i].pos_no;
         string suf   = "_" + IntegerToString(trade_no) + "_" + IntegerToString(pos_no);

         double entry_draw = UI_DrawPriceOrMid(rows[i].entry, 0);
         double sl_draw    = UI_DrawPriceOrMid(rows[i].sl,    0);

         if(rows[i].direction == "LONG")
           {
            CreateEntryAndSLLines(Entry_Long + suf, TimeCurrent(), entry_draw, TradeEntryLineLong);
            CreateEntryAndSLLines(SL_Long    + suf, TimeCurrent(), sl_draw,    Tradecolor_SLLineLong);
           }
         else
            if(rows[i].direction == "SHORT")
              {
               CreateEntryAndSLLines(Entry_Short + suf, TimeCurrent(), entry_draw, TradeEntryLineShort);
               CreateEntryAndSLLines(SL_Short    + suf, TimeCurrent(), sl_draw,    Tradecolor_SLLineShort);
              }
        }

      if(rows[i].direction == "LONG")
        {
         ArrayResize(longRows, nL+1);
         longRows[nL] = rows[i];
         nL++;
        }
      else
         if(rows[i].direction == "SHORT")
           {
            ArrayResize(shortRows, nS+1);
            shortRows[nS] = rows[i];
            nS++;
           }
     }

// 4) Sortieren (Trade zuerst, dann Position)
   if(nL>1)
      SortRowsByTradePos(longRows, nL);
   if(nS>1)
      SortRowsByTradePos(shortRows, nS);

// 5) LONG Seite zeichnen: Trade-Header immer über den Positionen
   int idxL = 0;
   int lastTradeL = -1;
   bool anyLong=false;

   for(int i=0; i<nL; i++)
     {
      if(idxL >= maxRows)
         break;

      int trade_no = longRows[i].trade_no;
      int pos_no   = longRows[i].pos_no;

      if(trade_no != lastTradeL)
        {
         string txt_tr  = StringFormat("Tradenummer: T%d", trade_no);
         string name_tr = StringFormat("%s%d", TP_ROW_LONG_TR_PREFIX, trade_no);

         TP_CreateButton(name_tr, xL, yTop + idxL*TP_ROW_H, col_w, TP_ROW_H, txt_tr, 8);
         idxL++;
         if(idxL >= maxRows)
            break;

         lastTradeL = trade_no;
        }

      string txt = StringFormat("P%d  %s  E:%s SL:%s",
                                pos_no, longRows[i].status,
                                DoubleToString(longRows[i].entry, digits),
                                DoubleToString(longRows[i].sl, digits));

      string name   = StringFormat("%s%d_%d", TP_ROW_LONG_PREFIX, trade_no, pos_no);
      string name_c = StringFormat("%s%d_%d", TP_ROW_LONG_Cancel_PREFIX, trade_no, pos_no);
      string name_s = StringFormat("%s%d_%d", TP_ROW_LONG_hitSL_PREFIX, trade_no, pos_no);

      TP_CreateButton(name,   xL,                 yTop + idxL*TP_ROW_H, col_w, TP_ROW_H, txt, 8);
      TP_CreateButton(name_c, xL + col_w + 10,    yTop + idxL*TP_ROW_H, 20,    TP_ROW_H, "C", 8);
      TP_CreateButton(name_s, xL + col_w + 10+20+10, yTop + idxL*TP_ROW_H, 20, TP_ROW_H, "S", 8);

      idxL++;
      anyLong=true;
     }

// 6) SHORT Seite zeichnen: Trade-Header immer über den Positionen
   int idxR = 0;
   int lastTradeS = -1;
   bool anyShort=false;

   for(int i=0; i<nS; i++)
     {
      if(idxR >= maxRows)
         break;

      int trade_no = shortRows[i].trade_no;
      int pos_no   = shortRows[i].pos_no;

      if(trade_no != lastTradeS)
        {
         string txt_tr  = StringFormat("Tradenummer: T%d", trade_no);
         string name_tr = StringFormat("%s%d", TP_ROW_SHORT_TR_PREFIX, trade_no);

         TP_CreateButton(name_tr, xR, yTop + idxR*TP_ROW_H, col_w, TP_ROW_H, txt_tr, 8);
         idxR++;
         if(idxR >= maxRows)
            break;

         lastTradeS = trade_no;
        }

      string txt = StringFormat("P%d  %s  E:%s SL:%s",
                                pos_no, shortRows[i].status,
                                DoubleToString(shortRows[i].entry, digits),
                                DoubleToString(shortRows[i].sl, digits));

      string name   = StringFormat("%s%d_%d", TP_ROW_SHORT_PREFIX, trade_no, pos_no);
      string name_c = StringFormat("%s%d_%d", TP_ROW_SHORT_Cancel_PREFIX, trade_no, pos_no);
      string name_s = StringFormat("%s%d_%d", TP_ROW_SHORT_hitSL_PREFIX, trade_no, pos_no);

      TP_CreateButton(name,   xR,                 yTop + idxR*TP_ROW_H, col_w, TP_ROW_H, txt, 8);
      TP_CreateButton(name_c, xR + col_w + 10,    yTop + idxR*TP_ROW_H, 20,    TP_ROW_H, "C", 8);
      TP_CreateButton(name_s, xR + col_w + 10+20+10, yTop + idxR*TP_ROW_H, 20, TP_ROW_H, "S", 8);

      idxR++;
      anyShort=true;
     }

// 7) Active/Cancel visibility nur einmal setzen
   if(anyLong)
     {
      showActive_long(true);
      showCancel_long(true);
     }
   if(anyShort)
     {
      showActive_short(true);
      showCancel_short(true);
     }

   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SortRowsByTradePos(DB_PositionRow &arr[], const int cnt)
  {
   for(int i=0; i<cnt-1; i++)
     {
      for(int j=i+1; j<cnt; j++)
        {
         bool swap=false;

         if(arr[j].trade_no < arr[i].trade_no)
            swap=true;
         else
            if(arr[j].trade_no == arr[i].trade_no && arr[j].pos_no < arr[i].pos_no)
               swap=true;

         if(swap)
           {
            DB_PositionRow tmp = arr[i];
            arr[i] = arr[j];
            arr[j] = tmp;
           }
        }
     }
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

 
 // LONG Cancel (C)
if(StringFind(sparam, TP_ROW_LONG_Cancel_PREFIX, 0) == 0)
{
   int trade_no, pos_no;
   if(UI_ParseTradePosFromButtonName(sparam, TP_ROW_LONG_Cancel_PREFIX, trade_no, pos_no))
   {
      // optional: Button-State zurücksetzen
      if(ObjectFind(0, sparam) >= 0)
         ObjectSetInteger(0, sparam, OBJPROP_STATE, 0);

      UI_CloseOnePositionAndNotify("CANCEL", "LONG", trade_no, pos_no);
   }
   return true;
}

// LONG SL erreicht (S)
if(StringFind(sparam, TP_ROW_LONG_hitSL_PREFIX, 0) == 0)
{
   int trade_no, pos_no;
   if(UI_ParseTradePosFromButtonName(sparam, TP_ROW_LONG_hitSL_PREFIX, trade_no, pos_no))
   {
      if(ObjectFind(0, sparam) >= 0)
         ObjectSetInteger(0, sparam, OBJPROP_STATE, 0);

      UI_CloseOnePositionAndNotify("SL", "LONG", trade_no, pos_no);
   }
   return true;
}

// SHORT Cancel (C)
if(StringFind(sparam, TP_ROW_SHORT_Cancel_PREFIX, 0) == 0)
{
   int trade_no, pos_no;
   if(UI_ParseTradePosFromButtonName(sparam, TP_ROW_SHORT_Cancel_PREFIX, trade_no, pos_no))
   {
      if(ObjectFind(0, sparam) >= 0)
         ObjectSetInteger(0, sparam, OBJPROP_STATE, 0);

      UI_CloseOnePositionAndNotify("CANCEL", "SHORT", trade_no, pos_no);
   }
   return true;
}

// SHORT SL erreicht (S)
if(StringFind(sparam, TP_ROW_SHORT_hitSL_PREFIX, 0) == 0)
{
   int trade_no, pos_no;
   if(UI_ParseTradePosFromButtonName(sparam, TP_ROW_SHORT_hitSL_PREFIX, trade_no, pos_no))
   {
      if(ObjectFind(0, sparam) >= 0)
         ObjectSetInteger(0, sparam, OBJPROP_STATE, 0);

      UI_CloseOnePositionAndNotify("SL", "SHORT", trade_no, pos_no);
   }
   return true;
}

 
 
   return false;
  }

  
  
  bool UI_ParseTradePosFromButtonName(const string name,
                                    const string prefix,
                                    int &trade_no,
                                    int &pos_no)
{
   trade_no = 0;
   pos_no   = 0;

   if(StringFind(name, prefix, 0) != 0)
      return false;

   string rest = StringSubstr(name, StringLen(prefix)); // erwartet "12_3"
   int sep = StringFind(rest, "_", 0);
   if(sep < 1)
      return false;

   trade_no = (int)StringToInteger(StringSubstr(rest, 0, sep));
   pos_no   = (int)StringToInteger(StringSubstr(rest, sep+1));

   return (trade_no > 0 && pos_no > 0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool UI_IsPriceVisible(const double price, const int subwin=0)
  {
   double pmin = ChartGetDouble(0, CHART_PRICE_MIN, subwin);
   double pmax = ChartGetDouble(0, CHART_PRICE_MAX, subwin);

   double lo = MathMin(pmin, pmax);
   double hi = MathMax(pmin, pmax);

   if(hi <= lo || hi == 0.0) // Chart noch nicht “ready”
      return true;

   return (price >= lo && price <= hi);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double UI_ChartMidPrice(const int subwin=0)
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
double UI_DrawPriceOrMid(const double intended_price, const int subwin=0)
  {
   if(UI_IsPriceVisible(intended_price, subwin))
      return intended_price;
   return UI_ChartMidPrice(subwin);
  }

#endif // __TRADES_PANEL_MQH__
//====================== end trades_panel.mqh ======================
