//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#ifndef __CCHART_EVENT_ROUTER_MQH__
#define __CCHART_EVENT_ROUTER_MQH__
#include "context.mqh"
#include "ui_names.mqh"
#include "CTradesPanel.mqh"

#include "CVirtualTradeGUI.mqh"
#include "CTradeManager.mqh"
#include "CDBService.mqh"

// Globals (müssen in *einer* .mq5 oder zentraler .mqh auch wirklich existieren!)
extern CTradesPanel          g_tp;
//extern CSendButtonController g_send_ctl;
extern CVirtualTradeGUI      g_vgui;       // ODER: extern CVirtualTradeGUI g_vgui;
extern CTradeManager         g_TradeMgr;
extern CDBService            g_DB;


/**
 * Beschreibung: Zentraler Router für Chart-Events. Legt die Reihenfolge fest:
 *               1) TradesPanel (C*-GUI) 2) Controller (Send, Drag, ...) 3) Legacy/Rest.
 * Parameter:    id,lparam,dparam,sparam - Standard ChartEvent Parameter
 * Rückgabewert: bool - true wenn Event vollständig verarbeitet wurde
 * Hinweise:     Erst wenn Router false liefert, läuft Legacy-Code weiter.
 * Fehlerfälle:  keine
 */
class CChartEventRouter
  {
public:
   SContext          m_ctx;
   void              SetContext(const SContext &ctx) { m_ctx=ctx; }
   bool              Dispatch(const int id, const long &lparam, const double &dparam, const string &sparam)
     {
      const ENUM_TIMEFRAMES tf = m_ctx.tf;
      // 1) Panel zuerst (Row Buttons etc.)
      if(g_tp.OnChartEvent(id, lparam, dparam, sparam))
         return true;


      if(id == CHARTEVENT_OBJECT_DRAG)
        {
        }

      if(id == CHARTEVENT_OBJECT_ENDEDIT && (sparam == TRNB || sparam == POSNB))
        {
         // TM übernimmt ggf. Requests aus DB und published tm.pub.*
         g_TradeMgr.TM_ConsumeGUIRequestsFromDB(_Symbol, (ENUM_TIMEFRAMES)_Period);

         // GUI zeigt published Werte (und schreibt vt.draft.trnb/posnb)
         g_vgui.ApplyTradePosFromDBToEdits();
         // danach GUI: aus tm.pub.* lesen und anzeigen (deine GUI macht das)
        }

      if(id == CHARTEVENT_OBJECT_CLICK && sparam == SENDTRADEBTN)
        {
         // Draft aus aktuellen Linien/Buttons in DB schreiben (falls noch nicht vorhanden)
         g_vgui.FlushDraft(); // neue public Methode, siehe unten

         STMSendFromDraftResult r;
         if(!g_TradeMgr.TM_SendFromDraft(_Symbol, (ENUM_TIMEFRAMES)_Period, r))
           {
            Print("SEND failed: ", r.error);
            return true;
           }
         g_TradeMgr.RestoreTradePosLines(_Symbol, (ENUM_TIMEFRAMES)_Period);
         UI_ApplyZOrder();
         ChartRedraw(0);

         g_TradeMgr.TM_PublishTradePosToDB(_Symbol, (ENUM_TIMEFRAMES)_Period);
         g_vgui.ApplyTradePosFromDBToEdits();
         g_tp.RebuildRows();
         // NEU: Linien sofort zeichnen
         g_TradeMgr.RestoreTradePosLines(_Symbol, (ENUM_TIMEFRAMES)_Period);
         UI_ApplyZOrder();

         ChartRedraw(0);
         return true;
        }

      if(id == CHARTEVENT_OBJECT_CHANGE)
        {

        }

      // MouseUp-Fallback wird im MOUSE_MOVE Block gemacht (weil MouseState benötigt wird)
      return false;
     }
  };

static CChartEventRouter g_evt_router;
//+------------------------------------------------------------------+
#endif
//+------------------------------------------------------------------+
