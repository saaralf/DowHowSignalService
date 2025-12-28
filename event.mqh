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


if(UI_TradesPanel_OnChartEvent(id, lparam, dparam, sparam))
   return;

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
     
      UI_UpdateAllLineTags();
     }

  } // Ende ChartEvent



  
// Klick: irgendein SLHit Button? (pro Position: Cancel / SL erreicht)

// Parse: erkennt diese Namen
//   ButtonSLHit_LONG_2_1        -> action="SL"
//   CancelButtonSLHit_LONG_2_1  -> action="CANCEL"
//   SLButtonSLHit_LONG_2_1      -> action="SL"
//   StoppedButtonSLHit_LONG_2_1 -> action="SL" (Fallback)
bool UI_ParseSLHitActionName(const string obj_name,
                             string &action,
                             string &direction,
                             int &trade_no,
                             int &pos_no)
{
   action = "";
   direction = "";
   trade_no = 0;
   pos_no = 0;

   string base = obj_name;

   // Prefixe vor dem eigentlichen ButtonSLHit_... (UI_RebuildSLHitButtons baut daraus z.B. "Cancel"+btn)
   const string P_CANCEL  = "Cancel";
   const string P_SL      = "SL";
   const string P_STOPPED = "Stopped";

   if(StringFind(obj_name, P_CANCEL + SLHIT_PREFIX, 0) == 0)
   {
      action = "CANCEL";
      base   = StringSubstr(obj_name, StringLen(P_CANCEL)); // -> ButtonSLHit_...
   }
   else if(StringFind(obj_name, P_SL + SLHIT_PREFIX, 0) == 0)
   {
      action = "SL";
      base   = StringSubstr(obj_name, StringLen(P_SL)); // -> ButtonSLHit_...
   }
   else if(StringFind(obj_name, P_STOPPED + SLHIT_PREFIX, 0) == 0)
   {
      action = "SL";
      base   = StringSubstr(obj_name, StringLen(P_STOPPED)); // -> ButtonSLHit_...
   }
   else if(StringFind(obj_name, SLHIT_PREFIX, 0) == 0)
   {
      // Backward kompatibel: alter "ein Button pro Zeile" Modus
      action = "SL";
      base   = obj_name;
   }
   else
   {
      return false;
   }

   return UI_ParseSLHitName(base, direction, trade_no, pos_no);
}

// Prüft, ob innerhalb einer Trade-Nummer (und Richtung) noch irgendeine pending Position existiert.
// (falls nein -> Trade ist "zu" und darf nicht mehr als aktiv gelten)
bool UI_TradeHasAnyPendingPosition(const string direction, const int trade_no)
{
   DB_PositionRow rows[];
   int n = DB_LoadPositions(_Symbol, _Period, rows);

   for(int i = 0; i < n; i++)
   {
      if(rows[i].direction != direction)   continue;
      if(rows[i].trade_no   != trade_no)   continue;

      // Nur echte/gesendete Positionen berücksichtigen
      if(rows[i].was_sent   != 1)          continue;

      // Pending/offen?
      if(rows[i].is_pending != 1)          continue;

      // Alles was mit "CLOSED" beginnt, ist zu
      if(StringFind(rows[i].status, "CLOSED", 0) == 0) continue;

      return true;
   }
   return false;
}

void UI_CloseOnePositionAndNotify(const string action,
                                  const string direction,
                                  const int trade_no,
                                  const int pos_no)
{
   // 1) Discord
   DB_PositionRow r;
   r.symbol    = _Symbol;
   r.tf        = TF_ToString((ENUM_TIMEFRAMES)_Period);
   r.direction = direction;
   r.trade_no  = trade_no;
   r.pos_no    = pos_no;

   string message = "";
   string new_status = "CLOSED";

   if(action == "CANCEL")
   {
      message    = FormatCancelTradeMessage(r);
      new_status = "CLOSED_CANCEL";
   }
   else // "SL"
   {
      message    = FormatSLMessage(r);
      new_status = "CLOSED_SL";
   }

   SendDiscordMessage(message);

   // 2) DB
   DB_UpdatePositionStatus(_Symbol, (ENUM_TIMEFRAMES)_Period,
                          direction, trade_no, pos_no,
                          new_status, 0);

   // 3) Linien/Labels dieser Position entfernen (falls vorhanden)
   string suf = "_" + IntegerToString(pos_no);

   if(direction == "LONG")
   {
      ObjectDelete(0, Entry_Long + suf);
      ObjectDelete(0, SL_Long + suf);
      ObjectDelete(0, LabelEntryLong + suf);
      ObjectDelete(0, LabelSLLong + suf);
   }
   else
   {
      ObjectDelete(0, Entry_Short + suf);
      ObjectDelete(0, SL_Short + suf);
      ObjectDelete(0, LabelEntryShort + suf);
      ObjectDelete(0, LabelSLShort + suf);
   }

   UI_UpdateAllLineTags();

   // 4) Falls das die letzte pending Position des Trades war -> Runtime + Meta zurücksetzen
   if(!UI_TradeHasAnyPendingPosition(direction, trade_no))
   {
      if(direction == "LONG")
      {
         if(active_long_trade_no == trade_no)
         {
            active_long_trade_no = 0;
            DB_SetMetaInt(DB_Key("active_long_trade_no"), 0);
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
            DB_SetMetaInt(DB_Key("active_short_trade_no"), 0);
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
  
   UI_RebuildSLHitButtons();
   ChartRedraw(0);
}

void UI_CheckSLHitButtonClicks()
{
   int total = ObjectsTotal(0, -1, -1);

   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);

      string action, direction;
      int trade_no, pos_no;

      if(!UI_ParseSLHitActionName(name, action, direction, trade_no, pos_no))
         continue;

      // Klick?
      if(ObjectGetInteger(0, name, OBJPROP_STATE) == 0)
         continue;

      // Reset des Button-States (verhindert Doppelevents)
      ObjectSetInteger(0, name, OBJPROP_STATE, 0);

      Print("[SLHIT] click action=", action,
            " dir=", direction,
            " trade=", trade_no,
            " pos=", pos_no);

      UI_CloseOnePositionAndNotify(action, direction, trade_no, pos_no);

      // Safety: nach einer Aktion stoppen, weil Objekte neu aufgebaut werden
      return;
   }
}


#endif // __EVENTHANDLER__
