#ifndef __WEBHOOK_CONFIG_MQH__
#define __WEBHOOK_CONFIG_MQH__

class CWebhookConfig
  {
private:
   string            m_system;
   string            m_test;
   string            m_keys[];
   string            m_webhooks[];
   string            m_aliases[];

   string            TrimCopy(string s) const
     {
      StringTrimLeft(s);
      StringTrimRight(s);
      return s;
     }

   string            UpperCopy(string s) const
     {
      StringToUpper(s);
      return s;
     }

   void              Clear()
     {
      m_system = "";
      m_test   = "";
      ArrayResize(m_keys, 0);
      ArrayResize(m_webhooks, 0);
      ArrayResize(m_aliases, 0);
     }

   bool              AddRoute(const string key_raw,
                              const string webhook_raw,
                              const string aliases_raw)
     {
      string key     = UpperCopy(TrimCopy(key_raw));
      string webhook = TrimCopy(webhook_raw);
      string aliases = TrimCopy(aliases_raw);

      if(key == "" || webhook == "")
         return false;

      int n = ArraySize(m_keys);
      ArrayResize(m_keys, n + 1);
      ArrayResize(m_webhooks, n + 1);
      ArrayResize(m_aliases, n + 1);

      m_keys[n]     = key;
      m_webhooks[n] = webhook;
      m_aliases[n]  = aliases;
      return true;
     }

public:
                     CWebhookConfig()
     {
      Clear();
     }

   bool              Load(const string file_name)
     {
      Clear();

      ResetLastError();
      int h = FileOpen(file_name, FILE_READ | FILE_TXT | FILE_ANSI | FILE_SHARE_READ);
      if(h == INVALID_HANDLE)
        {
         Print("WebhookConfig: Datei konnte nicht geoeffnet werden: ",
               file_name, " error=", GetLastError());
         return false;
        }

      const ushort sep = (ushort)StringGetCharacter("|", 0);
      int line_no = 0;

      while(!FileIsEnding(h))
        {
         string line = FileReadString(h);
         line_no++;
         line = TrimCopy(line);

         if(line == "")
            continue;

         ushort first = (ushort)StringGetCharacter(line, 0);
         if(first == '#' || first == ';')
            continue;

         string parts[];
         int n = StringSplit(line, sep, parts);
         if(n < 2)
           {
            Print("WebhookConfig: ungueltige Zeile ", line_no,
                  " in ", file_name);
            FileClose(h);
            return false;
           }

         string key     = UpperCopy(TrimCopy(parts[0]));
         string webhook = TrimCopy(parts[1]);
         string aliases = (n >= 3 ? TrimCopy(parts[2]) : "");

         if(key == "SYSTEM")
           {
            m_system = webhook;
            continue;
           }

         if(key == "TEST")
           {
            m_test = webhook;
            if(!AddRoute("test", webhook, aliases))
              {
               FileClose(h);
               return false;
              }
            continue;
           }

         if(!AddRoute(key, webhook, aliases))
           {
            Print("WebhookConfig: unvollstaendige Route in Zeile ", line_no);
            FileClose(h);
            return false;
           }
        }

      FileClose(h);

      if(m_system == "")
        {
         Print("WebhookConfig: SYSTEM fehlt in ", file_name);
         return false;
        }

      if(m_test == "")
        {
         Print("WebhookConfig: TEST fehlt in ", file_name);
         return false;
        }

      if(ArraySize(m_keys) <= 0)
        {
         Print("WebhookConfig: keine Symbol-Routen in ", file_name);
         return false;
        }

      Print("WebhookConfig geladen: ", ArraySize(m_keys), " Routen aus ", file_name);
      return true;
     }

   string            SystemWebhook() const { return m_system; }
   string            TestWebhook()   const { return m_test; }

   int               RouteCount() const
     {
      return ArraySize(m_keys);
     }

   string            RouteKey(const int index) const
     {
      if(index < 0 || index >= ArraySize(m_keys))
         return "";
      return m_keys[index];
     }

   string            RouteWebhook(const int index) const
     {
      if(index < 0 || index >= ArraySize(m_webhooks))
         return "";
      return m_webhooks[index];
     }

   string            RouteAliases(const int index) const
     {
      if(index < 0 || index >= ArraySize(m_aliases))
         return "";
      return m_aliases[index];
     }
  };

#endif // __WEBHOOK_CONFIG_MQH__
