#ifndef __TRADES_PANEL_CLASS_MQH__
#define __TRADES_PANEL_CLASS_MQH__
#include "trades_panel.mqh"
#include <Controls\Dialog.mqh>
#include <Controls\Panel.mqh>
#include <Controls\Label.mqh>
#include <Controls\Button.mqh>

#ifndef OBJ_ALL_PERIODS
#define OBJ_ALL_PERIODS 0xFFFFFFFF
#endif




/**
 * Beschreibung: Trades-Panel als gekapselte UI-Komponente (Create/Destroy/Rebuild/Event-Routing).
 * Parameter:    keine (Klasse kapselt ihren Zustand)
 * Rückgabewert: n/a
 * Hinweise:     - Nutzt Standardbibliothek (CDialog/CPanel/CLabel/CButton).
 *              - Rows werden dynamisch erstellt/gelöscht (Prefix-basiert).
 *              - Kein Heavy-Work pro Tick: Rebuild nur bei Bedarf.
 * Fehlerfälle:  Create einzelner Controls kann fehlschlagen -> Logs + Rückgabe false.
 */
class CTradesPanel
{
private:
   bool   m_created;
   int    m_x, m_y, m_w, m_h;

   // Namen der statischen Objekte (bleiben bestehen)
   string m_bg;
   string m_sep;
   string m_hdrL;
   string m_hdrR;
   string m_lblL;
   string m_lblR;
   string m_btnActiveL;
   string m_btnActiveR;
   string m_btnCancelL;
   string m_btnCancelR;

   // Layout
   int m_pad, m_gap, m_hdr_h, m_btn_h, m_row_h;
   int m_col_min, m_col_max, m_panel_max_w;
   int m_btnC_w, m_btnS_w;

   // Theme (einheitlich)
   color m_hdr_bg;
   color m_hdr_border;
   color m_lbl_long_col;
   color m_lbl_short_col;

   // interne Helfer
   bool CreateRect(const string name, const int x, const int y, const int w, const int h, const color border, const color bg, const int z)
   {
      // robust: existiert falscher Typ -> löschen
      if(ObjectFind(0, name) >= 0)
      {
         long t = ObjectGetInteger(0, name, OBJPROP_TYPE);
         if((ENUM_OBJECT)t != OBJ_RECTANGLE_LABEL)
            UI_Reg_DeleteOne(name);
      }

      if(ObjectFind(0, name) < 0)
      {
         ResetLastError();
         CPanel p;
         if(!p.Create(0, name, 0, x, y, x + w, y + h))
         {
            int err = GetLastError();
            Print(__FUNCTION__, ": CPanel.Create failed '", name, "' err=", err, " -> fallback ObjectCreate");
            ResetLastError();
            if(!ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
            {
               Print(__FUNCTION__, ": ObjectCreate failed '", name, "' err=", GetLastError());
               return false;
            }
         }
         UI_Reg_Add(name);
      }

      UI_ObjSetIntSafe(0, name, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
      UI_ObjSetIntSafe(0, name, OBJPROP_XDISTANCE,  x);
      UI_ObjSetIntSafe(0, name, OBJPROP_YDISTANCE,  y);
      UI_ObjSetIntSafe(0, name, OBJPROP_XSIZE,      w);
      UI_ObjSetIntSafe(0, name, OBJPROP_YSIZE,      h);
      UI_ObjSetIntSafe(0, name, OBJPROP_COLOR,      border);
      UI_ObjSetIntSafe(0, name, OBJPROP_BGCOLOR,    bg);
      UI_ObjSetIntSafe(0, name, OBJPROP_SELECTABLE, false);
      UI_ObjSetIntSafe(0, name, OBJPROP_BACK,       false);
      UI_ObjSetIntSafe(0, name, OBJPROP_ZORDER,     z);
      UI_ObjSetIntSafe(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
      return true;
   }

   bool CreateLabel(const string name, const int x, const int y, const string txt, const color col, const int fontsize)
   {
      // robust: existiert falscher Typ -> löschen
      if(ObjectFind(0, name) >= 0)
      {
         long t = ObjectGetInteger(0, name, OBJPROP_TYPE);
         if((ENUM_OBJECT)t != OBJ_LABEL)
            UI_Reg_DeleteOne(name);
      }

      if(ObjectFind(0, name) < 0)
      {
         ResetLastError();
         CLabel l;
         if(!l.Create(0, name, 0, x, y, x + 10, y + 10))
         {
            int err = GetLastError();
            Print(__FUNCTION__, ": CLabel.Create failed '", name, "' err=", err, " -> fallback ObjectCreate");
            ResetLastError();
            if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
            {
               Print(__FUNCTION__, ": ObjectCreate failed '", name, "' err=", GetLastError());
               return false;
            }
         }
         UI_Reg_Add(name);
      }

      UI_ObjSetIntSafe(0, name, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
      UI_ObjSetIntSafe(0, name, OBJPROP_XDISTANCE,  x);
      UI_ObjSetIntSafe(0, name, OBJPROP_YDISTANCE,  y);
      ObjectSetString(0, name, OBJPROP_TEXT, txt);
      ObjectSetString(0, name, OBJPROP_FONT, InpFont);
      UI_ObjSetIntSafe(0, name, OBJPROP_FONTSIZE,   fontsize);
      UI_ObjSetIntSafe(0, name, OBJPROP_COLOR,      col);
      UI_ObjSetIntSafe(0, name, OBJPROP_SELECTABLE, false);
      UI_ObjSetIntSafe(0, name, OBJPROP_ZORDER,     20000);
      UI_ObjSetIntSafe(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
      return true;
   }

   bool CreateButton(const string name, const int x, const int y, const int w, const int h, const string txt, const int fontsize)
   {
      if(ObjectFind(0, name) >= 0)
      {
         long t = ObjectGetInteger(0, name, OBJPROP_TYPE);
         if((ENUM_OBJECT)t != OBJ_BUTTON)
            UI_Reg_DeleteOne(name);
      }

      if(ObjectFind(0, name) < 0)
      {
         ResetLastError();
         CButton b;
         if(!b.Create(0, name, 0, x, y, x + w, y + h))
         {
            int err = GetLastError();
            Print(__FUNCTION__, ": CButton.Create failed '", name, "' err=", err, " -> fallback ObjectCreate");
            ResetLastError();
            if(!ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0))
            {
               Print(__FUNCTION__, ": ObjectCreate failed '", name, "' err=", GetLastError());
               return false;
            }
         }
         UI_Reg_Add(name);
      }

      UI_ObjSetIntSafe(0, name, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
      UI_ObjSetIntSafe(0, name, OBJPROP_XDISTANCE,  x);
      UI_ObjSetIntSafe(0, name, OBJPROP_YDISTANCE,  y);
      UI_ObjSetIntSafe(0, name, OBJPROP_XSIZE,      w);
      UI_ObjSetIntSafe(0, name, OBJPROP_YSIZE,      h);
      ObjectSetString(0, name, OBJPROP_TEXT, txt);
      ObjectSetString(0, name, OBJPROP_FONT, InpFont);
      UI_ObjSetIntSafe(0, name, OBJPROP_FONTSIZE, fontsize);
      UI_ObjSetIntSafe(0, name, OBJPROP_SELECTABLE, false);
      UI_ObjSetIntSafe(0, name, OBJPROP_BACK,       false);
      UI_ObjSetIntSafe(0, name, OBJPROP_ZORDER,     10010);
      UI_ObjSetIntSafe(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
      return true;
   }

   void DeleteRowsOnly()
   {
      TP_DeleteByPrefix(TP_ROW_LONG_TR_PREFIX);
      TP_DeleteByPrefix(TP_ROW_SHORT_TR_PREFIX);
      TP_DeleteByPrefix(TP_ROW_LONG_TR_Cancel_PREFIX);
      TP_DeleteByPrefix(TP_ROW_SHORT_TR_Cancel_PREFIX);

      TP_DeleteByPrefix(TP_ROW_LONG_PREFIX);
      TP_DeleteByPrefix(TP_ROW_SHORT_PREFIX);
      TP_DeleteByPrefix(TP_ROW_LONG_Cancel_PREFIX);
      TP_DeleteByPrefix(TP_ROW_SHORT_Cancel_PREFIX);
      TP_DeleteByPrefix(TP_ROW_LONG_hitSL_PREFIX);
      TP_DeleteByPrefix(TP_ROW_SHORT_hitSL_PREFIX);
   }

public:
   /**
    * Beschreibung: Konstruktor setzt Default-Layout/Theme.
    * Parameter:    keine
    * Rückgabewert: n/a
    * Hinweise:     Werte können später via SetTheme/SetLayout erweitert werden.
    * Fehlerfälle:  keine
    */
   CTradesPanel()
   {
      m_created = false;
      m_x = 10; m_y = 40; m_w = 440; m_h = 420;

      m_pad = 6; m_gap = 6; m_hdr_h = 22; m_btn_h = 22; m_row_h = 18;
      m_col_min = 140; m_col_max = 200; m_panel_max_w = 460;
      m_btnC_w = 18; m_btnS_w = 18;

      m_hdr_bg     = (color)C'22,22,22';
      m_hdr_border = (color)C'70,70,70';
      m_lbl_long_col  = (color)C'0,170,100';
      m_lbl_short_col = (color)C'220,70,70';

      m_bg = "TP_BG";
      m_sep = "TP_SEP";
      m_hdrL = "TP_HDR_LONG_BG";
      m_hdrR = "TP_HDR_SHORT_BG";
      m_lblL = TP_LBL_LONG;
      m_lblR = TP_LBL_SHORT;
      m_btnActiveL = TP_BTN_ACTIVE_LONG;
      m_btnActiveR = TP_BTN_ACTIVE_SHORT;
      m_btnCancelL = TP_BTN_CANCEL_LONG;
      m_btnCancelR = TP_BTN_CANCEL_SHORT;
   }

   /**
    * Beschreibung: Baut statische Panel-Elemente (BG/Header/Buttons) auf.
    * Parameter:    x,y,w,h - Position/Größe
    * Rückgabewert: bool - true wenn OK
    * Hinweise:     Rows werden nicht hier, sondern via RebuildRows() erzeugt.
    * Fehlerfälle:  CreateRect/CreateLabel/CreateButton kann fehlschlagen -> false.
    */
   bool Create(const int x, const int y, const int w, const int h)
   {
      m_x = x; m_y = y; m_w = w; m_h = h;
      if(m_w > m_panel_max_w) m_w = m_panel_max_w;

      // Layout: 2 Spalten + Mini-Buttons
      int overhead = 2*m_pad + m_gap + 2*(m_gap + m_btnC_w + m_gap + m_btnS_w);
      int col_w = (m_w - overhead) / 2;
      if(col_w < m_col_min) col_w = m_col_min;
      if(col_w > m_col_max) col_w = m_col_max;

      int block_w = col_w + m_gap + m_btnC_w + m_gap + m_btnS_w;
      int xL = m_x + m_pad;
      int xR = xL + block_w + m_gap;

      // tatsächliche Breite passend setzen
      m_w = 2*m_pad + block_w + m_gap + block_w;

      // BG
      if(!CreateRect(m_bg, m_x, m_y, m_w, m_h, PriceButton_bgcolor, clrBlack, 9990))
         return false;

      // Separator
      if(!CreateRect(m_sep, xL + block_w, m_y, m_gap, m_h, clrDimGray, clrDimGray, 9991))
         return false;

      // Header BGs
      int y1 = m_y + m_pad;
      if(!CreateRect(m_hdrL, xL, y1, block_w, m_hdr_h, m_hdr_border, m_hdr_bg, 9992)) return false;
      if(!CreateRect(m_hdrR, xR, y1, block_w, m_hdr_h, m_hdr_border, m_hdr_bg, 9992)) return false;

      // Labels (LONG grün / SHORT rot)
      if(!CreateLabel(m_lblL, xL + 6, y1 + 4, "LONG",  m_lbl_long_col, 10)) return false;
      if(!CreateLabel(m_lblR, xR + 6, y1 + 4, "SHORT", m_lbl_short_col, 10)) return false;

      // Buttons
      int y2 = y1 + m_hdr_h + 6;
      if(!CreateButton(m_btnActiveL, xL, y2, block_w, m_btn_h, "Active Trade", 9)) return false;
      if(!CreateButton(m_btnActiveR, xR, y2, block_w, m_btn_h, "Active Trade", 9)) return false;

      int y3 = y2 + m_btn_h + 6;
      if(!CreateButton(m_btnCancelL, xL, y3, block_w, m_btn_h, "Cancel Trade", 9)) return false;
      if(!CreateButton(m_btnCancelR, xR, y3, block_w, m_btn_h, "Cancel Trade", 9)) return false;

      // Default: hidden
      TP_SetButtonVisible(m_btnActiveL, false, "", clrBlack, clrBlack, clrBlack);
      TP_SetButtonVisible(m_btnActiveR, false, "", clrBlack, clrBlack, clrBlack);
      TP_SetButtonVisible(m_btnCancelL, false, "", clrBlack, clrBlack, clrBlack);
      TP_SetButtonVisible(m_btnCancelR, false, "", clrBlack, clrBlack, clrBlack);

      m_created = true;
      UI_RequestRedraw();
      return true;
   }

   /**
    * Beschreibung: Löscht Panel-Objekte inkl. Rows.
    * Parameter:    keine
    * Rückgabewert: void
    * Hinweise:     Nutzt UI_Reg_DeleteAll() wenn du global arbeitest.
    * Fehlerfälle:  keine
    */
   void Destroy()
   {
      if(!m_created) return;

      DeleteRowsOnly();

      UI_Reg_DeleteOne(m_lblL);
      UI_Reg_DeleteOne(m_lblR);
      UI_Reg_DeleteOne(m_btnActiveL);
      UI_Reg_DeleteOne(m_btnActiveR);
      UI_Reg_DeleteOne(m_btnCancelL);
      UI_Reg_DeleteOne(m_btnCancelR);
      UI_Reg_DeleteOne(m_hdrL);
      UI_Reg_DeleteOne(m_hdrR);
      UI_Reg_DeleteOne(m_sep);
      UI_Reg_DeleteOne(m_bg);

      m_created = false;
      UI_RequestRedraw();
   }

   /**
    * Beschreibung: Rendert nur die dynamischen Rows neu (DB -> UI).
    * Parameter:    keine
    * Rückgabewert: void
    * Hinweise:     Kein Neubau von Header/BG (Performance).
    * Fehlerfälle:  keine
    */
   void RebuildRows()
   {
      if(!m_created) return;

      // Nur Rows löschen
      DeleteRowsOnly();

      // TODO: Hier kommt 1:1 deine existierende DB->Rows Zeichenlogik rein,
      //       nur dass du xL/xR/col_w/block_w aus m_* berechnest (wie in Create()).

      UI_RequestRedraw();
   }

   /**
    * Beschreibung: Routed relevante Click-Events des Panels (Buttons/Row-Buttons).
    * Parameter:    id,lparam,dparam,sparam - OnChartEvent Parameter
    * Rückgabewert: bool - true wenn Event verarbeitet wurde (EA kann returnen)
    * Hinweise:     Nur OBJECT_CLICK behandeln (robust).
    * Fehlerfälle:  keine
    */
   bool OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
   {
      if(!m_created) return false;
      if(id != CHARTEVENT_OBJECT_CLICK) return false;

      // Header Buttons
      if(sparam == m_btnCancelL)
      {
         // TODO: Cancel LONG trade -> DB Update + Discord + RebuildRows
         Print("Panel: Cancel LONG clicked");
         return true;
      }
      if(sparam == m_btnCancelR)
      {
         Print("Panel: Cancel SHORT clicked");
         return true;
      }

      // TODO: Row-Buttons Prefix handling (TP_ROW_LONG_Cancel_PREFIX etc.)
      return false;
   }
};







#endif // __TRADES_PANEL_CLASS_MQH__