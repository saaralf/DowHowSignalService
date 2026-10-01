#ifndef TA4_PANEL_MQH
#define TA4_PANEL_MQH
#include "TA4_Types.mqh"
// Area 3. Render-only state plus commands. No SQL, HTTP or trade rules.
class CTA4Panel
  {
private:
   TA4_Context m_ctx;
   TA4_Position m_rows[];
   string m_status;
   string m_drag_name;
   void Label(const string name,const string text,const int x,const int y,const color clr=clrWhite,const bool right=false)
     {
      if(ObjectFind(m_ctx.chart,name)<0) ObjectCreate(m_ctx.chart,name,OBJ_LABEL,0,0,0);
      ObjectSetInteger(m_ctx.chart,name,OBJPROP_CORNER,right?CORNER_RIGHT_UPPER:CORNER_LEFT_UPPER);
      ObjectSetInteger(m_ctx.chart,name,OBJPROP_ANCHOR,right?ANCHOR_RIGHT_LOWER:ANCHOR_LEFT_UPPER);
      ObjectSetInteger(m_ctx.chart,name,OBJPROP_XDISTANCE,x); ObjectSetInteger(m_ctx.chart,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(m_ctx.chart,name,OBJPROP_FONTSIZE,9); ObjectSetInteger(m_ctx.chart,name,OBJPROP_COLOR,clr);
      ObjectSetInteger(m_ctx.chart,name,OBJPROP_SELECTABLE,false); ObjectSetString(m_ctx.chart,name,OBJPROP_TEXT,text);
     }
   void Button(const string name,const string text,const int x,const int y,const int width,const color bg)
     {
      if(ObjectFind(m_ctx.chart,name)<0) ObjectCreate(m_ctx.chart,name,OBJ_BUTTON,0,0,0);
      ObjectSetInteger(m_ctx.chart,name,OBJPROP_CORNER,CORNER_LEFT_UPPER); ObjectSetInteger(m_ctx.chart,name,OBJPROP_XDISTANCE,x); ObjectSetInteger(m_ctx.chart,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(m_ctx.chart,name,OBJPROP_XSIZE,width); ObjectSetInteger(m_ctx.chart,name,OBJPROP_YSIZE,23); ObjectSetInteger(m_ctx.chart,name,OBJPROP_BGCOLOR,bg);
      ObjectSetInteger(m_ctx.chart,name,OBJPROP_COLOR,clrWhite); ObjectSetInteger(m_ctx.chart,name,OBJPROP_FONTSIZE,9); ObjectSetInteger(m_ctx.chart,name,OBJPROP_SELECTABLE,false); ObjectSetInteger(m_ctx.chart,name,OBJPROP_ZORDER,30); ObjectSetString(m_ctx.chart,name,OBJPROP_TEXT,text);
     }
   string Key(const long tr,const long po) const { return IntegerToString(tr)+"_"+IntegerToString(po); }
   bool Parse(const string name,const string prefix,string &kind,long &tr,long &po)
     {
      if(StringFind(name,prefix)!=0) return false; string parts[];
      if(StringSplit(StringSubstr(name,StringLen(prefix)),'_',parts)!=3) return false;
      kind=parts[0]; tr=StringToInteger(parts[1]); po=StringToInteger(parts[2]); return tr>0;
     }
   void PositionLine(const TA4_Position &p,const bool entry)
     {
      string name="TA4_POS_"+(entry?"E_":"S_")+Key(p.trade_no,p.pos_no);
      double price=entry?p.entry:p.sl;
      if(ObjectFind(m_ctx.chart,name)<0) ObjectCreate(m_ctx.chart,name,OBJ_HLINE,0,0,price);
      ObjectSetDouble(m_ctx.chart,name,OBJPROP_PRICE,price); ObjectSetInteger(m_ctx.chart,name,OBJPROP_COLOR,entry?clrAqua:clrRed);
      ObjectSetInteger(m_ctx.chart,name,OBJPROP_STYLE,p.status=="PENDING"?STYLE_DASH:STYLE_SOLID);
      ObjectSetInteger(m_ctx.chart,name,OBJPROP_SELECTABLE,!entry || p.status=="PENDING");
      Tag(name,price,p,entry);
     }
   void Tag(const string name,const double price,const TA4_Position &p,const bool entry)
     {
      int x=0,y=0; long first=ChartGetInteger(m_ctx.chart,CHART_FIRST_VISIBLE_BAR);
      datetime t=iTime(m_ctx.symbol,m_ctx.tf,(int)MathMax(0,first));
      if(ChartTimePriceToXY(m_ctx.chart,0,t,price,x,y)) Label(name+"_TAG",(entry?"E ":"SL ")+p.direction+" T"+IntegerToString(p.trade_no)+" P"+IntegerToString(p.pos_no)+" "+TA4_Price(m_ctx,price),10,MathMax(12,y),entry?clrAqua:clrRed,true);
     }
   void DeletePrefix(const string prefix)
     { for(int i=ObjectsTotal(m_ctx.chart)-1;i>=0;i--) { string n=ObjectName(m_ctx.chart,i); if(StringFind(n,prefix)==0) ObjectDelete(m_ctx.chart,n); } }
public:
   void Init(const TA4_Context &ctx) { m_ctx=ctx; m_drag_name=""; m_status="V4 SendOnly"; }
   bool Dragging() const { return m_drag_name!=""; }
   void Status(const string text)
     { m_status=text; Label("TA4_PANEL_STATUS",text,10,30,clrYellow); }
   void Render(const TA4_Position &rows[],const string delivery)
     {
      if(Dragging()) return;
      ArrayResize(m_rows,ArraySize(rows)); for(int k=0;k<ArraySize(rows);k++) m_rows[k]=rows[k]; DeletePrefix("TA4_PANEL_ROW_"); DeletePrefix("TA4_PANEL_ACTION_");
      // Remove closed lines only; active objects keep their identity/selection.
      for(int i=ObjectsTotal(m_ctx.chart)-1;i>=0;i--)
        {
         string name=ObjectName(m_ctx.chart,i),kind=""; long tr=0,po=0;
         if(StringFind(name,"_TAG")>=0) continue;
         if(!Parse(name,"TA4_POS_",kind,tr,po)) continue;
         bool found=false; for(int j=0;j<ArraySize(rows);j++) if(rows[j].trade_no==tr && rows[j].pos_no==po) found=true;
         if(!found) { ObjectDelete(m_ctx.chart,name+"_TAG"); ObjectDelete(m_ctx.chart,name); }
        }
      Label("TA4_PANEL_TITLE","TradeAssistant V4 | SEND ONLY",10,10,clrAqua);
      Status(m_status); Label("TA4_PANEL_DELIVERY",delivery,10,50,clrSilver);
      Button("TA4_PANEL_RETRY","Retry",10,70,90,clrDarkOrange); Button("TA4_PANEL_CONFIRM","Delivered",105,70,100,clrDarkSlateGray);
      Label("TA4_PANEL_LONG","LONG",10,105,clrAqua); Label("TA4_PANEL_SHORT","SHORT",235,105,clrAqua);
      int longs=0,shorts=0; long lt=0,st=0;
      for(int i=0;i<ArraySize(rows);i++)
        {
         TA4_Position p=rows[i]; bool is_long=p.direction=="LONG";
         int x=is_long?10:235,y=155+65*(is_long?longs++:shorts++); if(is_long)lt=p.trade_no;else st=p.trade_no;
         string key=Key(p.trade_no,p.pos_no);
         Label("TA4_PANEL_ROW_"+key,"T"+IntegerToString(p.trade_no)+" P"+IntegerToString(p.pos_no)+" "+p.status,x,y);
         Label("TA4_PANEL_ROW_VOL_"+key,"Lots "+DoubleToString(p.lots,4),x,y+16,clrSilver);
         Button("TA4_PANEL_ACTION_C_"+key,"Cancel",x,y+32,95,clrFireBrick);
         Button("TA4_PANEL_ACTION_S_"+key,"SL Hit",x+100,y+32,95,clrFireBrick);
         PositionLine(p,true); PositionLine(p,false);
        }
      if(lt>0) Button("TA4_PANEL_ACTION_T_"+Key(lt,0),"Cancel LONG trade",10,125,195,clrMaroon);
      if(st>0) Button("TA4_PANEL_ACTION_T_"+Key(st,0),"Cancel SHORT trade",235,125,195,clrMaroon);
      ChartRedraw(m_ctx.chart);
     }
   bool Handle(const int id,const long &lparam,const double &dparam,const string &sparam,TA4_Command &cmd)
     {
      cmd.kind="";
      if(id==CHARTEVENT_OBJECT_CLICK)
        {
         ObjectSetInteger(m_ctx.chart,sparam,OBJPROP_STATE,false);
         if(sparam=="TA4_PANEL_RETRY" || sparam=="TA4_PANEL_CONFIRM") { cmd.kind=sparam=="TA4_PANEL_RETRY"?"RETRY":"CONFIRM_DELIVERED"; return true; }
         string action=""; long tr=0,po=0;
         if(Parse(sparam,"TA4_PANEL_ACTION_",action,tr,po)) { cmd.kind=action=="T"?"CANCEL_TRADE":(action=="S"?"SL":"CANCEL_POSITION"); cmd.trade_no=tr;cmd.pos_no=po;return true; }
        }
      // Live label follows the native HLINE; final drag emits exactly one adjustment.
      if(id==CHARTEVENT_MOUSE_MOVE)
        {
         bool down=(((int)StringToInteger(sparam)&1)!=0);
         if(down)
           for(int i=0;i<ArraySize(m_rows);i++)
             for(int k=0;k<2;k++)
               {
                string n="TA4_POS_"+(k==0?"E_":"S_")+Key(m_rows[i].trade_no,m_rows[i].pos_no);
                if((bool)ObjectGetInteger(m_ctx.chart,n,OBJPROP_SELECTED) && (bool)ObjectGetInteger(m_ctx.chart,n,OBJPROP_SELECTABLE))
                  { m_drag_name=n; Tag(n,ObjectGetDouble(m_ctx.chart,n,OBJPROP_PRICE),m_rows[i],k==0); }
               }
         if(!down) m_drag_name="";
        }
      if(id==CHARTEVENT_OBJECT_DRAG)
        {
         string kind=""; long tr=0,po=0;
         if(Parse(sparam,"TA4_POS_",kind,tr,po)) { m_drag_name=""; cmd.kind=kind=="E"?"ADJUST_ENTRY":"ADJUST_SL";cmd.trade_no=tr;cmd.pos_no=po;cmd.price=TA4_Normalize(m_ctx.symbol,ObjectGetDouble(m_ctx.chart,sparam,OBJPROP_PRICE)); return true; }
        }
      return false;
     }
   void Destroy() { DeletePrefix("TA4_PANEL_"); DeletePrefix("TA4_POS_"); }
  };
#endif
