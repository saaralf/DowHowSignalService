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




#endif // __UI_REGISTRY_MQH__
//+------------------------------------------------------------------+
