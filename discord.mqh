//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include "db_state.mqh"
#include <Trade/Trade.mqh>
#include "config.mqh"
//CConfig g_Config;
// Strategy Parameters




//CJAVal g_config;



// Neue Variablen
//string Webhook_System=g_Config.GetWebhook("system");


// Wenn der Broker seltsame Namen für die Symbole hat, dann muss dieser in den Eigenschaften angegeben werden




//bool isWebRequestEnabled = false;
//datetime lastMessageTime = 0;

// Discord webhook URL - Replace with your webhook URL
//string discord_webhook = Webhook_System;
//string discord_webhook_test = "https://discord.com/api/webhooks/1328803943068860416/O7dsN4wcNk-vSA9sQQx1ZFzZUAhx8NsPe4JFPxQ4MuQtiOx1BWepkXqSz00ZkCrqiDHw";

/*
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkDiscord()
  {

   CLogger::Add(LOG_LEVEL_INFO, "Initialization step 1: Checking WebRequest permissions...");

   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
     {
      CLogger::Add(LOG_LEVEL_WARNING, "Error: WebRequest is not allowed. Please allow in Tool -> Options -> Expert Advisors");
      return false;
     }

   CLogger::Add(LOG_LEVEL_INFO, "TerminalInfoInteger ok!");

   CLogger::Add(LOG_LEVEL_INFO, "Initialization step 2: Testing Discord connection...");

// Simple test message
   ResetLastError();

   string test_message = "{\"content\":\"DowHow Signal Dienst AS3 System Test erfolgreich\"}";
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
      CLogger::Add(LOG_LEVEL_WARNING, "WebRequest failed. Error code: "+ error+"\n Make sure these URLs are allowed:\n");
      CLogger::Add(LOG_LEVEL_WARNING, "https://discord.com/*");
      CLogger::Add(LOG_LEVEL_WARNING, "https://discordapp.com/*");

      return false;
     }

      CLogger::Add(LOG_LEVEL_INFO, "Initialization step 3: Set Webhook");
   if(get_discord_webhook()==discord_webhook_test)
     {
      
      CLogger::Add(LOG_LEVEL_WARNING, "Please set Webhooks: ");
      return false;
     }
   else
     {
     
        CLogger::Add(LOG_LEVEL_INFO, "Use Webhook: "+get_discord_webhook());
     }

   isWebRequestEnabled = true;
   
        CLogger::Add(LOG_LEVEL_INFO, "Initialization step 4: All checks passed!");
        CLogger::Add(LOG_LEVEL_INFO, "Successfully connected to Discord!");
  
   return true;
  }
*/
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
string FormatTradeMessage(const DB_PositionRow &row)
  {
   string message = "@everyone\n";
   message += ":red_circle:TRADINGSIGNAL: :red_circle:\n\n";
   message += StringFormat("----------[Trade Nr. %d | Pos %d]----------\n\n", row.trade_no, row.pos_no);

   string dir = row.direction; // "LONG"/"SHORT"
   if(dir == "LONG")
      message += ":chart_with_upwards_trend: **LONG:** ";
   else
      message += ":chart_with_downwards_trend: **SHORT:** ";

   message += "**Symbol:** " + row.symbol + " " + row.tf + "\n";
   message += ":arrow_right: **Entry:** " + DoubleToString(row.entry, _Digits) + " (" + row.sabio_entry + ")\n\n";
   message += ":orange_circle: **SL:** " + DoubleToString(row.sl, _Digits) + " (" + row.sabio_sl + ")\n";


   return message;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SendDiscordMessageTest(string message, bool isError = false)
  {

   string discord_webhook_save = discord_webhook;
   discord_webhook =discord_webhook_test;

   return SendDiscordMessage(message,  false);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getPeriodText()
  {

   ENUM_TIMEFRAMES tf = Period();
   int sec = PeriodSeconds(tf);
   if(sec <= 0)
      return EnumToString(tf);

   int min = sec / 60;
   if(min < 60)
      return "M" + IntegerToString(min);
   if(min < 24*60)
      return "H" + IntegerToString(min/60);
   return "D" + IntegerToString(min/(24*60));


  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SendDiscordMessage(string message, bool isError = false)
  {
   if(!isWebRequestEnabled)
     {
      
        CLogger::SetLogFileName("Not isWebRequestEnabled");
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

  CLogger::SetLogFileName("Discord Error: "+ error+ " ("+ res+ ")");
      
  CLogger::SetLogFileName("Message: "+ message);
      
  CLogger::SetLogFileName("Last MT5 Error: "+GetLastError());
      
   return false;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string FormatSLMessage(const DB_PositionRow &row)
  {
   string message = "@everyone\n";
   message += StringFormat("**Note:** %s %s Trade %d Pos %d - SL erreicht\n",
                           row.symbol, row.tf, row.trade_no, row.pos_no);
   return message;
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string FormatCancelTradeMessage(const DB_PositionRow &row)
  {
   string message = "@everyone\n";
   message += StringFormat("**Attention:** %s %s Trade %d all Pos - Order canceln\n",
                           row.symbol, row.tf, row.trade_no);
   return message;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string FormatUpdateTradeMessage(const DB_PositionRow &row)
  {
   string message = "@everyone\n";
   message += StringFormat("**Attention:** %s %s Trade %d Pos %d - SL -> %s (Sabio: %s) | TP -> %s (Sabio: %s)\n",
                           row.symbol, row.tf, row.trade_no, row.pos_no,
                           DoubleToString(row.sl, _Digits), row.sabio_sl);

   return message;
  }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string get_discord_webhook()
  {


   string webhookUrl = g_Config.GetWebhook(_Symbol);
   return webhookUrl;

  }










//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string TF_Text()
  {
// liefert z.B. "PERIOD_H1"
   return EnumToString((ENUM_TIMEFRAMES)_Period);
  }

// optional hübscher: "H1" statt "PERIOD_H1"
string TF_Short()
  {
   switch((ENUM_TIMEFRAMES)_Period)
     {
      case PERIOD_M1:
         return "M1";
      case PERIOD_M5:
         return "M5";
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
         return TF_Text();
     }
  }


string FormatTradeMessageRow(const DB_PositionRow &row, const string order_type /*BUY/SELL*/)
  {
   string msg="@everyone\n:red_circle:TRADINGSIGNAL: :red_circle:\n\n";
   msg += "----------[Trade Nr. " + IntegerToString(row.trade_no) + " | Pos " + IntegerToString(row.pos_no) + "]----------\n\n";
   msg += (order_type=="BUY" ? ":chart_with_upwards_trend: **BUY:** " : ":chart_with_downwards_trend: **SELL:** ");
   msg += "**Symbol:** " + row.symbol + " " + getPeriodText() + "\n";
   msg += ":arrow_right: **Entry:** " + DoubleToString(row.entry, _Digits) + " (" + row.sabio_entry + ")\n\n";
   msg += ":orange_circle: **SL:** " + DoubleToString(row.sl, _Digits) + " (" + row.sabio_sl + ")\n";

   return msg;
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
        
  CLogger::SetLogFileName("ChartScreenShot Error: "+(string)GetLastError());
         
         Sleep(50);
         continue;
        }
      res=FileOpen(filename,FILE_READ|FILE_WRITE|FILE_BIN);
      if(res<0)
        {
  CLogger::SetLogFileName("File Open Error: "+filename+", Attempt: "+x);

         Sleep(100);
         continue;
        }
      if(FileSize(res)==0)
        {
         FileClose(res);
  CLogger::SetLogFileName("FileSize Error, Attempt: "+x);


         Sleep(100);
         continue;
        }
      break;
     }
   if(FileReadArray(res,file)!=FileSize(res))
     {
      FileClose(res);
      
  CLogger::SetLogFileName("File Read Error: "+filename);
    
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
   CLogger::SetLogFileName("Server response: "+CharArrayToString(data));
 
      if(res<0)
        {
   CLogger::SetLogFileName("Error: "+GetLastError());
 
        
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


//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string FormatLineMoveMessage(const DB_PositionRow &row,
                             const string kind,
                             const double old_price,
                             const double new_price)
  {
   string what = kind;
   if(kind == "entry")
      what = "Entry";
   else
      if(kind == "sl")
         what = "SL";

   string icon = (row.direction == "LONG") ? ":chart_with_upwards_trend:" : ":chart_with_downwards_trend:";

   string message = "@everyone\n";
   message += icon + " **UPDATE:** " + row.symbol + " " + row.tf + "\n";
   message += StringFormat("Trade %d | Pos %d | **%s**\n", row.trade_no, row.pos_no, row.direction);

   if(old_price > 0.0)
      message += StringFormat("**%s:** %s -> %s\n",
                              what,
                              DoubleToString(old_price, _Digits),
                              DoubleToString(new_price, _Digits));
   else
      message += StringFormat("**%s:** %s\n", what, DoubleToString(new_price, _Digits));

   message += "(Linie & Tag aktualisiert)\n";
   return message;
  }

//+------------------------------------------------------------------+
