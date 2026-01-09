//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#ifndef __EVENTHANDLER__
#define __EVENTHANDLER__

#include "CSendButtonController.mqh"

#include "CChartEventRouter.mqh"

#include "discord_client.mqh"
#include "trade_manager.mqh"


// ------------------------------
// UI Layout (Right Anchor)
// ------------------------------
input int InpBaseUI_RightMarginPx = 30;   // Abstand von rechts (EntryButton-Rechte Kante)
input int InpBaseUI_RightShiftPx  = 0;    // optional: gesamtes Paket weiter nach links (+) / rechts (-)

input int InpUI_RedrawMinIntervalMs = 50;

static bool g_ui_redraw_pending = false;
static uint g_ui_last_redraw_ms = 0;




input bool InpDebugEventTrace = false; // true: Events in Experts loggen

/**
 * Beschreibung: Wandelt Chart-Event-IDs in lesbaren Text um.
 * Parameter:    id - Event-ID aus OnChartEvent
 * Rückgabewert: string - Name des Events
 * Hinweise:     Nur für Debug/Logs.
 * Fehlerfälle:  Keine.
 */
string UI_EventIdToStr(const int id)
  {
   switch(id)
     {
      case CHARTEVENT_OBJECT_CLICK:
         return "OBJECT_CLICK";
      case CHARTEVENT_OBJECT_DRAG:
         return "OBJECT_DRAG";
      case CHARTEVENT_OBJECT_CHANGE:
         return "OBJECT_CHANGE";
      case CHARTEVENT_OBJECT_ENDEDIT:
         return "OBJECT_ENDEDIT";
      case CHARTEVENT_MOUSE_MOVE:
         return "MOUSE_MOVE";
      case CHARTEVENT_CHART_CHANGE:
         return "CHART_CHANGE";
      default:
         return "OTHER";
     }
  }

/**
 * Beschreibung: Stellt sicher, dass ein angefordertes Redraw auch wirklich ausgeführt wird,
 *               bevor OnChartEvent per early-return endet (z.B. durch Router-Shortcuts).
 * Parameter:    none
 * Rückgabewert: void
 * Hinweise:     Behebt das "Label zieht erst später nach" Verhalten bei Drag/Change.
 * Fehlerfälle:  keine
 */
void UI_FlushRedrawBeforeReturn()
  {
   UI_ProcessRedraw();
  }


/**
 * Beschreibung: Prüft, ob ein Objektname zu den “interessanten” UI/Trade-Objekten gehört.
 * Parameter:    name - Objektname (sparam)
 * Rückgabewert: bool - true wenn relevant für Event-Diagnose
 * Hinweise:     Prefix-Checks für Trade-Linien und Panel-Row-Buttons.
 * Fehlerfälle:  Keine.
 */
bool UI_IsWatchedEventObject(const string name)
  {
   if(name == PR_HL || name == SL_HL)
      return true;
   if(name == EntryButton || name == SLButton)
      return true;
   if(name == SENDTRADEBTN)
      return true;
   if(name == SabioEntry || name == SabioSL)
      return true;

// Trade-Pos Linien
   if(StringFind(name, "Entry_Long_")  == 0)
      return true;
   if(StringFind(name, "SL_Long_")     == 0)
      return true;
   if(StringFind(name, "Entry_Short_") == 0)
      return true;
   if(StringFind(name, "SL_Short_")    == 0)
      return true;

// TradesPanel Row Buttons (Cancel/HitSL)
   if(StringFind(name, TP_ROW_LONG_Cancel_PREFIX)  == 0)
      return true;
   if(StringFind(name, TP_ROW_LONG_hitSL_PREFIX)   == 0)
      return true;
   if(StringFind(name, TP_ROW_SHORT_Cancel_PREFIX) == 0)
      return true;
   if(StringFind(name, TP_ROW_SHORT_hitSL_PREFIX)  == 0)
      return true;

   return false;
  }

/**
 * Beschreibung: Loggt relevante Chart-Events für watched Objects.
 * Parameter:    id,lparam,dparam,sparam - Standard OnChartEvent Parameter
 * Rückgabewert: void
 * Hinweise:     Filtert MOUSE_MOVE aggressiv (sonst Log-Spam).
 * Fehlerfälle:  Keine; reine Diagnose.
 */
void UI_DebugTraceEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(!InpDebugEventTrace)
      return;
// MouseMove nur loggen, wenn gerade ein Drag aktiv ist (sonst Spam)
   const bool baseDrag = g_BaseLines.IsDragging();
   const bool btnDrag  = g_BaseBtnDrag.IsDragging();

   if(id == CHARTEVENT_MOUSE_MOVE && !(btnDrag || baseDrag ))
      return;

   Print("EVT ", UI_EventIdToStr(id),
         " sparam='", sparam,
         "' lparam=", (long)lparam,
         " dparam=", DoubleToString(dparam, 8),
         " baseDrag=", (baseDrag ? "1":"0"),
         " btnDrag=", (btnDrag  ? "1":"0"));
  }


/**
 * Beschreibung: Merkt, dass ein Redraw nötig ist (ohne sofort zu zeichnen).
 * Parameter:    none
 * Rückgabewert: void
 * Hinweise:     Verwenden statt ChartRedraw in Low-Level UI Funktionen.
 * Fehlerfälle:  keine
 */
void UI_RequestRedraw()
  {
   g_ui_redraw_pending = true;
  }

/**
 * Beschreibung: Führt ein gedrosseltes ChartRedraw aus, wenn angefordert.
 * Parameter:    none
 * Rückgabewert: void
 * Hinweise:     Am Ende von OnChartEvent und/oder OnTick aufrufen.
 * Fehlerfälle:  keine
 */
void UI_ProcessRedraw()
  {
   if(!g_ui_redraw_pending)
      return;

   uint now = GetTickCount();
   if((now - g_ui_last_redraw_ms) < (uint)InpUI_RedrawMinIntervalMs)
      return;

   ChartRedraw(0);
   g_ui_last_redraw_ms = now;
   g_ui_redraw_pending = false;
  }



// ------------------------------------------------------------------
// Basis-Linien-Drag Tracking (PR_HL / SL_HL)
// Ziel: UI live synchronisieren, Speichern nur 1x beim Loslassen.
// ------------------------------------------------------------------
static bool   g_base_drag_active  = false;
static string g_base_drag_name    = "";
static uint   g_base_drag_last_ms = 0;
// --- Drag-State (nur für Basis-Buttons Entry/SL) ---
static bool   g_base_btn_drag_active   = false;
static string g_base_btn_drag_btn_name = "";
static string g_base_btn_drag_line_name= "";
static int    g_base_btn_drag_offset_y = 0;   // Cursor-Offset innerhalb des Buttons (top->cursor)
static int    g_base_btn_drag_btn_ysize = 0;  // Button-Höhe (für bottom-y -> price)
static bool   g_base_btn_prev_left_down = false;
// --- OPTIONAL: Gekoppelter Drag (Abstand Entry<->SL bleibt konstant) ---

// Letzte bekannte Maus-Y aus CHARTEVENT_MOUSE_MOVE (Fallback für Objekt-Drag)
static int g_last_mouse_y = -1;


// ---------------------------------------------------------
// Base UI Right Anchor (relativ zum EntryButton)
// ---------------------------------------------------------
static bool g_base_anchor_inited = false;
static int  g_base_ref_x         = 0;   // EntryButton XDISTANCE (Baseline)
static int  g_base_ref_w         = 0;   // EntryButton XSIZE (Baseline)

static int  g_dx_slbtn   = 0;
static int  g_dx_send    = 0;
static int  g_dx_trnb    = 0;
static int  g_dx_posnb   = 0;
static int  g_dx_sabEnt  = 0;
static int  g_dx_sabSL   = 0;

/**
 * Beschreibung: Merkt die aktuellen X-Offsets der Base-UI relativ zum EntryButton.
 * Parameter:    force - true: immer neu erfassen (z.B. nach Rebuild), false: nur beim ersten Mal
 * Rückgabewert: bool - true wenn EntryButton vorhanden und Baseline gespeichert
 * Hinweise:     Wir ändern hier nichts, wir speichern nur Offsets (Layout bleibt erhalten).
 * Fehlerfälle:  EntryButton fehlt -> false (kein Anchor möglich)
 */
bool BaseUI_CaptureAnchorBaseline(const bool force)
  {
   if(g_base_anchor_inited && !force)
      return true;

   if(ObjectFind(0, EntryButton) < 0)
      return false;

   g_base_ref_x = (int)ObjectGetInteger(0, EntryButton, OBJPROP_XDISTANCE);
   g_base_ref_w = (int)ObjectGetInteger(0, EntryButton, OBJPROP_XSIZE);
   if(g_base_ref_w <= 0)
      g_base_ref_w = 200; // Fallback

// relative Offsets (obj_x - entry_x)
   if(ObjectFind(0, SLButton) >= 0)
      g_dx_slbtn = (int)ObjectGetInteger(0, SLButton, OBJPROP_XDISTANCE) - g_base_ref_x;

   if(ObjectFind(0, SENDTRADEBTN) >= 0)
      g_dx_send = (int)ObjectGetInteger(0, SENDTRADEBTN, OBJPROP_XDISTANCE) - g_base_ref_x;

   if(ObjectFind(0, TRNB) >= 0)
      g_dx_trnb = (int)ObjectGetInteger(0, TRNB, OBJPROP_XDISTANCE) - g_base_ref_x;

   if(ObjectFind(0, POSNB) >= 0)
      g_dx_posnb = (int)ObjectGetInteger(0, POSNB, OBJPROP_XDISTANCE) - g_base_ref_x;

   if(ObjectFind(0, SabioEntry) >= 0)
      g_dx_sabEnt = (int)ObjectGetInteger(0, SabioEntry, OBJPROP_XDISTANCE) - g_base_ref_x;

   if(ObjectFind(0, SabioSL) >= 0)
      g_dx_sabSL = (int)ObjectGetInteger(0, SabioSL, OBJPROP_XDISTANCE) - g_base_ref_x;

   g_base_anchor_inited = true;
   return true;
  }

// ------------------------------------------------------------------
// BaseLine-Kopplung / Reentrancy-Guard
// ------------------------------------------------------------------
static bool   g_base_sync_guard   = false;  // schützt vor Rekursion wenn wir SL_HL programmgesteuert setzen
static bool   g_base_lock_distance = true;  // "PR_HL zieht SL_HL mit" aktiv
static double g_base_lock_delta    = 0.0;   // SL - Entry (Preisdelta)
// Mouse-Y Tracking für Live-UI während Linien-Drag (verhindert "Springen" bei SL_HL)

/**
 * Beschreibung: Liefert die aktuelle Chart-Breite in Pixeln.
 * Parameter:    none
 * Rückgabewert: int - Breite in Pixeln (0 bei Fehler)
 * Hinweise:     Wird für Right-Anchoring verwendet.
 * Fehlerfälle:  ChartGetInteger schlägt fehl -> Print + GetLastError
 */
int UI_GetChartWidthPx()
  {
   long w = 0;
   ResetLastError();
   if(!ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0, w))
     {
      Print(__FUNCTION__, ": ChartGetInteger(CHART_WIDTH_IN_PIXELS) failed err=", GetLastError());
      return 0;
     }
   return (int)w;
  }


/**
 * Beschreibung: Verankert die Base-UI an der rechten Chartkante.
 * Parameter:    none
 * Rückgabewert: void
 * Hinweise:     Nur X wird gesetzt. Y kommt weiter aus UI_SyncBaseButtonsToLines().
 * Fehlerfälle:  Chartbreite 0 oder EntryButton fehlt -> keine Aktion
 */
void BaseUI_ApplyRightAnchor()
  {
   if(!BaseUI_CaptureAnchorBaseline(false))
      return;

   int w = UI_GetChartWidthPx();
   if(w <= 0)
      return;

   int entry_w = (ObjectFind(0, EntryButton) >= 0)
                 ? (int)ObjectGetInteger(0, EntryButton, OBJPROP_XSIZE)
                 : g_base_ref_w;

   if(entry_w <= 0)
      entry_w = g_base_ref_w;

   int new_entry_x = w - InpBaseUI_RightMarginPx - entry_w - InpBaseUI_RightShiftPx;
   if(new_entry_x < 0)
      new_entry_x = 0;

   UI_SetObjectXClamped(EntryButton,   new_entry_x, w);
   UI_SetObjectXClamped(SLButton,      new_entry_x + g_dx_slbtn,  w);
   UI_SetObjectXClamped(SENDTRADEBTN,  new_entry_x + g_dx_send,   w);
   UI_SetObjectXClamped(TRNB,          new_entry_x + g_dx_trnb,   w);
   UI_SetObjectXClamped(POSNB,         new_entry_x + g_dx_posnb,  w);
   UI_SetObjectXClamped(SabioEntry,    new_entry_x + g_dx_sabEnt, w);
   UI_SetObjectXClamped(SabioSL,       new_entry_x + g_dx_sabSL,  w);
  }

/**
 * Beschreibung: Setzt das X (XDISTANCE) eines Objekts sicher (clamp an Chartbreite).
 * Parameter:    name   - Objektname
 *               x_left - gewünschte X-Position (linke Kante) in Pixel
 *               chart_w- Chartbreite in Pixel
 * Rückgabewert: void
 * Hinweise:     Erzwingt CORNER_LEFT_UPPER.
 * Fehlerfälle:  Objekt fehlt -> silent return
 */
void UI_SetObjectXClamped(const string name, const int x_left, const int chart_w)
  {
   if(ObjectFind(0, name) < 0)
      return;

   UI_ObjSetIntSafe(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);

   int xs = (int)ObjectGetInteger(0, name, OBJPROP_XSIZE);
   if(xs < 0)
      xs = 0;

   int xx = x_left;
   if(xx < 0)
      xx = 0;
   if(chart_w > 0 && xs > 0 && xx > (chart_w - xs))
      xx = (chart_w - xs);
   if(xx < 0)
      xx = 0;

   UI_ObjSetIntSafe(0, name, OBJPROP_XDISTANCE, xx);
  }

/**
 * Beschreibung: Verankert die Base-UI an der rechten Chartkante.
 * Parameter:    none
 * Rückgabewert: void
 * Hinweise:     Nur X wird gesetzt.
 * Fehlerfälle:  s.o.
 */
/*
void BaseUI_ApplyRightAnchor()
{
  if(!BaseUI_CaptureAnchorBaseline(false))
     return;

  int w = UI_GetChartWidthPx();
  if(w <= 0)
     return;

  int entry_w = (ObjectFind(0, EntryButton) >= 0) ? (int)ObjectGetInteger(0, EntryButton, OBJPROP_XSIZE) : g_base_ref_w;
  if(entry_w <= 0) entry_w = g_base_ref_w;

  int new_entry_x = w - InpBaseUI_RightMarginPx - entry_w - InpBaseUI_RightShiftPx;
  if(new_entry_x < 0) new_entry_x = 0;

  UI_SetObjectXClamped(EntryButton, new_entry_x, w);

  UI_SetObjectXClamped(SLButton,     new_entry_x + g_dx_slbtn,  w);
  UI_SetObjectXClamped(SENDTRADEBTN, new_entry_x + g_dx_send,   w);
  UI_SetObjectXClamped(TRNB,         new_entry_x + g_dx_trnb,   w);
  UI_SetObjectXClamped(POSNB,        new_entry_x + g_dx_posnb,  w);
  UI_SetObjectXClamped(SabioEntry,   new_entry_x + g_dx_sabEnt, w);
  UI_SetObjectXClamped(SabioSL,      new_entry_x + g_dx_sabSL,  w);
}


/**
 * Beschreibung: Liefert eine robuste Mouse-Y Pixelposition (für Live-UI beim Linien-Drag).
 * Parameter:    dparam - Event dparam (bei OBJECT_DRAG oft MouseY; sonst ggf. 0/unsinnig)
 * Rückgabewert: int - MouseY in Pixeln (0..ChartHeight-1)
 * Hinweise:     Falls dparam unplausibel ist, wird die letzte MouseMove-Y (g_last_mouse_y) genutzt.
 * Fehlerfälle:  Keine harten Fehler; wenn keine MouseMove-Y bekannt ist, wird geclamped.
 */
int UI_GetMouseYPxSafe(const double dparam)
  {
   const int h = UI_GetChartHeightPx();

// dparam versuchen (bei OBJECT_DRAG i.d.R. MouseY)
   int my = (int)MathRound(dparam);

// Wenn dparam Quatsch ist -> Fallback auf letzte MouseMove-Y
   if(h > 0 && (my < 0 || my > (h - 1)))
     {
      if(g_last_mouse_y >= 0)
         my = g_last_mouse_y;
     }

// Clamp
   if(my < 0)
      my = 0;
   if(h > 0 && my > (h - 1))
      my = h - 1;

   return my;
  }




/**
 * Beschreibung: Deselektiert beide Basislinien (PR_HL/SL_HL).
 * Parameter:    none
 * Rückgabewert: void
 * Hinweise:     Nützlich bei Chart-Hintergrund-Klick (damit nichts “selected” bleibt).
 * Fehlerfälle:  ObjectSetInteger kann fehlschlagen -> Print.
 */
void UI_DeselectBaseLines()
  {
   if(ObjectFind(0, PR_HL) >= 0)
     {
      ResetLastError();
      if(!ObjectSetInteger(0, PR_HL, OBJPROP_SELECTED, false))
         Print(__FUNCTION__, ": deselect PR_HL failed err=", GetLastError());
     }
   if(ObjectFind(0, SL_HL) >= 0)
     {
      ResetLastError();
      if(!ObjectSetInteger(0, SL_HL, OBJPROP_SELECTED, false))
         Print(__FUNCTION__, ": deselect SL_HL failed err=", GetLastError());
     }
  }

/**
 * Beschreibung: Selektiert genau eine Basislinie exklusiv und deselektiert die andere.
 * Parameter:    clicked_line - PR_HL oder SL_HL
 * Rückgabewert: void
 * Hinweise:     Fix für “beide Linien bleiben selected”.
 * Fehlerfälle:  ObjectSetInteger kann fehlschlagen -> Print.
 */
void UI_SelectBaseLineExclusive(const string clicked_line)
  {
   if(clicked_line != PR_HL && clicked_line != SL_HL)
      return;

   const string other = (clicked_line == PR_HL ? SL_HL : PR_HL);

// Clicked -> selected
   if(ObjectFind(0, clicked_line) >= 0)
     {
      ResetLastError();
      if(!ObjectSetInteger(0, clicked_line, OBJPROP_SELECTED, true))
         Print(__FUNCTION__, ": select ", clicked_line, " failed err=", GetLastError());
     }

// Other -> deselected
   if(ObjectFind(0, other) >= 0)
     {
      ResetLastError();
      if(!ObjectSetInteger(0, other, OBJPROP_SELECTED, false))
         Print(__FUNCTION__, ": deselect other ", other, " failed err=", GetLastError());
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // Identifikator des Ereignisses
                  const long &lparam,   // Parameter des Ereignisses des Typs long, X cordinates
                  const double &dparam, // Parameter des Ereignisses des Typs double, Y cordinates
                  const string &sparam) // Parameter des Ereignisses des Typs string, name of the object, state
  {



if(g_evt_router.Dispatch(id, lparam, dparam, sparam))
     {
      UI_FlushRedrawBeforeReturn();
      return;
     }


// Panel zuerst (damit es seine Buttons/Rows sauber abfangen kann)
   if(g_tp.OnChartEvent(id, lparam, dparam, sparam))
     {
      UI_FlushRedrawBeforeReturn();
      return;
     }

   UI_DebugTraceEvent(id, lparam, dparam, sparam);



   CurrentAskPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   CurrentBidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(g_tp.OnChartEvent(id, lparam, dparam, sparam))
      return;



   /**
    * Beschreibung: Merkt den letzten Klick auf PR_HL/SL_HL, damit Live-Fallback beim Drag die richtige Linie wählt.
    * Parameter:    id/lparam/dparam/sparam - Standard OnChartEvent Parameter
    * Rückgabewert: void
    * Hinweise:     Fix gegen "SL wird gezogen, aber PR-Branch greift -> SL springt zurück".
    * Fehlerfälle:  keine
    */
   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      if(g_send_ctl.OnObjectClick(sparam))
         return;

      if(sparam == PR_HL || sparam == SL_HL)
        {
         UI_SelectBaseLineExclusive(sparam);   // Fix Bug #2
         g_base_last_clicked_line = sparam;    // falls du das noch nutzt
         // kein return: falls du später noch Click-Logik addest
        }
     }






// --- Trade-Pos-Linien: Tag live nachziehen (DRAG), Discord/DB genau 1x pro Drag (Finalize)
   if(id == CHARTEVENT_OBJECT_DRAG)
     {

#ifdef PR_HL
#ifdef SL_HL
      if(sparam == PR_HL || sparam == SL_HL)
        {
         // Klassen-Handler
         if(g_BaseLines.OnObjectDrag(sparam, dparam))
            return;
        }
#endif
#endif

      // sonstige Trade-Linien (z.B. TP): nur Tag live
      if(UI_IsTradePosLine(sparam))
        {

         // WICHTIG: auch für die "anderen" TradePos-Linien-Branches redraw anfordern,
         // sonst wirkt das Label wie "Lag" und springt später hinterher.
         UI_LineTag_SyncToLine(sparam);
         UI_RequestRedrawThrottled(15); // 10–20ms wirkt flüssig; 15ms ist ein guter Start
         UI_FlushRedrawBeforeReturn();
         return;
        }
     }

   if(id == CHARTEVENT_OBJECT_CHANGE)
     {
    

#ifdef PR_HL
#ifdef SL_HL
      if(sparam == PR_HL || sparam == SL_HL)
        {
         if(g_BaseLines.OnObjectChange(sparam))
            return;
        }
#endif
#endif


      // Trade-Linien: wie gehabt
      if(UI_IsTradePosLine(sparam))
        {

         // WICHTIG: auch für die "anderen" TradePos-Linien-Branches redraw anfordern,
         // sonst wirkt das Label wie "Lag" und springt später hinterher.
         UI_LineTag_SyncToLine(sparam);
         UI_RequestRedrawThrottled(15); // 10–20ms wirkt flüssig; 15ms ist ein guter Start
         g_TradeMgr.SaveLinePrices(_Symbol, (ENUM_TIMEFRAMES)_Period);
         
         UI_FlushRedrawBeforeReturn();
         return;
        }

     }



// Preise der Linien direkt als double holen
   Entry_Price = Get_Price_d(PR_HL);
   SL_Price = Get_Price_d(SL_HL);

   if(id == CHARTEVENT_MOUSE_MOVE)

     {
      const int mx = (int)lparam;
      const int my = (int)dparam;
      const int MouseState = (int)StringToInteger(sparam);


      g_last_mouse_y = my;          // bleibt für anderes Zeug erhalten
      g_BaseLines.SetLastMouseY(my);

      // 1) Button-Drag (Entry/SL) hat Priorität
      if(g_BaseBtnDrag.OnMouseMove(mx, my, MouseState)) // Button Entry/Sl werden verschoben
         return;

      // 2) HLine-Fallback/Finalize (nur wenn Button-Drag NICHT aktiv)
      g_BaseLines.OnMouseMove(mx, my, MouseState, g_BaseBtnDrag.IsDragging()); //PR_HL und SL_HL werden verschoben
      return;
     }

   if(id == CHARTEVENT_CHART_CHANGE)
     {
      // Right Anchor neu anwenden
      g_BaseLines.ApplyRightAnchor();

      // Optional: UI sync (ohne Save)
      UI_OnBaseLinesChanged(false);

      return;
     }






//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(id == CHARTEVENT_OBJECT_ENDEDIT)
     {
      if(sparam == SabioEntry || sparam == SabioSL)
        {
         UpdateSabioTP();
        }
     }

   static bool last_ui_direction_is_long = true;
   if(last_ui_direction_is_long != ui_direction_is_long)
     {
      last_ui_direction_is_long = ui_direction_is_long;
      TP_RebuildRows();

     }



// Zentraler, gedrosselter Redraw (statt vieler ChartRedraw-Aufrufe)
   UI_ProcessRedraw();
   g_tp.ProcessRebuild();

  } // Ende ChartEvent




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UI_CloseOnePositionAndNotify(const string action,
                                  const string direction,
                                  const int trade_no,
                                  const int pos_no)
  {
// 1) Business-Teil (Discord + DB + Cache + Remaining-Check) -> TradeManager
   bool has_pending = true;
   string err = "";

   CTradeManager::EPosAction act =
      (action == "CANCEL" ? CTradeManager::POS_CANCEL : CTradeManager::POS_HIT_SL);

   if(!g_TradeMgr.HandlePositionAction(_Symbol, (ENUM_TIMEFRAMES)_Period,
                                       direction, trade_no, pos_no,
                                       act, has_pending, err))
     {
      CLogger::Add(LOG_LEVEL_WARNING, "HandlePositionAction failed: " + err);
      return;
     }

// 2) UI-Linien/Tags dieser Position entfernen (wie bisher)
   string suf_tp = "_" + IntegerToString(trade_no) + "_" + IntegerToString(pos_no);

   if(direction == "LONG")
     {
      UI_DeleteLineAndAllKnownTags(Entry_Long + suf_tp);
      UI_DeleteLineAndAllKnownTags(SL_Long    + suf_tp);
     }
   else
     {
      UI_DeleteLineAndAllKnownTags(Entry_Short + suf_tp);
      UI_DeleteLineAndAllKnownTags(SL_Short    + suf_tp);
     }

   UI_DeleteTradePosLines(trade_no, pos_no);


// 3) Falls letzte pending Position -> Runtime + Meta zurücksetzen
   if(!has_pending)
     {
      if(direction == "LONG")
        {
         if(active_long_trade_no == trade_no)
           {
            active_long_trade_no = 0;
            g_DB.SetMetaInt(g_DB.Key("active_long_trade_no"), 0);
           }

         is_long_trade     = false;
         HitEntryPriceLong = false;

         if(ObjectFind(0, "ActiveLongTrade") >= 0)
           {
            UI_ObjSetIntSafe(0, "ActiveLongTrade", OBJPROP_COLOR, clrNONE);
            UI_ObjSetIntSafe(0, "ActiveLongTrade", OBJPROP_BGCOLOR, clrNONE);
           }
        }
      else
        {
         if(active_short_trade_no == trade_no)
           {
            active_short_trade_no = 0;
            g_DB.SetMetaInt(g_DB.Key("active_short_trade_no"), 0);
           }

         is_sell_trade         = false;
         is_sell_trade_pending = false;
         HitEntryPriceShort    = false;

         if(ObjectFind(0, "ActiveShortTrade") >= 0)
           {
            UI_ObjSetIntSafe(0, "ActiveShortTrade", OBJPROP_COLOR, clrNONE);
            UI_ObjSetIntSafe(0, "ActiveShortTrade", OBJPROP_BGCOLOR, clrNONE);
           }
        }
     }

// 4) UI Refresh
   UI_UpdateNextTradePosUI();
   UI_ProcessRedraw();
  }



//+------------------------------------------------------------------+
//| Cancel active trade (header cancel buttons)                       |
//+------------------------------------------------------------------+
bool UI_CancelActiveTrade(const string direction)
  {
   const bool isLong = (direction == "LONG");
   int trade_no = (isLong ? active_long_trade_no : active_short_trade_no);

   if(trade_no <= 0)
     {
      CLogger::Add(LOG_LEVEL_INFO, "UI_CancelActiveTrade: kein aktiver Trade für " + direction);
      return false;
     }

   string err = "";
   if(!g_TradeMgr.CancelTrade(_Symbol, (ENUM_TIMEFRAMES)_Period, direction, trade_no, err))
     {
      CLogger::Add(LOG_LEVEL_WARNING, "UI_CancelActiveTrade: CancelTrade failed: " + err);
      return false;
     }

// Linien/Tags entfernen
   UI_DeleteTradeLinesByTradeNo(trade_no);


// Runtime + Meta zurücksetzen (damit OnInit NICHT reaktiviert)
   if(isLong)
     {
      if(active_long_trade_no == trade_no)
        {
         active_long_trade_no = 0;
         g_DB.SetMetaInt(g_DB.Key("active_long_trade_no"), 0);
        }
      is_long_trade     = false;
      HitEntryPriceLong = false;

      showActive_long(false);
      showCancel_long(false);

      if(ObjectFind(0, "ActiveLongTrade") >= 0)
        {
         UI_ObjSetIntSafe(0, "ActiveLongTrade", OBJPROP_COLOR, clrNONE);
         UI_ObjSetIntSafe(0, "ActiveLongTrade", OBJPROP_BGCOLOR, clrNONE);
        }
     }
   else
     {
      if(active_short_trade_no == trade_no)
        {
         active_short_trade_no = 0;
         g_DB.SetMetaInt(g_DB.Key("active_short_trade_no"), 0);
        }

      is_sell_trade         = false;
      is_sell_trade_pending = false;
      HitEntryPriceShort    = false;

      showActive_short(false);
      showCancel_short(false);

      if(ObjectFind(0, "ActiveShortTrade") >= 0)
        {
         UI_ObjSetIntSafe(0, "ActiveShortTrade", OBJPROP_COLOR, clrNONE);
         UI_ObjSetIntSafe(0, "ActiveShortTrade", OBJPROP_BGCOLOR, clrNONE);
        }
     }

   UI_UpdateNextTradePosUI();
   g_tp.RebuildRows();

   ChartRedraw(0);
   return true;
  }
/**
 * Beschreibung: Liest Entry- und SL-Preis sicher aus den Basis-HLines (PR_HL/SL_HL).
 * Parameter:    out_entry - Rückgabe Entry-Preis
 *               out_sl    - Rückgabe SL-Preis
 * Rückgabewert: true, wenn beide Linien existieren und Preise > 0 sind
 * Hinweise:     Nutzt ObjectFind/ObjectGetDouble mit Fehler-Logs.
 * Fehlerfälle:  Linien fehlen oder Preis<=0 -> false (Print im Log)
 */
bool UI_GetBaseEntrySL(double &out_entry, double &out_sl)
  {
   out_entry = 0.0;
   out_sl    = 0.0;

   if(ObjectFind(0, PR_HL) < 0 || ObjectFind(0, SL_HL) < 0)
     {
      Print(__FUNCTION__, ": PR_HL/SL_HL not found");
      return false;
     }

   ResetLastError();
   out_entry = ObjectGetDouble(0, PR_HL, OBJPROP_PRICE);
   int err1  = GetLastError();

   ResetLastError();
   out_sl    = ObjectGetDouble(0, SL_HL, OBJPROP_PRICE);
   int err2  = GetLastError();

   if(err1 != 0 || err2 != 0)
      Print(__FUNCTION__, ": ObjectGetDouble error entry=", err1, " sl=", err2);

   if(out_entry <= 0.0 || out_sl <= 0.0)
      return false;

   return true;
  }/**
 * Beschreibung: Aktualisiert Direction/Lot/Texts (EntryButton, SLButton, SabioEntry, SabioSL)
 *              anhand der Basislinien-Preise (PR_HL/SL_HL) als 1 Quelle der Wahrheit.
 * Parameter:    opt_direction_object_name - OPTIONAL: Name eines Labels/Buttons, das nur "BUY" oder "SELL" anzeigen soll.
 * Rückgabewert: void
 * Hinweise:     Sabio-Texts werden hier zentral gepflegt, damit MouseMove keine Sonderlogik mehr braucht.
 * Fehlerfälle:  Fehlende Objekte werden übersprungen; bei fehlenden Linien wird abgebrochen (Print im Log).
 */
void UI_UpdateBaseSignalTexts(const string opt_direction_object_name = "")
  {
   double entry = 0.0, sl = 0.0;
   if(!UI_GetBaseEntrySL(entry, sl))
      return;

// Direction: SL über Entry => SHORT, sonst LONG
   ui_direction_is_long = (sl < entry);

// Distanz robust positiv (für Lots/Risk)
   const double dist = MathAbs(entry - sl);

// Lots: nutzt deine bestehende Logik im TradeManager (keine Heavy-Operation)
   double lots = g_TradeMgr.calcLots(_Symbol, (ENUM_TIMEFRAMES)_Period, dist);
   lots = NormalizeDouble(lots, 2);

// Entry-Button Text: zeigt Direction + Preis + Lot
   string entry_txt = (ui_direction_is_long ? "Buy Stop @ " : "Sell Stop @ ");
   entry_txt += DoubleToString(entry, _Digits) + " | Lot: " + DoubleToString(lots, 2);

// SL-Button Text: zeigt SL-Preis + Distanz in Points
   string sl_txt = "SL: " + DoubleToString(dist / _Point, 0) + " Points | " + DoubleToString(sl, _Digits);

// UI aktualisieren (nur wenn Objekt existiert)
   if(ObjectFind(0, EntryButton) >= 0)
      update_Text(EntryButton, entry_txt);
   if(ObjectFind(0, SLButton)    >= 0)
      update_Text(SLButton,    sl_txt);

// Sabio-Texts zentral pflegen (damit MouseMove nicht doppelt rechnet)
   if(ObjectFind(0, SabioEntry) >= 0)
     {
      if(SabioPrices)
         update_Text(SabioEntry, "SABIO Entry: " + DoubleToString(entry, _Digits));
      else
         update_Text(SabioEntry, "SABIO ENTRY: ");
     }

   if(ObjectFind(0, SabioSL) >= 0)
     {
      if(SabioPrices)
         update_Text(SabioSL, "SABIO SL: " + DoubleToString(sl, _Digits));
      else
         update_Text(SabioSL, "SABIO SL: ");
     }

// OPTIONAL: Falls du irgendwo ein Direction-Label/Button hast
   if(opt_direction_object_name != "" && ObjectFind(0, opt_direction_object_name) >= 0)
      update_Text(opt_direction_object_name, (ui_direction_is_long ? "BUY" : "SELL"));
  }


/**
 * Beschreibung: Synchronisiert die Y-Position der Basis-UI (Entry/SL Buttons + Send/TRNB/POSNB + Sabio-Edits)
 *               zu den Basis-HLines PR_HL und SL_HL.
 * Parameter:    none
 * Rückgabewert: void
 * Hinweise:     Nur Y wird angepasst; X bleibt wie vom Layout vorgegeben.
 * Fehlerfälle:  ChartTimePriceToXY=false -> Print im Log
 */
void UI_SyncBaseButtonsToLines()
  {
   double entry = 0.0, sl = 0.0;
   if(!UI_GetBaseEntrySL(entry, sl))
      return;



// Wir nehmen die aktuelle Bar-Zeit als X-Anker (rechts sichtbar).
   datetime t = iTime(_Symbol, (ENUM_TIMEFRAMES)_Period, 0);

   int x = 0, y = 0;

// -------------------------
// ENTRY-GRUPPE (PR_HL)
// EntryButton, SENDTRADEBTN, TRNB, POSNB, SabioEntry
// -------------------------
   if(ObjectFind(0, EntryButton) >= 0)
     {
      int ysize_entry_btn = (int)ObjectGetInteger(0, EntryButton, OBJPROP_YSIZE);
      int entrySLBtnDistance = MathAbs((int)ObjectGetInteger(0, EntryButton, OBJPROP_YDISTANCE)- (int)ObjectGetInteger(0, SLButton, OBJPROP_YDISTANCE));


      if(ChartTimePriceToXY(0, 0, t, entry, x, y))
        {
         const int baseY = y - ysize_entry_btn;

         UI_ObjSetIntSafe(0, EntryButton,  OBJPROP_YDISTANCE, baseY);

         // SendButton sitzt links neben EntryButton auf gleicher Höhe
         if(ObjectFind(0, SENDTRADEBTN) >= 0)
            UI_ObjSetIntSafe(0, SENDTRADEBTN, OBJPROP_YDISTANCE, baseY);

         // TRNB/POSNB + SabioEntry sind 30px unter EntryButton
         if(ObjectFind(0, TRNB) >= 0)
            UI_ObjSetIntSafe(0, TRNB, OBJPROP_YDISTANCE, baseY + 30);

         if(ObjectFind(0, POSNB) >= 0)
            UI_ObjSetIntSafe(0, POSNB, OBJPROP_YDISTANCE, baseY + 30);

         if(ObjectFind(0, SabioEntry) >= 0)
            UI_ObjSetIntSafe(0, SabioEntry, OBJPROP_YDISTANCE, baseY + 30);

         //Auch SL Button und der SLSabio muss verschoben werden
         if(ObjectFind(0, SLButton) >= 0)
            if(ui_direction_is_long)
              {
               UI_ObjSetIntSafe(0, SLButton, OBJPROP_YDISTANCE, baseY-entrySLBtnDistance);
               if(ObjectFind(0, SabioSL) >= 0)
                  UI_ObjSetIntSafe(0, SabioSL, OBJPROP_YDISTANCE, baseY-entrySLBtnDistance + 30);
              }
            else
              {
               UI_ObjSetIntSafe(0, SLButton, OBJPROP_YDISTANCE, baseY+entrySLBtnDistance);
               if(ObjectFind(0, SabioSL) >= 0)
                  UI_ObjSetIntSafe(0, SabioSL, OBJPROP_YDISTANCE, baseY-entrySLBtnDistance + 30);
              }
        }
      else
        {
         Print(__FUNCTION__, ": ChartTimePriceToXY failed for Entry");
        }
     }

// -------------------------
// SL-GRUPPE (SL_HL)
// SLButton + SabioSL
// -------------------------
   if(ObjectFind(0, SLButton) >= 0)
     {
      int ysize_sl_btn = (int)ObjectGetInteger(0, SLButton, OBJPROP_YSIZE);

      bool did_set = false;

      // 1) Wenn gerade SL_HL gezogen wird: UI direkt aus MouseY setzen (kein Springen)
      if(g_BaseLines.IsDraggingSL() && g_BaseLines.GetDragMouseY() >= 0)
        {
         const int baseY = g_BaseLines.GetDragMouseY() - ysize_sl_btn;
         UI_ObjSetIntSafe(0, SLButton, OBJPROP_YDISTANCE, baseY);
         if(ObjectFind(0, SabioSL) >= 0)
            UI_ObjSetIntSafe(0, SabioSL, OBJPROP_YDISTANCE, baseY + 30);
         did_set = true;
        }

      // 2) Normalfall: aus Preis berechnen
      if(!did_set)
        {
         if(ChartTimePriceToXY(0, 0, t, sl, x, y))
           {
            const int baseY = y - ysize_sl_btn;
            UI_ObjSetIntSafe(0, SLButton, OBJPROP_YDISTANCE, baseY);

            if(ObjectFind(0, SabioSL) >= 0)
               UI_ObjSetIntSafe(0, SabioSL, OBJPROP_YDISTANCE, baseY + 30);
           }
         else
           {
            // 3) Fallback: falls ChartTimePriceToXY während Drag fehlschlägt
            //    -> NUR noch die neue Klassen-Quelle verwenden (kein Legacy-State)
            const int dy = g_BaseLines.GetDragMouseY();
            if(dy >= 0)
              {
               int h = UI_GetChartHeightPx();
               int yclamp = dy;

               // clamp (Sicherheit)
               if(h > 0)
                 {
                  if(yclamp < 0)
                     yclamp = 0;
                  if(yclamp > h - 1)
                     yclamp = h - 1;
                 }

               const int baseY = yclamp - ysize_sl_btn;
               UI_ObjSetIntSafe(0, SLButton, OBJPROP_YDISTANCE, baseY);

               if(ObjectFind(0, SabioSL) >= 0)
                  UI_ObjSetIntSafe(0, SabioSL, OBJPROP_YDISTANCE, baseY + 30);
              }
            else
              {
               Print(__FUNCTION__, ": ChartTimePriceToXY failed for SL (no drag Y fallback)");
              }

           }
        }
     }

  }


/**
 * Beschreibung: Zentraler Handler für Basis-Linienänderungen (Line-Drag oder Change-Event).
 * Parameter:    do_save - wenn true: LinePrices in DB persistieren (nur beim Finalize)
 * Rückgabewert: void
 * Hinweise:     Throttled Redraw, damit Drag flüssig bleibt.
 * Fehlerfälle:  Keine (nur Logs).
 */
void UI_OnBaseLinesChanged(const bool do_save)
  {
   UI_SyncBaseButtonsToLines();
   UI_UpdateBaseSignalTexts(); // Direction steckt im EntryButton-Text

   if(do_save)
     {
      g_TradeMgr.SaveLinePrices(_Symbol, (ENUM_TIMEFRAMES)_Period);
      Print(__FUNCTION__, ": finalized + saved base line prices");
     }

// Redraw throttlen: Drag kann sonst ruckeln
   static uint last_redraw_ms = 0;
   uint now = GetTickCount();
   if(do_save || (now - last_redraw_ms > 50))
     {
      ChartRedraw(0);
      last_redraw_ms = now;
     }
  }



// ------------------------------------------------------------------
// Neuer Basis-Drag-Ansatz (Entry/SL): Linie ist 1 Quelle der Wahrheit
// - Button-Drag setzt nur den Preis der zugehörigen HLine
// - UI (Buttons/Edits) folgt zentral über UI_OnBaseLinesChanged()
// ------------------------------------------------------------------

/**
 * Beschreibung: Liefert die Chart-Höhe in Pixeln robust (0 bei Fehler).
 * Parameter:    none
 * Rückgabewert: int - Höhe in Pixeln (0 bei Fehler)
 * Hinweise:     Wird für Clamp bei Drag verwendet.
 * Fehlerfälle:  ChartGetInteger schlägt fehl -> Print + GetLastError
 */
int UI_GetChartHeightPx()
  {
   long h = 0;
   ResetLastError();
   if(!ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0, h))
     {
      Print(__FUNCTION__, ": ChartGetInteger(CHART_HEIGHT_IN_PIXELS) failed err=", GetLastError());
      return 0;
     }
   return (int)h;
  }

/**
 * Beschreibung: Normalisiert einen Preis auf TickSize und Digits (sauberes Snapping).
 * Parameter:    price_raw - Rohpreis (z.B. aus ChartXYToTimePrice)
 * Rückgabewert: double - auf Tick gerundeter Preis
 * Hinweise:     SYMBOL_TRADE_TICK_SIZE wird bevorzugt, sonst _Point.
 * Fehlerfälle:  keine (Fallback auf _Point)
 */
double UI_NormalizeToTick(const double price_raw)
  {
   double tick = 0.0;
   if(!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE, tick) || tick <= 0.0)
      tick = _Point;

   double snapped = MathRound(price_raw / tick) * tick;
   return NormalizeDouble(snapped, _Digits);
  }

/**
 * Beschreibung: Prüft, ob ein Mouse-Punkt innerhalb eines OBJ_BUTTON-Rechtecks liegt.
 * Parameter:    obj_name - Objektname (Button)
 *               mx,my    - Mauskoordinaten (Pixel)
 *               out_xd   - Rückgabe XDISTANCE
 *               out_yd   - Rückgabe YDISTANCE
 *               out_xs   - Rückgabe XSIZE
 *               out_ys   - Rückgabe YSIZE
 * Rückgabewert: true, wenn innerhalb; sonst false
 * Hinweise:     Liest Button-Props direkt aus dem Objektmodell.
 * Fehlerfälle:  Objekt fehlt -> false (kein Print, um Logs nicht zu fluten)
 */
bool UI_PointInButtonRect(const string obj_name,
                          const int mx, const int my,
                          int &out_xd, int &out_yd, int &out_xs, int &out_ys)
  {
   if(ObjectFind(0, obj_name) < 0)
      return false;

   out_xd = (int)ObjectGetInteger(0, obj_name, OBJPROP_XDISTANCE);
   out_yd = (int)ObjectGetInteger(0, obj_name, OBJPROP_YDISTANCE);
   out_xs = (int)ObjectGetInteger(0, obj_name, OBJPROP_XSIZE);
   out_ys = (int)ObjectGetInteger(0, obj_name, OBJPROP_YSIZE);

   return (mx >= out_xd && mx <= (out_xd + out_xs) &&
           my >= out_yd && my <= (out_yd + out_ys));
  }

/**
 * Beschreibung: Setzt den Preis einer HLine robust (mit Fehlerlog).
 * Parameter:    line_name - Objektname (z.B. PR_HL / SL_HL)
 *               price     - Zielpreis (bereits normalisiert)
 * Rückgabewert: true bei Erfolg, sonst false
 * Hinweise:     Für OBJ_HLINE reicht OBJPROP_PRICE.
 * Fehlerfälle:  Linie fehlt oder ObjectSetDouble scheitert -> Print + GetLastError
 */
bool UI_SetHLinePriceSafe(const string line_name, const double price)
  {

   ResetLastError();
   if(!ObjectSetDouble(0, line_name, OBJPROP_PRICE, price))
     {
      return false;
     }
   return true;
  }


/**
 * Beschreibung: Liest den Preis einer HLine robust.
 * Parameter:    line_name - Objektname (PR_HL/SL_HL)
 *               out_price - Rückgabe Preis
 * Rückgabewert: true bei Erfolg, sonst false
 * Hinweise:     Erwartet OBJ_HLINE.
 * Fehlerfälle:  Linie fehlt -> Print; ObjectGetDouble liefert 0/Fehler -> Print
 */
bool UI_GetHLinePriceSafe(const string line_name, double &out_price)
  {
   if(ObjectFind(0, line_name) < 0)
     {
      Print(__FUNCTION__, ": line not found: ", line_name);
      return false;
     }

   ResetLastError();
   out_price = ObjectGetDouble(0, line_name, OBJPROP_PRICE);
   int err = GetLastError();
   if(err != 0)
     {
      Print(__FUNCTION__, ": ObjectGetDouble failed for ", line_name, " err=", err);
      return false;
     }
   return true;
  }

/**
* Beschreibung: Fordert ein Chart-Redraw an, aber gedrosselt (Throttle), um flüssiges UI beim Drag zu bekommen,
*              ohne die CPU mit ChartRedraw() zu fluten.
* Parameter:    min_interval_ms - Mindestabstand zwischen Redraw-Requests in Millisekunden
* Rückgabewert: void
* Hinweise:     Nutzt UI_RequestRedraw() (dein bestehender Mechanismus). Nur während Drag klein wählen.
* Fehlerfälle:  Keine (rein logisch). Wenn UI_RequestRedraw() fehlt -> Compile-Fehler.
*/
void UI_RequestRedrawThrottled(const uint min_interval_ms)
  {
   static uint s_last_ms = 0;
   const uint now = GetTickCount();
   if(now - s_last_ms < min_interval_ms)
      return;

   UI_RequestRedraw();     // dein bestehender "sanfter" Redraw-Request
   s_last_ms = now;
  }


// Merkt, welche Basislinie der User zuletzt angeklickt hat (wichtig, wenn beide "selected" sind)
static string g_base_last_clicked_line = "";

#endif // __EVENTHANDLER__
