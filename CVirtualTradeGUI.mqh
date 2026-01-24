// CVirtualTradeGUI.mqh
#ifndef __CVIRTUALTRADEGUI_MQH__
#define __CVIRTUALTRADEGUI_MQH__

#include "ui_names.mqh"
#include "ta_controllers.mqh"
#include "CTradeManager.mqh"
#include "ui_state.mqh"



// --- tiny helpers (global, damit kein Klassen/Scope-Ärger) ---
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
// Draft struct (optional, falls du es später nutzt)
// ------------------------------------------------------------
struct VT_Draft
  {
   string            direction;     // "LONG" / "SHORT"
   int               trade_no;
   int               pos_no;
   double            entry_price;
   double            sl_price;
   string            sabio_entry;
   string            sabio_sl;
  };

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
   // --- Smooth Drag State (wie früher in OnChartEvent) ---

   int               m_downMouseX;


   // gespeicherte Start-Ys (mlbDownYD_*)
   int               m_downY_entryBtn;
   int               m_downY_slBtn;
   int               m_downY_sendBtn;
   int               m_downY_trnb;
   int               m_downY_posnb;
   int               m_downY_sabEntry;
   int               m_downY_sabSL;
   // --- Smooth drag state (line-master) ---
   int               m_prevMouseState;

   bool              m_drag_entry_group;   // EntryButton gedrückt -> beide Linien bewegen
   bool              m_drag_sl_only;       // SLButton gedrückt -> nur SL

   int               m_downMouseY;
   int               m_grabOffEntry;       // MausOffset innerhalb EntryButton
   int               m_grabOffSL;          // MausOffset innerhalb SLButton

   double            m_downEntryPrice;
   double            m_downSLPrice;
   double            m_priceDiffSL;        // SL - Entry (Preisabstand)
   double            m_lastEntryPrice;     // fürs "line changed?" Sabio update
   double            m_lastSLPrice;
   // --- Line-drag state (für smooth follow) ---
   bool              m_drag_pr_line;
   bool              m_drag_sl_line;
   double            m_drag_diff_sl;     // SL - Entry beim Start (für PR_HL drag)
   bool              m_sabio_entry_editing;
   bool              m_sabio_sl_editing;
   bool              m_sabio_user_entry;
   bool              m_sabio_user_sl;
   bool              m_prevLeftDown;
   // Controllers
   CBaseLinesController        m_baseLines;
   CBaseButtonsDragController  m_baseBtnDrag;

private:
   // --------- Mini helpers (ohne Abhängigkeit zu alten gui_elemente.mqh) ----------
   bool              ObjExists(const string name) const { return (ObjectFind(m_chart, name) >= 0); }



   void              SetYMoveSafe(const string name, const int y)
     {
      if(ObjectFind(m_chart, name) < 0)
         return;

      // WICHTIG: Bei OBJ_EDIT niemals SELECTED toggeln, das killt den Edit-Fokus/Caret.
      long type = ObjectGetInteger(m_chart, name, OBJPROP_TYPE);
      if(type == OBJ_EDIT)
        {
         ObjectSetInteger(m_chart, name, OBJPROP_YDISTANCE, y);
         return;
        }

      // Für andere Objekte einfach bewegen (ohne Selection-Fummelei)
      ObjectSetInteger(m_chart, name, OBJPROP_YDISTANCE, y);
     }



   void              LineDrag_Begin(const int mx, const int my)
     {
      bool hit_pr = HitTestLinePx(PR_HL, mx, my, 6);
      bool hit_sl = HitTestLinePx(SL_HL, mx, my, 6);

      bool start_pr = hit_pr;
      bool start_sl = (!start_pr && hit_sl);

      if(!(start_pr || start_sl))
         return;

      // Erst jetzt finalisieren
      FinalizeActiveEditBeforeDrag();

      m_drag_pr_line = start_pr;
      m_drag_sl_line = start_sl;

      ChartSetInteger(m_chart, CHART_MOUSE_SCROLL, false);

      // Startpreise + diff merken
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
         // Entry folgt Maus, SL bleibt im gleichen Abstand
         double new_entry = p;
         double new_sl    = VT_NormalizeToTick(new_entry + m_drag_diff_sl);

         ObjectSetDouble(m_chart, PR_HL, OBJPROP_PRICE, new_entry);
         ObjectSetDouble(m_chart, SL_HL, OBJPROP_PRICE, new_sl);

         OnBaseLinesChanged(false);   // live -> Buttons/Text/Lot laufen mit
         return;
        }

      if(m_drag_sl_line)
        {
         // SL folgt Maus
         ObjectSetDouble(m_chart, SL_HL, OBJPROP_PRICE, p);

         OnBaseLinesChanged(false);   // live -> Lot/Text aktualisiert
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

      OnBaseLinesChanged(true); // final
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

   void              Drag_Begin(const int mx, const int my)
     {

      bool hit_entry = HitTest(EntryButton, mx, my);
      bool hit_sl    = (!hit_entry && HitTest(SLButton, mx, my));

      if(!(hit_entry || hit_sl))
         return;

      // Erst jetzt, wo klar ist: wir starten Drag
      FinalizeActiveEditBeforeDrag();

      m_drag_entry_group = hit_entry;
      m_drag_sl_only     = hit_sl;

      ChartSetInteger(m_chart, CHART_MOUSE_SCROLL, false);

      m_downMouseY = my;

      // Grab-Offset speichern (damit es “smooth” bleibt)
      int x,y,w,h;
      if(m_drag_entry_group && GetBox(EntryButton, x,y,w,h))
         m_grabOffEntry = (my - y);
      if(m_drag_sl_only && GetBox(SLButton, x,y,w,h))
         m_grabOffSL = (my - y);

      // Startpreise sichern
      double e=0.0,s=0.0;
      if(GetBaseEntrySL(e,s))
        {
         m_downEntryPrice = e;
         m_downSLPrice    = s;
         m_priceDiffSL    = (s - e);      // SL bleibt relativ zu Entry gleich (Preisabstand)
        }
     }

   void              Drag_Update(const int mx, const int my)
     {
      if(!(m_drag_entry_group || m_drag_sl_only))
         return;

      double new_entry = 0.0;
      double new_sl    = 0.0;

      // ENTRY-GROUP: neue Entry aus Maus -> SL = Entry + diff
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

         OnBaseLinesChanged(false); // live refresh: Buttons folgen Lines, Texte/Lot aktualisieren
         return;
        }

      // SL-ONLY: neue SL aus Maus
      if(m_drag_sl_only)
        {
         int x,y,w,h;
         if(!GetBox(SLButton, x,y,w,h))
            return;

         int target_top = my - m_grabOffSL;

         if(!PriceFromButtonTopY(SLButton, target_top, new_sl))
            return;

         ObjectSetDouble(m_chart, SL_HL, OBJPROP_PRICE, new_sl);

         OnBaseLinesChanged(false); // Lot im Entry wird neu berechnet
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

      OnBaseLinesChanged(true); // final + persist
     }



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

   void              SetY(const string name, const int y)
     {
      if(ObjectFind(m_chart, name) < 0)
         return;
      ObjectSetInteger(m_chart, name, OBJPROP_YDISTANCE, y);
     }

   // Preis ermitteln, wenn Button-Top bei target_top_y wäre (Center-Referenz!)
   bool              PriceFromButtonTopY(const string btn_name, const int target_top_y, double &out_price) const
     {
      int x,y,w,h;
      if(!GetBox(btn_name, x, y, w, h))
         return false;

      datetime t=0;
      int window=0;
      double p=0.0;

      // Center statt bottom edge -> passt zu SyncBaseControlsToLines (y - h/2)
      int y_center = target_top_y + (h/2);

      if(!ChartXYToTimePrice(m_chart, x + w/2, y_center, window, t, p))
         return false;

      out_price = VT_NormalizeToTick(p);
      return true;
     }

   void              SetSabioFromLinePrice(const string obj, const string prefix, const double price)
     {
      if(ObjectFind(m_chart, obj) < 0)
         return;
      ObjectSetString(m_chart, obj, OBJPROP_TEXT,
                      prefix + DoubleToString(VT_NormalizeToTick(price), VT_Digits()));
     }

   // Wird beim Send genutzt: wenn User nur Prefix oder leer -> fallback Preis
   string            GetSabioTextForSend(const string obj, const string prefix, const double fallback_price) const
     {
      if(ObjectFind(m_chart, obj) < 0)
         return prefix + DoubleToString(VT_NormalizeToTick(fallback_price), VT_Digits());

      string t = VT_TrimCopy(VT_ObjText(m_chart, obj));
      if(t == "" || t == prefix)
         return prefix + DoubleToString(VT_NormalizeToTick(fallback_price), VT_Digits());

      // Prefix sicherstellen
      if(StringFind(t, prefix, 0) != 0)
         t = prefix + t;

      return t;
     }


   void              NormalizeSabioEdit(const string obj, const string prefix)
     {
      if(ObjectFind(m_chart, obj) < 0)
         return;

      string s = ObjectGetString(m_chart, obj, OBJPROP_TEXT);
      string t = s;
      StringTrimLeft(t);
      StringTrimRight(t);

      if(t == "")
        {
         ObjectSetString(m_chart, obj, OBJPROP_TEXT, prefix);
         return;
        }

      // Prefix entfernen, falls vorhanden
      if(StringFind(t, prefix, 0) == 0)
         t = StringSubstr(t, StringLen(prefix));

      StringTrimLeft(t);
      StringTrimRight(t);

      // wenn User nur Prefix gelassen hat
      if(t == "")
        {
         ObjectSetString(m_chart, obj, OBJPROP_TEXT, prefix);
         return;
        }

      // Zahl am Ende extrahieren (Komma->Punkt erlauben)
      StringReplace(t, ",", ".");

      // Wenn der User "0.67030" tippt -> wir machen "SABIO Entry: 0.67030"
      double v = StringToDouble(t);
      bool looks_like_number = (v != 0.0 || t == "0" || t == "0.0" || t == "0.00");

      if(looks_like_number)
         ObjectSetString(m_chart, obj, OBJPROP_TEXT, prefix + DoubleToString(VT_NormalizeToTick(v), VT_Digits()));
      else
         ObjectSetString(m_chart, obj, OBJPROP_TEXT, prefix + t); // fallback: Text behalten
     }

   void              EnsureSabioPrefixIfMissing(const string obj, const string prefix)
     {
      if(ObjectFind(m_chart, obj) < 0)
         return;

      string s = ObjectGetString(m_chart, obj, OBJPROP_TEXT);
      string t = s;
      StringTrimLeft(t);
      StringTrimRight(t);

      if(t == "")
        {
         ObjectSetString(m_chart, obj, OBJPROP_TEXT, prefix);
         return;
        }

      if(StringFind(t, prefix, 0) != 0)
        {
         // Prefix fehlt -> davor setzen, aber existierenden Inhalt behalten
         ObjectSetString(m_chart, obj, OBJPROP_TEXT, prefix + t);
        }
     }


   void              EnsureSabioTextWithPrice(const string obj_name,
         const string prefix,
         const double price,
         const bool allow_overwrite_when_has_value)
     {
      if(IsSelected(obj_name))
         return;
      if(ObjectFind(m_chart, obj_name) < 0)
         return;

      string cur = ObjectGetString(m_chart, obj_name, OBJPROP_TEXT);



      // Zieltext
      string target = prefix + DoubleToString(price, VT_Digits());

      // Wenn Feld leer oder nur prefix => setzen
      string t = cur;
      StringTrimLeft(t);
      StringTrimRight(t);

      bool only_prefix = (StringFind(t, prefix, 0) == 0 && StringLen(t) <= StringLen(prefix) + 1);

      if(t == "" || only_prefix)
        {
         ObjectSetString(m_chart, obj_name, OBJPROP_TEXT, target);
         return;
        }

      // Optional: wenn du IMMER auf Preis syncen willst (auch wenn User was drin hat)
      if(allow_overwrite_when_has_value)
         ObjectSetString(m_chart, obj_name, OBJPROP_TEXT, target);
     }

   bool              SabioHasOnlyPrefix(const string obj, const string prefix) const
     {
      if(ObjectFind(m_chart, obj) < 0)
         return true;
      string t = VT_TrimCopy(VT_ObjText(m_chart, obj));
      if(t == "" || t == prefix)
         return true;
      if(StringFind(t, prefix, 0) == 0)
        {
         string rest = VT_TrimCopy(VT_SubstrFrom(t, StringLen(prefix)));
         return (rest == "");
        }
      return false;
     }


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
                                  const string txt,
                                  const color font_clr, const color bg_clr)
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

   bool              EnsureEdit(const string name, const int x, const int y, const int w, const int h,
                                const string txt, const color font_clr, const color bg_clr)
     {
      const bool created = (ObjectFind(m_chart, name) < 0);
      if(created)
        {
         if(!ObjectCreate(m_chart, name, OBJ_EDIT, 0, 0, 0))
            return false;
        }

      ObjectSetInteger(m_chart, name, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chart, name, OBJPROP_XDISTANCE,  x);
      ObjectSetInteger(m_chart, name, OBJPROP_YDISTANCE,  y);
      ObjectSetInteger(m_chart, name, OBJPROP_XSIZE,      w);
      ObjectSetInteger(m_chart, name, OBJPROP_YSIZE,      h);

      ObjectSetInteger(m_chart, name, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(m_chart, name, OBJPROP_HIDDEN,     false);
      ObjectSetInteger(m_chart, name, OBJPROP_READONLY,   false);
      ObjectSetInteger(m_chart, name, OBJPROP_BACK,       false);
      ObjectSetInteger(m_chart, name, OBJPROP_ZORDER,     120);

      ObjectSetInteger(m_chart, name, OBJPROP_BGCOLOR,    bg_clr);
      ObjectSetInteger(m_chart, name, OBJPROP_COLOR,      font_clr);
      ObjectSetInteger(m_chart, name, OBJPROP_FONTSIZE,   9);
      ObjectSetString(m_chart, name, OBJPROP_FONT,       "Arial");

      // Text nur beim Erstellen initial setzen (nie laufend überschreiben)
      if(created && txt != "")
         ObjectSetString(m_chart, name, OBJPROP_TEXT, txt);

      return true;
     }


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

   string            DirectionFromLines() const
     {
      double e=0,s=0;
      if(!GetBaseEntrySL(e,s))
         return "LONG";
      return (s < e ? "LONG" : "SHORT");
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
      m_prevMouseState   = 0;
      m_drag_entry_group = false;
      m_drag_sl_only     = false;
      m_downMouseX       = 0;
      m_downMouseY       = 0;

      m_downY_entryBtn = 0;
      m_downY_slBtn    = 0;
      m_downY_sendBtn  = 0;
      m_downY_trnb     = 0;
      m_downY_posnb    = 0;
      m_downY_sabEntry = 0;
      m_downY_sabSL    = 0;
      m_prevMouseState   = 0;
      m_drag_entry_group = false;
      m_drag_sl_only     = false;

      m_downMouseY   = 0;
      m_grabOffEntry = 0;
      m_grabOffSL    = 0;

      m_downEntryPrice = 0.0;
      m_downSLPrice    = 0.0;
      m_priceDiffSL    = 0.0;

      m_lastEntryPrice  = 0.0;
      m_lastSLPrice     = 0.0;
      m_drag_pr_line = false;
      m_drag_sl_line = false;
      m_drag_diff_sl = 0.0;
      m_sabio_entry_editing = false;
      m_sabio_sl_editing    = false;
      m_sabio_user_entry = false;
      m_sabio_user_sl    = false;
      m_prevLeftDown = false;
     }

   // Zugriff (Pointer; Return-Referenz ist in MQL5 als Return-Typ nicht erlaubt)
   CBaseLinesController*       BaseLines()   { return &m_baseLines; }
   CBaseButtonsDragController* BaseBtnDrag() { return &m_baseBtnDrag; }

   bool              Init(CTradeManager *tm, const string symbol, const ENUM_TIMEFRAMES tf)
     {
      m_tm = tm;
      m_symbol = symbol;
      m_tf = tf;
      m_chart = ChartID();

      // Controller binden
      m_baseLines.BindChart(m_chart);
      m_baseBtnDrag.BindChart(m_chart);
      m_baseBtnDrag.Bind(&m_baseLines);

      return (m_tm != NULL && CheckPointer(m_tm) != POINTER_INVALID);
     }

   // Optional: Base UI entfernen
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

   // ------------------------------------------------------------------
   // Neu: CreateDefaults ohne legacy createHL/createButton/...
   // ------------------------------------------------------------------
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

      // Y-Anker Mitte
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

      // Preis aus XY holen
      datetime t=0;
      double p_entry=0.0, p_sl=0.0;
      int window=0;

      // Entry-Preis
      if(!ChartXYToTimePrice(m_chart, x_entry + btn_w/2, y_mid, window, t, p_entry))
         p_entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);

      // SL-Preis
      if(!ChartXYToTimePrice(m_chart, x_entry + btn_w/2, y_sl, window, t, p_sl))
         p_sl = p_entry - 50*_Point;

      p_entry = VT_NormalizeToTick(p_entry);
      p_sl    = VT_NormalizeToTick(p_sl);

      // Linien
      EnsureHLine(PR_HL, p_entry, clrDeepSkyBlue, STYLE_SOLID);
      EnsureHLine(SL_HL, p_sl,    clrTomato,      STYLE_SOLID);

      // X-Layout links von EntryButton
      const int gap = 8;
      const int send_w = 100;
      const int pos_w= send_w/2;
      const int trnb_w= send_w/2;
      int x_send = x_entry - send_w;
      int x_pos  = x_entry - 50;
      int x_trnb = x_pos - trnb_w;

      int x_sabE =  x_entry;

      if(x_sabE < 0)
         x_sabE = 0;
      if(x_pos  < 0)
         x_pos  = 0;
      if(x_trnb < 0)
         x_trnb = 0;
      if(x_send < 0)
         x_send = 0;

      // Buttons + Edits
      EnsureButton(EntryButton, x_entry, y_mid, btn_w, btn_h, "Entry", PriceButton_font_color, PriceButton_bgcolor);
      EnsureButton(SLButton,    x_entry, y_sl,  btn_w, btn_h, "SL",    SLButton_font_color, SLButton_bgcolor);

      EnsureButton(SENDTRADEBTN, x_send, y_mid, send_w, btn_h, "SEND", SendOnlyButton_font_color, SendOnlyButton_bgcolor);

      EnsureEdit(TRNB, x_trnb, y_mid + btn_h, edit_w, edit_h, "1", clrBlack, clrWhite);
      EnsureEdit(POSNB, x_pos,  y_mid + btn_h, edit_w, edit_h, "1", clrBlack, clrWhite);

      EnsureEdit(SabioEntry, x_sabE, y_mid + btn_h, btn_w, sab_h, "SABIO Entry: ", clrBlack, clrWhite);
      EnsureEdit(SabioSL,    x_sabE, y_sl  + btn_h, btn_w, sab_h, "SABIO SL: ",    clrBlack, clrWhite);
      EnsureSabioTextWithPrice(SabioEntry, "SABIO Entry: ", p_entry, true);
      EnsureSabioTextWithPrice(SabioSL,    "SABIO SL: ",    p_sl,    true);
      // MouseMove aktivieren
      ChartSetInteger(m_chart, CHART_EVENT_MOUSE_MOVE, true);

      // Baseline + Sync
      CaptureAnchorBaseline(true);
      ApplyRightAnchor(30, 0);
      OnBaseLinesChanged(false);
     }

   // ------------------------------------------------------------------
   // Base UI Eventhandling (Linien/Buttons Drag) + Re-Anchor
   // ------------------------------------------------------------------
   bool              HandleBaseUIEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
     {
      if(id == CHARTEVENT_OBJECT_ENDEDIT && IsEditObject(sparam))
        {
         EndEdit(sparam);
         return true;
        }
      // Linien Drag/Change
      if(id == CHARTEVENT_OBJECT_CHANGE && (sparam == PR_HL || sparam == SL_HL))
        {
         OnBaseLinesChanged(true);
         return true;
        }

      // OBJECT_DRAG ignorieren, weil wir smooth über MOUSE_MOVE fahren
      if(id == CHARTEVENT_OBJECT_DRAG && (sparam == PR_HL || sparam == SL_HL))
         return true;

      if(id == CHARTEVENT_OBJECT_DRAG && sparam == SL_HL)
        {
         OnBaseLinesChanged(false);
         return true;
        }

      if(id == CHARTEVENT_OBJECT_CHANGE && sparam == SL_HL)
        {
         OnBaseLinesChanged(true);
         return true;
        }

      if(id == CHARTEVENT_MOUSE_MOVE)
        {
         const int mx = (int)lparam;
         const int my = (int)dparam;
         const int flags = (int)StringToInteger(sparam);
         const bool leftDown = ((flags & 1) != 0);   // Bit 0 = Left button

         // MouseDown edge
         if(!m_prevLeftDown && leftDown)
           {
            Drag_Begin(mx, my);
            if(!(m_drag_entry_group || m_drag_sl_only))
               LineDrag_Begin(mx, my);
           }

         // Dragging
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

         // MouseUp edge
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



      // Chart resize -> right anchor re-apply
      if(id == CHARTEVENT_CHART_CHANGE)
        {

         ApplyRightAnchor(30, 0);
         OnBaseLinesChanged(false);
         return true;
        }

      return false;
     }


public:


   bool              IsEditObject(const string name) const
     {
      if(name == TRNB || name == POSNB || name == SabioEntry || name == SabioSL)
         return true;

      // Legacy-Namen (falls noch im Chart)
      if(name == "EingabePos" || name == "EingabeTrade")
         return true;

      return false;
     }




   void              SyncBaseControlsToLines()
     {
      double entry=0.0, sl=0.0;
      if(!GetBaseEntrySL(entry, sl))
         return;

      datetime t = VT_VisibleTime();
      int x=0, y=0;

      // Hilfs-Offsets (wie bei CreateDefaults)
      const int gap_under_btn = 2;

      // -----------------------------
      // ENTRY line -> Entry row
      // -----------------------------
      int entry_top = -1;
      if(ObjectFind(m_chart, EntryButton) >= 0 && ChartTimePriceToXY(m_chart, 0, t, entry, x, y))
        {
         int btn_h = (int)ObjectGetInteger(m_chart, EntryButton, OBJPROP_YSIZE);
         entry_top = y - (btn_h/2);
         if(entry_top < 0)
            entry_top = 0;

         ObjectSetInteger(m_chart, EntryButton, OBJPROP_YDISTANCE, entry_top);

         if(ObjectFind(m_chart, SENDTRADEBTN) >= 0)
            ObjectSetInteger(m_chart, SENDTRADEBTN, OBJPROP_YDISTANCE, entry_top);

         // EDITs unter Entry-Button-Zeile
         int y_edits_entry = entry_top + btn_h + gap_under_btn;

         // TRNB / POSNB (nur bewegen, wenn nicht aktiv editiert)
         if(ObjectFind(m_chart, TRNB) >= 0 && !IsSelected(TRNB))
            SetYMoveSafe(TRNB, y_edits_entry);

         if(ObjectFind(m_chart, POSNB) >= 0 && !IsSelected(POSNB))
            SetYMoveSafe(POSNB, y_edits_entry);

         if(ObjectFind(m_chart, SabioEntry) >= 0 && !IsSelected(SabioEntry))
            SetYMoveSafe(SabioEntry, y_edits_entry);
        }

      // -----------------------------
      // SL line -> SL row
      // -----------------------------
      int sl_top = -1;
      if(ObjectFind(m_chart, SLButton) >= 0 && ChartTimePriceToXY(m_chart, 0, t, sl, x, y))
        {
         int btn_h2 = (int)ObjectGetInteger(m_chart, SLButton, OBJPROP_YSIZE);
         sl_top = y - (btn_h2/2);
         if(sl_top < 0)
            sl_top = 0;

         ObjectSetInteger(m_chart, SLButton, OBJPROP_YDISTANCE, sl_top);

         // SabioSL unter SL-Button-Zeile
         int y_edits_sl = sl_top + btn_h2 + gap_under_btn;

         if(ObjectFind(m_chart, SabioSL) >= 0 && !IsSelected(SabioSL))
            SetYMoveSafe(SabioSL, y_edits_sl);
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
      if(ObjectFind(m_chart, SLButton) >= 0)
         SetText(SLButton, sl_txt);
     }


   void              UpdateTradePosTexts()
     {

      if(IsSelected(TRNB) || IsSelected(POSNB))
         return;

      if(m_tm == NULL || CheckPointer(m_tm) == POINTER_INVALID)
         return;

      string dir = DirectionFromLines();

      int active_trade = 0;
      m_tm.TM_GetActiveTradeNo(m_symbol, m_tf, dir, active_trade);

      if(active_trade > 0)
        {
         int next_pos = 1;
         m_tm.TM_GetNextPosNo(m_symbol, m_tf, dir, active_trade, next_pos);
         if(next_pos < 1)
            next_pos = 1;

         SetText(TRNB, IntegerToString(active_trade));
         SetText(POSNB, IntegerToString(next_pos));
         return;
        }

      int last_trade = 0;
      m_tm.TM_GetLastTradeNo(m_symbol, m_tf, last_trade);

      int next_trade = (last_trade > 0 ? last_trade + 1 : 1);
      SetText(TRNB, IntegerToString(next_trade));
      SetText(POSNB, "1");
     }

   void              OnBaseLinesChanged(const bool do_save)
     {
      SyncBaseControlsToLines();
      UpdateEntrySLButtonTexts();
      UpdateTradePosTexts();

      double entry=0.0, sl=0.0;
      if(GetBaseEntrySL(entry, sl))
        {
         // Force-Sync, sobald irgendein Drag läuft (Buttons oder Lines)
         bool force_sync =
            (m_drag_entry_group || m_drag_sl_only || m_drag_pr_line || m_drag_sl_line);

         if(force_sync)
           {
            // Sobald Nutzer wieder bewegt -> Sabio MUSS matchen (dein Punkt #2)
            SetSabioFromLinePrice(SabioEntry, "SABIO Entry: ", entry);
            SetSabioFromLinePrice(SabioSL,    "SABIO SL: ",    sl);

            // Und damit ist “User override” wieder aufgehoben (er bewegt ja neu)
            m_sabio_user_entry = false;
            m_sabio_user_sl    = false;
           }
         else
           {
            if(!m_sabio_user_entry && !IsSelected(SabioEntry))
               SetSabioFromLinePrice(SabioEntry, "SABIO Entry: ", entry);

            if(!m_sabio_user_sl && !IsSelected(SabioSL))
               SetSabioFromLinePrice(SabioSL, "SABIO SL: ", sl);

           }
        }

      ChartRedraw(m_chart);
     }
public:



   bool              EndEdit(const string obj)
     {
      if(!IsEditObject(obj))
         return false;

      else
         if(obj == "EingabePos") { /* wie POSNB behandeln */ }
         else
            if(obj == "EingabeTrade")
              {
               ApplyTRNBOverrideFromUser(); /* wie TRNB behandeln */
              }

      // Normalisieren/Override je Feld
      if(obj == TRNB)
        {
         ApplyTRNBOverrideFromUser();
        }
      else
         if(obj == SabioEntry)
           {
            NormalizeSabioEdit(SabioEntry, "SABIO Entry: ");
            m_sabio_user_entry = !SabioHasOnlyPrefix(SabioEntry, "SABIO Entry: ");
           }
         else
            if(obj == SabioSL)
              {
               NormalizeSabioEdit(SabioSL, "SABIO SL: ");
               m_sabio_user_sl = !SabioHasOnlyPrefix(SabioSL, "SABIO SL: ");
              }
      // POSNB: bleibt Freitext/Nummer, keine Auto-Logik beim ENDEDIT



      // UI konsistent
      UpdateTradePosTexts();
      ChartRedraw(m_chart);

      if(ObjectFind(m_chart, obj) >= 0)
         ObjectSetInteger(m_chart, obj, OBJPROP_SELECTED, false);
      return true;
     }


   // ------------------------------------------------------------------
   // Right anchor (X-Positions)
   // ------------------------------------------------------------------
   bool              CaptureAnchorBaseline(const bool force=false)
     {
      if(m_anchor_inited && !force)
         return true;

      if(ObjectFind(m_chart, EntryButton) < 0)
         return false;

      m_ref_x = (int)ObjectGetInteger(m_chart, EntryButton, OBJPROP_XDISTANCE);
      m_ref_w = (int)ObjectGetInteger(m_chart, EntryButton, OBJPROP_XSIZE);
      if(m_ref_w <= 0)
         m_ref_w = 200;

      if(ObjectFind(m_chart, SLButton) >= 0)
         m_dx_slbtn = (int)ObjectGetInteger(m_chart, SLButton, OBJPROP_XDISTANCE) - m_ref_x;
      if(ObjectFind(m_chart, SENDTRADEBTN) >= 0)
         m_dx_send  = (int)ObjectGetInteger(m_chart, SENDTRADEBTN, OBJPROP_XDISTANCE) - m_ref_x;
      if(ObjectFind(m_chart, TRNB) >= 0)
         m_dx_trnb  = (int)ObjectGetInteger(m_chart, TRNB, OBJPROP_XDISTANCE) - m_ref_x;
      if(ObjectFind(m_chart, POSNB) >= 0)
         m_dx_posnb = (int)ObjectGetInteger(m_chart, POSNB, OBJPROP_XDISTANCE) - m_ref_x;
      if(ObjectFind(m_chart, SabioEntry) >= 0)
         m_dx_sabE  = (int)ObjectGetInteger(m_chart, SabioEntry, OBJPROP_XDISTANCE) - m_ref_x;
      if(ObjectFind(m_chart, SabioSL) >= 0)
         m_dx_sabS  = (int)ObjectGetInteger(m_chart, SabioSL, OBJPROP_XDISTANCE) - m_ref_x;

      m_anchor_inited = true;
      return true;
     }

   void              ApplyRightAnchor(const int right_margin_px, const int shift_px)
     {
      if(!CaptureAnchorBaseline(false))
         return;

      const int w = VT_GetChartWidthPx(m_chart);
      if(w <= 0)
         return;

      int entry_w = (ObjectFind(m_chart, EntryButton) >= 0)
                    ? (int)ObjectGetInteger(m_chart, EntryButton, OBJPROP_XSIZE)
                    : m_ref_w;
      if(entry_w <= 0)
         entry_w = m_ref_w;

      int new_x = w - right_margin_px - entry_w - shift_px;
      if(new_x < 0)
         new_x = 0;

      VT_SetObjectXClamped(m_chart, EntryButton,  new_x, w);
      VT_SetObjectXClamped(m_chart, SLButton,     new_x + m_dx_slbtn, w);
      VT_SetObjectXClamped(m_chart, SENDTRADEBTN, new_x + m_dx_send,  w);
      // OBJ_EDIT im Fokus nicht bewegen (sonst verliert der User sofort den Edit-Fokus)

      if(!IsSelected(TRNB))
         VT_SetObjectXClamped(m_chart, TRNB, new_x + m_dx_trnb, w);
      if(!IsSelected(POSNB))
         VT_SetObjectXClamped(m_chart, POSNB, new_x + m_dx_posnb, w);
      if(!IsSelected(SabioEntry))
         VT_SetObjectXClamped(m_chart, SabioEntry, new_x + m_dx_sabE, w);
      if(!IsSelected(SabioSL))
         VT_SetObjectXClamped(m_chart, SabioSL, new_x + m_dx_sabS, w);

     }

   // ------------------------------------------------------------------
   // TRNB Override (User tippt TradeNo) -> setzt last_trade_no
   // ------------------------------------------------------------------

   void              ApplyTRNBOverrideFromUser()
     {
      // User darf TRNB nur dann als Startwert setzen, wenn aktuell KEIN aktiver Trade existiert
      // (weder LONG noch SHORT). Sonst würde das laufende Trade-Tracking kaputt gehen.
      int active_long  = 0;
      int active_short = 0;
      m_tm.TM_GetActiveTradeNo(m_symbol, m_tf, "LONG",  active_long);
      m_tm.TM_GetActiveTradeNo(m_symbol, m_tf, "SHORT", active_short);
      if(active_long > 0 || active_short > 0)
         return;

      string text = ObjectGetString(m_chart, TRNB, OBJPROP_TEXT);
      int user_trade_no = ExtractIntDigits(text);
      if(user_trade_no <= 0)
         return;

      // UI zeigt TradeNo an, intern speichern wir den "last_trade_no", damit der nächste Trade bei +1 startet.
      int new_last_trade_no = user_trade_no - 1;


      if(!m_tm.TM_SetLastTradeNo(m_symbol, m_tf, new_last_trade_no))
        {
         Print("[CVirtualTradeGUI] TM_SetLastTradeNo failed, err=", GetLastError());
        }
      // Legacy-Kompatibilität: einige Module lesen noch g_ui_state.last_trade_no (z.B. discord_send.mqh)
      g_ui_state.last_trade_no = new_last_trade_no;
      // und optional auch als Meta-Key (alter Restore-Pfad)
      g_DB.SetMetaInt(g_DB.KeyFor(m_symbol, m_tf, "g_ui_state.last_trade_no"), new_last_trade_no);
     }

   bool              IsSelected(const string name) const
     {
      if(ObjectFind(m_chart, name) < 0)
         return false;
      return (ObjectGetInteger(m_chart, name, OBJPROP_SELECTED) != 0);
     }

   string            ActiveEditSelected() const
     {
      if(IsSelected(TRNB))
         return TRNB;
      if(IsSelected(POSNB))
         return POSNB;
      if(IsSelected(SabioEntry))
         return SabioEntry;
      if(IsSelected(SabioSL))
         return SabioSL;
      return "";
     }
   void              FinalizeActiveEditBeforeDrag()
     {
      string obj = ActiveEditSelected();
      if(obj == "")
         return;

      if(obj == TRNB)
         ApplyTRNBOverrideFromUser();
      else
         if(obj == SabioEntry)
           {
            NormalizeSabioEdit(SabioEntry, "SABIO Entry: ");
            m_sabio_user_entry = !SabioHasOnlyPrefix(SabioEntry, "SABIO Entry: ");
           }
         else
            if(obj == SabioSL)
              {
               NormalizeSabioEdit(SabioSL, "SABIO SL: ");
               m_sabio_user_sl = !SabioHasOnlyPrefix(SabioSL, "SABIO SL: ");
              }
      // POSNB: keine Normalisierung nötig

      ObjectSetInteger(m_chart, obj, OBJPROP_SELECTED, false);
     }

  };
#endif
// __CVIRTUALTRAGUI_MQH__
// __CVIRTUALTRADEGUI_MQH__

//+------------------------------------------------------------------+
