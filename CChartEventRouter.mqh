#ifndef __CCHART_EVENT_ROUTER_MQH__
#define __CCHART_EVENT_ROUTER_MQH__

#include "ui_names.mqh"
#include "trades_panel.mqh"
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
   bool              Dispatch(const int id, const long &lparam, const double &dparam, const string &sparam)
     {
      // 1) Panel zuerst (Row Buttons etc.)
      if(g_tp.OnChartEvent(id, lparam, dparam, sparam))
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
         g_TradeMgr.TM_ConsumeGUIRequestsFromDB(_Symbol, PERIOD_CURRENT);

         // GUI zeigt published Werte (und schreibt vt.draft.trnb/posnb)
         g_vgui.ApplyTradePosFromDBToEdits();
         g_TradeMgr.TM_ConsumeGUIRequestsFromDB(_Symbol, PERIOD_CURRENT);
         // danach GUI: aus tm.pub.* lesen und anzeigen (deine GUI macht das)
        }

      if(id == CHARTEVENT_OBJECT_CLICK && sparam == SENDTRADEBTN)
        {
         const string k_dir   = g_DB.KeyFor(_Symbol, PERIOD_CURRENT, "vt.draft.direction");
         const string k_entry = g_DB.KeyFor(_Symbol, PERIOD_CURRENT, "vt.draft.entry_price");
         const string k_sl    = g_DB.KeyFor(_Symbol, PERIOD_CURRENT, "vt.draft.sl_price");
         const string k_sabE  = g_DB.KeyFor(_Symbol, PERIOD_CURRENT, "vt.draft.sabio_entry_text");
         const string k_sabS  = g_DB.KeyFor(_Symbol, PERIOD_CURRENT, "vt.draft.sabio_sl_text");

         string dir   = "LONG";
         g_DB.GetMetaText(k_dir,   dir,   "LONG");
         string entry = "0";
         g_DB.GetMetaText(k_entry, entry, "0");
         string sl    = "0";
         g_DB.GetMetaText(k_sl,    sl,    "0");
         string sabE  = "SABIO Entry: ";
         g_DB.GetMetaText(k_sabE,  sabE,  "SABIO Entry: ");
         string sabS  = "SABIO SL: ";
         g_DB.GetMetaText(k_sabS,  sabS,  "SABIO SL: ");

         int trnb  = g_DB.GetMetaInt(g_DB.KeyFor(_Symbol, PERIOD_CURRENT, "vt.draft.trnb"), 1);
         int posnb = g_DB.GetMetaInt(g_DB.KeyFor(_Symbol, PERIOD_CURRENT, "vt.draft.posnb"), 1);

         // TODO: hier würdest du "SendDraft" / "SendSignalDraft" aufrufen,
         // aktuell nur publish:
         g_TradeMgr.TM_PublishTradePosToDB(_Symbol, PERIOD_CURRENT);

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