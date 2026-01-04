//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#ifndef __EVENTHANDLER__
#define __EVENTHANDLER__


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
      case CHARTEVENT_OBJECT_CLICK:   return "OBJECT_CLICK";
      case CHARTEVENT_OBJECT_DRAG:    return "OBJECT_DRAG";
      case CHARTEVENT_OBJECT_CHANGE:  return "OBJECT_CHANGE";
      case CHARTEVENT_OBJECT_ENDEDIT: return "OBJECT_ENDEDIT";
      case CHARTEVENT_MOUSE_MOVE:     return "MOUSE_MOVE";
      case CHARTEVENT_CHART_CHANGE:   return "CHART_CHANGE";
      default:                        return "OTHER";
   }
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
   if(name == PR_HL || name == SL_HL) return true;
   if(name == EntryButton || name == SLButton) return true;
   if(name == SENDTRADEBTN) return true;
   if(name == SabioEntry || name == SabioSL) return true;

   // Trade-Pos Linien
   if(StringFind(name, "Entry_Long_")  == 0) return true;
   if(StringFind(name, "SL_Long_")     == 0) return true;
   if(StringFind(name, "Entry_Short_") == 0) return true;
   if(StringFind(name, "SL_Short_")    == 0) return true;

   // TradesPanel Row Buttons (Cancel/HitSL)
   if(StringFind(name, TP_ROW_LONG_Cancel_PREFIX)  == 0) return true;
   if(StringFind(name, TP_ROW_LONG_hitSL_PREFIX)   == 0) return true;
   if(StringFind(name, TP_ROW_SHORT_Cancel_PREFIX) == 0) return true;
   if(StringFind(name, TP_ROW_SHORT_hitSL_PREFIX)  == 0) return true;

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
   if(id == CHARTEVENT_MOUSE_MOVE && !(g_base_btn_drag_active || g_base_drag_active || g_tp_drag_active))
      return;

   if(sparam != "" && !UI_IsWatchedEventObject(sparam))
      return;

   Print("EVT ", UI_EventIdToStr(id),
         " sparam='", sparam,
         "' lparam=", (long)lparam,
         " dparam=", DoubleToString(dparam, 8),
         " baseDrag=", (g_base_drag_active ? "1":"0"),
         " btnDrag=",  (g_base_btn_drag_active ? "1":"0"),
         " tpDrag=",   (g_tp_drag_active ? "1":"0"));
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
// TradePos-Drag Tracking (damit Discord nur 1x pro Drag gesendet wird)
// Hinweis: Bei manchen MT5-Objekten kommt CHARTEVENT_OBJECT_CHANGE nicht
// zuverlässig. Darum finalisieren wir zusätzlich beim MouseUp.
// ------------------------------------------------------------------
static bool   g_tp_drag_active   = false;
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
static int    g_base_drag_mouse_y = -1;
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
 * Beschreibung: Startet/trackt einen Basislinien-Drag und friert bei PR_HL den Abstand (Delta) ein.
 * Parameter:    dragged_line - PR_HL oder SL_HL (die Linie, die der Nutzer gerade zieht)
 * Rückgabewert: void
 * Hinweise:     Delta wird nur bei PR_HL-Drag eingefroren, damit SL beim PR-Drag konstant folgt.
 * Fehlerfälle:  Wenn Linien fehlen, bleibt Delta unverändert (Logs über UI_GetHLinePriceSafe).
 */
void BaseLines_BeginDragIfNeeded(const string dragged_line)
  {
// Wenn wir gerade programmgesteuert syncen: nichts umstellen
   if(g_base_sync_guard)
      return;

// Drag-Start erkennen (neuer Drag oder anderer Linienname)
   if(!g_base_drag_active || g_base_drag_name != dragged_line)
     {
      g_base_drag_active  = true;
      g_base_drag_name    = dragged_line;
      g_base_drag_last_ms = GetTickCount();

      // Nur wenn PR_HL gezogen wird: Delta "einfrieren"
      if(g_base_lock_distance && dragged_line == PR_HL)
        {
         double entry=0.0, sl=0.0;
         if(UI_GetHLinePriceSafe(PR_HL, entry) && UI_GetHLinePriceSafe(SL_HL, sl))
            g_base_lock_delta = (sl - entry); // SL - Entry
        }
      return;
     }

// laufender Drag
   g_base_drag_last_ms = GetTickCount();
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
/*
/**
* Beschreibung: Wendet die gewünschte Linien-Drag-Regel an:
*               - PR_HL-Drag: SL_HL folgt mit konstantem Delta
*               - SL_HL-Drag: PR_HL bleibt stehen, Delta wird aktualisiert (SL - Entry)
* Parameter:    dragged_line - PR_HL oder SL_HL (die vom Nutzer gezogene Linie)
*               is_finalize  - true wenn Drag beendet (MouseUp/OBJECT_CHANGE), false für live
* Rückgabewert: bool - true wenn angewendet/ok, false bei fehlenden Objekten/Fehlern
* Hinweise:     Nutzt g_base_sync_guard gegen Rekursion durch ObjectSetDouble auf SL_HL.
* Fehlerfälle:  UI_SetHLinePriceSafe/UI_GetHLinePriceSafe loggen GetLastError.
*/
bool BaseLines_ApplyCoupling(const string dragged_line, const bool is_finalize)
  {
   if(!g_base_lock_distance)
      return true;

   if(g_base_sync_guard)
      return true;

   if(dragged_line != PR_HL && dragged_line != SL_HL)
      return true;

// Linien müssen existieren
   if(ObjectFind(0, PR_HL) < 0 || ObjectFind(0, SL_HL) < 0)
      return false;

// Reentrancy-Guard aktivieren
   g_base_sync_guard = true;

   double entry = 0.0, sl = 0.0;
   if(!UI_GetHLinePriceSafe(PR_HL, entry) || !UI_GetHLinePriceSafe(SL_HL, sl))
     {
      g_base_sync_guard = false;
      return false;
     }

// Snapping auf Tick (sauberes Verhalten bei Gold/Indices etc.)
   entry = UI_NormalizeToTick(entry);
   sl    = UI_NormalizeToTick(sl);

   if(dragged_line == PR_HL)
     {
      // PR_HL wird gezogen -> SL_HL soll folgen (Delta konstant)


      // Optional: PR_HL auf gesnappten Wert zurücksetzen (sauber)
      UI_SetHLinePriceSafe(PR_HL, entry);

      double sl_new = UI_NormalizeToTick(entry + g_base_lock_delta);
      UI_SetHLinePriceSafe(SL_HL, sl_new);
      // Delta bleibt unverändert
     }
   else // dragged_line == SL_HL
     {
      // SL_HL wird gezogen -> PR_HL bleibt stehen, SL setzt neuen Abstand
      UI_SetHLinePriceSafe(SL_HL, sl);

      // Delta wird durch SL-Drag bestimmt
      g_base_lock_delta = (sl - entry);
     }

   g_base_sync_guard = false;
   return true;
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
 * Beschreibung: MouseUp-Fallback für Basislinien. Falls MT5 kein OBJECT_CHANGE feuert,
 *               finalisieren wir beim Loslassen: Kopplung anwenden + UI sync + SaveLinePrices.
 * Parameter:    MouseState - 0 bedeutet MouseUp (Loslassen)
 * Rückgabewert: void
 * Hinweise:     Wird in CHARTEVENT_MOUSE_MOVE aufgerufen.
 * Fehlerfälle:  BaseLines_ApplyCoupling/UI_OnBaseLinesChanged loggen intern.
 */
void BaseLines_FinalizeDragIfNeeded(const int MouseState)
  {
   if(MouseState != 0)
      return;
   if(!g_base_drag_active)
      return;

// Final 1x die gewünschte Kopplung anwenden (wichtig wenn OBJECT_CHANGE ausbleibt)
   if(g_base_drag_name == PR_HL || g_base_drag_name == SL_HL)
      BaseLines_ApplyCoupling(g_base_drag_name, true);

// Reset Drag-State
   g_base_drag_active  = false;
   g_base_drag_name    = "";
   g_base_drag_last_ms = 0;
   g_base_drag_mouse_y = -1;

// Speichern + final redraw
   UI_OnBaseLinesChanged(true);
  }

static string g_tp_drag_name     = "";
static string g_tp_drag_dir      = "";   // "LONG" / "SHORT"
static string g_tp_drag_kind     = "";   // "entry" / "sl"
static int    g_tp_drag_trade_no = 0;
static int    g_tp_drag_pos_no   = 0;
static double g_tp_drag_old      = 0.0;
static double g_tp_drag_last     = 0.0;
static uint   g_tp_drag_last_ms  = 0;

// Finalisiert eine TradePos-Linienverschiebung: Tag updaten, speichern, Discord senden
void TP_FinalizeLineMove()
  {
   if(!g_tp_drag_active || g_tp_drag_name == "")
      return;

// Sicherheitscheck: Objekt muss existieren
   if(ObjectFind(0, g_tp_drag_name) < 0)
     {
      g_tp_drag_active = false;
      g_tp_drag_name = "";
      return;
     }

   const double new_price = g_tp_drag_last;
   const double old_price = g_tp_drag_old;

// UI: Tag sauber nachziehen
   UI_CreateOrUpdateLineTag(g_tp_drag_name);
     UI_RequestRedraw();


// DB: persistieren (erst nach dem old/new Vergleich)
   g_TradeMgr.SaveLinePrices(_Symbol,(ENUM_TIMEFRAMES)_Period);

// Discord: nur melden, wenn sich der Preis wirklich geändert hat
   const double pt = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   const bool changed = (old_price <= 0.0) || (MathAbs(new_price - old_price) > pt*0.25);

   if(changed && (g_tp_drag_kind == "entry" || g_tp_drag_kind == "sl"))
     {
      const string what = (g_tp_drag_kind == "entry") ? "Entry" : "SL";
      string msg = "@everyone\n";
      msg += StringFormat("**UPDATE:** %s %s Trade %d Pos %d (%s)\n",
                          _Symbol, TF_ToString((ENUM_TIMEFRAMES)_Period),
                          g_tp_drag_trade_no, g_tp_drag_pos_no, g_tp_drag_dir);
      if(old_price > 0.0)
         msg += StringFormat("**%s:** %s -> %s\n",
                             what,
                             DoubleToString(old_price, _Digits),
                             DoubleToString(new_price, _Digits));
      else
         msg += StringFormat("**%s:** %s\n", what, DoubleToString(new_price, _Digits));
      msg += "(Linie verschoben, Tag nachgezogen)\n";
      g_Discord.SendMessage(_Symbol,msg);
     }

// Reset
   g_tp_drag_active   = false;
   g_tp_drag_name     = "";
   g_tp_drag_dir      = "";
   g_tp_drag_kind     = "";
   g_tp_drag_trade_no = 0;
   g_tp_drag_pos_no   = 0;
   g_tp_drag_old      = 0.0;
   g_tp_drag_last     = 0.0;
   g_tp_drag_last_ms  = 0;
  }
/**
 * Beschreibung: Live-Fallback für Basislinien-Drag (PR_HL/SL_HL), ohne Umschalten wenn beide selected sind.
 * Parameter:    left_down - true wenn linke Maustaste gedrückt ist
 * Rückgabewert: void
 * Hinweise:     1) Wenn g_base_drag_active aktiv ist, wird NIE umgeschaltet (kein SL->PR "Hijack").
 *               2) Wenn beide Linien selected sind, wird die Linie gewählt, die näher an der Maus-Y liegt.
 *               3) Nur aktiv, wenn Maus nahe genug an der Linie ist (Threshold), sonst kein "Geister-Drag".
 * Fehlerfälle:  ChartTimePriceToXY kann fehlschlagen -> dann wird nichts erzwungen (sicherer als Springen).
 */
void BaseLines_LiveSyncFallback(const bool left_down)
  {
   if(!left_down)
      return;

// Button-Drag hat Vorrang
   if(g_base_btn_drag_active)
      return;

// Während programmgesteuertem Sync niemals eingreifen
   if(g_base_sync_guard)
      return;

// -------------------------------------------------------------
// 1) WICHTIG: Wenn Base-Drag bereits aktiv ist -> NICHT umschalten!
//    (genau das verursacht "SL springt auf Entry und zurück", wenn beide selected sind)
// -------------------------------------------------------------
   if(g_base_drag_active && (g_base_drag_name == PR_HL || g_base_drag_name == SL_HL))
     {
      // MouseY pflegen (für SLButton-MouseY-Fallback in UI_SyncBaseButtonsToLines)
      g_base_drag_mouse_y = (g_last_mouse_y >= 0 ? g_last_mouse_y : 0);

      BaseLines_ApplyCoupling(g_base_drag_name, false);
      UI_OnBaseLinesChanged(false);
      return;
     }

// -------------------------------------------------------------
// 2) Kein Base-Drag aktiv: Nur dann versuchen wir anhand selection zu starten
// -------------------------------------------------------------
   bool pr_sel = (ObjectFind(0, PR_HL) >= 0 && ObjectGetInteger(0, PR_HL, OBJPROP_SELECTED) != 0);
   bool sl_sel = (ObjectFind(0, SL_HL) >= 0 && ObjectGetInteger(0, SL_HL, OBJPROP_SELECTED) != 0);

   if(!pr_sel && !sl_sel)
      return;

// Wir reagieren nur, wenn die Maus wirklich nahe an der Linie ist
   const int THRESH_PX = 12;
   const int my = (g_last_mouse_y >= 0 ? g_last_mouse_y : 0);

   double entry = 0.0, sl = 0.0;
   if(!UI_GetHLinePriceSafe(PR_HL, entry) || !UI_GetHLinePriceSafe(SL_HL, sl))
      return;

// y-Positionen der Linien berechnen, um "welche Linie wird gerade gezogen?" sauber zu entscheiden
   datetime t = TimeCurrent();
   int x = 0, y_pr = 0, y_sl = 0;

   bool ok_pr = ChartTimePriceToXY(0, 0, t, entry, x, y_pr);
   bool ok_sl = ChartTimePriceToXY(0, 0, t, sl,    x, y_sl);

   if(!ok_pr && !ok_sl)
      return;

   int d_pr = (ok_pr ? (int)MathAbs(my - y_pr) : 999999);
   int d_sl = (ok_sl ? (int)MathAbs(my - y_sl) : 999999);

// Wenn Maus nicht nahe genug an irgendeiner Linie ist -> kein Fallback-Drag starten
   if(MathMin(d_pr, d_sl) > THRESH_PX)
      return;

// Linie wählen:
   string chosen = "";

   if(pr_sel && !sl_sel)
      chosen = PR_HL;
   else
      if(sl_sel && !pr_sel)
         chosen = SL_HL;
      else
        {
         // beide selected: wähle die nähere Linie zur Maus
         // Default bei Gleichstand: SL (sicherer, weil SL frei sein soll)
         chosen = (d_sl <= d_pr ? SL_HL : PR_HL);
        }

// Drag starten/tracken (Delta wird bei PR_HL korrekt eingefroren)
   BaseLines_BeginDragIfNeeded(chosen);

// MouseY für live UI
   g_base_drag_mouse_y = my;

   BaseLines_ApplyCoupling(chosen, false);
   UI_OnBaseLinesChanged(false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // Identifikator des Ereignisses
                  const long &lparam,   // Parameter des Ereignisses des Typs long, X cordinates
                  const double &dparam, // Parameter des Ereignisses des Typs double, Y cordinates
                  const string &sparam) // Parameter des Ereignisses des Typs string, name of the object, state
  {
 
    UI_DebugTraceEvent(id, lparam, dparam, sparam);

   CurrentAskPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   CurrentBidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);

// NEU: Delta im Idle aktuell halten
   BaseLines_UpdateDeltaIfIdle();
   /**
    * Beschreibung: Merkt den letzten Klick auf PR_HL/SL_HL, damit Live-Fallback beim Drag die richtige Linie wählt.
    * Parameter:    id/lparam/dparam/sparam - Standard OnChartEvent Parameter
    * Rückgabewert: void
    * Hinweise:     Fix gegen "SL wird gezogen, aber PR-Branch greift -> SL springt zurück".
    * Fehlerfälle:  keine
    */
   if(id == CHARTEVENT_OBJECT_CLICK)
     {
     
           // SEND button: nur auf echten Klick reagieren (kein State-Polling)
      if(sparam == SENDTRADEBTN)
      {
         // Button-State zurücksetzen, damit kein "stuck pressed" bleibt
         UI_ObjSetIntSafe(0, SENDTRADEBTN, OBJPROP_STATE, 0);

         if(Sabioedit == true)
         {
            int result = MessageBox("Sabio Preise angepasst?", NULL, MB_YESNO);
            if(result == IDYES)
               DiscordSend();
         }
         else
         {
            DiscordSend();
         }
         return;
      }

     
      if(sparam == PR_HL || sparam == SL_HL)
        {
         g_base_last_clicked_line = sparam;
         // Kein return: Click kann zusätzlich für andere Logik relevant sein
        }
     }

   if(UI_TradesPanel_OnChartEvent(id, lparam, dparam, sparam))
      return;





// --- Trade-Pos-Linien: Tag live nachziehen (DRAG), Discord/DB genau 1x pro Drag (Finalize)
   if(id == CHARTEVENT_OBJECT_DRAG)
     {
      string direction, kind;
      int trade_no, pos_no;

      // Nur Entry/SL der TradePos-Linien tracken
      if(UI_ParseTradePosFromName(sparam, direction, trade_no, pos_no, kind) && (kind == "entry" || kind == "sl"))
        {
         const double cur_price = ObjectGetDouble(0, sparam, OBJPROP_PRICE);

         // Drag-Start (neues Objekt oder vorher nicht aktiv)
         if(!g_tp_drag_active || g_tp_drag_name != sparam)
           {
            g_tp_drag_active   = true;
            g_tp_drag_name     = sparam;
            g_tp_drag_dir      = direction;
            g_tp_drag_kind     = kind;
            g_tp_drag_trade_no = trade_no;
            g_tp_drag_pos_no   = pos_no;
            g_tp_drag_last_ms  = GetTickCount();
            g_tp_drag_last     = cur_price;

            // old aus DB holen (falls vorhanden), sonst erstes Drag-Price als Fallback
            g_tp_drag_old = 0.0;
            DB_PositionRow row;
            if(g_DB.GetPosition(_Symbol, (ENUM_TIMEFRAMES)_Period, direction, trade_no, pos_no, row))
               g_tp_drag_old = (kind == "entry") ? row.entry : row.sl;
            if(g_tp_drag_old <= 0.0)
               g_tp_drag_old = cur_price;
           }
         else
           {
            // laufender Drag
            g_tp_drag_last_ms = GetTickCount();
            g_tp_drag_last    = cur_price;
           }

         // Tag live nachziehen
         UI_CreateOrUpdateLineTag(sparam);

         static uint last_redraw = 0;
         uint now = GetTickCount();
         if(now - last_redraw > 50)   // ~20 FPS
           {
            UI_RequestRedraw();
            last_redraw = now;
           }

         return; // TradePos-Drag fertig behandelt
        }
      // --- Basislinien (PR_HL / SL_HL): UI live nachziehen
      if(sparam == PR_HL || sparam == SL_HL)
        {

         g_base_last_clicked_line = sparam;

                // WICHTIG: Bei OBJECT_DRAG ist dparam bei HLINE/MT5 oft ein PREIS (Forex ~1.xxx).
         // Daher primär auf die echte MouseMove-Y zurückgreifen.
         g_base_drag_mouse_y = (g_last_mouse_y >= 0 ? g_last_mouse_y : UI_GetMouseYPxSafe(dparam));

         // Programmgesteuerte Änderungen (z.B. SL folgt) ignorieren, sonst Rekursion/Flackern
         if(g_base_sync_guard)
            return;

         BaseLines_BeginDragIfNeeded(sparam);
         static string last_dbg = "";
         if(last_dbg != sparam)
           {
            Print("BASE DRAG START: ", sparam, " last_click=", g_base_last_clicked_line);
            last_dbg = sparam;
           }

         // Live die gewünschte Kopplung anwenden:
         // PR_HL-Drag -> SL folgt; SL_HL-Drag -> Entry bleibt, Delta wird neu
         BaseLines_ApplyCoupling(sparam, false);

         // UI live nachziehen (Buttons/Edits/Texte), aber NICHT speichern
         UI_OnBaseLinesChanged(false);
         return;
        }

      // sonstige Trade-Linien (z.B. TP): nur Tag live
      if(UI_IsTradePosLine(sparam))
        {
         UI_CreateOrUpdateLineTag(sparam);
         return;
        }
     }

   if(id == CHARTEVENT_OBJECT_CHANGE)
     {
      // Wenn MT5 CHANGE liefert: finalize sofort (Discord + DB)
      if(g_tp_drag_active && sparam == g_tp_drag_name)
        {
         g_tp_drag_last = ObjectGetDouble(0, sparam, OBJPROP_PRICE);
         TP_FinalizeLineMove();
         return;
        }

      if(sparam == PR_HL || sparam == SL_HL)
        {
         // Programmgesteuerte CHANGE-Events ignorieren
         if(g_base_sync_guard)
            return;

         // Final: Kopplung + Delta sauber setzen
         BaseLines_ApplyCoupling(sparam, true);


         g_base_drag_name    = "";
         g_base_drag_last_ms = 0;
         g_base_drag_mouse_y = -1;

         // Final speichern
         UI_OnBaseLinesChanged(true);
         return;
        }


      // Trade-Linien: wie gehabt
      if(UI_IsTradePosLine(sparam))
        {
         UI_CreateOrUpdateLineTag(sparam);
         g_TradeMgr.SaveLinePrices(_Symbol, (ENUM_TIMEFRAMES)_Period);
         return;
        }

     }



// Preise der Linien direkt als double holen
   Entry_Price = Get_Price_d(PR_HL);
   SL_Price = Get_Price_d(SL_HL);

   if(id == CHARTEVENT_MOUSE_MOVE)
     {
      int MouseD_X = (int)lparam;
      int MouseD_Y = (int)dparam;
      g_last_mouse_y = MouseD_Y; // NEU: Fallback für Linien-Drag / OBJECT_DRAG

      int MouseState = (int)StringToInteger(sparam);

      // bestehend: TradePos-Fallback finalize
      if(MouseState == 0 && g_tp_drag_active)
         TP_FinalizeLineMove();

      // bestehend: BaseLines MouseUp-Fallback (für Linien-Drag)
      BaseLines_FinalizeDragIfNeeded(MouseState);

      // NEU: Button-Drag Controller (EntryButton/SLButton)
      if(BaseButtons_OnMouseMove(MouseD_X, MouseD_Y, MouseState))
         return;
      // 2) NEU: Linien-Drag live synchronisieren (auch ohne OBJECT_DRAG)
      const bool left_down = ((MouseState & 1) != 0);
      BaseLines_LiveSyncFallback(left_down);
      // nichts weiter im MouseMove nötig
      return;
     }


   if(id == CHARTEVENT_CHART_CHANGE)
     {
      // Bei Resize/Zoom: X rechts verankern + Y neu syncen (Skalierung ändert sich)
      BaseUI_ApplyRightAnchor();
      UI_OnBaseLinesChanged(false);   // nur UI, kein Save/Discord
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
      UI_UpdateNextTradePosUI();

      UI_UpdateAllLineTags();
     }



   // Zentraler, gedrosselter Redraw (statt vieler ChartRedraw-Aufrufe)
   UI_ProcessRedraw();

  } // Ende ChartEvent



/**
 * Beschreibung: Hält den Basis-Abstand (Delta = SL - Entry) aktuell, solange kein Drag läuft.
 * Parameter:    none
 * Rückgabewert: void
 * Hinweise:     Wird nur im Idle aktualisiert (kein Linien-Drag, kein Button-Drag).
 * Fehlerfälle:  UI_GetHLinePriceSafe loggt intern bei fehlenden Linien.
 */
void BaseLines_UpdateDeltaIfIdle()
  {
   if(!g_base_lock_distance)
      return;

// Während Drag niemals Delta "nachführen" (sonst geht das feste Delta verloren)
   if(g_base_drag_active || g_base_btn_drag_active)
      return;

   double entry = 0.0, sl = 0.0;
   if(!UI_GetHLinePriceSafe(PR_HL, entry) || !UI_GetHLinePriceSafe(SL_HL, sl))
      return;

   entry = UI_NormalizeToTick(entry);
   sl    = UI_NormalizeToTick(sl);

   g_base_lock_delta = (sl - entry);
  }

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
   UI_UpdateAllLineTags();

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
   UI_UpdateAllLineTags();

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
   UI_TradesPanel_RebuildRows();
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
      if(g_base_drag_active && g_base_drag_name == SL_HL && g_base_drag_mouse_y >= 0)
        {
         const int baseY = g_base_drag_mouse_y - ysize_sl_btn;
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
            if(g_base_drag_mouse_y >= 0)
              {
               const int baseY = g_base_drag_mouse_y - ysize_sl_btn;
               UI_ObjSetIntSafe(0, SLButton, OBJPROP_YDISTANCE, baseY);

               if(ObjectFind(0, SabioSL) >= 0)
                  UI_ObjSetIntSafe(0, SabioSL, OBJPROP_YDISTANCE, baseY + 30);
              }
            else
              {
               Print(__FUNCTION__, ": ChartTimePriceToXY failed for SL");
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BaseButtons_BeginDrag(const string btn_name,
                           const string line_name,
                           const int mouse_y,
                           const int btn_top_y,
                           const int btn_ys)
  {
   g_base_btn_drag_active    = true;
   g_base_btn_drag_btn_name  = btn_name;
   g_base_btn_drag_line_name = line_name;

   g_base_btn_drag_offset_y  = mouse_y - btn_top_y;
   g_base_btn_drag_btn_ysize = btn_ys;


// --- Delta nur dann neu aus Linien berechnen, wenn wir Entry ziehen ---
   if(g_base_lock_distance && line_name == PR_HL)
     {
      double entry=0.0, sl=0.0;
      if(UI_GetHLinePriceSafe(PR_HL, entry) && UI_GetHLinePriceSafe(SL_HL, sl))
         g_base_lock_delta = (sl - entry); // SL - Entry
      else
         g_base_lock_delta = 0.0;
     }

   ChartSetInteger(0, CHART_MOUSE_SCROLL, false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool BaseButtons_UpdateDrag(const int mouse_y)
  {
   if(!g_base_btn_drag_active)
      return false;

   if(ObjectFind(0, g_base_btn_drag_btn_name) < 0)
      return false;

   int xd = (int)ObjectGetInteger(0, g_base_btn_drag_btn_name, OBJPROP_XDISTANCE);
   int xs = (int)ObjectGetInteger(0, g_base_btn_drag_btn_name, OBJPROP_XSIZE);
   int x_center = xd + (xs / 2);

   int chart_h = UI_GetChartHeightPx();
   if(chart_h <= 0)
      return false;

   int desired_top    = mouse_y - g_base_btn_drag_offset_y;
   int desired_bottom = desired_top + g_base_btn_drag_btn_ysize;

   if(desired_bottom < 0)
      desired_bottom = 0;
   if(desired_bottom > chart_h - 1)
      desired_bottom = chart_h - 1;

   datetime t = 0;
   double price = 0.0;
   int window = 0;

   ResetLastError();
   if(!ChartXYToTimePrice(0, x_center, desired_bottom, window, t, price))
     {
      static uint last_log_ms = 0;
      uint now = GetTickCount();
      if(now - last_log_ms > 500)
        {
         Print(__FUNCTION__, ": ChartXYToTimePrice failed err=", GetLastError());
         last_log_ms = now;
        }
      return false;
     }

   price = UI_NormalizeToTick(price);

// --- NEU: Regeln exakt wie gewünscht ---
// 1) Entry-Drag: SL läuft mit (Abstand bleibt konstant während des Drags)
// 2) SL-Drag: Entry bleibt stehen, SL bewegt sich alleine und setzt neuen Abstand (Delta)
//    -> Delta wird live aktualisiert (SL - Entry), damit der nächste Entry-Drag dieses Delta nutzt.

   if(g_base_lock_distance)
     {
      // Aktuellen Entry-Preis immer sauber lesen (Entry soll ggf. stehen bleiben)
      double entry_cur = 0.0;
      if(!UI_GetHLinePriceSafe(PR_HL, entry_cur))
         return false;

      if(g_base_btn_drag_line_name == PR_HL)
        {
         // --- FALL 1: Entry wird gezogen -> SL folgt mit konstantem Delta ---
         double entry_new = price;
         double sl_new    = UI_NormalizeToTick(entry_new + g_base_lock_delta);

         if(!UI_SetHLinePriceSafe(PR_HL, entry_new))
            return false;
         if(!UI_SetHLinePriceSafe(SL_HL, sl_new))
            return false;

         // Delta bleibt während Entry-Drag konstant (nicht neu setzen!)
        }
      else
         if(g_base_btn_drag_line_name == SL_HL)
           {
            // --- FALL 2: SL wird gezogen -> Entry bleibt stehen ---
            double sl_new = price;

            if(!UI_SetHLinePriceSafe(SL_HL, sl_new))
               return false;

            // Neues Delta (Abstand) wird durch SL-Drag bestimmt
            g_base_lock_delta = (sl_new - entry_cur);
           }
         else
           {
            // Fallback: unbekannte Linie -> nur diese Linie setzen
            if(!UI_SetHLinePriceSafe(g_base_btn_drag_line_name, price))
               return false;
           }
     }
   else
     {
      // Ungekoppelt: nur die gezogene Linie
      if(!UI_SetHLinePriceSafe(g_base_btn_drag_line_name, price))
         return false;
     }


// Zentral: UI folgt Linien (Buttons/Edits + Texte/Lot/Direction)
   UI_OnBaseLinesChanged(false);
   return true;
  }

/**
 * Beschreibung: Beendet den Button-Drag und speichert final 1x (DB/Discord abhängig von eurem Flow).
 * Parameter:    none
 * Rückgabewert: void
 * Hinweise:     Schaltet Chart-Scroll wieder an und triggert UI_OnBaseLinesChanged(true).
 * Fehlerfälle:  keine
 */
void BaseButtons_EndDrag()
  {
   if(!g_base_btn_drag_active)
      return;

   g_base_btn_drag_active = false;

   ChartSetInteger(0, CHART_MOUSE_SCROLL, true);

// Final: 1x speichern + final redraw
   UI_OnBaseLinesChanged(true);

   g_base_btn_drag_btn_name   = "";
   g_base_btn_drag_line_name  = "";
   g_base_btn_drag_offset_y   = 0;
   g_base_btn_drag_btn_ysize  = 0;
  }

/**
 * Beschreibung: MouseMove-Controller: Start/Update/End Drag für EntryButton & SLButton.
 * Parameter:    mx,my      - Mauskoordinaten
 *               mouseState - Bitmaske aus sparam (MK_LBUTTON etc.)
 * Rückgabewert: true, wenn Controller das Event „konsumiert“ (drag aktiv), sonst false
 * Hinweise:     Nutzt Bit-Prüfung (robust auch mit SHIFT/CTRL gedrückt).
 * Fehlerfälle:  keine (Objekt fehlt => kein Drag)
 */
bool BaseButtons_OnMouseMove(const int mx, const int my, const int mouseState)
  {
   const bool left_down = ((mouseState & 1) != 0); // 1 == MK_LBUTTON

// Start Drag nur bei Flanke: vorher nicht gedrückt, jetzt gedrückt
   if(!g_base_btn_drag_active && !g_base_btn_prev_left_down && left_down)
     {
      int xd, yd, xs, ys;

      // EntryButton hat Priorität, falls sich Bereiche überlappen (normal nicht)
      if(UI_PointInButtonRect(EntryButton, mx, my, xd, yd, xs, ys))
        {
         BaseButtons_BeginDrag(EntryButton, PR_HL, my, yd, ys);
        }
      else
         if(UI_PointInButtonRect(SLButton, mx, my, xd, yd, xs, ys))
           {
            BaseButtons_BeginDrag(SLButton, SL_HL, my, yd, ys);
           }
     }

// Update / End
   if(g_base_btn_drag_active)
     {
      if(left_down)
         BaseButtons_UpdateDrag(my);
      else
         BaseButtons_EndDrag();

      g_base_btn_prev_left_down = left_down;
      return true; // Drag aktiv => wir konsumieren MouseMove
     }

   g_base_btn_prev_left_down = left_down;
   return false;
  }


// Merkt, welche Basislinie der User zuletzt angeklickt hat (wichtig, wenn beide "selected" sind)
static string g_base_last_clicked_line = "";

#endif // __EVENTHANDLER__
