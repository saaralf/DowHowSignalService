// trade_manager.mqh
//
// This class encapsulates the business logic for trade management.
// It uses the CDBService to store draft and active positions and
// uses the CDiscordClient to send notifications.

#ifndef __TRADE_MANAGER_MQH_
#define __TRADE_MANAGER_MQH_

#include "db_service.mqh"
#include "discord_client.mqh"
#include "logger.mqh"

class CTradeManager
  {
private:
   CDBService     *m_db;
   CDiscordClient *m_discord;
   CConfig        *m_config;

   int m_nextTradeNo; // Next trade number to assign
   int m_nextPosNo;   // Next position number to assign

public:
   CTradeManager() : m_db(NULL), m_discord(NULL), m_config(NULL) {}

   // Initialise dependencies.  This must be called before use.
   void Init(CDBService *db, CDiscordClient *discord, CConfig *cfg)
     {
      m_db      = db;
      m_discord = discord;
      m_config  = cfg;
      // initialise counters
      m_nextTradeNo = 1;
      m_nextPosNo   = 1;
     }

   // Calculates the lot size based on stop loss distance.
   double CalcLots(const double distance)
     {
      // TODO: implement risk management logic
      // For now, return a placeholder value
      // Basic risk management: risk 1% of account equity per trade.
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double riskPercent = 0.01;
      double riskAmount  = equity * riskPercent;
      // Determine tick value and contract size
      double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      if(distance <= 0 || tickSize <= 0 || tickValue <= 0)
         return 0.0;
      // pip value per lot: tickValue / tickSize
      double pipValuePerLot = tickValue / tickSize;
      // required volume (lots) = risk amount / (distance * pip value per lot)
      double lots = riskAmount / (distance * pipValuePerLot);
      // Round to the minimum lot step
      double minLot   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double lotStep  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      lots = MathMax(minLot, MathFloor(lots / lotStep) * lotStep);
      return lots;
     }

   // Creates a draft position in the database and sends a Discord
   // notification.  Returns true on success.
   bool CreateDraft(const string direction, const double entry,
                    const double sl)
     {
      if(m_db == NULL || m_discord == NULL)
        {
         CLogger::Add(LOG_LEVEL_ERROR,
                      "TradeManager: dependencies not initialised");
         return false;
        }
      // Build a position record (simplified)
      DB_PositionRow row;
      row.symbol    = _Symbol;
      row.tf        = TF_ToString((ENUM_TIMEFRAMES)_Period);
      row.direction = direction;
      // Assign trade and position numbers
      row.trade_no  = m_nextTradeNo;
      row.pos_no    = m_nextPosNo;
      m_nextPosNo++;
      // If this is a new symbol/timeframe/direction, increment trade number
      // In a real implementation, you might look up existing positions
      // from the DB to decide numbering.
      row.entry     = entry;
      row.sl        = sl;
      row.status    = "DRAFT";
      row.was_sent  = 0;
      row.is_pending= 1;
      row.updated_at= TimeCurrent();

      // Write to DB
      if(!m_db.UpsertPosition(row))
        {
         CLogger::Add(LOG_LEVEL_ERROR, "TradeManager: failed to write draft");
         return false;
        }
      // Send message
      string msg = m_discord.FormatTradeMessage(row);
      if(!m_discord.SendMessage(row.symbol, msg))
        {
         CLogger::Add(LOG_LEVEL_ERROR, "TradeManager: failed to send draft");
         return false;
        }
      // Update status
      row.status   = "PENDING";
      row.was_sent = 1;
      row.is_pending = 1;
      row.updated_at = TimeCurrent();
      m_db.UpsertPosition(row);
      // Increment trade number for next trade
      m_nextTradeNo++;
      return true;
     }

   // Additional methods for updating SL/TP, closing positions, etc.
  };

#endif // __TRADE_MANAGER_MQH_