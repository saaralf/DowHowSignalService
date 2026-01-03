//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#ifndef __EVENTHANDLER__
#define __EVENTHANDLER__


#include "discord_client.mqh"
#include "trade_manager.mqh"
// ------------------------------------------------------------------
// TradePos-Drag Tracking (damit Discord nur 1x pro Drag gesendet wird)
// Hinweis: Bei manchen MT5-Objekten kommt CHARTEVENT_OBJECT_CHANGE nicht
// zuverlässig. Darum finalisieren wir zusätzlich beim MouseUp.
// ------------------------------------------------------------------
static bool   g_tp_drag_active   = false;
// ------------------------------------------------------------------
// Basis-Linien-Drag Tracking (PR_HL / SL_HL)
// Ziel: UI live synchronisieren, Speichern nur 1x beim Loslassen.
// ------------------------------------------------------------------
static bool   g_base_drag_active  = false;
static string g_base_drag_name    = "";
static uint   g_base_drag_last_ms = 0;

/**
 * Beschreibung: MouseUp-Fallback für Basislinien. Falls MT5 kein OBJECT_CHANGE feuert,
 *               finalisieren wir beim Loslassen: UI sync + SaveLinePrices.
 * Parameter:    MouseState - 0 bedeutet MouseUp (Loslassen)
 * Rückgabewert: void
 * Hinweise:     Wird in CHARTEVENT_MOUSE_MOVE aufgerufen.
 * Fehlerfälle:  keine (nur Logs in den Unterfunktionen)
 */
void BaseLines_FinalizeDragIfNeeded(const int MouseState)
  {
   if(MouseState != 0)
      return;
   if(!g_base_drag_active)
      return;

   g_base_drag_active  = false;
   g_base_drag_name    = "";
   g_base_drag_last_ms = 0;

   UI_OnBaseLinesChanged(true); // speichern + redraw
  }

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
   g_TradeMgr.SaveLinePrices(_Symbol,(ENUM_TIMEFRAMES)_Period);

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
      // --- Basislinien (PR_HL / SL_HL): UI live nachziehen
      if(sparam == PR_HL || sparam == SL_HL)
        {
         g_base_drag_active  = true;
         g_base_drag_name    = sparam;
         g_base_drag_last_ms = GetTickCount();

         // live: Buttons/Edits/Text nachziehen, aber NICHT speichern
         UI_OnBaseLinesChanged(false);
         return;
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

      // Basislinien: UI + Texte synchronisieren + speichern
      // Basislinien: final synchronisieren + speichern
      if(sparam == PR_HL || sparam == SL_HL)
        {
         g_base_drag_active  = false;
         g_base_drag_name    = "";
         g_base_drag_last_ms = 0;

         UI_OnBaseLinesChanged(true);
         return;
        }


      // Trade-Linien: wie gehabt
      if(UI_IsTradePosLine(sparam))
        {
         UI_CreateOrUpdateLineTag(sparam);
         g_TradeMgr.SaveLinePrices(_Symbol, (ENUM_TIMEFRAMES)_Period);
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
      // MouseUp-Fallback für Basislinien (falls OBJECT_CHANGE ausbleibt)
      BaseLines_FinalizeDragIfNeeded(MouseState);

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

         // 1 Quelle der Wahrheit: Text/Lot/Direction aus PR_HL & SL_HL ableiten
         UI_UpdateBaseSignalTexts();


         datetime dt_TP = 0;
         double price_TP = 0;
      

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
         // 1 Quelle der Wahrheit: Text/Lot/Direction aus PR_HL & SL_HL ableiten
         UI_UpdateBaseSignalTexts();
        
         ChartRedraw(0);
        }

      if(MouseState == 0)
        {
         bool wasMoving = (movingState_R3 || movingState_R5);
         movingState_R3 = false;
         movingState_R5 = false;
         ChartSetInteger(0, CHART_MOUSE_SCROLL, true);
         if(wasMoving)
            g_TradeMgr.SaveLinePrices(_Symbol, (ENUM_TIMEFRAMES)_Period);
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
// 1) Business-Teil (Discord + DB + Cache + Remaining-Check) -> TradeManager
   bool has_pending = true;
   string err = "";

   CTradeManager::EPosAction act =
      (action == "CANCEL" ? CTradeManager::POS_CANCEL : CTradeManager::POS_HIT_SL);

   if(!g_TradeMgr.HandlePositionAction(_Symbol, (ENUM_TIMEFRAMES)_Period,
                                       direction, trade_no, pos_no,
                                       act, has_pending, err))
     {
      CLogger::Add(LOG_LEVEL_WARNING, "HandlePositionAction failed: " + err);
      return;
     }

// 2) UI-Linien/Tags dieser Position entfernen (wie bisher)
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

   UI_DeleteTradePosLines(trade_no, pos_no);
   UI_UpdateAllLineTags();

// 3) Falls letzte pending Position -> Runtime + Meta zurücksetzen
   if(!has_pending)
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

// 4) UI Refresh
   UI_UpdateNextTradePosUI();
   ChartRedraw(0);
  }



//+------------------------------------------------------------------+
//| Cancel active trade (header cancel buttons)                       |
//+------------------------------------------------------------------+
bool UI_CancelActiveTrade(const string direction)
  {
   const bool isLong = (direction == "LONG");
   int trade_no = (isLong ? active_long_trade_no : active_short_trade_no);

   if(trade_no <= 0)
     {
      CLogger::Add(LOG_LEVEL_INFO, "UI_CancelActiveTrade: kein aktiver Trade für " + direction);
      return false;
     }

   string err = "";
   if(!g_TradeMgr.CancelTrade(_Symbol, (ENUM_TIMEFRAMES)_Period, direction, trade_no, err))
     {
      CLogger::Add(LOG_LEVEL_WARNING, "UI_CancelActiveTrade: CancelTrade failed: " + err);
      return false;
     }

// Linien/Tags entfernen
   UI_DeleteTradeLinesByTradeNo(trade_no);
   UI_UpdateAllLineTags();

// Runtime + Meta zurücksetzen (damit OnInit NICHT reaktiviert)
   if(isLong)
     {
      if(active_long_trade_no == trade_no)
        {
         active_long_trade_no = 0;
         g_DB.SetMetaInt(g_DB.Key("active_long_trade_no"), 0);
        }
      is_long_trade     = false;
      HitEntryPriceLong = false;

      showActive_long(false);
      showCancel_long(false);

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

      showActive_short(false);
      showCancel_short(false);

      if(ObjectFind(0, "ActiveShortTrade") >= 0)
        {
         ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_COLOR, clrNONE);
         ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_BGCOLOR, clrNONE);
        }
     }

   UI_UpdateNextTradePosUI();
   UI_TradesPanel_RebuildRows();
   ChartRedraw(0);
   return true;
  }
/**
 * Beschreibung: Liest Entry- und SL-Preis sicher aus den Basis-HLines (PR_HL/SL_HL).
 * Parameter:    out_entry - Rückgabe Entry-Preis
 *               out_sl    - Rückgabe SL-Preis
 * Rückgabewert: true, wenn beide Linien existieren und Preise > 0 sind
 * Hinweise:     Nutzt ObjectFind/ObjectGetDouble mit Fehler-Logs.
 * Fehlerfälle:  Linien fehlen oder Preis<=0 -> false (Print im Log)
 */
bool UI_GetBaseEntrySL(double &out_entry, double &out_sl)
  {
   out_entry = 0.0;
   out_sl    = 0.0;

   if(ObjectFind(0, PR_HL) < 0 || ObjectFind(0, SL_HL) < 0)
     {
      Print(__FUNCTION__, ": PR_HL/SL_HL not found");
      return false;
     }

   ResetLastError();
   out_entry = ObjectGetDouble(0, PR_HL, OBJPROP_PRICE);
   int err1  = GetLastError();

   ResetLastError();
   out_sl    = ObjectGetDouble(0, SL_HL, OBJPROP_PRICE);
   int err2  = GetLastError();

   if(err1 != 0 || err2 != 0)
      Print(__FUNCTION__, ": ObjectGetDouble error entry=", err1, " sl=", err2);

   if(out_entry <= 0.0 || out_sl <= 0.0)
      return false;

   return true;
  }/**
 * Beschreibung: Aktualisiert Direction/Lot/Texts (EntryButton, SLButton, SabioEntry, SabioSL)
 *              anhand der Basislinien-Preise (PR_HL/SL_HL) als 1 Quelle der Wahrheit.
 * Parameter:    opt_direction_object_name - OPTIONAL: Name eines Labels/Buttons, das nur "BUY" oder "SELL" anzeigen soll.
 * Rückgabewert: void
 * Hinweise:     Sabio-Texts werden hier zentral gepflegt, damit MouseMove keine Sonderlogik mehr braucht.
 * Fehlerfälle:  Fehlende Objekte werden übersprungen; bei fehlenden Linien wird abgebrochen (Print im Log).
 */
void UI_UpdateBaseSignalTexts(const string opt_direction_object_name = "")
  {
   double entry = 0.0, sl = 0.0;
   if(!UI_GetBaseEntrySL(entry, sl))
      return;

// Direction: SL über Entry => SHORT, sonst LONG
   ui_direction_is_long = (sl < entry);

// Distanz robust positiv (für Lots/Risk)
   const double dist = MathAbs(entry - sl);

// Lots: nutzt deine bestehende Logik im TradeManager (keine Heavy-Operation)
   double lots = g_TradeMgr.calcLots(_Symbol, (ENUM_TIMEFRAMES)_Period, dist);
   lots = NormalizeDouble(lots, 2);

// Entry-Button Text: zeigt Direction + Preis + Lot
   string entry_txt = (ui_direction_is_long ? "Buy Stop @ " : "Sell Stop @ ");
   entry_txt += DoubleToString(entry, _Digits) + " | Lot: " + DoubleToString(lots, 2);

// SL-Button Text: zeigt SL-Preis + Distanz in Points
   string sl_txt = "SL: " + DoubleToString(dist / _Point, 0) + " Points | " + DoubleToString(sl, _Digits);

// UI aktualisieren (nur wenn Objekt existiert)
   if(ObjectFind(0, EntryButton) >= 0)
      update_Text(EntryButton, entry_txt);
   if(ObjectFind(0, SLButton)    >= 0)
      update_Text(SLButton,    sl_txt);

// Sabio-Texts zentral pflegen (damit MouseMove nicht doppelt rechnet)
   if(ObjectFind(0, SabioEntry) >= 0)
     {
      if(SabioPrices)
         update_Text(SabioEntry, "SABIO Entry: " + DoubleToString(entry, _Digits));
      else
         update_Text(SabioEntry, "SABIO ENTRY: ");
     }

   if(ObjectFind(0, SabioSL) >= 0)
     {
      if(SabioPrices)
         update_Text(SabioSL, "SABIO SL: " + DoubleToString(sl, _Digits));
      else
         update_Text(SabioSL, "SABIO SL: ");
     }

// OPTIONAL: Falls du irgendwo ein Direction-Label/Button hast
   if(opt_direction_object_name != "" && ObjectFind(0, opt_direction_object_name) >= 0)
      update_Text(opt_direction_object_name, (ui_direction_is_long ? "BUY" : "SELL"));
  }


/**
 * Beschreibung: Synchronisiert die Y-Position der Basis-UI (Entry/SL Buttons + Send/TRNB/POSNB + Sabio-Edits)
 *               zu den Basis-HLines PR_HL und SL_HL.
 * Parameter:    none
 * Rückgabewert: void
 * Hinweise:     Nur Y wird angepasst; X bleibt wie vom Layout vorgegeben.
 * Fehlerfälle:  ChartTimePriceToXY=false -> Print im Log
 */
void UI_SyncBaseButtonsToLines()
  {
   double entry = 0.0, sl = 0.0;
   if(!UI_GetBaseEntrySL(entry, sl))
      return;

// Wir nehmen die aktuelle Bar-Zeit als X-Anker (rechts sichtbar).
   datetime t = iTime(_Symbol, (ENUM_TIMEFRAMES)_Period, 0);

   int x = 0, y = 0;

// -------------------------
// ENTRY-GRUPPE (PR_HL)
// EntryButton, SENDTRADEBTN, TRNB, POSNB, SabioEntry
// -------------------------
   if(ObjectFind(0, EntryButton) >= 0)
     {
      int ysize_entry_btn = (int)ObjectGetInteger(0, EntryButton, OBJPROP_YSIZE);

      if(ChartTimePriceToXY(0, 0, t, entry, x, y))
        {
         const int baseY = y - ysize_entry_btn;

         ObjectSetInteger(0, EntryButton,  OBJPROP_YDISTANCE, baseY);

         // SendButton sitzt links neben EntryButton auf gleicher Höhe
         if(ObjectFind(0, SENDTRADEBTN) >= 0)
            ObjectSetInteger(0, SENDTRADEBTN, OBJPROP_YDISTANCE, baseY);

         // TRNB/POSNB + SabioEntry sind 30px unter EntryButton
         if(ObjectFind(0, TRNB) >= 0)
            ObjectSetInteger(0, TRNB, OBJPROP_YDISTANCE, baseY + 30);

         if(ObjectFind(0, POSNB) >= 0)
            ObjectSetInteger(0, POSNB, OBJPROP_YDISTANCE, baseY + 30);

         if(ObjectFind(0, SabioEntry) >= 0)
            ObjectSetInteger(0, SabioEntry, OBJPROP_YDISTANCE, baseY + 30);
        }
      else
        {
         Print(__FUNCTION__, ": ChartTimePriceToXY failed for Entry");
        }
     }

// -------------------------
// SL-GRUPPE (SL_HL)
// SLButton + SabioSL
// -------------------------
   if(ObjectFind(0, SLButton) >= 0)
     {
      int ysize_sl_btn = (int)ObjectGetInteger(0, SLButton, OBJPROP_YSIZE);

      if(ChartTimePriceToXY(0, 0, t, sl, x, y))
        {
         const int baseY = y - ysize_sl_btn;

         ObjectSetInteger(0, SLButton, OBJPROP_YDISTANCE, baseY);

         if(ObjectFind(0, SabioSL) >= 0)
            ObjectSetInteger(0, SabioSL, OBJPROP_YDISTANCE, baseY + 30);
        }
      else
        {
         Print(__FUNCTION__, ": ChartTimePriceToXY failed for SL");
        }
     }
  }


/**
 * Beschreibung: Zentraler Handler für Basis-Linienänderungen (Line-Drag oder Change-Event).
 * Parameter:    do_save - wenn true: LinePrices in DB persistieren (nur beim Finalize)
 * Rückgabewert: void
 * Hinweise:     Throttled Redraw, damit Drag flüssig bleibt.
 * Fehlerfälle:  Keine (nur Logs).
 */
void UI_OnBaseLinesChanged(const bool do_save)
  {
   UI_SyncBaseButtonsToLines();
   UI_UpdateBaseSignalTexts(); // Direction steckt im EntryButton-Text

   if(do_save)
     {
      g_TradeMgr.SaveLinePrices(_Symbol, (ENUM_TIMEFRAMES)_Period);
      Print(__FUNCTION__, ": finalized + saved base line prices");
     }

// Redraw throttlen: Drag kann sonst ruckeln
   static uint last_redraw_ms = 0;
   uint now = GetTickCount();
   if(do_save || (now - last_redraw_ms > 50))
     {
      ChartRedraw(0);
      last_redraw_ms = now;
     }
  }

#endif // __EVENTHANDLER__
