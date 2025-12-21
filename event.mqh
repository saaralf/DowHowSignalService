//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#ifndef __EVENTHANDLER__
#define __EVENTHANDLER__


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // Identifikator des Ereignisses
                  const long &lparam,   // Parameter des Ereignisses des Typs long, X cordinates
                  const double &dparam, // Parameter des Ereignisses des Typs double, Y cordinates
                  const string &sparam) // Parameter des Ereignisses des Typs string, name of the object, state
  {

// Wenn Linien verschoben wurden: sofort in SQLite speichern (damit nach Neustart/TF-Wechsel alles wieder da ist)
   if(id == CHARTEVENT_OBJECT_CHANGE || id == CHARTEVENT_OBJECT_DRAG)
     {
      if(sparam == PR_HL || sparam == SL_HL)
         DB_SaveLinePrices();
     }

// Preise der Linien direkt als double holen
   Entry_Price = Get_Price_d(PR_HL);
   SL_Price = Get_Price_d(SL_HL);




   if(id == CHARTEVENT_MOUSE_MOVE)
     {
      CurrentAskPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      CurrentBidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);

      int MouseD_X = (int)lparam;
      int MouseD_Y = (int)dparam;

      int MouseState = (int)StringToInteger(sparam);

      int XD_R3 = (int)ObjectGetInteger(0, EntryButton, OBJPROP_XDISTANCE);
      int YD_R3 = (int)ObjectGetInteger(0, EntryButton, OBJPROP_YDISTANCE);
      int XS_R3 = (int)ObjectGetInteger(0, EntryButton, OBJPROP_XSIZE);
      int YS_R3 = (int)ObjectGetInteger(0, EntryButton, OBJPROP_YSIZE);

      int XD_R5 = (int)ObjectGetInteger(0, SLButton, OBJPROP_XDISTANCE);
      int YD_R5 = (int)ObjectGetInteger(0, SLButton, OBJPROP_YDISTANCE);
      int XS_R5 = (int)ObjectGetInteger(0, SLButton, OBJPROP_XSIZE);
      int YS_R5 = (int)ObjectGetInteger(0, SLButton, OBJPROP_YSIZE);

      if(prevMouseState == 0 && MouseState == 1)  // 1 = true: clicked left mouse btn
        {

         mlbDownX3 = MouseD_X;
         mlbDownY3 = MouseD_Y;
         mlbDownXD_R3 = XD_R3;
         mlbDownYD_R3 = YD_R3;

         mlbDownX5 = MouseD_X;
         mlbDownY5 = MouseD_Y;
         mlbDownXD_R5 = XD_R5;
         mlbDownYD_R5 = YD_R5;

         if(MouseD_X >= XD_R3 && MouseD_X <= XD_R3 + XS_R3 &&
            MouseD_Y >= YD_R3 && MouseD_Y <= YD_R3 + YS_R3)
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
            ui_direction_is_long = 0;
            update_Text(EntryButton, "Sell Stop @ " + Get_Price_s(PR_HL) + " | Lot: " + DoubleToString(lots, 2));
            update_Text(SLButton, "SL: " + DoubleToString(((Get_Price_d(SL_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));
           }
         else
           {
            ui_direction_is_long = 1;
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

         ChartXYToTimePrice(0, XD_R3, YD_R3 + YS_R3, window, dt_PRC, price_PRC);

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
            DB_SaveLinePrices();
        }
      prevMouseState = MouseState;
     }
if(id == CHARTEVENT_CHART_CHANGE)
{
   UI_ReanchorRightPanel();
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
//| Klick Button Cancel Long Order                                                             |
//+------------------------------------------------------------------+
   if(ObjectGetInteger(0, "ButtonCancelOrder", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_STATE, 0);
  
      if(is_long_trade)
        {
         // 1) Discord nur EINMAL senden
         DB_PositionRow r;
         r.symbol    = _Symbol;
         r.tf        = TF_ToString((ENUM_TIMEFRAMES)_Period);
         r.direction = "LONG";
         r.trade_no  = active_long_trade_no;
         r.pos_no    = 0;

         string message = FormatCancelTradeMessage(r);
         bool ret = SendDiscordMessage(message);

         // 2) DB: Trade sauber "geschlossen" markieren, damit OnInit ihn NICHT wieder aktiviert
         DB_UpdatePositionStatus(_Symbol, (ENUM_TIMEFRAMES)_Period, "LONG", active_long_trade_no, 0, "CLOSED_CANCEL", 0);

         // 3) Broker-Pending löschen (falls vorhanden)
         DeleteBuyStopOrderForCurrentChart();

         // 4) Runtime-State komplett zurücksetzen
         is_long_trade       = false;
         HitEntryPriceLong   = false;

         // WICHTIG: aktive Tradenummer löschen, sonst "reanimiert" OnInit das wieder
         active_long_trade_no = 0;
         DB_SetMetaInt(DB_Key("active_long_trade_no"), active_long_trade_no);

         // UI cleanup
         ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_COLOR, clrNONE);
         ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_BGCOLOR, clrNONE);
         DeleteLinesandLabelsLong();

         // optional: Panels refresh
         UI_UpdateNextTradePosUI();
         UI_UpdateOverviewPanel();
         UI_RebuildSLHitButtons();
         
        }
      return;
     }

//+------------------------------------------------------------------+
//|  Klick Button Cancel Short Order                                                                 |
//+------------------------------------------------------------------+
   if(ObjectGetInteger(0, "ButtonCancelOrderSell", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_STATE, 0);
      Print("Klicked ButtonCancelOrderSell");

      if(is_sell_trade)
        {
         DB_PositionRow r;
         r.symbol    = _Symbol;
         r.tf        = TF_ToString((ENUM_TIMEFRAMES)_Period);
         r.direction = "SHORT";
         r.trade_no  = active_short_trade_no;
         r.pos_no    = 0;

         string message = FormatCancelTradeMessage(r);
         bool ret = SendDiscordMessage(message);

         DB_UpdatePositionStatus(_Symbol, (ENUM_TIMEFRAMES)_Period, "SHORT", active_short_trade_no, 0, "CLOSED_CANCEL", 0);

         DeleteSellStopOrderForCurrentChart();

         is_sell_trade         = false;
         is_sell_trade_pending = false;
         HitEntryPriceShort    = false;

         active_short_trade_no = 0;
         DB_SetMetaInt(DB_Key("active_short_trade_no"), active_short_trade_no);

         ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_COLOR, clrNONE);
         ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_BGCOLOR, clrNONE);
         DeleteLinesandLabelsShort();

         UI_UpdateNextTradePosUI();
         UI_UpdateOverviewPanel();
           UI_RebuildSLHitButtons();
        }

      return;
     }



// ... nach Cancel-Buttons:
   UI_CheckSLHitButtonClicks();
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
      UI_UpdateOverviewPanel();
      UI_UpdateAllLineTags();
     }

  } // Ende ChartEvent
  
  
  
// Klick: irgendein SLHit Button?
void UI_CheckSLHitButtonClicks()
  {
   int total = ObjectsTotal(0, -1, -1);
   for(int i = 0; i < total; i++)
     {
      string name = ObjectName(0, i);
      if(StringFind(name, SLHIT_PREFIX, 0) != 0)
         continue;

      if(ObjectGetInteger(0, name, OBJPROP_STATE) != 0)
        {
         ObjectSetInteger(0, name, OBJPROP_STATE, 0);

         string dir;
         int trade_no, pos_no;
         if(!UI_ParseSLHitName(name, dir, trade_no, pos_no))
            return;

         // --- DB: Position schließen (SL hit)
         DB_PositionRow row;
         bool ok = DB_GetPosition(_Symbol, _Period, dir, trade_no, pos_no, row); // falls du die Funktion noch nicht hast, sag Bescheid – dann bauen wir sie sauber.
         if(ok)
           {
            row.status = "CLOSED_SL";
            row.is_pending = 0;
            row.updated_at = TimeCurrent();
            DB_UpsertPosition(row);
           }

         // --- Linien löschen (deine Namenslogik: TP_Long + suf, etc.)
         string suf = "_" + IntegerToString(pos_no);

         if(dir == "LONG")
           {

            ObjectDelete(0, SL_Long + suf);
            ObjectDelete(0, Entry_Long + suf);
           }
         else
           {

            ObjectDelete(0, SL_Short + suf);
            ObjectDelete(0, Entry_Short + suf);
           }

         // Optional: Discord Info
         SendDiscordMessage("SL erreicht: " + dir + " T" + IntegerToString(trade_no) + " P" + IntegerToString(pos_no));

         // UI neu aufbauen
         UI_RebuildSLHitButtons();
         return;
        }
     }
  }

  
#endif // __EVENTHANDLER__
