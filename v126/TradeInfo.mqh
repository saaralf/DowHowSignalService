#ifndef DH126_TRADE_INFO
#define DH126_TRADE_INFO
struct TradeInfo
  {
   int               tradenummer;
   int               position;
   string            symbol;
   string            type;
   double            price;
   double            lots;
   double            sl;
   //   double            tp;
   string            sabioentry;
   string            sabiosl;
   //   string            sabiotp;
   bool              was_send;
   bool              is_trade_pending;
  };
#endif
