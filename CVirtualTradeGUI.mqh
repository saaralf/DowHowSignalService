//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#ifndef __CVIRTUALTRADEGUI_MQH__
#define __CVIRTUALTRADEGUI_MQH__
#include "ui_names.mqh"
#include "CTradeManager.mqh"
#include "logger.mqh"


#include "ta_controllers.mqh"


struct VT_Draft
  {
   string            direction;     // "LONG" / "SHORT"
   int               trade_no;       // nächste TradeNo
   int               pos_no;         // nächste PosNo
   double            entry_price;    // PR_HL Preis
   double            sl_price;       // SL_HL Preis
   string            sabio_entry;    // Freitext
   string            sabio_sl;       // Freitext
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CVirtualTradeGUI
  {
private:
   CTradeManager     *m_tm;
   string             m_symbol;
   ENUM_TIMEFRAMES    m_tf;
   long               m_chart;
   bool              m_edit_tradepos;
   string            m_edit_obj;
   bool              m_anchor_inited;
   int               m_ref_x, m_ref_w;
   int               m_dx_slbtn, m_dx_send, m_dx_trnb, m_dx_posnb, m_dx_sabE, m_dx_sabS;
   bool              m_trnb_editing;
   bool              m_posnb_editing;
   bool              GetBaseEntrySL(double &entry, double &sl);
   string            DirectionFromLines();
   CBaseLinesController        m_baseLines;
   CBaseButtonsDragController  m_baseBtnDrag;

public:
                     CVirtualTradeGUI() : m_tm(NULL), m_symbol(""), m_tf(PERIOD_CURRENT), m_chart(0) {m_edit_tradepos=false; m_edit_obj="";}

   CBaseLinesController*       BaseLines()   { return m_baseLines; }
   CBaseButtonsDragController* BaseBtnDrag() { return m_baseBtnDrag; }
  

   
   
   bool              Init(CTradeManager *tm, const string symbol, const ENUM_TIMEFRAMES tf);
   void              Destroy()
     {
      // später: Objekte löschen
     }
   // Base-UI Eventhandling (wie vorher in event.mqh)
   bool              HandleBaseUIEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   bool              OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   void              CreateDefaults();
   void              OnBaseLinesChanged(const bool do_save);
   void              SetObjectXClamped(const string name, const int x_left, const int chart_w);
   void              ApplyRightAnchor(const int right_margin_px, const int shift_px);
   bool              CaptureAnchorBaseline(const bool force);
   void              SyncBaseControlsToLines();
   void              UpdateEntrySLButtonTexts();
   bool              GetDraft(VT_Draft &out);
   void              UpdateTradePosTexts();
   int               ExtractIntDigits(const string text);
   void              ApplyTRNBOverrideFromUser();



  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool              CVirtualTradeGUI::Init(CTradeManager *tm, const string symbol, const ENUM_TIMEFRAMES tf)
  {
   m_tm = tm;
   m_symbol = symbol;
   m_tf = tf;
   m_chart = ChartID();
   m_baseBtnDrag.Bind(&m_baseLines);

   m_anchor_inited=false;
   m_trnb_editing=false;
   m_posnb_editing=false;

   return (m_tm != NULL && CheckPointer(m_tm) != POINTER_INVALID);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int              CVirtualTradeGUI::ExtractIntDigits(const string text)
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
// ------------------------------------------------------------------
// CVirtualTradeGUI: Base-UI Eventhandling (aus event.mqh in die Klasse gezogen)
// ------------------------------------------------------------------
bool CVirtualTradeGUI::HandleBaseUIEvent(const int id,
      const long &lparam,
      const double &dparam,
      const string &sparam)
  {
// BaseLine click -> exklusiv selektieren (ohne globale Variablen)
   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam == PR_HL || sparam == SL_HL)
        {
         // lokal: clicked selektieren, other deselektieren
         const string other = (sparam == PR_HL ? SL_HL : PR_HL);

         if(ObjectFind(0, sparam) >= 0)
            ObjectSetInteger(0, sparam, OBJPROP_SELECTED, true);
         if(ObjectFind(0, other)  >= 0)
            ObjectSetInteger(0, other,  OBJPROP_SELECTED, false);

         return true;
        }
     }

// BaseLine drag -> live sync
   if(id == CHARTEVENT_OBJECT_DRAG)
     {
      if(sparam == PR_HL || sparam == SL_HL)
        {
         if(m_baseLines.OnObjectDrag(sparam, dparam))
           {
            OnBaseLinesChanged(false);
            return true;
           }
        }
     }

// BaseLine change -> finalize + save
   if(id == CHARTEVENT_OBJECT_CHANGE)
     {
      if(sparam == PR_HL || sparam == SL_HL)
        {
         if(m_baseLines.OnObjectChange(sparam))
           {
            OnBaseLinesChanged(true);
            return true;
           }
        }
     }

// Buttons drag + BaseLines mouse coupling
   if(id == CHARTEVENT_MOUSE_MOVE)
     {
      const int mx = (int)lparam;
      const int my = (int)dparam;
      const int MouseState = (int)StringToInteger(sparam);

      m_baseLines.SetLastMouseY(my);

      if(m_baseBtnDrag.OnMouseMove(mx, my, MouseState))
        {
         if(m_baseBtnDrag.IsDragging())
            OnBaseLinesChanged(false);
         else
            OnBaseLinesChanged(true);

         return true;
        }

      m_baseLines.OnMouseMove(mx, my, MouseState, m_baseBtnDrag.IsDragging());
      return true;
     }

// CHART_CHANGE NICHT hier (weil InpBaseUI_* in event.mqh steht)
   return false;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool            CVirtualTradeGUI::OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
// Klick in TRNB/POSNB -> Sperre
   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam == TRNB || sparam == POSNB)
        {
         m_edit_tradepos = true;
         m_edit_obj = sparam;
        }
      else
        {
         m_edit_tradepos = false;
         m_edit_obj = "";
        }
      return false;
     }

// ENDEDIT TRNB -> übernehmen
   if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == TRNB)
     {
      ApplyTRNBOverrideFromUser();
      m_edit_tradepos = false;
      m_edit_obj = "";
      UpdateTradePosTexts();
      ChartRedraw(m_chart);
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CVirtualTradeGUI::GetBaseEntrySL(double &entry, double &sl)
  {
   entry = 0.0;
   sl = 0.0;
   if(ObjectFind(m_chart, PR_HL) < 0 || ObjectFind(m_chart, SL_HL) < 0)
      return false;

   entry = ObjectGetDouble(m_chart, PR_HL, OBJPROP_PRICE);
   sl    = ObjectGetDouble(m_chart, SL_HL, OBJPROP_PRICE);
   return (entry > 0.0 && sl > 0.0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CVirtualTradeGUI::DirectionFromLines()
  {
   double e=0,s=0;
   if(!GetBaseEntrySL(e,s))
      return "LONG"; // fallback
   return (s < e ? "LONG" : "SHORT");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CVirtualTradeGUI::GetDraft(VT_Draft &out)
  {
   double e=0,s=0;
   if(!GetBaseEntrySL(e,s))
      return false;

   out.entry_price = e;
   out.sl_price    = s;
   out.direction   = (s < e ? "LONG" : "SHORT");

   int active_trade = 0;
   m_tm.TM_GetActiveTradeNo(m_symbol, m_tf, out.direction, active_trade);

   if(active_trade > 0)
     {
      out.trade_no = active_trade;

      int next_pos = 1;
      m_tm.TM_GetNextPosNo(m_symbol, m_tf, out.direction, active_trade, next_pos);
      if(next_pos < 1)
         next_pos = 1;

      out.pos_no = next_pos;
     }
   else
     {
      int last_trade = 0;
      m_tm.TM_GetLastTradeNo(m_symbol, m_tf, last_trade);

      out.trade_no = (last_trade > 0 ? last_trade + 1 : 1);
      out.pos_no   = 1;
     }

// Sabio Freitext (nur lesen)
   out.sabio_entry = (ObjectFind(m_chart, SabioEntry) >= 0 ? ObjectGetString(m_chart, SabioEntry, OBJPROP_TEXT) : "");
   out.sabio_sl    = (ObjectFind(m_chart, SabioSL)    >= 0 ? ObjectGetString(m_chart, SabioSL,    OBJPROP_TEXT) : "");

   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CVirtualTradeGUI::UpdateTradePosTexts()
  {
// wenn User gerade tippt: TRNB/POSNB nicht überschreiben
   if(m_trnb_editing || m_posnb_editing)
      return;

   double e=0,s=0;
   if(!GetBaseEntrySL(e,s))
      return;

   string dir = (s < e ? "LONG" : "SHORT");

   int active_trade = 0;
   m_tm.TM_GetActiveTradeNo(m_symbol, m_tf, dir, active_trade);

   if(active_trade > 0)
     {
      int next_pos = 1;
      m_tm.TM_GetNextPosNo(m_symbol, m_tf, dir, active_trade, next_pos);
      update_Text(TRNB, IntegerToString(active_trade));
      update_Text(POSNB, IntegerToString(next_pos));
      return;
     }

   int last_trade = 0;
   m_tm.TM_GetLastTradeNo(m_symbol, m_tf, last_trade);

   int next_trade = (last_trade > 0 ? last_trade + 1 : 1);
   update_Text(TRNB, IntegerToString(next_trade));
   update_Text(POSNB, "1");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CVirtualTradeGUI::UpdateEntrySLButtonTexts()
  {
   double entry=0.0, sl=0.0;
   if(!GetBaseEntrySL(entry, sl))
      return;

   const bool is_long = (sl < entry);
   const double dist = MathAbs(entry - sl);

   double lots = 0.0;
   if(m_tm != NULL && CheckPointer(m_tm)!=POINTER_INVALID)
      lots = m_tm.calcLots(m_symbol, m_tf, dist);
   lots = NormalizeDouble(lots, 2);

   string entry_txt = (is_long ? "Buy Stop @ " : "Sell Stop @ ");
   entry_txt += DoubleToString(entry, _Digits) + " | Lot: " + DoubleToString(lots, 2);

   string sl_txt = "SL: " + DoubleToString(dist/_Point, 0) + " Points | " + DoubleToString(sl, _Digits);

   if(ObjectFind(m_chart, EntryButton) >= 0)
      update_Text(EntryButton, entry_txt);
   if(ObjectFind(m_chart, SLButton)    >= 0)
      update_Text(SLButton,    sl_txt);

// Sabio: Freitext NICHT überschreiben (wenn du Auto-Fill willst, nur wenn SabioPrices==true)
   if(SabioPrices)
     {
      if(ObjectFind(m_chart, SabioEntry) >= 0)
         update_Text(SabioEntry, "SABIO Entry: " + DoubleToString(entry, _Digits));
      if(ObjectFind(m_chart, SabioSL)    >= 0)
         update_Text(SabioSL,    "SABIO SL: " + DoubleToString(sl, _Digits));
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void  CVirtualTradeGUI::SyncBaseControlsToLines()
  {
   double entry=0.0, sl=0.0;
   if(!GetBaseEntrySL(entry, sl))
      return;

   datetime t = iTime(m_symbol, m_tf, 0);
   int x=0,y=0;

   const bool is_long = (sl < entry);

// ENTRY: EntryButton + Send + TRNB + POSNB + SabioEntry
   if(ObjectFind(m_chart, EntryButton) >= 0 && ChartTimePriceToXY(m_chart, 0, t, entry, x, y))
     {
      int ysize_entry = (int)ObjectGetInteger(m_chart, EntryButton, OBJPROP_YSIZE);
      int baseY = y - ysize_entry;

      UI_ObjSetIntSafe(m_chart, EntryButton,  OBJPROP_YDISTANCE, baseY);

      if(ObjectFind(m_chart, SENDTRADEBTN) >= 0)
         UI_ObjSetIntSafe(m_chart, SENDTRADEBTN, OBJPROP_YDISTANCE, baseY);

      // Edits: 30px unter EntryButton (aber nicht überschreiben wenn gerade getippt wird)
      if(ObjectFind(m_chart, TRNB) >= 0 && m_edit_obj != TRNB)
         UI_ObjSetIntSafe(m_chart, TRNB, OBJPROP_YDISTANCE, baseY + 30);

      if(ObjectFind(m_chart, POSNB) >= 0 && m_edit_obj != POSNB)
         UI_ObjSetIntSafe(m_chart, POSNB, OBJPROP_YDISTANCE, baseY + 30);

      if(ObjectFind(m_chart, SabioEntry) >= 0)
         UI_ObjSetIntSafe(m_chart, SabioEntry, OBJPROP_YDISTANCE, baseY + 30);

      // Optional: SLButton Abstand vom EntryButton beibehalten, wenn du das willst.
      // Wenn du SL nur rein aus SL_HL setzen willst, lass diesen Block weg.
     }

// SL: SLButton + SabioSL
   if(ObjectFind(m_chart, SLButton) >= 0 && ChartTimePriceToXY(m_chart, 0, t, sl, x, y))
     {
      int ysize_sl = (int)ObjectGetInteger(m_chart, SLButton, OBJPROP_YSIZE);
      int baseY = y - ysize_sl;

      UI_ObjSetIntSafe(m_chart, SLButton, OBJPROP_YDISTANCE, baseY);

      if(ObjectFind(m_chart, SabioSL) >= 0)
         UI_ObjSetIntSafe(m_chart, SabioSL, OBJPROP_YDISTANCE, baseY + 30);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CVirtualTradeGUI::CaptureAnchorBaseline(const bool force=false)
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CVirtualTradeGUI::SetObjectXClamped(const string name, const int x_left, const int chart_w)
  {
   if(ObjectFind(m_chart, name) < 0)
      return;
   UI_ObjSetIntSafe(m_chart, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);

   int xs = (int)ObjectGetInteger(m_chart, name, OBJPROP_XSIZE);
   if(xs < 0)
      xs = 0;

   int xx = x_left;
   if(xx < 0)
      xx = 0;
   if(chart_w > 0 && xs > 0 && xx > (chart_w - xs))
      xx = (chart_w - xs);
   if(xx < 0)
      xx = 0;

   UI_ObjSetIntSafe(m_chart, name, OBJPROP_XDISTANCE, xx);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CVirtualTradeGUI::ApplyRightAnchor(const int right_margin_px, const int shift_px)
  {
   if(!CaptureAnchorBaseline(false))
      return;

   long w=0;
   if(!ChartGetInteger(m_chart, CHART_WIDTH_IN_PIXELS, 0, w) || w <= 0)
      return;

   int entry_w = (ObjectFind(m_chart, EntryButton) >= 0)
                 ? (int)ObjectGetInteger(m_chart, EntryButton, OBJPROP_XSIZE)
                 : m_ref_w;
   if(entry_w <= 0)
      entry_w = m_ref_w;

   int new_entry_x = (int)w - right_margin_px - entry_w - shift_px;
   if(new_entry_x < 0)
      new_entry_x = 0;

   SetObjectXClamped(EntryButton,  new_entry_x, (int)w);
   SetObjectXClamped(SLButton,     new_entry_x + m_dx_slbtn, (int)w);
   SetObjectXClamped(SENDTRADEBTN, new_entry_x + m_dx_send, (int)w);
   SetObjectXClamped(TRNB,         new_entry_x + m_dx_trnb, (int)w);
   SetObjectXClamped(POSNB,        new_entry_x + m_dx_posnb, (int)w);
   SetObjectXClamped(SabioEntry,   new_entry_x + m_dx_sabE, (int)w);
   SetObjectXClamped(SabioSL,      new_entry_x + m_dx_sabS, (int)w);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CVirtualTradeGUI::OnBaseLinesChanged(const bool do_save)
  {
   SyncBaseControlsToLines();
   UpdateEntrySLButtonTexts();
   UpdateTradePosTexts(); // TRNB/POSNB aus TradeManager + Direction

   if(do_save && m_tm != NULL && CheckPointer(m_tm)!=POINTER_INVALID)
      m_tm.SaveLinePrices(m_symbol, m_tf);

   ChartRedraw(m_chart);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CVirtualTradeGUI::CreateDefaults()
  {
// 1) PR_HL + SL_HL erstellen

   int   xd3 = getChartWidthInPixels() -DistancefromRight-10;
   int   yd3 = getChartHeightInPixels()/2;
   int  xs3 = 280;
   int  ys3= 30;
   datetime dt_tp = iTime(_Symbol, 0, 0), dt_sl = iTime(_Symbol, 0, 0), dt_prc = iTime(_Symbol, 0, 0);
   double price_tp = iClose(_Symbol, 0, 0), price_sl = iClose(_Symbol, 0, 0), price_prc = iClose(_Symbol, 0, 0);
   int window = 0;

   ChartXYToTimePrice(0, xd3, yd3 + ys3, window, dt_prc, price_prc);


   createHLine(PR_HL, price_prc,color_EntryLine);
   SetPriceOnObject(PR_HL, price_prc);


//+------------------------------------------------------------------+
//createHL(PR_HL, dt_prc, price_prc, EntryLine);



   createButton(EntryButton, "", xd3, yd3, xs3, ys3, PriceButton_font_color, PriceButton_bgcolor, InpFontSize, clrNONE, InpFont);

// SL Button
   int xd5 = xd3;
   int yd5 = yd3 + 100;
   int xs5 = xs3;
   int ys5 = 30;

   ChartXYToTimePrice(0, xd5, yd5 + ys5, window, dt_sl, price_sl);

   createHL(SL_HL, dt_sl, price_sl, color_SLLine);

   ObjectMove(0, EntryButton, 0, dt_prc, price_prc);



// 2) Buttons/Edits erstellen


//   DrawHL();
   if(Sabioedit)
     {
      SabioEdit();
     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   SendButton();
   if(!SendOnlyButton)
     {
      ObjectSetString(0, SENDTRADEBTN, OBJPROP_TEXT, "T & S"); // label
      UI_ObjSetIntSafe(0, SENDTRADEBTN, OBJPROP_BGCOLOR, TSButton_bgcolor);
      ObjectSetInteger(0, SENDTRADEBTN, OBJPROP_COLOR, TSButton_font_color);
     }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


   createButton(SLButton, "", xd5, yd5, xs5, ys5, SLButton_font_color, SLButton_bgcolor, InpFontSize, clrNONE, InpFont);
   ObjectMove(0, SLButton, 0, dt_sl, price_sl);
// 3) Defaults setzen
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   update_Text(EntryButton, "Buy Stop @ " + Get_Price_s(PR_HL) + " | Lot: " + DoubleToString(NormalizeDouble(g_TradeMgr.calcLots(_Symbol,_Period,SL_Price - Entry_Price), 2), 2));
   update_Text(SLButton, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   ChartRedraw(0);

// 4) ApplyRightAnchor + OnBaseLinesChanged(false)
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void               CVirtualTradeGUI::ApplyTRNBOverrideFromUser()
  {
   if(ObjectFind(m_chart, TRNB) < 0)
      return;

   string s = ObjectGetString(m_chart, TRNB, OBJPROP_TEXT);
   int user_trade_no = ExtractIntDigits(s);
   if(user_trade_no <= 0)
      return;

// Nur wenn kein aktiver Trade in dieser Direction läuft
   string dir = DirectionFromLines();
   int active_trade=0;
   m_tm.TM_GetActiveTradeNo(m_symbol, m_tf, dir, active_trade);
   if(active_trade > 0)
      return;

// Startnummer setzen: last_trade_no = user_trade_no-1
   m_tm.TM_SetLastTradeNo(m_symbol, m_tf, user_trade_no - 1);
  }
#endif __CVIRTUALTRADEGUI_MQH__
//+------------------------------------------------------------------+
