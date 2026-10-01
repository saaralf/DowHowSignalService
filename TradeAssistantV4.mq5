#property copyright "DowHowSignalService"
#property version "4.000"
#property strict
#include "v4/TA4_Core.mqh"
#include "v4/TA4_InputUI.mqh"
#include "v4/TA4_Panel.mqh"
#include "v4/TA4_Discord.mqh"
input group "===== V4 State ====="
input string InpV4Database="DowHowSignalServiceV4.sqlite";
input string InpV4Profile="default";
input group "===== V4 Risk ====="
input TA4_RiskMode InpV4RiskMode=TA4_RISK_MONEY;
input double InpV4RiskValue=250.0;
input group "===== V4 Interface ====="
input bool InpV4SabioVisible=true;
input bool InpV4SabioSend=true;
input bool InpV4EnableTP=false; // optional TP price field; no TP drag group yet
input bool InpV4ConfirmSend=true;
input group "===== V4 Discord ====="
input bool InpV4DiscordEnabled=false; // deliberate opt-in for the new EA
input string InpV4WebhookConfig="DowHowSignalService_webhooks.cfg";
input string InpV4BotName="DowHow Signalservice V4";
input bool InpV4MentionEveryone=false;
CTA4Repository v4_repo;
CTA4Core v4_core;
CTA4InputUI v4_input;
CTA4Panel v4_panel;
CTA4Discord v4_discord;
TA4_Context v4_ctx;
TA4_Settings v4_settings;
bool v4_ready=false,v4_owned=false,v4_db_open=false,v4_ui_created=false;
uint v4_last_send=0;
bool v4_sent_once=false;

bool V4Refresh()
  {
   if(v4_input.Dragging() || v4_panel.Dragging()) return true;
   TA4_Position rows[]; if(!v4_repo.Positions(v4_ctx.key,rows)) { v4_panel.Status(v4_repo.Error()); return false; }
   TA4_Draft d=v4_input.Draft(); long tr=0,po=0;
   if(!v4_repo.Numbers(v4_ctx.key,TA4_Direction(d),tr,po)) { v4_panel.Status(v4_repo.Error()); return false; }
   string err=""; double lots=v4_core.Lots(d,err); v4_input.SetNumbers(tr,po,lots);
   TA4_Outbox o; bool found=false; if(!v4_repo.NextOutbox(v4_ctx.key,o,found)) { v4_panel.Status(v4_repo.Error()); return false; }
   string delivery=found?"Discord #"+IntegerToString(o.id)+": "+o.state:"Discord: no pending messages";
   if(!InpV4DiscordEnabled) delivery+=" (disabled; queue retained)";
   v4_panel.Render(rows,delivery); return true;
  }

int OnInit()
  {
   v4_ctx.chart=ChartID();v4_ctx.symbol=_Symbol;v4_ctx.tf=(ENUM_TIMEFRAMES)_Period;v4_ctx.digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   v4_ctx.key=AccountInfoString(ACCOUNT_SERVER)+"|"+IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN))+"|"+InpV4Profile+"|"+_Symbol+"|"+TA4_TF(v4_ctx.tf);
   v4_ctx.owner=IntegerToString((long)TimeGMT())+"-"+IntegerToString(ChartID())+"-"+IntegerToString((long)GetMicrosecondCount());
   v4_settings.risk_mode=InpV4RiskMode;v4_settings.risk_value=InpV4RiskValue;v4_settings.sabio_visible=InpV4SabioVisible;v4_settings.sabio_send=InpV4SabioSend;v4_settings.tp_enabled=InpV4EnableTP;v4_settings.mention=InpV4MentionEveryone;
   if(InpV4RiskValue<=0 || InpV4Profile=="") { Print("V4 invalid risk/profile input"); return INIT_PARAMETERS_INCORRECT; }
   if(!v4_repo.Open(InpV4Database)) { Print("V4: ",v4_repo.Error());return INIT_FAILED; } v4_db_open=true;
   if(!v4_repo.Acquire(v4_ctx)) { Print("V4: ",v4_repo.Error());return INIT_FAILED; } v4_owned=true;
   v4_core.Init(&v4_repo,v4_ctx,v4_settings);
   if(!v4_repo.Recover(v4_ctx)) { Print("V4: ",v4_repo.Error());return INIT_FAILED; }
   if(!v4_repo.BeginOwned(v4_ctx)) return INIT_FAILED;
   string config="RiskMode="+IntegerToString((int)InpV4RiskMode)+";RiskValue="+DoubleToString(InpV4RiskValue,4)+";TP="+IntegerToString(InpV4EnableTP?1:0)+";SabioVisible="+IntegerToString(InpV4SabioVisible?1:0)+";SabioSend="+IntegerToString(InpV4SabioSend?1:0)+";Discord="+IntegerToString(InpV4DiscordEnabled?1:0)+";Everyone="+IntegerToString(InpV4MentionEveryone?1:0);
   if(!v4_repo.Event(v4_ctx,"CONFIG_LOADED",0,0,"",config,"START")) { v4_repo.Rollback();return INIT_FAILED; }
   if(!v4_repo.Commit()) return INIT_FAILED;
   TA4_Draft d; bool found=false;
   if(!v4_repo.LoadDraft(v4_ctx.key,d,found)) return INIT_FAILED;
   if(!found)
     {
      MqlTick tick; if(!SymbolInfoTick(_Symbol,tick) || tick.ask<=0) { Print("V4: wait for valid market data"); return INIT_FAILED; }
      double size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE),distance=MathMax(100*SymbolInfoDouble(_Symbol,SYMBOL_POINT),10*size);
      d.entry=TA4_Normalize(_Symbol,tick.ask+distance);d.sl=TA4_Normalize(_Symbol,d.entry-distance);d.tp=TA4_Normalize(_Symbol,d.entry+distance);
      d.sabio_entry=TA4_Price(v4_ctx,d.entry);d.sabio_sl=TA4_Price(v4_ctx,d.sl);d.entry_override=false;d.sl_override=false;
      if(!v4_core.SaveDraft(d)) return INIT_FAILED;
     }
   if(InpV4DiscordEnabled && !v4_discord.Init(InpV4WebhookConfig,InpV4BotName)) { Print("V4: ",v4_discord.Error());return INIT_FAILED; }
   v4_input.Init(v4_ctx,v4_settings,d);v4_panel.Init(v4_ctx);v4_ui_created=true;v4_panel.Status("Ready | SendOnly | offline history not reconciled");
   if(!V4Refresh() || !EventSetTimer(1)) return INIT_FAILED;
   v4_ready=true; return INIT_SUCCEEDED;
  }
void OnDeinit(const int reason)
  {
   EventKillTimer();v4_ready=false;if(v4_ui_created) { v4_input.Destroy();v4_panel.Destroy(); }v4_ui_created=false;
   if(v4_owned) { if(v4_repo.BeginOwned(v4_ctx)) { if(v4_repo.Event(v4_ctx,"EA_STOPPED",0,0,"",IntegerToString(reason),"STOP")) v4_repo.Commit();else v4_repo.Rollback(); }v4_repo.Release(v4_ctx); }
   if(v4_db_open)v4_repo.Close();v4_owned=false;v4_db_open=false;
  }
void OnTick()
  {
   if(!v4_ready)return;MqlTick tick;
   if(SymbolInfoTick(_Symbol,tick) && !v4_core.Evaluate(tick)) v4_panel.Status(v4_core.Error());
  }
void OnTimer()
  {
   if(!v4_ready)return;
   if(!v4_repo.Acquire(v4_ctx)) { v4_ready=false;v4_panel.Status("Ownership lost; EA paused");return; }
   if(InpV4DiscordEnabled && !v4_input.Dragging() && !v4_panel.Dragging())
     {
      TA4_Outbox o;bool found=false;
      if(!v4_repo.NextOutbox(v4_ctx.key,o,found)) { v4_panel.Status(v4_repo.Error());return; }
      if(found && o.state=="QUEUED")
        {
         if(!v4_repo.OutboxState(v4_ctx,o.id,"SENDING","",true)) { v4_panel.Status(v4_repo.Error());return; }
         string state=v4_discord.Deliver(_Symbol,o,InpV4MentionEveryone),error=v4_discord.Error();int delay=0;
         if(state=="RATE_LIMITED") { state=o.attempts<2?"QUEUED":"FAILED";delay=30*(o.attempts+1); }
         if(!v4_repo.OutboxState(v4_ctx,o.id,state,error,false,delay))
           { v4_ready=false;v4_panel.Status("Delivery result not saved; restart to reconcile UNKNOWN");return; }
         if(state=="SENT" && o.image!="")FileDelete(o.image);
         if(error!="")v4_panel.Status(error);
        }
     }
   V4Refresh();
  }
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(!v4_ready)return; TA4_Command cmd;string error="";
   bool handled=v4_input.Handle(id,lparam,dparam,sparam,cmd,error);
   if(!handled)handled=v4_panel.Handle(id,lparam,dparam,sparam,cmd);
   if(error!="")v4_panel.Status(error);
   if(id==CHARTEVENT_MOUSE_MOVE && v4_input.Dragging() && !v4_input.Editing())
     { TA4_Draft live=v4_input.Draft();long tr=0,po=0;string lot_error="";if(v4_repo.Numbers(v4_ctx.key,TA4_Direction(live),tr,po))v4_input.Preview(tr,po,v4_core.Lots(live,lot_error)); }
   if(cmd.kind=="") { if(id==CHARTEVENT_CHART_CHANGE)V4Refresh();return; }
   bool ok=false;
   if(cmd.kind=="DRAFT")
     {
      ok=v4_core.SaveDraft(cmd.draft);
      if(!ok) { TA4_Draft old;bool found=false;if(v4_repo.LoadDraft(v4_ctx.key,old,found) && found)v4_input.SetDraft(old); }
     }
   else if(cmd.kind=="SEND")
     {
      uint now=GetTickCount();if(v4_sent_once && now-v4_last_send<1000)return;
      if(InpV4DiscordEnabled && !v4_discord.HasRoute(_Symbol)) { v4_panel.Status("No symbol webhook; SEND blocked");return; }
      if(InpV4ConfirmSend && MessageBox("Queue "+TA4_Direction(cmd.draft)+" signal?\nEntry "+TA4_Price(v4_ctx,cmd.draft.entry)+" / SL "+TA4_Price(v4_ctx,cmd.draft.sl),"V4 SEND",MB_YESNO)!=IDYES)return;
      string image="TA4_"+IntegerToString(v4_ctx.chart)+"_"+IntegerToString((long)GetMicrosecondCount())+".png";
      if(!ChartScreenShot(v4_ctx.chart,image,(int)ChartGetInteger(v4_ctx.chart,CHART_WIDTH_IN_PIXELS),(int)ChartGetInteger(v4_ctx.chart,CHART_HEIGHT_IN_PIXELS)))image="";
      ok=v4_core.Send(cmd.draft,image);if(!ok && image!="")FileDelete(image);
      if(ok) { v4_last_send=GetTickCount();v4_sent_once=true;v4_panel.Status("Signal saved and queued; Discord delivery pending"); }
     }
   else if(cmd.kind=="CANCEL_TRADE")
     { if(MessageBox("Cancel every active position of Trade "+IntegerToString(cmd.trade_no)+"?","V4",MB_YESNO)!=IDYES)return;ok=v4_core.CancelTrade(cmd.trade_no); }
   else if(cmd.kind=="SL" || cmd.kind=="CANCEL_POSITION")
     { if(MessageBox(cmd.kind+" for T"+IntegerToString(cmd.trade_no)+" P"+IntegerToString(cmd.pos_no)+"?\nSL on Pos 1 ends all positions of this trade.","V4",MB_YESNO)!=IDYES)return;ok=v4_core.ClosePosition(cmd.trade_no,cmd.pos_no,cmd.kind=="SL"?"SL":"CANCEL","USER"); }
   else if(cmd.kind=="ADJUST_ENTRY" || cmd.kind=="ADJUST_SL")ok=v4_core.Adjust(cmd.trade_no,cmd.pos_no,cmd.kind=="ADJUST_ENTRY"?"ENTRY":"SL",cmd.price);
   else if(cmd.kind=="RETRY" || cmd.kind=="CONFIRM_DELIVERED")
     {
      TA4_Outbox o;bool found=false;
      if(!v4_repo.NextOutbox(v4_ctx.key,o,found) || !found || (o.state!="UNKNOWN" && o.state!="FAILED")) { v4_panel.Status("No FAILED/UNKNOWN message to resolve");return; }
      string question=cmd.kind=="RETRY"?"Retry the message? If it already arrived, a duplicate can result.":"Have you verified this message in Discord? Mark it delivered and unblock following messages?";
      if(MessageBox(question,"V4 delivery resolution",MB_YESNO)!=IDYES)return;
      ok=v4_repo.ResolveOutbox(v4_ctx,o,cmd.kind=="RETRY");if(!ok)v4_panel.Status(v4_repo.Error());
     }
   if(!ok && cmd.kind!="RETRY" && cmd.kind!="CONFIRM_DELIVERED")v4_panel.Status(v4_core.Error());
   V4Refresh();
  }
