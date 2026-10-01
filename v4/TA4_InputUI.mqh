#ifndef TA4_INPUT_UI_MQH
#define TA4_INPUT_UI_MQH
#include "TA4_Types.mqh"
// Area 1. Captures drafts and emits commands; no persistence or business rules.
class CTA4InputUI
  {
private:
   TA4_Context m_ctx;
   TA4_Settings m_settings;
   TA4_Draft m_draft;
   bool m_drag;
   bool m_entry_drag;
   bool m_prev_down;
   bool m_native_drag;
   string m_edit;
   double m_drag_anchor_price;
   double m_drag_mouse_price;
   double m_delta;
   long m_trade,m_pos;
   double m_lots;
   string Name(const string tail) const { return "TA4_IN_"+tail; }
   void Text(const string tail,const string value) { ObjectSetString(m_ctx.chart,Name(tail),OBJPROP_TEXT,value); }
   void Box(const string tail,const ENUM_OBJECT type,const int w,const int h,const color bg,const color fg)
     {
      string n=Name(tail);
      if(ObjectFind(m_ctx.chart,n)<0) ObjectCreate(m_ctx.chart,n,type,0,0,0);
      ObjectSetInteger(m_ctx.chart,n,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(m_ctx.chart,n,OBJPROP_XSIZE,w); ObjectSetInteger(m_ctx.chart,n,OBJPROP_YSIZE,h);
      ObjectSetInteger(m_ctx.chart,n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(m_ctx.chart,n,OBJPROP_COLOR,fg);
      ObjectSetInteger(m_ctx.chart,n,OBJPROP_FONTSIZE,9); ObjectSetString(m_ctx.chart,n,OBJPROP_FONT,"Arial");
      ObjectSetInteger(m_ctx.chart,n,OBJPROP_SELECTABLE,false); ObjectSetInteger(m_ctx.chart,n,OBJPROP_ZORDER,20);
     }
   void Line(const string tail,const double price,const color clr)
     {
      string n=Name(tail); if(ObjectFind(m_ctx.chart,n)<0) ObjectCreate(m_ctx.chart,n,OBJ_HLINE,0,0,price);
      ObjectSetDouble(m_ctx.chart,n,OBJPROP_PRICE,price); ObjectSetInteger(m_ctx.chart,n,OBJPROP_COLOR,clr);
      ObjectSetInteger(m_ctx.chart,n,OBJPROP_SELECTABLE,true); ObjectSetInteger(m_ctx.chart,n,OBJPROP_ZORDER,10);
     }
   void XY(const string tail,const int x,const int y)
     { ObjectSetInteger(m_ctx.chart,Name(tail),OBJPROP_XDISTANCE,x); ObjectSetInteger(m_ctx.chart,Name(tail),OBJPROP_YDISTANCE,y); }
   int PriceY(const double price)
     {
      long first=ChartGetInteger(m_ctx.chart,CHART_FIRST_VISIBLE_BAR); datetime t=iTime(m_ctx.symbol,m_ctx.tf,(int)MathMax(0,first));
      int x=0,y=0; if(!ChartTimePriceToXY(m_ctx.chart,0,t,price,x,y)) return -10000; return y;
     }
   bool MousePrice(const int y,double &price)
     {
      datetime t=0; int window=0; double p=0;
      if(!ChartXYToTimePrice(m_ctx.chart,0,y,window,t,p) || window!=0) return false;
      price=TA4_Normalize(m_ctx.symbol,p); return price>0;
     }
   bool Hit(const string tail,const int x,const int y)
     {
      string n=Name(tail); int bx=(int)ObjectGetInteger(m_ctx.chart,n,OBJPROP_XDISTANCE),by=(int)ObjectGetInteger(m_ctx.chart,n,OBJPROP_YDISTANCE);
      return x>=bx && x<=bx+(int)ObjectGetInteger(m_ctx.chart,n,OBJPROP_XSIZE) && y>=by && y<=by+(int)ObjectGetInteger(m_ctx.chart,n,OBJPROP_YSIZE);
     }
   void ResetSabio()
     { m_draft.entry_override=false; m_draft.sl_override=false; m_draft.sabio_entry=TA4_Price(m_ctx,m_draft.entry); m_draft.sabio_sl=TA4_Price(m_ctx,m_draft.sl); }
   bool ReadSabio(const string tail,const string prefix,string &value)
     {
      string text=ObjectGetString(m_ctx.chart,Name(tail),OBJPROP_TEXT); StringReplace(text,prefix,""); StringTrimLeft(text); StringTrimRight(text);
      if(text=="") { value=""; return true; }
      for(int i=0;i<StringLen(text);i++) { ushort ch=StringGetCharacter(text,i); if((ch<'0' || ch>'9') && ch!='.') return false; }
      double p=StringToDouble(text); if(p<=0 || !MathIsValidNumber(p)) return false;
      value=DoubleToString(p,m_ctx.digits); return true;
     }
public:
   void Init(const TA4_Context &ctx,const TA4_Settings &settings,const TA4_Draft &draft)
     {
      m_ctx=ctx; m_settings=settings; m_draft=draft; m_drag=false; m_prev_down=false; m_native_drag=false; m_edit=""; m_trade=1; m_pos=1; m_lots=0;
      Box("ENTRY",OBJ_BUTTON,330,30,clrAqua,clrBlack); Box("SL",OBJ_BUTTON,330,30,clrRed,clrWhite);
      Box("SEND",OBJ_BUTTON,110,30,clrForestGreen,clrWhite); Text("SEND","SEND");
      Box("TRADE",OBJ_EDIT,55,24,clrWhite,clrBlack); Box("POS",OBJ_EDIT,55,24,clrWhite,clrBlack);
      ObjectSetInteger(m_ctx.chart,Name("TRADE"),OBJPROP_READONLY,true); ObjectSetInteger(m_ctx.chart,Name("POS"),OBJPROP_READONLY,true);
      if(settings.sabio_visible) { Box("SABIO_ENTRY",OBJ_EDIT,330,24,clrWhite,clrBlack); Box("SABIO_SL",OBJ_EDIT,330,24,clrWhite,clrBlack); }
      if(settings.tp_enabled) { Box("TP",OBJ_EDIT,330,24,clrDarkGreen,clrWhite); Text("TP",TA4_Price(m_ctx,draft.tp)); }
      Line("ENTRY_LINE",draft.entry,clrAqua); Line("SL_LINE",draft.sl,clrRed);
      ChartSetInteger(m_ctx.chart,CHART_EVENT_MOUSE_MOVE,true); Render();
     }
   TA4_Draft Draft() const { return m_draft; }
   void SetDraft(const TA4_Draft &draft) { m_draft=draft; Render(); }
   bool Editing() const { return m_edit!=""; }
   void Preview(const long tr,const long po,const double lots) { m_trade=tr; m_pos=po; m_lots=lots; if(m_edit=="") Render(); }
   void SetNumbers(const long tr,const long po,const double lots) { m_trade=tr; m_pos=po; m_lots=lots; if(!m_drag && !m_native_drag && m_edit=="") Render(); }
   bool Dragging() const { return m_drag || m_native_drag || m_edit!=""; }
   void Render()
     {
      if(m_edit!="") return;
      int width=(int)ChartGetInteger(m_ctx.chart,CHART_WIDTH_IN_PIXELS),height=(int)ChartGetInteger(m_ctx.chart,CHART_HEIGHT_IN_PIXELS);
      int x=MathMax(120,width-350),ey=PriceY(m_draft.entry),sy=PriceY(m_draft.sl);
      // Clamp only display positions. Never derive a stored price from a clamped button.
      int et=MathMax(35,MathMin(height-100,ey-15)),st=MathMax(35,MathMin(height-100,sy-15));
      XY("ENTRY",x,et); XY("SL",x,st); XY("SEND",x-110,et); XY("TRADE",x-110,et+30); XY("POS",x-55,et+30);
      string side=TA4_Direction(m_draft)=="LONG"?"Buy Stop":"Sell Stop";
      Text("ENTRY",side+" @ "+TA4_Price(m_ctx,m_draft.entry)+" | Lots: "+DoubleToString(m_lots,4));
      Text("SL","SL: "+DoubleToString(MathAbs(m_draft.entry-m_draft.sl)/SymbolInfoDouble(m_ctx.symbol,SYMBOL_POINT),0)+" pts | "+TA4_Price(m_ctx,m_draft.sl));
      Text("TRADE",IntegerToString(m_trade)); Text("POS",IntegerToString(m_pos));
      if(m_settings.sabio_visible)
        { XY("SABIO_ENTRY",x,et+30); XY("SABIO_SL",x,st+30); Text("SABIO_ENTRY","SabioEntry: "+m_draft.sabio_entry); Text("SABIO_SL","SabioSL: "+m_draft.sabio_sl); }
      if(m_settings.tp_enabled) { XY("TP",x,et+58); Text("TP",TA4_Price(m_ctx,m_draft.tp)); }
      Line("ENTRY_LINE",m_draft.entry,clrAqua); Line("SL_LINE",m_draft.sl,clrRed); ChartRedraw(m_ctx.chart);
     }
   bool Handle(const int id,const long &lparam,const double &dparam,const string &sparam,TA4_Command &cmd,string &error)
     {
      cmd.kind=""; error="";
      if(id==CHARTEVENT_CHART_CHANGE) { Render(); return true; }
      if(id==CHARTEVENT_MOUSE_MOVE)
        {
         int x=(int)lparam,y=(int)dparam; bool down=(((int)StringToInteger(sparam)&1)!=0);
         if(down && !m_prev_down && (Hit("ENTRY",x,y) || Hit("SL",x,y)))
           { m_entry_drag=Hit("ENTRY",x,y); m_drag=true; m_drag_anchor_price=m_entry_drag?m_draft.entry:m_draft.sl; if(!MousePrice(y,m_drag_mouse_price))m_drag=false; m_delta=m_draft.sl-m_draft.entry; ChartSetInteger(m_ctx.chart,CHART_MOUSE_SCROLL,false); }
         if(m_drag && down)
           {
            double price=0;
            if(MousePrice(y,price))
              {
               price=TA4_Normalize(m_ctx.symbol,m_drag_anchor_price+price-m_drag_mouse_price);
               if(price<=0)return true;
               if(m_entry_drag) { double shift=price-m_draft.entry; m_draft.entry=price; m_draft.sl=TA4_Normalize(m_ctx.symbol,price+m_delta); if(m_settings.tp_enabled) m_draft.tp=TA4_Normalize(m_ctx.symbol,m_draft.tp+shift); }
               else m_draft.sl=price;
               ResetSabio(); Render();
              }
           }
         if(m_drag && !down)
           { m_drag=false; ChartSetInteger(m_ctx.chart,CHART_MOUSE_SCROLL,true); cmd.kind="DRAFT"; cmd.draft=m_draft; }
         if(!m_drag && down)
           {
            double e=TA4_Normalize(m_ctx.symbol,ObjectGetDouble(m_ctx.chart,Name("ENTRY_LINE"),OBJPROP_PRICE));
            double sl=TA4_Normalize(m_ctx.symbol,ObjectGetDouble(m_ctx.chart,Name("SL_LINE"),OBJPROP_PRICE));
            if(e>0 && sl>0 && (e!=m_draft.entry || sl!=m_draft.sl))
              {
               m_native_drag=true;
               if(e!=m_draft.entry) { double shift=e-m_draft.entry;m_draft.sl=TA4_Normalize(m_ctx.symbol,m_draft.sl+shift);m_draft.entry=e;if(m_settings.tp_enabled)m_draft.tp=TA4_Normalize(m_ctx.symbol,m_draft.tp+shift); }
               else m_draft.sl=sl;
               ResetSabio();Render();
              }
           }
         if(m_native_drag && !down) { m_native_drag=false;cmd.kind="DRAFT";cmd.draft=m_draft; }
         m_prev_down=down; return m_drag || m_native_drag || cmd.kind!="";
        }
      if(id==CHARTEVENT_OBJECT_DRAG && (sparam==Name("ENTRY_LINE") || sparam==Name("SL_LINE")))
        {
         double p=TA4_Normalize(m_ctx.symbol,ObjectGetDouble(m_ctx.chart,sparam,OBJPROP_PRICE));
         if(p<=0) { Render(); return true; }
         if(sparam==Name("ENTRY_LINE")) { double shift=p-m_draft.entry; m_draft.sl=TA4_Normalize(m_ctx.symbol,m_draft.sl+shift); m_draft.entry=p; if(m_settings.tp_enabled) m_draft.tp=TA4_Normalize(m_ctx.symbol,m_draft.tp+shift); }
         else m_draft.sl=p;
         ResetSabio(); Render(); cmd.kind="DRAFT"; cmd.draft=m_draft; return true;
        }
      if(id==CHARTEVENT_OBJECT_ENDEDIT)
        {
         m_edit="";
         if(sparam==Name("SABIO_ENTRY") || sparam==Name("SABIO_SL"))
           {
            bool entry=sparam==Name("SABIO_ENTRY"); string value="";
            if(!ReadSabio(entry?"SABIO_ENTRY":"SABIO_SL",entry?"SabioEntry:":"SabioSL:",value)) { error="Sabio: enter a positive numeric price"; Render(); return true; }
            if(entry) { m_draft.sabio_entry=value==""?TA4_Price(m_ctx,m_draft.entry):value; m_draft.entry_override=value!=""; }
            else { m_draft.sabio_sl=value==""?TA4_Price(m_ctx,m_draft.sl):value; m_draft.sl_override=value!=""; }
            Render(); cmd.kind="DRAFT"; cmd.draft=m_draft; return true;
           }
         if(sparam==Name("TP"))
           { double p=TA4_Normalize(m_ctx.symbol,StringToDouble(ObjectGetString(m_ctx.chart,Name("TP"),OBJPROP_TEXT))); if(p<=0) { error="Invalid TP"; return true; } m_draft.tp=p; cmd.kind="DRAFT"; cmd.draft=m_draft; return true; }
        }
      if(id==CHARTEVENT_OBJECT_CLICK && (sparam==Name("SABIO_ENTRY") || sparam==Name("SABIO_SL") || sparam==Name("TP")))
        { m_edit=sparam; return true; }
      if(id==CHARTEVENT_OBJECT_CLICK && sparam==Name("SEND"))
        { ObjectSetInteger(m_ctx.chart,Name("SEND"),OBJPROP_STATE,false); cmd.kind="SEND"; cmd.draft=m_draft; return true; }
      return false;
     }
   void Destroy()
     { ChartSetInteger(m_ctx.chart,CHART_MOUSE_SCROLL,true); for(int i=ObjectsTotal(m_ctx.chart)-1;i>=0;i--) { string n=ObjectName(m_ctx.chart,i); if(StringFind(n,"TA4_IN_")==0) ObjectDelete(m_ctx.chart,n); } }
  };
#endif
