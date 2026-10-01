//+------------------------------------------------------------------+

/* History
   16.01.2025 (Steffen) Zeilen Input LinkChannelM2 und ...M5 hinzugefÃ¼gt - wird nicht angezeigt
   16.01.2025 (saaralf) Methoden FormatSLMessage, FormatTPMessage ,FormatUpdateTradeMessage und FormatCancelTradeMessage erstellt

//-------------------------------------------------------------------*/

#property copyright "Copyright 2025, saaralf, Michael Keller"
#property link      "kellermichael.de"
// Version is defined by the EA entry point.

#include <Trade/Trade.mqh>
#include "methoden_4.22.mqh"
#include "../WebhookConfig.mqh"

// Strategy Parameters
input group "===== Discord Settings ====="
input string DiscordBotName = "DowHow Trading Signalservice";    // Name of the bot in Discord
input color MessageColor = clrBlue;                 // Color for Discord messages

// webhooks Markus
input string InpWebhookConfigFile = "DowHowSignalService_webhooks.cfg"; // V2.x config, TEST route only

bool isWebRequestEnabled = false;
datetime lastMessageTime = 0;

// Discord webhook URL - Replace with your webhook URL
string discord_webhook = "";
string discord_webhook_test = "";

bool RecordDiscordAttempt(string kind,int http);

// Structure to hold trade information
#include "TradeInfo.mqh"
TradeInfo tradeInfo[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkDiscord()
  {
   isWebRequestEnabled=false;
   CWebhookConfig cfg;
   if(!cfg.Load(InpWebhookConfigFile)) { Print("TEST Discord blocked: V2 webhook config missing or invalid"); return false; }
   discord_webhook_test=cfg.TestWebhook(); StringTrimLeft(discord_webhook_test); StringTrimRight(discord_webhook_test);
   string prefix="https://discord.com/api/webhooks/";
   if(StringFind(discord_webhook_test,"https://discordapp.com/api/webhooks/")==0) prefix="https://discordapp.com/api/webhooks/";
   if(StringFind(discord_webhook_test,prefix)!=0 || StringFind(discord_webhook_test,"REPLACE")>=0 || StringFind(discord_webhook_test,"<")>=0 || StringLen(discord_webhook_test)<=StringLen(prefix)+5) { Print("TEST Discord blocked: invalid TEST URL"); discord_webhook_test=""; return false; }
   discord_webhook=discord_webhook_test;
   isWebRequestEnabled=true;
   Print("Discord configured: TEST route only. No startup POST.");
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
   g_transport_trade=tradeInfo.tradenummer; g_transport_pos=tradeInfo.position;

   string

   message = "[DEV TEST]\n";
   message += ":red_circle:TRADINGSIGNAL: :red_circle:\n";
   message += "\n";

   message += StringFormat("----------[Trade Nr. %d | Pos. %d]----------\n", tradeInfo.tradenummer, tradeInfo.position);

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
   return message;

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SendDiscordMessageTest(string message,bool isError=false) { return SendDiscordMessage(message,isError); }

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

   if(get_discord_webhook()=="") return false;

// Prepare webhook data
   string payload = "{\"allowed_mentions\":{\"parse\":[]},\"content\":\"" + EscapeJSON(message) + "\"}";
   string headers = "Content-Type: application/json\r\n";

   char post[], result[];
   ArrayResize(post, StringToCharArray(payload, post, 0, WHOLE_ARRAY, CP_UTF8) - 1);

   ResetLastError();
   if(!RecordDiscordAttempt("TEXT_ATTEMPT",0)) return false;
   int res = WebRequest(
                "POST",
                get_discord_webhook(),
                headers,
                5000,
                post,
                result,
                headers
             );

   RecordDiscordAttempt("TEXT_RESULT",res);

// Both 200 and 204 are success codes for Discord webhooks
   if(res >= 200 && res < 300)
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
string FormatSLMessage(TradeInfo &p) { g_transport_trade=p.tradenummer; g_transport_pos=p.position; return "[DEV TEST] "+p.symbol+" "+getPeriodText()+" "+p.type+" Trade "+IntegerToString(p.tradenummer)+" | Pos "+IntegerToString(p.position)+": SL reached"; }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string FormatTPMessage(TradeInfo &p) { g_transport_trade=p.tradenummer; g_transport_pos=p.position; return "[DEV TEST] "+p.symbol+" "+getPeriodText()+" "+p.type+" Trade "+IntegerToString(p.tradenummer)+" | Pos "+IntegerToString(p.position)+": TP reached"; }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string FormatCancelTradeMessage(TradeInfo &p) { g_transport_trade=p.tradenummer; g_transport_pos=p.position; return "[DEV TEST] "+p.symbol+" "+getPeriodText()+" "+p.type+" Trade "+IntegerToString(p.tradenummer)+" | Pos "+IntegerToString(p.position)+": Cancel"; }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string FormatUpdateTradeMessage(TradeInfo &p) { g_transport_trade=p.tradenummer; g_transport_pos=p.position; return "[DEV TEST] "+p.symbol+" "+getPeriodText()+" "+p.type+" Trade "+IntegerToString(p.tradenummer)+" | Pos "+IntegerToString(p.position)+": SL="+DoubleToString(p.sl,_Digits)+"; SabioSL="+p.sabiosl; }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string get_discord_webhook()
  {
   if(!isWebRequestEnabled) return "";
   if(_Period!=PERIOD_M2 && _Period!=PERIOD_M5 && _Period!=PERIOD_H1) return "";
   return discord_webhook_test;
  }


//+------------------------------------------------------------------+
//| Screenshot an Discord senden (robust für 4k/DPI & richtiger Chart)|
//+------------------------------------------------------------------+
void SendScreenShot(string symbol, int _period, int ScreenWidth = 0, int ScreenHeight = 0)
  {
   if(get_discord_webhook()=="") return;
// 1) passenden Chart finden
   long currChart = ChartFirst();
   while(currChart != -1)
     {
      if(ChartSymbol(currChart) == symbol && ChartPeriod(currChart) == _period)
         break;
      currChart = ChartNext(currChart);
     }

// Fallback: wenn nicht gefunden, nimm aktuellen Chart
   if(currChart == -1)
      currChart = ChartID();

// 2) echte Chart-Pixelmaße vom *currChart* holen
   int w = (int)ChartGetInteger(currChart, CHART_WIDTH_IN_PIXELS, 0);
   int h = (int)ChartGetInteger(currChart, CHART_HEIGHT_IN_PIXELS, 0);

// Fallback, falls MT5 0 liefert (kommt bei manchen DPI-Situationen vor)
   if(w <= 0)
      w = getChartWidthInPixels(currChart);
   if(h <= 0)
      h = getChartHeightInPixels(currChart);

// Wenn Parameter übergeben wurden, nimm sie (aber nicht kleiner als Chartmaß)
   if(ScreenWidth  > 0)
      w = MathMax(w, ScreenWidth);
   if(ScreenHeight > 0)
      h = MathMax(h, ScreenHeight);

// 3) Sicherheitsrand rechts/unten, damit UI am Rand nicht abgeschnitten wird
// (bei 4k/DPI ist das oft nötig)
   const int PAD_X = 80;
   const int PAD_Y = 40;

   w += PAD_X;
   h += PAD_Y;

// 4) Screenshot erstellen
   string filename = "DH126_"+IntegerToString(ChartID())+"_"+IntegerToString((long)GetMicrosecondCount())+".png";

   ChartRedraw(currChart);
   Sleep(150);

   if(!ChartScreenShot(currChart, filename, w, h))
     {
      Print("ChartScreenShot failed. chart=", currChart,
            " w=", w, " h=", h, " err=", GetLastError());
      return;
     }

// 5) Datei einlesen und als multipart an Discord senden
   int res = FileOpen(filename, FILE_READ|FILE_BIN);
   if(res < 0)
     {
      Print("FileOpen failed: ", filename, " err=", GetLastError());
      return;
     }

   int fsize = (int)FileSize(res);
   if(fsize <= 0)
     {
      FileClose(res);
      Print("FileSize invalid: ", filename);
      return;
     }

   uchar file[];
   ArrayResize(file, fsize);
   int read = FileReadArray(res, file, 0, fsize);
   FileClose(res);

   if(read != fsize)
     {
      Print("FileReadArray mismatch: read=", read, " size=", fsize);
      return;
     }

   string boundary = "-------Fech2lie9mp8R34k";
   string head =
      "--" + boundary + "\r\n"
      "Content-Disposition: form-data; name=\"attachments\"; filename=\"" + filename + "\"\r\n"
      "Content-Type: image/png\r\n\r\n";

   string tail = "\r\n--" + boundary + "--\r\n";

   char data[];
   int pos = 0;

// head
   int n1 = StringToCharArray(head, data, 0, WHOLE_ARRAY, CP_UTF8);
   if(n1 > 0)
      pos = n1 - 1;

// file
   int old = ArraySize(data);
   ArrayResize(data, pos + ArraySize(file) + 1);
   ArrayCopy(data, file, pos, 0, WHOLE_ARRAY);
   pos += ArraySize(file);

// tail
   int n2 = StringToCharArray(tail, data, pos, WHOLE_ARRAY, CP_UTF8);
   if(n2 > 0)
      pos += n2 - 1;

   ArrayResize(data, pos);

   string headers = "Content-Type: multipart/form-data; boundary=" + boundary + "\r\n";

   ResetLastError();
   char result[];
   if(!RecordDiscordAttempt("IMAGE_ATTEMPT",0)) { FileDelete(filename); return; }
   int http = WebRequest("POST", get_discord_webhook(), headers, 5000, data, result, headers);

   RecordDiscordAttempt("IMAGE_RESULT",http);
   if(http < 200 || http >= 300)
      Print("Discord screenshot upload failed. http=", http, " err=", GetLastError());

   FileDelete(filename);
  }
