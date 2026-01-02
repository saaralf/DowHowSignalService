//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#ifndef __EVENTHANDLER__
#define __EVENTHANDLER__


#include "discord_client.mqh"

// ------------------------------------------------------------------
// TradePos-Drag Tracking (damit Discord nur 1x pro Drag gesendet wird)
// Hinweis: Bei manchen MT5-Objekten kommt CHARTEVENT_OBJECT_CHANGE nicht
// zuverlässig. Darum finalisieren wir zusätzlich beim MouseUp.
// ------------------------------------------------------------------
static bool   g_tp_drag_active   = false;
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
   ChartRedraw(0);

// DB: persistieren (erst nach dem old/new Vergleich)
   g_TradeMgr.SaveLinePrices();

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


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // Identifikator des Ereignisses
                  const long &lparam,   // Parameter des Ereignisses des Typs long, X cordinates
                  const double &dparam, // Parameter des Ereignisses des Typs double, Y cordinates
                  const string &sparam) // Parameter des Ereignisses des Typs string, name of the object, state
  {
   CurrentAskPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   CurrentBidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);



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
            ChartRedraw(0);
            last_redraw = now;
           }

         return; // TradePos-Drag fertig behandelt
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

      // Basislinien (PR_HL/SL_HL) und andere Trade-Linien: nur speichern/Tag
      if(sparam == PR_HL || sparam == SL_HL || UI_IsTradePosLine(sparam))
        {
         if(UI_IsTradePosLine(sparam))
            UI_CreateOrUpdateLineTag(sparam);

         g_TradeMgr.SaveLinePrices();
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

      int MouseState = (int)StringToInteger(sparam);

      // Fallback-Finalize: Wenn MT5 kein CHARTEVENT_OBJECT_CHANGE feuert,
      // senden wir Discord + speichern beim MouseUp (state==0).
      if(MouseState == 0 && g_tp_drag_active)
         TP_FinalizeLineMove();

      int XD_EntryButton = (int)ObjectGetInteger(0, EntryButton, OBJPROP_XDISTANCE);
      int YD_EntryButton = (int)ObjectGetInteger(0, EntryButton, OBJPROP_YDISTANCE);
      int XS_EntryButton = (int)ObjectGetInteger(0, EntryButton, OBJPROP_XSIZE);
      int YS_EntryButton = (int)ObjectGetInteger(0, EntryButton, OBJPROP_YSIZE);

      int XD_R5 = (int)ObjectGetInteger(0, SLButton, OBJPROP_XDISTANCE);
      int YD_R5 = (int)ObjectGetInteger(0, SLButton, OBJPROP_YDISTANCE);
      int XS_R5 = (int)ObjectGetInteger(0, SLButton, OBJPROP_XSIZE);
      int YS_R5 = (int)ObjectGetInteger(0, SLButton, OBJPROP_YSIZE);

      if(prevMouseState == 0 && MouseState == 1)  // 1 = true: clicked left mouse btn
        {

         mlbDownX3 = MouseD_X;
         mlbDownY3 = MouseD_Y;
         mlbDownXD_R3 = XD_EntryButton;
         mlbDownYD_R3 = YD_EntryButton;

         mlbDownX5 = MouseD_X;
         mlbDownY5 = MouseD_Y;
         mlbDownXD_R5 = XD_R5;
         mlbDownYD_R5 = YD_R5;

         if(MouseD_X >= XD_EntryButton && MouseD_X <= XD_EntryButton + XS_EntryButton &&
            MouseD_Y >= YD_EntryButton && MouseD_Y <= YD_EntryButton + YS_EntryButton)
           {
            movingState_R3 = true;
           }

         if(MouseD_X >= XD_R5 && MouseD_X <= XD_R5 + XS_R5 &&
            MouseD_Y >= YD_R5 && MouseD_Y <= YD_R5 + YS_R5)
           {
            movingState_R5 = true;
           }
        }

      if(movingState_R5)
        {
         ChartSetInteger(0, CHART_MOUSE_SCROLL, false);
         //move SLButton und SabioSL
         ObjectSetInteger(0, SLButton, OBJPROP_YDISTANCE, mlbDownYD_R5 + MouseD_Y - mlbDownY5);
         ObjectSetInteger(0, SabioSL, OBJPROP_YDISTANCE, mlbDownYD_R5 + MouseD_Y + 30 - mlbDownY5);

         datetime dt_SL = 0;
         double price_SL = 0;
         int window = 0;

         ChartXYToTimePrice(0, XD_R5, YD_R5 + YS_R5, window, dt_SL, price_SL);
         //Move SL HL LInie
         ObjectSetInteger(0, SL_HL, OBJPROP_TIME, dt_SL);
         ObjectSetDouble(0, SL_HL, OBJPROP_PRICE, price_SL);

         datetime dt_TP = 0;
         double price_TP = 0;

         double lots = calcLots(Entry_Price - SL_Price);
         lots = NormalizeDouble(lots, 2);
         //Schreibe aktuelle Zahlen in den Button
         update_Text(EntryButton, "Buy Stop @ " + Get_Price_s(PR_HL) + " | Lot: " + DoubleToString(lots, 2));
         update_Text(SLButton, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));
         // auch in den SabioEdits
         if(SabioPrices)
           {
            update_Text(SabioEntry, "SABIO Entry: " + Get_Price_s(PR_HL));
            update_Text(SabioSL, "SABIO SL: " + Get_Price_s(SL_HL));
           }

         else
           {
            update_Text(SabioEntry, "SABIO ENTRY: ");
            update_Text(SabioSL, "SABIO SL: ");
           }

         //prüfe ob wir eine Richtungswechsel haben. SL geht über Entry oder zurück
         //Also wir wollen dann einen Short oder LONG Trade machen
         if((Get_Price_d(SL_HL)) > (Get_Price_d(PR_HL)))
           {
            double lots = calcLots(SL_Price - Entry_Price);
            lots = NormalizeDouble(lots, 2);
            ui_direction_is_long = false;
            update_Text(EntryButton, "Sell Stop @ " + Get_Price_s(PR_HL) + " | Lot: " + DoubleToString(lots, 2));
            update_Text(SLButton, "SL: " + DoubleToString(((Get_Price_d(SL_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));
           }
         else
           {
            ui_direction_is_long = true;
           }

         ChartRedraw(0);
        }

      if(movingState_R3)
        {
         ChartSetInteger(0, CHART_MOUSE_SCROLL, false);
         ObjectSetInteger(0, EntryButton, OBJPROP_YDISTANCE, mlbDownYD_R3 + MouseD_Y - mlbDownY3);

         ObjectSetInteger(0, SLButton, OBJPROP_YDISTANCE, mlbDownYD_R5 + MouseD_Y - mlbDownY5);
         ObjectSetInteger(0, SENDTRADEBTN, OBJPROP_YDISTANCE, mlbDownYD_R3 + MouseD_Y - mlbDownY3);
         ObjectSetInteger(0, TRNB, OBJPROP_YDISTANCE, (mlbDownYD_R3 + MouseD_Y - mlbDownY3) + 30);
         ObjectSetInteger(0, POSNB, OBJPROP_YDISTANCE, (mlbDownYD_R3 + MouseD_Y - mlbDownY3) + 30);

         ObjectSetInteger(0, SabioEntry, OBJPROP_YDISTANCE, mlbDownYD_R3 + MouseD_Y + 30 - mlbDownY5);
         ObjectSetInteger(0, SabioSL, OBJPROP_YDISTANCE, mlbDownYD_R5 + MouseD_Y + 30 - mlbDownY5);

         datetime dt_PRC = 0, dt_SL1 = 0, dt_TP1 = 0;
         double price_PRC = 0, price_SL1 = 0, price_TP1 = 0;
         int window = 0;

         ChartXYToTimePrice(0, XD_EntryButton, YD_EntryButton + YS_EntryButton, window, dt_PRC, price_PRC);

         ChartXYToTimePrice(0, XD_R5, YD_R5 + YS_R5, window, dt_SL1, price_SL1);

         ObjectSetInteger(0, PR_HL, OBJPROP_TIME, dt_PRC);
         ObjectSetDouble(0, PR_HL, OBJPROP_PRICE, price_PRC);

         ObjectSetInteger(0, SL_HL, OBJPROP_TIME, dt_SL1);
         ObjectSetDouble(0, SL_HL, OBJPROP_PRICE, price_SL1);

         if(SabioPrices)
           {
            update_Text(SabioEntry, "SABIO Entry: " + Get_Price_s(PR_HL));

            update_Text(SabioSL, "SABIO SL: " + Get_Price_s(SL_HL));
           }

         else
           {
            update_Text(SabioEntry, "SABIO ENTRY: ");

            update_Text(SabioSL, "SABIO SL: ");
           }

         if((Get_Price_d(SL_HL)) > (Get_Price_d(PR_HL)))
           {
            double lots = calcLots(SL_Price - Entry_Price);
            lots = NormalizeDouble(lots, 2);

            update_Text(EntryButton, "Sell Stop @ " + Get_Price_s(PR_HL) + " | Lot: " + DoubleToString(lots, 2));
            update_Text(SLButton, "SL: " + DoubleToString(((Get_Price_d(SL_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

            ui_direction_is_long = 0;
           }
         else
           {
            double lots = calcLots(Entry_Price - SL_Price);

            update_Text(EntryButton, "Buy Stop @ " + Get_Price_s(PR_HL) + " | Lot: " + DoubleToString(lots, 2));
            update_Text(SLButton, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

            ui_direction_is_long = 1;
           }

         ChartRedraw(0);
        }

      if(MouseState == 0)
        {
         bool wasMoving = (movingState_R3 || movingState_R5);
         movingState_R3 = false;
         movingState_R5 = false;
         ChartSetInteger(0, CHART_MOUSE_SCROLL, true);
         if(wasMoving)
            g_TradeMgr.SaveLinePrices();
        }
      prevMouseState = MouseState;
     }
   if(id == CHARTEVENT_CHART_CHANGE)
     {
      return;
     }

// Klick Button Send only
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(ObjectGetInteger(0, SENDTRADEBTN, OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, SENDTRADEBTN, OBJPROP_STATE, 0);

      if(Sabioedit == true)
        {
         int result = MessageBox("Sabio Preise angepasst?", NULL, MB_YESNO);
         //            MessageBoxSound = PlaySound(C:\Program Files\IC Markets (SC) Demo 51680033\Sounds\Alert2.wav);
         if(result == IDYES)
           {
            DiscordSend();
           }
        }
      else
        {
         DiscordSend();
        }
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

  } // Ende ChartEvent




// Prüft, ob innerhalb einer Trade-Nummer (und Richtung) noch irgendeine pending Position existiert.
// (falls nein -> Trade ist "zu" und darf nicht mehr als aktiv gelten)
bool UI_TradeHasAnyPendingPosition(const string direction, const int trade_no)
  {
   DB_PositionRow rows[];
   int n = g_DB.LoadPositions(_Symbol, _Period, rows);

   for(int i = 0; i < n; i++)
     {
      if(rows[i].direction != direction)
         continue;
      if(rows[i].trade_no   != trade_no)
         continue;

      // Nur echte/gesendete Positionen berücksichtigen
      if(rows[i].was_sent   != 1)
         continue;

      // Pending/offen?
      if(rows[i].is_pending != 1)
         continue;

      // Alles was mit "CLOSED" beginnt, ist zu
      if(StringFind(rows[i].status, "CLOSED", 0) == 0)
         continue;

      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UI_CloseOnePositionAndNotify(const string action,
                                  const string direction,
                                  const int trade_no,
                                  const int pos_no)
  {

   Cache_Ensure();  // lädt g_cache_rows einmalig (falls noch nicht ready)

   DB_PositionRow r;
   int idx = Cache_FindIdx(direction, trade_no, pos_no);

   if(idx >= 0)
     {
      // vollständige Row inkl. entry/sl/sabio/status/...
      r = g_cache_rows[idx];
     }
   else
     {
      // Fallback (sollte selten passieren, ist aber robust)
      r.symbol    = _Symbol;
      r.tf        = TF_ToString((ENUM_TIMEFRAMES)_Period);
      r.direction = direction;
      r.trade_no  = trade_no;
      r.pos_no    = pos_no;
     }


   string message = "";
   string new_status = "CLOSED";

   if(action == "CANCEL")
     {
      message    = g_Discord.FormatCancelTradeMessage(r);
      new_status = "CLOSED_CANCEL";
     }
   else // "SL"
     {
      message    = g_Discord.FormatSLMessage(r);
      new_status = "CLOSED_SL";
     }

   g_Discord.SendMessage(_Symbol,message);

// 2) DB
   g_DB.UpdatePositionStatus(_Symbol, (ENUM_TIMEFRAMES)_Period,
                           direction, trade_no, pos_no,
                           new_status, 0);
// Cache synchron halten, sonst bleibt die Position im Cache "offen"
   if(!Cache_UpdateStatusLocal(direction, trade_no, pos_no, new_status, 0))
     {
      // wenn aus irgendeinem Grund nicht im Cache: minimal einfügen
      r.status     = new_status;
      r.is_pending = 0;
      r.updated_at = TimeCurrent();
      Cache_UpsertLocal(r);
     }
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

// 3) Linien + Tags dieser Position entfernen (robust, einheitlich)
   UI_DeleteTradePosLines(trade_no, pos_no);

// zusätzlich: falls Altlasten/Orphans existieren, räumt UpdateAllLineTags sauber auf
   UI_UpdateAllLineTags();

// 4) Falls das die letzte pending Position des Trades war -> Runtime + Meta zurücksetzen
   if(!UI_TradeHasAnyPendingPosition(direction, trade_no))
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
            ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_COLOR, clrNONE);
            ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_BGCOLOR, clrNONE);
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
            ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_COLOR, clrNONE);
            ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_BGCOLOR, clrNONE);
           }
        }
     }

// 5) UI Refresh
   UI_UpdateNextTradePosUI();

   ChartRedraw(0);
  }



#endif // __EVENTHANDLER__
