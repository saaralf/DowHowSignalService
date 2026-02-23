// event.mqh
// -----------------------------------------------------------------------------
// Zentraler Einstiegspunkt für Chart-Events.
// Reihenfolge:
//   1) CVirtualTradeGUI  (Base UI rechts: Entry/SL Buttons + Edits + Drag)
//   2) CChartEventRouter (TradesPanel + Controller-Kette)
//   3) Drag-Fallback (MouseUp-Erkennung für TradePosLines)
// -----------------------------------------------------------------------------

#ifndef __EVENT_MQH__
#define __EVENT_MQH__

#include "logger.mqh"
#include "ui_names.mqh"
#include "ui_state.mqh"
#include "CVirtualTradeGUI.mqh"
#include "CTradePosLineDragController.mqh"
#include "CChartEventRouter.mqh"

// (Optional) Alt-Input bleibt bestehen, auch wenn aktuell nicht benutzt.
input int InpUI_Deprecated_RedrawMinIntervalMs = 60; // deprecated

extern CVirtualTradeGUI g_vgui;

//+------------------------------------------------------------------+
//| Chart event handler                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   // ----------------------------------------------------------------
   // Preise aktuell halten (einige UI-/Lot-Berechnungen lesen das)
   // ----------------------------------------------------------------
   CurrentAskPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   CurrentBidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // ----------------------------------------------------------------
   // MouseMove: wir brauchen den MouseState (Flags) immer auch für
   // TradePosLine-Drag-Fallback (MouseUp-Erkennung).
   // ----------------------------------------------------------------
   if(id == CHARTEVENT_MOUSE_MOVE)
     {
      const int mx = (int)lparam;
      const int my = (int)dparam;
      const int mouse_state = (int)StringToInteger(sparam);

      // 1) Base UI (Entry/SL + Edits) darf zuerst ziehen/verschieben.
      const bool handled_by_base = g_vgui.HandleBaseUIEvent(id, lparam, dparam, sparam);

      // 3) MouseUp-Fallback für TradePosLines (nur anhand MouseState möglich)
      g_tp_drag.OnMouseMoveFinalizeIfNeeded(mouse_state);

      if(handled_by_base)
         return;

      // 2) Router (Panel/Send/Controller)
     g_evt_router.Dispatch(id, lparam, dparam, sparam);

      // TradesPanel Rebuild/Throttle (falls angefordert)
      g_tp.ProcessRebuild();
      return;
     }

   // ----------------------------------------------------------------
   // Alle anderen Events: Base UI zuerst
   // ----------------------------------------------------------------
   if(g_vgui.HandleBaseUIEvent(id, lparam, dparam, sparam))
      return;


   // ----------------------------------------------------------------
   // Router (Panel + Controller-Kette)
   // ----------------------------------------------------------------
  g_evt_router.Dispatch(id, lparam, dparam, sparam);

   // Chart-Resize / TF-Wechsel etc: Panel neu anfordern
   if(id == CHARTEVENT_CHART_CHANGE){
  
      g_tp.RequestRebuild();

      }

   // TradesPanel Rebuild/Throttle (falls angefordert)
   g_tp.ProcessRebuild();
  }


void UI_RequestRedraw()
  {
   g_ui_redraw_pending = true;
  }
input int InpUI_RedrawMinIntervalMs = 50;
static bool g_ui_redraw_pending = false;
static uint g_ui_last_redraw_ms = 0;

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

#endif // __EVENT_MQH__
