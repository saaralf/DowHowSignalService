//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#ifndef __C_WEBHOOK_ROUTER__
#define __C_WEBHOOK_ROUTER__
//+------------------------------------------------------------------+
//| Webhook Router                                                   |
//+------------------------------------------------------------------+
class CWebhookRouter
  {
private:
   struct Route
     {
      string         key;         // kanonischer Key (z.B. EURUSD, NASDAQ)
      string         webhook;     // URL
      string         patterns[];  // Alias-Patterns (mit * ?)
     };

   Route             routes[];
   string            webhook_system;
   bool              require_known;

private:
   string            ToUpperCopy(const string s)
     {
      string t = s;
      StringToUpper(t);
      return t;
     }

   string            TrimCopy(const string s)
     {
      string t = s;
      StringTrimLeft(t);
      StringTrimRight(t);
      return t;
     }

   // Schneidet Broker-Suffixe ab und behält nur A-Z0-9
   string            NormalizeSymbol(const string sym)
     {
      if(sym == "")
         return "";

      string up = ToUpperCopy(sym);

      // häufige Trenner: ab erstem Vorkommen abschneiden
      int cut = -1;
      const string delims[] = {".","_","-"," ","#"};
      for(int i=0;i<ArraySize(delims);i++)
        {
         int p = StringFind(up, delims[i], 0);
         if(p >= 0)
           {
            cut = p;
            break;
           }
        }
      if(cut > 0)
         up = StringSubstr(up, 0, cut);

      // nur A-Z0-9 behalten
      string out = "";
      for(int i=0;i<(int)StringLen(up);i++)
        {
         ushort c = (ushort)StringGetCharacter(up, i);
         if((c>='A' && c<='Z') || (c>='0' && c<='9'))
            out += CharToString((uchar)c);
        }
      return out;
     }

   // Wildcard-Match (* und ?), case-insensitive
   bool              WildMatchCI(const string text_raw, const string pattern_raw)
     {
      string text = ToUpperCopy(text_raw);
      string pat  = ToUpperCopy(pattern_raw);

      int t=0, p=0, star=-1, match=0;
      int tl=(int)StringLen(text), pl=(int)StringLen(pat);

      while(t < tl)
        {
         if(p < pl)
           {
            ushort pc = (ushort)StringGetCharacter(pat, p);
            ushort tc = (ushort)StringGetCharacter(text, t);

            if(pc=='?' || pc==tc)
              {
               t++;
               p++;
               continue;
              }
            if(pc=='*')
              {
               star=p;
               match=t;
               p++;
               continue;
              }
           }

         if(star != -1)
           {
            p = star + 1;
            match++;
            t = match;
            continue;
           }
         return false;
        }

      // Restliche * erlauben
      while(p < pl && (ushort)StringGetCharacter(pat, p) == '*')
         p++;
      return (p == pl);
     }

   void              SplitCSV(const string csv, string &out[])
     {
      ArrayResize(out, 0);
      if(csv == "")
         return;

      string tmp[];
      int n = StringSplit(csv, ',', tmp);
      if(n <= 0)
         return;

      ArrayResize(out, n);
      for(int i=0;i<n;i++)
         out[i] = TrimCopy(tmp[i]);
     }

   void              AddRoute(const string key, const string webhook, const string aliases_csv)
     {
      int n = ArraySize(routes);
      ArrayResize(routes, n+1);

      routes[n].key     = ToUpperCopy(TrimCopy(key));
      routes[n].webhook = TrimCopy(webhook);

      string pats[];
      SplitCSV(aliases_csv, pats);
      ArrayResize(routes[n].patterns, ArraySize(pats));
      for(int i=0;i<ArraySize(pats);i++)
         routes[n].patterns[i] = ToUpperCopy(TrimCopy(pats[i]));
     }

   string            CanonicalFromSymbolInfoFX(const string broker_symbol)
     {
      string base="", profit="";
      if(SymbolInfoString(broker_symbol, SYMBOL_CURRENCY_BASE, base) &&
         SymbolInfoString(broker_symbol, SYMBOL_CURRENCY_PROFIT, profit))
        {
         base   = ToUpperCopy(TrimCopy(base));
         profit = ToUpperCopy(TrimCopy(profit));
         if(StringLen(base)==3 && StringLen(profit)==3)
            return base + profit; // z.B. EURUSD
        }
      return "";
     }

   int               FindRouteByKey(const string key_up)
     {
      for(int i=0;i<ArraySize(routes);i++)
         if(routes[i].key == key_up)
            return i;
      return -1;
     }

public:
                     CWebhookRouter() { ArrayResize(routes,0); webhook_system=""; require_known=false; }

   void              Init(const bool requireKnown, const string wh_system)
     {
      require_known  = requireKnown;
      webhook_system = TrimCopy(wh_system);
     }

   void              Add(const string key, const string webhook, const string aliases_csv)
     {
      AddRoute(key, webhook, aliases_csv);
     }

   bool              Validate()
     {
      if(webhook_system == "")
        {
         CLogger::Add(LOG_LEVEL_ERROR, "WebhookRouter Validate(): InpWebhook_system ist leer.");
         if(require_known)
            return false;
        }

      for(int i=0;i<ArraySize(routes);i++)
        {
         if(routes[i].key == "" || routes[i].webhook == "")
           {
            CLogger::Add(LOG_LEVEL_ERROR, "WebhookRouter: ERROR: Route unvollständig: key='"+routes[i].key+"' webhook='"+routes[i].webhook+"'");
            if(require_known)
               return false;
           }
        }
      return true;
     }

   // Gibt URL zurück; wenn require_known und nicht gefunden: "" (damit du NICHT sendest)
   string            GetWebhookFor(const string broker_symbol)
     {
      string sym_raw = TrimCopy(broker_symbol);
      if(sym_raw == "")
         return (require_known ? "" : webhook_system);

      // 1) direkt
      string s1 = ToUpperCopy(sym_raw);
      int idx = FindRouteByKey(s1);
      if(idx >= 0)
         return routes[idx].webhook;

      // 2) normalize
      string n = NormalizeSymbol(sym_raw);
      if(n != "")
        {
         idx = FindRouteByKey(n);
         if(idx >= 0)
            return routes[idx].webhook;
        }

      // 3) FX SymbolInfo
      string fx = CanonicalFromSymbolInfoFX(sym_raw);
      if(fx != "")
        {
         idx = FindRouteByKey(fx);
         if(idx >= 0)
            return routes[idx].webhook;
        }

      // 4) aliases (wildcards), match gegen raw und normalized
      for(int i=0;i<ArraySize(routes);i++)
        {
         for(int j=0;j<ArraySize(routes[i].patterns);j++)
           {
            string pat = routes[i].patterns[j];
            if(pat == "")
               continue;

            if(WildMatchCI(s1, pat))
               return routes[i].webhook;
            if(n!="" && WildMatchCI(n, pat))
               return routes[i].webhook;
           }
        }

      // 5) fallback
      CLogger::Add(LOG_LEVEL_ERROR, "WebhookRouter: WARN: Kein Mapping für _Symbol='"+sym_raw+"' (norm='"+n+"', fx='"+fx+"') -> system");
      return (require_known ? "" : webhook_system);
     }
  };



#endif //__C_WEBHOOK_ROUTER__
//+------------------------------------------------------------------+
