//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string PosSuf(const int pos_no)
  {
   return "_" + IntegerToString(pos_no);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool StatusIsClosed(const string s)
  {
   return (StringFind(s, "CLOSED") == 0); // CLOSED / CLOSED_TP / CLOSED_SL
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool StatusIsActive(const string s)
  {
   return (s == "PENDING" || s == "OPEN");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeletePosLines(const string direction, const int pos_no)
  {
   string suf = PosSuf(pos_no);

   if(direction == "LONG")
     {

      ObjectDelete(0, SL_Long + suf);
      ObjectDelete(0, Entry_Long + suf);
     }
   else
      if(direction == "SHORT")
        {

         ObjectDelete(0, SL_Short + suf);
         ObjectDelete(0, Entry_Short + suf);
        }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ClearActiveTrend(const string direction)
  {
   if(direction == "LONG")
     {
      g_ui_state.active_trade_no_long = 0;
      is_long_trade = false;
      HitEntryPriceLong = false; // legacy-Flag, jetzt egal – aber sauber

      g_DB.SetMetaInt(g_DB.Key("g_ui_state.active_trade_no_long"), 0);

      if(ObjectFind(0, "TP_BTN_ACTIVE_LONG") != -1)
        {
         g_tp.ShowActiveLong(false); //Button Ausblenden
         g_tp.ShowCancelLong(false);
        }
     }
   else
      if(direction == "SHORT")
        {
         g_ui_state.active_trade_no_short = 0;
         is_sell_trade = false;
         HitEntryPriceShort = false;

         if(g_DB.SetMetaInt(g_DB.Key("g_ui_state.active_trade_no_short"), 0))
           {
            if(ObjectFind(0, "TP_BTN_ACTIVE_SHORT") != -1)
              {
               g_tp.ShowActiveLong(false);
               g_tp.ShowCancelShort(false);
              }
           }
        }
  }






//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void setzeTrade()
  {

// Die echte Traden Logig muss ich mir später ansehen...
   /*
    if(!SendOnlyButton)
       {
     if(g_ui_state.is_long)
          {
           double lots = g_TradeMgr.CalcLots(_Symbol,_Period,Entry_Price - SL_Price);
           bool buy_ok = (!ShowTPButton)
                         ? trade.BuyStop(lots, Entry_Price, _Symbol, SL_Price, 0.0, ORDER_TIME_GTC)
                         : trade.BuyStop(lots, Entry_Price, _Symbol, SL_Price, TP_Price, ORDER_TIME_GTC);

           if(buy_ok)
             {
              ulong order_ticket = trade.ResultOrder();
              SaveNewTrade("BUY", _Symbol, (long)order_ticket, TimeCurrent(), Entry_Price, SL_Price, TP_Price, "EA BuyStop created");
              order_created=true;
             }
           else
             {
              Print(__FUNCTION__,": BuyStop failed. Retcode=", trade.ResultRetcode());
              int result = MessageBox("BuyStop konnte NICHT platziert werden. TradeNummer bleibt unverändert.", NULL, MB_OK);

             }
          }
        else
          {
           double lots = g_TradeMgr.calcLots(_Symbol,_Period,SL_Price - Entry_Price);
           bool sell_ok = (!ShowTPButton)
                          ? trade.SellStop(lots, Entry_Price, _Symbol, SL_Price, 0.0, ORDER_TIME_GTC)
                          : trade.SellStop(lots, Entry_Price, _Symbol, SL_Price, TP_Price, ORDER_TIME_GTC);

           if(sell_ok)
             {
              ulong sell_ticket = trade.ResultOrder();
              SaveNewTrade("SELL", _Symbol, (long)sell_ticket, TimeCurrent(), Entry_Price, SL_Price, TP_Price, "EA SellStop created");
              order_created=true;
             }
           else
             {
              Print(__FUNCTION__,": SellStop failed. Retcode=", trade.ResultRetcode());
              int result = MessageBox("SellStop konnte NICHT platziert werden. TradeNummer bleibt unverändert.", NULL, MB_OK);

             }
          }
       }
       */
  }





//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TPSLReached()
  {

   bool any_opened=false;   // <-- NEU
   bool any_closed=false;
   Cache_Ensure();
   int n = Cache_Size();
   if(n <= 0)
      return;

// --- 1) Alle aktiven Positionen prüfen/aktualisieren
   for(int i = 0; i < n; i++)
     {
      DB_PositionRow p = g_cache_rows[i];

      if(p.was_sent != 1)
         continue;

      // nur aktuell aktive TradeNo pro Richtung prüfen
      if(p.direction == "LONG")
        {
         if(g_ui_state.active_trade_no_long <= 0 || p.trade_no != g_ui_state.active_trade_no_long)
            continue;
        }
      else
         if(p.direction == "SHORT")
           {
            if(g_ui_state.active_trade_no_short <= 0 || p.trade_no != g_ui_state.active_trade_no_short)
               continue;
           }
         else
           {
            continue;
           }

      // bereits geschlossen -> skip
      if(StatusIsClosed(p.status))
         continue;

      // ---- Entry-Hit -> PENDING -> OPEN
      if(p.status == "PENDING")
        {
         bool entry_hit = false;
         if(p.direction == "LONG")
            entry_hit = (CurrentAskPrice >= p.entry);
         else // SHORT
            entry_hit = (CurrentBidPrice <= p.entry);

         if(entry_hit)
           {
            string err_open;
            if(g_TradeMgr.MarkPositionOpen(_Symbol,(ENUM_TIMEFRAMES)_Period,p.direction,p.trade_no,p.pos_no,err_open))
              {
               // lokale Kopie updaten, damit dieselbe Tick-Iteration korrekt weiterläuft
               p.status     = "OPEN";
               p.is_pending = 0;
               any_opened   = true;           // Panel muss refreshen
              }
            else
              {
               Print("TPSLReached: MarkPositionOpen failed: ", err_open);
              }
           }

        }

      // ---- SL/TP nur wenn OPEN
      if(p.status != "OPEN")
         continue;

      // LONG Regeln
      if(p.direction == "LONG")
        {
         if(p.sl > 0.0 && (CurrentBidPrice <= p.sl))
           {
             g_TradeMgr.UI_CloseOnePositionAndNotify("HIT_SL","LONG",p.trade_no,p.pos_no);
            any_closed=true;
            Alert(_Symbol + " LONG Trade " + IntegerToString(p.trade_no) + " Pos" + IntegerToString(p.pos_no) + " stopped out");
            continue;
           }
        }

      // SHORT Regeln
      if(p.direction == "SHORT")
        {
         if(p.sl > 0.0 && (CurrentAskPrice >= p.sl))
           {
             g_TradeMgr.UI_CloseOnePositionAndNotify("HIT_SL","SHORT",p.trade_no,p.pos_no);
            any_closed=true;
            Alert(_Symbol + _Period +" SHORT: Trade " + IntegerToString(p.trade_no) + " Pos" + IntegerToString(p.pos_no) + " stopped out");
            continue;
           }
        }
     }

// --- 2) Prüfen ob Richtung komplett fertig ist -> active_* löschen
   bool any_long_active = false;
   bool any_short_active = false;

   for(int j = 0; j < n; j++)
     {
      if(g_cache_rows[j].was_sent != 1)
         continue;

      if(g_cache_rows[j].direction == "LONG" && g_ui_state.active_trade_no_long > 0 && g_cache_rows[j].trade_no == g_ui_state.active_trade_no_long)
        {
         if(StatusIsActive(g_cache_rows[j].status))
            any_long_active = true;
        }

      if(g_cache_rows[j].direction == "SHORT" && g_ui_state.active_trade_no_short > 0 && g_cache_rows[j].trade_no == g_ui_state.active_trade_no_short)
        {
         if(StatusIsActive(g_cache_rows[j].status))
            any_short_active = true;
        }
     }

   if(g_ui_state.active_trade_no_long > 0 && !any_long_active)
      ClearActiveTrend("LONG");

   if(g_ui_state.active_trade_no_short > 0 && !any_short_active)
      ClearActiveTrend("SHORT");

   if(any_closed || any_opened)
      g_tp.RequestRebuild();
  }








// --- Trade-Line Erkennung/Parsing -------------------------------------------
bool UI_IsLineTagName(const string name)
  {
   int L = (int)StringLen(name);
   int S = (int)StringLen(LINE_TAG_SUFFIX);
   if(L < S)
      return false;
   return (StringSubstr(name, L - S) == LINE_TAG_SUFFIX);
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool UI_IsTradePosLine(const string name)
  {
// Tags nicht als Linien behandeln
   if(UI_IsLineTagName(name))
      return false;
   return (
             StringFind(name, "SL_Long_")    == 0 ||
             StringFind(name, "Entry_Long_") == 0 ||

             StringFind(name, "SL_Short_")   == 0 ||
             StringFind(name, "Entry_Short_")== 0);
  }

#ifndef LINE_TAG_SUFFIX
#define LINE_TAG_SUFFIX "_TAG"
#endif

/**
 * Beschreibung: Synchronisiert ein Label-Tag (_TAG) pixelgenau an die Y-Position einer HLINE/Trade-Linie.
 *              Ziel: Tag läuft beim Drag ohne sichtbares "Nachziehen" mit.
 * Parameter:    line_name - Name der Linie (z.B. "Entry_Long_12_3")
 * Rückgabewert: bool - true wenn Sync ok, sonst false
 * Hinweise:     - Tag wird als OBJ_LABEL rechts oben verankert (CORNER_RIGHT_UPPER)
 *              - Y wird per ChartTimePriceToXY aus einer garantiert sichtbaren Bar ermittelt
 * Fehlerfälle:  - Linie nicht gefunden -> false
 *              - ChartTimePriceToXY failt -> false (Print mit GetLastError)
 */

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool UI_LineTag_SyncToLine(const string line_name)
  {
   if(ObjectFind(0, line_name) < 0)
      return false;

   const string tag_name = line_name + LINE_TAG_SUFFIX;

// Preis der Linie holen
   const double price = ObjectGetDouble(0, line_name, OBJPROP_PRICE);
   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

// Tag ggf. erstellen
   if(ObjectFind(0, tag_name) < 0)
     {
      ResetLastError();
      if(!ObjectCreate(0, tag_name, OBJ_LABEL, 0, 0, 0))
        {
         Print(__FUNCTION__, ": ObjectCreate failed tag='", tag_name, "' err=", GetLastError());
         return false;
        }

      // Eigenschaften: nicht anklickbar, nicht im Objektbaum sichtbar
      ObjectSetInteger(0, tag_name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, tag_name, OBJPROP_HIDDEN,     true);
      ObjectSetInteger(0, tag_name, OBJPROP_BACK,       false);
      ObjectSetInteger(0, tag_name, OBJPROP_ZORDER,     1000);
      ObjectSetInteger(0, tag_name, OBJPROP_FONTSIZE,   9);
     }

// Text aktualisieren (du kannst hier auch "E:"/"SL:" ergänzen, wenn du willst)
   ObjectSetString(0, tag_name, OBJPROP_TEXT, DoubleToString(price, digits));

// Rechts verankern, damit es sauber am rechten Rand steht
   ObjectSetInteger(0, tag_name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, tag_name, OBJPROP_XDISTANCE, 8);

// Sichtbare Bar-Zeit holen (robuster als TimeCurrent)
   long first_visible = ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR, 0);
   if(first_visible < 0)
      first_visible = 0;
   datetime t_vis = iTime(_Symbol, (ENUM_TIMEFRAMES)_Period, (int)first_visible);
   if(t_vis <= 0)
      t_vis = iTime(_Symbol, (ENUM_TIMEFRAMES)_Period, 0);

   int x = 0, y = 0;
   ResetLastError();
   if(!ChartTimePriceToXY(0, 0, t_vis, price, x, y))
     {
      Print(__FUNCTION__, ": ChartTimePriceToXY failed line='", line_name,
            "' price=", DoubleToString(price, digits),
            " err=", GetLastError());
      return false;
     }

// Y setzen (kleiner Offset, damit Text nicht exakt auf der Linie klebt)
   int y_px = y - 7;
   if(y_px < 0)
      y_px = 0;

   ObjectSetInteger(0, tag_name, OBJPROP_YDISTANCE, y_px);

   return true;
  }

//+------------------------------------------------------------------+
