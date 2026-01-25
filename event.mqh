//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#ifndef __EVENTHANDLER__
#define __EVENTHANDLER__
#include "CVirtualTradeGUI.mqh"
#include "CSendButtonController.mqh"
#include "ui_state.mqh"
#include "CChartEventRouter.mqh"

#include "CDiscordClient.mqh"
#include "CTradeManager.mqh"
#include "CTradePosLineDragController.mqh"

// ------------------------------
// UI Layout (Right Anchor)
// ------------------------------
input int InpBaseUI_RightMarginPx = 30;   // Abstand von rechts (EntryButton-Rechte Kante)
input int InpBaseUI_RightShiftPx  = 0;    // optional: gesamtes Paket weiter nach links (+) / rechts (-)

input int InpUI_RedrawMinIntervalMs = 50;

static bool g_ui_redraw_pending = false;
static uint g_ui_last_redraw_ms = 0;




input bool InpDebugEventTrace = false; // true: Events in Experts loggen
extern CVirtualTradeGUI g_vgui;
//extern CVirtualTradeGUI g_vgui;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   bool handled = false;


   CurrentAskPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   CurrentBidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);





// 2) BaseUI (Drag Lines/Buttons + Sync)
   if(g_vgui.HandleBaseUIEvent(id, lparam, dparam, sparam))
      handled = true;

// 3) Router / restliche Logik wie bisher...

   if(g_evt_router.Dispatch(id, lparam, dparam, sparam))
      handled = true;

// 1) Legacy / restliche Verarbeitung nur wenn Router NICHT handled hat
  if(!handled)
     {



      // OBJECT_CLICK (Fallback)
      if(id == CHARTEVENT_OBJECT_CLICK)
        {
         if(g_send_ctl.OnObjectClick(sparam))
           {
            handled = true;
           }
        }

      // OBJECT_DRAG
      if(!handled && id == CHARTEVENT_OBJECT_DRAG)
        {
         if(g_tp_drag.OnObjectDrag(sparam))
           {
            handled = true;
           }
         else
           {
            if(!handled && UI_IsTradePosLine(sparam))
              {
               UI_RequestRedrawThrottled(15);
               handled = true;
              }
           }
        }

      // OBJECT_CHANGE
      if(!handled && id == CHARTEVENT_OBJECT_CHANGE)
        {
         if(g_tp_drag.OnObjectChange(sparam))
           {
            handled = true;
           }
         else
           {

            if(!handled && UI_IsTradePosLine(sparam))
              {
               UI_RequestRedrawThrottled(15);
               g_TradeMgr.SaveLinePrices(_Symbol, (ENUM_TIMEFRAMES)_Period);
               handled = true;
              }
           }
        }

      // Preise der Linien (wie vorher, aber nur wenn wir noch nicht handled sind)
      if(!handled)
        {
         Entry_Price = Get_Price_d(PR_HL);
         SL_Price    = Get_Price_d(SL_HL);
        }

      // MOUSE_MOVE
      if(!handled && id == CHARTEVENT_MOUSE_MOVE)
        {
         const int mx = (int)lparam;
         const int my = (int)dparam;
         const int MouseState = (int)StringToInteger(sparam);

         // TradePosLine finalize muss bleiben
         g_tp_drag.OnMouseMoveFinalizeIfNeeded(MouseState);

        }

      // CHART_CHANGE
      if(!handled && id == CHARTEVENT_CHART_CHANGE)
        {
         // TradePosLine Tags bleiben separat
         g_tradePosLines.SyncAllTags();


         g_tradePosLines.SyncAllTags();
         UI_ApplyZOrder();
         handled = true;
        }
     } // if(!handled)
  


// --- Post-Phase: MUSS IMMER laufen ---

// Post-Phase + Redraw wie bisher
   static bool last_is_long = true;
   if(last_is_long != g_ui_state.is_long)
     {
      last_is_long = g_ui_state.is_long;
      TP_RebuildRows();
     }

   UI_ProcessRedraw();
   g_tp.ProcessRebuild();

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
static string g_base_edit_active = ""; // "", TRNB oder POSNB wenn User gerade tippt

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
static bool g_sabio_user_override = false; // sobald User Sabio editiert -> keine Auto-Texte mehr
/**
 * Beschreibung: Merkt die aktuellen X-Offsets der Base-UI relativ zum EntryButton.
 * Parameter:    force - true: immer neu erfassen (z.B. nach Rebuild), false: nur beim ersten Mal
 * Rückgabewert: bool - true wenn EntryButton vorhanden und Baseline gespeichert
 * Hinweise:     Wir ändern hier nichts, wir speichern nur Offsets (Layout bleibt erhalten).
 * Fehlerfälle:  EntryButton fehlt -> false (kein Anchor möglich)
 */

// ------------------------------------------------------------------
// BaseLine-Kopplung / Reentrancy-Guard
// ------------------------------------------------------------------
static bool   g_base_sync_guard   = false;  // schützt vor Rekursion wenn wir SL_HL programmgesteuert setzen
static bool   g_base_lock_distance = true;  // "PR_HL zieht SL_HL mit" aktiv
static double g_base_lock_delta    = 0.0;   // SL - Entry (Preisdelta)
// Mouse-Y Tracking für Live-UI während Linien-Drag (verhindert "Springen" bei SL_HL)




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


#endif // __EVENTHANDLER__
