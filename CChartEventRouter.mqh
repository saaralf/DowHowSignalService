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
      // 1) Panel zuerst
      if(g_tp.OnChartEvent(id, lparam, dparam, sparam))
         return true;

      // 2) Nur noch Dispatch, keine Business-Logik mehr im Router
      if(id == CHARTEVENT_OBJECT_ENDEDIT)
        {
         if(sparam == TRNB || sparam == POSNB)
           {
            g_TradeMgr.TM_HandleTradePosEditCommit(_Symbol, (ENUM_TIMEFRAMES)_Period);
            return true;
           }
        }

      if(id == CHARTEVENT_OBJECT_CLICK)
        {
         if(sparam == SENDTRADEBTN)
           {
            STMSendFromDraftResult r;
            if(!g_TradeMgr.TM_HandleSendTradeClick(_Symbol, (ENUM_TIMEFRAMES)_Period, r))
               Print("SEND failed: ", r.error);
            return true;
           }
        }
      return false;
     }
  };

static CChartEventRouter g_evt_router;
//+------------------------------------------------------------------+
#endif
//+------------------------------------------------------------------+
