//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include "Discord.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CVirtualTrade
  {

private:
   
   CDiscord my_Discord;
   int               m_trade_id;                // Eindeutige ID
   string            m_type;                 // "buy" oder "sell"
   string            m_symbol;               // Symbol des Charts
   ENUM_TIMEFRAMES   m_timeframe;   // Zeitrahmen des Charts
   double            m_entry_price;          // Einstiegspreis
   double            m_stop_loss;            // SL
   double            m_take_profit;          // TP
   bool              m_tp_sent;                // TP erreicht (Discord gesendet)
   bool              m_sl_sent;                // SL erreicht (Discord gesendet)
   bool              m_closed;                 // Virtuell geschl

public:

                     CVirtualTrade();
                     ~CVirtualTrade();
                     CVirtualTrade(const CVirtualTrade &){};



   bool              Create(const int trade_id,const string type,const string symbol,const ENUM_TIMEFRAMES timeframe, const  double entry_price,const double stop_loss,const  double take_profit, const  bool tp_sent =false,const bool sl_sent = false,const bool closed =false);
   void              setPrices(double Entry_Price, double TP_Price,  double SL_Price);
   bool              CloseVirtualTrade();
   string            FormatTradeMessage();

   void              setDicord(CDiscord &my_Discord);

   string            FormatSLMessage();
   string            FormatTPMessage();
   string            FormatCancelTradeMessage();
   string            FormatUpdateTradeMessage();

protected:


  };
void CVirtualTrade::setDicord(CDiscord &my_Discord){

   my_Discord = my_Discord;
}
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CVirtualTrade::CVirtualTrade(void)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CVirtualTrade::~CVirtualTrade(void)
  {
  }
//+------------
//+------------------------------------------------------------------+
//| Virtuelle Trades erstellen                                       |
//+------------------------------------------------------------------+
bool CVirtualTrade::Create(const int trade_id,const string type,const string symbol,const ENUM_TIMEFRAMES timeframe, const  double entry_price,const double stop_loss,const  double take_profit, const  bool tp_sent =false,const bool sl_sent = false,const bool closed =false)
  {


   m_trade_id = trade_id;
   m_type = type;
   m_symbol = symbol;
   m_timeframe = timeframe;
   m_entry_price = entry_price;
   m_stop_loss = stop_loss;
   m_take_profit = take_profit;
   m_tp_sent = false;
   m_sl_sent = false;
   m_closed = false;
   my_Discord.create("");
   my_Discord.setWebhook();
   my_Discord.checkDiscord();
   my_Discord.toString();

   Print("Virtueller ", m_type, "-Trade erstellt: ID=", m_trade_id);
   return true;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CVirtualTrade::FormatTradeMessage()
  {
   string
   message = "@everyone\n";
   message += ":red_circle:TRADINGSIGNAL: :red_circle:\n";
   message += "\n";
   message +="----------[Trade Nr. "+m_trade_id+"]----------\n";
   message += "\n";
   if(m_type=="buy")
     {
      message += ":chart_with_upwards_trend: **" + m_type + ":** ";
     }
   else
     {
      message += ":chart_with_downwards_trend: **" + m_type + ":** ";
     }
   message += "**Symbol:** "+m_symbol + " "+ m_timeframe+ "\n";
   message += ":arrow_right: **Entry:** " + DoubleToString(m_entry_price, _Digits) + "\n";
   message += "\n";
   message += ":orange_circle: **SL:** " + DoubleToString(m_stop_loss, _Digits) + "\n";
   message += ":dollar: **TP:** " + DoubleToString(m_take_profit, _Digits) + "\n";



//   message += "Uhrzeit der Meldung: " + TimeToString(TimeCurrent());
   return message;

//string message ="@everyone \\n\\n----------[Trade Nr. 88]----------\\n:chart_with_downwards_trend: **Sell: DAX40 M5**:arrow_right: **Entry:** 123456 (Sabio: 12345):orange_circle: **SL:** 123456 (Sabio: 12345):dollar: **TP:** 123456 (Sabio: 12345)";
  }

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Virtuelle Trades wegen TP erreichtschließen                                       |
//+------------------------------------------------------------------+
bool CVirtualTrade::CloseVirtualTrade()
  {
   if(!m_closed)
     {
      m_closed= true;
      m_tp_sent=true;

      string message = FormatTPMessage();
      bool ret= my_Discord.SendDiscordMessage(message);

      //buy_trade_exists = false;
      return true;
     }
   Print("Fehler bei CloseVirtualTrade: VirtualTrade ist schon geschlossen");
   return false;
  }







//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CVirtualTrade::FormatSLMessage()
  {
   string  message = "@everyone\n";
   message += "**Note:** "+m_symbol+" Trade "+m_trade_id+" - has been stopped out\n";

   return message;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CVirtualTrade::FormatTPMessage()
  {
   string  message = "@everyone\n";
   message += "**Note:** "+m_symbol+" Trade "+m_trade_id+" - target reached :dollar: \n";

   return message;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CVirtualTrade::FormatCancelTradeMessage()
  {
   string  message = "@everyone\n";
   message += "**Attention:** "+m_symbol+" Trade "+m_trade_id+" - cancel the order cause trend is broken\n";

   return message;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CVirtualTrade::FormatUpdateTradeMessage()
  {
   string  message = "@everyone\n";
//message += "**Attention:** "+trade.symbol+" Trade "+trade_id+" - I trail my SL price down to "+stop_loss+" (Sabio: "+tradeInfo.sl+") - Target new: "+tp+" (Sabio:  "+tp +")\n";

   return message;
  }





// Struktur für virtuelle Trades
/*
struct VirtualTrade
  {
   int               trade_id;                // Eindeutige ID
   string            type;                 // "buy" oder "sell"
   string            symbol;               // Symbol des Charts
   ENUM_TIMEFRAMES   timeframe;   // Zeitrahmen des Charts
   double            entry_price;          // Einstiegspreis
   double            stop_loss;            // SL
   double            take_profit;          // TP
   bool              tp_sent;                // TP erreicht (Discord gesendet)
   bool              sl_sent;                // SL erreicht (Discord gesendet)
   bool              closed;                 // Virtuell geschlossen
  };

// Globale Variablen
int trade_counter;                          // Zähler für Trades
bool buy_trade_exists = false, sell_trade_exists = false;  // Status
//VirtualTrade last_buy_trade, last_sell_trade;   // Letzter Buy/Sell-Trade

*/
//+------------------------------------------------------------------+
