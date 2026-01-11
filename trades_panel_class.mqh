// trades_panel_class.mqh (Zielversion - Standalone UI)

#ifndef __TRADES_PANEL_CLASS_MQH__
#define __TRADES_PANEL_CLASS_MQH__

#include "db_service.mqh"
#include "trade_pos_line_registry.mqh"
#include "discord_client.mqh"
#include "logger.mqh"
#include "UI_CreateOrUpdateLineTag.mqh"

// Optional: UI helpers (wo UI_Reg_Add/UI_ObjSetIntSafe/UI_RequestRedraw wohnen)
// #include "ui_helpers.mqh"

#ifndef OBJ_ALL_PERIODS
#define OBJ_ALL_PERIODS 0xFFFFFFFF
#endif
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
   g_tp.RebuildRows();
  }

// -------------------- Action-Handler (entkoppelt DB/Discord/Lines) --------------------
class ITradesPanelHandler
  {
public:
   virtual void      OnHeaderActive(const bool isLong) = 0;
   virtual void      OnHeaderCancel(const bool isLong) = 0;

   virtual void      OnRowCancelPos(const bool isLong, const int trade_no, const int pos_no) = 0;
   virtual void      OnRowStopPos(const bool isLong, const int trade_no, const int pos_no) = 0;
   virtual void      OnRowHitSL(const bool isLong, const int trade_no, const int pos_no) = 0;

   virtual          ~ITradesPanelHandler() {}
  };

// -------------------- Trades Panel UI --------------------
class CTradesPanel
  {
private:
   // State
   bool              m_created;
   bool              m_dirty;
   ulong             m_lastRebuildMs;

   // External
   CDBService        *m_db;          // optional (wenn UI selbst laden soll)
   ITradesPanelHandler *m_handler;  // Aktionen

   // Geometry
   int               m_x, m_y, m_w, m_h;
   int               m_pad, m_gap, m_hdr_h, m_btn_h, m_row_h;
   int               m_col_min, m_col_max, m_panel_max_w;
   int               m_btnC_w, m_btnS_w;
   struct STPLayout
     {
      int            col_w;
      int            block_w;
      int            xL;
      int            xR;
      int            yTop;
      int            maxRows;
     };

   STPLayout         m_layout;

   // Theme
   color             m_hdr_bg, m_hdr_border;
   color             m_lbl_long_col, m_lbl_short_col;

   // Names (statisch)
   string            m_bg, m_sep, m_hdrL, m_hdrR, m_lblL, m_lblR;
   string            m_btnActiveL, m_btnActiveR, m_btnCancelL, m_btnCancelR;

   // Prefixes (Rows)
   string            m_prefLongTr, m_prefShortTr;
   string            m_prefLongPos, m_prefShortPos;
   string            m_prefLongCancel, m_prefShortCancel;
   string            m_prefLongTrCancel, m_prefShortTrCancel;
   string            m_prefLongHitSL, m_prefShortHitSL;

private:
   // ---------- low-level object factory (hast du schon) ----------
   bool              CreateRect(const string name, const int x, const int y, const int w, const int h,
                                const color border, const color bg, const int z);

   bool              CreateLabel(const string name, const int x, const int y, const int w, const int h,
                                 const string txt, const int fontsize, const color col);

   bool              CreateButton(const string name, const int x, const int y, const int w, const int h,
                                  const string txt, const int fontsize);

   // ---------- helpers (aus trades_panel.mqh in die Klasse ziehen) ----------


   void              ComputeCompactLayout(int &col_w, int &block_w, int &xL, int &xR);

   // ---------- build steps ----------
   bool              BuildStatic(const int x, const int y, const int w, const int h);                 // BG + Header + Active/Cancel + Labels + Separator
   void              DeleteRowsOnly();              // Rows löschen (nur dynamische Objekte)
   void              BuildRows();                   // DB laden, sortieren, zeichnen

   bool              BuildSide(const bool isLong, const DB_PositionRow &arr[], const int cnt,
                               const int xBase, const int yTop, const int col_w, const int maxRows);

   // ---------- events ----------
   bool              HandleHeaderClick(const string objName);
   bool              HandleRowClick(const string objName);

   bool              ParseTradePosFromButtonName(const string name, const string prefix,
         int &trade_no, int &pos_no);
   void              RestoreTradeLinesFromRows(const DB_PositionRow &rows[], const int n);
public:
                     CTradesPanel()
     {
      m_created=false;
      m_dirty=false;
      m_lastRebuildMs=0;
      m_db=NULL;
      m_handler=NULL;

      m_x=10;
      m_y=40;
      m_w=440;
      m_h=420;

      m_pad=8;
      m_gap=6;
      m_hdr_h=26;
      m_btn_h=22;
      m_row_h=18;
      m_col_min=140;
      m_col_max=200;
      m_panel_max_w=460;
      m_btnC_w=18;
      m_btnS_w=18;

      m_hdr_bg=(color)C'22,22,22';
      m_hdr_border=(color)C'70,70,70';
      m_lbl_long_col=(color)C'0,170,100';
      m_lbl_short_col=(color)C'220,70,70';

      m_bg="TP_BG";
      m_sep="TP_SEP";
      m_hdrL="TP_HDR_LONG_BG";
      m_hdrR="TP_HDR_SHORT_BG";
      m_lblL="TP_LBL_LONG";
      m_lblR="TP_LBL_SHORT";
      m_btnActiveL="TP_BTN_ACTIVE_LONG";
      m_btnActiveR="TP_BTN_ACTIVE_SHORT";
      m_btnCancelL="TP_BTN_CANCEL_LONG";
      m_btnCancelR="TP_BTN_CANCEL_SHORT";

      // prefixes (entsprechen deinen #defines aus trades_panel.mqh)
      m_prefLongTr="TP_ROW_LONG_TR_";
      m_prefShortTr="TP_ROW_SHORT_TR_";
      m_prefLongTrCancel="TP_ROW_LONG_TR_Cancel_";
      m_prefShortTrCancel="TP_ROW_SHORT_TR_Cancel_";
      m_prefLongPos="TP_ROW_LONG_";
      m_prefShortPos="TP_ROW_SHORT_";
      m_prefLongCancel="TP_ROW_LONG_Cancel_";
      m_prefShortCancel="TP_ROW_SHORT_Cancel_";
      m_prefLongHitSL="TP_ROW_LONG_sl_";
      m_prefShortHitSL="TP_ROW_SHORT_sl_";
      m_layout.col_w=0;
      m_layout.block_w=0;
      m_layout.xL=0;
      m_layout.xR=0;
      m_layout.yTop=0;
      m_layout.maxRows=0;
     }

   bool              OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);

   void              StyleButton(const string name, const color txt, const color bg, const color brd);

   void              SetButtonVisible(const string name, const bool visible, const string caption,
                                      const color txt_col, const color bg_col, const color border_col);
   void              DeleteByPrefix(const string prefix);
   void              SetDB(CDBService *db) { m_db=db; }
   void              SetHandler(ITradesPanelHandler *h) { m_handler=h; }

   bool              IsCreated() const { return m_created; }

   bool              Create(const int x, const int y, const int w, const int h)
     {
      m_x=x;
      m_y=y;
      m_w=w;
      m_h=h;

      if(!BuildStatic(m_x,m_y,m_w,m_h))
        {
         m_created=false;
         return false;
        }

      m_created=true;
      RequestRebuild();
      return true;
     }

   void              Destroy()
     {
      m_created=false;
      // optional: hier gezielt m_bg/m_sep/... löschen oder Registry in OnDeinit nutzen
     }

   void              RequestRebuild()
     {
      if(!m_created)
         return;
      m_dirty=true;
     }

   void              ProcessRebuild()
     {
      if(!m_created || !m_dirty)
         return;

      ulong now=GetTickCount64();
      if(now - m_lastRebuildMs < 100)
         return;

      m_lastRebuildMs=now;
      m_dirty=false;

      RebuildRows();
     }

   void              RebuildRows();



  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTradesPanel::BuildStatic(const int x, const int y, const int w, const int h)
  {
   m_x=x;
   m_y=y;
   m_h=h;
   m_w=w;

   int col_w=0, block_w=0, xL=0, xR=0;
   ComputeCompactLayout(col_w, block_w, xL, xR);

// Header-Vertikal-Layout (einmalig)
   int y1 = m_y + m_pad;
   int y2 = y1 + m_hdr_h + 6;
   int y3 = y2 + m_btn_h + 6;

   m_layout.col_w   = col_w;
   m_layout.block_w = block_w;
   m_layout.xL      = xL;
   m_layout.xR      = xR;
   m_layout.yTop    = y3 + m_btn_h + 10;

// maxRows hängt von Höhe ab (für später)
   int yBottom = m_y + m_h - m_pad;
   int maxRows = (yBottom - m_layout.yTop) / m_row_h;
   if(maxRows < 1)
      maxRows = 1;
   m_layout.maxRows = maxRows;

// --- Static UI erstellen ---
// BG
   if(!CreateRect(m_bg, m_x, m_y, m_w, m_h, m_hdr_border, clrBlack, 9990))
      return false;

// Separator (Mitte)
   if(!CreateRect(m_sep, xL + block_w, m_y, m_gap, m_h, clrDimGray, clrDimGray, 10002))
      return false;

// Header-BGs (neutral)
   if(!CreateRect(m_hdrL, xL, y1, block_w, m_hdr_h, m_hdr_border, m_hdr_bg, 10003))
      return false;
   if(!CreateRect(m_hdrR, xR, y1, block_w, m_hdr_h, m_hdr_border, m_hdr_bg, 10003))
      return false;

// Header-Labels
   if(!CreateLabel(m_lblL, xL+6, y1+4, block_w, m_hdr_h, "LONG", 10, m_lbl_long_col))
      return false;
   if(!CreateLabel(m_lblR, xR+6, y1+4, block_w, m_hdr_h, "SHORT", 10, m_lbl_short_col))
      return false;

// Header-Buttons erstellen (aber hidden)
   CreateButton(m_btnActiveL, xL, y2, block_w, m_btn_h, "Active Trade", 9);
   CreateButton(m_btnActiveR, xR, y2, block_w, m_btn_h, "Active Trade", 9);
   CreateButton(m_btnCancelL, xL, y3, block_w, m_btn_h, "Cancel Trade", 9);
   CreateButton(m_btnCancelR, xR, y3, block_w, m_btn_h, "Cancel Trade", 9);

   SetButtonVisible(m_btnActiveL, false, "", clrBlack, clrBlack, clrBlack);
   SetButtonVisible(m_btnActiveR, false, "", clrBlack, clrBlack, clrBlack);
   SetButtonVisible(m_btnCancelL, false, "", clrBlack, clrBlack, clrBlack);
   SetButtonVisible(m_btnCancelR, false, "", clrBlack, clrBlack, clrBlack);

   UI_RequestRedraw();
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTradesPanel::CreateRect(const string name,const int x,const int y,const int w,const int h,
                              const color border,const color bg,const int z)
  {
// falschen Typ entfernen
   if(ObjectFind(0,name) >= 0)
     {
      long t=0;
      ObjectGetInteger(0,name,OBJPROP_TYPE,t);
      if((int)t != OBJ_RECTANGLE_LABEL)
         ObjectDelete(0,name);
     }

   if(ObjectFind(0,name) < 0)
     {
      if(!ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0))
         return false;
      UI_Reg_Add(name);
     }

   UI_ObjSetIntSafe(0,name,OBJPROP_XDISTANCE,x);
   UI_ObjSetIntSafe(0,name,OBJPROP_YDISTANCE,y);
   UI_ObjSetIntSafe(0,name,OBJPROP_XSIZE,w);
   UI_ObjSetIntSafe(0,name,OBJPROP_YSIZE,h);
   UI_ObjSetIntSafe(0,name,OBJPROP_COLOR,border);
   UI_ObjSetIntSafe(0,name,OBJPROP_BGCOLOR,bg);
   UI_ObjSetIntSafe(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   UI_ObjSetIntSafe(0,name,OBJPROP_ZORDER,z);
   UI_ObjSetIntSafe(0,name,OBJPROP_HIDDEN,true);
   UI_ObjSetIntSafe(0,name,OBJPROP_SELECTABLE,false);
   UI_ObjSetIntSafe(0,name,OBJPROP_BACK,false);
   UI_ObjSetIntSafe(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   UI_ObjSetIntSafe(0,name,OBJPROP_TIMEFRAMES,OBJ_ALL_PERIODS);
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTradesPanel::CreateLabel(const string name,const int x,const int y,const int w,const int h,
                               const string txt,const int fontsize,const color col)
  {
   if(ObjectFind(0,name) >= 0)
     {
      long t=0;
      ObjectGetInteger(0,name,OBJPROP_TYPE,t);
      if((int)t != OBJ_LABEL)
         ObjectDelete(0,name);
     }

   if(ObjectFind(0,name) < 0)
     {
      if(!ObjectCreate(0,name,OBJ_LABEL,0,0,0))
         return false;
      UI_Reg_Add(name);
     }

   UI_ObjSetIntSafe(0,name,OBJPROP_XDISTANCE,x);
   UI_ObjSetIntSafe(0,name,OBJPROP_YDISTANCE,y);
   UI_ObjSetIntSafe(0,name,OBJPROP_COLOR,col);
   UI_ObjSetIntSafe(0,name,OBJPROP_FONTSIZE,fontsize);
   ObjectSetString(0,name,OBJPROP_TEXT,txt);
   UI_ObjSetIntSafe(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   UI_ObjSetIntSafe(0,name,OBJPROP_HIDDEN,true);
   UI_ObjSetIntSafe(0,name,OBJPROP_SELECTABLE,false);
   UI_ObjSetIntSafe(0,name,OBJPROP_TIMEFRAMES,OBJ_ALL_PERIODS);

   UI_ObjSetIntSafe(0,name,OBJPROP_SELECTABLE,false);
   UI_ObjSetIntSafe(0,name,OBJPROP_ZORDER,10005);
   UI_ObjSetIntSafe(0,name,OBJPROP_BACK,false);
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTradesPanel::CreateButton(const string name,const int x,const int y,const int w,const int h,
                                const string txt,const int fontsize)
  {
   if(ObjectFind(0,name) >= 0)
     {
      long t=0;
      ObjectGetInteger(0,name,OBJPROP_TYPE,t);
      if((int)t != OBJ_BUTTON)
         ObjectDelete(0,name);
     }

   if(ObjectFind(0,name) < 0)
     {
      if(!ObjectCreate(0,name,OBJ_BUTTON,0,0,0))
         return false;
      UI_Reg_Add(name);
     }

   UI_ObjSetIntSafe(0,name,OBJPROP_XDISTANCE,x);
   UI_ObjSetIntSafe(0,name,OBJPROP_YDISTANCE,y);
   UI_ObjSetIntSafe(0,name,OBJPROP_XSIZE,w);
   UI_ObjSetIntSafe(0,name,OBJPROP_YSIZE,h);
   UI_ObjSetIntSafe(0,name,OBJPROP_FONTSIZE,fontsize);
   ObjectSetString(0,name,OBJPROP_TEXT,txt);
   UI_ObjSetIntSafe(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   UI_ObjSetIntSafe(0,name,OBJPROP_HIDDEN,true);
   UI_ObjSetIntSafe(0,name,OBJPROP_TIMEFRAMES,OBJ_ALL_PERIODS);

// klickbar
   UI_ObjSetIntSafe(0,name,OBJPROP_SELECTABLE,true);
   UI_ObjSetIntSafe(0,name,OBJPROP_SELECTED,false);

// sicher vor dem BG (BG hat 10000)
   UI_ObjSetIntSafe(0,name,OBJPROP_ZORDER,10010);

// optional, aber empfehlenswert
   UI_ObjSetIntSafe(0,name,OBJPROP_BACK,false);
   UI_ObjSetIntSafe(0,name,OBJPROP_STATE,0);


   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTradesPanel::ComputeCompactLayout(int &col_w, int &block_w, int &xL, int &xR)
  {
// Wunschbreite (m_w) cappen
   int desired_w = m_w;
   if(m_panel_max_w > 0)
      desired_w = MathMin(desired_w, m_panel_max_w);

// Overhead: PADs + Mittelgap + pro Seite (gap + C + gap + S)
   int overhead = 2*m_pad + m_gap + 2*(m_gap + m_btnC_w + m_gap + m_btnS_w);

   col_w = (desired_w - overhead) / 2;
   col_w = MathMax(m_col_min, MathMin(col_w, m_col_max));

   block_w = col_w + (m_gap + m_btnC_w + m_gap + m_btnS_w);

   xL = m_x + m_pad;
   xR = xL + block_w + m_gap;

// echte Panelbreite “passgenau”
   m_w = 2*m_pad + block_w + m_gap + block_w;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTradesPanel::DeleteRowsOnly()
  {
   DeleteByPrefix(m_prefLongPos);
   DeleteByPrefix(m_prefShortPos);
   DeleteByPrefix(m_prefLongTr);
   DeleteByPrefix(m_prefShortTr);
   DeleteByPrefix(m_prefLongCancel);
   DeleteByPrefix(m_prefShortCancel);
   DeleteByPrefix(m_prefLongHitSL);
   DeleteByPrefix(m_prefShortHitSL);
   DeleteByPrefix(m_prefLongTrCancel);
   DeleteByPrefix(m_prefShortTrCancel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTradesPanel::BuildRows()
  {
// yTop/maxRows aus BuildStatic-Layout
   const int xL = m_layout.xL;
   const int xR = m_layout.xR;
   const int col_w = m_layout.col_w;
   const int yTop = m_layout.yTop;
   const int maxRows = m_layout.maxRows;

// Header Buttons erstmal aus
   SetButtonVisible(m_btnActiveL,false,"", clrBlack,clrBlack,clrBlack);
   SetButtonVisible(m_btnCancelL,false,"", clrBlack,clrBlack,clrBlack);
   SetButtonVisible(m_btnActiveR,false,"", clrBlack,clrBlack,clrBlack);
   SetButtonVisible(m_btnCancelR,false,"", clrBlack,clrBlack,clrBlack);

// DB laden
   DB_PositionRow rows[];
   int n=0;
   if(m_db != NULL)
      n = m_db.LoadPositions(_Symbol, (ENUM_TIMEFRAMES)_Period, rows);
   else
      n = g_DB.LoadPositions(_Symbol, (ENUM_TIMEFRAMES)_Period, rows);
// NEU: Lines aus DB wiederherstellen (Entry/SL pro Position)
   RestoreTradeLinesFromRows(rows, n);
   if(n <= 0)
      return;

// split (effizient: einmal groß, am Ende kürzen)
   DB_PositionRow longRows[];
   DB_PositionRow shortRows[];
   ArrayResize(longRows, n);
   ArrayResize(shortRows, n);
   int nL=0, nS=0;

   for(int i=0;i<n;i++)
     {
      if(StringFind(rows[i].status,"CLOSED",0) == 0)
         continue;

      if(rows[i].direction=="LONG")
         longRows[nL++] = rows[i];
      if(rows[i].direction=="SHORT")
         shortRows[nS++] = rows[i];
     }
   ArrayResize(longRows, nL);
   ArrayResize(shortRows, nS);

   if(nL > 1)
      SortRowsByTradePos(longRows, nL);
   if(nS > 1)
      SortRowsByTradePos(shortRows, nS);

// Seiten rendern
   bool anyLong  = BuildSide(true,  longRows,  nL, xL, yTop, col_w, maxRows);
   bool anyShort = BuildSide(false, shortRows, nS, xR, yTop, col_w, maxRows);

// Header Buttons sichtbar schalten
   if(anyLong)
     {
      SetButtonVisible(m_btnActiveL,true,"Active Trade",
                       PriceButton_font_color, PriceButton_bgcolor, PriceButton_bgcolor);
      SetButtonVisible(m_btnCancelL,true,"Cancel Trade",
                       SLButton_font_color, SLButton_bgcolor, SLButton_bgcolor);
     }
   if(anyShort)
     {
      SetButtonVisible(m_btnActiveR,true,"Active Trade",
                       PriceButton_font_color, PriceButton_bgcolor, PriceButton_bgcolor);
      SetButtonVisible(m_btnCancelR,true,"Cancel Trade",
                       SLButton_font_color, SLButton_bgcolor, SLButton_bgcolor);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTradesPanel::RestoreTradeLinesFromRows(const DB_PositionRow &rows[], const int n)
  {
   for(int i=0; i<n; i++)
     {
      if(StringFind(rows[i].status, "CLOSED", 0) == 0)
         continue;

      if(rows[i].was_sent != 1 || rows[i].pos_no < 1)
         continue;

      const int trade_no = rows[i].trade_no;
      const int pos_no   = rows[i].pos_no;
      const string suf   = "_" + IntegerToString(trade_no) + "_" + IntegerToString(pos_no);

      const double entry_draw = UI_DrawPriceOrMid(rows[i].entry, 0);
      const double sl_draw    = UI_DrawPriceOrMid(rows[i].sl, 0);

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
      PrintFormat("RESTORE-LINE: dir=%s trade=%d pos=%d was_sent=%d status=%s entry=%f sl=%f",
                  rows[i].direction, rows[i].trade_no, rows[i].pos_no,
                  rows[i].was_sent, rows[i].status, rows[i].entry, rows[i].sl);


     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTradesPanel::HandleRowClick(const string objName)
  {
   int trade_no=0, pos_no=0;

   if(StringFind(objName, m_prefLongCancel, 0) == 0)
     {
      if(ParseTradePosFromButtonName(objName, m_prefLongCancel, trade_no, pos_no))
        {
         if(m_handler != NULL)
            m_handler.OnRowCancelPos(true, trade_no, pos_no);
         else
            UI_CloseOnePositionAndNotify("CANCEL","LONG",trade_no,pos_no);
         RebuildRows();
        }
      return true;
     }

   if(StringFind(objName, m_prefLongHitSL, 0) == 0)
     {
      if(ParseTradePosFromButtonName(objName, m_prefLongHitSL, trade_no, pos_no))
        {
         if(m_handler != NULL)
            m_handler.OnRowHitSL(true, trade_no, pos_no);
         else
            UI_CloseOnePositionAndNotify("HIT_SL","LONG",trade_no,pos_no);
         RebuildRows();
        }
      return true;
     }

   if(StringFind(objName, m_prefShortCancel, 0) == 0)
     {
      if(ParseTradePosFromButtonName(objName, m_prefShortCancel, trade_no, pos_no))
        {
         if(m_handler != NULL)
            m_handler.OnRowCancelPos(false, trade_no, pos_no);
         else
            UI_CloseOnePositionAndNotify("CANCEL","SHORT",trade_no,pos_no);
         RebuildRows();
        }
      return true;
     }

   if(StringFind(objName, m_prefShortHitSL, 0) == 0)
     {
      if(ParseTradePosFromButtonName(objName, m_prefShortHitSL, trade_no, pos_no))
        {
         if(m_handler != NULL)
            m_handler.OnRowHitSL(false, trade_no, pos_no);
         else
            UI_CloseOnePositionAndNotify("HIT_SL","SHORT",trade_no,pos_no);
         RebuildRows();
        }
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void               CTradesPanel::StyleButton(const string name, const color txt, const color bg, const color brd)
  {
   if(ObjectFind(0, name) < 0)
      return;

   UI_ObjSetIntSafe(0, name, OBJPROP_COLOR,        txt);
   UI_ObjSetIntSafe(0, name, OBJPROP_BGCOLOR,      bg);
   UI_ObjSetIntSafe(0, name, OBJPROP_BORDER_COLOR, brd);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTradesPanel::BuildSide(const bool isLong, const DB_PositionRow &arr[], const int cnt,
                             const int xBase, const int yTop, const int col_w, const int maxRows)
  {
   int idx=0;
   int lastTrade=-1;
   bool any=false;

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

// Farben Trade-Header
   const color TR_BG  = isLong ? (color)C'0,150,90'  : (color)C'200,60,60';
   const color TR_BRD = isLong ? (color)C'0,120,70'  : (color)C'160,40,40';
   const color TR_TXT = clrWhite;

   for(int i=0;i<cnt;i++)
     {
      if(idx >= maxRows)
         break;

      int trade_no = arr[i].trade_no;
      int pos_no   = arr[i].pos_no;

      // Trade Header bei Wechsel
      if(trade_no != lastTrade)
        {
         string trName = StringFormat("%s%d", (isLong?m_prefLongTr:m_prefShortTr), trade_no);
         string trTxt  = StringFormat("%s T%d", (isLong?"LONG":"SHORT"), trade_no);

         CreateButton(trName, xBase, yTop + idx*m_row_h, col_w, m_row_h, trTxt, 8);
         UI_ObjSetIntSafe(0, trName, OBJPROP_COLOR, TR_TXT);
         UI_ObjSetIntSafe(0, trName, OBJPROP_BGCOLOR, TR_BG);
         UI_ObjSetIntSafe(0, trName, OBJPROP_BORDER_COLOR, TR_BRD);

         idx++;
         if(idx >= maxRows)
            break;
         lastTrade = trade_no;
        }

      // Position Row + Mini Buttons
      string rowName = StringFormat("%s%d_%d", (isLong?m_prefLongPos:m_prefShortPos), trade_no, pos_no);
      string cName   = StringFormat("%s%d_%d", (isLong?m_prefLongCancel:m_prefShortCancel), trade_no, pos_no);
      string sName   = StringFormat("%s%d_%d", (isLong?m_prefLongHitSL:m_prefShortHitSL), trade_no, pos_no);

      string txt = StringFormat("P%d  %s  E:%s SL:%s",
                                pos_no,
                                arr[i].status,
                                DoubleToString(arr[i].entry, digits),
                                DoubleToString(arr[i].sl, digits));

      CreateButton(rowName, xBase, yTop + idx*m_row_h, col_w, m_row_h, txt, 8);
      CreateButton(cName, xBase + col_w + m_gap, yTop + idx*m_row_h, m_btnC_w, m_row_h, "C", 8);
      CreateButton(sName, xBase + col_w + m_gap + m_btnC_w + m_gap, yTop + idx*m_row_h, m_btnS_w, m_row_h, "S", 8);

      // Styles row
      UI_ObjSetIntSafe(0, rowName, OBJPROP_COLOR, clrWhite);
      UI_ObjSetIntSafe(0, rowName, OBJPROP_BGCOLOR, clrDarkSlateGray);
      UI_ObjSetIntSafe(0, rowName, OBJPROP_BORDER_COLOR, clrDimGray);

      // Styles minis (du nutzt SLButton_* als Theme)
      UI_ObjSetIntSafe(0, cName, OBJPROP_COLOR, SLButton_font_color);
      UI_ObjSetIntSafe(0, cName, OBJPROP_BGCOLOR, SLButton_bgcolor);
      UI_ObjSetIntSafe(0, cName, OBJPROP_BORDER_COLOR, clrWhite);

      UI_ObjSetIntSafe(0, sName, OBJPROP_COLOR, SLButton_font_color);
      UI_ObjSetIntSafe(0, sName, OBJPROP_BGCOLOR, SLButton_bgcolor);
      UI_ObjSetIntSafe(0, sName, OBJPROP_BORDER_COLOR, clrWhite);

      idx++;
      any=true;
     }

   return any;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void               CTradesPanel::SetButtonVisible(const string name, const bool visible, const string caption,
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
bool CTradesPanel::ParseTradePosFromButtonName(const string name,const string prefix,int &trade_no,int &pos_no)
  {
   trade_no=0;
   pos_no=0;

   if(StringFind(name, prefix, 0) != 0)
      return false;

   string rest = StringSubstr(name, (int)StringLen(prefix)); // z.B. "12_3"
   int sep = StringFind(rest, "_", 0);
   if(sep < 1)
      return false;

   string sTrade = StringSubstr(rest, 0, sep);
   string sPos   = StringSubstr(rest, sep+1);

   trade_no = (int)StringToInteger(sTrade);
   pos_no   = (int)StringToInteger(sPos);

   return (trade_no > 0 && pos_no > 0);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTradesPanel::HandleHeaderClick(const string objName)
  {
// Active Buttons: schlucken
   if(objName == m_btnActiveL || objName == m_btnActiveR)
      return true;

   if(objName == m_btnCancelL)
     {
      if(m_handler != NULL)
         m_handler.OnHeaderCancel(true);
      else
         UI_CancelActiveTrade("LONG");
      RequestRebuild();
      return true;
     }

   if(objName == m_btnCancelR)
     {
      if(m_handler != NULL)
         m_handler.OnHeaderCancel(false);
      else
         UI_CancelActiveTrade("SHORT");
      RequestRebuild();
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void              CTradesPanel::DeleteByPrefix(const string prefix)
  {
   int total = ObjectsTotal(0, -1, -1);
   for(int i = total - 1; i >= 0; --i)
     {
      string n = ObjectName(0, i);
      if(StringFind(n, prefix, 0) == 0)
        {
         CLogger::Add(LOG_LEVEL_DEBUG, "Object mit Prefix"+prefix +": Object: " + n +" wird gelöscht");
         UI_Reg_DeleteOne(n);
        }

     }

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTradesPanel::RebuildRows()
  {
   if(!m_created)
      return;

   DeleteRowsOnly();
   BuildRows();
   UI_RequestRedraw();
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTradesPanel::OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(!m_created)
      return false;
   if(id != CHARTEVENT_OBJECT_CLICK)
      return false;

   if(HandleHeaderClick(sparam))
      return true;
   if(HandleRowClick(sparam))
      return true;

   return false;
  }




/**
* Beschreibung: Zentrale Rebuild-Funktion (Bridge) für Call-Sites außerhalb der Klasse.
* Parameter:    keine
* Rückgabewert: void
* Hinweise:     Ruft g_tp.RebuildRows() auf (welches in Adapter-Phase Legacy nutzt).
* Fehlerfälle:  Panel nicht created -> Print und return.
*/
void TP_RebuildRows()
  {
   if(!g_tp.IsCreated())
     {
      CLogger::Add(LOG_LEVEL_ERROR, "TP_RebuildRows(): Panel ist nicht vorhanden!");
      return;
     }

   g_tp.RebuildRows();
  }
extern CTradesPanel g_tp;










#endif // __TRADES_PANEL_CLASS_MQH__

//+------------------------------------------------------------------+
