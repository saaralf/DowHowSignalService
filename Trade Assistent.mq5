//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
/*
feat: Major optimization - v1.04.18

- Trade number: string → int with validation
- Risk management: Enhanced calcLots() with error handling
- Memory: Fixed leaks, complete object cleanup
- Errors: Professional error system with German messages
- Discord: Configurable webhooks per timeframe + fallback

Bug fixes:
- Fixed undefined variables
- Corrected type conversions
- Resolved memory leaks




## 🎯 What's Next (Roadmap)
- [ ] Trade History System (CSV tracking)
- [ ] MT5 History Synchronization
- [ ] Statistics Dashboard
- [ ] Multi-Symbol Support
- [ ] Automated Backup System
*/

#property copyright "Michael Keller, Steffen Kachold"
#property link ""
#property version "02.00.0"
int tradenummer = 0;
#include <Trade\Trade.mqh>
CTrade trade;
#include <Controls\Dialog.mqh>
CAppDialog SabioConfirmation;


#include "discord.mqh" // alles rund ums senden an Discord
#include "LabelundMessageButton.mqh" // Label für die Message Button

// Default values for settings:
double EntryLevel = 0;
double StopLossLevel = 0;
double TakeProfitLevel = 0;
double StopPriceLevel = 0;

// only one button is visible
input group "===== Defaults ====="
input bool SendOnlyButton = true;   // Send only (true) or Trade & Send (false)
input bool Sabioedit = true;  // Sabio Prices Edit visible
input bool SabioPrices = true;   // Sabio Prices already insert (true) or not (false)
input bool MessageBoxSound = true;
input bool ShowTPButton = true;          // TP Button sichtbar (JA/NEIN)
input group "===== Discord Webhook URLs ====="
input string WebhookM1 = "";     // Discord Webhook URL für M1
input string WebhookM2 = "";     // Discord Webhook URL für M2
input string WebhookM5 = "";     // Discord Webhook URL für M5
input string WebhookM10 = "";     // Discord Webhook URL für M10
input string WebhookM15 = "";     // Discord Webhook URL für M15
input string WebhookM30 = "";     // Discord Webhook URL für M30
input string WebhookH1 = "";     // Discord Webhook URL für H1
input string WebhookDefault = ""; // Discord Webhook URL Standard (Fallback)

input group "===== Discord Settings ====="
input string DiscordBotName = "DowHow Trading Signalservice";    // Name of the bot in Discord
input color MessageColor = clrBlue;                 // Color for Discord messages

input group "=====Money Management====="
input int riskMoney = 250;                                        // Risk Amount in Account Currency

input group "====== Message Button and Label ======"
input color ButtonCancelOrder_bgcolor = clrLightGray; // Button Cancel Order  Color
input color ButtonCancelOrder_font_color = clrBlack;  // Button Cancel Order  Font Color
input uint ButtonCancelOrder_font_size = 8;  // Button Cancel Order  Font Size
input color InfoLabelFontSize_bgcolor = clrRed; // Info Label  Color
input color InfoLabelFontSize_font_color = clrWhite;  // Info Label  Font Color
input uint InfoLabelFontSize = 8;   // Info Label  Font Size

input group "===== Button ====="
input color TPButton_bgcolor = clrGreen;  // TP Button   Color
input color TPButton_font_color = clrWhite;  // TP Button   Font Color
input uint TPButton_font_size = 8;  // TP Button   Font Size
input int TPButtonDistancefromright = 70; // TPButton Distance from right
input color SLButton_bgcolor = clrRed; // SL Button   Color
input color SLButton_font_color = clrWhite;  // SL Button   Font Color
input uint SLButton_font_size = 8;  // SL Button   Font Size
input color PriceButton_bgcolor = clrAqua;   // Price Button   Color
input color PriceButton_font_color = clrBlack;  // Price Button   Font Color
input uint PriceButton_font_size = 8;  // Price Button   Font Size
input color SendOnlyButton_bgcolor = clrForestGreen;  // Button Send only  Color
input color SendOnlyButton_font_color = clrWhite;  // Button Send only  Font Color
input uint SendOnlyButton_font_size = 10; // Button Send only  Font Size
input color TSButton_bgcolor = clrGray;   // Button Trade & Send  Color
input color TSButton_font_color = clrRed; // Button Trade & Send  Font Color
input uint TSButton_font_size = 10; // Button Trade & Send  Font Size
input string NotizEdit_length = 500;   // Notiz field Length
input group "===== Lines ====="
input color EntryLine = clrBlue; // Entry Line
input color TPLine = clrGreen;   // TP Line at TP Button
input color SLLine = clrRed;  // SL Line at SL Button
input color TradeEntryLineLong = clrGreen; // Active Trade SL Line Long
input color TradeTPLineLong = clrGreen;   // Active Trade TP Line Long
input color TradeSLLineLong = clrRed;  // Active Trade SL Line Long
input color TradeEntryLineShort = clrAqua;   // Active Trade Entry Line Short
input color TradeTPLineShort = clrDarkOrange;   // Active Trade TP Line Short
input color TradeSLLineShort = clrViolet; // Active Trade SL Line Long




//input double DefaultRisk = 0.5;   // Risk in %
//input int tradecounter=0;  // 1. Tradenummer
//int trade_counter=tradecounter;
input int DistancefromRight = 300;  //Distance from right screen edge

#define TPButton "TPButton"
#define EntryButton "EntryButton"
#define SLButton "SLButton"
#define BTN2 "SendOnlyButton"
#define TP_HL "TP_HL"
#define SL_HL "SL_HL"
#define PR_HL "PR_HL"
#define TRNB "EingabeTrade"
#define SabioTP "SabioTP"
#define SabioEntry "SabioEntry"
#define SabioSL "SabioSL"
#define TP_Long "TP_Long"
#define SL_Long "SL_Long"
#define TP_Short "TP_Short"
#define SL_Short "SL_Short"
#define LabelTPLong "LabelTPLong"
#define LabelSLLong "LabelSLLong"
#define LabelTPShort "LabelTPShort"
#define LabelSLShort "LabelSLShort"
#define Entry_Long "Entry_Long"
#define Entry_Short "Entry_Short"
#define LabelEntryLong "LabelEntryLong"
#define LabelEntryShort "LabelEntryShort"
#define ConfirmSabioInserts "ConfirmSabioInserts"

string g_last_known_parameters_hash = "";
// Error Code Enumeration
enum TRADE_ERROR_CODE
  {
   ERR_NONE = 0,
   ERR_INVALID_TRADE_NUMBER,
   ERR_TRADE_ALREADY_EXISTS,
   ERR_ENTRY_BELOW_CURRENT,
   ERR_ENTRY_ABOVE_CURRENT,
   ERR_INVALID_PRICES,
   ERR_DISCORD_SEND_FAILED,
   ERR_LOT_CALCULATION_FAILED,
   ERR_ORDER_SEND_FAILED,
   ERR_MARKET_CLOSED,           // NEU
   ERR_NO_CURRENT_PRICES,       // NEU
   ERR_WEEKEND_TRADING          // NEU
  };

struct MarketStatus
  {
   bool              is_open;                // Markt geöffnet
   bool              has_valid_prices;       // Gültige Preise verfügbar
   datetime          market_open_time;   // Nächste Marktöffnung
   datetime          market_close_time;  // Letzte/Nächste Marktschließung
   string            status_text;          // Benutzerfreundlicher Text
   double            last_valid_ask;       // Letzter gültiger Ask-Preis
   double            last_valid_bid;       // Letzter gültiger Bid-Preis
  };
MarketStatus g_market_status;  // Globale Variable
// Settings Struktur für alle Konfigurationen
struct TradeAssistantSettings
  {
   // Discord Settings - VERWENDE CHAR ARRAYS STATT STRING!
   char              webhook_m1[256];      // Max 256 Zeichen für URL
   char              webhook_m2[256];
   char              webhook_m5[256];
   char              webhook_m10[256];
   char              webhook_m15[256];
   char              webhook_m30[256];
   char              webhook_h1[256];

   char              webhook_default[256];

   // Button Settings
   bool              show_tp_button;
   color             tp_button_bgcolor;
   color             tp_button_font_color;
   uint              tp_button_font_size;
   int               tp_button_distance;

   color             sl_button_bgcolor;
   color             sl_button_font_color;
   uint              sl_button_font_size;

   color             price_button_bgcolor;
   color             price_button_font_color;
   uint              price_button_font_size;

   // Line Colors
   color             entry_line_color;
   color             tp_line_color;
   color             sl_line_color;

   // Trade Settings
   bool              send_only;
   bool              sabio_edit;
   bool              sabio_prices;
   bool              message_box_sound;
   int               risk_money;
   int               distance_from_right;

   // Last State
   int               last_trade_number;
   char              last_settings_version[20];  // Auch hier char array statt string

   bool              is_long_trade_active; // Flag, ob ein Long-Trade aktiv ist
   bool              is_sell_trade_active; // Flag, ob ein Short-Trade aktiv ist

   // TradeInfo Strukturen zerlegt speichern
   int               long_trade_tradenummer;
   double            long_trade_price;
   double            long_trade_sl;
   double            long_trade_tp;
   bool              long_trade_was_send;

   int               short_trade_tradenummer;
   double            short_trade_price;
   double            short_trade_sl;
   double            short_trade_tp;
   bool              short_trade_was_send;


   // Button/Label Status speichern (als uint)
   uint              long_trade_label_bgcolor; // Hintergrundfarbe des Long-Trade-Labels
   uint              long_trade_label_color; // Textfarbe des Long-Trade-Labels
   uint              short_trade_label_bgcolor; // Hintergrundfarbe des Short-Trade-Labels
   uint              short_trade_label_color; // Textfarbe des Short-Trade-Labels

  };
// Globale Settings Variable
TradeAssistantSettings g_Settings;



// Webhook Arbeits-Variablen (da Input-Parameter read-only sind)
string working_webhook_m1 = "";
string working_webhook_m2 = "";
string working_webhook_m5 = "";
string working_webhook_m10 = "";    // NEU
string working_webhook_m15 = "";    // NEU
string working_webhook_m30 = "";    // NEU
string working_webhook_h1 = "";
string working_webhook_default = "";
bool g_parameters_changed = false;
bool working_ShowTPButton = ShowTPButton;
double Entry_Price;
double TP_Price;
double SL_Price;
double CurrentAskPrice;
double CurrentBidPrice;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CalculateHashOfParameters()
  {
   string hash_string = "";

// Füge ALLE Input-Parameter dem String hinzu
   hash_string += string(SendOnlyButton);
   hash_string += string(Sabioedit);
   hash_string += string(SabioPrices);
   hash_string += string(MessageBoxSound);
   hash_string += string(ShowTPButton);
   hash_string += WebhookM1;
   hash_string += WebhookM2;
   hash_string += WebhookM5;
   hash_string += WebhookH1;
   hash_string += WebhookDefault;
   hash_string += string(DiscordBotName);
   hash_string += string(MessageColor);
   hash_string += string(riskMoney);
   hash_string += string(ButtonCancelOrder_bgcolor);
   hash_string += string(ButtonCancelOrder_font_color);
   hash_string += string(ButtonCancelOrder_font_size);
   hash_string += string(InfoLabelFontSize_bgcolor);
   hash_string += string(InfoLabelFontSize_font_color);
   hash_string += string(InfoLabelFontSize);
   hash_string += string(TPButton_bgcolor);
   hash_string += string(TPButton_font_color);
   hash_string += string(TPButton_font_size);
   hash_string += string(TPButtonDistancefromright);
   hash_string += string(SLButton_bgcolor);
   hash_string += string(SLButton_font_color);
   hash_string += string(SLButton_font_size);
   hash_string += string(PriceButton_bgcolor);
   hash_string += string(PriceButton_font_color);
   hash_string += string(PriceButton_font_size);
   hash_string += string(SendOnlyButton_bgcolor);
   hash_string += string(SendOnlyButton_font_color);
   hash_string += string(SendOnlyButton_font_size);
   hash_string += string(TSButton_bgcolor);
   hash_string += string(TSButton_font_color);
   hash_string += string(TSButton_font_size);
   hash_string += string(NotizEdit_length);
   hash_string += string(EntryLine);
   hash_string += string(TPLine);
   hash_string += string(SLLine);
   hash_string += string(TradeEntryLineLong);
   hash_string += string(TradeTPLineLong);
   hash_string += string(TradeSLLineLong);
   hash_string += string(TradeEntryLineShort);
   hash_string += string(TradeTPLineShort);
   hash_string += string(TradeSLLineShort);
   hash_string += string(DistancefromRight);

// Berechne einen einfachen Hash-Wert (du kannst auch eine komplexere Hash-Funktion verwenden)
   int hash_value = StringToInteger(hash_string);
   return string(hash_value);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckForExistingLongPosition();
bool isBuy=1;
bool is_long_trade=false,is_sell_trade=false;
bool send_TP_buy=false;
bool send_SL_buy=false;
bool send_CL_buy=false;
bool send_TP_sell=false;
bool send_SL_sell=false;
bool send_CL_sell=false;
bool HitEntryPriceLong = false;
bool HitEntryPriceShort = false;
bool is_sell_trade_pending = false;
bool is_buy_trade_pending = false;

int last_trade_nummer=0;
int last_buy_trade=-1;
int last_sell_trade=-1;
int
xd1,
yd1, xs1, ys1,
xd2, yd2, xs2, ys2,
xd3, yd3, xs3, ys3,
xd4, yd4, xs4, ys4,
xd5, yd5, xs5, ys5;

datetime dt_Labels = iTime(_Symbol, 0, 0);


//+------------------------------------------------------------------+
//| Die Funktion erhält den Wert der Höhe des Charts in Pixeln       |
//+------------------------------------------------------------------+
int getChartHeightInPixels(const long chartID = 0, const int subwindow = 0)
  {
//--- Bereiten wir eine Variable, um den Wert der Eigenschaft zu erhalten
   long result = -1;
//--- Setzen den Wert des Fehlers zurück
   ResetLastError();
//--- Erhalten wir den Wert der Eigenschaft
   if(!ChartGetInteger(chartID, CHART_HEIGHT_IN_PIXELS, 0, result))
     {
      //--- Schreiben die Fehlermeldung in den Log "Experten"
      Print(__FUNCTION__ + ", Error Code = ", GetLastError());
     }
//--- Geben den Wert der Eigenschaft zurück
   return ((int)result);
  }

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Die Funktion erhält den Wert der Breite des Charts in Pixeln     |
//+------------------------------------------------------------------+
int getChartWidthInPixels(const long chart_ID = 0)
  {
//--- Bereiten wir eine Variable, um den Wert der Eigenschaft zu erhalten
   long result = -1;
//--- Setzen den Wert des Fehlers zurück
   ResetLastError();
//--- Erhalten wir den Wert der Eigenschaft
   if(!ChartGetInteger(chart_ID, CHART_WIDTH_IN_PIXELS, 0, result))
     {
      //--- Schreiben die Fehlermeldung in den Log "Experten"
      Print(__FUNCTION__ + ", Error Code = ", GetLastError());
     }
//--- Geben den Wert der Eigenschaft zurück
   return ((int)result);
  }


  
  //+------------------------------------------------------------------+
//| VERBESSERTE Get_Price_d() MIT VALIDIERUNG                       |
//+------------------------------------------------------------------+
double Get_Price_d(string name)
{
   if(name == "")
   {
      Print(__FUNCTION__, " > Error: Empty object name!");
      return 0.0;
   }
   
   if(ObjectFind(0, name) < 0)
   {
      Print(__FUNCTION__, " > Error: Object '", name, "' not found!");
      return 0.0;
   }
   
   double price = ObjectGetDouble(0, name, OBJPROP_PRICE, 0);
   if(price <= 0)
   {
      Print(__FUNCTION__, " > Warning: Object '", name, "' has invalid price: ", price);
      return 0.0;
   }
   
   return NormalizeDouble(price, _Digits);
}


//+------------------------------------------------------------------+
//| VERBESSERTE Get_Price_s() MIT VALIDIERUNG                       |
//+------------------------------------------------------------------+
string Get_Price_s(string name)
{
   double price = Get_Price_d(name);
   if(price <= 0)
   {
      return "0.00000";
   }
   
   return DoubleToString(price, _Digits);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool get_sabio_price(string      &text,        // Text
                     const long   chart_ID=0,  // ID des Charts
                     const string name="Edit") // Objektname
  {
//--- Setzen den Wert des Fehlers zurück
   ResetLastError();
//--- erhalten wir den Text des Objektes
   if(!ObjectGetString(chart_ID,name,OBJPROP_TEXT,0,text))
     {
      Print(__FUNCTION__,
            ": Konnte nicht den Text erhalten! Fehlercode = ",GetLastError());
      return(false);
     }
     Print ("ermittelter Sabio Preis: " + text);
//--- die erfolgreiche Umsetzung
   return(true);
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string update_Text(string name, string val)
  {
   return (string)ObjectSetString(0, name, OBJPROP_TEXT, val);
  }



double calcLots(double slDistance)
{
   // 1. Validierung der Eingabe
   if(slDistance <= 0)
     {
      Print(__FUNCTION__, " > Error: SL Distance must be positive! Got: ", slDistance);
      return 0.01; // Minimum Lot Size als Fallback
     }

   // 2. Symbol-Informationen holen
   double ticksize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickvalue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double lotstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minlot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxlot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   // 3. Validierung der Symbol-Informationen
   if(ticksize == 0 || tickvalue == 0 || lotstep == 0)
     {
      Print(__FUNCTION__, " > Error: Invalid symbol information");
      Print("TickSize: ", ticksize, " TickValue: ", tickvalue, " LotStep: ", lotstep);
      return minlot > 0 ? minlot : 0.01;
     }

   // 4. Berechnung mit Fehlerbehandlung
   double moneyLotstep = (slDistance / ticksize) * tickvalue * lotstep;
   if(moneyLotstep == 0)
     {
      Print(__FUNCTION__, " > Error: Money per lot step is zero");
      return minlot > 0 ? minlot : 0.01;
     }
   
   // 5. Lot-Größe berechnen
   double lots = MathFloor(riskMoney / moneyLotstep) * lotstep;
   
   // 6. An Broker-Limits anpassen
   if(lots < minlot) 
     {
      Print(__FUNCTION__, " > Warning: Calculated lots (", lots, ") below minimum (", minlot, ")");
      lots = minlot;
     }
   if(lots > maxlot) 
     {
      Print(__FUNCTION__, " > Warning: Calculated lots (", lots, ") above maximum (", maxlot, ")");
      lots = maxlot;
     }
   
   // 7. Normalisierung mit korrekter Dezimalstelle
   int digits = 2; // Standard
   if(lotstep == 0.001) digits = 3;
   else if(lotstep == 0.01) digits = 2;
   else if(lotstep == 0.1) digits = 1;
   else if(lotstep == 1.0) digits = 0;
   
   lots = NormalizeDouble(lots, digits);
   
   Print(__FUNCTION__, " > Calculated lots: ", lots, " (Risk: ", riskMoney, " SL Distance: ", slDistance, ")");
   
   return lots;
}


  
void DeleteBuyStopOrderForCurrentChart()
  {
   string current_symbol = Symbol(); // Aktuelles Symbol des Charts

   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong order_ticket = OrderGetTicket(i);
      if(OrderSelect(order_ticket))
        {
         string symbol = OrderGetString(ORDER_SYMBOL);
         int type = OrderGetInteger(ORDER_TYPE);

         // Überprüfen, ob die Order zum aktuellen Chart gehört und ein Buy Stop ist
         if(symbol == current_symbol && type == ORDER_TYPE_BUY_STOP)
           {
            // Pending Order löschen
            if(!trade.OrderDelete(order_ticket))
              {
               Print("Fehler beim Löschen der Buy Stop Order. Fehler: ", GetLastError());
              }
            else
              {
               Print("Buy Stop Order für ", symbol, " erfolgreich gelöscht.");
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteSellStopOrderForCurrentChart()
  {
   string current_symbol = Symbol(); // Aktuelles Symbol des Charts

   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong order_ticket = OrderGetTicket(i);
      if(OrderSelect(order_ticket))
        {
         string symbol = OrderGetString(ORDER_SYMBOL);
         int type = OrderGetInteger(ORDER_TYPE);

         // Überprüfen, ob die Order zum aktuellen Chart gehört und ein Buy Stop ist
         if(symbol == current_symbol && type == ORDER_TYPE_SELL_STOP)
           {
            // Pending Order löschen
            if(!trade.OrderDelete(order_ticket))
              {
               Print("Fehler beim Löschen der Sell Stop Order. Fehler: ", GetLastError());
              }
            else
              {
               Print("Sell Stop Order für ", symbol, " erfolgreich gelöscht.");
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|  TP or SL reached                                                                |
//+------------------------------------------------------------------+
void TPSLReached()
  {
   double CurrentAskPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double CurrentBidPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);

//+------------------------------------------------------------------+
//|  Long TP or SL Reached                                                                 |
//+------------------------------------------------------------------+

   if(is_long_trade)
     {

      if(!send_CL_buy)
        {
         if(!HitEntryPriceLong && CurrentAskPrice >= tradeInfo[0].price)
           {
            HitEntryPriceLong = true;
            ObjectSetInteger(0, Entry_Long, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, TP_Long, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, SL_Long, OBJPROP_STYLE, STYLE_SOLID);
           }

         if(HitEntryPriceLong && tradeInfo[0].sl > 0 && (CurrentBidPrice <= tradeInfo[0].sl))
           {
            // Send notification before placing trade
            string message = FormatSLMessage(tradeInfo[0]);
            bool ret= SendDiscordMessage(message);
            is_long_trade=false;
            send_SL_buy=true;
            ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_COLOR, clrNONE);
            ObjectSetInteger(0,"ActiveLongTrade", OBJPROP_BGCOLOR, clrNONE);
            ObjectSetString(0,"ActiveLongTrade",OBJPROP_TEXT,"");
            DeleteLinesandLabelsLong();
            HitEntryPriceLong = false;
            Alert(_Symbol + " Long stopped out");
           }

         if(HitEntryPriceLong == true && tradeInfo[0].tp > 0 && (CurrentAskPrice >= tradeInfo[0].tp))
           {
            // Send notification before placing trade
            string message = FormatTPMessage(tradeInfo[0]);
            bool ret= SendDiscordMessage(message);
            is_long_trade=false;
            send_TP_buy=true;
            ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_COLOR, clrNONE);
            ObjectSetInteger(0,"ActiveLongTrade", OBJPROP_BGCOLOR, clrNONE);
            ObjectSetString(0,"ActiveLongTrade",OBJPROP_TEXT,"");
            DeleteLinesandLabelsLong();
            HitEntryPriceLong = false;
            Alert(_Symbol + " Long TP reached");
           }
        }
     }

//+------------------------------------------------------------------+
//| Short TP or SL Reached                                                                  |
//+------------------------------------------------------------------+

   if(is_sell_trade)
     {

      if(!HitEntryPriceShort && CurrentBidPrice <= tradeInfo[1].price)
        {
         HitEntryPriceShort = true;
         ObjectSetInteger(0, Entry_Short, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSetInteger(0, TP_Short, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSetInteger(0, SL_Short, OBJPROP_STYLE, STYLE_SOLID);
        }

      if(!send_CL_sell)
        {
         if(HitEntryPriceShort == true && tradeInfo[1].sl > 0 && (CurrentAskPrice >= tradeInfo[1].sl))
           {
            // Send notification before placing trade
            string message = FormatSLMessage(tradeInfo[1]);
            bool ret= SendDiscordMessage(message);
            is_sell_trade=false;
            send_SL_sell=true;
            ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_COLOR, clrNONE);
            ObjectSetInteger(0,"ActiveShortTrade", OBJPROP_BGCOLOR, clrNONE);
            ObjectSetString(0,"ActiveShortTrade",OBJPROP_TEXT,"");
            DeleteLinesandLabelsShort();
            HitEntryPriceShort = false;
            Alert(_Symbol + " Short stopped out");
           }

         if(HitEntryPriceShort == true &&  tradeInfo[1].tp > 0 && CurrentBidPrice <= tradeInfo[1].tp)
           {
            // Send notification before placing trade
            string message = FormatTPMessage(tradeInfo[1]);
            bool ret= SendDiscordMessage(message);
            is_sell_trade=false;
            send_TP_sell=true;
            ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_COLOR, clrNONE);
            ObjectSetInteger(0,"ActiveShortTrade", OBJPROP_BGCOLOR, clrNONE);
            ObjectSetString(0,"ActiveShortTrade",OBJPROP_TEXT,"");
            DeleteLinesandLabelsShort();
            HitEntryPriceShort = false;
            Alert(_Symbol + " Short TP reached");
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Label für Tradenummern                                                                |
//+------------------------------------------------------------------+
void LabelTradeNumber()
  {
   ObjectCreate(0, "LabelTradenummer", OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0,"LabelTradenummer",OBJPROP_XDISTANCE,100);
   ObjectSetInteger(0,"LabelTradenummer",OBJPROP_YDISTANCE,90+30+10+30+10);
   ObjectSetInteger(0,"LabelTradenummer",OBJPROP_XSIZE,330);
   ObjectSetInteger(0,"LabelTradenummer",OBJPROP_YSIZE,30);
   ObjectSetString(0,"LabelTradenummer",OBJPROP_TEXT,"Last Trade Number: " + IntegerToString(tradenummer));
   ObjectSetInteger(0,"LabelTradenummer", OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, "LabelTradenummer", OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, "LabelTradenummer", OBJPROP_FONTSIZE, InfoLabelFontSize);
   ObjectSetString(0, "LabelTradenummer", OBJPROP_FONT, "Arial");
  }

//+------------------------------------------------------------------+
//| Sabio TP berechnen                                                                 |
//+------------------------------------------------------------------+
void UpdateSabioTP()
  {
   if(Entry_Price > CurrentAskPrice)
     {
      string EntryPriceString = ObjectGetString(0,SabioEntry,OBJPROP_TEXT,0);
      int Ergebnis = StringReplace(EntryPriceString,"SABIO ENTRY:","");
      double SabioEntryPrice = (double)EntryPriceString;
      string SabioSLPriceString = ObjectGetString(0,SabioSL,OBJPROP_TEXT,0);
      int ErgebnisSL = StringReplace(SabioSLPriceString,"SABIO SL:","");
      double SabioSLPrice = (double)SabioSLPriceString;
      if(SabioEntryPrice > 0 && SabioSLPrice > 0 && SabioEntryPrice != SabioSLPrice)
        {
         double SabioTPPrice = MathAbs(SabioEntryPrice - SabioSLPrice);
         update_Text(SabioTP, "SABIO TP: " + (int)(SabioTPPrice + SabioEntryPrice));
        }
     }

   if(Entry_Price < CurrentBidPrice)
     {
      string EntryPriceString = ObjectGetString(0,SabioEntry,OBJPROP_TEXT,0);
      int Ergebnis = StringReplace(EntryPriceString,"SABIO ENTRY:","");
      double SabioEntryPrice = (double)EntryPriceString;
      string SabioSLPriceString = ObjectGetString(0,SabioSL,OBJPROP_TEXT,0);
      int ErgebnisSL = StringReplace(SabioSLPriceString,"SABIO SL:","");

      double SabioSLPrice = (double)SabioSLPriceString;

      if(SabioEntryPrice > 0 && SabioSLPrice > 0 && SabioEntryPrice != SabioSLPrice)
        {
         double SabioTPPrice = MathAbs(SabioSLPrice -SabioEntryPrice);
         update_Text(SabioTP, "SABIO TP: " + (int)(SabioEntryPrice - SabioTPPrice));
        }
     }
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateLabelsTPSLLines(string LABEL_NAME, string text, double price2, color clr1)
  {
   ResetLastError();

   if(!ObjectCreate(0, LABEL_NAME, OBJ_TEXT, 0, TimeCurrent(), price2))
     {
      Print(__FUNCTION__, ": Failed to create Label: Error Code: ", GetLastError());
      return;
     }

   ObjectSetInteger(0, LABEL_NAME, OBJPROP_COLOR, clr1);
   ObjectSetInteger(0, LABEL_NAME, OBJPROP_FONTSIZE, 12);
   ObjectSetInteger(0, LABEL_NAME, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, LABEL_NAME, OBJPROP_ANCHOR, ANCHOR_LEFT);
   ObjectSetInteger(0, LABEL_NAME, OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, LABEL_NAME, OBJPROP_SELECTED, false);

   ObjectSetString(0, LABEL_NAME, OBJPROP_TEXT, text); // Hier der wichtige Unterschied!

   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| Create Trading Lines
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CreateTPSLLines(string objName, datetime time1, double price1, color clr)
  {
   ResetLastError();

   if(!ObjectCreate(0, objName, OBJ_HLINE, 0, time1, price1))
     {
      Print(__FUNCTION__, ": Failed to create HL: Error Code: ", GetLastError());
      return (false);
     }
   ObjectSetInteger(0, objName, OBJPROP_TIME, TimeCurrent());
   ObjectSetDouble(0, objName, OBJPROP_PRICE, price1);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);


   ChartRedraw(0);
   return (true);
  }

//+------------------------------------------------------------------+
//| Create Line Labels
//+------------------------------------------------------------------+


// 3. OPTIMIERE AUCH CreateLabelsLong() und CreateLabelsShort():

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateLabelsLong()
  {
// Prüfe ob Labels bereits existieren
   if(ObjectFind(0, LabelTPLong) < 0)  // Label existiert nicht
     {
      CreateLabelsTPSLLines(LabelTPLong, "TP Long Trade", tradeInfo[0].tp, TradeTPLineLong);
      update_Text(LabelTPLong, "TP Long Trade");
      if(!working_ShowTPButton)
        {
         ObjectSetInteger(0, LabelTPLong, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        }
     }

   if(ObjectFind(0, LabelSLLong) < 0)
     {
      CreateLabelsTPSLLines(LabelSLLong, "SL Long Trade", tradeInfo[0].sl, TradeSLLineLong);
      update_Text(LabelSLShort, "SL Short Trade");
     }

   if(ObjectFind(0, LabelEntryLong) < 0)
     {
      CreateLabelsTPSLLines(LabelEntryLong, "Entry Long Trade", tradeInfo[0].price, TradeEntryLineLong);
      update_Text(LabelEntryLong, "Entry Long Trade");
     }

// Update nur die Zeit der Labels (nicht neu erstellen)
   ObjectSetInteger(0, LabelTPLong, OBJPROP_TIME, TimeCurrent());
   ObjectSetInteger(0, LabelSLLong, OBJPROP_TIME, TimeCurrent());
   ObjectSetInteger(0, LabelEntryLong, OBJPROP_TIME, TimeCurrent());


  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateLabelsShort()
  {
// Prüfe ob Labels bereits existieren
   if(ObjectFind(0, LabelTPShort) < 0)
     {
      CreateLabelsTPSLLines(LabelTPShort, "TP Short Trade", tradeInfo[1].tp, TradeTPLineShort);
      update_Text(LabelTPShort, "TP Short Trade");
      if(!working_ShowTPButton)
        {
         ObjectSetInteger(0, LabelTPShort, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        }
     }

   if(ObjectFind(0, LabelSLShort) < 0)
     {
      CreateLabelsTPSLLines(LabelSLShort, "SL Short Trade", tradeInfo[1].sl, TradeSLLineShort);
      update_Text(LabelSLShort, "SL Short Trade");
     }

   if(ObjectFind(0, LabelEntryShort) < 0)
     {
      CreateLabelsTPSLLines(LabelEntryShort, "Entry Short Trade", tradeInfo[1].price, TradeEntryLineShort);
      update_Text(LabelEntryShort, "Entry Short Trade");
     }

// Update nur die Zeit der Labels
   ObjectSetInteger(0, LabelTPShort, OBJPROP_TIME, TimeCurrent());
   ObjectSetInteger(0, LabelSLShort, OBJPROP_TIME, TimeCurrent());
   ObjectSetInteger(0, LabelEntryShort, OBJPROP_TIME, TimeCurrent());
  }

//+------------------------------------------------------------------+
//|   Delete all objects                                 |
//+------------------------------------------------------------------+
void deleteObjects()
  {

// 1. Haupt-Trading Buttons
   ObjectDelete(0, TPButton);
   ObjectDelete(0, EntryButton);
   ObjectDelete(0, SLButton);
   ObjectDelete(0, "SendOnlyButton");

// 2. Horizontale Linien
   ObjectDelete(0, TP_HL);
   ObjectDelete(0, SL_HL);
   ObjectDelete(0, PR_HL);

// 3. Trade Management Buttons
   ObjectDelete(0, "ButtonCancelOrder");
   ObjectDelete(0, "ButtonCancelOrderSell");
   ObjectDelete(0, "ButtonTargetReached");
   ObjectDelete(0, "ButtonStoppedout");
   ObjectDelete(0, "ButtonTargetReachedSell");
   ObjectDelete(0, "ButtonStoppedoutSell");

// 4. Info Labels
   ObjectDelete(0, "ActiveLongTrade");
   ObjectDelete(0, "ActiveShortTrade");
   ObjectDelete(0, "InfoButtonCancelOrder");
   ObjectDelete(0, "InfoButtonStoppedout");
   ObjectDelete(0, "InfoButtonCancelOrderSell");
   ObjectDelete(0, "InfoButtonStoppedoutSell");

// 5. Trade Linien und Labels
   ObjectDelete(0, "TP_Long");
   ObjectDelete(0, "SL_Long");
   ObjectDelete(0, "Entry_Long");
   ObjectDelete(0, "TP_Short");
   ObjectDelete(0, "SL_Short");
   ObjectDelete(0, "Entry_Short");
   ObjectDelete(0, "LabelTPLong");
   ObjectDelete(0, "LabelSLLong");
   ObjectDelete(0, "LabelEntryLong");
   ObjectDelete(0, "LabelTPShort");
   ObjectDelete(0, "LabelSLShort");
   ObjectDelete(0, "LabelEntryShort");

// 6. Eingabefelder
   ObjectDelete(0, "EingabeTrade");
   ObjectDelete(0, "SabioEntry");
   ObjectDelete(0, "SabioTP");
   ObjectDelete(0, "SabioSL");
   ObjectDelete(0, "NotizEdit");
   ObjectDelete(0, "LabelTradenummer");
      ObjectDelete(0, "MarketStatus");

// 7. Zusätzliche Bereinigung für dynamisch erstellte Objekte
   DeleteAllObjectsByPrefix("Temp_");  // Falls temporäre Objekte existieren

   ChartRedraw(0);
   Print(__FUNCTION__, " > All objects cleaned up");
  }
// 2. NEUE HILFSFUNKTION für Prefix-basierte Löschung:
void DeleteAllObjectsByPrefix(string prefix)
  {
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i);
      if(StringFind(name, prefix) == 0)  // Beginnt mit prefix
        {
         ObjectDelete(0, name);
        }
     }
  }
//+------------------------------------------------------------------+
//| Tradelinien Long löschen                                                                  |
//+------------------------------------------------------------------+
void DeleteLinesandLabelsLong()
  {
   ObjectDelete(0, "TP_Long");
   ObjectDelete(0, "SL_Long");
   ObjectDelete(0, "LabelTPLong");
   ObjectDelete(0, "LabelSLLong");
   ObjectDelete(0, "Entry_Long");
   ObjectDelete(0, "LabelEntryLong");

  }
//+------------------------------------------------------------------+
//| Tradelinien Short löschen                                                                 |
//+------------------------------------------------------------------+
void DeleteLinesandLabelsShort()
  {
   ObjectDelete(0, "TP_Short");
   ObjectDelete(0, "SL_Short");
   ObjectDelete(0, "LabelTPShort");
   ObjectDelete(0, "LabelSLShort");
   ObjectDelete(0, "Entry_Short");
   ObjectDelete(0, "LabelEntryShort");
  }

//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| ERWEITERTE ERROR MESSAGES                                        |
//+------------------------------------------------------------------+
string GetErrorMessage(TRADE_ERROR_CODE error_code)
  {
   switch(error_code)
     {
      case ERR_MARKET_CLOSED:
      {
         string next_open = "";
         if(g_market_status.market_open_time > 0)
           {
            next_open = "\n\nNächste Marktöffnung: " + TimeToString(g_market_status.market_open_time);
           }
         return "Markt ist geschlossen!\n\nTrading ist nur während den Marktzeiten möglich." + next_open;
}
      case ERR_NO_CURRENT_PRICES:
         return "Keine aktuellen Preise verfügbar!\n\nBitte warten Sie bis der Markt öffnet oder die Preise aktualisiert werden.";

      case ERR_WEEKEND_TRADING:
         return "Weekend Trading nicht möglich!\n\nTrading ist nur Montag bis Freitag möglich.";

      case ERR_INVALID_TRADE_NUMBER:
         return "Bitte geben Sie eine gültige Trade-Nummer ein (größer als " + IntegerToString(last_trade_nummer) + ")";

      case ERR_TRADE_ALREADY_EXISTS:
         return "Es läuft bereits ein Trade in diese Richtung!\nBitte warten Sie bis der aktuelle Trade geschlossen ist.";

      case ERR_ENTRY_BELOW_CURRENT:
         return "Entry-Preis liegt unter dem aktuellen Kurs!\nFür Buy-Stop muss Entry über " +
                DoubleToString(g_market_status.last_valid_ask, _Digits) + " liegen.";

      case ERR_ENTRY_ABOVE_CURRENT:
         return "Entry-Preis liegt über dem aktuellen Kurs!\nFür Sell-Stop muss Entry unter " +
                DoubleToString(g_market_status.last_valid_bid, _Digits) + " liegen.";

      // ... andere Error Codes ...

      default:
         return "Unbekannter Fehler aufgetreten!";
     }
  }

// Verbesserte Message Box Funktion
bool ShowTradeError(TRADE_ERROR_CODE error_code, string additional_info = "")
  {
   string title = "Trading Assistent - Hinweis";
   string message = GetErrorMessage(error_code);

   if(additional_info != "")
      message += "\n\n" + additional_info;

// Sound abspielen wenn aktiviert
   if(MessageBoxSound)
     {
      PlaySound("alert.wav");  // oder "alert2.wav"
     }

// Log für Debugging
   Print("[ERROR] ", EnumToString(error_code), ": ", message);

   return MessageBox(message, title, MB_OK | MB_ICONWARNING) == IDOK;
  }
//+------------------------------------------------------------------+
void UpdateTradeNumberDisplay()
  {
   string display_text = "Last Trade Number: " + IntegerToString(last_trade_nummer);

// Sichere Aktualisierung des Labels
   if(!SafeUpdateText("LabelTradenummer", display_text))
     {
      Print(__FUNCTION__, " > Warning: Could not update trade number display");
     }

// Auch das Eingabefeld für die nächste Tradenummer aktualisieren
   int next_trade_number = last_trade_nummer + 1;
   if(!SafeUpdateText(TRNB, IntegerToString(next_trade_number)))
     {
      Print(__FUNCTION__, " > Warning: Could not update trade number input field");
     }

   Print(__FUNCTION__, " > Trade number display updated: ", last_trade_nummer, " Next: ", next_trade_number);
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| HILFSFUNKTION: Nächsten Montag 00:00 finden                     |
//+------------------------------------------------------------------+
datetime GetNextMondayOpen() {
   datetime current = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(current, dt);
   
   int days_until_monday = (8 - dt.day_of_week) % 7;
   if(days_until_monday == 0 && dt.hour < 22) // Forex öffnet Sonntag 22:00
      days_until_monday = 1;
   
   // Sonntag 22:00 Uhr (typische Forex-Öffnungszeit)
   datetime next_open = current + days_until_monday * 86400;
   TimeToStruct(next_open, dt);
   dt.hour = 22; // 22:00 Uhr
   dt.min = 0;
   dt.sec = 0;
   if(dt.day_of_week == 1) // Wenn Montag, dann einen Tag zurück auf Sonntag
      next_open -= 86400;
   
   return StructToTime(dt);
}
//+------------------------------------------------------------------+
//| MARKT-STATUS ANZEIGE - POSITION KORRIGIERT                      |
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| MARKTSTATUS - SCHLICHTE VERSION                                 |
//+------------------------------------------------------------------+
void CreateMarketStatusPanel()
{
   // Nur ein einfaches Text-Label, kein Hintergrund
   ObjectCreate(0, "MarketStatus", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "MarketStatus", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, "MarketStatus", OBJPROP_XDISTANCE, 270);
   ObjectSetInteger(0, "MarketStatus", OBJPROP_YDISTANCE, 15);
   ObjectSetString(0, "MarketStatus", OBJPROP_FONT, "Arial");  // Normale Schrift, nicht Bold
   ObjectSetInteger(0, "MarketStatus", OBJPROP_FONTSIZE, 11);   // Kleinere Schrift
   
   UpdateMarketStatusDisplay();
}

void UpdateMarketStatusDisplay()
{
   g_market_status = CheckMarketStatus();
   
   string status_text = "";
   color status_color = clrGray;  // Neutralere Farbe
   
   if(g_market_status.is_open && g_market_status.has_valid_prices)
   {
      status_text = "Markt offen";  // Schlicht, ohne Symbole
      status_color = clrMediumSeaGreen;  // Dezenteres Grün
   }
   else
   {
      status_text = "Markt geschlossen";
      status_color = clrIndianRed;  // Dezenteres Rot
   }
   
   if(ObjectFind(0, "MarketStatus") >= 0)
   {
      ObjectSetString(0, "MarketStatus", OBJPROP_TEXT, status_text);
      ObjectSetInteger(0, "MarketStatus", OBJPROP_COLOR, status_color);
   }
   
   ChartRedraw();
}
//+------------------------------------------------------------------+
//| Blinkende Warnung bei geschlossenem Markt                       |
//+------------------------------------------------------------------+
void MarketClosedWarningBlink()
{
   static bool blink_state = false;
   static datetime last_blink = 0;
   
   if(!g_market_status.is_open && TimeCurrent() - last_blink > 1)  // Jede Sekunde
   {
      blink_state = !blink_state;
      last_blink = TimeCurrent();
      
      if(blink_state)
      {
         ObjectSetInteger(0, "MarketStatus", OBJPROP_COLOR, clrRed);
         ObjectSetInteger(0, "MarketStatusBG", OBJPROP_BGCOLOR, C'60,0,0');
      }
      else
      {
         ObjectSetInteger(0, "MarketStatus", OBJPROP_COLOR, clrOrangeRed);
         ObjectSetInteger(0, "MarketStatusBG", OBJPROP_BGCOLOR, C'40,0,0');
      }
      
      ChartRedraw();
   }
}
//+------------------------------------------------------------------+
//| SEND BUTTON AKTIVIERUNG/DEAKTIVIERUNG                           |
//+------------------------------------------------------------------+
void UpdateSendButtonState()
{
  g_market_status = CheckMarketStatus();
   
   if(g_market_status.is_open && g_market_status.has_valid_prices)
   {
      ObjectSetString(0, "MarketStatusDot", OBJPROP_TEXT, "•");  // Punkt
      ObjectSetInteger(0, "MarketStatusDot", OBJPROP_COLOR, clrLimeGreen);
   }
   else
   {
      ObjectSetString(0, "MarketStatusDot", OBJPROP_TEXT, "•");
      ObjectSetInteger(0, "MarketStatusDot", OBJPROP_COLOR, clrCrimson);
   }
      ChartRedraw();
}


// 1. WICHTIG: SafeUpdateText() Funktion fehlt - MUSS HINZUGEFÜGT WERDEN
bool SafeUpdateText(string object_name, string new_text)
{
   if(object_name == "")
   {
      Print(__FUNCTION__, " > Error: Empty object name!");
      return false;
   }
   
   if(ObjectFind(0, object_name) < 0)
   {
      Print(__FUNCTION__, " > Error: Object '", object_name, "' not found!");
      return false;
   }
   
   if(StringLen(new_text) > 255)
   {
      Print(__FUNCTION__, " > Warning: Text too long, truncating...");
      new_text = StringSubstr(new_text, 0, 255);
   }
   
   if(!ObjectSetString(0, object_name, OBJPROP_TEXT, new_text))
   {
      Print(__FUNCTION__, " > Error: Failed to update text for '", object_name, "'");
      return false;
   }
   
   return true;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SaveSettings()
  {
// Webhook URLs konvertieren - NUR DIE WORKING VARIABLEN VERWENDEN!
   ArrayInitialize(g_Settings.webhook_m1, 0);
   if(working_webhook_m1 != "")
      StringToCharArray(working_webhook_m1, g_Settings.webhook_m1, 0, StringLen(working_webhook_m1));

   ArrayInitialize(g_Settings.webhook_m2, 0);
   if(working_webhook_m2 != "")
      StringToCharArray(working_webhook_m2, g_Settings.webhook_m2, 0, StringLen(working_webhook_m2));

   ArrayInitialize(g_Settings.webhook_m5, 0);
   if(working_webhook_m5 != "")
      StringToCharArray(working_webhook_m5, g_Settings.webhook_m5, 0, StringLen(working_webhook_m5));

   ArrayInitialize(g_Settings.webhook_m10, 0);
   if(working_webhook_m10 != "")
      StringToCharArray(working_webhook_m10, g_Settings.webhook_m10, 0, StringLen(working_webhook_m10));

   ArrayInitialize(g_Settings.webhook_m15, 0);
   if(working_webhook_m15 != "")
      StringToCharArray(working_webhook_m15, g_Settings.webhook_m15, 0, StringLen(working_webhook_m15));

   ArrayInitialize(g_Settings.webhook_h1, 0);
   if(working_webhook_h1 != "")
      StringToCharArray(working_webhook_h1, g_Settings.webhook_h1, 0, StringLen(working_webhook_h1));

   ArrayInitialize(g_Settings.webhook_default, 0);
   if(working_webhook_default != "")
      StringToCharArray(working_webhook_default, g_Settings.webhook_default, 0, StringLen(working_webhook_default));

// Button Settings
   g_Settings.show_tp_button = working_ShowTPButton;
   g_Settings.tp_button_bgcolor = TPButton_bgcolor;
   g_Settings.tp_button_font_color = TPButton_font_color;
   g_Settings.tp_button_font_size = TPButton_font_size;
   g_Settings.tp_button_distance = TPButtonDistancefromright;

   g_Settings.sl_button_bgcolor = SLButton_bgcolor;
   g_Settings.sl_button_font_color = SLButton_font_color;
   g_Settings.sl_button_font_size = SLButton_font_size;

   g_Settings.price_button_bgcolor = PriceButton_bgcolor;
   g_Settings.price_button_font_color = PriceButton_font_color;
   g_Settings.price_button_font_size = PriceButton_font_size;

   g_Settings.entry_line_color = EntryLine;
   g_Settings.tp_line_color = TPLine;
   g_Settings.sl_line_color = SLLine;

   g_Settings.send_only = SendOnlyButton;
   g_Settings.sabio_edit = Sabioedit;
   g_Settings.sabio_prices = SabioPrices;
   g_Settings.message_box_sound = MessageBoxSound;
   g_Settings.risk_money = riskMoney;
   g_Settings.distance_from_right = DistancefromRight;



   g_Settings.is_long_trade_active = is_long_trade;
   g_Settings.is_sell_trade_active = is_sell_trade;
   g_Settings.last_trade_number = last_trade_nummer;

// TradeInfo Strukturen zerlegt speichern
   g_Settings.long_trade_tradenummer = tradeInfo[0].tradenummer;
   g_Settings.long_trade_price = tradeInfo[0].price;
   g_Settings.long_trade_sl = tradeInfo[0].sl;
   g_Settings.long_trade_tp = tradeInfo[0].tp;
   g_Settings.long_trade_was_send = tradeInfo[0].was_send;

   g_Settings.short_trade_tradenummer = tradeInfo[1].tradenummer;
   g_Settings.short_trade_price = tradeInfo[1].price;
   g_Settings.short_trade_sl = tradeInfo[1].sl;
   g_Settings.short_trade_tp = tradeInfo[1].tp;
   g_Settings.short_trade_was_send = tradeInfo[1].was_send;

// Button/Label Status speichern (als uint)
   g_Settings.long_trade_label_bgcolor = (uint)ObjectGetInteger(0, "ActiveLongTrade", OBJPROP_BGCOLOR);
   g_Settings.long_trade_label_color = (uint)ObjectGetInteger(0, "ActiveLongTrade", OBJPROP_COLOR);
   g_Settings.short_trade_label_bgcolor = (uint)ObjectGetInteger(0, "ActiveShortTrade", OBJPROP_BGCOLOR);
   g_Settings.short_trade_label_color = (uint)ObjectGetInteger(0, "ActiveShortTrade", OBJPROP_COLOR);


// Button/Label Status speichern
// g_Settings.long_trade_label_bgcolor = ObjectGetInteger(0, "ActiveLongTrade", OBJPROP_BGCOLOR); // DOPPELT GEMOPPELT
// g_Settings.long_trade_label_color = ObjectGetInteger(0, "ActiveLongTrade", OBJPROP_COLOR); // DOPPELT GEMOPPELT
// g_Settings.short_trade_label_bgcolor = ObjectGetInteger(0, "ActiveShortTrade", OBJPROP_BGCOLOR);// DOPPELT GEMOPPELT
// g_Settings.short_trade_label_color = ObjectGetInteger(0, "ActiveShortTrade", OBJPROP_COLOR);// DOPPELT GEMOPPELT


// Version String korrekt konvertieren
   ArrayInitialize(g_Settings.last_settings_version, 0);
   string version = "1.04.18";
   StringToCharArray(version, g_Settings.last_settings_version, 0, StringLen(version));

// Speichere in Datei
   string filename = _Symbol + "_" + PeriodToString(Period()) + "_TradeAssistant_Settings.dat";
   int handle = FileOpen(filename, FILE_WRITE|FILE_BIN);

   if(handle == INVALID_HANDLE)
     {
      Print("Failed to save settings: ", GetLastError());
      return false;
     }

   FileWriteStruct(handle, g_Settings);
   FileClose(handle);

   Print("Settings saved successfully to ", filename);
   return true;


  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string PeriodToString(ENUM_TIMEFRAMES period)
  {
   switch(period)
     {
      case PERIOD_M1:
         return "M1";
      case PERIOD_M2:
         return "M2";
      case PERIOD_M5:
         return "M5";
      case PERIOD_M10:
         return "M10";
      case PERIOD_M15:
         return "M15";
      case PERIOD_M30:
         return "M30";
      case PERIOD_H1:
         return "H1";
      case PERIOD_H4:
         return "H4";
      case PERIOD_D1:
         return "D1";
      case PERIOD_W1:
         return "W1";
      case PERIOD_MN1:
         return "MN1";
      default:
         return "Unknown";
     }
  }
// 3. ERWEITERTE LoadSettings() MIT ALLEN WEBHOOKS:

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool LoadSettings()
  {
   string filename = _Symbol + "_" + PeriodToString(Period()) + "_TradeAssistant_Settings.dat";

   if(!FileIsExist(filename))
     {
      Print("Settings file not found: ", filename);
      // Initialisiere ALLE Arbeits-Variablen mit Input-Werten
      working_webhook_m1 = WebhookM1;
      working_webhook_m2 = WebhookM2;
      working_webhook_m5 = WebhookM5;
      working_webhook_m10 = WebhookM10;
      working_webhook_m15 = WebhookM15;
      working_webhook_m30 = WebhookM30;
      working_webhook_h1 = WebhookH1;
      working_webhook_default = WebhookDefault;
      return false;
     }
   else
     {
      Print("File: ",filename," gefunden");
     }

   int handle = FileOpen(filename, FILE_READ|FILE_BIN);
   if(handle == INVALID_HANDLE)
     {
      Print("Failed to load settings: ", GetLastError());
      return false;
     }

   FileReadStruct(handle, g_Settings);
   FileClose(handle);


   is_long_trade = g_Settings.is_long_trade_active;
   is_sell_trade = g_Settings.is_sell_trade_active;
   last_trade_nummer = g_Settings.last_trade_number;

// Lade Webhooks in Arbeits-Variablen
   string loaded_m1 = CharArrayToString(g_Settings.webhook_m1);
   string loaded_m2 = CharArrayToString(g_Settings.webhook_m2);
   string loaded_m5 = CharArrayToString(g_Settings.webhook_m5);
   string loaded_m10 = CharArrayToString(g_Settings.webhook_m10);
   string loaded_m15 = CharArrayToString(g_Settings.webhook_m15);
   string loaded_m30 = CharArrayToString(g_Settings.webhook_m30);
   string loaded_h1 = CharArrayToString(g_Settings.webhook_h1);
   string loaded_default = CharArrayToString(g_Settings.webhook_default);

// Priorität: Input-Parameter > Gespeicherte Werte
   working_webhook_m1 = (WebhookM1 != "") ? WebhookM1 : loaded_m1;  // M1 nicht in Settings gespeichert
   working_webhook_m2 = (WebhookM2 != "") ? WebhookM2 : loaded_m2;
   working_webhook_m5 = (WebhookM5 != "") ? WebhookM5 : loaded_m5;
   working_webhook_m10 = (WebhookM10 != "") ? WebhookM10 : loaded_m10;  // M10 nicht in Settings
   working_webhook_m15 = (WebhookM15 != "") ? WebhookM15 : loaded_m15;  // M15 nicht in Settings
   working_webhook_m30 = (WebhookM30 != "") ? WebhookM30 : loaded_m30;  // M30 nicht in Settings
   working_webhook_h1 = (WebhookH1 != "") ? WebhookH1 : loaded_h1;
   working_webhook_default = (WebhookDefault != "") ? WebhookDefault : loaded_default;

   string version_str = CharArrayToString(g_Settings.last_settings_version);




// TradeInfo Strukturen zerlegt wiederherstellen
   tradeInfo[0].tradenummer = g_Settings.long_trade_tradenummer;
   tradeInfo[0].price = g_Settings.long_trade_price;
   tradeInfo[0].sl = g_Settings.long_trade_sl;
   tradeInfo[0].tp = g_Settings.long_trade_tp;
   tradeInfo[0].was_send = g_Settings.long_trade_was_send;

   tradeInfo[1].tradenummer =  g_Settings.short_trade_tradenummer;
   tradeInfo[1].price = g_Settings.short_trade_price;
   tradeInfo[1].sl = g_Settings.short_trade_sl;
   tradeInfo[1].tp = g_Settings.short_trade_tp;
   tradeInfo[1].was_send = g_Settings.short_trade_was_send;

   working_ShowTPButton=g_Settings.show_tp_button;


// Button/Label Status wiederherstellen (als color)
   if(is_long_trade)
     {

      Print("Stelle ActiveLongTrade Button wieder her");
      ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_BGCOLOR, (color)g_Settings.long_trade_label_bgcolor);
      ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_COLOR, (color)g_Settings.long_trade_label_color);
      update_Text("ActiveLongTrade", "ACTIVE POSITION");

      // Hier ggf. noch weitere Objekte (Linien, Labels) wiederherstellen
      CreateTPSLLines(TP_Long,TimeCurrent(),tradeInfo[0].tp,TradeTPLineLong);
      if(!working_ShowTPButton)
        {
         ObjectSetInteger(0, TP_Long, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        }
      CreateTPSLLines(SL_Long,TimeCurrent(),tradeInfo[0].sl,TradeSLLineLong);
      CreateTPSLLines(Entry_Long,TimeCurrent(),tradeInfo[0].price,TradeEntryLineLong);
      CreateLabelsLong();
     }

   if(is_sell_trade)
     {
      ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_BGCOLOR, (color)g_Settings.short_trade_label_bgcolor);
      ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_COLOR, (color)g_Settings.short_trade_label_color);
      update_Text("ActiveShortTrade", "ACTIVE POSITION");

      // Hier ggf. noch weitere Objekte (Linien, Labels) wiederherstellen
      CreateTPSLLines(TP_Short,TimeCurrent(),tradeInfo[1].tp,TradeTPLineShort);
      if(!working_ShowTPButton)
        {
         ObjectSetInteger(0, TP_Short, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        }
      CreateTPSLLines(SL_Short,TimeCurrent(),tradeInfo[1].sl,TradeSLLineShort);
      CreateTPSLLines(Entry_Short,TimeCurrent(),tradeInfo[1].price,TradeEntryLineShort);
      CreateLabelsShort();
     }


   Print("=== Settings Loaded ===");
   Print("Trade number continuing from: ", last_trade_nummer);
   Print("Long Trade Active: ", is_long_trade);
   Print("Short Trade Active: ", is_sell_trade);
   Print("Version: ", version_str);
   Print("Webhooks loaded: M1=", (working_webhook_m1 != "" ? "✓" : "✗"),
         ", M2=", (working_webhook_m2 != "" ? "✓" : "✗"),
         ", M5=", (working_webhook_m5 != "" ? "✓" : "✗"),
         ", M10=", (working_webhook_m10 != "" ? "✓" : "✗"),
         ", M15=", (working_webhook_m15 != "" ? "✓" : "✗"),
         ", M30=", (working_webhook_m30 != "" ? "✓" : "✗"),
         ", H1=", (working_webhook_h1 != "" ? "✓" : "✗"));

   Print("tradeInfo[0].tradenummer =",tradeInfo[0].tradenummer);
   Print("tradeInfo[0].price = ",tradeInfo[0].price);
   Print("tradeInfo[0].sl = ",tradeInfo[0].sl);
   Print("tradeInfo[0].tp =",tradeInfo[0].tp) ;
   Print("tradeInfo[0].was_send =", tradeInfo[0].was_send);

   Print("tradeInfo[1].tradenummer = ", tradeInfo[1].tradenummer);
   Print("tradeInfo[1].price = ",tradeInfo[1].price);
   Print("tradeInfo[1].sl = ",tradeInfo[1].sl);
   Print("tradeInfo[1].tp = ",tradeInfo[1].tp);
   Print("tradeInfo[1].was_send =",tradeInfo[1].was_send) ;



   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ExportSettingsAsText()
  {
   string filename = _Symbol + "_TradeAssistant_Settings.txt";
   int handle = FileOpen(filename, FILE_WRITE|FILE_TXT);

   if(handle == INVALID_HANDLE)
      return;

   FileWriteString(handle, "=== Trade Assistant Settings ===\n");
   FileWriteString(handle, "Symbol: " + _Symbol + "\n");
   FileWriteString(handle, "Version: " + CharArrayToString(g_Settings.last_settings_version) + "\n");
   FileWriteString(handle, "Last Trade: " + IntegerToString(g_Settings.last_trade_number) + "\n");
   FileWriteString(handle, "\n[Discord Webhooks]\n");

// Konvertiere char arrays zurück zu strings für die Anzeige
   string webhook_m2_str = CharArrayToString(g_Settings.webhook_m2);
   string webhook_m5_str = CharArrayToString(g_Settings.webhook_m5);
   string webhook_h1_str = CharArrayToString(g_Settings.webhook_h1);

   FileWriteString(handle, "M2: " + (webhook_m2_str != "" ? "Configured" : "Not configured") + "\n");
   FileWriteString(handle, "M5: " + (webhook_m5_str != "" ? "Configured" : "Not configured") + "\n");
   FileWriteString(handle, "H1: " + (webhook_h1_str != "" ? "Configured" : "Not configured") + "\n");
   FileWriteString(handle, "\n[Risk Settings]\n");
   FileWriteString(handle, "Risk Amount: " + IntegerToString(g_Settings.risk_money) + "\n");

   FileClose(handle);
   Print("Settings exported to ", filename);
  }



//+------------------------------------------------------------------+
//| Reset Settings auf Defaults                                     |
//+------------------------------------------------------------------+
void ResetSettingsToDefaults()
  {
   if(MessageBox("Wirklich alle Settings zurücksetzen?", "Settings Reset", MB_YESNO) == IDYES)
     {
      // Lösche Settings-Datei
      string filename = _Symbol + "_TradeAssistant_Settings.dat";
      if(FileIsExist(filename))
        {
         FileDelete(filename);
        }

      // Reset Trade-Nummer
      tradenummer = 0;
      last_trade_nummer = 0;

      Print("Settings reset to defaults");
      MessageBox("Settings wurden zurückgesetzt.\nBitte EA neu starten.", "Reset Complete", MB_OK);
     }
  }



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {



   if(g_parameters_changed)
     {
      Print("Parameter wurden geändert. Speichere aktuelle Parameter.");
      SaveSettings(); // Speichere die aktuellen (geänderten) Parameter
      g_parameters_changed = false; // Variable zurücksetzen
     }

   Entry_Price = StringToDouble(Get_Price_s(PR_HL));
   TP_Price = StringToDouble(Get_Price_s(TP_HL));
   SL_Price = StringToDouble(Get_Price_s(SL_HL));

   tradeInfo[0].tradenummer=-1;
   tradeInfo[0].symbol = _Symbol;
   tradeInfo[0].type = "BUY";
   tradeInfo[0].price = Entry_Price;
   tradeInfo[0].sl = SL_Price;
   tradeInfo[0].tp = TP_Price;
   tradeInfo[0].was_send=false;

   tradeInfo[1].tradenummer=-1;
   tradeInfo[1].symbol = _Symbol;
   tradeInfo[1].type = "SELL";
   tradeInfo[1].price = Entry_Price;
   tradeInfo[1].sl = SL_Price;
   tradeInfo[1].tp = TP_Price;
   tradeInfo[1].was_send=false;

   MessageButton();
   InfoLabel();
   LabelTradeNumber();
   NotizEdit();


   string current_parameters_hash = CalculateHashOfParameters();
   GlobalVariableSet("PS_ParametersHash_" + string(ChartID()), current_parameters_hash); //Eindeutiger Name durch ChartID

//Init und Test Discord Api
// Init und Test Discord Api

// Lade gespeicherte Settings
   if(LoadSettings())
     {
      tradenummer = last_trade_nummer + 1;
      Print("Continuing from trade number: ", tradenummer);
      UpdateTradeNumberDisplay();
     }
   else
     {
      // Keine Settings gefunden - starte bei 0
      tradenummer = 0;
      isBuy=true;
      last_trade_nummer=0;
      is_long_trade=false;
      is_sell_trade=false;

      Print("Starting fresh with trade number: ", tradenummer);
      UpdateTradeNumberDisplay();
     }

   UpdateTradeNumberDisplay();
   if(checkDiscord())
     {
      PrintWebhookStatus();  // NEU: Status ausgeben
     }

   createButton(TPButton, "", getChartWidthInPixels()-DistancefromRight-TPButtonDistancefromright,getChartHeightInPixels()/2,280, 30, TPButton_font_color, TPButton_bgcolor, TPButton_font_size, clrNONE, "Arial Black");

// EINZIGE NEUE ZEILE: Unsichtbar machen wenn gewünscht
   if(!working_ShowTPButton)
     {
      ObjectSetInteger(0, TPButton, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
     }

// TP Button
   xd1 = (int)ObjectGetInteger(0, TPButton, OBJPROP_XDISTANCE);
   yd1 = (int)ObjectGetInteger(0, TPButton, OBJPROP_YDISTANCE);
   xs1 = (int)ObjectGetInteger(0, TPButton, OBJPROP_XSIZE);
   ys1 = (int)ObjectGetInteger(0, TPButton, OBJPROP_YSIZE);

// Button at price
   xd3 = xd1;
   yd3 = yd1 + (100);
   xs3 = xs1;
   ys3 = 30;

// SL Button
   xd5 = xd1;
   yd5 = yd3 + 100;
   xs5 = xs1;
   ys5 = 30;

   datetime dt_tp = iTime(_Symbol, 0, 0), dt_sl = iTime(_Symbol, 0, 0), dt_prc = iTime(_Symbol, 0, 0);
   double price_tp = iClose(_Symbol, 0, 0), price_sl = iClose(_Symbol, 0, 0), price_prc = iClose(_Symbol, 0, 0);
   int window = 0;

   ChartXYToTimePrice(0, xd1, yd1 + ys1, window, dt_tp, price_tp);
   ChartXYToTimePrice(0, xd3, yd3 + ys3, window, dt_prc, price_prc);
   ChartXYToTimePrice(0, xd5, yd5 + ys5, window, dt_sl, price_sl);

   createHL(TP_HL, dt_tp, price_tp, TPLine);

   if(!working_ShowTPButton)
     {
      ObjectSetInteger(0, TP_HL, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
     }

   createHL(PR_HL, dt_prc, price_prc, EntryLine);
   createHL(SL_HL, dt_sl, price_sl, SLLine);

   ObjectMove(0, TPButton, 0, dt_tp, price_tp);
   ObjectMove(0, EntryButton, 0, dt_prc, price_prc);
   ObjectMove(0, SLButton, 0, dt_sl, price_sl);

//   DrawHL();
   if(Sabioedit)
     {
      SabioEdit();
      if(!working_ShowTPButton && Sabioedit)
        {
         ObjectSetInteger(0, SabioTP, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        }
     }

   SendButton();
   if(!SendOnlyButton)
     {
      ObjectSetString(0, BTN2, OBJPROP_TEXT, "T & S"); // label
      ObjectSetInteger(0, BTN2, OBJPROP_BGCOLOR, TSButton_bgcolor);
      ObjectSetInteger(0, BTN2, OBJPROP_COLOR, TSButton_font_color);
     }
   double lots = calcLots(SL_Price - Entry_Price);
   lots = NormalizeDouble(lots,2);

   createButton(EntryButton, "", xd3, yd3, xs3, ys3, PriceButton_font_color, PriceButton_bgcolor, PriceButton_font_size, clrNONE, "Arial Black");
   createButton(SLButton, "", xd5, yd5, xs5, ys5, SLButton_font_color, SLButton_bgcolor, SLButton_font_size, clrNONE, "Arial Black");
   if(working_ShowTPButton)
     {
      update_Text(TPButton, "TP: " + DoubleToString(((Get_Price_d(TP_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
     }
   update_Text(EntryButton, "Buy Stop @ " + Get_Price_s(PR_HL) +" | Lot: " + DoubleToString(lots,2));
   update_Text(SLButton, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   ChartRedraw(0);




   ChartSetInteger(0,CHART_MOUSE_SCROLL,0,false);
   ChartSetInteger(0,CHART_SHOW_GRID,0,false);
// Markt-Status Panel erstellen
   CreateMarketStatusPanel();
   DebugMarketStatus();  // Zeigt alle relevanten Infos im Log
   // WICHTIG: Initial Markt-Status prüfen
   g_market_status = CheckMarketStatus();
   UpdateMarketStatusDisplay();
   UpdateSendButtonState();
   
   return (INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
// 1. Reason loggen für Debugging
   string reason_text = "";
   switch(reason)
     {
      case REASON_PROGRAM:
         reason_text = "Program terminated";
         break;
      case REASON_REMOVE:
         reason_text = "Program removed from chart";
         break;
      case REASON_RECOMPILE:
         reason_text = "Program recompiled";
         break;
      case REASON_CHARTCHANGE:
         reason_text = "Chart symbol or period changed";
         break;
      case REASON_CHARTCLOSE:
         reason_text = "Chart closed";
         break;
      case REASON_PARAMETERS:
         reason_text = "Input parameters changed";
         break;
      case REASON_ACCOUNT:
         reason_text = "Account changed";
         break;
      default:
         reason_text = "Other reason";
     }

   Print("=== EA Deinitialization: ", reason_text, " ===");

// 2. Aktuelle Trade-States speichern (für spätere Erweiterung)
   if(is_long_trade || is_sell_trade)
     {
      Print("Active trades detected during shutdown:");
      if(is_long_trade)
         Print("- Long trade #", tradeInfo[0].tradenummer);
      if(is_sell_trade)
         Print("- Short trade #", tradeInfo[1].tradenummer);
      // Hier könnte später SaveTradeState() aufgerufen werden
     }

// 3. Discord Cleanup
   if(isWebRequestEnabled)
     {
      // Optional: Shutdown-Nachricht senden
      // SendDiscordMessage("EA shutting down on " + _Symbol);
     }
// Speichere Settings vor dem Beenden
   if(reason != REASON_RECOMPILE)  // Nicht bei Recompile speichern
     {
      SaveSettings();
     }

// 4. Alle Objekte löschen
   deleteObjects();

// 5. Chart Events deaktivieren
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, false);

   GlobalVariableDel("PS_ParametersHash_" + string(ChartID())); //Eindeutiger Name durch ChartID



   Print("=== EA Cleanup completed ===");
  }

// Price Cache Variablen
double cached_ask_price = 0;
double cached_bid_price = 0;
datetime last_price_update = 0;

// Label Update Flags
bool need_label_update_long = true;
bool need_label_update_short = true;

//+------------------------------------------------------------------+
//| ERWEITERTE OnTick() MIT MARKT-ÜBERWACHUNG                       |
//+------------------------------------------------------------------+
void OnTick()
{
   static datetime last_market_check = 0;
   datetime current_time = TimeCurrent();
   
   // Prüfe Markt-Status alle 60 Sekunden
   if(current_time - last_market_check > 60)
   {
      UpdateMarketStatusDisplay();
      UpdateSendButtonState();
      last_market_check = current_time;
   }
    // Blinkeffekt bei geschlossenem Markt
   if(!g_market_status.is_open)
   {
      MarketClosedWarningBlink();
   }
   // Nur bei offenem Markt Preise aktualisieren
   if(g_market_status.is_open && g_market_status.has_valid_prices)
   {
      // Dein existierender OnTick Code hier...
      if(current_time > last_price_update)
      {
         double new_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double new_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

         if(new_ask != cached_ask_price || new_bid != cached_bid_price)
         {
            CurrentAskPrice = cached_ask_price = new_ask;
            CurrentBidPrice = cached_bid_price = new_bid;
            last_price_update = current_time;

            if(is_long_trade)
               need_label_update_long = true;
            if(is_sell_trade)
               need_label_update_short = true;
         }
         else
         {
            CurrentAskPrice = cached_ask_price;
            CurrentBidPrice = cached_bid_price;
         }
      }

      if(is_long_trade || is_sell_trade)
      {
         TPSLReached();
      }

      if(is_long_trade && need_label_update_long)
      {
         CreateLabelsLong();
         need_label_update_long = false;
      }

      if(is_sell_trade && need_label_update_short)
      {
         CreateLabelsShort();
         need_label_update_short = false;
      }
   }
}

//+------------------------------------------------------------------+

int prevMouseState = 0;

int mlbDownX1 = 0;
int mlbDownY1 = 0;
int mlbDownXD_R1 = 0;
int mlbDownYD_R1 = 0;

int mlbDownX2 = 0;
int mlbDownY2 = 0;
int mlbDownXD_R2 = 0;
int mlbDownYD_R2 = 0;

int mlbDownX3 = 0;
int mlbDownY3 = 0;
int mlbDownXD_R3 = 0;
int mlbDownYD_R3 = 0;

int mlbDownX4 = 0;
int mlbDownY4 = 0;
int mlbDownXD_R4 = 0;
int mlbDownYD_R4 = 0;

int mlbDownX5 = 0;
int mlbDownY5 = 0;
int mlbDownXD_R5 = 0;
int mlbDownYD_R5 = 0;

bool movingState_R1 = false;
bool movingState_R3 = false;
bool movingState_R5 = false;



//+------------------------------------------------------------------+
//| Update Button und Line Positionen                                |
//+------------------------------------------------------------------+
void UpdateButtonPosition(string button_name, string line_name, int new_y_pos)
  {
   ObjectSetInteger(0, button_name, OBJPROP_YDISTANCE, new_y_pos);

// Update der zugehörigen Linie
   datetime dt = 0;
   double price = 0;
   int window = 0;
   int x_pos = (int)ObjectGetInteger(0, button_name, OBJPROP_XDISTANCE);
   int y_size = (int)ObjectGetInteger(0, button_name, OBJPROP_YSIZE);

   ChartXYToTimePrice(0, x_pos, new_y_pos + y_size, window, dt, price);
   ObjectSetInteger(0, line_name, OBJPROP_TIME, dt);
   ObjectSetDouble(0, line_name, OBJPROP_PRICE, price);
  }

//+------------------------------------------------------------------+
//| Update Preis Labels für alle Buttons                            |
//+------------------------------------------------------------------+
void UpdatePriceLabels()
  {
   double tp_price = Get_Price_d(TP_HL);
   double m_entry_price = Get_Price_d(PR_HL);
   double sl_price = Get_Price_d(SL_HL);
   Print("Entry_price :"+m_entry_price);
   Print("CurrentAskPrice :"+CurrentAskPrice);
   Print("CurrentBidPrice :"+CurrentBidPrice);
// Prüfe ob Short oder Long
   bool is_short = (sl_price > tp_price);

// Berechne Lots
   double lots = 0;
   if(is_short)
     {
      lots = calcLots(sl_price - m_entry_price);
      isBuy = 0;
     }
   else
     {
      lots = calcLots(m_entry_price - sl_price);
      isBuy = 1;
     }
   lots = NormalizeDouble(lots, 2);

// Update Button Texte
   string order_type = is_short ? "Sell Stop" : "Buy Stop";
   update_Text(EntryButton, order_type + " @ " + Get_Price_s(PR_HL) + " | Lot: " + DoubleToString(lots, 2));

   if(working_ShowTPButton)
     {
      double tp_points = is_short ?
                         (m_entry_price - tp_price) / _Point :
                         (tp_price - m_entry_price) / _Point;
      update_Text(TPButton, "TP: " + DoubleToString(tp_points, 0) + " Points | " + Get_Price_s(TP_HL));
     }

   double sl_points = is_short ?
                      (sl_price - m_entry_price) / _Point :
                      (m_entry_price - sl_price) / _Point;
   update_Text(SLButton, "SL: " + DoubleToString(sl_points, 0) + " Points | " + Get_Price_s(SL_HL));
  }

//+------------------------------------------------------------------+
//| Update Sabio Preis Felder                                       |
//+------------------------------------------------------------------+
void UpdateSabioPriceFields()
  {
   if(SabioPrices)
     {
      update_Text(SabioEntry, "SABIO Entry: " + Get_Price_s(PR_HL));
      if(working_ShowTPButton)
         update_Text(SabioTP, "SABIO TP: " + Get_Price_s(TP_HL));
      update_Text(SabioSL, "SABIO SL: " + Get_Price_s(SL_HL));
     }
   else
     {
      update_Text(SabioEntry, "SABIO ENTRY: ");
      if(working_ShowTPButton)
         update_Text(SabioTP, "SABIO TP: ");
      update_Text(SabioSL, "SABIO SL: ");
     }
  }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // Identifikator des Ereignisses
                  const long &lparam,   // Parameter des Ereignisses des Typs long, X cordinates
                  const double &dparam, // Parameter des Ereignisses des Typs double, Y cordinates
                  const string &sparam)  // Parameter des Ereignisses des Typs string, name of the object, state
  {

   if(id == CHARTEVENT_CHART_CHANGE)
     {
      // 1. Hash-Wert der Parameter berechnen
      string current_parameters_hash = CalculateHashOfParameters();

      // 2. Globale Variable auslesen

      string stored_parameters_hash = GlobalVariableGet("PS_ParametersHash_" + string(ChartID())); //Eindeutiger Name durch ChartID
      // 3. Vergleichen
      if(current_parameters_hash != stored_parameters_hash)
        {
         // Parameter haben sich geändert!
         Print("Parameter wurden geändert. Speichere Einstellungen.");

         // 4. Einstellungen speichern
         SaveSettings();

         // 5. Globale Variable aktualisieren
         GlobalVariableSet("PS_ParametersHash_" + string(ChartID()), current_parameters_hash); //Eindeutiger Name durch ChartID
        }
     }


   Entry_Price = StringToDouble(Get_Price_s(PR_HL));
   TP_Price = StringToDouble(Get_Price_s(TP_HL));
   SL_Price = StringToDouble(Get_Price_s(SL_HL));

   if(id == CHARTEVENT_MOUSE_MOVE)
     {
      int MouseD_X = (int)lparam;
      int MouseD_Y = (int)dparam;
      int MouseState = (int)sparam;

      int XD_R1 = (int)ObjectGetInteger(0, TPButton, OBJPROP_XDISTANCE);
      int YD_R1 = (int)ObjectGetInteger(0, TPButton, OBJPROP_YDISTANCE);
      int XS_R1 = (int)ObjectGetInteger(0, TPButton, OBJPROP_XSIZE);
      int YS_R1 = (int)ObjectGetInteger(0, TPButton, OBJPROP_YSIZE);

      int XD_R3 = (int)ObjectGetInteger(0, EntryButton, OBJPROP_XDISTANCE);
      int YD_R3 = (int)ObjectGetInteger(0, EntryButton, OBJPROP_YDISTANCE);
      int XS_R3 = (int)ObjectGetInteger(0, EntryButton, OBJPROP_XSIZE);
      int YS_R3 = (int)ObjectGetInteger(0, EntryButton, OBJPROP_YSIZE);

      int XD_R5 = (int)ObjectGetInteger(0, SLButton, OBJPROP_XDISTANCE);
      int YD_R5 = (int)ObjectGetInteger(0, SLButton, OBJPROP_YDISTANCE);
      int XS_R5 = (int)ObjectGetInteger(0, SLButton, OBJPROP_XSIZE);
      int YS_R5 = (int)ObjectGetInteger(0, SLButton, OBJPROP_YSIZE);

      if(prevMouseState == 0 && MouseState == 1)  // 1 = true: clicked left mouse btn
        {
         mlbDownX1 = MouseD_X;
         mlbDownY1 = MouseD_Y;
         mlbDownXD_R1 = XD_R1;
         mlbDownYD_R1 = YD_R1;

         mlbDownX3 = MouseD_X;
         mlbDownY3 = MouseD_Y;
         mlbDownXD_R3 = XD_R3;
         mlbDownYD_R3 = YD_R3;

         mlbDownX5 = MouseD_X;
         mlbDownY5 = MouseD_Y;
         mlbDownXD_R5 = XD_R5;
         mlbDownYD_R5 = YD_R5;

         if(working_ShowTPButton && MouseD_X >= XD_R1 && MouseD_X <= XD_R1 + XS_R1 &&
            MouseD_Y >= YD_R1 && MouseD_Y <= YD_R1 + YS_R1)
           {
            movingState_R1 = true;
           }

         if(MouseD_X >= XD_R3 && MouseD_X <= XD_R3 + XS_R3 &&
            MouseD_Y >= YD_R3 && MouseD_Y <= YD_R3 + YS_R3)
           {
            movingState_R3 = true;
           }

         if(MouseD_X >= XD_R5 && MouseD_X <= XD_R5 + XS_R5 &&
            MouseD_Y >= YD_R5 && MouseD_Y <= YD_R5 + YS_R5)
           {
            movingState_R5 = true;
           }
        }



      if(working_ShowTPButton && movingState_R1)
        {
         ChartSetInteger(0, CHART_MOUSE_SCROLL, false);

         // Update Positionen
         int new_tp_y = mlbDownYD_R1 + MouseD_Y - mlbDownY1;
         int new_sl_y = mlbDownYD_R5 - MouseD_Y + mlbDownY1;

         UpdateButtonPosition(TPButton, TP_HL, new_tp_y);
         UpdateButtonPosition(SLButton, SL_HL, new_sl_y);

         // Update Sabio Felder Positionen
         if(Sabioedit)
           {
            ObjectSetInteger(0, SabioTP, OBJPROP_YDISTANCE, new_tp_y + 30);
            ObjectSetInteger(0, SabioSL, OBJPROP_YDISTANCE, new_sl_y + 30);
           }

         // Update alle Labels
         UpdatePriceLabels();
         UpdateSabioPriceFields();

         ChartRedraw(0);
        }



      if(movingState_R5)
        {
         ChartSetInteger(0, CHART_MOUSE_SCROLL, false);

         // Update Positionen
         int new_sl_y = mlbDownYD_R5 + MouseD_Y - mlbDownY5;
         UpdateButtonPosition(SLButton, SL_HL, new_sl_y);

         if(working_ShowTPButton)
           {
            int new_tp_y = mlbDownYD_R1 - MouseD_Y + mlbDownY5;
            UpdateButtonPosition(TPButton, TP_HL, new_tp_y);

            if(Sabioedit)
               ObjectSetInteger(0, SabioTP, OBJPROP_YDISTANCE, new_tp_y + 30);
           }

         if(Sabioedit)
            ObjectSetInteger(0, SabioSL, OBJPROP_YDISTANCE, new_sl_y + 30);

         // Update alle Labels
         UpdatePriceLabels();
         UpdateSabioPriceFields();

         ChartRedraw(0);
        }
      if(movingState_R3)
        {
         ChartSetInteger(0, CHART_MOUSE_SCROLL, false);

         // Update Entry Position
         int new_entry_y = mlbDownYD_R3 + MouseD_Y - mlbDownY3;
         UpdateButtonPosition(EntryButton, PR_HL, new_entry_y);

         // Update andere Buttons relativ
         if(working_ShowTPButton)
           {
            int new_tp_y = mlbDownYD_R1 + MouseD_Y - mlbDownY1;
            UpdateButtonPosition(TPButton, TP_HL, new_tp_y);
            if(Sabioedit)
               ObjectSetInteger(0, SabioTP, OBJPROP_YDISTANCE, new_tp_y + 30);
           }

         int new_sl_y = mlbDownYD_R5 + MouseD_Y - mlbDownY5;
         UpdateButtonPosition(SLButton, SL_HL, new_sl_y);

         // Update Send Button und Trade Nummer
         ObjectSetInteger(0, BTN2, OBJPROP_YDISTANCE, new_entry_y);
         ObjectSetInteger(0, TRNB, OBJPROP_YDISTANCE, new_entry_y + 30);

         // Update Sabio Felder
         if(Sabioedit)
           {
            ObjectSetInteger(0, SabioEntry, OBJPROP_YDISTANCE, new_entry_y + 30);
            ObjectSetInteger(0, SabioSL, OBJPROP_YDISTANCE, new_sl_y + 30);
           }

         // Update alle Labels
         UpdatePriceLabels();
         UpdateSabioPriceFields();

         ChartRedraw(0);
        }



      if(MouseState == 0)
        {
         movingState_R1 = false;
         movingState_R3 = false;
         movingState_R5 = false;
         ChartSetInteger(0, CHART_MOUSE_SCROLL, true);
        }
      prevMouseState = MouseState;
     }

   if(ObjectGetInteger(0, "Button1", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "Button1", OBJPROP_STATE, 0);
      return;
     }

// Klick Button Send only

   if(ObjectGetInteger(0, "SendOnlyButton", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "SendOnlyButton", OBJPROP_STATE, 0);
      if(Period()==PERIOD_M2 ||  Period()==PERIOD_M5 ||  Period()==PERIOD_H1)
         //      if(Period()==PERIOD_H1)
        {
         if(Sabioedit == true)
           {
            int result = MessageBox("Sabio Prices Insert?", NULL, MB_YESNO);
            //            MessageBoxSound = PlaySound(C:\Program Files\IC Markets (SC) Demo 51680033\Sounds\Alert2.wav);
            if(result == IDYES)
              {
               DiscordSend();
               //speichere alle Settings in die Datei
               SaveSettings();
              }
           }
         else
           {
            DiscordSend();
            //speichere alle Settings in die Datei
            SaveSettings();
           }
        }


      // NEU: Reagiere auf Änderungen im Tradenummer-Eingabefeld
      if(id == CHARTEVENT_OBJECT_ENDEDIT)
        {
         if(sparam == TRNB)  // Tradenummer-Eingabefeld wurde geändert
           {
            string eingabe;
            ObjectGetString(0, TRNB, OBJPROP_TEXT, 0, eingabe);
            int neue_nummer = (int)eingabe;

            if(neue_nummer > last_trade_nummer)
              {
               tradenummer = neue_nummer;
               Print("Trade number manually changed to: ", tradenummer);
              }
            else
              {
               // Ungültige Eingabe - zurücksetzen
               SafeUpdateText(TRNB, IntegerToString(last_trade_nummer + 1));
               ShowTradeError(ERR_INVALID_TRADE_NUMBER);
              }
           }

         if(sparam == SabioEntry || sparam == SabioSL)
           {
            UpdateSabioTP();
            SaveSettings();
           }
        }

      return;
     }

//+------------------------------------------------------------------+
//| Klick Button Cancel Long Order                                                             |
//+------------------------------------------------------------------+
   if(ObjectGetInteger(0, "ButtonCancelOrder", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_STATE, 0);
      if(is_long_trade)
        {
         if(!send_TP_buy && !send_SL_buy || !send_CL_buy)
           {
            //            // Send notification before placing trade
            string message = FormatCancelTradeMessage(tradeInfo[0]);
            bool ret= SendDiscordMessage(message);
            // Close open Buy Order
            DeleteBuyStopOrderForCurrentChart();
            is_long_trade=false;
            send_CL_buy=true;
            HitEntryPriceLong = false;
            ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_COLOR, clrNONE);
            ObjectSetInteger(0,"ActiveLongTrade", OBJPROP_BGCOLOR, clrNONE);
            DeleteLinesandLabelsLong();
            //speichere alle Settings in die Datei
            SaveSettings();
           }
        }
      return;
     }

//+------------------------------------------------------------------+
//|  Klick Button Cancel Short Order                                                                 |
//+------------------------------------------------------------------+
   if(ObjectGetInteger(0, "ButtonCancelOrderSell", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_STATE, 0);
      if(is_sell_trade)
        {
         if(!send_TP_sell && !send_SL_sell || !send_CL_sell)
           {
            // Send notification before placing trade
            string message = FormatCancelTradeMessage(tradeInfo[1]);
            bool ret= SendDiscordMessage(message);

            // Close open Sell Order
            DeleteSellStopOrderForCurrentChart();
            is_sell_trade=false;
            send_CL_sell=true;
            HitEntryPriceShort = false;
            ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_COLOR, clrNONE);
            ObjectSetInteger(0,"ActiveShortTrade", OBJPROP_BGCOLOR, clrNONE);
            DeleteLinesandLabelsShort();
            //speichere alle Settings in die Datei
            SaveSettings();
           }
        }
     }

   if(id == CHARTEVENT_OBJECT_ENDEDIT)
     {
      if(sparam == SabioEntry || sparam == SabioSL)
        {
         UpdateSabioTP();
         //speichere alle Settings in die Datei
         SaveSettings();
        }
     }


  }
//+------------------------------------------------------------------+
//| ERROR DESCRIPTION HELPER                                         |
//+------------------------------------------------------------------+
void PrintErrorDescription(int error_code)
  {
   string description = "";
   switch(error_code)
     {
      case 4001:
         description = "Wrong function parameter";
         break;
      case 4003:
         description = "No memory for function call stack";
         break;
      case 4004:
         description = "Recursive stack overflow";
         break;
      case 4006:
         description = "No memory for parameter string";
         break;
      case 4007:
         description = "No memory for temp string";
         break;
      case 4008:
         description = "Not initialized string";
         break;
      case 4009:
         description = "Not initialized string in array";
         break;
      case 4010:
         description = "No memory for array";
         break;
      case 4011:
         description = "Too long string";
         break;
      case 4012:
         description = "Remainder from zero divide";
         break;
      case 4013:
         description = "Zero divide";
         break;
      case 4014:
         description = "Unknown command";
         break;
      case 4015:
         description = "Wrong jump (never generated error)";
         break;
      case 4016:
         description = "Not initialized array";
         break;
      case 4017:
         description = "DLL calls are not allowed";
         break;
      case 4018:
         description = "Cannot load library";
         break;
      case 4019:
         description = "Cannot call function";
         break;
      case 4020:
         description = "Expert function calls are not allowed";
         break;
      case 4021:
         description = "Not enough memory for temp string returned from function";
         break;
      case 4022:
         description = "System is busy (never generated error)";
         break;
      case 4023:
         description = "DLL-function call critical error";
         break;
      case 4024:
         description = "Internal error";
         break;
      case 4025:
         description = "Out of memory";
         break;
      case 4026:
         description = "Invalid pointer";
         break;
      case 4027:
         description = "Too many formatters in the format function";
         break;
      case 4028:
         description = "Parameters count is more than formatters count";
         break;
      case 4029:
         description = "Invalid array";
         break;
      case 4030:
         description = "No reply from chart";
         break;
      default:
         description = "Unknown error";
         break;
     }
   Print("Error ", error_code, ": ", description);
  }
//+------------------------------------------------------------------+
//| Create Trading Button                                                                 |
//+------------------------------------------------------------------+
bool createButton(string objName, string text, int xD, int yD, int xS, int yS, color clrTxt, color clrBG, int fontsize = 12, color clrBorder = clrNONE, string font = "Calibri")
  {


   if(objName == "")
     {
      Print(__FUNCTION__, " > Error: Object name cannot be empty!");
      return false;
     }

   if(xD < 0 || yD < 0)
     {
      Print(__FUNCTION__, " > Error: Negative coordinates not allowed! xD=", xD, " yD=", yD);
      return false;
     }

   if(xS <= 0 || yS <= 0)
     {
      Print(__FUNCTION__, " > Error: Size must be positive! xS=", xS, " yS=", yS);
      return false;
     }

   if(fontsize < 6 || fontsize > 72)
     {
      Print(__FUNCTION__, " > Error: Font size out of range (6-72)! Got: ", fontsize);
      return false;
     }
   ResetLastError();
   if(!ObjectCreate(0, objName, OBJ_BUTTON, 0, 0, TimeCurrent()))
     {
      Print(__FUNCTION__, ": Failed to create Btn: Error Code: ", GetLastError());
      return (false);
     }


// 2. Chart Boundaries Check
   int chart_width = getChartWidthInPixels();
   int chart_height = getChartHeightInPixels();

   if(xD + xS > chart_width || yD + yS > chart_height)
     {
      Print(__FUNCTION__, " > Warning: Button outside chart boundaries!");
      Print("Chart: ", chart_width, "x", chart_height, " Button: ", xD+xS, "x", yD+yS);
      // Optional: Auto-adjust position
      xD = MathMin(xD, chart_width - xS);
      yD = MathMin(yD, chart_height - yS);
     }
// 3. Lösche existierendes Object falls vorhanden
   if(ObjectFind(0, objName) >= 0)
     {
      Print(__FUNCTION__, " > Info: Deleting existing object: ", objName);
      ObjectDelete(0, objName);
     }
// 4. Object Creation mit Error Handling
   ResetLastError();
   if(!ObjectCreate(0, objName, OBJ_BUTTON, 0, 0, TimeCurrent()))
     {
      int error = GetLastError();
      Print(__FUNCTION__, " > CRITICAL ERROR: Failed to create button '", objName, "' Error: ", error);
      PrintErrorDescription(error);
      return false;
     }

// 5. Setze Properties mit Einzelvalidierung
   if(!ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, xD))
     {
      Print(__FUNCTION__, " > Error setting XDISTANCE for ", objName);
      ObjectDelete(0, objName);
      return false;
     }

   if(!ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, yD))
     {
      Print(__FUNCTION__, " > Error setting YDISTANCE for ", objName);
      ObjectDelete(0, objName);
      return false;
     }

   if(!ObjectSetInteger(0, objName, OBJPROP_XSIZE, xS))
     {
      Print(__FUNCTION__, " > Error setting XSIZE for ", objName);
      ObjectDelete(0, objName);
      return false;
     }

   if(!ObjectSetInteger(0, objName, OBJPROP_YSIZE, yS))
     {
      Print(__FUNCTION__, " > Error setting YSIZE for ", objName);
      ObjectDelete(0, objName);
      return false;
     }

// 6. Weitere Properties mit Fallback-Werten
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, fontsize);
   ObjectSetString(0, objName, OBJPROP_FONT, font);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrTxt);
   ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, clrBG);
   ObjectSetInteger(0, objName, OBJPROP_BORDER_COLOR, clrBorder);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_STATE, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_CENTER);

   ChartRedraw(0);
   Print(__FUNCTION__, " > SUCCESS: Created button '", objName, "' at ", xD, ",", yD);
   return true;
  }

//+------------------------------------------------------------------+
//| Create Preislinien Trading Buttton                                                                 |
//+------------------------------------------------------------------+
bool createHL(string objName, datetime time1, double price1, color clr)
  {
// 1. Parameter Validation
   if(objName == "")
     {
      Print(__FUNCTION__, " > Error: Object name cannot be empty!");
      return false;
     }

   if(price1 <= 0)
     {
      Print(__FUNCTION__, " > Error: Invalid price! Got: ", price1);
      return false;
     }

   if(time1 <= 0)
     {
      Print(__FUNCTION__, " > Error: Invalid time! Got: ", time1);
      return false;
     }

// 2. Symbol-spezifische Validation
   double symbol_min = SymbolInfoDouble(_Symbol, SYMBOL_SESSION_PRICE_LIMIT_MIN);
   double symbol_max = SymbolInfoDouble(_Symbol, SYMBOL_SESSION_PRICE_LIMIT_MAX);

   if(symbol_min > 0 && price1 < symbol_min)
     {
      Print(__FUNCTION__, " > Warning: Price below symbol minimum! Price: ", price1, " Min: ", symbol_min);
     }

   if(symbol_max > 0 && price1 > symbol_max)
     {
      Print(__FUNCTION__, " > Warning: Price above symbol maximum! Price: ", price1, " Max: ", symbol_max);
     }

// 3. Lösche existierendes Object
   if(ObjectFind(0, objName) >= 0)
     {
      ObjectDelete(0, objName);
     }

// 4. Object Creation
   ResetLastError();
   if(!ObjectCreate(0, objName, OBJ_HLINE, 0, time1, price1))
     {
      int error = GetLastError();
      Print(__FUNCTION__, " > CRITICAL ERROR: Failed to create line '", objName, "' Error: ", error);
      PrintErrorDescription(error);
      return false;
     }

// 5. Properties setzen
   ObjectSetInteger(0, objName, OBJPROP_TIME, time1);
   ObjectSetDouble(0, objName, OBJPROP_PRICE, price1);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);

   ChartRedraw(0);
   Print(__FUNCTION__, " > SUCCESS: Created line '", objName, "' at price: ", price1);
   return true;
  }
//+------------------------------------------------------------------+
//| CHART BOUNDARIES VALIDATION                                      |
//+------------------------------------------------------------------+
bool ValidateChartBoundaries(int x, int y, int width, int height)
  {
   int chart_width = getChartWidthInPixels();
   int chart_height = getChartHeightInPixels();

   if(chart_width <= 0 || chart_height <= 0)
     {
      Print(__FUNCTION__, " > Error: Invalid chart dimensions! W=", chart_width, " H=", chart_height);
      return false;
     }

   if(x < 0 || y < 0)
     {
      Print(__FUNCTION__, " > Error: Negative coordinates! x=", x, " y=", y);
      return false;
     }

   if(x + width > chart_width)
     {
      Print(__FUNCTION__, " > Error: Object extends beyond chart width! ", x+width, " > ", chart_width);
      return false;
     }

   if(y + height > chart_height)
     {
      Print(__FUNCTION__, " > Error: Object extends beyond chart height! ", y+height, " > ", chart_height);
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Send und T & S Button                                                                 |
//+------------------------------------------------------------------+
void SendButton()
  {
   ObjectCreate(0, "SendOnlyButton", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "SendOnlyButton", OBJPROP_XDISTANCE, xd3-100);   // X position
   ObjectSetInteger(0, "SendOnlyButton", OBJPROP_XSIZE, 100);       // width
   ObjectSetInteger(0, "SendOnlyButton", OBJPROP_YDISTANCE, yd3);    // Y position
   ObjectSetInteger(0, "SendOnlyButton", OBJPROP_YSIZE, 30);        // height
   ObjectSetInteger(0, "SendOnlyButton", OBJPROP_CORNER, 0);        // chart corner
   if(!SendOnlyButton)
     {
      ObjectSetString(0, "SendOnlyButton", OBJPROP_TEXT, "T & S"); // label
      ObjectSetInteger(0, "SendOnlyButton", OBJPROP_BGCOLOR, TSButton_bgcolor);
      ObjectSetInteger(0, "SendOnlyButton", OBJPROP_COLOR, TSButton_font_color);
     }
   else
     {
      ObjectSetString(0, "SendOnlyButton", OBJPROP_TEXT, "Send only"); // label
      ObjectSetInteger(0, "SendOnlyButton", OBJPROP_BGCOLOR, SendOnlyButton_bgcolor);
      ObjectSetInteger(0, "SendOnlyButton", OBJPROP_COLOR, SendOnlyButton_font_color);
     }
   ObjectSetInteger(0, "SendOnlyButton", OBJPROP_FONTSIZE, SendOnlyButton_font_size);

//+------------------------------------------------------------------+
//|   TradenummerneingabeFeld
//+------------------------------------------------------------------+

   ObjectCreate(0, TRNB, OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0,TRNB,OBJPROP_XDISTANCE,xd3-100);
   ObjectSetInteger(0,TRNB,OBJPROP_YDISTANCE,yd3+30);
//--- Objektgröße setzen
   ObjectSetInteger(0,TRNB,OBJPROP_XSIZE,100);
   ObjectSetInteger(0,TRNB,OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,TRNB,OBJPROP_TEXT,IntegerToString(tradenummer));
//--- Schriftgröße setzen
   ObjectSetInteger(0,TRNB, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, TRNB, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, TRNB, OBJPROP_ALIGN,ALIGN_CENTER);
//--- aktivieren (true) oder deaktivieren (false) den schreibgeschützten Modus
   ObjectSetInteger(0,TRNB,OBJPROP_READONLY,false);
  }

//+------------------------------------------------------------------+
//| Eingabefelder für Sabio Preise                                                                |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SabioEdit()
  {
//SabioTPEdit
   ObjectCreate(0, SabioTP, OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0,SabioTP,OBJPROP_XDISTANCE,xd1);
   ObjectSetInteger(0,SabioTP,OBJPROP_YDISTANCE,yd1+30);
//--- Objektgröße setzen
   ObjectSetInteger(0,SabioTP,OBJPROP_XSIZE,280);
   ObjectSetInteger(0,SabioTP,OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,SabioTP,OBJPROP_TEXT,"SABIO TP: "+ Get_Price_s(TP_HL));
//--- Schriftgröße setzen
   ObjectSetInteger(0,SabioTP, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, SabioTP, OBJPROP_COLOR, clrBlack);

//--- aktivieren (true) oder deaktivieren (false) den schreibgeschützten Modus
   ObjectSetInteger(0,TRNB,OBJPROP_READONLY,false);

//SabioSLEdit
   ObjectCreate(0, SabioSL, OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0,SabioSL,OBJPROP_XDISTANCE,xd1);
   ObjectSetInteger(0,SabioSL,OBJPROP_YDISTANCE,yd5+30);
//--- Objektgröße setzen
   ObjectSetInteger(0,SabioSL,OBJPROP_XSIZE,280);
   ObjectSetInteger(0,SabioSL,OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,SabioSL,OBJPROP_TEXT,"SABIO SL: "+ Get_Price_s(SL_HL));
//--- Schriftgröße setzen
   ObjectSetInteger(0,SabioSL, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, SabioSL, OBJPROP_COLOR, clrBlack);

//--- aktivieren (true) oder deaktivieren (false) den schreibgeschützten Modus
   ObjectSetInteger(0,TRNB,OBJPROP_READONLY,false);

//SabioEntryEdit
   ObjectCreate(0, SabioEntry, OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0,SabioEntry,OBJPROP_XDISTANCE,xd1);
   ObjectSetInteger(0,SabioEntry,OBJPROP_YDISTANCE,yd3+30);
//--- Objektgröße setzen
   ObjectSetInteger(0,SabioEntry,OBJPROP_XSIZE,280);
   ObjectSetInteger(0,SabioEntry,OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,SabioEntry,OBJPROP_TEXT,"SABIO ENTRY: "+ Get_Price_s(PR_HL));
//--- Schriftgröße setzen
   ObjectSetInteger(0,SabioEntry, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, SabioEntry, OBJPROP_COLOR, clrBlack);

//--- aktivieren (true) oder deaktivieren (false) den schreibgeschützten Modus
   ObjectSetInteger(0,TRNB,OBJPROP_READONLY,false);
  }

//+------------------------------------------------------------------+
//| Feld für Notizen erstellen                                                                  |
//+------------------------------------------------------------------+
void NotizEdit()
  {
//SabioTPEdit
   ObjectCreate(0, "NotizEdit", OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0,"NotizEdit",OBJPROP_XDISTANCE,100);
   ObjectSetInteger(0,"NotizEdit",OBJPROP_YDISTANCE,getChartHeightInPixels() - 100);
//--- Objektgröße setzen
   ObjectSetInteger(0,"NotizEdit",OBJPROP_XSIZE,500);
   ObjectSetInteger(0,"NotizEdit",OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,"NotizEdit",OBJPROP_TEXT,"space for trade remarks ");
//--- Schriftgröße setzen
   ObjectSetInteger(0,"NotizEdit", OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, "NotizEdit", OBJPROP_COLOR, clrBlack);
  }



//+------------------------------------------------------------------+
//| MODIFIZIERTE DiscordSend() Funktion - FIX IMPLEMENTIERUNG       |
//+------------------------------------------------------------------+

void DiscordSend()
{
   // 1. ERSTE PRIORITÄT: Markt-Status prüfen
   g_market_status = CheckMarketStatus();
   
   // 2. Prüfe ob Trading möglich ist
   if(!g_market_status.is_open)
   {
      ShowTradeError(ERR_MARKET_CLOSED);
      return;  // STOPP - kein Trading wenn Markt geschlossen
   }
   
   if(!g_market_status.has_valid_prices)
   {
      ShowTradeError(ERR_NO_CURRENT_PRICES);
      return;  // STOPP - keine gültigen Preise
   }
   
   // 3. Verwende die validierten Marktpreise für Vergleiche
   double validated_ask = g_market_status.last_valid_ask;
   double validated_bid = g_market_status.last_valid_bid;
   
   string tradenummer_string;
   ObjectGetString(0,TRNB,OBJPROP_TEXT,0,tradenummer_string);
   int neue_tradenummer = (int) tradenummer_string;

   if(neue_tradenummer < 0)
   {
      ShowTradeError(ERR_INVALID_TRADE_NUMBER);
      return;
   }

   tradenummer = neue_tradenummer;

   if(tradenummer > last_trade_nummer)
   {
      if(isBuy)  // Long Trade zum senden
      {
         // WICHTIG: Verwende validierte Preise statt CurrentAskPrice
         if(Entry_Price <= validated_ask)
         {
            ShowTradeError(ERR_ENTRY_BELOW_CURRENT);
         }
         else if(!is_long_trade)
         {
            // ... Rest der Long Trade Logik bleibt gleich ...
            
            // Setze die aktuellen Preise für die weitere Verarbeitung
            CurrentAskPrice = validated_ask;
            CurrentBidPrice = validated_bid;
            
            // Erzeuge Array TradeInfo
            tradeInfo[0].tradenummer = tradenummer;
            tradeInfo[0].symbol = _Symbol;
            tradeInfo[0].type = "BUY";
            tradeInfo[0].price = Entry_Price;
            tradeInfo[0].sl = SL_Price;
            tradeInfo[0].tp = TP_Price;
            tradeInfo[0].sabioentry = ObjectGetString(0,SabioEntry,OBJPROP_TEXT,0);
            tradeInfo[0].sabiosl = ObjectGetString(0,SabioSL,OBJPROP_TEXT,0);
            tradeInfo[0].sabiotp = ObjectGetString(0,SabioTP,OBJPROP_TEXT,0);
            tradeInfo[0].was_send = false;
            tradeInfo[0].is_trade_pending = true;
            is_buy_trade_pending = true;

            is_long_trade = true;
            need_label_update_long = true;
            ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_COLOR, InfoLabelFontSize_font_color);
            ObjectSetInteger(0,"ActiveLongTrade", OBJPROP_BGCOLOR, InfoLabelFontSize_bgcolor);
            SafeUpdateText("ActiveLongTrade", "ACTIVE POSITION");
            
            CreateTPSLLines(TP_Long,TimeCurrent(),TP_Price,TradeTPLineLong);
            if(!working_ShowTPButton)
            {
               ObjectSetInteger(0, TP_Long, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
            }
            CreateTPSLLines(SL_Long,TimeCurrent(),SL_Price,TradeSLLineLong);
            CreateTPSLLines(Entry_Long,TimeCurrent(),tradeInfo[0].price,TradeEntryLineLong);
            CreateLabelsLong();
            
            last_trade_nummer = tradenummer;
            UpdateTradeNumberDisplay();

            send_TP_buy = false;
            send_SL_buy = false;
            send_CL_buy = false;
            
            string message = FormatTradeMessage(tradeInfo[0]);
            bool ret = SendDiscordMessage(message);
            if(!ret)
            {
               ShowTradeError(ERR_DISCORD_SEND_FAILED);
            }

            SendScreenShot(_Symbol,_Period,getChartWidthInPixels(),getChartHeightInPixels());
            tradeInfo[0].was_send = true;
            last_buy_trade = tradenummer;
            
            UpdateTradeNumberDisplay();
            
            if(!SendOnlyButton)
            {
               double lots = calcLots(Entry_Price - SL_Price);
               if(!working_ShowTPButton)
               {
                  trade.BuyStop(lots, Entry_Price, _Symbol, SL_Price, 0.0, ORDER_TIME_GTC);
               }
               else
               {
                  trade.BuyStop(lots, Entry_Price, _Symbol, SL_Price, TP_Price, ORDER_TIME_GTC);
               }
               return;
            }
         }
         else
         {
            ShowTradeError(ERR_TRADE_ALREADY_EXISTS);
         }
      }
      else // Short Trade
      {
         // WICHTIG: Verwende validierte Preise statt CurrentBidPrice
         if(Entry_Price > validated_bid)
         {
            ShowTradeError(ERR_ENTRY_ABOVE_CURRENT);
         }
         else if(!is_sell_trade)
         {
            // Setze die aktuellen Preise für die weitere Verarbeitung
            CurrentAskPrice = validated_ask;
            CurrentBidPrice = validated_bid;
            
            // ... Rest der Short Trade Logik analog zu Long ...
         }
         else
         {
            ShowTradeError(ERR_TRADE_ALREADY_EXISTS);
         }
      }
   }
   else
   {
      ShowTradeError(ERR_INVALID_TRADE_NUMBER);
   }
}

//+------------------------------------------------------------------+
//| KORRIGIERTE MARKT-STATUS PRÜFUNG                                |
//+------------------------------------------------------------------+
MarketStatus CheckMarketStatus()
{
   MarketStatus status;
   
   // 1. Hole BEIDE Zeiten - Server UND Lokal
   datetime current_server_time = TimeCurrent();
   datetime current_local_time = TimeLocal();
   
   MqlDateTime dt_server, dt_local;
   TimeToStruct(current_server_time, dt_server);
   TimeToStruct(current_local_time, dt_local);
   
   Print("=== MARKT STATUS CHECK ===");
   Print("Server Zeit: ", TimeToString(current_server_time), " (Tag: ", dt_server.day_of_week, ")");
   Print("Lokale Zeit: ", TimeToString(current_local_time), " (Tag: ", dt_local.day_of_week, ")");
   
   // 2. Prüfe BEIDE Zeiten auf Wochenende
   bool is_weekend_server = (dt_server.day_of_week == 0 || dt_server.day_of_week == 6);
   bool is_weekend_local = (dt_local.day_of_week == 0 || dt_local.day_of_week == 6);
   
   // 3. Spezielle Regel für Forex: 
   // - Schließt Freitag ca. 22:00 Uhr (Server-Zeit)
   // - Öffnet Sonntag ca. 22:00 Uhr (Server-Zeit)
   bool forex_closed = false;
   
   // Freitag nach 22:00 Uhr = geschlossen
   if(dt_server.day_of_week == 5 && dt_server.hour >= 22)
   {
      forex_closed = true;
      Print("Forex geschlossen: Freitag nach 22:00 Server-Zeit");
   }
   
   // Samstag = immer geschlossen
   if(dt_server.day_of_week == 6)
   {
      forex_closed = true;
      Print("Forex geschlossen: Samstag");
   }
   
   // Sonntag vor 22:00 = noch geschlossen
   if(dt_server.day_of_week == 0 && dt_server.hour < 22)
   {
      forex_closed = true;
      Print("Forex geschlossen: Sonntag vor 22:00 Server-Zeit");
   }
   
   // 4. Prüfe aktuelle Preise
   double current_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double current_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double last_tick_time = (double)SymbolInfoInteger(_Symbol, SYMBOL_TIME);
   
   // Prüfe ob der letzte Tick älter als 60 Sekunden ist
   bool prices_stale = (current_server_time - (datetime)last_tick_time > 60);
   
   // 5. Validiere Preise
   bool prices_valid = (current_ask > 0 && 
                       current_bid > 0 && 
                       current_ask > current_bid &&
                       !prices_stale &&
                       (current_ask - current_bid) < current_ask * 0.01); // Spread < 1%
   
   Print("Ask: ", current_ask, " Bid: ", current_bid, " Valid: ", prices_valid);
   Print("Letzter Tick: ", TimeToString((datetime)last_tick_time));
   
   // 6. OVERRIDE: Wenn Wochenende (lokal ODER server), dann geschlossen!
   if(forex_closed || is_weekend_local)
   {
      status.is_open = false;
      status.has_valid_prices = false;
      status.status_text = "Markt geschlossen: Wochenende";
      
      // Berechne nächste Öffnung (Sonntag 22:00 Server-Zeit)
      if(dt_server.day_of_week == 6) // Samstag
      {
         // Morgen (Sonntag) 22:00
         datetime tomorrow = current_server_time + 86400;
         MqlDateTime dt_tomorrow;
         TimeToStruct(tomorrow, dt_tomorrow);
         dt_tomorrow.hour = 22;
         dt_tomorrow.min = 0;
         dt_tomorrow.sec = 0;
         status.market_open_time = StructToTime(dt_tomorrow);
      }
      else if(dt_server.day_of_week == 0 && dt_server.hour < 22) // Sonntag vor 22:00
      {
         // Heute 22:00
         dt_server.hour = 22;
         dt_server.min = 0;
         dt_server.sec = 0;
         status.market_open_time = StructToTime(dt_server);
      }
      else if(dt_server.day_of_week == 5) // Freitag Abend
      {
         // Übernächster Tag (Sonntag) 22:00
         datetime sunday = current_server_time + (2 * 86400);
         MqlDateTime dt_sunday;
         TimeToStruct(sunday, dt_sunday);
         dt_sunday.hour = 22;
         dt_sunday.min = 0;
         dt_sunday.sec = 0;
         status.market_open_time = StructToTime(dt_sunday);
      }
      
      Print("MARKT GESCHLOSSEN - Wochenende erkannt!");
      return status;
   }
   
   // 7. Zusätzliche Prüfung über Trading erlaubt
   bool trading_allowed = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_FULL;
   bool market_open = (bool)SymbolInfoInteger(_Symbol, SYMBOL_SESSION_DEALS);
   
   Print("Trading erlaubt: ", trading_allowed, " Market Open Flag: ", market_open);
   
   // 8. Finale Entscheidung
   status.is_open = !forex_closed && trading_allowed && market_open;
   status.has_valid_prices = prices_valid;
   
   if(status.is_open && status.has_valid_prices)
   {
      status.status_text = "Markt GEÖFFNET";
      status.last_valid_ask = current_ask;
      status.last_valid_bid = current_bid;
   }
   else if(!status.is_open)
   {
      status.status_text = "Markt GESCHLOSSEN";
      // Speichere trotzdem die letzten Preise
      status.last_valid_ask = current_ask > 0 ? current_ask : 0;
      status.last_valid_bid = current_bid > 0 ? current_bid : 0;
   }
   else
   {
      status.status_text = "Warte auf gültige Preise";
   }
   
   Print("FINAL: ", status.status_text);
   Print("=======================");
   
   return status;
}

//+------------------------------------------------------------------+
//| Debug-Funktion zum Testen                                       |
//+------------------------------------------------------------------+
void DebugMarketStatus()
{
   Print("\n========== MARKET STATUS DEBUG ==========");
   
   // Server Info
   datetime server_time = TimeCurrent();
   MqlDateTime dt_server;
   TimeToStruct(server_time, dt_server);
   Print("Server Zeit: ", TimeToString(server_time));
   Print("Server Wochentag: ", dt_server.day_of_week, 
         " (0=So, 1=Mo, 2=Di, 3=Mi, 4=Do, 5=Fr, 6=Sa)");
   
   // Lokale Info
   datetime local_time = TimeLocal();
   MqlDateTime dt_local;
   TimeToStruct(local_time, dt_local);
   Print("Lokale Zeit: ", TimeToString(local_time));
   Print("Lokaler Wochentag: ", dt_local.day_of_week);
   
   // Symbol Info
   Print("\nSymbol Informationen:");
   Print("Trade Mode: ", SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE));
   Print("Session Deals: ", SymbolInfoInteger(_Symbol, SYMBOL_SESSION_DEALS));
   Print("Last Tick: ", TimeToString((datetime)SymbolInfoInteger(_Symbol, SYMBOL_TIME)));
   
   // Preise
   Print("\nPreise:");
   Print("Ask: ", SymbolInfoDouble(_Symbol, SYMBOL_ASK));
   Print("Bid: ", SymbolInfoDouble(_Symbol, SYMBOL_BID));
   Print("Spread: ", SymbolInfoInteger(_Symbol, SYMBOL_SPREAD));
   
   // Status Check
   MarketStatus status = CheckMarketStatus();
   Print("\nErgebnis:");
   Print("Markt offen: ", status.is_open);
   Print("Preise gültig: ", status.has_valid_prices);
   Print("Status: ", status.status_text);
   
   Print("========================================\n");
}
