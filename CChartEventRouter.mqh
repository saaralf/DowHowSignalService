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
#include "CSendButtonController.mqh"
#include "CVirtualTradeGUI.mqh"
#include "CTradeManager.mqh"
#include "CDBService.mqh"

// Globals (müssen in *einer* .mq5 oder zentraler .mqh auch wirklich existieren!)
extern CTradesPanel          g_tp;
extern CSendButtonController g_send_ctl;
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
      if(g_tp.OnChartEvent(m_ctx.chart_id, lparam, dparam, sparam))
         return true;

      // 2) Controller Chain
      if(id == CHARTEVENT_OBJECT_CLICK)
        {
         if(g_send_ctl.OnObjectClick(sparam))
            return true;

        }

      if(id == CHARTEVENT_OBJECT_DRAG)
        {




        }
      if(id == CHARTEVENT_OBJECT_ENDEDIT && (sparam == TRNB || sparam == POSNB))
        {
         // TM übernimmt ggf. Requests aus DB und published tm.pub.*
         g_TradeMgr.TM_ConsumeGUIRequestsFromDB(m_ctx.symbol, m_ctx.tf);

         // GUI zeigt published Werte (und schreibt vt.draft.trnb/posnb)
         g_vgui.ApplyTradePosFromDBToEdits();
         // danach GUI: aus tm.pub.* lesen und anzeigen (deine GUI macht das)
        }

      if(id == CHARTEVENT_OBJECT_CLICK && sparam == SENDTRADEBTN)
        {
         ENUM_TIMEFRAMES tf = m_ctx.tf;

         string dir="LONG", entry="0", sl="0", sabE="", sabS="", trnb_s="1", posnb_s="1";
         g_DB.GetMetaText(g_DB.KeyFor(m_ctx.symbol, tf, "vt.draft.direction"), dir, "LONG");
         g_DB.GetMetaText(g_DB.KeyFor(m_ctx.symbol, tf, "vt.draft.entry_price"), entry, "0");
         g_DB.GetMetaText(g_DB.KeyFor(m_ctx.symbol, tf, "vt.draft.sl_price"), sl, "0");
         g_DB.GetMetaText(g_DB.KeyFor(m_ctx.symbol, tf, "vt.draft.sabio_entry_text"), sabE, "");
         g_DB.GetMetaText(g_DB.KeyFor(m_ctx.symbol, tf, "vt.draft.sabio_sl_text"), sabS, "");
         g_DB.GetMetaText(g_DB.KeyFor(m_ctx.symbol, tf, "vt.draft.trnb"), trnb_s, "1");
         g_DB.GetMetaText(g_DB.KeyFor(m_ctx.symbol, tf, "vt.draft.posnb"), posnb_s, "1");
         StringToUpper(dir);

         const int trade_no = (int)StringToInteger(trnb_s);
         const int pos_no   = (int)StringToInteger(posnb_s);

         double entry_d = StringToDouble(entry);
         double sl_d    = StringToDouble(sl);

         string err="";
         if(!g_TradeMgr.SendDraftWithUserPos(m_ctx.symbol, tf, dir, trade_no, pos_no, entry_d, sl_d, sabE, sabS, err))
            CLogger::Add(LOG_LEVEL_WARNING, "SEND failed: " + err);

         g_tp.RequestRebuild();
         UI_ProcessRedraw();
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
