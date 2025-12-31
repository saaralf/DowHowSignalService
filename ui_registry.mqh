// ui_registry.mqh
// Zentraler Registry-Mechanismus: jedes von dir erstellte Chart-Objekt wird
// per Name registriert. Du kannst danach zuverlässig ALLE registrierten
// Objekte löschen (oder nach Prefix/Suffix).
#ifndef __UI_REGISTRY_MQH__
#define __UI_REGISTRY_MQH__


// ------------------------------------------------------------------
// Globales Registry-Array
// ------------------------------------------------------------------
string g_UI_Registry[];

// ------------------------------------------------------------------
// Helpers
// ------------------------------------------------------------------
int UI_Reg_IndexOf(const string name)
  {
   int n = ArraySize(g_UI_Registry);
   for(int i=0; i<n; i++)
      if(g_UI_Registry[i] == name)
         return i;
   return -1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UI_Reg_Add(const string name)
  {
   if(name == "")
      return;

// unique
   if(UI_Reg_IndexOf(name) >= 0)
      return;

   int n = ArraySize(g_UI_Registry);
   ArrayResize(g_UI_Registry, n+1);
   g_UI_Registry[n] = name;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool UI_Reg_Remove(const string name)
  {
   int idx = UI_Reg_IndexOf(name);
   if(idx < 0)
      return false;

   int n = ArraySize(g_UI_Registry);
   for(int i=idx; i<n-1; i++)
      g_UI_Registry[i] = g_UI_Registry[i+1];

   ArrayResize(g_UI_Registry, n-1);
   return true;
  }

// Löscht Objekt (falls existiert) + entfernt es aus Registry
bool UI_Reg_DeleteOne(const string name)
  {
   bool ok = true;

   if(ObjectFind(0, name) >= 0)
      ok = ObjectDelete(0, name);

   UI_Reg_Remove(name); // auch wenn nicht existiert -> sauber halten
   return ok;
  }

// ------------------------------------------------------------------
// Bulk Deletes
// ------------------------------------------------------------------

// Löscht ALLE registrierten Objekte (in Reverse-Reihenfolge)
int UI_Reg_DeleteAll()
  {
   int deleted = 0;

   for(int i = ArraySize(g_UI_Registry) - 1; i >= 0; i--)
     {
      string name = g_UI_Registry[i];
      if(name == "")
         continue;

      if(ObjectFind(0, name) >= 0)
        {
         if(ObjectDelete(0, name))
           {
            deleted++;
           
           }
        }
     }

   ArrayResize(g_UI_Registry, 0);
   return deleted;
  }

// Löscht registrierte Objekte nach Prefix (und entfernt sie aus Registry)
int UI_Reg_DeleteByPrefix(const string prefix)
  {
   int deleted = 0;

   for(int i = ArraySize(g_UI_Registry) - 1; i >= 0; i--)
     {
      string name = g_UI_Registry[i];
      if(StringFind(name, prefix, 0) == 0)
        {
         if(ObjectFind(0, name) >= 0)
           {
            if(ObjectDelete(0, name))
               deleted++;
           }

         // remove from registry (remove-at)
         int n = ArraySize(g_UI_Registry);
         for(int k=i; k<n-1; k++)
            g_UI_Registry[k] = g_UI_Registry[k+1];
         ArrayResize(g_UI_Registry, n-1);
        }
     }

   return deleted;
  }

// Löscht registrierte Objekte nach Suffix (und entfernt sie aus Registry)
int UI_Reg_DeleteBySuffix(const string suffix)
  {
   int deleted = 0;
   int sufLen  = (int)StringLen(suffix);

   for(int i = ArraySize(g_UI_Registry) - 1; i >= 0; i--)
     {
      string name = g_UI_Registry[i];
      int nLen = (int)StringLen(name);

      if(nLen >= sufLen && StringSubstr(name, nLen - sufLen, sufLen) == suffix)
        {
         if(ObjectFind(0, name) >= 0)
           {
            if(ObjectDelete(0, name))
               deleted++;
           }

         int n = ArraySize(g_UI_Registry);
         for(int k=i; k<n-1; k++)
            g_UI_Registry[k] = g_UI_Registry[k+1];
         ArrayResize(g_UI_Registry, n-1);
        }
     }

   return deleted;
  }
// ------------------------------------------------------------------
// Adopt: nimmt bereits existierende Chart-Objekte per Prefix in die Registry auf.
// Damit kannst du beim EA-Start "alte Leichen" einsammeln und später sauber löschen.
// Rückgabe: Anzahl neu adoptierter Objekte.
// ------------------------------------------------------------------
int UI_Reg_AdoptByPrefix(const string prefix)
  {
   int adopted = 0;

   int total = ObjectsTotal(0, -1, -1);
   for(int i = 0; i < total; i++)
     {
      string name = ObjectName(0, i, -1, -1);
      if(name == "")
         continue;

      if(StringFind(name, prefix, 0) == 0)
        {
         int before = ArraySize(g_UI_Registry);
         UI_Reg_Add(name);
         if(ArraySize(g_UI_Registry) > before)
            adopted++;
        }
     }

   return adopted;
  }

// ------------------------------------------------------------------
// Adopt: per Suffix (z.B. "_TAG" oder "_12_1").
// Rückgabe: Anzahl neu adoptierter Objekte.
// ------------------------------------------------------------------
int UI_Reg_AdoptBySuffix(const string suffix)
  {
   int adopted = 0;
   int sufLen  = (int)StringLen(suffix);
   if(sufLen == 0)
      return 0;

   int total = ObjectsTotal(0, -1, -1);
   for(int i = 0; i < total; i++)
     {
      string name = ObjectName(0, i, -1, -1);
      if(name == "")
         continue;

      int nLen = (int)StringLen(name);
      if(nLen < sufLen)
         continue;

      if(StringSubstr(name, nLen - sufLen, sufLen) == suffix)
        {
         int before = ArraySize(g_UI_Registry);
         UI_Reg_Add(name);
         if(ArraySize(g_UI_Registry) > before)
            adopted++;
        }
     }

   return adopted;
  }



#endif // __UI_REGISTRY_MQH__
//+------------------------------------------------------------------+
