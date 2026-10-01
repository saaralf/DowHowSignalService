#ifndef DH126_SQLITE_STORE
#define DH126_SQLITE_STORE
#include "SQLiteSchema.mqh"
#include "TradeInfo.mqh"
// Stage 1: legacy two direction slots, durable history and shared numbering.
class CDH126Store
  {
private:
   int m_db;
   string m_ctx,m_owner;
   bool m_tx,m_acquired;
   bool Execute(string sql) { return m_db!=INVALID_HANDLE && DatabaseExecute(m_db,sql); }
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
      if(DatabaseTableExists(m_db,"schema_version"))
        { long version=0; if(!Scalar("SELECT MAX(version) FROM schema_version;",version) || version!=1) { Close(); return false; } }
      if(!Execute("BEGIN IMMEDIATE;")) { Close(); return false; } m_tx=true;
      string stmts[]; int count=StringSplit(DH126Schema(),'\n',stmts);
      for(int i=0;i<count;i++) if(stmts[i]!="" && !Execute(stmts[i])) { Close(); return false; }
      if(!Execute("INSERT OR IGNORE INTO contexts VALUES("+Q(m_ctx)+","+I(initial_last)+");") || !Commit() || !Renew()) { Close(); return false; }
      if(!Event("EA_STARTED",0,0,"","V1.04.27 SQLite stage 1")) { Close(); return false; }
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
   bool Next(int &tn)
     {
      long n=0; if(!Scalar("SELECT last_trade_no FROM contexts WHERE context="+Q(m_ctx)+";",n) || n>=2147483647) return false;
      tn=(int)n+1; return true;
     }
   bool Create(TradeInfo &p)
     {
      if(!Begin()) return false;
      long last=0;
      if(!Scalar("SELECT last_trade_no FROM contexts WHERE context="+Q(m_ctx)+";",last) || last>=2147483647) { Abort(); return false; }
      p.tradenummer=(int)last+1; p.position=1;
      string values=Q(m_ctx)+","+I(p.tradenummer)+",1,"+Q(p.type)+",'PENDING',"+N(p.price)+","+N(p.sl)+","+N(p.lots)+","+Q(p.sabioentry)+","+Q(p.sabiosl);
      if(!Execute("UPDATE contexts SET last_trade_no="+I(p.tradenummer)+" WHERE context="+Q(m_ctx)+";") || !Execute("INSERT INTO positions VALUES("+values+");") || !WriteEvent("SIGNAL_CREATED",p.tradenummer,1,"",values)) { Abort(); return false; }
      return Commit();
     }
   bool Change(TradeInfo &p,string state,string kind,string old_value,string new_value)
     {
      if(!Begin()) return false;
      string where="context="+Q(m_ctx)+" AND trade_no="+I(p.tradenummer)+" AND pos_no="+I(p.position)+" AND status IN ('PENDING','OPEN')";
      long count=0;
      if(!Scalar("SELECT COUNT(*) FROM positions WHERE "+where+";",count) || count!=1 || !Execute("UPDATE positions SET status="+Q(state)+",sl="+N(p.sl)+" WHERE "+where+";") || !WriteEvent(kind,p.tradenummer,p.position,old_value,new_value)) { Abort(); return false; }
      return Commit();
     }
   bool Restore(TradeInfo &slots[],bool &buy_active,bool &sell_active,bool &buy_hit,bool &sell_hit)
     {
      buy_active=false; sell_active=false; buy_hit=false; sell_hit=false;
      int r=DatabasePrepare(m_db,"SELECT trade_no,pos_no,direction,status,entry,sl,lots,sabio_entry,sabio_sl FROM positions WHERE context="+Q(m_ctx)+" AND status IN ('PENDING','OPEN');");
      if(r==INVALID_HANDLE) return false;
      bool ok=true; int err=0;
      while(true)
        {
         ResetLastError(); if(!DatabaseRead(r)) { err=GetLastError(); break; }
         TradeInfo p; string state;
         ok=DatabaseColumnInteger(r,0,p.tradenummer) && DatabaseColumnInteger(r,1,p.position) && DatabaseColumnText(r,2,p.type) && DatabaseColumnText(r,3,state) && DatabaseColumnDouble(r,4,p.price) && DatabaseColumnDouble(r,5,p.sl) && DatabaseColumnDouble(r,6,p.lots) && DatabaseColumnText(r,7,p.sabioentry) && DatabaseColumnText(r,8,p.sabiosl);
         if(!ok) break;
         p.symbol=_Symbol; p.was_send=false; p.is_trade_pending=state=="PENDING";
         int idx=p.type=="BUY"?0:1; slots[idx]=p;
         if(idx==0) { buy_active=true; buy_hit=state=="OPEN"; } else { sell_active=true; sell_hit=state=="OPEN"; }
        }
      DatabaseFinalize(r); return ok && err==ERR_DATABASE_NO_MORE_DATA;
     }
  };
#endif
