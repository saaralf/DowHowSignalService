#ifndef __TA3_UI_MQH__
#define __TA3_UI_MQH__

#include "TA3_Application.mqh"

#define TA3_ENTRY_LINE   "TA3_ENTRY_LINE"
#define TA3_SL_LINE      "TA3_SL_LINE"
#define TA3_ENTRY_BTN    "TA3_ENTRY_BTN"
#define TA3_SL_BTN       "TA3_SL_BTN"
#define TA3_TRADE_EDIT   "TA3_TRADE_EDIT"
#define TA3_POS_EDIT     "TA3_POS_EDIT"
#define TA3_SABIO_ENTRY  "TA3_SABIO_ENTRY"
#define TA3_SABIO_SL     "TA3_SABIO_SL"
#define TA3_SEND_BTN     "TA3_SEND_BTN"
#define TA3_STATUS_LABEL "TA3_STATUS_LABEL"
#define TA3_PANEL_PREFIX "TA3_PANEL_"
#define TA3_POS_PREFIX   "TA3_POS_"

class CTA3UI
  {
private:
   CTA3Application   *m_app;
   TA3_Context        m_ctx;
   bool               m_sabio_entry_user;
   bool               m_sabio_sl_user;
   uint               m_last_refresh_ms;

   bool Exists(const string name) const
     {
      return (ObjectFind(m_ctx.chart_id,name)>=0);
     }

   void DeleteObject(const string name)
     {
      if(Exists(name))
         ObjectDelete(m_ctx.chart_id,name);
     }

   void DeletePrefix(const string prefix)
     {
      for(int i=ObjectsTotal(m_ctx.chart_id,0,-1)-1;i>=0;i--)
        {
         string n=ObjectName(m_ctx.chart_id,i,0,-1);
         if(StringFind(n,prefix,0)==0)
            ObjectDelete(m_ctx.chart_id,n);
        }
     }

   bool CreateLabel(const string name,const int x,const int y,const string text,const color clr=clrWhite)
     {
      DeleteObject(name);
      if(!ObjectCreate(m_ctx.chart_id,name,OBJ_LABEL,0,0,0))
         return false;
      ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
      ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_XDISTANCE,x);
      ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_COLOR,clr);
      ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_FONTSIZE,9);
      ObjectSetString(m_ctx.chart_id,name,OBJPROP_TEXT,text);
      ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_SELECTABLE,false);
      return true;
     }

   bool CreateButton(const string name,const int x,const int y,const int w,const int h,
                     const string text,const color bg=clrDimGray,const color fg=clrWhite)
     {
      DeleteObject(name);
      if(!ObjectCreate(m_ctx.chart_id,name,OBJ_BUTTON,0,0,0))
         return false;
      ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
      ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_XDISTANCE,x);
      ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_XSIZE,w);
      ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_YSIZE,h);
      ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_BGCOLOR,bg);
      ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_COLOR,fg);
      ObjectSetString(m_ctx.chart_id,name,OBJPROP_TEXT,text);
      return true;
     }

   bool CreateEdit(const string name,const int x,const int y,const int w,const int h,const string text)
     {
      DeleteObject(name);
      if(!ObjectCreate(m_ctx.chart_id,name,OBJ_EDIT,0,0,0))
         return false;
      ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
      ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_XDISTANCE,x);
      ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_XSIZE,w);
      ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_YSIZE,h);
      ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_BGCOLOR,clrWhite);
      ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_COLOR,clrBlack);
      ObjectSetString(m_ctx.chart_id,name,OBJPROP_TEXT,text);
      return true;
     }

   bool CreateHLine(const string name,const double price,const color clr)
     {
      if(!Exists(name))
        {
         if(!ObjectCreate(m_ctx.chart_id,name,OBJ_HLINE,0,0,price))
            return false;
         ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_COLOR,clr);
         ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_WIDTH,2);
         ObjectSetInteger(m_ctx.chart_id,name,OBJPROP_SELECTABLE,true);
        }
      ObjectSetDouble(m_ctx.chart_id,name,OBJPROP_PRICE,price);
      return true;
     }

   string Text(const string name,const string def="") const
     {
      if(!Exists(name)) return def;
      return ObjectGetString(m_ctx.chart_id,name,OBJPROP_TEXT);
     }

   int IntText(const string name,const int def=0) const
     {
      string s=Text(name,IntegerToString(def));
      StringTrimLeft(s); StringTrimRight(s);
      int v=(int)StringToInteger(s);
      return (v>0?v:def);
     }

   double Price(const string name) const
     {
      if(!Exists(name)) return 0.0;
      return ObjectGetDouble(m_ctx.chart_id,name,OBJPROP_PRICE);
     }

   string Direction() const
     {
      double e=Price(TA3_ENTRY_LINE), s=Price(TA3_SL_LINE);
      return (s<e ? "LONG" : "SHORT");
     }

   void SetStatus(const string text,const color clr=clrSilver)
     {
      if(!Exists(TA3_STATUS_LABEL))
         CreateLabel(TA3_STATUS_LABEL,20,185,text,clr);
      else
        {
         ObjectSetString(m_ctx.chart_id,TA3_STATUS_LABEL,OBJPROP_TEXT,text);
         ObjectSetInteger(m_ctx.chart_id,TA3_STATUS_LABEL,OBJPROP_COLOR,clr);
        }
     }

   void UpdateBaseTexts()
     {
      double e=Price(TA3_ENTRY_LINE), s=Price(TA3_SL_LINE);
      string err="";
      double lots=m_app.CalcLots(e,s,err);

      ObjectSetString(m_ctx.chart_id,TA3_ENTRY_BTN,OBJPROP_TEXT,
                      Direction()+" Entry "+DoubleToString(e,m_ctx.digits)+" | Lot "+DoubleToString(lots,2));
      ObjectSetString(m_ctx.chart_id,TA3_SL_BTN,OBJPROP_TEXT,
                      "SL "+DoubleToString(s,m_ctx.digits));

      if(!m_sabio_entry_user && Exists(TA3_SABIO_ENTRY))
         ObjectSetString(m_ctx.chart_id,TA3_SABIO_ENTRY,OBJPROP_TEXT,
                         "SABIO Entry: "+DoubleToString(e,m_ctx.digits));
      if(!m_sabio_sl_user && Exists(TA3_SABIO_SL))
         ObjectSetString(m_ctx.chart_id,TA3_SABIO_SL,OBJPROP_TEXT,
                         "SABIO SL: "+DoubleToString(s,m_ctx.digits));
     }

   bool CaptureDraft(TA3_Draft &d)
     {
      d.direction=Direction();
      d.entry=Price(TA3_ENTRY_LINE);
      d.sl=Price(TA3_SL_LINE);
      d.sabio_entry=Text(TA3_SABIO_ENTRY,"");
      d.sabio_sl=Text(TA3_SABIO_SL,"");
      d.requested_trade_no=IntText(TA3_TRADE_EDIT,0);
      d.requested_pos_no=IntText(TA3_POS_EDIT,1);
      d.sabio_entry_user=m_sabio_entry_user;
      d.sabio_sl_user=m_sabio_sl_user;
      return (d.entry>0.0 && d.sl>0.0);
     }

   void PersistDraft()
     {
      TA3_Draft d;
      if(!CaptureDraft(d))
         return;
      string err="";
      if(!m_app.SaveDraft(d,err) && err!="")
         SetStatus(err,clrTomato);
     }

   bool ParseAction(const string name,string &action,string &dir,int &trade_no,int &pos_no)
     {
      action="";dir="";trade_no=0;pos_no=0;
      string parts[];
      int n=StringSplit(name,'_',parts);
      // TA3 PANEL CANCEL LONG 7 2
      if(n!=6) return false;
      if(parts[0]!="TA3" || parts[1]!="PANEL") return false;
      action=parts[2];
      dir=parts[3];
      trade_no=(int)StringToInteger(parts[4]);
      pos_no=(int)StringToInteger(parts[5]);
      return true;
     }

   void DrawPositionLines(const TA3_Position &p)
     {
      string key=p.direction+"_"+IntegerToString(p.trade_no)+"_"+IntegerToString(p.pos_no);
      string e=TA3_POS_PREFIX+"E_"+key;
      string s=TA3_POS_PREFIX+"S_"+key;
      CreateHLine(e,p.entry,(p.direction=="LONG"?clrGreen:clrAqua));
      CreateHLine(s,p.sl,clrRed);
      ObjectSetInteger(m_ctx.chart_id,e,OBJPROP_STYLE,(p.status=="OPEN"?STYLE_SOLID:STYLE_DASH));
      ObjectSetInteger(m_ctx.chart_id,s,OBJPROP_STYLE,(p.status=="OPEN"?STYLE_SOLID:STYLE_DASH));
      ObjectSetInteger(m_ctx.chart_id,e,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(m_ctx.chart_id,s,OBJPROP_SELECTABLE,false);

      // Pixel-Labels: X bleibt rechts fix; Y wird aus dem Preis berechnet.
      int x=0,y=0;
      if(ChartTimePriceToXY(m_ctx.chart_id,0,TimeCurrent(),p.entry,x,y))
         CreateLabel(TA3_PANEL_PREFIX+"EL_"+key,12,MathMax(0,y-8),
                     p.direction+" T"+IntegerToString(p.trade_no)+" P"+IntegerToString(p.pos_no)+" Entry");
      if(ChartTimePriceToXY(m_ctx.chart_id,0,TimeCurrent(),p.sl,x,y))
         CreateLabel(TA3_PANEL_PREFIX+"SL_"+key,12,MathMax(0,y-8),"SL");
     }

public:
                     CTA3UI():m_app(NULL),m_sabio_entry_user(false),m_sabio_sl_user(false),m_last_refresh_ms(0) {}

   bool Init(CTA3Application *app,const TA3_Context &ctx)
     {
      m_app=app;
      m_ctx=ctx;
      return (m_app!=NULL);
     }

   void Create()
     {
      TA3_Draft d;
      m_app.LoadDraft(d);

      double ask=SymbolInfoDouble(m_ctx.symbol,SYMBOL_ASK);
      double point=SymbolInfoDouble(m_ctx.symbol,SYMBOL_POINT);
      double entry=(d.entry>0.0?d.entry:ask+100*point);
      double sl=(d.sl>0.0?d.sl:entry-200*point);

      CreateHLine(TA3_ENTRY_LINE,entry,clrDodgerBlue);
      CreateHLine(TA3_SL_LINE,sl,clrRed);

      CreateButton(TA3_ENTRY_BTN,20,20,260,24,"Entry",clrDodgerBlue,clrWhite);
      CreateButton(TA3_SL_BTN,20,48,260,24,"SL",clrFireBrick,clrWhite);
      CreateEdit(TA3_TRADE_EDIT,20,78,60,22,IntegerToString(d.requested_trade_no>0?d.requested_trade_no:1));
      CreateEdit(TA3_POS_EDIT,85,78,45,22,IntegerToString(d.requested_pos_no>0?d.requested_pos_no:1));
      CreateEdit(TA3_SABIO_ENTRY,135,78,145,22,d.sabio_entry!=""?d.sabio_entry:"SABIO Entry: ");
      CreateEdit(TA3_SABIO_SL,135,104,145,22,d.sabio_sl!=""?d.sabio_sl:"SABIO SL: ");
      CreateButton(TA3_SEND_BTN,20,132,260,28,"SEND SIGNAL",clrForestGreen,clrWhite);
      CreateLabel(TA3_STATUS_LABEL,20,166,"V3 bereit",clrSilver);

      m_sabio_entry_user=d.sabio_entry_user;
      m_sabio_sl_user=d.sabio_sl_user;

      UpdateBaseTexts();
      PersistDraft();
      Refresh();
     }

   void Destroy()
     {
      DeleteObject(TA3_ENTRY_LINE);
      DeleteObject(TA3_SL_LINE);
      DeleteObject(TA3_ENTRY_BTN);
      DeleteObject(TA3_SL_BTN);
      DeleteObject(TA3_TRADE_EDIT);
      DeleteObject(TA3_POS_EDIT);
      DeleteObject(TA3_SABIO_ENTRY);
      DeleteObject(TA3_SABIO_SL);
      DeleteObject(TA3_SEND_BTN);
      DeleteObject(TA3_STATUS_LABEL);
      DeletePrefix(TA3_PANEL_PREFIX);
      DeletePrefix(TA3_POS_PREFIX);
     }

   void Refresh()
     {
      DeletePrefix(TA3_PANEL_PREFIX);
      DeletePrefix(TA3_POS_PREFIX);

      TA3_Position rows[];
      int n=m_app.ActivePositions(rows);
      int y=210;
      for(int i=0;i<n;i++)
        {
         DrawPositionLines(rows[i]);
         string base=rows[i].direction+" T"+IntegerToString(rows[i].trade_no)+" P"+IntegerToString(rows[i].pos_no);
         CreateLabel(TA3_PANEL_PREFIX+"ROW_"+IntegerToString(i),20,y,
                     base+" "+rows[i].status+" Lot "+DoubleToString(rows[i].lots,2));
         string suffix=rows[i].direction+"_"+IntegerToString(rows[i].trade_no)+"_"+IntegerToString(rows[i].pos_no);
         CreateButton(TA3_PANEL_PREFIX+"CANCEL_"+suffix,20,y+18,70,20,"Pos Cancel",clrDarkSlateGray,clrWhite);
         CreateButton(TA3_PANEL_PREFIX+"SL_"+suffix,95,y+18,60,20,"SL Hit",clrFireBrick,clrWhite);
         CreateButton(TA3_PANEL_PREFIX+"TCANCEL_"+rows[i].direction+"_"+IntegerToString(rows[i].trade_no)+"_0",
                      160,y+18,120,20,"Trade Cancel",clrMaroon,clrWhite);
         y+=48;
        }
      ChartRedraw(m_ctx.chart_id);
     }

   void OnTick()
     {
      m_app.EvaluateMarket();

      uint now=GetTickCount();
      if((now-m_last_refresh_ms)>=1000)
        {
         Refresh();
         m_last_refresh_ms=now;
        }
     }

   void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
     {
      if(id==CHARTEVENT_OBJECT_DRAG || id==CHARTEVENT_OBJECT_CHANGE)
        {
         if(sparam==TA3_ENTRY_LINE || sparam==TA3_SL_LINE)
           {
            m_sabio_entry_user=false;
            m_sabio_sl_user=false;
            UpdateBaseTexts();
            PersistDraft();
            return;
           }
        }

      if(id==CHARTEVENT_OBJECT_ENDEDIT)
        {
         if(sparam==TA3_SABIO_ENTRY) m_sabio_entry_user=true;
         if(sparam==TA3_SABIO_SL)    m_sabio_sl_user=true;
         if(sparam==TA3_TRADE_EDIT || sparam==TA3_POS_EDIT ||
            sparam==TA3_SABIO_ENTRY || sparam==TA3_SABIO_SL)
           {
            PersistDraft();
            return;
           }
        }

      if(id==CHARTEVENT_OBJECT_CLICK)
        {
         if(sparam==TA3_SEND_BTN)
           {
            TA3_Draft d;
            if(!CaptureDraft(d))
              {
               SetStatus("Draft ungueltig",clrTomato);
               return;
              }
            TA3_Result r=m_app.SendDraft(d);
            if(r.ok)
              {
               ObjectSetString(m_ctx.chart_id,TA3_TRADE_EDIT,OBJPROP_TEXT,IntegerToString(r.trade_no));
               ObjectSetString(m_ctx.chart_id,TA3_POS_EDIT,OBJPROP_TEXT,IntegerToString(r.pos_no));
               SetStatus("Gesendet: T"+IntegerToString(r.trade_no)+" P"+IntegerToString(r.pos_no),clrLimeGreen);
               Refresh();
              }
            else
               SetStatus(r.error,clrTomato);
            return;
           }

         string action="",dir="";
         int tr=0,po=0;
         if(ParseAction(sparam,action,dir,tr,po))
           {
            string err="";

            if(action=="TCANCEL")
              {
               bool ok=m_app.CancelTrade(dir,tr,err);
               SetStatus(ok?"Trade abgebrochen":err,ok?clrLimeGreen:clrTomato);
               Refresh();
               return;
              }

            TA3_Position rows[];
            int n=m_app.ActivePositions(rows);
            for(int i=0;i<n;i++)
              {
               if(rows[i].direction!=dir || rows[i].trade_no!=tr || rows[i].pos_no!=po)
                  continue;
               bool ok=(action=="SL" ? m_app.ClosePosition(rows[i],"SL",err)
                                     : m_app.ClosePosition(rows[i],"CANCEL",err));
               SetStatus(ok?"Position aktualisiert":err,ok?clrLimeGreen:clrTomato);
               Refresh();
               return;
              }
           }
        }

      if(id==CHARTEVENT_CHART_CHANGE)
         Refresh();
     }
  };

#endif
