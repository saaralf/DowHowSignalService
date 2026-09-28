#ifndef __TRADE_DRAFT_MQH__
#define __TRADE_DRAFT_MQH__

#include "context.mqh"

struct SDraftSnapshot
  {
   string direction;
   double entry;
   double sl;
   string sabio_entry;
   string sabio_sl;
   string trnb;
   string posnb;
   bool   sabio_entry_user;
   bool   sabio_sl_user;
  };

// Bridge: GUI liefert nur Daten; Persistenz wird im TradeManager umgesetzt.
bool TM_PersistDraftIntent(const SContext &ctx, const SDraftSnapshot &draft);

#endif // __TRADE_DRAFT_MQH__
