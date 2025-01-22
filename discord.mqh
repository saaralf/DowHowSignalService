//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

/* History
   16.01.2025 (Steffen) Zeilen Input LinkChannelM2 und ...M5 hinzugefügt - wird nicht angezeigt
   16.01.2025 (saaralf) Methoden FormatSLMessage, FormatTPMessage ,FormatUpdateTradeMessage und FormatCancelTradeMessage erstellt

//-------------------------------------------------------------------*/

#property copyright "Copyright 2025, saaralf, Michael Keller"
#property link      "kellermichael.de"
#property version   "1.01"

input group "=====Discord Settings====="
input string DiscordBotName = "DowHow Trading Signalservice";    // Name of the bot in Discord
input string LinkChannelM2 = "https://discord.com/api/webhooks/1313603310548418580/536YHYIxfiJwbpPB0mj8t1CRuePiVpLCs8TbEwQ06NVcUd_ekftgsnbGitLmjXhGcbU4";  // Discord Channel M2 Link
input string LinkChannelM5 = "https://discord.com/api/webhooks/1313603118768062575/TPHxceiomoSnyZmp4RZnKtwzM2U4ptc-lTCcnUxj4qqpo1UdXedoyRQaB_Gv-gE9JDSP";  // Discord Channel M5 Link
input string Allow_Period1 = "PERIOD_M1"; // Erlaubte Zeiteinheiten
input string Allow_Period2 = "PERIOD_M2";
input string Allow_Period3 = "PERIOD_M5";
input string Allow_Period4 = "PERIOD_M10";
input string Allow_Period5 = "PERIOD_M15";




input color MessageColor = clrBlue;                 // Color for Discord messages
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CDiscord
  {

private:
   string            webhook;
   datetime          lastMessageTime;
   bool              debug;
   bool              isWebRequestEnabled;

public:

                     CDiscord(void);
                    ~CDiscord(void);

   bool              checkDiscord();
   void              create(string webhook);
   void              setWebhook(string webhook);
   void              setWebhook();
   string            getWebhook();
   void              setDebug(bool debug);
   bool              isDebug();
   string            CDiscord::get_discord_webhook();
   bool              SendDiscordMessage(string message, bool isError = false);
   string            CDiscord::SendScreenShot(string symbol,int _period, int ScreenWidth = 1912, int ScreenHeight = 1080);
   string            EscapeJSON(string text);
   void              toString();


protected:



  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void               CDiscord::toString()
  {


   Print("CDiscord");
   Print("webhook: "+webhook);
   Print("isdebug: "+debug);
   Print("isWebRequestEnabled: "+isWebRequestEnabled);
   Print("lastMessageTime: "+lastMessageTime);
   Print("EndeCDiscord");

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDiscord::setDebug(bool debug) {debug=debug;}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDiscord::isDebug() {return debug;}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDiscord::create(string webhook)
  {
   webhook= get_discord_webhook();

   debug=false;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CDiscord::CDiscord(void) {}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CDiscord::~CDiscord(void) {}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDiscord::setWebhook(string webhook) {webhook=webhook;}
void CDiscord::setWebhook() {webhook=get_discord_webhook();}

string CDiscord::getWebhook() {return webhook;}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDiscord::checkDiscord()
  {

  


      Print("Initialization step 1: Checking WebRequest permissions...");



      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
        {
         Print("Error: WebRequest is not allowed. Please allow in Tool -> Options -> Expert Advisors");
         return false;
        }
 if(isDebug())
     {

      Print("Initialization step 2: Testing Discord connection...");

      // Simple test message
      ResetLastError();

      string test_message = "{\"content\":\"Test message from MT5\"}";
      string headers = "Content-Type: application/json\r\n";
      char data[], result[];
      ArrayResize(data, StringToCharArray(test_message, data, 0, WHOLE_ARRAY, CP_UTF8) - 1);
      /*
         int res = WebRequest(
                      "POST",
                      get_discord_webhook(),
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
      */
      Print("Initialization step 3: Test Period");
      if(!Period() == Allow_Period1 || !Period() == Allow_Period2)
        {
         Print("Check Period: Falsche Zeiteingeit: Nur "+Allow_Period1 + " und "+ Allow_Period2+ "erlaubt");
         return false;
        }
  }
      isWebRequestEnabled = true;
      Print("Initialization step 4: All checks passed!");
      Print("Successfully connected to Discord!");



   

   return true;
  }

// Gibt den korrekten Webhook für die Zeiteinheit zurück, damit die Messages an den richtigen Discord Server gesendet werden
string CDiscord::get_discord_webhook()
  {
   if(!isDebug())
     {
      if(Period()==Allow_Period1)
        {
         return LinkChannelM2;
        }
      if(Period()==Allow_Period2)
        {
         return LinkChannelM5;
        }
     }

   string discord_webhook_test = "https://discord.com/api/webhooks/1328803943068860416/O7dsN4wcNk-vSA9sQQx1ZFzZUAhx8NsPe4JFPxQ4MuQtiOx1BWepkXqSz00ZkCrqiDHw";
   Print("Falsche Zeiteinheit "+ EnumToString(Period())+" eingestellt:. Derzeit nur M2 und M5 definiert!");
   return discord_webhook_test;
  }


//+------------------------------------------------------------------+
//| Function to escape JSON string                                     |
//+------------------------------------------------------------------+
string  CDiscord::EscapeJSON(string text)
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
bool  CDiscord::SendDiscordMessage(string message, bool isError = false)
  {


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
                getWebhook(),
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
string CDiscord::SendScreenShot(string symbol,int _period, int ScreenWidth = 1912, int ScreenHeight = 1080)
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
      filename=StringFormat("%s_%s.png",ChartSymbol(currChart),EnumToString(ChartPeriod(currChart)));
      Print("Filename:" + filename);
      //---
      if(ChartScreenShot(currChart,filename,ScreenWidth,ScreenHeight))
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
      return "fehler";
     }
   FileClose(res);
   /*
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
         res=WebRequest("POST",get_discord_webhook(),str,5000,data,data,str);
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
   */
   Sleep(5);
   return filename;
  }
//+------------------------------------------------------------------+
