#ifndef DH126_SQLITE_STORE
#define DH126_SQLITE_STORE
#include "SQLiteSchema.mqh"
#include "TradeInfo.mqh"
// Multiple durable positions, editable identity and a shared trade counter.
class CDH126Store
  {
private:
   int m_db;
   string m_ctx,m_owner,m_error;
   bool m_tx,m_acquired;
   bool Execute(string sql)
     { if(m_db!=INVALID_HANDLE && DatabaseExecute(m_db,sql)) return true; m_error="SQLite error "+IntegerToString(GetLastError()); return false; }
   bool Statements(string sql)
     { string lines[]; int n=StringSplit(sql,'\n',lines); for(int i=0;i<n;i++) if(lines[i]!="" && !Execute(lines[i])) return false; return true; }
   string Where(TradeInfo &p) { return "context="+Q(m_ctx)+" AND trade_no="+I(p.tradenummer)+" AND pos_no="+I(p.position); }
   bool Reject(string error) { Abort(); m_error=error; return false; }
   bool CloseTradeIfEmpty(int tn)
     { return Execute("UPDATE trades SET status='CLOSED' WHERE context="+Q(m_ctx)+" AND trade_no="+I(tn)+" AND NOT EXISTS(SELECT 1 FROM positions WHERE context="+Q(m_ctx)+" AND trade_no="+I(tn)+" AND status IN ('PENDING','OPEN'));"); }
   bool Scalar(string sql,long &v)
     {
      int r=DatabasePrepare(m_db,sql); if(r==INVALID_HANDLE) return false;
      bool ok=DatabaseRead(r) && DatabaseColumnLong(r,0,v); DatabaseFinalize(r); return ok;
     }
   bool Begin()
     {
      if(m_tx || !Execute("BEGIN IMMEDIATE;")) return false; m_tx=true;
      long owned=0;
      if(!Scalar("SELECT COUNT(*) FROM leases WHERE context="+Q(m_ctx)+" AND owner="+Q(m_owner)+" AND expires>"+I((long)TimeGMT())+";",owned) || owned!=1) { Abort(); return false; }
      return true;
     }
   bool Commit() { bool ok=Execute("COMMIT;"); if(!ok) Abort(); m_tx=false; return ok; }
   void Abort() { if(m_tx) Execute("ROLLBACK;"); m_tx=false; }
   bool WriteEvent(string kind,int tn,int pn,string old_value,string new_value)
     { return Execute("INSERT INTO events(context,trade_no,pos_no,kind,old_value,new_value,created_at) VALUES("+Q(m_ctx)+","+I(tn)+","+I(pn)+","+Q(kind)+","+Q(old_value)+","+Q(new_value)+","+I((long)TimeGMT())+");"); }
public:
   CDH126Store():m_db(INVALID_HANDLE),m_tx(false),m_acquired(false) {}
   string Error() { return m_error; }
   string Q(string s) { StringReplace(s,"'","''"); return "'"+s+"'"; }
   string I(long n) { return IntegerToString(n); }
   string N(double n) { return DoubleToString(n,12); }
   bool Open(string file,int magic,int initial_last)
     {
      if(initial_last<0) return false;
      // Length-prefixed variable parts avoid ambiguous context keys.
      string server=AccountInfoString(ACCOUNT_SERVER);
      m_ctx=I(StringLen(server))+":"+server+"|"+I(AccountInfoInteger(ACCOUNT_LOGIN))+"|"+I(magic)+"|"+I(StringLen(_Symbol))+":"+_Symbol+"|"+I((long)_Period);
      m_owner=I(ChartID())+"-"+I((long)GetMicrosecondCount());
      m_db=DatabaseOpen(file,DATABASE_OPEN_READWRITE|DATABASE_OPEN_CREATE|DATABASE_OPEN_COMMON);
      if(m_db==INVALID_HANDLE) return false;
      if(!Execute("PRAGMA foreign_keys=ON;") || !Execute("PRAGMA journal_mode=WAL;") || !Execute("PRAGMA synchronous=FULL;") || !Execute("PRAGMA busy_timeout=1000;")) { Close(); return false; }
      long version=0;
      if(!Execute("BEGIN IMMEDIATE;")) { Close(); return false; } m_tx=true;
      if(DatabaseTableExists(m_db,"schema_version") && !Scalar("SELECT MAX(version) FROM schema_version;",version)) { Close(); return false; }
      if(version!=0 && version!=1 && version!=2) { m_error="Unsupported SQLite schema"; Close(); return false; }
      if(version==1)
        {
         long running=0;
         if(!Scalar("SELECT COUNT(*) FROM leases WHERE expires>"+I((long)TimeGMT())+";",running) || running>0) { m_error="Stop old EA instances before migration (lease 30 seconds)"; Close(); return false; }
         if(!Statements(DH126MigrateBegin())) { Close(); return false; }
        }
      if(!Statements(DH126Schema())) { Close(); return false; }
      if(version==1 && !Statements(DH126MigrateFinish())) { Close(); return false; }
      if(!Execute("INSERT OR IGNORE INTO contexts VALUES("+Q(m_ctx)+","+I(initial_last)+");") || !Commit() || !Renew()) { Close(); return false; }
      if(!Event("EA_STARTED",0,0,"","V1.04.28 editable numbers and multiple positions")) { Close(); return false; }
      return true;
     }
   bool Renew()
     {
      if(m_tx || !Execute("BEGIN IMMEDIATE;")) return false; m_tx=true;
      long now=(long)TimeGMT(),owned=0;
      string sql=m_acquired?
         "UPDATE leases SET expires="+I(now+30)+" WHERE context="+Q(m_ctx)+" AND owner="+Q(m_owner)+" AND expires>"+I(now)+";":
         "INSERT INTO leases VALUES("+Q(m_ctx)+","+Q(m_owner)+","+I(now+30)+") ON CONFLICT(context) DO UPDATE SET owner=excluded.owner,expires=excluded.expires WHERE leases.owner=excluded.owner OR leases.expires<="+I(now)+";";
      bool ok=Execute(sql) && Scalar("SELECT COUNT(*) FROM leases WHERE context="+Q(m_ctx)+" AND owner="+Q(m_owner)+" AND expires>"+I(now)+";",owned) && owned==1;
      if(!ok) { Abort(); return false; }
      if(!Commit()) return false; m_acquired=true; return true;
     }
   void Close()
     {
      Abort(); if(m_db!=INVALID_HANDLE) { Execute("DELETE FROM leases WHERE context="+Q(m_ctx)+" AND owner="+Q(m_owner)+";"); DatabaseClose(m_db); } m_db=INVALID_HANDLE; m_acquired=false;
     }
   bool Event(string kind,int tn,int pn,string old_value,string new_value)
     { if(!Begin()) return false; if(!WriteEvent(kind,tn,pn,old_value,new_value)) { Abort(); return false; } return Commit(); }
   bool Next(string direction,int &tn,int &pn)
     {
      long active=0,last=0;
      if(!Scalar("SELECT COALESCE(MAX(trade_no),0) FROM trades WHERE context="+Q(m_ctx)+" AND direction="+Q(direction)+" AND status='ACTIVE';",active)) return false;
      if(active>0)
        {
         if(!Scalar("SELECT COALESCE(MAX(pos_no),0) FROM positions WHERE context="+Q(m_ctx)+" AND trade_no="+I(active)+";",last) || last>=2147483647) return false;
         tn=(int)active; pn=(int)last+1; return true;
        }
      if(!Scalar("SELECT last_trade_no FROM contexts WHERE context="+Q(m_ctx)+";",last) || last>=2147483647) return false;
      tn=(int)last+1; pn=1; return true;
     }
   bool Create(TradeInfo &p)
     {
      m_error="";
      if(p.tradenummer<=0 || p.position<=0 || (p.type!="BUY" && p.type!="SELL")) { m_error="Trade and position must be positive integers"; return false; }
      if(!Begin()) return false;
      long active=0,used=0,last_pos=0,total=0;
      int proposed_tn=0,proposed_pn=0;
      if(!Next(p.type,proposed_tn,proposed_pn) || !Scalar("SELECT COALESCE(MAX(trade_no),0) FROM trades WHERE context="+Q(m_ctx)+" AND direction="+Q(p.type)+" AND status='ACTIVE';",active)) return Reject("Cannot read trade numbering");
      if(active>0 && active!=p.tradenummer) return Reject("This direction has an active trade: "+I(active)+". Finish it before changing trade number.");
      if(active==0)
        {
         if(!Scalar("SELECT COUNT(*) FROM trades WHERE context="+Q(m_ctx)+" AND trade_no="+I(p.tradenummer)+";",used)) return Reject("Cannot read trade history");
         if(used>0) return Reject("Trade number already used by another direction or a closed trade");
         if(!Execute("INSERT INTO trades VALUES("+Q(m_ctx)+","+I(p.tradenummer)+","+Q(p.type)+",'ACTIVE');")) { Abort(); return false; }
        }
      if(!Scalar("SELECT COALESCE(MAX(pos_no),0) FROM positions WHERE context="+Q(m_ctx)+" AND trade_no="+I(p.tradenummer)+";",last_pos) || !Scalar("SELECT COUNT(*) FROM positions WHERE context="+Q(m_ctx)+" AND direction="+Q(p.type)+" AND status IN ('PENDING','OPEN');",total)) return Reject("Cannot read positions");
      if(p.position<=last_pos) return Reject("Position number must exceed all previous positions of this trade: "+I(last_pos));
      if(total>=4) return Reject("Maximum four active positions per direction");
      string values=Q(m_ctx)+","+I(p.tradenummer)+","+I(p.position)+","+Q(p.type)+",'PENDING',"+N(p.price)+","+N(p.sl)+","+N(p.lots)+","+Q(p.sabioentry)+","+Q(p.sabiosl);
      if(!Execute("UPDATE contexts SET last_trade_no=MAX(last_trade_no,"+I(p.tradenummer)+") WHERE context="+Q(m_ctx)+";") || !Execute("INSERT INTO positions VALUES("+values+");") || !WriteEvent("SIGNAL_CREATED",p.tradenummer,p.position,"",values)) { Abort(); return false; }
      if((p.tradenummer!=proposed_tn || p.position!=proposed_pn) && !WriteEvent("NUMBERS_CORRECTED",p.tradenummer,p.position,I(proposed_tn)+"."+I(proposed_pn),I(p.tradenummer)+"."+I(p.position))) { Abort(); return false; }
      return Commit();
     }
   bool Change(TradeInfo &p,string state,string kind,string old_value,string new_value)
     {
      if(!Begin()) return false;
      long count=0;
      string where=Where(p)+" AND status IN ('PENDING','OPEN')";
      if(!Scalar("SELECT COUNT(*) FROM positions WHERE "+where+";",count) || count!=1 || !Execute("UPDATE positions SET status="+Q(state)+",sl="+N(p.sl)+" WHERE "+where+";") || !WriteEvent(kind,p.tradenummer,p.position,old_value,new_value)) { Abort(); return false; }
      if(state=="CLOSED_SL" && p.position==1)
        {
         string scope="context="+Q(m_ctx)+" AND trade_no="+I(p.tradenummer)+" AND status IN ('PENDING','OPEN')";
         if(!Execute("INSERT INTO events(context,trade_no,pos_no,kind,old_value,new_value,created_at) SELECT context,trade_no,pos_no,'TRADE_ENDED_BY_POS1_SL',status,'CLOSED_POS1_SL',"+I((long)TimeGMT())+" FROM positions WHERE "+scope+";") || !Execute("UPDATE positions SET status='CLOSED_POS1_SL' WHERE "+scope+";")) { Abort(); return false; }
        }
      if(!CloseTradeIfEmpty(p.tradenummer)) { Abort(); return false; }
      return Commit();
     }
   bool CancelTrade(int tn)
     {
      if(!Begin()) return false;
      string scope="context="+Q(m_ctx)+" AND trade_no="+I(tn)+" AND status IN ('PENDING','OPEN')";
      long count=0;
      if(!Scalar("SELECT COUNT(*) FROM positions WHERE "+scope+";",count) || count==0) return Reject("No active positions in this trade");
      if(!Execute("INSERT INTO events(context,trade_no,pos_no,kind,old_value,new_value,created_at) SELECT context,trade_no,pos_no,'CANCEL',status,'CLOSED_CANCEL',"+I((long)TimeGMT())+" FROM positions WHERE "+scope+";") || !Execute("UPDATE positions SET status='CLOSED_CANCEL' WHERE "+scope+";") || !CloseTradeIfEmpty(tn)) { Abort(); return false; }
      return Commit();
     }
   bool Restore(TradeInfo &rows[])
     {
      ArrayResize(rows,0);
      int r=DatabasePrepare(m_db,"SELECT trade_no,pos_no,direction,status,entry,sl,lots,sabio_entry,sabio_sl FROM positions WHERE context="+Q(m_ctx)+" AND status IN ('PENDING','OPEN') ORDER BY trade_no,pos_no;");
      if(r==INVALID_HANDLE) return false;
      bool ok=true; int err=0;
      while(true)
        {
         ResetLastError(); if(!DatabaseRead(r)) { err=GetLastError(); break; }
         TradeInfo p; string state;
         ok=DatabaseColumnInteger(r,0,p.tradenummer) && DatabaseColumnInteger(r,1,p.position) && DatabaseColumnText(r,2,p.type) && DatabaseColumnText(r,3,state) && DatabaseColumnDouble(r,4,p.price) && DatabaseColumnDouble(r,5,p.sl) && DatabaseColumnDouble(r,6,p.lots) && DatabaseColumnText(r,7,p.sabioentry) && DatabaseColumnText(r,8,p.sabiosl);
         if(!ok) break;
         p.symbol=_Symbol; p.was_send=false; p.is_trade_pending=state=="PENDING";
         int n=ArraySize(rows); ArrayResize(rows,n+1); rows[n]=p;
        }
      DatabaseFinalize(r); return ok && err==ERR_DATABASE_NO_MORE_DATA;
     }
  };
#endif
