//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#ifndef __POSITIONS_CACHE_MQH__
#define __POSITIONS_CACHE_MQH__
#include "CDBService.mqh"
string          g_cache_symbol = "";
ENUM_TIMEFRAMES g_cache_tf     = PERIOD_CURRENT;
bool            g_cache_ready  = false;

DB_PositionRow  g_cache_rows[];

// ---------------------------------------------------------
// helpers
// ---------------------------------------------------------
bool Cache_Matches(const string symbol, const ENUM_TIMEFRAMES tf)
  {
   return (g_cache_ready &&
           g_cache_symbol == symbol &&
           g_cache_tf     == tf);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Cache_Invalidate()
  {
   g_cache_symbol = "";
   g_cache_tf     = PERIOD_CURRENT;
   g_cache_ready  = false;
   ArrayResize(g_cache_rows, 0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Cache_Load(const string symbol, ENUM_TIMEFRAMES tf)
  {
   ArrayResize(g_cache_rows, 0);
   g_cache_symbol = symbol;
   g_cache_tf     = tf;

   int n = g_DB.LoadPositions(symbol, tf, g_cache_rows);
   g_cache_ready = (n >= 0);

   if(!g_cache_ready)
     {
      g_cache_symbol = "";
      g_cache_tf     = PERIOD_CURRENT;
      ArrayResize(g_cache_rows, 0);
     }

   return n;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Cache_EnsureFor(const string symbol, const ENUM_TIMEFRAMES tf)
  {
   if(!Cache_Matches(symbol, tf))
      return (Cache_Load(symbol, tf) >= 0);
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Cache_Ensure()
  {
   return Cache_EnsureFor(_Symbol, (ENUM_TIMEFRAMES)_Period);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Cache_Size()
  {
   return ArraySize(g_cache_rows);
  }

// ---------------------------------------------------------
// find / get
// ---------------------------------------------------------
int Cache_FindIdx(const string symbol,
                  const ENUM_TIMEFRAMES tf,
                  const string direction,
                  const int trade_no,
                  const int pos_no)
  {
   if(!Cache_Matches(symbol, tf))
      return -1;

   int n = ArraySize(g_cache_rows);
   for(int i = 0; i < n; i++)
     {
      if(g_cache_rows[i].direction == direction &&
         g_cache_rows[i].trade_no   == trade_no &&
         g_cache_rows[i].pos_no     == pos_no)
         return i;
     }
   return -1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Cache_Get(const string symbol,
               const ENUM_TIMEFRAMES tf,
               const string direction,
               const int trade_no,
               const int pos_no,
               DB_PositionRow &out_row)
  {
   if(!Cache_EnsureFor(symbol, tf))
      return false;

   int i = Cache_FindIdx(symbol, tf, direction, trade_no, pos_no);
   if(i < 0)
      return false;

   out_row = g_cache_rows[i];
   return true;
  }

// ---------------------------------------------------------
// mutations (nur Cache)
// ---------------------------------------------------------
bool Cache_UpsertLocal(const string symbol,
                       const ENUM_TIMEFRAMES tf,
                       const DB_PositionRow &row)
  {

   if(row.symbol != symbol || row.tf != CDBService::TFToString(tf))
      return false;

   if(!Cache_EnsureFor(symbol, tf))
      return false;

   int i = Cache_FindIdx(symbol, tf, row.direction, row.trade_no, row.pos_no);
   if(i < 0)
     {
      int n = ArraySize(g_cache_rows);
      ArrayResize(g_cache_rows, n + 1);
      g_cache_rows[n] = row;
      return true;
     }

   g_cache_rows[i] = row;
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Cache_UpdateStatusLocal(const string symbol,
                             const ENUM_TIMEFRAMES tf,
                             const string direction,
                             const int trade_no,
                             const int pos_no,
                             const string new_status,
                             const int new_pending)
  {
   if(!Cache_EnsureFor(symbol, tf))
      return false;

   int i = Cache_FindIdx(symbol, tf, direction, trade_no, pos_no);
   if(i < 0)
      return false;

   g_cache_rows[i].status     = new_status;
   g_cache_rows[i].is_pending = new_pending;
   g_cache_rows[i].updated_at = TimeCurrent();
   return true;
  }

#endif // __POSITIONS_CACHE_MQH__
//+------------------------------------------------------------------+
