#ifndef TA4_DISCORD_MQH
#define TA4_DISCORD_MQH
#include "TA4_Types.mqh"
#include "../CWebhookRouter.mqh"
#include "../WebhookConfig.mqh"
// Area 2. Does not mutate trade state or access SQLite.
class CTA4Discord
  {
private:
   CWebhookRouter m_router;
   bool m_ready;
   string m_bot;
   string m_error;
   string Escape(string s)
     { StringReplace(s,"\\","\\\\"); StringReplace(s,"\"","\\\""); StringReplace(s,"\r","\\r"); StringReplace(s,"\n","\\n"); StringReplace(s,"\t","\\t"); return s; }
   void Append(char &body[],const string text)
     { char bytes[]; int n=StringToCharArray(text,bytes,0,WHOLE_ARRAY,CP_UTF8)-1; if(n<=0)return; int offset=ArraySize(body); ArrayResize(body,offset+n); ArrayCopy(body,bytes,offset,0,n); }
public:
   CTA4Discord():m_ready(false) {}
   string Error() const { return m_error; }
   bool Init(const string config_file,const string bot)
     {
      CWebhookConfig cfg; m_bot=bot;
      if(!cfg.Load(config_file)) { m_error="Webhook configuration missing or invalid"; return false; }
      m_router.Init(true,cfg.SystemWebhook());
      for(int i=0;i<cfg.RouteCount();i++) m_router.Add(cfg.RouteKey(i),cfg.RouteWebhook(i),cfg.RouteAliases(i));
      m_ready=true; return true; // no automatic connection-test post
     }
   bool HasRoute(const string symbol) { return m_ready && m_router.GetWebhookFor(symbol)!=""; }
   string Deliver(const string symbol,const TA4_Outbox &o,const bool mention)
     {
      m_error="";
      if(!m_ready) { m_error="Discord disabled or not configured"; return "FAILED"; }
      string url=m_router.GetWebhookFor(symbol);
      if(url=="") { m_error="No Discord route for this symbol"; return "FAILED"; }
      string mentions=mention?"[\"everyone\"]":"[]";
      string json="{\"username\":\""+Escape(m_bot)+"\",\"content\":\""+Escape(o.message)+"\",\"allowed_mentions\":{\"parse\":"+mentions+"}}";
      char body[]; string headers="Content-Type: application/json\r\n";
      bool with_image=false;
      if(o.image!="")
        {
         int f=FileOpen(o.image,FILE_READ|FILE_BIN|FILE_SHARE_READ);
         if(f!=INVALID_HANDLE)
           {
            int size=(int)FileSize(f); char png[]; ArrayResize(png,size);
            uint read=FileReadArray(f,png); FileClose(f);
            if(size>0 && read==(uint)size)
              {
               string boundary="TA4_"+IntegerToString((long)GetMicrosecondCount());
               headers="Content-Type: multipart/form-data; boundary="+boundary+"\r\n";
               Append(body,"--"+boundary+"\r\nContent-Disposition: form-data; name=\"payload_json\"\r\n\r\n"+json+"\r\n");
               Append(body,"--"+boundary+"\r\nContent-Disposition: form-data; name=\"files[0]\"; filename=\"chart.png\"\r\nContent-Type: image/png\r\n\r\n");
               int offset=ArraySize(body); ArrayResize(body,offset+size); ArrayCopy(body,png,offset,0,size);
               Append(body,"\r\n--"+boundary+"--\r\n"); with_image=true;
              }
           }
         if(!with_image) m_error="Screenshot missing; text-only delivery";
        }
      if(!with_image) { int n=StringToCharArray(json,body,0,WHOLE_ARRAY,CP_UTF8); ArrayResize(body,n-1); }
      char result[]; string response_headers="";
      ResetLastError(); int code=WebRequest("POST",url,headers,5000,body,result,response_headers);
      if(code>=200 && code<300) return "SENT";
      // Never log the webhook URL, payload or response body.
      m_error="Discord HTTP "+IntegerToString(code)+" / MT5 "+IntegerToString(GetLastError());
      if(code==429) return "RATE_LIMITED";
      if(code>=400 && code<500) return "FAILED";
      return "UNKNOWN"; // network/timeout/5xx: delivery may have happened
     }
  };
#endif
