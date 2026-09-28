#ifndef __TA3_REPOSITORY_MQH__
#define __TA3_REPOSITORY_MQH__

#include "logger.mqh"
#include "TA3_Types.mqh"

class CTA3Repository
  {
private:
   int               m_db;
   string            m_file;

   bool Exec(const string sql)
     {
      if(m_db == INVALID_HANDLE)
         return false;
      ResetLastError();
      if(!DatabaseExecute(m_db, sql))
        {
         CLogger::Add(LOG_LEVEL_ERROR, "TA3 DB exec failed: " + sql);
         return false;
        }
      return true;
     }

   bool ExecNonQuery(const int rq)
     {
      if(rq == INVALID_HANDLE)
         return false;
      ResetLastError();
      bool ok = DatabaseRead(rq);
      int err = GetLastError();
      if(ok)
         return true;
      return (err == ERR_DATABASE_NO_MORE_DATA);
     }

   string Key(const string symbol,const ENUM_TIMEFRAMES tf,const string suffix) const
     {
      return symbol + "|" + TA3_TFToString(tf) + "|" + suffix;
     }

public:
                     CTA3Repository():m_db(INVALID_HANDLE),m_file("") {}
                    ~CTA3Repository(){ Close(); }

   bool Open(const string file_name="DowHowSignalServiceV3.sqlite")
     {
      if(m_db != INVALID_HANDLE)
         return true;

      m_file=file_name;
      m_db=DatabaseOpen(m_file,DATABASE_OPEN_CREATE|DATABASE_OPEN_READWRITE|DATABASE_OPEN_COMMON);
      if(m_db==INVALID_HANDLE)
        {
         CLogger::Add(LOG_LEVEL_ERROR,"TA3 DatabaseOpen failed: "+m_file);
         return false;
        }

      if(!Exec("PRAGMA journal_mode=WAL;"))
         return false;

      if(!Exec("CREATE TABLE IF NOT EXISTS ta3_meta ("
               "key TEXT PRIMARY KEY,"
               "value TEXT"
               ");"))
         return false;

      if(!Exec("CREATE TABLE IF NOT EXISTS ta3_positions ("
               "symbol TEXT NOT NULL,"
               "tf TEXT NOT NULL,"
               "direction TEXT NOT NULL,"
               "trade_no INTEGER NOT NULL,"
               "pos_no INTEGER NOT NULL,"
               "entry REAL NOT NULL DEFAULT 0,"
               "sl REAL NOT NULL DEFAULT 0,"
               "lots REAL NOT NULL DEFAULT 0,"
               "sabio_entry TEXT,"
               "sabio_sl TEXT,"
               "status TEXT NOT NULL DEFAULT 'PENDING',"
               "was_sent INTEGER NOT NULL DEFAULT 0,"
               "is_pending INTEGER NOT NULL DEFAULT 1,"
               "created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),"
               "updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),"
               "PRIMARY KEY(symbol,tf,direction,trade_no,pos_no)"
               ");"))
         return false;

      return true;
     }

   void Close()
     {
      if(m_db!=INVALID_HANDLE)
        {
         DatabaseClose(m_db);
         m_db=INVALID_HANDLE;
        }
     }

   bool IsReady() const { return (m_db!=INVALID_HANDLE); }

   bool SetMeta(const string symbol,const ENUM_TIMEFRAMES tf,const string suffix,const string value)
     {
      int rq=DatabasePrepare(m_db,
         "INSERT INTO ta3_meta(key,value) VALUES(?,?) "
         "ON CONFLICT(key) DO UPDATE SET value=excluded.value;");
      if(rq==INVALID_HANDLE) return false;
      DatabaseBind(rq,0,Key(symbol,tf,suffix));
      DatabaseBind(rq,1,value);
      bool ok=ExecNonQuery(rq);
      DatabaseFinalize(rq);
      return ok;
     }

   bool GetMeta(const string symbol,const ENUM_TIMEFRAMES tf,const string suffix,string &out,const string def="")
     {
      out=def;
      int rq=DatabasePrepare(m_db,"SELECT value FROM ta3_meta WHERE key=?;");
      if(rq==INVALID_HANDLE) return false;
      DatabaseBind(rq,0,Key(symbol,tf,suffix));
      bool found=false;
      if(DatabaseRead(rq))
        {
         DatabaseColumnText(rq,0,out);
         found=true;
        }
      DatabaseFinalize(rq);
      return found;
     }

   bool SaveDraft(const string symbol,const ENUM_TIMEFRAMES tf,const TA3_Draft &d)
     {
      bool ok=true;
      ok &= SetMeta(symbol,tf,"draft.direction",d.direction);
      ok &= SetMeta(symbol,tf,"draft.entry",DoubleToString(d.entry,8));
      ok &= SetMeta(symbol,tf,"draft.sl",DoubleToString(d.sl,8));
      ok &= SetMeta(symbol,tf,"draft.sabio_entry",d.sabio_entry);
      ok &= SetMeta(symbol,tf,"draft.sabio_sl",d.sabio_sl);
      ok &= SetMeta(symbol,tf,"draft.trade_no",IntegerToString(d.requested_trade_no));
      ok &= SetMeta(symbol,tf,"draft.pos_no",IntegerToString(d.requested_pos_no));
      ok &= SetMeta(symbol,tf,"draft.sabio_entry_user",d.sabio_entry_user?"1":"0");
      ok &= SetMeta(symbol,tf,"draft.sabio_sl_user",d.sabio_sl_user?"1":"0");
      return ok;
     }

   bool LoadDraft(const string symbol,const ENUM_TIMEFRAMES tf,TA3_Draft &d)
     {
      string s="";
      GetMeta(symbol,tf,"draft.direction",s,"LONG"); d.direction=s;
      GetMeta(symbol,tf,"draft.entry",s,"0"); d.entry=StringToDouble(s);
      GetMeta(symbol,tf,"draft.sl",s,"0"); d.sl=StringToDouble(s);
      GetMeta(symbol,tf,"draft.sabio_entry",d.sabio_entry,"");
      GetMeta(symbol,tf,"draft.sabio_sl",d.sabio_sl,"");
      GetMeta(symbol,tf,"draft.trade_no",s,"0"); d.requested_trade_no=(int)StringToInteger(s);
      GetMeta(symbol,tf,"draft.pos_no",s,"1"); d.requested_pos_no=(int)StringToInteger(s);
      GetMeta(symbol,tf,"draft.sabio_entry_user",s,"0"); d.sabio_entry_user=(s=="1");
      GetMeta(symbol,tf,"draft.sabio_sl_user",s,"0"); d.sabio_sl_user=(s=="1");
      return true;
     }

   int MaxTradeNo(const string symbol,const ENUM_TIMEFRAMES tf)
     {
      int out=0;
      int rq=DatabasePrepare(m_db,
         "SELECT COALESCE(MAX(trade_no),0) FROM ta3_positions WHERE symbol=? AND tf=?;");
      if(rq==INVALID_HANDLE) return 0;
      DatabaseBind(rq,0,symbol);
      DatabaseBind(rq,1,TA3_TFToString(tf));
      if(DatabaseRead(rq))
         DatabaseColumnInteger(rq,0,out);
      DatabaseFinalize(rq);
      return out;
     }

   bool PositionExists(const string symbol,const ENUM_TIMEFRAMES tf,const string direction,
                       const int trade_no,const int pos_no)
     {
      int rq=DatabasePrepare(m_db,
         "SELECT 1 FROM ta3_positions WHERE symbol=? AND tf=? AND direction=? AND trade_no=? AND pos_no=?;");
      if(rq==INVALID_HANDLE) return false;
      DatabaseBind(rq,0,symbol);
      DatabaseBind(rq,1,TA3_TFToString(tf));
      DatabaseBind(rq,2,direction);
      DatabaseBind(rq,3,trade_no);
      DatabaseBind(rq,4,pos_no);
      bool found=DatabaseRead(rq);
      DatabaseFinalize(rq);
      return found;
     }

   int NextFreePos(const string symbol,const ENUM_TIMEFRAMES tf,const string direction,const int trade_no,const int preferred)
     {
      if(preferred>=1 && preferred<=4 && !PositionExists(symbol,tf,direction,trade_no,preferred))
         return preferred;
      for(int p=1;p<=4;p++)
         if(!PositionExists(symbol,tf,direction,trade_no,p))
            return p;
      return 0;
     }

   bool UpsertPosition(TA3_Position &p)
     {
      long now=(long)TimeCurrent();
      if(p.created_at<=0) p.created_at=now;
      p.updated_at=now;

      int rq=DatabasePrepare(m_db,
         "INSERT INTO ta3_positions("
         "symbol,tf,direction,trade_no,pos_no,entry,sl,lots,sabio_entry,sabio_sl,status,was_sent,is_pending,created_at,updated_at"
         ") VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) "
         "ON CONFLICT(symbol,tf,direction,trade_no,pos_no) DO UPDATE SET "
         "entry=excluded.entry,sl=excluded.sl,lots=excluded.lots,"
         "sabio_entry=excluded.sabio_entry,sabio_sl=excluded.sabio_sl,"
         "status=excluded.status,was_sent=excluded.was_sent,is_pending=excluded.is_pending,"
         "updated_at=excluded.updated_at;");
      if(rq==INVALID_HANDLE) return false;
      DatabaseBind(rq,0,p.symbol);
      DatabaseBind(rq,1,p.tf);
      DatabaseBind(rq,2,p.direction);
      DatabaseBind(rq,3,p.trade_no);
      DatabaseBind(rq,4,p.pos_no);
      DatabaseBind(rq,5,p.entry);
      DatabaseBind(rq,6,p.sl);
      DatabaseBind(rq,7,p.lots);
      DatabaseBind(rq,8,p.sabio_entry);
      DatabaseBind(rq,9,p.sabio_sl);
      DatabaseBind(rq,10,p.status);
      DatabaseBind(rq,11,p.was_sent);
      DatabaseBind(rq,12,p.is_pending);
      DatabaseBind(rq,13,p.created_at);
      DatabaseBind(rq,14,p.updated_at);
      bool ok=ExecNonQuery(rq);
      DatabaseFinalize(rq);
      return ok;
     }

   bool DeletePosition(const TA3_Position &p)
     {
      int rq=DatabasePrepare(m_db,
         "DELETE FROM ta3_positions WHERE symbol=? AND tf=? AND direction=? AND trade_no=? AND pos_no=?;");
      if(rq==INVALID_HANDLE) return false;
      DatabaseBind(rq,0,p.symbol);
      DatabaseBind(rq,1,p.tf);
      DatabaseBind(rq,2,p.direction);
      DatabaseBind(rq,3,p.trade_no);
      DatabaseBind(rq,4,p.pos_no);
      bool ok=ExecNonQuery(rq);
      DatabaseFinalize(rq);
      return ok;
     }

   bool UpdateStatus(const string symbol,const ENUM_TIMEFRAMES tf,const string direction,
                     const int trade_no,const int pos_no,const string status,const int pending)
     {
      int rq=DatabasePrepare(m_db,
         "UPDATE ta3_positions SET status=?,is_pending=?,updated_at=? "
         "WHERE symbol=? AND tf=? AND direction=? AND trade_no=? AND pos_no=?;");
      if(rq==INVALID_HANDLE) return false;
      DatabaseBind(rq,0,status);
      DatabaseBind(rq,1,pending);
      DatabaseBind(rq,2,(long)TimeCurrent());
      DatabaseBind(rq,3,symbol);
      DatabaseBind(rq,4,TA3_TFToString(tf));
      DatabaseBind(rq,5,direction);
      DatabaseBind(rq,6,trade_no);
      DatabaseBind(rq,7,pos_no);
      bool ok=ExecNonQuery(rq);
      DatabaseFinalize(rq);
      return ok;
     }

   int LoadPositions(const string symbol,const ENUM_TIMEFRAMES tf,TA3_Position &rows[],const bool active_only=false)
     {
      ArrayResize(rows,0);
      string sql="SELECT symbol,tf,direction,trade_no,pos_no,entry,sl,lots,sabio_entry,sabio_sl,status,was_sent,is_pending,created_at,updated_at "
                 "FROM ta3_positions WHERE symbol=? AND tf=?";
      if(active_only)
         sql += " AND status NOT LIKE 'CLOSED%'";
      sql += " ORDER BY trade_no,pos_no;";

      int rq=DatabasePrepare(m_db,sql);
      if(rq==INVALID_HANDLE) return -1;
      DatabaseBind(rq,0,symbol);
      DatabaseBind(rq,1,TA3_TFToString(tf));

      while(DatabaseRead(rq))
        {
         int n=ArraySize(rows);
         ArrayResize(rows,n+1);
         DatabaseColumnText(rq,0,rows[n].symbol);
         DatabaseColumnText(rq,1,rows[n].tf);
         DatabaseColumnText(rq,2,rows[n].direction);
         DatabaseColumnInteger(rq,3,rows[n].trade_no);
         DatabaseColumnInteger(rq,4,rows[n].pos_no);
         DatabaseColumnDouble(rq,5,rows[n].entry);
         DatabaseColumnDouble(rq,6,rows[n].sl);
         DatabaseColumnDouble(rq,7,rows[n].lots);
         DatabaseColumnText(rq,8,rows[n].sabio_entry);
         DatabaseColumnText(rq,9,rows[n].sabio_sl);
         DatabaseColumnText(rq,10,rows[n].status);
         DatabaseColumnInteger(rq,11,rows[n].was_sent);
         DatabaseColumnInteger(rq,12,rows[n].is_pending);
         DatabaseColumnInteger(rq,13,rows[n].created_at);
         DatabaseColumnInteger(rq,14,rows[n].updated_at);
        }
      DatabaseFinalize(rq);
      return ArraySize(rows);
     }

   bool GetPosition(const string symbol,const ENUM_TIMEFRAMES tf,const string direction,
                    const int trade_no,const int pos_no,TA3_Position &out)
     {
      TA3_Position rows[];
      int n=LoadPositions(symbol,tf,rows,false);
      for(int i=0;i<n;i++)
         if(rows[i].direction==direction && rows[i].trade_no==trade_no && rows[i].pos_no==pos_no)
           { out=rows[i]; return true; }
      return false;
     }
  };

#endif
