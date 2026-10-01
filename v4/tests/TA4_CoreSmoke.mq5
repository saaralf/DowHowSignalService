#property strict
#property script_show_inputs
#include "../TA4_Core.mqh"
// Manual MT5 integration test. Uses a NEW disposable DB, no HTTP or broker calls.
int failures=0;
void Check(const bool ok,const string name)
  { Print((ok?"PASS ":"FAIL ")+name);if(!ok)failures++; }
void OnStart()
  {
   string dbfile="TA4_Smoke_"+IntegerToString((long)TimeGMT())+"_"+IntegerToString((long)GetMicrosecondCount())+".sqlite";
   CTA4Repository repo;TA4_Context c;
   c.key="SMOKE|"+_Symbol+"|"+TA4_TF((ENUM_TIMEFRAMES)_Period);c.symbol=_Symbol;c.tf=(ENUM_TIMEFRAMES)_Period;c.digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);c.chart=ChartID();c.owner="SMOKE_"+IntegerToString((long)GetMicrosecondCount());
   if(!repo.Open(dbfile) || !repo.Acquire(c)) { Check(false,repo.Error());repo.Close();return; }
   TA4_Settings settings;settings.risk_mode=TA4_RISK_MONEY;settings.risk_value=100000;settings.sabio_visible=true;settings.sabio_send=true;settings.tp_enabled=false;settings.mention=false;
   CTA4Core core;core.Init(&repo,c,settings);
   MqlTick tick;if(!SymbolInfoTick(_Symbol,tick) || tick.ask<=0){Check(false,"Market data unavailable");repo.Release(c);repo.Close();return;}
   double dist=MathMax(100*SymbolInfoDouble(_Symbol,SYMBOL_POINT),10*SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE));
   TA4_Draft d;d.entry=TA4_Normalize(_Symbol,tick.ask+2*dist);d.sl=TA4_Normalize(_Symbol,d.entry-dist);d.tp=0;d.sabio_entry="123.45";d.sabio_sl="120.00";d.entry_override=true;d.sl_override=true;
   Check(core.SaveDraft(d),"Save draft");TA4_Draft restored;bool found=false;
   Check(repo.LoadDraft(c.key,restored,found) && found && restored.entry==d.entry && restored.sabio_entry==d.sabio_entry && restored.entry_override,"Restore prices and manual Sabio");
   for(int i=1;i<=4;i++)Check(core.Send(d,""),"Send P"+IntegerToString(i));
   Check(!core.Send(d,""),"Reject fifth simultaneously active position");
   Check(core.ClosePosition(1,3,"SL","TEST"),"Close P3 without ending trade");
   Check(core.Send(d,""),"Allocate P5");
   long n=0;Check(repo.Scalar("SELECT COUNT(*) FROM positions WHERE context="+repo.Q(c.key)+" AND pos_no=3 AND status='CLOSED_SL';",n) && n==1,"Preserve P3 history");
   Check(repo.Scalar("SELECT COUNT(*) FROM positions WHERE context="+repo.Q(c.key)+" AND pos_no=5 AND status='PENDING';",n) && n==1,"P5 persisted");
   MqlTick reached=tick;reached.ask=d.entry;reached.bid=d.entry-dist/10;
   Check(core.Evaluate(reached),"Entry evaluation");
   Check(!core.Adjust(1,1,"ENTRY",d.entry+dist),"OPEN Entry locked");
   Check(core.ClosePosition(1,1,"SL","TEST"),"Pos 1 ends remaining positions");
   Check(repo.Scalar("SELECT COUNT(*) FROM positions WHERE context="+repo.Q(c.key)+" AND status IN ('PENDING','OPEN');",n) && n==0,"No active followers");
   Check(core.Send(d,""),"New LONG trade");TA4_Draft short_d=d;short_d.sl=TA4_Normalize(_Symbol,short_d.entry+dist);
   Check(core.Send(short_d,""),"Concurrent SHORT trade");long tr=0,po=0;
   Check(repo.Numbers(c.key,"LONG",tr,po) && tr==2 && po==2,"Shared numbering LONG T2");
   Check(repo.Numbers(c.key,"SHORT",tr,po) && tr==3 && po==2,"Shared numbering SHORT T3");
   Check(core.CancelTrade(2),"Cancel LONG trade");
   Check(repo.Scalar("SELECT COUNT(*) FROM positions WHERE context="+repo.Q(c.key)+" AND trade_no=3 AND status IN ('PENDING','OPEN');",n) && n==1,"SHORT unaffected");
   TA4_Outbox o;bool pending=false;Check(repo.NextOutbox(c.key,o,pending) && pending,"Durable outbox");
   Check(repo.OutboxState(c,o.id,"SENDING","",true) && repo.Recover(c),"Recover interrupted request");
   Check(repo.NextOutbox(c.key,o,pending) && pending && o.state=="UNKNOWN","UNKNOWN blocks automatic retry");
   Check(repo.ResolveOutbox(c,o,false),"Manual delivery confirmation");
   repo.Release(c);repo.Close();
   Check(repo.Open(dbfile) && repo.Acquire(c),"Reopen persistent database");
   Check(repo.LoadDraft(c.key,restored,found) && found && restored.entry==d.entry,"Draft survives database reopen");
   repo.Release(c);repo.Close();
   Print("V4 smoke failures: ",failures," | retained disposable DB: ",dbfile);
  }
