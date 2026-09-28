#ifndef __TA3_APPLICATION_MQH__
#define __TA3_APPLICATION_MQH__

#include "TA3_Types.mqh"
#include "TA3_Repository.mqh"
#include "CDiscordClient.mqh"

class CTA3Application
  {
private:
   CTA3Repository    *m_repo;
   CDiscordClient    *m_discord;
   TA3_Context        m_ctx;
   double             m_risk_percent;

   string FormatSignal(const TA3_Position &p) const
     {
      string msg="**DowHow Signal V3**\n";
      msg += p.direction+" | Trade "+IntegerToString(p.trade_no)+" | Pos "+IntegerToString(p.pos_no)+"\n";
      msg += "Entry: "+DoubleToString(p.entry,m_ctx.digits)+"\n";
      msg += "SL: "+DoubleToString(p.sl,m_ctx.digits)+"\n";
      msg += "Lot: "+DoubleToString(p.lots,2);
      if(p.sabio_entry!="") msg += "\n"+p.sabio_entry;
      if(p.sabio_sl!="")    msg += "\n"+p.sabio_sl;
      return msg;
     }

   string FormatLifecycle(const string kind,const TA3_Position &p) const
     {
      return "**DowHow Signal V3 - "+kind+"**\n"+
             p.direction+" | Trade "+IntegerToString(p.trade_no)+" | Pos "+IntegerToString(p.pos_no);
     }

   bool SendDiscord(const string symbol,const string msg,const bool with_chart)
     {
      if(m_discord==NULL || CheckPointer(m_discord)==POINTER_INVALID)
         return false;

      if(!with_chart)
         return m_discord.SendMessage(symbol,msg);

      int w=(int)ChartGetInteger(m_ctx.chart_id,CHART_WIDTH_IN_PIXELS,0);
      int h=(int)ChartGetInteger(m_ctx.chart_id,CHART_HEIGHT_IN_PIXELS,0);
      return m_discord.SendMessageWithChart(symbol,msg,m_ctx.chart_id,w,h);
     }

public:
                     CTA3Application():m_repo(NULL),m_discord(NULL),m_risk_percent(0.01) {}

   bool Init(CTA3Repository *repo,CDiscordClient *discord,const TA3_Context &ctx)
     {
      m_repo=repo;
      m_discord=discord;
      m_ctx=ctx;
      return (m_repo!=NULL && m_discord!=NULL);
     }

   void SetRiskPercent(const double value)
     {
      if(value>0.0 && value<=0.20)
         m_risk_percent=value;
     }

   double CalcLots(const double entry,const double sl,string &error)
     {
      error="";
      double distance=MathAbs(entry-sl);
      double equity=AccountInfoDouble(ACCOUNT_EQUITY);
      double tick_size=SymbolInfoDouble(m_ctx.symbol,SYMBOL_TRADE_TICK_SIZE);
      double tick_value=SymbolInfoDouble(m_ctx.symbol,SYMBOL_TRADE_TICK_VALUE_LOSS);
      if(tick_value<=0.0)
         tick_value=SymbolInfoDouble(m_ctx.symbol,SYMBOL_TRADE_TICK_VALUE);

      double min_lot=SymbolInfoDouble(m_ctx.symbol,SYMBOL_VOLUME_MIN);
      double max_lot=SymbolInfoDouble(m_ctx.symbol,SYMBOL_VOLUME_MAX);
      double step=SymbolInfoDouble(m_ctx.symbol,SYMBOL_VOLUME_STEP);

      if(distance<=0.0 || equity<=0.0 || tick_size<=0.0 || tick_value<=0.0 ||
         min_lot<=0.0 || max_lot<=0.0 || step<=0.0)
        {
         error="ungueltige Broker-/Preis-Daten fuer Lotberechnung";
         return 0.0;
        }

      double risk=equity*m_risk_percent;
      double loss_per_lot=(distance/tick_size)*tick_value;
      if(loss_per_lot<=0.0)
        {
         error="loss_per_lot <= 0";
         return 0.0;
        }

      double raw=risk/loss_per_lot;
      if(raw<min_lot)
        {
         error="berechnetes Lot liegt unter Broker-Minimum";
         return 0.0;
        }

      double lots=MathMin(raw,max_lot);
      lots=MathFloor((lots+1e-12)/step)*step;
      if(lots<min_lot)
        {
         error="gerundetes Lot liegt unter Broker-Minimum";
         return 0.0;
        }
      return NormalizeDouble(lots,8);
     }

   bool SaveDraft(TA3_Draft &draft,string &error)
     {
      error="";
      draft.direction=TA3_Upper(draft.direction);
      if(draft.direction!="LONG" && draft.direction!="SHORT")
        {
         error="ungueltige Richtung";
         return false;
        }
      if(draft.entry<=0.0 || draft.sl<=0.0 || draft.entry==draft.sl)
        {
         error="Entry/SL ungueltig";
         return false;
        }
      return m_repo.SaveDraft(m_ctx.symbol,m_ctx.tf,draft);
     }

   bool LoadDraft(TA3_Draft &draft)
     {
      return m_repo.LoadDraft(m_ctx.symbol,m_ctx.tf,draft);
     }

   TA3_Result SendDraft(TA3_Draft &draft)
     {
      TA3_Result out;
      out.ok=false; out.error=""; out.trade_no=0; out.pos_no=0;

      if(!SaveDraft(draft,out.error))
         return out;

      int max_trade=m_repo.MaxTradeNo(m_ctx.symbol,m_ctx.tf);
      int trade_no=draft.requested_trade_no;
      if(trade_no<=0)
         trade_no=max_trade+1;

      string dir=TA3_Upper(draft.direction);
      int pos_no=m_repo.NextFreePos(m_ctx.symbol,m_ctx.tf,dir,trade_no,draft.requested_pos_no);
      if(pos_no<=0)
        {
         out.error="maximal 4 Positionen je Trade/Richtung";
         return out;
        }

      string lot_error="";
      double lots=CalcLots(draft.entry,draft.sl,lot_error);
      if(lots<=0.0)
        {
         out.error="Lotberechnung: "+lot_error;
         return out;
        }

      TA3_Position p;
      p.symbol=m_ctx.symbol;
      p.tf=TA3_TFToString(m_ctx.tf);
      p.direction=dir;
      p.trade_no=trade_no;
      p.pos_no=pos_no;
      p.entry=draft.entry;
      p.sl=draft.sl;
      p.lots=lots;
      p.sabio_entry=draft.sabio_entry;
      p.sabio_sl=draft.sabio_sl;
      p.status="PENDING";
      p.was_sent=1;
      p.is_pending=1;
      p.created_at=(long)TimeCurrent();
      p.updated_at=p.created_at;

      // Finaler Zustand zuerst persistieren; Discord ist danach irreversibel.
      if(!m_repo.UpsertPosition(p))
        {
         out.error="DB: PENDING konnte nicht gespeichert werden";
         return out;
        }

      if(!SendDiscord(m_ctx.symbol,FormatSignal(p),true))
        {
         if(!m_repo.DeletePosition(p))
            out.error="Discord fehlgeschlagen; DB-Rollback ebenfalls fehlgeschlagen";
         else
            out.error="Discord fehlgeschlagen; DB-Rollback erfolgreich";
         return out;
        }

      draft.requested_trade_no=trade_no;
      draft.requested_pos_no=pos_no;
      m_repo.SaveDraft(m_ctx.symbol,m_ctx.tf,draft);

      out.ok=true;
      out.trade_no=trade_no;
      out.pos_no=pos_no;
      return out;
     }

   bool MarkOpen(const TA3_Position &p,string &error)
     {
      error="";
      if(TA3_IsClosed(p.status))
         return true;
      if(p.status=="OPEN" && p.is_pending==0)
         return true;

      if(!m_repo.UpdateStatus(m_ctx.symbol,m_ctx.tf,p.direction,p.trade_no,p.pos_no,"OPEN",0))
        {
         error="DB OPEN transition fehlgeschlagen";
         return false;
        }

      if(!SendDiscord(m_ctx.symbol,FormatLifecycle("ENTRY HIT",p),false))
         CLogger::Add(LOG_LEVEL_WARNING,"TA3: OPEN wurde gespeichert, Discord-Meldung schlug fehl");
      return true;
     }

   bool ClosePosition(const TA3_Position &p,const string reason,string &error)
     {
      error="";
      if(TA3_IsClosed(p.status))
         return true;

      string target=(reason=="SL" ? "CLOSED_SL" : "CLOSED_CANCEL");
      string kind=(reason=="SL" ? "STOP LOSS" : "POSITION CANCEL");

      // Bei Close/Cancel zuerst Nachricht. Bei Sendefehler bleibt Zustand unveraendert.
      if(!SendDiscord(m_ctx.symbol,FormatLifecycle(kind,p),false))
        {
         error="Discord Close/Cancel fehlgeschlagen";
         return false;
        }

      if(!m_repo.UpdateStatus(m_ctx.symbol,m_ctx.tf,p.direction,p.trade_no,p.pos_no,target,0))
        {
         error="DB Close/Cancel fehlgeschlagen";
         return false;
        }
      return true;
     }

   bool CancelTrade(const string direction,const int trade_no,string &error)
     {
      error="";
      TA3_Position rows[];
      int n=m_repo.LoadPositions(m_ctx.symbol,m_ctx.tf,rows,true);
      if(n<0)
        {
         error="Positionen konnten nicht geladen werden";
         return false;
        }

      bool found=false;
      TA3_Position first;
      for(int i=0;i<n;i++)
        {
         if(rows[i].direction==direction && rows[i].trade_no==trade_no)
           {
            if(!found) first=rows[i];
            found=true;
           }
        }
      if(!found)
         return true;

      string msg="**DowHow Signal V3 - TRADE CANCEL**\n"+
                 direction+" | Trade "+IntegerToString(trade_no);
      if(!SendDiscord(m_ctx.symbol,msg,false))
        {
         error="Discord Trade-Cancel fehlgeschlagen";
         return false;
        }

      for(int i=0;i<n;i++)
        {
         if(rows[i].direction!=direction || rows[i].trade_no!=trade_no)
            continue;
         if(TA3_IsClosed(rows[i].status))
            continue;
         if(!m_repo.UpdateStatus(m_ctx.symbol,m_ctx.tf,direction,trade_no,rows[i].pos_no,"CLOSED_CANCEL",0))
           {
            error="DB Trade-Cancel teilweise fehlgeschlagen";
            return false;
           }
        }
      return true;
     }

   void EvaluateMarket()
     {
      TA3_Position rows[];
      int n=m_repo.LoadPositions(m_ctx.symbol,m_ctx.tf,rows,true);
      if(n<=0)
         return;

      double ask=SymbolInfoDouble(m_ctx.symbol,SYMBOL_ASK);
      double bid=SymbolInfoDouble(m_ctx.symbol,SYMBOL_BID);

      for(int i=0;i<n;i++)
        {
         string err="";
         if(rows[i].status=="PENDING")
           {
            bool hit=(rows[i].direction=="LONG" ? ask>=rows[i].entry : bid<=rows[i].entry);
            if(hit)
               MarkOpen(rows[i],err);
           }
         else if(rows[i].status=="OPEN")
           {
            bool sl_hit=(rows[i].direction=="LONG" ? bid<=rows[i].sl : ask>=rows[i].sl);
            if(sl_hit)
               ClosePosition(rows[i],"SL",err);
           }

         if(err!="")
            CLogger::Add(LOG_LEVEL_WARNING,"TA3 lifecycle: "+err);
        }
     }

   int ActivePositions(TA3_Position &rows[])
     {
      return m_repo.LoadPositions(m_ctx.symbol,m_ctx.tf,rows,true);
     }
  };

#endif
