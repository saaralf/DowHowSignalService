#ifndef __UI_STATE_MQH__
#define __UI_STATE_MQH__

class SUIState
{
public:
   string         symbol;
   ENUM_TIMEFRAMES tf;

   bool           is_long;

   int            last_trade_no;
   int            active_long_trade_no;
   int            active_short_trade_no;

   SUIState()
   {
      symbol="";
      tf=PERIOD_CURRENT;
      is_long=true;
      last_trade_no=0;
      active_long_trade_no=0;
      active_short_trade_no=0;
   }

   void SetSymbolTf(const string s, const ENUM_TIMEFRAMES t)
   {
      symbol=s;
      tf=t;
   }

   void UpdateDirectionFromPrices(const double entry, const double sl)
   {
      is_long = (sl < entry);
   }

   int ActiveTradeNo() const
   {
      return is_long ? active_long_trade_no : active_short_trade_no;
   }

   string DirectionStr() const
   {
      return is_long ? "LONG" : "SHORT";
   }
};

#endif
