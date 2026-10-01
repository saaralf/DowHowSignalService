#ifndef TA4_CORE_MQH
#define TA4_CORE_MQH
#include "TA4_Repository.mqh"
// Shared trade rules. No chart objects, HTTP calls or broker operations.
class CTA4Core
  {
private:
   CTA4Repository *m_repo;
   TA4_Context m_ctx;
   TA4_Settings m_settings;
   string m_error;
   string DraftSnapshot(const TA4_Draft &d) const
     { return "Entry="+TA4_Price(m_ctx,d.entry)+";SL="+TA4_Price(m_ctx,d.sl)+";TP="+TA4_Price(m_ctx,d.tp)+";SabioEntry="+d.sabio_entry+";SabioSL="+d.sabio_sl+";EntryOverride="+m_repo.I(d.entry_override?1:0)+";SLOverride="+m_repo.I(d.sl_override?1:0); }
   string Where(const TA4_Position &p) const
     { return "context="+m_repo.Q(m_ctx.key)+" AND trade_no="+m_repo.I(p.trade_no)+" AND pos_no="+m_repo.I(p.pos_no); }
   string Prefix(const string kind,const TA4_Position &p) const
     { return (m_settings.mention?"@everyone\n":"")+"**"+kind+"** "+m_ctx.symbol+" "+TA4_TF(m_ctx.tf)+" "+p.direction+" | Trade "+m_repo.I(p.trade_no)+" | Pos "+m_repo.I(p.pos_no); }
   bool Abort(const string error="") { m_error=error!=""?error:m_repo.Error(); m_repo.Rollback(); return false; }
   bool Finish() { if(!m_repo.Commit()) { m_error=m_repo.Error(); return false; } return true; }
   bool CloseRow(const TA4_Position &p,const string status,const string cause,const string source,const bool notify)
     {
      bool ok=m_repo.Exec("UPDATE positions SET status="+m_repo.Q(status)+",updated_at="+m_repo.I((long)TimeGMT())+" WHERE "+Where(p)+" AND status IN ('PENDING','OPEN');");
      string msg=notify?Prefix(cause,p):"";
      return ok && m_repo.Event(m_ctx,cause,p.trade_no,p.pos_no,p.status,status,source,msg);
     }
   bool FinishTradeIfEmpty(const long tr)
     { return m_repo.Exec("UPDATE trades SET status='CLOSED',updated_at="+m_repo.I((long)TimeGMT())+" WHERE context="+m_repo.Q(m_ctx.key)+" AND trade_no="+m_repo.I(tr)+" AND NOT EXISTS(SELECT 1 FROM positions WHERE context="+m_repo.Q(m_ctx.key)+" AND trade_no="+m_repo.I(tr)+" AND status IN ('PENDING','OPEN'));"); }
public:
   void Init(CTA4Repository *repo,const TA4_Context &ctx,const TA4_Settings &settings) { m_repo=repo; m_ctx=ctx; m_settings=settings; }
   string Error() const { return m_error; }
   double Lots(const TA4_Draft &d,string &error)
     {
      error=""; double distance=MathAbs(d.entry-d.sl);
      double tick=SymbolInfoDouble(m_ctx.symbol,SYMBOL_TRADE_TICK_SIZE);
      double value=SymbolInfoDouble(m_ctx.symbol,SYMBOL_TRADE_TICK_VALUE_LOSS);
      if(value<=0) value=SymbolInfoDouble(m_ctx.symbol,SYMBOL_TRADE_TICK_VALUE);
      double step=SymbolInfoDouble(m_ctx.symbol,SYMBOL_VOLUME_STEP),minimum=SymbolInfoDouble(m_ctx.symbol,SYMBOL_VOLUME_MIN),maximum=SymbolInfoDouble(m_ctx.symbol,SYMBOL_VOLUME_MAX);
      double budget=m_settings.risk_mode==TA4_RISK_MONEY?m_settings.risk_value:AccountInfoDouble(ACCOUNT_EQUITY)*m_settings.risk_value/100.0;
      if(distance<=0 || tick<=0 || value<=0 || step<=0 || minimum<=0 || maximum<minimum || budget<=0)
        { error="Invalid prices, risk budget or symbol volume data"; return 0; }
      double raw=budget/(distance/tick*value);
      if(raw<minimum) { error="Risk budget is below the broker minimum volume"; return 0; }
      double lots=NormalizeDouble(MathFloor((MathMin(raw,maximum)+1e-12)/step)*step,8);
      if(lots<minimum || lots>maximum) { error="Calculated volume outside broker limits"; return 0; } return lots;
     }
   bool SaveDraft(const TA4_Draft &d)
     {
      m_error="";
      if(d.entry<=0 || d.sl<=0 || !MathIsValidNumber(d.entry) || !MathIsValidNumber(d.sl)) { m_error="Draft prices invalid"; return false; }
      if(!m_repo.BeginOwned(m_ctx)) return Abort();
      TA4_Draft old; bool found=false;
      if(!m_repo.LoadDraft(m_ctx.key,old,found)) return Abort();
      // No event for a redraw with unchanged data.
      if(found && old.entry==d.entry && old.sl==d.sl && old.tp==d.tp && old.sabio_entry==d.sabio_entry && old.sabio_sl==d.sabio_sl && old.entry_override==d.entry_override && old.sl_override==d.sl_override) { m_repo.Rollback(); return true; }
      string before=found?DraftSnapshot(old):"";
      if(!m_repo.WriteDraft(m_ctx.key,d) || !m_repo.Event(m_ctx,"DRAFT_SAVED",0,0,before,DraftSnapshot(d),"USER")) return Abort();
      return Finish();
     }
   bool Send(const TA4_Draft &d,const string image)
     {
      m_error="";
      if(d.entry<=0 || d.sl<=0 || d.entry==d.sl) { m_error="Entry and SL must be positive and different"; return false; }
      string dir=TA4_Direction(d);
      if(m_settings.tp_enabled && (d.tp<=0 || (dir=="LONG" && d.tp<=d.entry) || (dir=="SHORT" && d.tp>=d.entry)))
        { m_error="TP must be beyond Entry in the trade direction"; return false; }
      string lot_error=""; double lots=Lots(d,lot_error); if(lots<=0) { m_error=lot_error; return false; }
      if(!m_repo.BeginOwned(m_ctx)) return Abort();
      TA4_Position rows[]; if(!m_repo.Positions(m_ctx.key,rows)) return Abort();
      int active=0; for(int i=0;i<ArraySize(rows);i++) if(rows[i].direction==dir) active++;
      if(active>=4) return Abort("Maximum four active positions in this direction");
      long tr=0,po=0; if(!m_repo.Numbers(m_ctx.key,dir,tr,po)) return Abort();
      long now=(long)TimeGMT(); string ctx=m_repo.Q(m_ctx.key),t=m_repo.I(tr);
      if(active==0)
        {
         if(!m_repo.Exec("INSERT INTO contexts VALUES("+ctx+","+t+") ON CONFLICT(context) DO UPDATE SET last_trade_no=excluded.last_trade_no;") || !m_repo.Exec("INSERT INTO trades VALUES("+ctx+","+t+","+m_repo.Q(dir)+",'ACTIVE',0,"+m_repo.I(now)+","+m_repo.I(now)+");")) return Abort();
        }
      TA4_Position p; p.trade_no=tr; p.pos_no=po; p.direction=dir; p.status="PENDING"; p.entry=d.entry; p.sl=d.sl; p.tp=m_settings.tp_enabled?d.tp:0; p.lots=lots;
      p.sabio_entry=d.sabio_entry; p.sabio_sl=d.sabio_sl;
      string sql="INSERT INTO positions VALUES("+ctx+","+t+","+m_repo.I(po)+","+m_repo.Q(dir)+",'PENDING',"+m_repo.N(p.entry)+","+m_repo.N(p.sl)+","+m_repo.N(p.tp)+","+m_repo.N(lots)+","+m_repo.Q(d.sabio_entry)+","+m_repo.Q(d.sabio_sl)+","+m_repo.I(now)+","+m_repo.I(now)+");";
      string msg=Prefix("SIGNAL",p)+"\nEntry: "+TA4_Price(m_ctx,p.entry)+"\nSL: "+TA4_Price(m_ctx,p.sl)+"\nLots: "+DoubleToString(lots,8);
      if(p.tp>0) msg+="\nTP: "+TA4_Price(m_ctx,p.tp);
      if(m_settings.sabio_send) msg+="\nSabioEntry: "+d.sabio_entry+"\nSabioSL: "+d.sabio_sl;
      if(!m_repo.Exec(sql) || !m_repo.Exec("UPDATE trades SET last_pos_no="+m_repo.I(po)+",updated_at="+m_repo.I(now)+" WHERE context="+ctx+" AND trade_no="+t+";") || !m_repo.WriteDraft(m_ctx.key,d) || !m_repo.Event(m_ctx,"SIGNAL_CREATED",tr,po,"",DraftSnapshot(d)+";Lots="+DoubleToString(lots,8),"USER",msg,image)) return Abort();
      return Finish();
     }
   bool Adjust(const long tr,const long po,const string kind,const double price)
     {
      m_error=""; if(price<=0 || (kind!="ENTRY" && kind!="SL")) { m_error="Invalid adjustment"; return false; }
      if(!m_repo.BeginOwned(m_ctx)) return Abort(); TA4_Position rows[];
      if(!m_repo.Positions(m_ctx.key,rows)) return Abort();
      for(int i=0;i<ArraySize(rows);i++) if(rows[i].trade_no==tr && rows[i].pos_no==po)
        {
         TA4_Position p=rows[i]; if(kind=="ENTRY" && p.status!="PENDING") return Abort("OPEN Entry is locked");
         double old=kind=="ENTRY"?p.entry:p.sl;
         if(price==old) { m_repo.Rollback(); return true; }
         if((kind=="ENTRY" && ((p.direction=="LONG" && price<=p.sl) || (p.direction=="SHORT" && price>=p.sl))) || (kind=="SL" && p.status=="PENDING" && ((p.direction=="LONG" && price>=p.entry) || (p.direction=="SHORT" && price<=p.entry)))) return Abort("Pending Entry/SL would contradict the trade direction");
         string column=kind=="ENTRY"?"entry":"sl";
         string msg=Prefix("ADJUST "+kind,p)+"\n"+TA4_Price(m_ctx,old)+" -> "+TA4_Price(m_ctx,price);
         if(!m_repo.Exec("UPDATE positions SET "+column+"="+m_repo.N(price)+",updated_at="+m_repo.I((long)TimeGMT())+" WHERE "+Where(p)+";") || !m_repo.Event(m_ctx,"ADJUST_"+kind,tr,po,TA4_Price(m_ctx,old),TA4_Price(m_ctx,price),"USER",msg)) return Abort();
         return Finish();
        }
      return Abort("Active position not found");
     }
   bool ClosePosition(const long tr,const long po,const string reason,const string source)
     {
      m_error=""; if(!m_repo.BeginOwned(m_ctx)) return Abort(); TA4_Position rows[];
      if(!m_repo.Positions(m_ctx.key,rows)) return Abort();
      for(int i=0;i<ArraySize(rows);i++) if(rows[i].trade_no==tr && rows[i].pos_no==po)
        {
         TA4_Position p=rows[i]; string status=reason=="SL"?"CLOSED_SL":(reason=="TP"?"CLOSED_TP":"CLOSED_CANCEL");
         if(!CloseRow(p,status,reason+"_HIT",source,true)) return Abort();
         // Pos 1 SL terminates the whole direction trade; followers get an honest cause.
         if(reason=="SL" && po==1)
           for(int j=0;j<ArraySize(rows);j++) if(rows[j].trade_no==tr && rows[j].pos_no!=po)
             if(!CloseRow(rows[j],"CLOSED_POS1_SL","TRADE_ENDED_BY_POS1_SL",source,true)) return Abort();
         if(!FinishTradeIfEmpty(tr)) return Abort(); return Finish();
        }
      m_repo.Rollback(); return true; // idempotent repeat on an already closed position
     }
   bool CancelTrade(const long tr)
     {
      m_error=""; if(!m_repo.BeginOwned(m_ctx)) return Abort(); TA4_Position rows[];
      if(!m_repo.Positions(m_ctx.key,rows)) return Abort(); bool any=false; string ids="",dir="";
      for(int i=0;i<ArraySize(rows);i++) if(rows[i].trade_no==tr)
        {
         any=true; dir=rows[i].direction; if(ids!="") ids+=", "; ids+=m_repo.I(rows[i].pos_no);
         if(!CloseRow(rows[i],"CLOSED_CANCEL","POSITION_CANCEL","USER",false)) return Abort();
        }
      if(!any) { m_repo.Rollback(); return true; }
      string msg=(m_settings.mention?"@everyone\n":"")+"**TRADE CANCEL** "+m_ctx.symbol+" "+TA4_TF(m_ctx.tf)+" "+dir+" | Trade "+m_repo.I(tr)+" | Positions: "+ids;
      if(!FinishTradeIfEmpty(tr) || !m_repo.Event(m_ctx,"TRADE_CANCEL",tr,0,"ACTIVE","CLOSED","USER",msg)) return Abort();
      return Finish();
     }
   bool Evaluate(const MqlTick &tick)
     {
      if(tick.ask<=0 || tick.bid<=0) return true;
      TA4_Position rows[]; if(!m_repo.Positions(m_ctx.key,rows)) { m_error=m_repo.Error(); return false; }
      for(int i=0;i<ArraySize(rows);i++)
        {
         TA4_Position p=rows[i];
         // A preceding Pos-1 SL may have closed followers from this snapshot.
         long current=0; if(!m_repo.Scalar("SELECT COUNT(*) FROM positions WHERE "+Where(p)+" AND status IN ('PENDING','OPEN');",current)) { m_error=m_repo.Error(); return false; }
         if(current==0) continue;
         if(p.status=="PENDING" && (p.direction=="LONG"?tick.ask>=p.entry:tick.bid<=p.entry))
           {
            if(!m_repo.BeginOwned(m_ctx)) return Abort();
            if(!m_repo.Exec("UPDATE positions SET status='OPEN',updated_at="+m_repo.I((long)TimeGMT())+" WHERE "+Where(p)+" AND status='PENDING';") || !m_repo.Event(m_ctx,"ENTRY_HIT",p.trade_no,p.pos_no,"PENDING","OPEN","TICK")) return Abort();
            if(!Finish()) return false; p.status="OPEN";
           }
         if(p.status!="OPEN") continue;
         bool sl=p.direction=="LONG"?tick.bid<=p.sl:tick.ask>=p.sl;
         if(sl) { if(!ClosePosition(p.trade_no,p.pos_no,"SL","TICK")) return false; continue; }
         bool tp=p.tp>0 && (p.direction=="LONG"?tick.bid>=p.tp:tick.ask<=p.tp);
         if(tp && !ClosePosition(p.trade_no,p.pos_no,"TP","TICK")) return false;
        }
      return true;
     }
  };
#endif
