#ifndef TA4_REPOSITORY_MQH
#define TA4_REPOSITORY_MQH
#include "TA4_Types.mqh"
#include "TA4_Schema.mqh"
// Area 4. The only module allowed to use the Database API.
class CTA4Repository
  {
private:
   int m_db;
   string m_error;
   bool m_tx;
public:
   CTA4Repository():m_db(INVALID_HANDLE),m_tx(false) {}
   string Error() const { return m_error; }
   string Q(string s) const { StringReplace(s,"'","''"); return "'"+s+"'"; }
   string N(double n) const { return DoubleToString(n,10); }
   string I(long n) const { return IntegerToString(n); }
   bool Exec(const string sql)
     {
      ResetLastError();
      if(m_db==INVALID_HANDLE || !DatabaseExecute(m_db,sql))
        { m_error="SQLite operation failed: "+IntegerToString(GetLastError()); Print("V4: ",m_error); return false; }
      return true;
     }
   int Query(const string sql)
     {
      ResetLastError(); int r=DatabasePrepare(m_db,sql);
      if(r==INVALID_HANDLE) m_error="SQLite query failed: "+IntegerToString(GetLastError());
      return r;
     }
   bool Scalar(const string sql,long &value)
     {
      value=0; int r=Query(sql); if(r==INVALID_HANDLE) return false;
      bool ok=DatabaseRead(r); if(ok) ok=DatabaseColumnLong(r,0,value);
      DatabaseFinalize(r); if(!ok) m_error="SQLite scalar read failed"; return ok;
     }
   bool Begin()
     { if(m_tx) { m_error="Nested transaction rejected"; return false; } if(!Exec("BEGIN IMMEDIATE;")) return false; m_tx=true; return true; }
   bool Commit()
     { if(!m_tx) return false; if(!Exec("COMMIT;")) { Rollback(); return false; } m_tx=false; return true; }
   void Rollback() { if(m_tx) { Exec("ROLLBACK;"); m_tx=false; } }
   bool Open(const string file)
     {
      m_db=DatabaseOpen(file,DATABASE_OPEN_READWRITE|DATABASE_OPEN_CREATE|DATABASE_OPEN_COMMON);
      if(m_db==INVALID_HANDLE) { m_error="Cannot open V4 database"; return false; }
      if(!Exec("PRAGMA foreign_keys=ON;") || !Exec("PRAGMA journal_mode=WAL;") || !Exec("PRAGMA synchronous=FULL;") || !Exec("PRAGMA busy_timeout=1000;")) { Close(); return false; }
      // Reject future schema versions before changing any schema.
      if(DatabaseTableExists(m_db,"schema_version"))
        { long v=0; if(!Scalar("SELECT COALESCE(MAX(version),0) FROM schema_version;",v) || v!=1) { m_error="Unsupported V4 schema version"; Close(); return false; } }
      if(!Begin()) { Close(); return false; }
      string statements[];
      int count=StringSplit(TA4_SchemaSQL(),'\n',statements);
      for(int i=0;i<count;i++) if(statements[i]!="" && !Exec(statements[i])) { Rollback(); Close(); return false; }
      if(!Commit()) { Close(); return false; } return true;
     }
   void Close() { Rollback(); if(m_db!=INVALID_HANDLE) DatabaseClose(m_db); m_db=INVALID_HANDLE; }
   bool Acquire(const TA4_Context &c)
     {
      if(!Begin()) return false;
      long now=(long)TimeGMT();
      bool ok=Exec("INSERT INTO leases(context,owner,expires) VALUES("+Q(c.key)+","+Q(c.owner)+","+I(now+30)+") ON CONFLICT(context) DO UPDATE SET owner=excluded.owner,expires=excluded.expires WHERE leases.expires<="+I(now)+" OR leases.owner=excluded.owner;");
      long owned=0;
      ok=ok && Scalar("SELECT COUNT(*) FROM leases WHERE context="+Q(c.key)+" AND owner="+Q(c.owner)+";",owned) && owned==1;
      if(!ok) { Rollback(); m_error="Context is already owned by another V4 chart, or database unavailable"; return false; }
      return Commit();
     }
   void Release(const TA4_Context &c) { Exec("DELETE FROM leases WHERE context="+Q(c.key)+" AND owner="+Q(c.owner)+";"); }
   bool BeginOwned(const TA4_Context &c)
     {
      if(!Begin()) return false; long n=0;
      if(!Scalar("SELECT COUNT(*) FROM leases WHERE context="+Q(c.key)+" AND owner="+Q(c.owner)+" AND expires>"+I((long)TimeGMT())+";",n) || n!=1)
        { Rollback(); m_error="Context ownership lost; writes blocked"; return false; }
      return true;
     }
   bool LoadDraft(const string ctx,TA4_Draft &d,bool &found)
     {
      found=false; int r=Query("SELECT entry,sl,tp,sabio_entry,sabio_sl,entry_override,sl_override FROM drafts WHERE context="+Q(ctx)+";");
      if(r==INVALID_HANDLE) return false;
      ResetLastError(); bool row=DatabaseRead(r); int err=GetLastError();
      if(row)
        {
         int a=0,b=0; bool ok=DatabaseColumnDouble(r,0,d.entry) && DatabaseColumnDouble(r,1,d.sl) && DatabaseColumnDouble(r,2,d.tp) && DatabaseColumnText(r,3,d.sabio_entry) && DatabaseColumnText(r,4,d.sabio_sl) && DatabaseColumnInteger(r,5,a) && DatabaseColumnInteger(r,6,b);
         d.entry_override=a!=0; d.sl_override=b!=0; found=ok; DatabaseFinalize(r); return ok;
        }
      DatabaseFinalize(r); return err==ERR_DATABASE_NO_MORE_DATA;
     }
   bool WriteDraft(const string ctx,const TA4_Draft &d)
     {
      return Exec("INSERT INTO drafts VALUES("+Q(ctx)+","+N(d.entry)+","+N(d.sl)+","+N(d.tp)+","+Q(d.sabio_entry)+","+Q(d.sabio_sl)+","+I(d.entry_override?1:0)+","+I(d.sl_override?1:0)+","+I((long)TimeGMT())+") ON CONFLICT(context) DO UPDATE SET entry=excluded.entry,sl=excluded.sl,tp=excluded.tp,sabio_entry=excluded.sabio_entry,sabio_sl=excluded.sabio_sl,entry_override=excluded.entry_override,sl_override=excluded.sl_override,updated_at=excluded.updated_at;");
     }
   bool Positions(const string ctx,TA4_Position &rows[])
     {
      ArrayResize(rows,0);
      int r=Query("SELECT trade_no,pos_no,direction,status,entry,sl,tp,lots,sabio_entry,sabio_sl FROM positions WHERE context="+Q(ctx)+" AND status IN ('PENDING','OPEN') ORDER BY trade_no,pos_no;");
      if(r==INVALID_HANDLE) return false;
      int err=0; bool ok=true;
      while(true)
        {
         ResetLastError(); if(!DatabaseRead(r)) { err=GetLastError(); break; }
         int n=ArraySize(rows); ArrayResize(rows,n+1);
         ok=DatabaseColumnLong(r,0,rows[n].trade_no) && DatabaseColumnLong(r,1,rows[n].pos_no) && DatabaseColumnText(r,2,rows[n].direction) && DatabaseColumnText(r,3,rows[n].status) && DatabaseColumnDouble(r,4,rows[n].entry) && DatabaseColumnDouble(r,5,rows[n].sl) && DatabaseColumnDouble(r,6,rows[n].tp) && DatabaseColumnDouble(r,7,rows[n].lots) && DatabaseColumnText(r,8,rows[n].sabio_entry) && DatabaseColumnText(r,9,rows[n].sabio_sl);
         if(!ok) break;
        }
      DatabaseFinalize(r); return ok && err==ERR_DATABASE_NO_MORE_DATA;
     }
   bool Numbers(const string ctx,const string dir,long &trade_no,long &pos_no)
     {
      trade_no=0; pos_no=1;
      if(!Scalar("SELECT COALESCE(MAX(trade_no),0) FROM trades WHERE context="+Q(ctx)+" AND direction="+Q(dir)+" AND status='ACTIVE';",trade_no)) return false;
      if(trade_no>0) { long last=0; if(!Scalar("SELECT last_pos_no FROM trades WHERE context="+Q(ctx)+" AND trade_no="+I(trade_no)+";",last)) return false; pos_no=last+1; }
      else { long last=0; if(!Scalar("SELECT COALESCE(MAX(last_trade_no),0) FROM contexts WHERE context="+Q(ctx)+";",last)) return false; trade_no=last+1; }
      return true;
     }
   bool Event(const TA4_Context &c,const string kind,const long tr,const long po,const string old_value,const string new_value,const string source,const string message="",const string image="")
     {
      // Must be called inside the state transaction. The ID survives retries unchanged.
      static long sequence=0;sequence++;
      string id=c.owner+"-"+IntegerToString((long)GetMicrosecondCount())+"-"+IntegerToString(sequence);
      bool ok=Exec("INSERT INTO events VALUES("+Q(id)+","+Q(c.key)+","+Q(kind)+","+I(tr)+","+I(po)+","+Q(old_value)+","+Q(new_value)+","+Q(source)+","+I((long)TimeGMT())+");");
      if(ok && message!="") ok=Exec("INSERT INTO outbox(event_id,context,message,image,state,updated_at) VALUES("+Q(id)+","+Q(c.key)+","+Q(message+"\nEvent: "+id)+","+Q(image)+",'QUEUED',"+I((long)TimeGMT())+");");
      return ok;
     }
   bool Recover(const TA4_Context &c)
     {
      if(!BeginOwned(c)) return false;
      if(!Exec("UPDATE outbox SET state='UNKNOWN',last_error='Interrupted request; delivery uncertain',updated_at="+I((long)TimeGMT())+" WHERE context="+Q(c.key)+" AND state='SENDING';") || !Event(c,"EA_STARTED",0,0,"","","START")) { Rollback(); return false; }
      return Commit();
     }
   bool NextOutbox(const string ctx,TA4_Outbox &o,bool &found)
     {
      found=false;
      // Strict order: FAILED/UNKNOWN blocks later events until the user resolves it.
      int r=Query("SELECT id,event_id,state,message,image,attempts,next_attempt FROM outbox WHERE context="+Q(ctx)+" AND state!='SENT' ORDER BY id LIMIT 1;");
      if(r==INVALID_HANDLE) return false;
      ResetLastError(); bool row=DatabaseRead(r); int err=GetLastError();
      if(row)
        {
         long next=0; bool ok=DatabaseColumnLong(r,0,o.id) && DatabaseColumnText(r,1,o.event_id) && DatabaseColumnText(r,2,o.state) && DatabaseColumnText(r,3,o.message) && DatabaseColumnText(r,4,o.image) && DatabaseColumnInteger(r,5,o.attempts) && DatabaseColumnLong(r,6,next);
         // A not-yet-due QUEUED item is still returned, but not claimed.
         if(ok && o.state=="QUEUED" && next>(long)TimeGMT()) o.state="WAITING";
         found=ok; DatabaseFinalize(r); return ok;
        }
      DatabaseFinalize(r); return err==ERR_DATABASE_NO_MORE_DATA;
     }
   bool OutboxState(const TA4_Context &c,const long id,const string state,const string error,const bool attempt=false,const int delay=0)
     {
      if(!BeginOwned(c)) return false;
      bool ok=Exec("UPDATE outbox SET state="+Q(state)+",attempts=attempts+"+I(attempt?1:0)+",next_attempt="+I((long)TimeGMT()+delay)+",last_error="+Q(error)+",updated_at="+I((long)TimeGMT())+" WHERE id="+I(id)+" AND context="+Q(c.key)+";");
      if(ok) ok=Event(c,"DELIVERY_"+state,0,0,"",I(id),"DISCORD");
      if(!ok) { Rollback(); return false; } return Commit();
     }
   bool ResolveOutbox(const TA4_Context &c,const TA4_Outbox &o,const bool retry)
     {
      if(o.state!="FAILED" && o.state!="UNKNOWN") { m_error="No unresolved delivery selected"; return false; }
      if(!BeginOwned(c)) return false;
      bool ok=Exec("UPDATE outbox SET state="+Q(retry?"QUEUED":"SENT")+",next_attempt=0,last_error='Manual resolution',updated_at="+I((long)TimeGMT())+" WHERE id="+I(o.id)+" AND context="+Q(c.key)+" AND state IN ('FAILED','UNKNOWN');");
      if(ok) ok=Event(c,retry?"DELIVERY_RETRY_REQUESTED":"DELIVERY_CONFIRMED_MANUALLY",0,0,o.state,I(o.id),"USER");
      if(!ok) { Rollback(); return false; } return Commit();
     }
  };
#endif
