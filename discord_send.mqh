//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#ifndef __DISCORD_SEND__
#define __DISCORD_SEND__


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DiscordSend()
  {

   static bool busy=false;
   if(busy)
      return;
   busy=true;

// --- TradeNr aus Eingabefeld (TRNB)
   string tradenummer_string = "";
   ObjectGetString(0, TRNB, OBJPROP_TEXT, 0, tradenummer_string);
   int trade_no_input = (int)StringToInteger(tradenummer_string);

   bool isLong = ui_direction_is_long;
   int idx = (ui_direction_is_long ? 0 : 1);
   string direction = (ui_direction_is_long ? "LONG" : "SHORT");

// --- Basis-Validierung (Preis vs. Markt)
   if(ui_direction_is_long)
     {
      if(Entry_Price <= CurrentAskPrice)
        {
         MessageBox("Entry ist tiefer als aktueller Ask.", NULL, MB_OK);
         return;
        }
     }
   else
     {
      if(Entry_Price >= CurrentBidPrice)
        {
         MessageBox("Entry ist höher als aktueller Bid.", NULL, MB_OK);
         return;
        }
     }

// --- Aktive Tradenummer der Richtung
   int active_trade_no = (ui_direction_is_long ? active_long_trade_no : active_short_trade_no);

// --- TradeNo bestimmen (AUTO-KORREKTUR statt blockieren)
   int trade_no = trade_no_input;

// (A) Richtung hat bereits laufende Pyramide -> immer gleiche TradeNo erzwingen
   if(active_trade_no > 0)
     {
      if(trade_no != active_trade_no)
        {
         trade_no = active_trade_no;
         update_Text(TRNB, IntegerToString(trade_no)); // UI korrigieren
        }
     }
// (B) Richtung ist neu -> wenn Eingabe ungültig, automatisch nächste Nummer nehmen
   else
     {
      if(trade_no <= last_trade_nummer)
        {
         trade_no = last_trade_nummer + 1;
         update_Text(TRNB, IntegerToString(trade_no)); // UI korrigieren
        }
     }

   bool starting_new_trade = (active_trade_no <= 0);

// 1) gleichzeitig aktive Positionen zählen (nicht CLOSED)
   int active_cnt = DB_CountActivePositions(_Symbol, (ENUM_TIMEFRAMES)_Period, direction, trade_no);
   if(active_cnt >= DB_MAX_POS_PER_SIDE)
     {
      MessageBox("Maximale gleichzeitige Positionen erreicht (max 4).", NULL, MB_OK);
      return;
     }

// 2) nächste Positionsnummer vergeben (darf 5,6,7... sein)
   int pos_no = DB_GetNextPosNo(_Symbol, _Period, direction, trade_no);
   if(pos_no < 1)
      pos_no = 1;


// --- Draft in DB schreiben
   DB_PositionRow row;
   row.symbol = _Symbol;
   row.tf = TF_ToString((ENUM_TIMEFRAMES)_Period);
   row.direction = direction;
   row.trade_no = trade_no;
   row.pos_no = pos_no;
   row.entry = Entry_Price;
   row.sl = SL_Price;
   row.sabio_entry = (Sabioedit ? ObjectGetString(0, SabioEntry, OBJPROP_TEXT, 0) : "kein Sabio");
   row.sabio_sl = (Sabioedit ? ObjectGetString(0, SabioSL, OBJPROP_TEXT, 0) : "kein Sabio");

   row.status = "DRAFT";
   row.was_sent = 0;
   row.is_pending = 1;
   row.updated_at = TimeCurrent();

   if(!DB_UpsertPosition(row))
     {
      MessageBox("DB Fehler: Position konnte nicht gespeichert werden.", NULL, MB_OK);
      return;
     }

// --- Discord senden
   string message = FormatTradeMessage(row);

   bool discord_ok = SendDiscordMessage(message);

   if(!discord_ok)
     {
       CLogger::Add(LOG_LEVEL_INFO, "Discord Fehler (Draft bleibt in DB, PosNo bleibt wiederverwendbar)");
   
      RollbackDraftRow(row);
      return;
     }

// Screenshot optional
   SendScreenShot(_Symbol, _Period, getChartWidthInPixels(), getChartHeightInPixels());

// --- Commit: Position bestätigt

   row.status = "PENDING";
   row.was_sent = 1;
   row.is_pending = 1;
   row.updated_at = TimeCurrent();
   DB_UpsertPosition(row);
   Cache_UpsertLocal(row);

   if(isLong)
     {
      // Info-Label sicht- und farbig machen
      showActive_long(true);
      showCancel_long(true);

      update_Text(TP_BTN_ACTIVE_LONG, "ACTIVE POSITION");
      UI_TradesPanel_RebuildRows();
     }
   else
     {
      showActive_short(true);
      showCancel_short(true);
      update_Text(TP_BTN_ACTIVE_SHORT, "ACTIVE POSITION");
      UI_TradesPanel_RebuildRows();
     }

// --- Meta aktualisieren

// last_trade_no nur bei neuem Trade (Pos1) committen
   if(starting_new_trade && pos_no == 1 && trade_no > last_trade_nummer)
     {
      last_trade_nummer = trade_no;
      DB_SetMetaInt(DB_Key("last_trade_no"), last_trade_nummer);
     }
// aktive TradeNo der Richtung nur beim Start (Pos1) setzen
   if(starting_new_trade && pos_no == 1)
     {
      if(isLong)
        {
         active_long_trade_no = trade_no;
         is_long_trade = true;
         DB_SetMetaInt(DB_Key("active_long_trade_no"), active_long_trade_no);
         UI_TradesPanel_RebuildRows();
        }
      else
        {
         active_short_trade_no = trade_no;
         is_sell_trade = true;
         DB_SetMetaInt(DB_Key("active_short_trade_no"), active_short_trade_no);
         UI_TradesPanel_RebuildRows();
        }
     }


// --- TRNB sinnvoll setzen:
// wenn Richtung weiterläuft -> gleiche TradeNo anzeigen
// wenn Pos4 erreicht -> Vorschlag nächste TradeNo
// Wenn Richtung aktiv -> zeig weiterhin diese TradeNr
   if(active_trade_no > 0)
     {
      update_Text(TRNB, IntegerToString(active_trade_no));
      update_Text(POSNB, IntegerToString(pos_no+1));
     }
   else
      update_Text(TRNB, IntegerToString(last_trade_nummer + 1));

// --- Panels/Übersicht aktualisieren
   UI_UpdateNextTradePosUI();

   busy=false;

  }






#endif // __DISCORD_SEND__
