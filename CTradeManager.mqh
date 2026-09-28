// trade_manager.mqh
//
// This class encapsulates the business logic for trade management.
// It uses the CDBService to store draft and active positions and
// uses the CDiscordClient to send notifications.

#ifndef __TRADE_MANAGER_MQH_
#define __TRADE_MANAGER_MQH_
#include "context.mqh"
#include "ui_state.mqh"
#include "CDBService.mqh"
#include "CDiscordClient.mqh"
#include "logger.mqh"
#include "positions_cache.mqh"
#include "UI_ParseTradePosFromName.mqh"
#include "UI_LineTag_GetLineName.mqh"
#include "CVirtualTradeGUI.mqh"
#include "CTradesPanel.mqh"


extern CVirtualTradeGUI g_vgui;
extern CTradesPanel     g_tp;


enum ESendDraftResult
  {
   SEND_OK = 0,
   SEND_ERR_INVALID,
   SEND_ERR_MAXPOS,
   SEND_ERR_DB,
   SEND_ERR_DISCORD
  };


struct STMSendFromDraftResult
  {
   bool              ok;
   string            error;

   string            direction;
   int               trade_no_input;
   int               pos_no_input;

   int               trade_no_effective;
   int               pos_no_effective;
   bool              starting_new_trade;

   DB_PositionRow    row;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string UI_BaseLineFromTag(const string tag_name)
  {
   int L = (int)StringLen(tag_name);
   int S = (int)StringLen(LINE_TAG_SUFFIX);
   if(L <= S)
      return "";
   return StringSubstr(tag_name, 0, L - S);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int UI_CleanupOrphanLineTags()
  {
   int deleted = 0;
   int total = ObjectsTotal(0, -1, -1);

   for(int i = total - 1; i >= 0; --i)
     {
      string name = ObjectName(0, i, -1, -1);
      if(name == "")
         continue;

      if(!UI_IsLineTagName(name))
         continue;

      string base_line = UI_LineNameFromTag(name);
      if(base_line == "")
         continue;

      if(ObjectFind(0, base_line) < 0)
        {
         if(UI_Reg_DeleteOne(name)) // löscht Objekt + entfernt aus Registry
            deleted++;
        }
     }
   return deleted;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string UI_LineNameFromTag(const string tag_name)
  {
   int L = (int)StringLen(tag_name);
   int S = (int)StringLen(LINE_TAG_SUFFIX);
   if(L <= S)
      return "";
   return StringSubstr(tag_name, 0, L - S);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Get_Price_d(string name)
  {
//   return ObjectGetDouble(0, name, OBJPROP_PRICE);
   return NormalizeDouble(ObjectGetDouble(0, name, OBJPROP_PRICE, 0), _Digits);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string Get_Price_s(string name)
  {
   return DoubleToString(ObjectGetDouble(0, name, OBJPROP_PRICE), _Digits);
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTradeManager
  {
private:
   CDBService        *m_db;
   CDiscordClient    *m_discord;
   SContext          m_ctx;

   int               m_nextTradeNo; // Next trade number to assign
   int               m_nextPosNo;   // Next position number to assign


public:
   void              SetContext(const SContext &ctx) { m_ctx=ctx; }
   enum EPosAction
     {
      POS_CANCEL = 0,
      POS_HIT_SL = 1
     };

                     CTradeManager() : m_db(NULL), m_discord(NULL) {}
   bool              TM_HandleTradePosEditCommit(const string symbol, const ENUM_TIMEFRAMES tf, const string field, const int value);
   bool              TM_HandleSendTradeClick(const string symbol, const ENUM_TIMEFRAMES tf, STMSendFromDraftResult &out);
   bool              UI_CloseOnePositionAndNotify(const string symbol,
         const ENUM_TIMEFRAMES tf,
         const string action,
         const string direction,
         const int trade_no,
         const int pos_no);

   void              PersistToDB(string symbol,const ENUM_TIMEFRAMES tf);
   bool              RestoreFromDB(const string symbol, const ENUM_TIMEFRAMES tf);

   bool              TM_SendFromDraft(const string symbol,
                                      const ENUM_TIMEFRAMES tf,
                                      STMSendFromDraftResult &out);


bool              TM_SendSignal(const string symbol,
                                const ENUM_TIMEFRAMES tf,
                                const string direction,
                                const int trade_no_input,
                                const int pos_no_input,
                                const double entry,
                                const double sl,
                                const string sabio_entry,
                                const string sabio_sl,
                                STMSendFromDraftResult &out);
   void              SaveLinePrices(const string symbol, const ENUM_TIMEFRAMES tf);

   void              SaveTradeLines(const string suf);
   void              SetPosLinesSolid(const string direction, const int trade_no, const int pos_no);


   bool              CancelTrade(const string symbol,
                                 const ENUM_TIMEFRAMES tf,
                                 const string direction,
                                 const int trade_no,
                                 string &out_err);

   bool              MarkPositionOpen(const string symbol,
                                      const ENUM_TIMEFRAMES tf,
                                      const string direction,
                                      const int trade_no,
                                      const int pos_no,
                                      string &out_err);

   bool              HandlePositionAction(const string symbol,
                                          const ENUM_TIMEFRAMES tf,
                                          const string direction,
                                          const int trade_no,
                                          const int pos_no,
                                          const EPosAction action,
                                          bool &out_trade_has_pending,
                                          string &out_err);

   ESendDraftResult  SendSignalDraft(const string symbol,
                                     const ENUM_TIMEFRAMES tf,
                                     const string direction,
                                     const int trade_no_input,
                                     const int pos_no_input,          // <-- NEU
                                     const double entry_price,
                                     const double sl_price,
                                     const string sabio_entry,
                                     const string sabio_sl,
                                     int &io_last_trade_no,
                                     int &io_active_trade_no,
                                     bool &io_is_trade_flag,
                                     int &out_trade_no_effective,
                                     int &out_pos_no,
                                     bool &out_starting_new_trade,
                                     DB_PositionRow &out_row,
                                     string &out_error);

   bool              TM_GetActiveTradeNo(const string symbol, const ENUM_TIMEFRAMES tf,
                                         const string direction, int &out_trade_no);

   bool              TM_GetNextPosNo(const string symbol, const ENUM_TIMEFRAMES tf,
                                     const string direction, const int trade_no,
                                     int &out_next_pos_no);

   bool              TM_GetLastTradeNo(const string symbol, const ENUM_TIMEFRAMES tf, int &out_last_trade_no);
   bool              TM_SetLastTradeNo(const string symbol, const ENUM_TIMEFRAMES tf, const int last_trade_no);
   // --- NEW: DB Bridge für GUI . TradeManager (TRNB/POSNB via DB) ---
   void              TM_PublishTradePosToDB(const string symbol, const ENUM_TIMEFRAMES tf);
   //+------------------------------------------------------------------+
   //| Cancel active trade (header cancel buttons)                       |
   //+------------------------------------------------------------------+
   bool              UI_CancelActiveTrade(const string direction)
     {
      const bool isLong = (direction == "LONG");
      int trade_no = (isLong ? g_ui_state.active_trade_no_long : g_ui_state.active_trade_no_short);

      if(trade_no <= 0)
        {
         CLogger::Add(LOG_LEVEL_INFO, "UI_CancelActiveTrade: kein aktiver Trade für " + direction);
         return false;
        }

      string err = "";
      if(!CancelTrade(m_ctx.symbol, m_ctx.tf, direction, trade_no, err))
        {
         CLogger::Add(LOG_LEVEL_WARNING, "UI_CancelActiveTrade: CancelTrade failed: " + err);
         return false;
        }

      // Linien/Tags entfernen
      TradePosLines_DeleteTradeByTradeNo(direction, trade_no);



      // Runtime + Meta zurücksetzen (damit OnInit NICHT reaktiviert)
      if(isLong)
        {
         if(g_ui_state.active_trade_no_long == trade_no)
           {
            g_ui_state.active_trade_no_long = 0;
            g_DB.SetMetaInt(g_DB.KeyFor(m_ctx.symbol, m_ctx.tf,"g_ui_state.active_trade_no_long"), 0);
           }
         is_long_trade     = false;
         HitEntryPriceLong = false;

         g_tp.ShowActiveLong(false);
         g_tp.ShowCancelLong(false);

         if(ObjectFind(0, "ActiveLongTrade") >= 0)
           {
            UI_ObjSetIntSafe(0, "ActiveLongTrade", OBJPROP_COLOR, clrNONE);
            UI_ObjSetIntSafe(0, "ActiveLongTrade", OBJPROP_BGCOLOR, clrNONE);
           }
        }
      else
        {
         if(g_ui_state.active_trade_no_short == trade_no)
           {
            g_ui_state.active_trade_no_short = 0;
            g_DB.SetMetaInt(g_DB.KeyFor(m_ctx.symbol, m_ctx.tf,"g_ui_state.active_trade_no_short"), 0);
           }

         is_sell_trade         = false;
         is_sell_trade_pending = false;
         HitEntryPriceShort    = false;

         g_tp.ShowActiveShort(false);
         g_tp.ShowCancelShort(false);

         if(ObjectFind(0, "ActiveShortTrade") >= 0)
           {
            UI_ObjSetIntSafe(0, "ActiveShortTrade", OBJPROP_COLOR, clrNONE);
            UI_ObjSetIntSafe(0, "ActiveShortTrade", OBJPROP_BGCOLOR, clrNONE);
           }
        }
      g_tp.RebuildRows();

      ChartRedraw(0);
      return true;
     }


   // Initialise dependencies.  This must be called before use.
   bool              Init(CDBService *db, CDiscordClient *discord,const SContext &ctx)
     {
      m_db      = db;
      m_discord = discord;
      m_ctx = ctx;
      // initialise counters
      m_nextTradeNo = 1;
      m_nextPosNo   = 1;

      return true;
     }
   void              RestoreTradePosLines(const string symbol, const ENUM_TIMEFRAMES tf)
     {
      DB_PositionRow rows[];
      int n = m_db.LoadPositions(symbol, tf, rows);

      for(int i=0;i<n;i++)
        {
         if(StringFind(rows[i].status, "CLOSED", 0) == 0)
            continue;

         int trade_no = rows[i].trade_no;
         int pos_no   = rows[i].pos_no;
         if(trade_no <= 0 || pos_no <= 0)
            continue;

         string suf = "_" + IntegerToString(trade_no) + "_" + IntegerToString(pos_no);

         string entryName = (rows[i].direction=="LONG") ? (Entry_Long  + suf) : (Entry_Short + suf);
         string slName    = (rows[i].direction=="LONG") ? (SL_Long     + suf) : (SL_Short    + suf);
         string st = rows[i].status;
         StringToUpper(st);



         bool dashed = false;

         // Status-basiert (SEND neu)
         if(StringFind(st, "DRAFT",   0) >= 0)
            dashed = true;
         if(StringFind(st, "PENDING", 0) >= 0)
            dashed = true;
         if(StringFind(st, "SEND",    0) >= 0)
            dashed = true;  // <-- NEU

         // Optional (wenn du was_sent weiter als Fallback willst)
         if(rows[i].was_sent == 0)
            dashed = true;


         ENUM_LINE_STYLE style = (dashed ? STYLE_DASH : STYLE_SOLID);

         double entry_price = rows[i].entry;
         double sl_price    = rows[i].sl;

         TradePosLines_CreateOrUpdate(entryName, entry_price, tf,
                                      StringFormat("E T%d P%d %s", trade_no, pos_no, DoubleToString(rows[i].entry, _Digits)),
                                      (rows[i].direction=="LONG" ? TradeEntryLineLong : TradeEntryLineShort),
                                      1, style,
                                      (rows[i].direction=="LONG" ? TradeEntryLineLong : TradeEntryLineShort),
                                      10, "Arial", "_TAG", 4, 12);

         TradePosLines_CreateOrUpdate(slName, sl_price, tf,
                                      StringFormat("SL T%d P%d %s", trade_no, pos_no, DoubleToString(rows[i].sl, _Digits)),
                                      (rows[i].direction=="LONG" ? Tradecolor_SLLineLong : Tradecolor_SLLineShort),
                                      1, style,
                                      (rows[i].direction=="LONG" ? Tradecolor_SLLineLong : Tradecolor_SLLineShort),
                                      10, "Arial", "_TAG", 4, 12);
        }

      g_tradePosLines.SyncAllTags();
      UI_ApplyZOrder();
      ChartRedraw(0);
     }
   void              CTradeManager::TM_ConsumeGUIRequestsFromDB(const string symbol, const ENUM_TIMEFRAMES tf)
     {
      if(m_db == NULL || CheckPointer(m_db) == POINTER_INVALID)
         return;

      // Direction kommt aus Draft (GUI schreibt die beim LinesChanged)
      string dir = "LONG";
      m_db.GetMetaText(m_db.KeyFor(symbol, tf, "vt.draft.direction"), dir, "LONG");
      StringToUpper(dir);
      if(dir != "LONG" && dir != "SHORT")
         dir = "LONG";

      // Requests lesen
      int has_tr = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "tm.req.has_trnb"), 0);
      int has_po = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "tm.req.has_posnb"), 0);

      int req_tr = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "tm.req.trnb"), 0);
      int req_po = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "tm.req.posnb"), 0);

      bool changed = false;

      // TRNB Request . wir speichern das als "manual trade override" (optional)
      // Ich empfehle: trade_no manuell NICHT global überschreiben,
      // sondern nur als "GUI will das" merken (du nutzt tm.pub.* ohnehin).
      if(has_tr == 1 && req_tr > 0)
        {
         // optional: wenn du trade override willst:
         m_db.SetMetaInt(m_db.KeyFor(symbol, tf, "tm.manual_trnb." + dir), req_tr);
         changed = true;
        }

      // POSNB Request . manual pos override NUR für aktuellen Trade
      if(has_po == 1 && req_po > 0)
        {
         // Wir müssen wissen, auf welchen Trade sich die POS bezieht.
         // Basis: publish erst mal aktuellen Trade ermitteln:
         int active_trade = 0;
         if(dir == "LONG")
            active_trade = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "g_ui_state.active_trade_no_long"), 0);
         else
            active_trade = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "g_ui_state.active_trade_no_short"), 0);

         int last_trade = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "g_ui_state.last_trade_no"), 0);
         if(last_trade < 0)
            last_trade = 0;

         int tr_effective = 1;
         if(has_tr == 1 && req_tr > 0)
            tr_effective = req_tr;
         else if(active_trade > 0)
            tr_effective = active_trade;
         else
            tr_effective = (last_trade > 0 ? last_trade + 1 : 1);

         // manual pos override keys (die hattest du in TM_PublishTradePosToDB schon vorgesehen)
         const string key_manual_pos = m_db.KeyFor(symbol, tf, "tm.manual_posnb." + dir);
         const string key_manual_tr  = m_db.KeyFor(symbol, tf, "tm.manual_posnb_trade." + dir);

         m_db.SetMetaInt(key_manual_pos, req_po);
         m_db.SetMetaInt(key_manual_tr,  tr_effective);
         changed = true;
        }

      // Requests zurücksetzen (wichtig, sonst wird immer wieder konsumiert)
      if(has_tr == 1)
        {
         m_db.SetMetaInt(m_db.KeyFor(symbol, tf, "tm.req.has_trnb"), 0);
         changed = true;
        }
      if(has_po == 1)
        {
         m_db.SetMetaInt(m_db.KeyFor(symbol, tf, "tm.req.has_posnb"), 0);
         changed = true;
        }

      // ganz wichtig: nach Consume wieder publishen,
      // damit GUI sofort die neuen tm.pub.* Werte bekommt
      if(changed)
         TM_PublishTradePosToDB(symbol, tf);
     }



   // Calculates the lot size based on stop loss distance.
   double            calcLots(const string symbol,const ENUM_TIMEFRAMES tf,const double distance)
     {
      // TODO: implement risk management logic
      // For now, return a placeholder value
      // Basic risk management: risk 1% of account equity per trade.
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double riskPercent = 0.01;
      double riskAmount  = equity * riskPercent;
      // Determine tick value and contract size
      double tickSize  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      if(distance <= 0 || tickSize <= 0 || tickValue <= 0)
         return 0.0;
      // pip value per lot: tickValue / tickSize
      double pipValuePerLot = tickValue / tickSize;
      // required volume (lots) = risk amount / (distance * pip value per lot)
      double lots = riskAmount / (distance * pipValuePerLot);
      // Round to the minimum lot step
      double minLot   = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      double lotStep  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      lots = MathMax(minLot, MathFloor(lots / lotStep) * lotStep);
      return lots;
     }




   // Additional methods for updating SL/TP, closing positions, etc.
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTradeManager::PersistToDB(string symbol,const ENUM_TIMEFRAMES tf)
  {
// Kern-State
   m_db.SetMetaInt(m_db.KeyFor(symbol, tf, "g_ui_state.last_trade_no"), g_ui_state.last_trade_no);
   m_db.SetMetaInt(m_db.KeyFor(symbol, tf, "g_ui_state.active_trade_no_long"), g_ui_state.active_trade_no_long);
   m_db.SetMetaInt(m_db.KeyFor(symbol, tf, "g_ui_state.active_trade_no_short"), g_ui_state.active_trade_no_short);

// Linienpreise (Entry/SL/TP) persistieren
   SaveLinePrices(symbol,tf);

// Optional: UI-TradeNr aus dem Eingabefeld sichern
   if(ObjectFind(0, TRNB) >= 0)
     {
      string s = ObjectGetString(0, TRNB, OBJPROP_TEXT);
      int trn = (int)StringToInteger(s);
      m_db.SetMetaInt(m_db.KeyFor(symbol, tf,"trnb_ui"), trn);
     }
  }

//+------------------------------------------------------------------+
//| Mark pending position as OPEN (Entry hit)                        |
//+------------------------------------------------------------------+
bool CTradeManager::MarkPositionOpen(const string symbol,
                                     const ENUM_TIMEFRAMES tf,
                                     const string direction,
                                     const int trade_no,
                                     const int pos_no,
                                     string &out_err)
  {
   out_err = "";

   if(m_db == NULL)
     {
      out_err = "MarkPositionOpen: db not initialized";
      return false;
     }

   DB_PositionRow row;
   bool have_row = m_db.GetPosition(symbol, tf, direction, trade_no, pos_no, row);

   if(have_row)
     {
      // Idempotent: already CLOSED -> no-op
      if(StringFind(row.status, "CLOSED", 0) == 0)
         return true;
      // Idempotent: already OPEN
      if(row.status == "OPEN" && row.is_pending == 0)
        {
         SetPosLinesSolid(direction, trade_no, pos_no);
         Cache_UpdateStatusLocal(symbol, tf,direction, trade_no, pos_no, "OPEN", 0);
         return true;
        }

      if(!m_db.UpdatePositionStatus(symbol, tf, direction, trade_no, pos_no, "OPEN", 0))
        {
         out_err = "MarkPositionOpen: UpdatePositionStatus failed";
         return false;
        }
     }
   else
     {
      // Fallback: Cache . Upsert (should be rare)
      if(!Cache_Get(symbol, tf,direction, trade_no, pos_no, row))
        {
         out_err = "MarkPositionOpen: row not found (db+cache)";
         return false;
        }

      row.status     = "OPEN";
      row.is_pending = 0;
      row.updated_at = TimeCurrent();

      if(!m_db.UpsertPosition(row))
        {
         out_err = "MarkPositionOpen: UpsertPosition failed";
         return false;
        }
     }

// Cache sync
   if(!Cache_UpdateStatusLocal(symbol, tf,direction, trade_no, pos_no, "OPEN", 0))
     {
      if(have_row)
        {
         row.status     = "OPEN";
         row.is_pending = 0;
         row.updated_at = TimeCurrent();
        }
      Cache_UpsertLocal(symbol, tf,row);
     }

// Visual: set trade lines solid
   SetPosLinesSolid(direction, trade_no, pos_no);

   return true;
  }


// ================= PERSIST / RESTORE LINE PRICES (SQLite Meta) =================
void  CTradeManager::SaveLinePrices(const string symbol, const ENUM_TIMEFRAMES tf)

  {
   if(!m_db.IsReady())
      return;

   double p;

// 1) Basislinien wie bisher
   if(ObjectFind(0, PR_HL) >= 0)
     {
      p = ObjectGetDouble(0, PR_HL, OBJPROP_PRICE);

     }

   if(ObjectFind(0, SL_HL) >= 0)
     {
      p = ObjectGetDouble(0, SL_HL, OBJPROP_PRICE);

     }

// 2) Alle Trade-HLines mitspeichern + (für Entry/SL) positions updaten
   int total = ObjectsTotal(0, 0, -1);
   for(int i = 0; i < total; i++)
     {
      string name = ObjectName(0, i, 0, -1);
      if(!UI_IsTradePosLine(name))
         continue;

      // Nur echte HLINEs speichern
      if((ENUM_OBJECT)ObjectGetInteger(0, name, OBJPROP_TYPE) != OBJ_HLINE)
         continue;

      double price = ObjectGetDouble(0, name, OBJPROP_PRICE);

      // 2a) Meta: pro Objektname (stabil, kollisionsfrei)
      m_db.SetMetaText(m_db.KeyFor(symbol, tf,"hline|" + name), DoubleToString(price, _Digits));

      // 2b) Positions-Tabelle: Entry/SL sauber persistieren (damit RestoreTradeLines_All stimmt)
      string direction, kind;
      int trade_no, pos_no;
      if(!UI_ParseTradePosFromName(name, direction, trade_no, pos_no, kind))
         continue; // Objekt ignorieren, nicht alles abbrechen
      if(UI_IsLineTagName(name))
         name = UI_LineTag_GetLineName(name);


      if(kind == "ENTRY" || kind == "SL")
        {
         DB_PositionRow row;
         if(m_db.GetPosition(symbol, tf, direction, trade_no, pos_no, row))
           {
            if(kind == "ENTRY")
               row.entry = price;
            else
               row.sl    = price;

            row.updated_at = TimeCurrent();
            m_db.UpsertPosition(row);
            Cache_UpsertLocal(symbol, tf,row);
           }
        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTradeManager::RestoreFromDB(const string symbol, const ENUM_TIMEFRAMES tf)
  {
   int meta_last = 0, meta_long = 0, meta_short = 0;
   m_db.GetMetaInt(m_db.KeyFor(symbol, tf,"g_ui_state.last_trade_no"), meta_last, 0);
   m_db.GetMetaInt(m_db.KeyFor(symbol, tf,"g_ui_state.active_trade_no_long"), meta_long, 0);
   m_db.GetMetaInt(m_db.KeyFor(symbol, tf,"g_ui_state.active_trade_no_short"), meta_short, 0);

   int max_any = 0;
   int max_open_long = 0;
   int max_open_short = 0;

   Cache_Load(symbol, tf);
   int n = Cache_Size();

   for(int i=0;i<n;i++)
     {
      DB_PositionRow r = g_cache_rows[i]; // aus Cache
      if(r.was_sent != 1)
         continue;

      if(r.trade_no > max_any)
         max_any = r.trade_no;
      if(StringFind(r.status, "CLOSED") == 0)
         continue;

      if(r.direction == "LONG"  && r.trade_no > max_open_long)
         max_open_long  = r.trade_no;
      if(r.direction == "SHORT" && r.trade_no > max_open_short)
         max_open_short = r.trade_no;
     }

   g_ui_state.last_trade_no = MathMax(meta_last, max_any);
   g_ui_state.active_trade_no_long = max_open_long; // kann 0 sein . gut!
   g_ui_state.active_trade_no_short = max_open_short;

   is_long_trade = (g_ui_state.active_trade_no_long > 0);
   is_sell_trade = (g_ui_state.active_trade_no_short > 0);

   m_db.SetMetaInt(m_db.KeyFor(symbol, tf,"g_ui_state.last_trade_no"), g_ui_state.last_trade_no);
   m_db.SetMetaInt(m_db.KeyFor(symbol, tf,"g_ui_state.active_trade_no_long"), g_ui_state.active_trade_no_long);
   m_db.SetMetaInt(m_db.KeyFor(symbol, tf,"g_ui_state.active_trade_no_short"), g_ui_state.active_trade_no_short);
   UI_TradesPanel_RebuildRows();
   TM_PublishTradePosToDB(symbol, tf);
   return true;
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTradeManager::SaveTradeLines(const string suf)
  {
// LONG

   if(ObjectFind(0, SL_Long + suf) >= 0)
      m_db.SetMetaText(m_db.KeyFor(m_ctx.symbol, m_ctx.tf,"L_sl"), DoubleToString(ObjectGetDouble(0, SL_Long + suf, OBJPROP_PRICE), _Digits));
   if(ObjectFind(0, Entry_Long + suf) >= 0)
      m_db.SetMetaText(m_db.KeyFor(m_ctx.symbol, m_ctx.tf,"L_entry"), DoubleToString(ObjectGetDouble(0, Entry_Long + suf, OBJPROP_PRICE), _Digits));

// SHORT

   if(ObjectFind(0, SL_Short + suf) >= 0)
      m_db.SetMetaText(m_db.KeyFor(m_ctx.symbol, m_ctx.tf,"S_sl"), DoubleToString(ObjectGetDouble(0, SL_Short + suf, OBJPROP_PRICE), _Digits));
   if(ObjectFind(0, Entry_Short + suf) >= 0)
      m_db.SetMetaText(m_db.KeyFor(m_ctx.symbol, m_ctx.tf,"S_entry"), DoubleToString(ObjectGetDouble(0, Entry_Short + suf, OBJPROP_PRICE), _Digits));
  }



//+------------------------------------------------------------------+
//| Setzt die angegebene HR Linie als Solid (durchgehende Linie)     |
//+------------------------------------------------------------------+
void CTradeManager::SetPosLinesSolid(const string direction, const int trade_no, const int pos_no)
  {
   string suf = "_" + IntegerToString(trade_no) + "_" + IntegerToString(pos_no);

   if(direction == "LONG")
     {
      string e = Entry_Long + suf;
      string s = SL_Long    + suf;

      if(ObjectFind(0, e) >= 0)
         UI_ObjSetIntSafe(0, e, OBJPROP_STYLE, STYLE_SOLID);
      if(ObjectFind(0, s) >= 0)
         UI_ObjSetIntSafe(0, s, OBJPROP_STYLE, STYLE_SOLID);
     }
   else
      if(direction == "SHORT")
        {
         string e = Entry_Short + suf;
         string s = SL_Short    + suf;

         if(ObjectFind(0, e) >= 0)
            UI_ObjSetIntSafe(0, e, OBJPROP_STYLE, STYLE_SOLID);
         if(ObjectFind(0, s) >= 0)
            UI_ObjSetIntSafe(0, s, OBJPROP_STYLE, STYLE_SOLID);
        }

   ChartRedraw(0); // sofort sichtbar
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ESendDraftResult CTradeManager::SendSignalDraft(const string symbol,
      const ENUM_TIMEFRAMES tf,
      const string direction,
      const int trade_no_input,
      const int pos_no_input,
      const double entry_price,
      const double sl_price,
      const string sabio_entry,
      const string sabio_sl,
      int &io_last_trade_no,
      int &io_active_trade_no,
      bool &io_is_trade_flag,
      int &out_trade_no_effective,
      int &out_pos_no,
      bool &out_starting_new_trade,
      DB_PositionRow &out_row,
      string &out_error)
  {
   out_error              = "";
   out_trade_no_effective = trade_no_input;
   out_pos_no             = 0;
   out_starting_new_trade = false;

   if(m_db == NULL || m_discord == NULL)
     {
      out_error = "deps NULL";
      return SEND_ERR_INVALID;
     }

   if(trade_no_input <= 0 || entry_price <= 0.0 || sl_price <= 0.0)
     {
      out_error = "invalid input";
      return SEND_ERR_INVALID;
     }

// Normalize direction
   string dir = direction;
   StringToUpper(dir);
   if(dir != "LONG" && dir != "SHORT")
      dir = "LONG";

// --- TradeNo bestimmen (AUTO-KORREKTUR wie in DiscordSend)
// --- NEW: globale TradeNo-Basis über LONG+SHORT erzwingen ---
// Problem: Beim Richtungswechsel darf TradeNo nicht wiederverwendet werden.
// Basis ist immer das Maximum aus last_trade_no und beiden active_trade_no_*.
   if(m_db == NULL)
     {
      out_error="db NULL";
      return SEND_ERR_INVALID;
     }
   int meta_last  = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "g_ui_state.last_trade_no"), 0);
   int meta_long  = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "g_ui_state.active_trade_no_long"), 0);
   int meta_short = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "g_ui_state.active_trade_no_short"), 0);

   int base_last = io_last_trade_no;
   base_last = MathMax(base_last, meta_last);
   base_last = MathMax(base_last, meta_long);
   base_last = MathMax(base_last, meta_short);

// io_last_trade_no ist by-ref, damit der Rest der Funktion konsistent bleibt
   io_last_trade_no = base_last;
   int trade_no = trade_no_input;
   int active_trade_no_before = io_active_trade_no;

   if(active_trade_no_before > 0)
     {
      // gleicher Trade erzwingen
      if(trade_no != active_trade_no_before)
         trade_no = active_trade_no_before;
     }
   else
     {
      // nächste Nummer erzwingen, falls User kleiner/gleich last_trade_no
      if(trade_no <= io_last_trade_no)
         trade_no = io_last_trade_no + 1;
     }

   out_trade_no_effective = trade_no;
   out_starting_new_trade = (active_trade_no_before <= 0);

// --- POSNB final bestimmen (Option B): Wunschpos bevorzugen, sonst nächste freie
   int wanted_pos = pos_no_input;
   if(wanted_pos < 1)
      wanted_pos = 1;
   if(wanted_pos > DB_MAX_POS_PER_SIDE)
      wanted_pos = DB_MAX_POS_PER_SIDE;

   bool used[DB_MAX_POS_PER_SIDE+1];
   for(int i=0;i<=DB_MAX_POS_PER_SIDE;i++)
      used[i]=false;

   DB_PositionRow rows[];
   int nrows = m_db.LoadPositions(symbol, tf, rows);
   for(int i=0;i<nrows;i++)
     {
      if(rows[i].direction != dir)
         continue;
      if(rows[i].trade_no  != trade_no)
         continue;
      if(rows[i].pos_no < 1 || rows[i].pos_no > DB_MAX_POS_PER_SIDE)
         continue;
      if(StringFind(rows[i].status, "CLOSED", 0) == 0)
         continue;
      used[rows[i].pos_no] = true;
     }

   int pos_no = 0;
   if(!used[wanted_pos])
      pos_no = wanted_pos;
   else
     {
      for(int p=1;p<=DB_MAX_POS_PER_SIDE;p++)
        {
         if(!used[p])
           {
            pos_no = p;
            break;
           }
        }
     }

   if(pos_no == 0)
     {
      out_error = "max 4 aktive Positionen erreicht (keine freie POSNB)";
      return SEND_ERR_MAXPOS;
     }

   out_pos_no = pos_no;

// --- Draft Row
   DB_PositionRow row;
   row.symbol      = symbol;
   row.tf          = m_db.TFToString(tf);
   row.direction   = dir;
   row.trade_no    = trade_no;
   row.pos_no      = pos_no;
   row.entry       = entry_price;
   row.sl          = sl_price;
   row.sabio_entry = sabio_entry;
   row.sabio_sl    = sabio_sl;
   // Finalen Positionszustand VOR dem irreversiblen Discord-Send persistieren.
   // TradeNo und PosNo stehen zu diesem Zeitpunkt bereits endgültig fest.
   row.status      = "PENDING";
   row.was_sent    = 1;
   row.is_pending  = 1;
   row.updated_at  = TimeCurrent();

   out_row = row;

   if(!m_db.UpsertPosition(row))
     {
      out_error = "DB Fehler: finaler PENDING-Commit vor Discord";
      return SEND_ERR_DB;
     }

   // --- Discord senden
   string msg = m_discord.FormatTradeMessage(row);

   long cid = ChartID();
   int w = (int)ChartGetInteger(cid, CHART_WIDTH_IN_PIXELS, 0);
   int h = (int)ChartGetInteger(cid, CHART_HEIGHT_IN_PIXELS, 0);
   bool ok = m_discord.SendMessageWithChart(symbol, msg, cid, w, h);

   if(!ok)
     {
      // Rollback: Datensatz wieder entfernen, damit die Position nicht
      // als versendet bestehen bleibt und die PosNo wieder frei ist.
      if(!m_db.DeletePosition(symbol, tf, dir, trade_no, pos_no))
        {
         out_error = "Discord Send fehlgeschlagen; DB-Rollback ebenfalls fehlgeschlagen";
         return SEND_ERR_DB;
        }

      out_error = "Discord Send fehlgeschlagen";
      return SEND_ERR_DISCORD;
     }

   // Kein zweiter Positions-Commit nach Discord: DB und Discord verwenden
   // exakt denselben bereits finalisierten Trade-/Positionsschlüssel.
   Cache_UpsertLocal(symbol, tf,row);
   out_row = row;

// --- Meta aktualisieren (identisch zu deiner Logik)
   if(out_starting_new_trade && pos_no == 1 && trade_no > io_last_trade_no)
     {
      io_last_trade_no = trade_no;
      m_db.SetMetaInt(m_db.KeyFor(symbol, tf, "g_ui_state.last_trade_no"), io_last_trade_no);
     }

   if(out_starting_new_trade && pos_no == 1)
     {
      io_active_trade_no = trade_no;
      io_is_trade_flag   = true;

      string key = (dir == "LONG" ? "g_ui_state.active_trade_no_long" : "g_ui_state.active_trade_no_short");
      m_db.SetMetaInt(m_db.KeyFor(symbol, tf, key), io_active_trade_no);
     }

   return SEND_OK;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTradeManager::HandlePositionAction(const string symbol,
      const ENUM_TIMEFRAMES tf,
      const string direction,
      const int trade_no,
      const int pos_no,
      const EPosAction action,
      bool &out_trade_has_pending,
      string &out_err)
  {
   out_err = "";
   out_trade_has_pending = true;

   if(m_db == NULL || m_discord == NULL)
     {
      out_err = "deps NULL";
      return false;
     }

   DB_PositionRow row;
   if(!m_db.GetPosition(symbol, tf, direction, trade_no, pos_no, row))
     {
      out_err = "GetPosition failed (row not found)";
      return false;
     }

   string msg;
   string new_status;

// WICHTIG: Status muss mit "CLOSED" beginnen, sonst brechen Pending/Close-Prüfungen
   if(action == POS_CANCEL)
     {
      // Safety: pos_no==0 ist semantisch ein Trade-Cancel. Dafür gibt es CancelTrade().
      // Falls das hier trotzdem passiert, senden wir die Trade-Message, um Fehlbedienung sichtbar zu machen.
      if(pos_no <= 0)
         msg = m_discord.FormatCancelTradeMessage(row);
      else
         msg = m_discord.FormatCancelPositionMessage(row);

      new_status = "CLOSED_CANCEL";
     }

   else
     {
      msg        = m_discord.FormatSLMessage(row);
      new_status = "CLOSED_SL";
     }

// Idempotent: already CLOSED -> no-op (avoid duplicate Discord + DB flaps)
   if(StringFind(row.status, "CLOSED", 0) == 0)
     {
      int remaining0 = m_db.CountActivePositions(symbol, tf, direction, trade_no);
      out_trade_has_pending = (remaining0 > 0);
      return true;
     }

// Idempotent: already at target status
   if(row.status == new_status && row.is_pending == 0)
     {
      int remaining1 = m_db.CountActivePositions(symbol, tf, direction, trade_no);
      out_trade_has_pending = (remaining1 > 0);
      return true;
     }

// 1) Discord
   if(!m_discord.SendMessage(symbol, msg))
     {
      out_err = "SendMessage failed";
      return false;
     }

// 2) DB Status (is_pending . 0)
   if(!m_db.UpdatePositionStatus(symbol, tf, direction, trade_no, pos_no, new_status, 0))
     {
      out_err = "UpdatePositionStatus failed";
      return false;
     }

// 3) Cache sync (falls nicht gefunden: Row upserten)
   if(!Cache_UpdateStatusLocal(symbol, tf,direction, trade_no, pos_no, new_status, 0))
     {
      row.status     = new_status;
      row.is_pending = 0;
      row.updated_at = TimeCurrent();
      Cache_UpsertLocal(symbol, tf,row);
     }

// 4) Gibt es noch pending/aktive Positionen im selben Trade?
   int remaining = m_db.CountActivePositions(symbol, tf, direction, trade_no);
   out_trade_has_pending = (remaining > 0);

   return true;
  }

//+------------------------------------------------------------------+
//| Cancel active trade (all pending positions) and notify once       |
//+------------------------------------------------------------------+
bool CTradeManager::CancelTrade(const string symbol,
                                const ENUM_TIMEFRAMES tf,
                                const string direction,
                                const int trade_no,
                                string &out_err)
  {
   out_err = "";

   if(m_db == NULL || m_discord == NULL)
     {
      out_err = "CancelTrade: dependencies not initialized (db/discord).";
      return false;
     }
// Idempotent: if nothing left active/pending, do nothing
   int remaining = m_db.CountActivePositions(symbol, tf, direction, trade_no);
   if(remaining <= 0)
      return true;
// 1) Einmalige Cancel-Nachricht senden (Trade-Level)
   DB_PositionRow fake;
   fake.symbol    = symbol;
   fake.tf        = m_db.TFToString(tf);
   fake.direction = direction;
   fake.trade_no  = trade_no;
   fake.pos_no    = 0;
   string msg = m_discord.FormatCancelTradeMessage(fake);
   if(!m_discord.SendMessage(symbol, msg))
     {
      out_err = "CancelTrade: Discord SendMessage failed.";
      return false;
     }

// 2) Alle offenen/pending Positionen dieses Trades schließen
   DB_PositionRow rows[];
   int n = m_db.LoadPositions(symbol, tf, rows);

   for(int i = 0; i < n; i++)
     {
      if(rows[i].direction != direction)
         continue;
      if(rows[i].trade_no  != trade_no)
         continue;
      if(rows[i].pos_no    <= 0)
         continue;
      if(rows[i].is_pending == 0)
         continue;
      if(StringFind(rows[i].status, "CLOSED", 0) == 0)
         continue;

      const string new_status = "CLOSED_CANCEL";

      if(!m_db.UpdatePositionStatus(symbol, tf, direction, trade_no, rows[i].pos_no,
                                    new_status, 0))
        {
         out_err = StringFormat("CancelTrade: UpdatePositionStatus failed (T%d P%d).", trade_no, rows[i].pos_no);
         return false;
        }

      // Cache synchron halten
      if(!Cache_UpdateStatusLocal(symbol, tf,direction, trade_no, rows[i].pos_no, new_status, 0))
        {
         DB_PositionRow r = rows[i];
         r.status     = new_status;
         r.is_pending = 0;
         r.updated_at = TimeCurrent();
         Cache_UpsertLocal(symbol, tf,r);
        }
     }

   return true;
  }
//+------------------------------------------------------------------+
//| TradeManager: Active Trade No per Direction                       |
//+------------------------------------------------------------------+
bool CTradeManager::TM_GetActiveTradeNo(const string symbol, const ENUM_TIMEFRAMES tf,
                                        const string direction, int &out_trade_no)
  {
   out_trade_no = 0;

   if(m_db == NULL || CheckPointer(m_db) == POINTER_INVALID)
      return false;

// Direction normalisieren
   string dir = direction;
   StringToUpper(dir);

   string key = "";
   if(dir == "LONG")
      key = m_db.KeyFor(symbol, tf, "g_ui_state.active_trade_no_long");
   else
      if(dir == "SHORT")
         key = m_db.KeyFor(symbol, tf, "g_ui_state.active_trade_no_short");
      else
         return false;


   int v = m_db.GetMetaInt(key, 0);

   if(v < 0)
      v = 0;
   out_trade_no = v;
   return true;
  }
//+------------------------------------------------------------------+
//| TradeManager: Next Pos No (delegiert an DB)                        |
//+------------------------------------------------------------------+
bool CTradeManager::TM_GetNextPosNo(const string symbol, const ENUM_TIMEFRAMES tf,
                                    const string direction, const int trade_no,
                                    int &out_next_pos_no)
  {
   out_next_pos_no = 1;

   if(trade_no <= 0)
      return false;

   if(m_db == NULL || CheckPointer(m_db) == POINTER_INVALID)
      return false;

   string dir = direction;
   StringToUpper(dir);
   if(dir != "LONG" && dir != "SHORT")
      return false;

   int nextPos = m_db.GetNextPosNo(symbol, tf, dir, trade_no);
   if(nextPos < 1)
      nextPos = 1;

   out_next_pos_no = nextPos;
   return true;
  }
//+------------------------------------------------------------------+
//| TradeManager: Last Trade No (per Symbol/TF)                        |
//+------------------------------------------------------------------+
bool CTradeManager::TM_GetLastTradeNo(const string symbol, const ENUM_TIMEFRAMES tf,
                                      int &out_last_trade_no)
  {
   out_last_trade_no = 0;

   if(m_db == NULL || CheckPointer(m_db) == POINTER_INVALID)
      return false;

   const string key = m_db.KeyFor(symbol, tf, "g_ui_state.last_trade_no");

   int v = m_db.GetMetaInt(key, 0);

   if(v < 0)
      v = 0;
   out_last_trade_no = v;
   return true;
  }
//+------------------------------------------------------------------+
//| TradeManager: Set Last Trade No (per Symbol/TF)                    |
//+------------------------------------------------------------------+
bool CTradeManager::TM_SetLastTradeNo(const string symbol, const ENUM_TIMEFRAMES tf,
                                      const int last_trade_no)
  {
   if(m_db == NULL || CheckPointer(m_db) == POINTER_INVALID)
      return false;

   int v = last_trade_no;
   if(v < 0)
      v = 0;

   const string key = m_db.KeyFor(symbol, tf, "g_ui_state.last_trade_no");
   m_db.SetMetaInt(key, v);
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTradeManager::TM_PublishTradePosToDB(const string symbol, const ENUM_TIMEFRAMES tf)
  {
   if(m_db == NULL || CheckPointer(m_db) == POINTER_INVALID)
      return;

// Direction kommt aus dem Draft (GUI schreibt das)
   string dir = "LONG";
   m_db.GetMetaText(m_db.KeyFor(symbol, tf, "vt.draft.direction"), dir, "LONG");
   StringToUpper(dir);
   if(dir != "LONG" && dir != "SHORT")
      dir = "LONG";

// Active trade je Direction (Master aus UI-State/DB)
   int active_trade = 0;
   if(dir == "LONG")
      active_trade = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "g_ui_state.active_trade_no_long"), 0);
   else
      active_trade = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "g_ui_state.active_trade_no_short"), 0);

   int last_trade = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "g_ui_state.last_trade_no"), 0);
   if(last_trade < 0)
      last_trade = 0;

   int trnb_effective = 1;
   int posnb_effective = 1;

   if(active_trade > 0)
     {
      trnb_effective = active_trade;

      posnb_effective = m_db.GetNextPosNo(symbol, tf, dir, trnb_effective);
      if(posnb_effective < 1)
         posnb_effective = 1;
     }
   else
     {
      trnb_effective  = (last_trade > 0 ? last_trade + 1 : 1);
      posnb_effective = 1;
     }

// Manual TRNB override (falls gesetzt)
   const string key_manual_trnb = m_db.KeyFor(symbol, tf, "tm.manual_trnb." + dir);
   const int manual_trnb = m_db.GetMetaInt(key_manual_trnb, 0);
   if(manual_trnb > 0)
     {
      trnb_effective = manual_trnb;
      posnb_effective = m_db.GetNextPosNo(symbol, tf, dir, trnb_effective);
      if(posnb_effective < 1)
         posnb_effective = 1;
     }

// Optional: Manual POS override (falls gesetzt)
   string key_manual_pos = m_db.KeyFor(symbol, tf, "tm.manual_posnb." + dir);
   string key_manual_tr  = m_db.KeyFor(symbol, tf, "tm.manual_posnb_trade." + dir);

   int manual_pos = m_db.GetMetaInt(key_manual_pos, 0);
   int manual_tr  = m_db.GetMetaInt(key_manual_tr, 0);

   if(manual_pos > 0 && manual_tr == trnb_effective)
      posnb_effective = manual_pos;

// Publish für GUI
   m_db.SetMetaText(m_db.KeyFor(symbol, tf, "tm.pub.direction"), dir);
   m_db.SetMetaInt(m_db.KeyFor(symbol, tf, "tm.pub.trnb"), trnb_effective);
   m_db.SetMetaInt(m_db.KeyFor(symbol, tf, "tm.pub.posnb"), posnb_effective);

   int rev = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "tm.pub.rev"), 0);
   m_db.SetMetaInt(m_db.KeyFor(symbol, tf, "tm.pub.rev"), rev + 1);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool             CTradeManager::UI_CloseOnePositionAndNotify(const string symbol,
      const ENUM_TIMEFRAMES tf,
      const string action,
      const string direction,
      const int trade_no,
      const int pos_no)
  {



// 1) Business-Teil (Discord + DB + Cache + Remaining-Check) . TradeManager
   bool has_pending = true;
   string err = "";

   EPosAction act =
      (action == "CANCEL" ? POS_CANCEL : POS_HIT_SL);

   if(!HandlePositionAction(symbol, tf,
                            direction, trade_no, pos_no,
                            act, has_pending, err))
     {
      CLogger::Add(LOG_LEVEL_WARNING, "HandlePositionAction failed: " + err);
      return false;
     }

// 2) UI-Linien/Tags dieser Position entfernen (wie bisher)
   string suf_tp = "_" + IntegerToString(trade_no) + "_" + IntegerToString(pos_no);

   TradePosLines_DeleteTradePos(direction, trade_no, pos_no);



// 3) Falls letzte pending Position . Runtime + Meta zurücksetzen
   if(!has_pending)
     {
      if(direction == "LONG")
        {
         if(g_ui_state.active_trade_no_long == trade_no)
           {
            g_ui_state.active_trade_no_long = 0;
            g_DB.SetMetaInt(g_DB.KeyFor(symbol, tf,"g_ui_state.active_trade_no_long"), 0);
           }

         is_long_trade     = false;
         HitEntryPriceLong = false;

         if(ObjectFind(0, "ActiveLongTrade") >= 0)
           {
            UI_ObjSetIntSafe(0, "ActiveLongTrade", OBJPROP_COLOR, clrNONE);
            UI_ObjSetIntSafe(0, "ActiveLongTrade", OBJPROP_BGCOLOR, clrNONE);
           }
        }
      else
        {
         if(g_ui_state.active_trade_no_short == trade_no)
           {
            g_ui_state.active_trade_no_short = 0;
            g_DB.SetMetaInt(g_DB.KeyFor(symbol, tf,"g_ui_state.active_trade_no_short"), 0);
           }

         is_sell_trade         = false;
         is_sell_trade_pending = false;
         HitEntryPriceShort    = false;

         if(ObjectFind(0, "ActiveShortTrade") >= 0)
           {
            UI_ObjSetIntSafe(0, "ActiveShortTrade", OBJPROP_COLOR, clrNONE);
            UI_ObjSetIntSafe(0, "ActiveShortTrade", OBJPROP_BGCOLOR, clrNONE);
           }
        }
     }

// 4) UI Refresh
   UI_ProcessRedraw();
   g_tp.RequestRebuild();

   g_tp.ProcessRebuild();
   UI_ApplyZOrder();       // <-- HIER
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTradeManager::TM_SendFromDraft(const string symbol,
                                     const ENUM_TIMEFRAMES tf,
                                     STMSendFromDraftResult &out)
  {

   string e_s = "";
   string s_s = "";
   m_db.GetMetaText(m_db.KeyFor(symbol, tf, "vt.draft.entry_price"), e_s, "NA");
   m_db.GetMetaText(m_db.KeyFor(symbol, tf, "vt.draft.sl_price"),    s_s, "NA");
   Print("TM_SendFromDraft read entry=", e_s, " sl=", s_s, " sym=", symbol, " tf=", (int)tf);
   out.ok = false;
   out.error = "";
   out.direction = "LONG";
   out.trade_no_input = 1;
   out.pos_no_input   = 1;
   out.trade_no_effective = 0;
   out.pos_no_effective   = 0;
   out.starting_new_trade = false;

   if(m_db == NULL || m_discord == NULL)
     {
      out.error = "deps NULL (db/discord)";
      return false;
     }

// --- 1) Draft lesen (Option B)
   string dir="LONG", entry_s="0", sl_s="0", sabE="", sabS="", tr_s="1", po_s="1";
   m_db.GetMetaText(m_db.KeyFor(symbol, tf, "vt.draft.direction"), dir, "LONG");
   m_db.GetMetaText(m_db.KeyFor(symbol, tf, "vt.draft.entry_price"), entry_s, "0");
   m_db.GetMetaText(m_db.KeyFor(symbol, tf, "vt.draft.sl_price"), sl_s, "0");
   m_db.GetMetaText(m_db.KeyFor(symbol, tf, "vt.draft.sabio_entry_text"), sabE, "");
   m_db.GetMetaText(m_db.KeyFor(symbol, tf, "vt.draft.sabio_sl_text"), sabS, "");
   m_db.GetMetaText(m_db.KeyFor(symbol, tf, "vt.draft.trnb"), tr_s, "1");
   m_db.GetMetaText(m_db.KeyFor(symbol, tf, "vt.draft.posnb"), po_s, "1");

   StringToUpper(dir);
   if(dir != "LONG" && dir != "SHORT")
      dir = "LONG";

   StringTrimLeft(tr_s);
   StringTrimRight(tr_s);
   StringTrimLeft(po_s);
   StringTrimRight(po_s);

   int trade_no_in = (int)StringToInteger(tr_s);
   int pos_no_in   = (int)StringToInteger(po_s);
   if(trade_no_in < 1)
      trade_no_in = 1;
   if(pos_no_in   < 1)
      pos_no_in   = 1;

   if(pos_no_in > DB_MAX_POS_PER_SIDE)
      pos_no_in = DB_MAX_POS_PER_SIDE;

   double entry = StringToDouble(entry_s);
   double sl    = StringToDouble(sl_s);

   out.direction = dir;
   out.trade_no_input = trade_no_in;
   out.pos_no_input   = pos_no_in;

// Basic validation
   if(entry <= 0.0 || sl <= 0.0)
     {
      out.error = "draft invalid: entry/sl <= 0";
      return false;
     }

// --- 2) UI-State laden (Engine erwartet io-Parameter)
   int io_last_trade_no = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "g_ui_state.last_trade_no"), 0);

   int io_active_trade_no = 0;
   if(dir == "LONG")
      io_active_trade_no = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "g_ui_state.active_trade_no_long"), 0);
   else
      io_active_trade_no = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "g_ui_state.active_trade_no_short"), 0);

   bool io_is_trade_flag = (dir == "LONG" ? is_long_trade : is_sell_trade);

// --- 3) Engine call (SendSignalDraft)
   string err="";
   int out_trade_no_eff=0, out_pos_no=0;
   bool out_starting=false;
   DB_PositionRow out_row;

   ESendDraftResult r = SendSignalDraft(symbol, tf, dir,
                                        trade_no_in,
                                        pos_no_in,          // <-- NEU
                                        entry, sl,
                                        sabE, sabS,
                                        io_last_trade_no,
                                        io_active_trade_no,
                                        io_is_trade_flag,
                                        out_trade_no_eff,
                                        out_pos_no,
                                        out_starting,
                                        out_row,
                                        err);

   m_db.SetMetaText(m_db.KeyFor(symbol, tf, "vt.draft.trnb"), IntegerToString(out_trade_no_eff));
   m_db.SetMetaText(m_db.KeyFor(symbol, tf, "vt.draft.posnb"), IntegerToString(out_pos_no));

   if(r != SEND_OK)
     {
      out.error = err;
      return false;
     }

// --- 4) TradeNo und PosNo sind bereits in SendSignalDraft finalisiert.
   // Nach Discord darf keine Umnummerierung und kein DB-Move mehr passieren.
   int final_trade = out_trade_no_eff;
   int final_pos   = out_pos_no;

   // Draft zurückschreiben: GUI zeigt exakt die tatsächlich gesendeten Nummern.
   m_db.SetMetaText(m_db.KeyFor(symbol, tf, "vt.draft.trnb"), IntegerToString(final_trade));
   m_db.SetMetaText(m_db.KeyFor(symbol, tf, "vt.draft.posnb"), IntegerToString(final_pos));

   out.ok = true;
   out.trade_no_effective = final_trade;
   out.pos_no_effective   = final_pos;
   out.starting_new_trade = out_starting;
   out.row = out_row;

   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTradeManager::TM_HandleTradePosEditCommit(const string symbol,
                                                  const ENUM_TIMEFRAMES tf,
                                                  const string field,
                                                  const int value)
  {
   if(m_db == NULL || CheckPointer(m_db) == POINTER_INVALID)
      return false;
   if(value <= 0)
      return false;

   if(field == TRNB)
     {
      m_db.SetMetaInt(m_db.KeyFor(symbol, tf, "tm.req.trnb"), value);
      m_db.SetMetaInt(m_db.KeyFor(symbol, tf, "tm.req.has_trnb"), 1);
      m_db.SetMetaInt(m_db.KeyFor(symbol, tf, "vt.draft.trnb_user"), 1);
     }
   else
      if(field == POSNB)
        {
         m_db.SetMetaInt(m_db.KeyFor(symbol, tf, "tm.req.posnb"), value);
         m_db.SetMetaInt(m_db.KeyFor(symbol, tf, "tm.req.has_posnb"), 1);
         m_db.SetMetaInt(m_db.KeyFor(symbol, tf, "vt.draft.posnb_user"), 1);
        }
      else
         return false;

   int rev = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "tm.req.rev"), 0);
   m_db.SetMetaInt(m_db.KeyFor(symbol, tf, "tm.req.rev"), rev + 1);

   TM_ConsumeGUIRequestsFromDB(symbol, tf);

   g_vgui.ApplyTradePosFromDBToEdits();
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTradeManager::TM_HandleSendTradeClick(const string symbol,
      const ENUM_TIMEFRAMES tf,
      STMSendFromDraftResult &out)
  {
   out = STMSendFromDraftResult();

// Aktuellen GUI-Draft persistieren
   g_vgui.FlushDraft();

   if(!TM_SendFromDraft(symbol, tf, out))
      return false;

// GUI-/Meta-Publish nach erfolgreichem Send
   TM_PublishTradePosToDB(symbol, tf);
   g_vgui.ApplyTradePosFromDBToEdits();

// Panel + Linien refresh
   g_tp.RebuildRows();
   RestoreTradePosLines(symbol, tf);
   UI_ApplyZOrder();
   ChartRedraw(0);

   return true;
  }
bool CTradeManager::TM_SendSignal(const string symbol,
                                  const ENUM_TIMEFRAMES tf,
                                  const string direction,
                                  const int trade_no_input,
                                  const int pos_no_input,
                                  const double entry,
                                  const double sl,
                                  const string sabio_entry,
                                  const string sabio_sl,
                                  STMSendFromDraftResult &out)
  {
   out.ok = false;
   out.error = "";
   out.direction = direction;
   out.trade_no_input = trade_no_input;
   out.pos_no_input   = pos_no_input;
   out.trade_no_effective = 0;
   out.pos_no_effective   = 0;
   out.starting_new_trade = false;

   if(m_db == NULL || m_discord == NULL)
     {
      out.error = "deps NULL (db/discord)";
      return false;
     }

   string dir = direction;
   StringToUpper(dir);
   if(dir != "LONG" && dir != "SHORT")
      dir = "LONG";

   int trade_no_in = trade_no_input;
   int pos_no_in   = pos_no_input;
   if(trade_no_in < 1)
      trade_no_in = 1;
   if(pos_no_in < 1)
      pos_no_in = 1;
   if(pos_no_in > DB_MAX_POS_PER_SIDE)
      pos_no_in = DB_MAX_POS_PER_SIDE;

   out.direction = dir;
   out.trade_no_input = trade_no_in;
   out.pos_no_input   = pos_no_in;

   if(entry <= 0.0 || sl <= 0.0)
     {
      out.error = "invalid input: entry/sl <= 0";
      return false;
     }

   int io_last_trade_no = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "g_ui_state.last_trade_no"), 0);
   int io_active_trade_no = 0;
   if(dir == "LONG")
      io_active_trade_no = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "g_ui_state.active_trade_no_long"), 0);
   else
      io_active_trade_no = m_db.GetMetaInt(m_db.KeyFor(symbol, tf, "g_ui_state.active_trade_no_short"), 0);

   bool io_is_trade_flag = (dir == "LONG" ? is_long_trade : is_sell_trade);

   string err = "";
   int out_trade_no_eff = 0;
   int out_pos_no = 0;
   bool out_starting = false;
   DB_PositionRow out_row;

   ESendDraftResult r = SendSignalDraft(symbol, tf, dir,
                                        trade_no_in,
                                        pos_no_in,
                                        entry, sl,
                                        sabio_entry, sabio_sl,
                                        io_last_trade_no,
                                        io_active_trade_no,
                                        io_is_trade_flag,
                                        out_trade_no_eff,
                                        out_pos_no,
                                        out_starting,
                                        out_row,
                                        err);

   m_db.SetMetaText(m_db.KeyFor(symbol, tf, "vt.draft.trnb"), IntegerToString(out_trade_no_eff));
   m_db.SetMetaText(m_db.KeyFor(symbol, tf, "vt.draft.posnb"), IntegerToString(out_pos_no));

   if(r != SEND_OK)
     {
      out.error = err;
      return false;
     }

   out.ok = true;
   out.trade_no_effective = out_trade_no_eff;
   out.pos_no_effective   = out_pos_no;
   out.starting_new_trade = out_starting;
   out.row = out_row;
   return true;
  }
  
#endif // __TRADE_MANAGER_MQH_
//+------------------------------------------------------------------+
