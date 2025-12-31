//======================== positions_cache.mqh ========================
#ifndef __POSITIONS_CACHE_MQH__
#define __POSITIONS_CACHE_MQH__

// Cache ist bewusst "pro Symbol + Timeframe".
// Quelle der Wahrheit für Laufzeit-Logik (OnTick) ist der Cache.
// Persistenz passiert weiterhin über DB_* Funktionen (SQLite).

string         g_cache_symbol = "";
ENUM_TIMEFRAMES g_cache_tf    = PERIOD_CURRENT;
bool           g_cache_ready  = false;

// öffentlich sichtbar (damit MQ5/Includes direkt iterieren können)
DB_PositionRow g_cache_rows[];

// -------- Basics --------
int Cache_Load(const string symbol, ENUM_TIMEFRAMES tf)
{
   g_cache_symbol = symbol;
   g_cache_tf     = tf;
   g_cache_ready  = true;
   return DB_LoadPositions(symbol, tf, g_cache_rows);
}

bool Cache_Ensure()
{
   if(!g_cache_ready || g_cache_symbol != _Symbol || g_cache_tf != (ENUM_TIMEFRAMES)_Period)
      Cache_Load(_Symbol, (ENUM_TIMEFRAMES)_Period);
   return true;
}

int Cache_Size()
{
   return ArraySize(g_cache_rows);
}

// -------- Find / Get --------
int Cache_FindIdx(const string direction, const int trade_no, const int pos_no)
{
   int n = ArraySize(g_cache_rows);
   for(int i=0; i<n; i++)
   {
      if(g_cache_rows[i].direction == direction &&
         g_cache_rows[i].trade_no   == trade_no &&
         g_cache_rows[i].pos_no     == pos_no)
         return i;
   }
   return -1;
}

bool Cache_Get(const string direction, const int trade_no, const int pos_no, DB_PositionRow &out_row)
{
   int i = Cache_FindIdx(direction, trade_no, pos_no);
   if(i < 0) return false;
   out_row = g_cache_rows[i];
   return true;
}

// -------- Mutations (nur Cache) --------
void Cache_UpsertLocal(const DB_PositionRow &row)
{
   int i = Cache_FindIdx(row.direction, row.trade_no, row.pos_no);
   if(i < 0)
   {
      int n = ArraySize(g_cache_rows);
      ArrayResize(g_cache_rows, n+1);
      g_cache_rows[n] = row;
      return;
   }
   g_cache_rows[i] = row;
}

bool Cache_DeleteLocal(const string direction, const int trade_no, const int pos_no)
{
   int i = Cache_FindIdx(direction, trade_no, pos_no);
   if(i < 0) return false;

   int n = ArraySize(g_cache_rows);
   if(i != n-1)
      g_cache_rows[i] = g_cache_rows[n-1];
   ArrayResize(g_cache_rows, n-1);
   return true;
}

bool Cache_UpdateStatusLocal(const string direction, const int trade_no, const int pos_no,
                            const string new_status, const int new_pending)
{
   int i = Cache_FindIdx(direction, trade_no, pos_no);
   if(i < 0) return false;

   g_cache_rows[i].status     = new_status;
   g_cache_rows[i].is_pending = new_pending;
   g_cache_rows[i].updated_at = TimeCurrent();
   return true;
}

bool Cache_UpdateEntrySL_Local(const string direction, const int trade_no, const int pos_no,
                               const bool is_entry, const double price)
{
   int i = Cache_FindIdx(direction, trade_no, pos_no);
   if(i < 0) return false;

   if(is_entry) g_cache_rows[i].entry = price;
   else         g_cache_rows[i].sl    = price;

   g_cache_rows[i].updated_at = TimeCurrent();
   return true;
}

// -------- Helpers (optional) --------
int Cache_GetPosNoCount(const string direction, const int trade_no)
{
   int n = ArraySize(g_cache_rows);
   int c = 0;
   for(int i=0; i<n; i++)
   {
      if(g_cache_rows[i].direction == direction && g_cache_rows[i].trade_no == trade_no)
         c++;
   }
   return c;
}

#endif // __POSITIONS_CACHE_MQH__
