#property script_show_inputs
#include "../SQLiteStore.mqh"
void Require(bool ok,string label,int &failures)
  {
   if(!ok) { failures++; Print("FAIL: ",label," error=",GetLastError()); }
   else Print("PASS: ",label);
  }
void OnStart()
  {
   int failures=0;
   string file="DH126_SMOKE_"+IntegerToString((long)GetMicrosecondCount())+".sqlite";
   CDH126Store db,second;
   if(!db.Open(file,987654,0)) { Print("FAIL opening smoke DB: ",db.Error()); return; }
   Require(!second.Open(file,987654,0),"second owner blocked",failures); second.Close();
   TradeInfo p;
   p.tradenummer=127; p.position=1; p.symbol=_Symbol; p.type="BUY";
   p.price=100; p.sl=90; p.lots=0.1; p.sabioentry="Sabio's entry"; p.sabiosl="90"; p.was_send=false; p.is_trade_pending=true;
   Require(db.Create(p),"manual production number 127.1",failures);
   int tn=0,pn=0; Require(db.Next("BUY",tn,pn) && tn==127 && pn==2,"same direction 127.2",failures);
   Require(!db.Create(p),"duplicate identity rejected",failures);
   p.position=2; Require(db.Create(p),"second independent position",failures);
   p.type="SELL"; p.tradenummer=128; p.position=1; Require(db.Create(p),"opposite trade 128.1",failures);
   Require(db.Next("BUY",tn,pn) && tn==127 && pn==3,"return to BUY 127.3",failures);
   p.type="BUY"; p.tradenummer=129; Require(!db.Create(p),"cannot replace active trade",failures);
   db.Close();
   Require(db.Open(file,987654,999),"reopen existing DB ignores seed",failures);
   TradeInfo rows[];
   Require(db.Restore(rows) && ArraySize(rows)==3,"restore all three positions",failures);
   if(ArraySize(rows)==3)
     {
      TradeInfo first=rows[0]; first.sl=95;
      Require(db.Change(first,"OPEN","ENTRY_HIT","PENDING","OPEN"),"persist OPEN and SL",failures);
      Require(db.Change(first,"CLOSED_SL","SL_HIT","OPEN","CLOSED_SL"),"Pos1 SL closes BUY family",failures);
      Require(db.Restore(rows) && ArraySize(rows)==1 && rows[0].type=="SELL","opposite position remains",failures);
     }
   Require(db.Next("BUY",tn,pn) && tn==129 && pn==1,"next fresh trade follows high water",failures);
   db.Close(); FileDelete(file,FILE_COMMON); FileDelete(file+"-wal",FILE_COMMON); FileDelete(file+"-shm",FILE_COMMON);
   Print("SQLite smoke failures: ",failures);
  }
