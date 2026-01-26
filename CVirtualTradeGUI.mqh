// CVirtualTradeGUI.mqh
#ifndef __CVIRTUALTRADEGUI_MQH__
#define __CVIRTUALTRADEGUI_MQH__

#include "ui_names.mqh"
#include "ta_controllers.mqh"
#include "ui_state.mqh"
#include "CDBService.mqh"
extern CDBService g_DB;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTradeManager;            // forward declare
// --- tiny helpers (global) ---
string VT_TrimCopy(string s)
  {
   StringTrimLeft(s);
   StringTrimRight(s);
   return s;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string VT_ObjText(const long chart_id, const string obj)
  {
   if(ObjectFind(chart_id, obj) < 0)
      return "";
   return ObjectGetString(chart_id, obj, OBJPROP_TEXT);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string VT_SubstrFrom(const string s, const int start)
  {
   int n = StringLen(s);
   if(start <= 0)
      return s;
   if(start >= n)
      return "";
   string out = "";
   for(int i=start; i<n; i++)
      out += CharToString((uchar)StringGetCharacter(s, i));
   return out;
  }

// ------------------------------------------------------------
// CVirtualTradeGUI
// ------------------------------------------------------------
class CVirtualTradeGUI
  {
private:
   CTradeManager      *m_tm;
   string              m_symbol;
   ENUM_TIMEFRAMES     m_tf;
   long                m_chart;

   // Right anchor baseline
   bool                m_anchor_inited;
   int                 m_ref_x, m_ref_w;
   int                 m_dx_slbtn, m_dx_send, m_dx_trnb, m_dx_posnb, m_dx_sabE, m_dx_sabS;

   // --- Drag state ---
   bool                m_drag_entry_group;
   bool                m_drag_sl_only;
   int                 m_grabOffEntry;
   int                 m_grabOffSL;
   double              m_priceDiffSL;

   // --- Line drag state ---
   bool                m_drag_pr_line;
   bool                m_drag_sl_line;
   double              m_drag_diff_sl;

   bool                m_prevLeftDown;

   CBaseLinesController        m_baseLines;
   CBaseButtonsDragController  m_baseBtnDrag;

private:

   void              PersistDraftPricesAndSabio()
     {
      double e=0.0, s=0.0;
      if(GetBaseEntrySL(e,s))
        {
         DB_SetText("vt.draft.direction", DirectionFromLines());
         DB_SetText("vt.draft.entry_price", DoubleToString(VT_NormalizeToTick(e), VT_Digits()));
         DB_SetText("vt.draft.sl_price",    DoubleToString(VT_NormalizeToTick(s), VT_Digits()));
        }

      // Sabio Texte stehen bereits im Edit (user oder auto)
      string se = (ObjectFind(m_chart,SabioEntry)>=0 ? ObjectGetString(m_chart,SabioEntry,OBJPROP_TEXT) : "SABIO Entry: ");
      string ss = (ObjectFind(m_chart,SabioSL)>=0    ? ObjectGetString(m_chart,SabioSL,OBJPROP_TEXT)    : "SABIO SL: ");

      DB_SetText("vt.draft.sabio_entry_text", se);
      DB_SetText("vt.draft.sabio_sl_text",    ss);
     }



   // --- DB helper: keys ---
   string            Key(const string suffix) const
     {
      return g_DB.KeyFor(m_symbol, m_tf, suffix);
     }

   bool              DB_GetInt(const string suffix, int &out, const int def=0) const
     {
      return g_DB.GetMetaInt(Key(suffix), out, def);
     }

   int               DB_GetIntV(const string suffix, const int def=0) const
     {
      return g_DB.GetMetaInt(Key(suffix), def);
     }

   void              DB_SetInt(const string suffix, const int v)
     {
      g_DB.SetMetaInt(Key(suffix), v);
     }

   void              DB_SetText(const string suffix, const string v)
     {
      g_DB.SetMetaText(Key(suffix), v);
     }


   // ----------------- Objekt/Selection Helpers -----------------
   bool              ObjExists(const string name) const { return (ObjectFind(m_chart, name) >= 0); }

   // ----------------- Geometrie / HitTest -----------------
   bool              GetBox(const string name, int &x, int &y, int &w, int &h) const
     {
      if(ObjectFind(m_chart, name) < 0)
         return false;
      x = (int)ObjectGetInteger(m_chart, name, OBJPROP_XDISTANCE);
      y = (int)ObjectGetInteger(m_chart, name, OBJPROP_YDISTANCE);
      w = (int)ObjectGetInteger(m_chart, name, OBJPROP_XSIZE);
      h = (int)ObjectGetInteger(m_chart, name, OBJPROP_YSIZE);
      return true;
     }

   bool              HitTest(const string name, const int mx, const int my) const
     {
      int x,y,w,h;
      if(!GetBox(name,x,y,w,h))
         return false;
      return (mx>=x && mx<=x+w && my>=y && my<=y+h);
     }

   bool              HitTestLinePx(const string line_name, const int mx, const int my, const int tol_px=6) const
     {
      if(ObjectFind(m_chart, line_name) < 0)
         return false;

      double price = ObjectGetDouble(m_chart, line_name, OBJPROP_PRICE);

      int x=0, y=0;
      datetime t = VT_VisibleTime();
      if(!ChartTimePriceToXY(m_chart, 0, t, price, x, y))
         return false;

      return (MathAbs(my - y) <= tol_px);
     }

   bool              PriceFromMouse(const int mx, const int my, double &out_price) const
     {
      datetime t=0;
      int window=0;
      double p=0.0;
      if(!ChartXYToTimePrice(m_chart, mx, my, window, t, p))
         return false;
      out_price = VT_NormalizeToTick(p);
      return true;
     }

   bool              PriceFromButtonTopY(const string btn_name, const int target_top_y, double &out_price) const
     {
      int x,y,w,h;
      if(!GetBox(btn_name, x, y, w, h))
         return false;

      datetime t=0;
      int window=0;
      double p=0.0;

      int y_center = target_top_y + (h/2);
      if(!ChartXYToTimePrice(m_chart, x + w/2, y_center, window, t, p))
         return false;

      out_price = VT_NormalizeToTick(p);
      return true;
     }

   // ----------------- Text helpers -----------------
   void              SetText(const string name, const string txt)
     {
      if(ObjectFind(m_chart, name) < 0)
         return;
      ObjectSetString(m_chart, name, OBJPROP_TEXT, txt);
     }

   string            GetText(const string name) const
     {
      if(ObjectFind(m_chart, name) < 0)
         return "";
      return ObjectGetString(m_chart, name, OBJPROP_TEXT);
     }

   int               ExtractIntDigits(const string text) const
     {
      string d="";
      for(int i=0;i<StringLen(text);i++)
        {
         ushort c = StringGetCharacter(text,i);
         if(c>='0' && c<='9')
            d += CharToString((uchar)c);
        }
      if(d=="")
         return 0;
      return (int)StringToInteger(d);
     }

   // ----------------- Objects ensure -----------------
   bool              EnsureHLine(const string name, const double price, const color clr, const ENUM_LINE_STYLE style)
     {
      if(ObjectFind(m_chart, name) < 0)
        {
         if(!ObjectCreate(m_chart, name, OBJ_HLINE, 0, 0, price))
            return false;
        }
      ObjectSetInteger(m_chart, name, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(m_chart, name, OBJPROP_SELECTED,   false);
      ObjectSetInteger(m_chart, name, OBJPROP_HIDDEN,     false);
      ObjectSetInteger(m_chart, name, OBJPROP_BACK,       false);
      ObjectSetInteger(m_chart, name, OBJPROP_ZORDER,     10);
      ObjectSetInteger(m_chart, name, OBJPROP_COLOR,      clr);
      ObjectSetInteger(m_chart, name, OBJPROP_STYLE,      style);
      ObjectSetDouble(m_chart, name, OBJPROP_PRICE,      VT_NormalizeToTick(price));
      return true;
     }

   bool              EnsureButton(const string name, const int x, const int y, const int w, const int h,
                                  const string txt, const color font_clr, const color bg_clr)
     {
      if(ObjectFind(m_chart, name) < 0)
        {
         if(!ObjectCreate(m_chart, name, OBJ_BUTTON, 0, 0, 0))
            return false;
        }
      ObjectSetInteger(m_chart, name, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chart, name, OBJPROP_XDISTANCE,  x);
      ObjectSetInteger(m_chart, name, OBJPROP_YDISTANCE,  y);
      ObjectSetInteger(m_chart, name, OBJPROP_XSIZE,      w);
      ObjectSetInteger(m_chart, name, OBJPROP_YSIZE,      h);
      ObjectSetInteger(m_chart, name, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(m_chart, name, OBJPROP_HIDDEN,     false);
      ObjectSetInteger(m_chart, name, OBJPROP_BGCOLOR,    bg_clr);
      ObjectSetInteger(m_chart, name, OBJPROP_COLOR,      font_clr);
      ObjectSetInteger(m_chart, name, OBJPROP_ZORDER,     100);
      ObjectSetString(m_chart, name, OBJPROP_TEXT,       txt);
      ObjectSetInteger(m_chart, name, OBJPROP_FONTSIZE,   InpFontSize);
      ObjectSetString(m_chart, name, OBJPROP_FONT,       InpFont);
      return true;
     }

   // ✅ WICHTIG: Editfelder dürfen NICHT "selectable" sein, sonst klickst du nur "Objekt auswählen"
   // und kommst NICHT in den Eingabefokus (blau/cursor).
   bool              EnsureEdit(const string name, const int x, const int y, const int w, const int h,
                                const string txt, const color font_clr, const color bg_clr)
     {
      if(ObjectFind(m_chart, name) < 0)
        {
         if(!ObjectCreate(m_chart, name, OBJ_EDIT, 0, 0, 0))
            return false;
        }

      ObjectSetInteger(m_chart, name, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chart, name, OBJPROP_XDISTANCE,  x);
      ObjectSetInteger(m_chart, name, OBJPROP_YDISTANCE,  y);
      ObjectSetInteger(m_chart, name, OBJPROP_XSIZE,      w);
      ObjectSetInteger(m_chart, name, OBJPROP_YSIZE,      h);

      ObjectSetInteger(m_chart, name, OBJPROP_HIDDEN,     false);
      ObjectSetInteger(m_chart, name, OBJPROP_READONLY,   false);
      ObjectSetInteger(m_chart, name, OBJPROP_BACK,       false);

      // 🔥 Der entscheidende Unterschied:
      // - selectable=false -> Klick geht in "Edit-Fokus" (Cursor/Blue highlight)
      // - selectable=true  -> Klick selektiert Objekt (Mini-Quadrat), aber kein Tippen
      ObjectSetInteger(m_chart, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chart, name, OBJPROP_SELECTED,   false);

      // ZOrder ok, wichtig ist selectable=false
      ObjectSetInteger(m_chart, name, OBJPROP_ZORDER,     120);

      ObjectSetInteger(m_chart, name, OBJPROP_BGCOLOR,    bg_clr);
      ObjectSetInteger(m_chart, name, OBJPROP_COLOR,      font_clr);
      ObjectSetInteger(m_chart, name, OBJPROP_FONTSIZE,   9);
      ObjectSetString(m_chart, name, OBJPROP_FONT,       "Arial");

      // Text IMMER setzen (du wolltest Preis/Default sofort sichtbar)
      ObjectSetString(m_chart, name, OBJPROP_TEXT, txt);

      return true;
     }

   // ----------------- Base prices -----------------
   bool              GetBaseEntrySL(double &entry, double &sl) const
     {
      entry = 0.0;
      sl = 0.0;
      if(ObjectFind(m_chart, PR_HL) < 0 || ObjectFind(m_chart, SL_HL) < 0)
         return false;
      entry = ObjectGetDouble(m_chart, PR_HL, OBJPROP_PRICE);
      sl    = ObjectGetDouble(m_chart, SL_HL, OBJPROP_PRICE);
      return (entry > 0.0 && sl > 0.0);
     }

   // ----------------- Dragging -----------------
   void              Drag_Begin(const int mx, const int my)
     {
      bool hit_entry = HitTest(EntryButton, mx, my);
      bool hit_sl    = (!hit_entry && HitTest(SLButton, mx, my));
      if(!(hit_entry || hit_sl))
         return;

      m_drag_entry_group = hit_entry;
      m_drag_sl_only     = hit_sl;

      ChartSetInteger(m_chart, CHART_MOUSE_SCROLL, false);

      int x,y,w,h;
      if(m_drag_entry_group && GetBox(EntryButton, x,y,w,h))
         m_grabOffEntry = (my - y);
      if(m_drag_sl_only && GetBox(SLButton, x,y,w,h))
         m_grabOffSL = (my - y);

      double e=0.0,s=0.0;
      if(GetBaseEntrySL(e,s))
         m_priceDiffSL = (s - e);
     }

   void              Drag_Update(const int mx, const int my)
     {
      if(!(m_drag_entry_group || m_drag_sl_only))
         return;

      double new_entry = 0.0;
      double new_sl    = 0.0;

      if(m_drag_entry_group)
        {
         int x,y,w,h;
         if(!GetBox(EntryButton, x,y,w,h))
            return;

         int target_top = my - m_grabOffEntry;
         if(!PriceFromButtonTopY(EntryButton, target_top, new_entry))
            return;

         new_sl = VT_NormalizeToTick(new_entry + m_priceDiffSL);

         ObjectSetDouble(m_chart, PR_HL, OBJPROP_PRICE, new_entry);
         ObjectSetDouble(m_chart, SL_HL, OBJPROP_PRICE, new_sl);

         OnBaseLinesChanged();
         return;
        }

      if(m_drag_sl_only)
        {
         int x,y,w,h;
         if(!GetBox(SLButton, x,y,w,h))
            return;

         int target_top = my - m_grabOffSL;
         if(!PriceFromButtonTopY(SLButton, target_top, new_sl))
            return;

         ObjectSetDouble(m_chart, SL_HL, OBJPROP_PRICE, new_sl);
         OnBaseLinesChanged();
         return;
        }
     }

   void              Drag_End()
     {
      if(!(m_drag_entry_group || m_drag_sl_only))
         return;
      m_drag_entry_group = false;
      m_drag_sl_only     = false;
      ChartSetInteger(m_chart, CHART_MOUSE_SCROLL, true);
      OnBaseLinesChanged();
     }

   void              LineDrag_Begin(const int mx, const int my)
     {
      bool hit_pr = HitTestLinePx(PR_HL, mx, my, 6);
      bool hit_sl = HitTestLinePx(SL_HL, mx, my, 6);

      bool start_pr = hit_pr;
      bool start_sl = (!start_pr && hit_sl);

      if(!(start_pr || start_sl))
         return;

      m_drag_pr_line = start_pr;
      m_drag_sl_line = start_sl;

      ChartSetInteger(m_chart, CHART_MOUSE_SCROLL, false);

      double e=0.0, s=0.0;
      if(GetBaseEntrySL(e, s))
         m_drag_diff_sl = (s - e);
     }

   void              LineDrag_Update(const int mx, const int my)
     {
      if(!(m_drag_pr_line || m_drag_sl_line))
         return;

      double p=0.0;
      if(!PriceFromMouse(mx, my, p))
         return;

      if(m_drag_pr_line)
        {
         double new_entry = p;
         double new_sl    = VT_NormalizeToTick(new_entry + m_drag_diff_sl);

         ObjectSetDouble(m_chart, PR_HL, OBJPROP_PRICE, new_entry);
         ObjectSetDouble(m_chart, SL_HL, OBJPROP_PRICE, new_sl);

         OnBaseLinesChanged();
         return;
        }

      if(m_drag_sl_line)
        {
         ObjectSetDouble(m_chart, SL_HL, OBJPROP_PRICE, p);
         OnBaseLinesChanged();
         return;
        }
     }

   void              LineDrag_End()
     {
      if(!(m_drag_pr_line || m_drag_sl_line))
         return;
      m_drag_pr_line = false;
      m_drag_sl_line = false;
      ChartSetInteger(m_chart, CHART_MOUSE_SCROLL, true);
      OnBaseLinesChanged();
     }

   // ----------------- UI sync -----------------
   void              SyncBaseControlsToLines()
     {
      double entry=0.0, sl=0.0;
      if(!GetBaseEntrySL(entry, sl))
         return;

      datetime t = VT_VisibleTime();
      int x=0, y=0;

      const int gap_under_btn = 2;

      if(ObjectFind(m_chart, EntryButton) >= 0 && ChartTimePriceToXY(m_chart, 0, t, entry, x, y))
        {
         int btn_h = (int)ObjectGetInteger(m_chart, EntryButton, OBJPROP_YSIZE);
         int entry_top = y - (btn_h/2);
         if(entry_top < 0)
            entry_top = 0;

         ObjectSetInteger(m_chart, EntryButton, OBJPROP_YDISTANCE, entry_top);
         if(ObjectFind(m_chart, SENDTRADEBTN) >= 0)
            ObjectSetInteger(m_chart, SENDTRADEBTN, OBJPROP_YDISTANCE, entry_top);

         int y_edits_entry = entry_top + btn_h + gap_under_btn;

         ObjectSetInteger(m_chart, TRNB,      OBJPROP_YDISTANCE, y_edits_entry);
         ObjectSetInteger(m_chart, POSNB,     OBJPROP_YDISTANCE, y_edits_entry);
         ObjectSetInteger(m_chart, SabioEntry,OBJPROP_YDISTANCE, y_edits_entry);
        }

      if(ObjectFind(m_chart, SLButton) >= 0 && ChartTimePriceToXY(m_chart, 0, t, sl, x, y))
        {
         int btn_h2 = (int)ObjectGetInteger(m_chart, SLButton, OBJPROP_YSIZE);
         int sl_top = y - (btn_h2/2);
         if(sl_top < 0)
            sl_top = 0;

         ObjectSetInteger(m_chart, SLButton, OBJPROP_YDISTANCE, sl_top);

         int y_edits_sl = sl_top + btn_h2 + gap_under_btn;
         ObjectSetInteger(m_chart, SabioSL, OBJPROP_YDISTANCE, y_edits_sl);
        }
     }

   void              UpdateEntrySLButtonTexts()
     {
      double entry=0.0, sl=0.0;
      if(!GetBaseEntrySL(entry, sl))
         return;

      const bool is_long = (sl < entry);
      const double dist = MathAbs(entry - sl);
      const double dist_points = dist / _Point;

      double lots = 0.0;
      if(m_tm != NULL && CheckPointer(m_tm) != POINTER_INVALID)
         lots = m_tm.calcLots(m_symbol, m_tf, dist);
      lots = NormalizeDouble(lots, 2);

      string entry_txt = (is_long ? "Buy Stop @ " : "Sell Stop @ ");
      entry_txt += DoubleToString(entry, VT_Digits()) + " | Lot: " + DoubleToString(lots, 2);

      string sl_txt = "SL: " + DoubleToString(dist_points, 0) + " pts | " + DoubleToString(sl, VT_Digits());

      if(ObjectFind(m_chart, EntryButton) >= 0)
         SetText(EntryButton, entry_txt);
      if(ObjectFind(m_chart, SLButton)   >= 0)
         SetText(SLButton,   sl_txt);
     }

public:
                     CVirtualTradeGUI()
     {
      m_tm = NULL;
      m_symbol = "";
      m_tf = PERIOD_CURRENT;
      m_chart = 0;

      m_anchor_inited=false;
      m_ref_x=0;
      m_ref_w=0;
      m_dx_slbtn=0;
      m_dx_send=0;
      m_dx_trnb=0;
      m_dx_posnb=0;
      m_dx_sabE=0;
      m_dx_sabS=0;

      m_drag_entry_group=false;
      m_drag_sl_only=false;
      m_grabOffEntry=0;
      m_grabOffSL=0;
      m_priceDiffSL=0.0;

      m_drag_pr_line=false;
      m_drag_sl_line=false;
      m_drag_diff_sl=0.0;

      m_prevLeftDown=false;
     }

   bool              Init(CTradeManager *tm, const string symbol, const ENUM_TIMEFRAMES tf)
     {
      m_tm = tm;
      m_symbol = symbol;
      m_tf = tf;
      m_chart = ChartID();

      m_baseLines.BindChart(m_chart);
      m_baseBtnDrag.BindChart(m_chart);
      m_baseBtnDrag.Bind(&m_baseLines);

      return (m_tm != NULL && CheckPointer(m_tm) != POINTER_INVALID);
     }
   void              Destroy()
     {
      ObjectDelete(m_chart, PR_HL);
      ObjectDelete(m_chart, SL_HL);

      ObjectDelete(m_chart, EntryButton);
      ObjectDelete(m_chart, SLButton);
      ObjectDelete(m_chart, SENDTRADEBTN);

      ObjectDelete(m_chart, TRNB);
      ObjectDelete(m_chart, POSNB);
      ObjectDelete(m_chart, SabioEntry);
      ObjectDelete(m_chart, SabioSL);
     }

   void              CreateDefaults()
     {
      const int w = VT_GetChartWidthPx(m_chart);
      const int h = VT_GetChartHeightPx(m_chart);

      const int btn_w = 260;
      const int btn_h = 30;
      const int edit_w = 80;
      const int edit_h = 30;
      const int sab_h  = 30;

      const int right_margin = 30;
      const int x_entry = (w > 0 ? MathMax(0, w - right_margin - btn_w) : 20);

      int y_mid = (h > 0 ? (h/2) : 200);
      int y_sl  = y_mid + 100;
      if(h > 0)
        {
         if(y_sl > h-40)
            y_sl = h-40;
         if(y_mid > h-140)
            y_mid = h-140;
         if(y_mid < 40)
            y_mid = 40;
        }

      datetime t=0;
      double p_entry=0.0, p_sl=0.0;
      int window=0;

      if(!ChartXYToTimePrice(m_chart, x_entry + btn_w/2, y_mid, window, t, p_entry))
         p_entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);

      if(!ChartXYToTimePrice(m_chart, x_entry + btn_w/2, y_sl, window, t, p_sl))
         p_sl = p_entry - 50*_Point;

      p_entry = VT_NormalizeToTick(p_entry);
      p_sl    = VT_NormalizeToTick(p_sl);

      EnsureHLine(PR_HL, p_entry, clrDeepSkyBlue, STYLE_SOLID);
      EnsureHLine(SL_HL, p_sl,    clrTomato,      STYLE_SOLID);

      const int send_w = 100;
      const int trnb_w = send_w/2;
      int x_send = x_entry - send_w;
      int x_pos  = x_entry - 50;
      int x_trnb = x_pos - trnb_w;
      int x_sabE = x_entry;

      if(x_sabE < 0)
         x_sabE = 0;
      if(x_pos  < 0)
         x_pos  = 0;
      if(x_trnb < 0)
         x_trnb = 0;
      if(x_send < 0)
         x_send = 0;

      EnsureButton(EntryButton, x_entry, y_mid, btn_w, btn_h, "Entry", PriceButton_font_color, PriceButton_bgcolor);
      EnsureButton(SLButton,    x_entry, y_sl,  btn_w, btn_h, "SL",    SLButton_font_color, SLButton_bgcolor);
      EnsureButton(SENDTRADEBTN, x_send, y_mid, send_w, btn_h, "SEND", SendOnlyButton_font_color, SendOnlyButton_bgcolor);

      // ✅ Editfelder: jetzt sofort mit Inhalt (und wirklich editierbar)
      int tr = DB_GetIntV("tm.pub.trnb", 1);
      int po = DB_GetIntV("tm.pub.posnb", 1);

      EnsureEdit(TRNB,  x_trnb, y_mid + btn_h, edit_w, edit_h, IntegerToString(tr), clrBlack, clrWhite);
      EnsureEdit(POSNB, x_pos,  y_mid + btn_h, edit_w, edit_h, IntegerToString(po), clrBlack, clrWhite);

      EnsureEdit(SabioEntry, x_sabE, y_mid + btn_h, btn_w, sab_h,
                 "SABIO Entry: " + DoubleToString(p_entry, VT_Digits()), clrBlack, clrWhite);

      EnsureEdit(SabioSL,    x_sabE, y_sl  + btn_h, btn_w, sab_h,
                 "SABIO SL: " + DoubleToString(p_sl, VT_Digits()), clrBlack, clrWhite);

      ChartSetInteger(m_chart, CHART_EVENT_MOUSE_MOVE, true);
      // --- nach EnsureEdit(...) ---
      // published Werte aus DB in die GUI schreiben (sonst bleibt "1" bis ENDEDIT)
      ApplyTradePosFromDBToEdits();

      // Draft-Preise/Sabio gleich persistieren (optional aber sinnvoll)
      PersistDraftPricesAndSabio();

      // initial sync
      OnBaseLinesChanged();


     }

   bool              HandleBaseUIEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
     {
      if(id == CHARTEVENT_OBJECT_CHANGE && (sparam == PR_HL || sparam == SL_HL))
        {
         OnBaseLinesChanged();
         return true;
        }

      if(id == CHARTEVENT_OBJECT_DRAG && (sparam == PR_HL || sparam == SL_HL))
         return true;

      if(id == CHARTEVENT_MOUSE_MOVE)
        {
         const int mx = (int)lparam;
         const int my = (int)dparam;
         const int flags = (int)StringToInteger(sparam);
         const bool leftDown = ((flags & 1) != 0);

         if(!m_prevLeftDown && leftDown)
           {
            Drag_Begin(mx, my);
            if(!(m_drag_entry_group || m_drag_sl_only))
               LineDrag_Begin(mx, my);
           }

         if(leftDown && (m_drag_entry_group || m_drag_sl_only))
           {
            Drag_Update(mx, my);
            m_prevLeftDown = leftDown;
            return true;
           }
         if(leftDown && (m_drag_pr_line || m_drag_sl_line))
           {
            LineDrag_Update(mx, my);
            m_prevLeftDown = leftDown;
            return true;
           }

         if(m_prevLeftDown && !leftDown)
           {
            if(m_drag_entry_group || m_drag_sl_only)
               Drag_End();
            if(m_drag_pr_line || m_drag_sl_line)
               LineDrag_End();
           }

         m_prevLeftDown = leftDown;
         return false;
        }

      if(id == CHARTEVENT_CHART_CHANGE)
        {
         OnBaseLinesChanged();
         return true;
        }
      if(id == CHARTEVENT_OBJECT_ENDEDIT && (sparam == TRNB || sparam == POSNB))
        {
         if(sparam == TRNB)
           {
            int v = ExtractIntDigits(ObjectGetString(m_chart, TRNB, OBJPROP_TEXT));
            if(v > 0)
              {
               DB_SetInt("tm.req.trnb", v);
               DB_SetInt("tm.req.has_trnb", 1);
               DB_SetInt("vt.draft.trnb_user", 1);

               int rev = DB_GetIntV("tm.req.rev", 0);
               DB_SetInt("tm.req.rev", rev + 1);
              }
           }
         else // POSNB
           {
            int v = ExtractIntDigits(ObjectGetString(m_chart, POSNB, OBJPROP_TEXT));
            if(v > 0)
              {
               DB_SetInt("tm.req.posnb", v);
               DB_SetInt("tm.req.has_posnb", 1);
               DB_SetInt("vt.draft.posnb_user", 1);

               int rev = DB_GetIntV("tm.req.rev", 0);
               DB_SetInt("tm.req.rev", rev + 1);
              }
           }
         return true;
        }

      return false;
     }

   void              OnBaseLinesChanged()
     {
      SyncBaseControlsToLines();
      UpdateEntrySLButtonTexts();

      // Preise auch im Sabio-Edit live anzeigen (ohne irgendeine Prüfung/Logik)
      double entry=0.0, sl=0.0;
      if(GetBaseEntrySL(entry, sl))
        {
         SetText(SabioEntry, "SABIO Entry: " + DoubleToString(entry, VT_Digits()));
         SetText(SabioSL,    "SABIO SL: "    + DoubleToString(sl,    VT_Digits()));
        }


      ChartRedraw(m_chart);
     }


   string            DirectionFromLines() const
     {
      double e=0.0, s=0.0;
      if(!GetBaseEntrySL(e, s))
         return "LONG"; // fallback
      return (s < e ? "LONG" : "SHORT");
     }

   void              ApplyTradePosFromDBToEdits()
     {
      int tr=0, po=0;
      if(!DB_GetInt("tm.pub.trnb", tr, 1))
         tr = 1;
      if(!DB_GetInt("tm.pub.posnb", po, 1))
         po = 1;

      // Draft-DB immer aktuell halten (SEND-Layer liest vt.draft.*)
      DB_SetInt("vt.draft.trnb", tr);
      DB_SetInt("vt.draft.posnb", po);

      if(ObjectFind(m_chart, TRNB) >= 0)
         ObjectSetString(m_chart, TRNB, OBJPROP_TEXT, IntegerToString(tr));
      if(ObjectFind(m_chart, POSNB) >= 0)
         ObjectSetString(m_chart, POSNB, OBJPROP_TEXT, IntegerToString(po));

      ChartRedraw(m_chart);
     }
  };

#endif // __CVIRTUALTRADEGUI_MQH__