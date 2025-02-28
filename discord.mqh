//+------------------------------------------------------------------+

/* History
   16.01.2025 (Steffen) Zeilen Input LinkChannelM2 und ...M5 hinzugefÃ¼gt - wird nicht angezeigt
   16.01.2025 (saaralf) Methoden FormatSLMessage, FormatTPMessage ,FormatUpdateTradeMessage und FormatCancelTradeMessage erstellt

//-------------------------------------------------------------------*/

#property copyright "Copyright 2025, saaralf, Michael Keller"
#property link      "kellermichael.de"
#property version   "1.01"

#include <Trade/Trade.mqh>

// Strategy Parameters
input group "===== Discord Settings ====="
input string DiscordBotName = "DowHow Trading Signalservice";    // Name of the bot in Discord
input color MessageColor = clrBlue;                 // Color for Discord messages

// webhooks Markus 
input string LinkChSannelM2 = " ";  // Discord Channel 

bool isWebRequestEnabled = false;
datetime lastMessageTime = 0;

// Discord webhook URL - Replace with your webhook URL
string discord_webhook = LinkChannelM2;
string discord_webhook_test = "https://discord.com/api/webhooks/1328803943068860416/O7dsN4wcNk-vSA9sQQx1ZFzZUAhx8NsPe4JFPxQ4MuQtiOx1BWepkXqSz00ZkCrqiDHw";

// Structure to hold trade information
struct TradeInfo
  {
   int               tradenummer;
   string            symbol;
   string            type;
   double            price;
   double            lots;
   double            sl;
   double            tp;
   string            sabioentry;
   string            sabiosl;
   string            sabiotp;
   bool              was_send;
   bool              is_trade_pending;
  };
TradeInfo tradeInfo[2];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkDiscord()
  {
   Print("Initialization step 1: Checking WebRequest permissions...");



   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
     {
      Print("Error: WebRequest is not allowed. Please allow in Tool -> Options -> Expert Advisors");
      return false;
     }

   Print("Initialization step 2: Testing Discord connection...");

// Simple test message
   ResetLastError();

   string test_message = "{\"content\":\"Discord Test Steffen\"}";
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

   Print("Initialization step 3: Test Period");
   if(get_discord_webhook()==discord_webhook_test)
     {
      Print("Check Period");
      return false;
     }

   isWebRequestEnabled = true;
   Print("Initialization step 4: All checks passed!");
   Print("Successfully connected to Discord!");


// Erzeuge Array TradeInfo
   tradeInfo[0].tradenummer=0;
   tradeInfo[0].symbol = _Symbol;
   tradeInfo[0].type = "BUY";
   tradeInfo[0].price = 0.0;
   tradeInfo[0].lots = 0.01;
   tradeInfo[0].sl = 0.0;
   tradeInfo[0].tp = 0.0;
   tradeInfo[0].sabioentry = 0.0;
   tradeInfo[0].sabiosl = 0.0;
   tradeInfo[0].sabiotp = 0.0;
   tradeInfo[0].was_send=false;

   tradeInfo[1].tradenummer=0;
   tradeInfo[1].symbol = _Symbol;
   tradeInfo[1].type = "SELL";
   tradeInfo[1].price = 0.0;
   tradeInfo[1].lots = 0.01;
   tradeInfo[1].sl = 0.0;
   tradeInfo[1].tp = 0.0;
   tradeInfo[1].sabioentry = 0.0;
   tradeInfo[1].sabiosl = 0.0;
   tradeInfo[1].sabiotp = 0.0;
   tradeInfo[1].was_send=false;




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
  
   message = "@everyone\n";
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
   message += "**Symbol:** "+tradeInfo.symbol + " "+ getPeriodText() + "\n";
   message += ":arrow_right: **Entry:** " + DoubleToString(tradeInfo.price, _Digits) + " ("+ tradeInfo.sabioentry+")\n";
   message += "\n";
   message += ":orange_circle: **SL:** " + DoubleToString(tradeInfo.sl, _Digits) + " ("+ tradeInfo.sabiosl+")\n";
   message += ":dollar: **TP:** " + DoubleToString(tradeInfo.tp, _Digits) + " ("+tradeInfo.sabiotp+")\n";
  
//   message += "Uhrzeit der Meldung: " + TimeToString(TimeCurrent());
   return message;

//string message ="@everyone \\n\\n----------[Trade Nr. 88]----------\\n:chart_with_downwards_trend: **Sell: DAX40 M5**:arrow_right: **Entry:** 123456 (Sabio: 12345):orange_circle: **SL:** 123456 (Sabio: 12345):dollar: **TP:** 123456 (Sabio: 12345)";
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SendDiscordMessageTest(string message, bool isError = false)
  {

   string discord_webhook_save = discord_webhook;
   string discord_webhook =discord_webhook_test;

   return SendDiscordMessage(message,  false);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getPeriodText()
  {


   if(EnumToString(Period()) == "PERIOD_M2")
      return "M2";

   if(EnumToString(Period()) == "PERIOD_M5")
      return "M5";

   return "H1";

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
   string payload = "{\"content\":\"" + EscapeJSON(message) + "\"}";
   string headers = "Content-Type: application/json\r\n";

   char post[], result[];
   ArrayResize(post, StringToCharArray(payload, post, 0, WHOLE_ARRAY, CP_UTF8) - 1);

   ResetLastError();
   int res = WebRequest(
                "POST",
                get_discord_webhook(),
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
//|                                                                  |
//+------------------------------------------------------------------+
string FormatSLMessage(TradeInfo& tradeInfo)
  {
   string  message = "@everyone\n";
   message += "**Note:** "+tradeInfo.symbol+" Trade "+tradeInfo.tradenummer+" - has been stopped out\n";

   return message;
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string FormatTPMessage(TradeInfo& tradeInfo)
  {
   string  message = "@everyone\n";
   message += "**Note:** "+tradeInfo.symbol+" Trade "+tradeInfo.tradenummer+" - target reached :dollar: \n";

   return message;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string FormatCancelTradeMessage(TradeInfo& tradeInfo)
  {
   string  message = "@everyone\n";
   message += "**Attention:** "+tradeInfo.symbol+" Trade "+tradeInfo.tradenummer+" - cancel the order cause trend is broken\n";

   return message;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string FormatUpdateTradeMessage(TradeInfo& tradeInfo)
  {
   string  message = "@everyone\n";
   message += "**Attention:** "+tradeInfo.symbol+" Trade "+tradeInfo.tradenummer+" - I trail my SL price down to "+tradeInfo.sl+" (Sabio: "+tradeInfo.sl+") - Target new: "+tradeInfo.tp+" (Sabio:  "+tradeInfo.tp +")\n";

   return message;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string get_discord_webhook()
  {
   if(Period()==PERIOD_M2)
     {
      return LinkChannelM2;
     }
   if(Period()==PERIOD_M5)
     {
      return LinkChannelM2;
     }

   Alert("Falsche Zeiteinheit "+ EnumToString(Period())+" eingestellt:. Derzeit nur M2 und M5 definiert!");
   return discord_webhook_test;
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SendScreenShot(string symbol,int _period, int ScreenWidth = 1912, int ScreenHeight = 1080)
  {

   int res=-1;
   char data[],file[];
   string filename;
   ResetLastError();
   for(int x=1; x<=20; x++)
     {
      long currChart=ChartFirst();
      int i=0;
      while(i<CHARTS_MAX)
        {
         if(ChartSymbol(currChart)==symbol)
           {
            ChartRedraw(currChart);
            break;
           }
         currChart=ChartNext(currChart);
         if(currChart==-1)
            break;
         i++;
        }
      filename=StringFormat("%s_%s.png",ChartSymbol(currChart),ChartPeriod(currChart));
      //---
      if(ChartScreenShot(0,filename,ScreenWidth,ScreenHeight))
        {
         Sleep(200);
        }
      else
        {
         Print("ChartScreenShot Error: ",(string)GetLastError());
         Sleep(50);
         continue;
        }
      res=FileOpen(filename,FILE_READ|FILE_WRITE|FILE_BIN);
      if(res<0)
        {
         Print("File Open Error: "+filename+", Attempt: ",x);
         Sleep(100);
         continue;
        }
      if(FileSize(res)==0)
        {
         FileClose(res);
         Print("FileSize Error, Attempt: ",x);
         Sleep(100);
         continue;
        }
      break;
     }
   if(FileReadArray(res,file)!=FileSize(res))
     {
      FileClose(res);
      Print("File Read Error: "+filename);
      return;
     }
   FileClose(res);

   if(ArraySize(file)>0)
     {
      string str,sep="-------Fech2lie9mp8R34k";
      str="--"+sep+"\r\n";
      str+="Content-Disposition: form-data; name=\"attachments\"; filename=\""+filename+"\"\r\n";
      str+="Content-Type: image/png\r\n\r\n";
      res =StringToCharArray(str,data);
      res+=ArrayCopy(data,file,res-1,0);
      res+=StringToCharArray("\r\n--"+sep+"--\r\n",data,res-1);
      ArrayResize(data,ArraySize(data)-1);
      str="Content-Type: multipart/form-data; boundary="+sep+"\r\n";
      ResetLastError();
      res=WebRequest("POST", get_discord_webhook(),str,5000,data,data,str);
      if(res==NULL)
         Print("Server response: ",CharArrayToString(data));
      if(res<0)
        {
         Print("Error: ",GetLastError());
        }
      else
        {
        }
      FileDelete(filename);
     }

   Sleep(5);
   return;
  }
//+------------------------------------------------------------------+
