//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include "discord.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class TradeDB
  {
private:
   string            db_path;
   void              *db;

public:
                     TradeDB(const string &path) : db_path(path), db(NULL) {}
                    ~TradeDB() { Close(); }

   bool              Open()
     {
      if(DatabaseOpen(db_path, db))
        {
         Print("Database opened successfully.");
         return true;
        }
      Print("Failed to open database.");
      return false;
     }

   void              Close()
     {
      if(db)
        {
         DatabaseClose((void*)db);
         db = NULL;
        }
     }

   bool              CreateTable()
     {
      string query = "CREATE TABLE IF NOT EXISTS trades (";
      query = query+"  tradenummer INTEGER PRIMARY KEY, ";
      query = query+"   symbol TEXT, ";
      query = query+"     type TEXT, ";
      query = query+"     price REAL, ";
      query = query+"    lots REAL, ";
      query = query+"    sl REAL, ";
      query = query+"    tp REAL, ";
      query = query+"    sabioentry TEXT, ";
      query = query+"    sabiosl TEXT, ";
      query = query+"    sabiotp TEXT, ";
      query = query+"   was_send INTEGER, ";
      query = query+"    is_pending INTEGER,";
      query = query+"    was_stoppedin INTEGER);";

      return DatabaseExecute(db, query);
     }

   bool              BeginTransaction()
     {
      return DatabaseExecute(db, "BEGIN TRANSACTION;");
     }

   bool              CommitTransaction()
     {
      return DatabaseExecute(db, "COMMIT;");
     }

   bool              RollbackTransaction()
     {
      return DatabaseExecute(db, "ROLLBACK;");
     }

   bool              InsertTrade(const TradeInfo &trade)
     {
      BeginTransaction();
      string query = "INSERT INTO trades VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
      void *stmt;
      if(!DatabasePrepare(db, query, stmt))
         return false;

      DatabaseBind(stmt, 0, trade.tradenummer);
      DatabaseBind(stmt, 1, trade.symbol);
      DatabaseBind(stmt, 2, trade.type);
      DatabaseBind(stmt, 3, trade.price);
      DatabaseBind(stmt, 4, trade.lots);
      DatabaseBind(stmt, 5, trade.sl);
      DatabaseBind(stmt, 6, trade.tp);
      DatabaseBind(stmt, 7, trade.sabioentry);
      DatabaseBind(stmt, 8, trade.sabiosl);
      DatabaseBind(stmt, 9, trade.sabiotp);
      DatabaseBind(stmt, 10, trade.was_send);
      DatabaseBind(stmt, 11, trade.is_pending);
      DatabaseBind(stmt, 12, trade.was_stoppedin);

      bool result = DatabaseExecute(stmt);
      DatabaseFinalize(stmt);
      result ? CommitTransaction() : RollbackTransaction();
      return result;
     }

   bool              UpdateTrade(const TradeInfo &trade)
     {
      BeginTransaction();
      string query = "UPDATE trades SET symbol=?, type=?, price=?, lots=?, sl=?, tp=?, sabioentry=?, sabiosl=?, sabiotp=?, was_send=?, is_pending=?, was_stoppedin=? WHERE tradenummer=?";
      void *stmt;
      if(!DatabasePrepare(db, query, stmt))
         return false;

      DatabaseBind(stmt, 0, trade.symbol);
      DatabaseBind(stmt, 1, trade.type);
      DatabaseBind(stmt, 2, trade.price);
      DatabaseBind(stmt, 3, trade.lots);
      DatabaseBind(stmt, 4, trade.sl);
      DatabaseBind(stmt, 5, trade.tp);
      DatabaseBind(stmt, 6, trade.sabioentry);
      DatabaseBind(stmt, 7, trade.sabiosl);
      DatabaseBind(stmt, 8, trade.sabiotp);
      DatabaseBind(stmt, 9, trade.was_send);
      DatabaseBind(stmt, 10, trade.is_pending);
      DatabaseBind(stmt, 11, trade.was_stoppedin);
      DatabaseBind(stmt, 12, trade.tradenummer);

      bool result = DatabaseExecute(stmt);
      DatabaseFinalize(stmt);
      result ? CommitTransaction() : RollbackTransaction();
      return result;
     }

   bool              DeleteTrade(int tradenummer)
     {
      BeginTransaction();
      string query = "DELETE FROM trades WHERE tradenummer=?";
      void *stmt;
      if(!DatabasePrepare(db, query, stmt))
         return false;
      DatabaseBind(stmt, 0, tradenummer);
      bool result = DatabaseExecute(stmt);
      DatabaseFinalize(stmt);
      result ? CommitTransaction() : RollbackTransaction();
      return result;
     }

   bool              GetTrade(int tradenummer, TradeInfo &trade)
     {
      string query = "SELECT * FROM trades WHERE tradenummer=?";
      void *stmt;
      if(!DatabasePrepare(db, query, stmt))
         return false;
      DatabaseBind(stmt, 0, tradenummer);

      if(DatabaseStep(stmt))
        {
         trade.tradenummer = DatabaseColumnInteger(stmt, 0);
         trade.symbol = DatabaseColumnString(stmt, 1);
         trade.type = DatabaseColumnString(stmt, 2);
         trade.price = DatabaseColumnDouble(stmt, 3);
         trade.lots = DatabaseColumnDouble(stmt, 4);
         trade.sl = DatabaseColumnDouble(stmt, 5);
         trade.tp = DatabaseColumnDouble(stmt, 6);
         trade.sabioentry = DatabaseColumnString(stmt, 7);
         trade.sabiosl = DatabaseColumnString(stmt, 8);
         trade.sabiotp = DatabaseColumnString(stmt, 9);
         trade.was_send = DatabaseColumnInteger(stmt, 10) > 0;
         trade.is_pending = DatabaseColumnInteger(stmt, 11) > 0;
         trade.was_stoppedin = DatabaseColumnInteger(stmt, 12) > 0;
         DatabaseFinalize(stmt);
         return true;
        }
      DatabaseFinalize(stmt);
      return false;
     }
  };
//+------------------------------------------------------------------+
