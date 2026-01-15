//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#ifndef __DISCORD_SEND__
#define __DISCORD_SEND__

#include "trades_panel.mqh"
#include "ui_state.mqh"



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DiscordSend()
  {
   static bool busy=false;
   if(busy)
      return;
   busy=true;

   string mb_msg="";
   bool show_mb=false;

// alles in einen Block, Fehler -> break
   do
     {
      // --- TradeNr aus Eingabefeld
      string tradenummer_string="";
      ObjectGetString(0, TRNB, OBJPROP_TEXT, 0, tradenummer_string);
      int trade_no_input = (int)StringToInteger(tradenummer_string);

    bool isLong = g_ui_state.is_long;
      string direction = (isLong ? "LONG" : "SHORT");

      // --- Basis-Validierung (Preis vs. Markt)
      if(isLong)
        {
         if(Entry_Price <= CurrentAskPrice)
           {
            mb_msg="Entry ist tiefer als aktueller Ask.";
            show_mb=true;
            break;
           }
        }
      else
        {
         if(Entry_Price >= CurrentBidPrice)
           {
            mb_msg="Entry ist höher als aktueller Bid.";
            show_mb=true;
            break;
           }
        }

      // Sabio Strings
      string sabE = (Sabioedit ? ObjectGetString(0, SabioEntry, OBJPROP_TEXT, 0) : "kein Sabio");
      string sabS = (Sabioedit ? ObjectGetString(0, SabioSL,    OBJPROP_TEXT, 0) : "kein Sabio");

      int active_before = (isLong ? g_ui_state.active_trade_no_long  : g_ui_state.active_trade_no_short);

      // Call TradeManager (dein neuer Flow)
      int eff_trade_no=trade_no_input, pos_no=0;
      bool starting_new_trade=false;
      DB_PositionRow row;
      string err="";

      ESendDraftResult r;
      if(isLong)
         r = g_TradeMgr.SendSignalDraft(_Symbol,(ENUM_TIMEFRAMES)_Period,"LONG",
                                        trade_no_input,Entry_Price,SL_Price,
                                        sabE,sabS,
                                        last_trade_nummer,
                                         g_ui_state.active_trade_no_long,
                                        is_long_trade,
                                        eff_trade_no,pos_no,starting_new_trade,
                                        row,err);
      else
         r = g_TradeMgr.SendSignalDraft(_Symbol,(ENUM_TIMEFRAMES)_Period,"SHORT",
                                        trade_no_input,Entry_Price,SL_Price,
                                        sabE,sabS,
                                        last_trade_nummer,
                                         g_ui_state.active_trade_no_short,
                                        is_sell_trade,
                                        eff_trade_no,pos_no,starting_new_trade,
                                        row,err);

      // UI-Korrektur TradeNo
      if(eff_trade_no != trade_no_input)
         update_Text(TRNB, IntegerToString(eff_trade_no));

      if(r == SEND_ERR_MAXPOS)
        {
         mb_msg="Maximale gleichzeitige Positionen erreicht (max 4).";
         show_mb=true;
         break;
        }
      if(r == SEND_ERR_DB)
        {
         mb_msg="DB Fehler: Position konnte nicht gespeichert werden.";
         show_mb=true;
         break;
        }
      if(r == SEND_ERR_DISCORD)
        {
         CLogger::Add(LOG_LEVEL_INFO, "Discord Fehler (Draft zurückgerollt): " + err);
         break;
        }
      if(r != SEND_OK)
        {
         CLogger::Add(LOG_LEVEL_WARNING, "SendDraft Fehler: " + err);
         break;
        }

      // Screenshot optional
      //  g_Discord.SendScreenShot(_Symbol, _Period, getChartWidthInPixels(), getChartHeightInPixels());

      // UI Updates wie vorher
      if(isLong)
        {
         showActive_long(true);
         showCancel_long(true);
         update_Text(TP_BTN_ACTIVE_LONG, "ACTIVE POSITION");

        }
      else
        {
         showActive_short(true);
         showCancel_short(true);
         update_Text(TP_BTN_ACTIVE_SHORT, "ACTIVE POSITION");

        }
      g_tp.RebuildRows();
      g_TradeMgr.RestoreTradePosLines(_Symbol, (ENUM_TIMEFRAMES)_Period);
      ChartRedraw(0);
      UI_UpdateNextTradePosUI();

     }
   while(false);

   if(show_mb && mb_msg!="")
      MessageBox(mb_msg, NULL, MB_OK);

   busy=false;
  }

#endif // __DISCORD_SEND__
