//+------------------------------------------------------------------+
//|                                                 database.mqh.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include "ClassDBSQLite.mqh"

input string Databasename = "dwhsignalservice"; 
 DBSQLite db;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void initdb()
  {
  db(Databasename);                   // create or open the base in the constructor
   db.getHandle();                    // 65537 / ok
   Print("Database geht "+ FileIsExist(Databasename + ".sqlite"));  // true / ok
   createTables();

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createTables()
  {


   if(db.isOpen())
     {
      db.execute(StringFormat("CREATE TABLE %s (msg text)", Table));
     }

  }

/*
// Structure to hold trade information
struct TradeInfo
  {
   int               tradenummer;
   string            symbol;
   string            type;
   double            price;
   double            lots;
   double            sl;
   double            tp;
   string            sabioentry;
   string            sabiosl;
   string            sabiotp;
   bool              was_send;
  };
*/
