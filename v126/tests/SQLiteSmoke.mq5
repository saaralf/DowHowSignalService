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
   if(!db.Open(file,987654,7)) { Print("FAIL opening smoke DB"); return; }
   Require(!second.Open(file,987654,7),"second owner blocked",failures); second.Close();
   TradeInfo p;
   p.tradenummer=0; p.position=1; p.symbol=_Symbol; p.type="BUY";
   p.price=100; p.sl=90; p.lots=0.1; p.sabioentry="Sabio's entry"; p.sabiosl="90"; p.was_send=false; p.is_trade_pending=true;
   Require(db.Create(p) && p.tradenummer==8,"initial seed and signal",failures);
   TradeInfo duplicate=p;
   Require(!db.Create(duplicate),"duplicate active direction rolls back",failures);
   int next=0; Require(db.Next(next) && next==9,"no counter gap",failures);
   p.sl=95; Require(db.Change(p,"OPEN","ENTRY_HIT","PENDING","OPEN"),"persist OPEN and SL",failures);
   db.Close();
   Require(db.Open(file,987654,999),"reopen existing DB ignores seed",failures);
   TradeInfo slots[2]; bool buy=false,sell=false,bh=false,sh=false;
   Require(db.Restore(slots,buy,sell,bh,sh) && buy && !sell && bh && slots[0].tradenummer==8 && slots[0].sl==95 && slots[0].sabioentry=="Sabio's entry","restore position and Sabio",failures);
   Require(db.Change(slots[0],"CLOSED_CANCEL","CANCEL","OPEN","CLOSED_CANCEL"),"close durable position",failures);
   p.type="SELL"; Require(db.Create(p) && p.tradenummer==9,"shared counter across direction",failures);
   db.Close(); FileDelete(file,FILE_COMMON); FileDelete(file+"-wal",FILE_COMMON); FileDelete(file+"-shm",FILE_COMMON);
   Print("SQLite smoke failures: ",failures);
  }
