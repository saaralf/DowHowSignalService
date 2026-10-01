#ifndef TA4_TYPES_MQH
#define TA4_TYPES_MQH
// Shared contracts. These types do not depend on UI, SQLite or Discord.
enum TA4_RiskMode { TA4_RISK_MONEY=0, TA4_RISK_EQUITY_PERCENT=1 };
struct TA4_Context { string key; string symbol; ENUM_TIMEFRAMES tf; int digits; long chart; string owner; };
struct TA4_Settings { TA4_RiskMode risk_mode; double risk_value; bool sabio_visible; bool sabio_send; bool tp_enabled; bool mention; };
struct TA4_Draft { double entry; double sl; double tp; string sabio_entry; string sabio_sl; bool entry_override; bool sl_override; };
struct TA4_Position { long trade_no; long pos_no; string direction; string status; double entry; double sl; double tp; double lots; string sabio_entry; string sabio_sl; };
struct TA4_Command { string kind; string direction; long trade_no; long pos_no; double price; TA4_Draft draft; };
struct TA4_Outbox { long id; string event_id; string state; string message; string image; int attempts; };
string TA4_Direction(const TA4_Draft &d) { return d.sl<=d.entry ? "LONG" : "SHORT"; }
bool TA4_Active(const string status) { return status=="PENDING" || status=="OPEN"; }
string TA4_Price(const TA4_Context &ctx,const double p) { return DoubleToString(p,ctx.digits); }
string TA4_TF(const ENUM_TIMEFRAMES tf) { string s=EnumToString(tf); StringReplace(s,"PERIOD_",""); return s; }
double TA4_Normalize(const string symbol,const double p)
  { double t=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE); return t>0 ? NormalizeDouble(MathRound(p/t)*t,(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS)) : 0; }
#endif
