
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

/*
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string FormatCloseSL_DB(const g_DB.PositionRow &p)
  {
   string msg = "@everyone\n";
   msg += StringFormat("**Note:** %s Trade %d | Pos %d - has been stopped out\n",
                       p.symbol, p.trade_no, p.pos_no);
   return msg;
  }
*/


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ClearActiveTrend(const string direction)
  {
   if(direction == "LONG")
     {
      active_long_trade_no = 0;
      is_long_trade = false;
      HitEntryPriceLong = false; // legacy-Flag, jetzt egal – aber sauber

      g_DB.SetMetaInt(g_DB.Key("active_long_trade_no"), 0);

      if(ObjectFind(0, TP_BTN_ACTIVE_LONG) != -1)
        {
         showActive_long(false); //Button Ausblenden
         showCancel_long(false);
        }
     }
   else
      if(direction == "SHORT")
        {
         active_short_trade_no = 0;
         is_sell_trade = false;
         HitEntryPriceShort = false;

         if(g_DB.SetMetaInt(g_DB.Key("active_short_trade_no"), 0))
           {
            if(ObjectFind(0, TP_BTN_ACTIVE_SHORT) != -1)
              {
               showActive_long(false);
               showCancel_short(false);
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
        if(ui_direction_is_long)
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
//| Sabio TP berechnen                                                                 |
//+------------------------------------------------------------------+
void UpdateSabioTP()
  {
   if(Entry_Price > CurrentAskPrice)
     {
      string EntryPriceString = ObjectGetString(0, SabioEntry, OBJPROP_TEXT, 0);
      int Ergebnis = StringReplace(EntryPriceString, "SABIO ENTRY:", "");
      double SabioEntryPrice = (double)EntryPriceString;
      string SabioSLPriceString = ObjectGetString(0, SabioSL, OBJPROP_TEXT, 0);
      int ErgebnisSL = StringReplace(SabioSLPriceString, "SABIO SL:", "");
      double SabioSLPrice = (double)SabioSLPriceString;
     }

   if(Entry_Price < CurrentBidPrice)
     {
      string EntryPriceString = ObjectGetString(0, SabioEntry, OBJPROP_TEXT, 0);
      int Ergebnis = StringReplace(EntryPriceString, "SABIO ENTRY:", "");
      double SabioEntryPrice = (double)EntryPriceString;
      string SabioSLPriceString = ObjectGetString(0, SabioSL, OBJPROP_TEXT, 0);
      int ErgebnisSL = StringReplace(SabioSLPriceString, "SABIO SL:", "");

      double SabioSLPrice = (double)SabioSLPriceString;
     }
  }

//+------------------------------------------------------------------+
//| Tradelinien Short löschen                                                                 |
//+------------------------------------------------------------------+




//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TPSLReached()
  {
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
         if(active_long_trade_no <= 0 || p.trade_no != active_long_trade_no)
            continue;
        }
      else
         if(p.direction == "SHORT")
           {
            if(active_short_trade_no <= 0 || p.trade_no != active_short_trade_no)
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
            p.status = "OPEN";
            p.updated_at = TimeCurrent();
            g_DB.UpsertPosition(p);
            g_cache_rows[i] = p;
            // Linien optisch aktivieren
            g_TradeMgr.SetPosLinesSolid(p.direction, p.pos_no);
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
            g_Discord.SendMessage(_Symbol,g_Discord.FormatCloseSL_DB(p));
            p.status = "CLOSED_SL";
            p.is_pending = 0;
            p.updated_at = TimeCurrent();
            g_DB.UpsertPosition(p);
            g_cache_rows[i] = p;
            DeletePosLines("LONG", p.pos_no);
            Alert(_Symbol + " LONG Trade " + IntegerToString(p.trade_no) + " Pos" + IntegerToString(p.pos_no) + " stopped out");
            continue;
           }
        }

      // SHORT Regeln
      if(p.direction == "SHORT")
        {
         if(p.sl > 0.0 && (CurrentAskPrice >= p.sl))
           {
            g_Discord.SendMessage(_Symbol,g_Discord.FormatCloseSL_DB(p));
            p.status = "CLOSED_SL";
            p.is_pending = 0;
            p.updated_at = TimeCurrent();
            g_DB.UpsertPosition(p);
            g_cache_rows[i] = p;
            DeletePosLines("SHORT", p.pos_no);
            Alert(_Symbol + " SHORT Trade " + IntegerToString(p.trade_no) + " Pos" + IntegerToString(p.pos_no) + " stopped out");
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

      if(g_cache_rows[j].direction == "LONG" && active_long_trade_no > 0 && g_cache_rows[j].trade_no == active_long_trade_no)
        {
         if(StatusIsActive(g_cache_rows[j].status))
            any_long_active = true;
        }

      if(g_cache_rows[j].direction == "SHORT" && active_short_trade_no > 0 && g_cache_rows[j].trade_no == active_short_trade_no)
        {
         if(StatusIsActive(g_cache_rows[j].status))
            any_short_active = true;
        }
     }

   if(active_long_trade_no > 0 && !any_long_active)
      ClearActiveTrend("LONG");

   if(active_short_trade_no > 0 && !any_short_active)
      ClearActiveTrend("SHORT");
  }





//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SetPriceOnObject(const string name, const double price)
  {
   if(ObjectFind(0, name) < 0)
      return false;

   long type = ObjectGetInteger(0, name, OBJPROP_TYPE);

   if(type == OBJ_HLINE)
      return ObjectSetDouble(0, name, OBJPROP_PRICE, price);

// Fallback für “preisbasierte” Objekte mit Punkten:
   datetime t = iTime(_Symbol, (ENUM_TIMEFRAMES)Period(), 0);
   return ObjectMove(0, name, 0, t, price);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createEntryAndSLLinien()
  {

   xd3 = getChartWidthInPixels() -DistancefromRight-10;
   yd3 = getChartHeightInPixels()/2;
   xs3 = 280;
   ys3= 30;
   datetime dt_tp = iTime(_Symbol, 0, 0), dt_sl = iTime(_Symbol, 0, 0), dt_prc = iTime(_Symbol, 0, 0);
   double price_tp = iClose(_Symbol, 0, 0), price_sl = iClose(_Symbol, 0, 0), price_prc = iClose(_Symbol, 0, 0);
   int window = 0;

   ChartXYToTimePrice(0, xd3, yd3 + ys3, window, dt_prc, price_prc);
   ChartXYToTimePrice(0, xd5, yd5 + ys5, window, dt_sl, price_sl);

   createHLine(PR_HL, price_prc,color_EntryLine);
   SetPriceOnObject(PR_HL, price_prc);


//+------------------------------------------------------------------+
//createHL(PR_HL, dt_prc, price_prc, EntryLine);

   createButton(EntryButton, "", xd3, yd3, xs3, ys3, PriceButton_font_color, PriceButton_bgcolor, InpFontSize, clrNONE, InpFont);

// SL Button
   xd5 = xd3;
   yd5 = yd3 + 100;
   xs5 = xs3;
   ys5 = 30;

   ChartXYToTimePrice(0, xd5, yd5 + ys5, window, dt_sl, price_sl);

   createHL(SL_HL, dt_sl, price_sl, color_SLLine);

   ObjectMove(0, EntryButton, 0, dt_prc, price_prc);




//   DrawHL();
   if(Sabioedit)
     {
      SabioEdit();
     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   SendButton();
   if(!SendOnlyButton)
     {
      ObjectSetString(0, SENDTRADEBTN, OBJPROP_TEXT, "T & S"); // label
      UI_ObjSetIntSafe(0, SENDTRADEBTN, OBJPROP_BGCOLOR, TSButton_bgcolor);
      ObjectSetInteger(0, SENDTRADEBTN, OBJPROP_COLOR, TSButton_font_color);
     }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   createButton(SLButton, "", xd5, yd5, xs5, ys5, SLButton_font_color, SLButton_bgcolor, InpFontSize, clrNONE, InpFont);
   ObjectMove(0, SLButton, 0, dt_sl, price_sl);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   update_Text(EntryButton, "Buy Stop @ " + Get_Price_s(PR_HL) + " | Lot: " + DoubleToString(NormalizeDouble(g_TradeMgr.calcLots(_Symbol,_Period,SL_Price - Entry_Price), 2), 2));
   update_Text(SLButton, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool createHLine(const string name, const double price, color clr)
  {
   if(ObjectFind(0, name) >= 0)
      return true;

   if(!ObjectCreate(0, name, OBJ_HLINE, 0, 0, price))
     {
      CLogger::Add(LOG_LEVEL_INFO, "createHLine: create failed for "+ name+ " err="+ GetLastError());
      return false;
     }
   UI_ObjSetIntSafe(0, name, OBJPROP_SELECTABLE, true);
   UI_ObjSetIntSafe(0, name, OBJPROP_HIDDEN, false);
//UI_ObjSetIntSafe(0, objName, OBJPROP_TIME, time1);
   ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   UI_ObjSetIntSafe(0, name, OBJPROP_COLOR, clr);
   UI_ObjSetIntSafe(0, name, OBJPROP_BACK, false);
   UI_ObjSetIntSafe(0, name, OBJPROP_STYLE, STYLE_SOLID);
   UI_ObjSetIntSafe(0, name, OBJPROP_ZORDER, 10);

   UI_Reg_Add(name);//Speichere Object im Array zum späteren löschen

   return true;
  }



// Einheitlicher Suffix (wenn du lieber "_tag" willst: hier ändern UND überall beim Delete ändern)



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

// Erzeugt/updated das Tag-Label für genau DIESE Linie
bool UI_CreateOrUpdateLineTag(const string line_name)
  {
   if(ObjectFind(0, line_name) < 0)
      return false;

   const string tag_name = line_name + LINE_TAG_SUFFIX;
   UI_Reg_Add(tag_name); // sicher, weil UI_Reg_Add unique prüft

// >>> WICHTIG: Preis von DER Linie holen, nicht von PR_HL/SL_HL
   const double price = ObjectGetDouble(0, line_name, OBJPROP_PRICE);

// Farbe optional von der Linie übernehmen
   const color  line_clr = (color)ObjectGetInteger(0, line_name, OBJPROP_COLOR);

// y-Pixel aus Preis berechnen (x ignorieren), dann Label rechts anheften
   int x_any = 0, y = 0;
   ChartTimePriceToXY(0, 0, TimeCurrent(), price, x_any, y);

   const int chart_w = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);
   const int x = chart_w - 160;          // rechts im Chart, anpassen nach Geschmack
   const int y_adj = y - 8;              // optische Zentrierung

// Text hübsch machen: T/P aus Suffix ziehen
   string parts[];
   int n = StringSplit(line_name, '_', parts);
   int trade_no = 0, pos_no = 0;
   if(n >= 2)
     {
      trade_no = (int)StringToInteger(parts[n-2]);
      pos_no   = (int)StringToInteger(parts[n-1]);
     }

   string kind = "";
   if(StringFind(line_name, Entry_Long, 0) == 0)
      kind = "ENTRY LONG";
   if(StringFind(line_name, SL_Long, 0) == 0)
      kind = "SL LONG";
   if(StringFind(line_name, Entry_Short, 0) == 0)
      kind = "ENTRY SHORT";
   if(StringFind(line_name, SL_Short, 0) == 0)
      kind = "SL SHORT";

   const string txt = StringFormat("T%d P%d  %s  %s",
                                   trade_no, pos_no, kind,
                                   DoubleToString(price, _Digits));

   if(ObjectFind(0, tag_name) < 0)
     {
      if(!ObjectCreate(0, tag_name, OBJ_LABEL, 0, 0, 0))
         return false;

      UI_Reg_Add(tag_name);

      UI_ObjSetIntSafe(0, tag_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      UI_ObjSetIntSafe(0, tag_name, OBJPROP_FONTSIZE, 9);
      UI_ObjSetIntSafe(0, tag_name, OBJPROP_COLOR, line_clr);

      // Damit das Tag nicht “aus Versehen” gezogen wird:
      UI_ObjSetIntSafe(0, tag_name, OBJPROP_SELECTABLE, false);
      UI_ObjSetIntSafe(0, tag_name, OBJPROP_SELECTED,   false);
      UI_ObjSetIntSafe(0, tag_name, OBJPROP_BACK,       false);
     }

   UI_ObjSetIntSafe(0, tag_name, OBJPROP_XDISTANCE, x);
   UI_ObjSetIntSafe(0, tag_name, OBJPROP_YDISTANCE, y_adj-5);
   ObjectSetString(0,  tag_name, OBJPROP_TEXT,      txt);

   return true;
  }



//+------------------------------------------------------------------+
