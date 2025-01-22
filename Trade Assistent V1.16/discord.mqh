#property copyright "Copyright 2025, saaralf, Michael Keller"
#property link      "kellermichael.de"
#property version   "1.00"

#include <Trade/Trade.mqh>

// Strategy Parameters
input group "Discord Settings"
input string DiscordBotName = "DowHow Trading Signalservice";    // Name of the bot in Discord
input color MessageColor = clrBlue;                 // Color for Discord messages


bool isWebRequestEnabled = false;
datetime lastMessageTime = 0;


// Discord webhook URL - Replace with your webhook URL
string discord_webhook = "https://discord.com/api/webhooks/1313603118768062575/TPHxceiomoSnyZmp4RZnKtwzM2U4ptc-lTCcnUxj4qqpo1UdXedoyRQaB_Gv-gE9JDSP";
 string discord_webhook_test = "https://discord.com/api/webhooks/1328803943068860416/O7dsN4wcNk-vSA9sQQx1ZFzZUAhx8NsPe4JFPxQ4MuQtiOx1BWepkXqSz00ZkCrqiDHw";

// Structure to hold trade information
struct TradeInfo
  {
   int            tradenummer;
   string            symbol;
   string            type;
   double            price;
   double            lots;
   double            sl;
   double            tp;
  };


bool checkDiscord(){
 Print("Initialization step 1: Checking WebRequest permissions...");



   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
     {
      Print("Error: WebRequest is not allowed. Please allow in Tool -> Options -> Expert Advisors");
      return false;
     }

   Print("Initialization step 2: Testing Discord connection...");

// Simple test message
   ResetLastError();
 
   string test_message = "{\"content\":\"Test message from MT5\"}";
   string headers = "Content-Type: application/json\r\n";
   char data[], result[];
   ArrayResize(data, StringToCharArray(test_message, data, 0, WHOLE_ARRAY, CP_UTF8) - 1);

   int res = WebRequest(
                "POST",
                discord_webhook_test,
                headers,
                5000,
                data,
                result,
                headers
             );

   if(res == -1)
     {
      int error = GetLastError();
      Print("WebRequest failed. Error code: ", error);
      Print("Make sure these URLs are allowed:");
      Print("https://discord.com/*");
      Print("https://discordapp.com/*");
      return false;
     }

   isWebRequestEnabled = true;
   Print("Initialization step 3: All checks passed!");
   Print("Successfully connected to Discord!");

return true;
}

//+------------------------------------------------------------------+
//| Function to escape JSON string                                     |
//+------------------------------------------------------------------+
string EscapeJSON(string text)
  {
   string escaped = text;
   StringReplace(escaped, "\\", "\\\\");
   StringReplace(escaped, "\"", "\\\"");
   StringReplace(escaped, "\n", "\\n");
   StringReplace(escaped, "\r", "\\r");
   StringReplace(escaped, "\t", "\\t");
   return escaped;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string FormatTradeMessage(TradeInfo& tradeInfo)
  {
   string 
   message = "---------------------------------------------------------------------------------------------------------------------------------------------------\n";
   message += "@everyone\n";
   message += ":red_circle:TRADINGSIGNAL: :red_circle:\n";
   message += "\n";
   message +="----------[Trade Nr. "+tradeInfo.tradenummer+"]----------\n";
  message += "\n";
   if(tradeInfo.type=="BUY")
     {
      message += ":chart_with_upwards_trend: **" + tradeInfo.type + ":** ";
     }
   else
     {
      message += ":chart_with_downwards_trend: **" + tradeInfo.type + ":** ";
     }
      message += "**Symbol:** "+tradeInfo.symbol + " "+ Period() + "\n";
   message += ":arrow_right: **Entry:** " + DoubleToString(tradeInfo.price, _Digits) + "\n";
   message += "\n";
   message += ":orange_circle: **SL:** " + DoubleToString(tradeInfo.sl, _Digits) + "\n";
   message += ":dollar: **TP:** " + DoubleToString(tradeInfo.tp, _Digits) + "\n";
   message += "---------------------------------------------------------------------------------------------------------------------------------------------------\n";
//   message += "Uhrzeit der Meldung: " + TimeToString(TimeCurrent());
   return message;

//string message ="@everyone \\n\\n----------[Trade Nr. 88]----------\\n:chart_with_downwards_trend: **Sell: DAX40 M5**:arrow_right: **Entry:** 123456 (Sabio: 12345):orange_circle: **SL:** 123456 (Sabio: 12345):dollar: **TP:** 123456 (Sabio: 12345)";
  }

bool SendDiscordMessageTest(string message, bool isError = false){

string discord_webhook_save = discord_webhook;
string discord_webhook =discord_webhook_test;

return SendDiscordMessage( message,  false);

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SendDiscordMessage(string message, bool isError = false)
  {
   if(!isWebRequestEnabled)
   {
      Print("Not isWebRequestEnabled");
      return false;
      }

   Sleep(100);

// Add emoji prefix for visual status
 //  message = (isError ? "? " : "? ") + message;

// Prepare webhook data
   string payload = "{ \"avatar_url\": \"https://www.dowhow-trading.com/wp-content/uploads/2021/04/dowhow-logo-1024x1024.png\",\"content\":\"" + EscapeJSON(message) + "\"}";
   string headers = "Content-Type: application/json\r\n";

   char post[], result[];
   ArrayResize(post, StringToCharArray(payload, post, 0, WHOLE_ARRAY, CP_UTF8) - 1);

   ResetLastError();
   int res = WebRequest(
                "POST",
                discord_webhook,
                headers,
                5000,
                post,
                result,
                headers
             );

// Both 200 and 204 are success codes for Discord webhooks
   if(res == 200 || res == 204)
     {
      lastMessageTime = TimeCurrent();
      return true;
     }

// If we get here, there was an error
   string error = "";
   switch(res)
     {
      case 400:
         error = "Bad Request";
         break;
      case 401:
         error = "Unauthorized";
         break;
      case 403:
         error = "Forbidden";
         break;
      case 404:
         error = "Not Found";
         break;
      case 429:
         error = "Rate Limited";
         break;
      default:
         error = "Unknown Error";
     }

   Print("Discord Error: ", error, " (", res, ")");
   Print("Message: ", message);
   Print("Last MT5 Error: ", GetLastError());

   return false;
  }
//+------------------------------------------------------------------+
