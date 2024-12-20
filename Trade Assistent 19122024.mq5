//+------------------------------------------------------------------+
//|                                              Trade Assistant.mq5 |
//|                                 Michael Keller & Steffen Kachold |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Michael Keller & Steffen Kachold"
#property link      ""
#property version   "0.10"

#property strict
#include <Controls\Dialog.mqh>
#include <Trade\Trade.mqh>
CTrade trade;

// Default values for settings:
double EntryLevel = 0;
double StopLossLevel = 0;
double TakeProfitLevel = 0;
double StopPriceLevel = 0;

// Button1 = input parameters for Trade & Send = Send only
// Button2 = Send only
// Button3 = Trade & Send
// only one button is visible 

input group "label & fonts"
input color Button1_bgcolor = clrRed; // Button Color Please check settings
input color Button1_font_color = clrBlack; // Font Color Button Please check settings
input uint Button1_font_size = 15; // Font Size Button Please check settings
input color Button2_bgcolor = clrLime; // Button Color Send only
input color Button2_font_color = clrWhite; // Font Color Button Send only
input uint Button2_font_size = 10; // Font Size Button Trade & Send
input color Button3_bgcolor = clrAqua; // Button Color Trade & Send 
input color Button3_font_color = clrRed; // Font Color Button Trade & Send 
input uint Button3_font_size = 10; // Font Size Button Trade & Send 
//input string font_face = "Courier"; // Labels Font Face
//input color entry_line_color = clrAqua; // Entry Line Color
//input color stoploss_line_color = clrRed; // Stop-Loss Line Color
//input color takeprofit_line_color = clrLime; // Take-Profit Line Color
//input color stopprice_line_color = clrPurple; // Stop Price Line Color
//input color be_line_color = clrNONE; // BE Line Color
//input ENUM_LINE_STYLE entry_line_style = STYLE_SOLID; // Entry Line Style
//input ENUM_LINE_STYLE stoploss_line_style = STYLE_SOLID; // Stop-Loss Line Stylek
//input ENUM_LINE_STYLE takeprofit_line_style = STYLE_SOLID; // Take-Profit Line Style
//input ENUM_LINE_STYLE stopprice_line_style = STYLE_DOT; // Stop Price Line Style
//input ENUM_LINE_STYLE be_line_style = STYLE_DOT; // BE Line Style
//input uint entry_line_width = 1; // Entry Line Width
//input uint stoploss_line_width = 1; // Stop-Loss Line Width
//input uint takeprofit_line_width = 1; // Take-Profit Line Width
//input uint stopprice_line_width = 1; // Stop Price Line Width
//input uint be_line_width = 1; // BE Line Width
input group "Defaults"
//input int buttonwidth =200; // Button breite in Pixel
//input int buttonhigh =80;// Button Höhe in Pixel
input bool Button2 = true; //Send only
input bool Button3 = false;//Trade & Send
//input bool TradeandSend = false;
input double DefaultRisk = 1; // Risk in %
//input double DefaultMoneyRisk = 0; // MoneyRisk: If > 0, money risk tolerance in currency.
//input double DefaultPositionSize = 0; // PositionSize: If > 0, position size in lots.
//input int DefaultMagicNumber = 2022052714; // MagicNumber: Default magic number for Trading tab.
//input bool DefaultTPLockedOnSL = true; // TPLockedOnSL: Lock TP to (multiplied) SL distance.
//input double TP_Multiplier = 1.00; // TP Multiplier for SL value, appears in Take-profit button.
//input group "Discord"
//input string Target_Channel = "Intraday-M2"; //Target Channel

bool CheckForExistingLongPosition();


#define REC1 "REC1"
#define REC3 "REC3"
#define REC5 "REC5"

#define TP_HL "TP_HL"
#define SL_HL "SL_HL"
#define PR_HL "PR_HL"

double Get_Price_d(string name)
   {
      return ObjectGetDouble(0,name,OBJPROP_PRICE);
   }
   
string Get_Price_s(string name)
   {
      return DoubleToString(ObjectGetDouble(0,name,OBJPROP_PRICE),_Digits);
   }

string update_Text(string name,string val)
   {
   return (string)ObjectSetString(0,name,OBJPROP_TEXT,val);
   }

int
   xd1,yd1,xs1,ys1,
   xd2,yd2,xs2,ys2,
   xd3,yd3,xs3,ys3,
   xd4,yd4,xs4,ys4,
   xd5,yd5,xs5,ys5;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  if ((Button2 == true && Button3 == true) || (Button2 == false && Button3 == false))
      {
         ObjectCreate(0, "Button1", OBJ_BUTTON, 0, 0, 0);
         ObjectSetInteger(0, "Button1", OBJPROP_XDISTANCE, 400);    // X position
         ObjectSetInteger(0, "Button1", OBJPROP_XSIZE, 300);        // width
         ObjectSetInteger(0, "Button1", OBJPROP_YDISTANCE, 50);    // Y position
         ObjectSetInteger(0, "Button1", OBJPROP_YSIZE, 50);        // height
         ObjectSetInteger(0, "Button1", OBJPROP_CORNER, 0);        // chart corner
         ObjectSetString(0, "Button1", OBJPROP_TEXT, "Please check settings"); // label
         ObjectSetInteger(0, "Button1", OBJPROP_BGCOLOR,Button1_bgcolor);
         ObjectSetInteger(0, "Button1", OBJPROP_COLOR,Button1_font_color);
         ObjectSetInteger(0, "Button1", OBJPROP_FONTSIZE,Button1_font_size);
      } 
  else
  
  if (Button2 == true && Button3 == false)
      {
         ObjectCreate(0, "Button2", OBJ_BUTTON, 0, 0, 0);
         ObjectSetInteger(0, "Button2", OBJPROP_XDISTANCE, 400);    // X position
         ObjectSetInteger(0, "Button2", OBJPROP_XSIZE, 150);        // width
         ObjectSetInteger(0, "Button2", OBJPROP_YDISTANCE, 50);    // Y position
         ObjectSetInteger(0, "Button2", OBJPROP_YSIZE, 50);        // height
         ObjectSetInteger(0, "Button2", OBJPROP_CORNER, 0);        // chart corner
         ObjectSetString(0, "Button2", OBJPROP_TEXT, "Send only"); // label
         ObjectSetInteger(0, "Button2", OBJPROP_COLOR,Button2_font_color);
         ObjectSetInteger(0, "Button2", OBJPROP_FONTSIZE,Button2_font_size);
         ObjectSetInteger(0, "Button2", OBJPROP_BGCOLOR,Button2_bgcolor);

      }     
  else
  
  if (Button2 == false && Button3 == true)
      {
         ObjectCreate(0, "Button3", OBJ_BUTTON, 0, 0, 0);
         ObjectSetInteger(0, "Button3", OBJPROP_XDISTANCE, 400);    // X position
         ObjectSetInteger(0, "Button3", OBJPROP_XSIZE, 150);        // width
         ObjectSetInteger(0, "Button3", OBJPROP_YDISTANCE, 50);    // Y position
         ObjectSetInteger(0, "Button3", OBJPROP_YSIZE, 50);        // height
         ObjectSetInteger(0, "Button3", OBJPROP_CORNER, 0);        // chart corner
         ObjectSetString(0, "Button3", OBJPROP_TEXT, "Trade & Send"); // label
         ObjectSetInteger(0, "Button3", OBJPROP_BGCOLOR,Button3_bgcolor);
         ObjectSetInteger(0, "Button3", OBJPROP_COLOR,Button3_font_color);
         ObjectSetInteger(0, "Button3", OBJPROP_FONTSIZE,Button3_font_size);
      }       

   createButton(REC1,"",2900,500,400,30,clrWhite,clrGreen,13,clrWhite,"Arial Black");
   // TP Button   
   xd1 = (int)ObjectGetInteger(0,REC1,OBJPROP_XDISTANCE);
   yd1 = (int)ObjectGetInteger(0,REC1,OBJPROP_YDISTANCE);
   xs1 = (int)ObjectGetInteger(0,REC1,OBJPROP_XSIZE);
   ys1 = (int)ObjectGetInteger(0,REC1,OBJPROP_YSIZE);
    
   // Button at price
   xd3 = xd1;
   yd3 = yd1 + (100*DefaultRisk);
   xs3 = xs1;
   ys3 = 30;   
   
   // SL Button
   xd5 = xd1;
   yd5 = yd3 + 100;
   xs5 = xs1;
   ys5 = 30;
 
   datetime dt_tp=0,dt_sl=0,dt_prc=0;
   double price_tp=0,price_sl=0,price_prc=0;
   int window = 0;
 
   ChartXYToTimePrice(0,xd1,yd1+ys1,window,dt_tp,price_tp);
   ChartXYToTimePrice(0,xd3,yd3+ys3,window,dt_prc,price_prc);
   ChartXYToTimePrice(0,xd5,yd5+ys5,window,dt_sl,price_sl);
  
   createHL(TP_HL,dt_tp,price_tp,clrLime);
   createHL(PR_HL,dt_prc,price_prc,clrAqua);
   createHL(SL_HL,dt_sl,price_sl,clrWhite);   
   
   createButton(REC3,"",xd3,yd3,xs3,ys3,clrBlack,clrAqua,12,clrNONE,"Arial Black");
   createButton(REC5,"",xd5,yd5,xs5,ys5,clrWhite,clrRed,13,clrNONE,"Arial Black");
   
   update_Text(REC1,"TP: "+ DoubleToString(((Get_Price_d(TP_HL)-Get_Price_d(PR_HL))/_Point),0)+" Points | "+Get_Price_s(TP_HL));
   update_Text(REC3,"Buy Stop @ "+Get_Price_s(PR_HL));

   update_Text(REC5,"SL: "+ DoubleToString(((Get_Price_d(PR_HL)-Get_Price_d(SL_HL))/_Point),0)+" Points | "+Get_Price_s(SL_HL));
   
   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,true);
   ChartRedraw(0);
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   deleteObjects();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
      
  }
//+------------------------------------------------------------------+

int prevMouseState = 0;

int mlbDownX1 = 0;
int mlbDownY1 = 0;
int mlbDownXD_R1 = 0;
int mlbDownYD_R1 = 0;

int mlbDownX2 = 0;
int mlbDownY2 = 0;
int mlbDownXD_R2 = 0;
int mlbDownYD_R2 = 0;

int mlbDownX3 = 0;
int mlbDownY3 = 0;
int mlbDownXD_R3 = 0;
int mlbDownYD_R3 = 0;

int mlbDownX4 = 0;
int mlbDownY4 = 0;
int mlbDownXD_R4 = 0;
int mlbDownYD_R4 = 0;

int mlbDownX5 = 0;
int mlbDownY5 = 0;
int mlbDownXD_R5 = 0;
int mlbDownYD_R5 = 0;

bool movingState_R1 = false;
bool movingState_R3 = false;
bool movingState_R5 = false;

void OnChartEvent(const int id,         // Identifikator des Ereignisses    
                  const long& lparam,   // Parameter des Ereignisses des Typs long, X cordinates 
                  const double& dparam, // Parameter des Ereignisses des Typs double, Y cordinates 
                  const string& sparam  // Parameter des Ereignisses des Typs string, name of the object, state
                  )
{
       if (id==CHARTEVENT_MOUSE_MOVE)
         {
            int MouseD_X = (int)lparam;
            int MouseD_Y = (int)dparam;
            int MouseState = (int)sparam;
            
            int XD_R1 = (int)ObjectGetInteger(0,REC1,OBJPROP_XDISTANCE);
            int YD_R1 = (int)ObjectGetInteger(0,REC1,OBJPROP_YDISTANCE);
            int XS_R1 = (int)ObjectGetInteger(0,REC1,OBJPROP_XSIZE);
            int YS_R1 = (int)ObjectGetInteger(0,REC1,OBJPROP_YSIZE);
            
            int XD_R3 = (int)ObjectGetInteger(0,REC3,OBJPROP_XDISTANCE);
            int YD_R3 = (int)ObjectGetInteger(0,REC3,OBJPROP_YDISTANCE);
            int XS_R3 = (int)ObjectGetInteger(0,REC3,OBJPROP_XSIZE);
            int YS_R3 = (int)ObjectGetInteger(0,REC3,OBJPROP_YSIZE);
            
            int XD_R5 = (int)ObjectGetInteger(0,REC5,OBJPROP_XDISTANCE);
            int YD_R5 = (int)ObjectGetInteger(0,REC5,OBJPROP_YDISTANCE);
            int XS_R5 = (int)ObjectGetInteger(0,REC5,OBJPROP_XSIZE);
            int YS_R5 = (int)ObjectGetInteger(0,REC5,OBJPROP_YSIZE);
                      
            if (prevMouseState == 0 && MouseState == 1) //1 = true: clicked left mouse btn
            {
               mlbDownX1 = MouseD_X;
               mlbDownY1 = MouseD_Y;
               mlbDownXD_R1 = XD_R1;
               mlbDownYD_R1 = YD_R1;
               
               mlbDownX3 = MouseD_X;
               mlbDownY3 = MouseD_Y;
               mlbDownXD_R3 = XD_R3;
               mlbDownYD_R3 = YD_R3;
               
               mlbDownX5 = MouseD_X;
               mlbDownY5 = MouseD_Y;
               mlbDownXD_R5 = XD_R5;
               mlbDownYD_R5 = YD_R5;
           
           if (MouseD_X >= XD_R1 && MouseD_X <= XD_R1+XS_R1 &&
               MouseD_Y >= YD_R1 && MouseD_Y <= YD_R1+YS_R1)
               {
                  movingState_R1 = true;
               }
            
            if (MouseD_X >= XD_R3 && MouseD_X <= XD_R3+XS_R3 &&
               MouseD_Y >= YD_R3 && MouseD_Y <= YD_R3+YS_R3)
               {
                  movingState_R3 = true;
               }
            
            if (MouseD_X >= XD_R5 && MouseD_X <= XD_R5+XS_R5 &&
               MouseD_Y >= YD_R5 && MouseD_Y <= YD_R5+YS_R5)
               {
                  movingState_R5 = true;
               }
            }
            
            if (movingState_R1 )
            {
               
               ChartSetInteger(0,CHART_MOUSE_SCROLL,false);
               
               ObjectSetInteger(0,REC1,OBJPROP_YDISTANCE,mlbDownYD_R1 + MouseD_Y - mlbDownY1);
               ObjectSetInteger(0,REC5,OBJPROP_YDISTANCE,mlbDownYD_R5 - MouseD_Y + mlbDownY1);
                              
               datetime dt_TP=0;
               double price_TP=0;
               int window = 0;
               
               ChartXYToTimePrice(0,XD_R1,YD_R1+YS_R1,window,dt_TP,price_TP);
               ObjectSetInteger(0,TP_HL,OBJPROP_TIME,dt_TP);
               ObjectSetDouble(0,TP_HL,OBJPROP_PRICE,price_TP);
               
               datetime dt_SL=0;
               double price_SL=0;               

               ChartXYToTimePrice(0,XD_R5,YD_R5+YS_R5,window,dt_SL,price_SL);
               ObjectSetInteger(0,SL_HL,OBJPROP_TIME,dt_SL);
               ObjectSetDouble(0,SL_HL,OBJPROP_PRICE,price_SL);
               
               update_Text(REC1,"TP: "+ DoubleToString(((Get_Price_d(TP_HL)-Get_Price_d(PR_HL))/_Point),0)+" Points | "+Get_Price_s(TP_HL));
               update_Text(REC5,"SL: "+ DoubleToString(((Get_Price_d(PR_HL)-Get_Price_d(SL_HL))/_Point),0)+" Points | "+Get_Price_s(SL_HL));
               
               if ((Get_Price_s(SL_HL)) > (Get_Price_s(TP_HL)))
                  {
                     update_Text(REC3,"Sell Stop @ "+Get_Price_s(PR_HL));
                     update_Text(REC1,"TP: "+ DoubleToString(((Get_Price_d(PR_HL)-Get_Price_d(TP_HL))/_Point),0)+" Points | "+Get_Price_s(TP_HL));
                     update_Text(REC5,"SL: "+ DoubleToString(((Get_Price_d(SL_HL)-Get_Price_d(PR_HL))/_Point),0)+" Points | "+Get_Price_s(SL_HL));                   
                  
                  }
               else  
                     update_Text(REC3,"Buy Stop @ "+Get_Price_s(PR_HL));
                    
               ChartRedraw(0);
            }
            
            if (movingState_R5 )
            {
               ChartSetInteger(0,CHART_MOUSE_SCROLL,false);
               
               ObjectSetInteger(0,REC5,OBJPROP_YDISTANCE,mlbDownYD_R5 + MouseD_Y - mlbDownY5);
               ObjectSetInteger(0,REC1,OBJPROP_YDISTANCE,mlbDownYD_R1 - MouseD_Y + mlbDownY5);
               
               datetime dt_SL=0;
               double price_SL=0;
               int window = 0;
               
               ChartXYToTimePrice(0,XD_R5,YD_R5+YS_R5,window,dt_SL,price_SL);
               ObjectSetInteger(0,SL_HL,OBJPROP_TIME,dt_SL);
               ObjectSetDouble(0,SL_HL,OBJPROP_PRICE,price_SL);
               
               datetime dt_TP=0;
               double price_TP=0;
               
               ChartXYToTimePrice(0,XD_R1,YD_R1+YS_R1,window,dt_TP,price_TP);
               ObjectSetInteger(0,TP_HL,OBJPROP_TIME,dt_TP);
               ObjectSetDouble(0,TP_HL,OBJPROP_PRICE,price_TP);
               
               update_Text(REC1,"TP: "+ DoubleToString(((Get_Price_d(TP_HL)-Get_Price_d(PR_HL))/_Point),0)+" Points | "+Get_Price_s(TP_HL));
               update_Text(REC5,"SL: "+ DoubleToString(((Get_Price_d(PR_HL)-Get_Price_d(SL_HL))/_Point),0)+" Points | "+Get_Price_s(SL_HL));
               
               if ((Get_Price_s(SL_HL)) > (Get_Price_s(TP_HL)))
                  {
                     update_Text(REC3,"Sell Stop @ "+Get_Price_s(PR_HL));
                     update_Text(REC1,"TP: "+ DoubleToString(((Get_Price_d(PR_HL)-Get_Price_d(TP_HL))/_Point),0)+" Points | "+Get_Price_s(TP_HL));
                     update_Text(REC5,"SL: "+ DoubleToString(((Get_Price_d(SL_HL)-Get_Price_d(PR_HL))/_Point),0)+" Points | "+Get_Price_s(SL_HL));                   
                  
                  }
               else  
                     update_Text(REC3,"Buy Stop @ "+Get_Price_s(PR_HL));
               
               ChartRedraw(0);
            }

            if (movingState_R3)
            {
               ChartSetInteger(0,CHART_MOUSE_SCROLL,false);
               
               ObjectSetInteger(0,REC3,OBJPROP_YDISTANCE,mlbDownYD_R3 + MouseD_Y -mlbDownY3);
               
               ObjectSetInteger(0,REC1,OBJPROP_YDISTANCE,mlbDownYD_R1 + MouseD_Y -mlbDownY1);

               ObjectSetInteger(0,REC5,OBJPROP_YDISTANCE,mlbDownYD_R5 + MouseD_Y -mlbDownY5);

               datetime dt_PRC=0,dt_SL1=0,dt_TP1=0;
               double price_PRC=0,price_SL1=0,price_TP1=0;
               int window = 0;
               
               ChartXYToTimePrice(0,XD_R3,YD_R3+YS_R3,window,dt_PRC,price_PRC);
               ChartXYToTimePrice(0,XD_R5,YD_R5+YS_R5,window,dt_SL1,price_SL1);
               ChartXYToTimePrice(0,XD_R1,YD_R1+YS_R1,window,dt_TP1,price_TP1);

               ObjectSetInteger(0,PR_HL,OBJPROP_TIME,dt_PRC);
               ObjectSetDouble(0,PR_HL,OBJPROP_PRICE,price_PRC);
               
               ObjectSetInteger(0,TP_HL,OBJPROP_TIME,dt_TP1);
               ObjectSetDouble(0,TP_HL,OBJPROP_PRICE,price_TP1);

               ObjectSetInteger(0,SL_HL,OBJPROP_TIME,dt_SL1);
               ObjectSetDouble(0,SL_HL,OBJPROP_PRICE,price_SL1);
               
               update_Text(REC1,"TP: "+DoubleToString(((Get_Price_d(TP_HL)-Get_Price_d(PR_HL))/_Point),0)+" Points | "+Get_Price_s(TP_HL)); //nicht geprüft

               if ((Get_Price_s(SL_HL)) > (Get_Price_s(TP_HL)))
                  {
                     update_Text(REC3,"Sell Stop @ "+Get_Price_s(PR_HL));               
                  }
               else
                  
               update_Text(REC3,"Buy Stop @ "+Get_Price_s(PR_HL));

               update_Text(REC5,"SL: "+ DoubleToString(((Get_Price_d(PR_HL)-Get_Price_d(SL_HL))/_Point),0)+" Points | "+Get_Price_s(SL_HL));//nicht geprüft
              
               ChartRedraw(0);
            }            
            if (MouseState == 0)
            {
               movingState_R1 = false;
               movingState_R3 = false;
               movingState_R5 = false;
               ChartSetInteger(0,CHART_MOUSE_SCROLL,true);
            }
            prevMouseState = MouseState;
         }  
        
             if(ObjectGetInteger(0,"Button1",OBJPROP_STATE)!=0)
              {
                  ObjectSetInteger(0,"Button1",OBJPROP_STATE,0);
                  Print("Eigenschaften öffnen");
                  return;
               
               // Öffnen/Schließen der Eingabemaske
               Print("Eigenschaften öffnen");
//               showInputBox = !showInputBox;
 //              inputBox.Visible(showInputBox);
              }        
        
         
         //Klick Button Send only
         if(ObjectGetInteger(0,"Button2",OBJPROP_STATE)!=0)
            {
               ObjectSetInteger(0,"Button2",OBJPROP_STATE,0);
//               ObjectSetInteger(0,"Button2", OBJPROP_BGCOLOR,clrDarkOrange);
               Print("senden an Discord");
//               string params=("{"content":"" + msgName + "","tts":false,"embeds":[{"title":"" + msgTitle + "","description":"" + message + ""}]}");

               return;
            }
            
            //Klick Button Trade & Send
            if(ObjectGetInteger(0,"Button3",OBJPROP_STATE)!=0)
            {
               ObjectSetInteger(0,"Button3",OBJPROP_STATE,0);
//             Discord-Befehl          string params=("{"content":"" + msgName + "","tts":false,"embeds":[{"title":"" + msgTitle + "","description":"" + message + ""}]}");
 //              return;
               
               double Entry_Price = StringToDouble(Get_Price_s(PR_HL));
               double TP_Price = StringToDouble(Get_Price_s(TP_HL));
               double SL_Price = StringToDouble(Get_Price_s(SL_HL));
               Entry_Price = NormalizeDouble(Entry_Price,_Digits);
               TP_Price = NormalizeDouble(TP_Price,_Digits);
               SL_Price = NormalizeDouble(SL_Price,_Digits);
               
               double SL_Points = (Entry_Price - SL_Price)/_Point;
               SL_Points = NormalizeDouble(SL_Points,_Digits);

               //Buy Stop
  
               if(PositionsTotal()==0 && OrdersTotal()==0)
                  {
                     double lots = calcLots(Entry_Price - SL_Price);
                     trade.BuyStop(lots,Entry_Price,_Symbol,SL_Price,TP_Price,ORDER_TIME_GTC);
//                   Discord-Befehl          string params=("{"content":"" + msgName + "","tts":false,"embeds":[{"title":"" + msgTitle + "","description":"" + message + ""}]}");
                     return;
                  }
                     
                  else
                  {
                     Print(__FUNCTION__,"Order vorhanden");
                       
                     Print("Order vorhanden");
                     return;
                  }
                  
                       
               //Sell Stop
               if(PositionsTotal()==0 && OrdersTotal()==0)

//                  if (ORDER_TYPE_SELL_STOP < 1)

                  {
                     double lots = calcLots(SL_Price - Entry_Price);
                     trade.SellStop(lots,Entry_Price,_Symbol,SL_Price,TP_Price,ORDER_TIME_GTC);
                     Print("Sell Order öffnen");
                     return;
                  }
                  else
                  {
                     Print(__FUNCTION__,"Order vorhanden");
                       
                     Print("Order vorhanden");
                     return;
                  }
           }     
                
}

             double calcLots(double slDistance)
               {
                  double ticksize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
                  double tickvalue = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
                  double lotstep = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
                  
                  if (ticksize == 0 || tickvalue == 0 || lotstep == 0)
                     {
                        Print(__FUNCTION__,"> Lotsize cannot be calculated");
                        return 0;
                     }
            
                  double riskMoney = AccountInfoDouble(ACCOUNT_EQUITY) * DefaultRisk / 100;
                  double moneyLotstep = (slDistance / ticksize) * tickvalue * lotstep;
                  if(moneyLotstep == 0)
                     {
                        Print(__FUNCTION__,"> Lotsize cannot be calculated");
                        return 0;
                     }
                  double lots = MathFloor(riskMoney/moneyLotstep) * lotstep;
                  lots = NormalizeDouble(lots,2);
                  Print(lots);
                       
                  return lots;
               }         
 
bool createButton(string objName,string text,int xD,int yD,int xS,int yS,color clrTxt,color clrBG,int fontsize=12,color clrBorder=clrNONE,string font="Calibri")
   {
      ResetLastError();
      if (!ObjectCreate(0,objName,OBJ_BUTTON,0,0,0))
      {
         Print(__FUNCTION__,": Failed to create Btn: Error Code: ", GetLastError());
         return (false);
      }
      ObjectSetInteger(0,objName,OBJPROP_XDISTANCE,xD);
      ObjectSetInteger(0,objName,OBJPROP_YDISTANCE,yD);
      ObjectSetInteger(0,objName,OBJPROP_XSIZE,xS);
      ObjectSetInteger(0,objName,OBJPROP_YSIZE,yS);
      ObjectSetInteger(0,objName,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetString(0,objName,OBJPROP_TEXT,text);
      ObjectSetInteger(0,objName,OBJPROP_FONTSIZE,fontsize);
      ObjectSetString(0,objName,OBJPROP_FONT,font);
      ObjectSetInteger(0,objName,OBJPROP_COLOR,clrTxt);
      ObjectSetInteger(0,objName,OBJPROP_BGCOLOR,clrBG);
      ObjectSetInteger(0,objName,OBJPROP_BORDER_COLOR,clrBorder);
      ObjectSetInteger(0,objName,OBJPROP_BACK,false);
      ObjectSetInteger(0,objName,OBJPROP_STATE,false);
      ObjectSetInteger(0,objName,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,objName,OBJPROP_SELECTED,false);
      
      ChartRedraw(0);
      return (true);
    }
   
   bool createHL(string objName,datetime time1,double price1,color clr)
   {
      ResetLastError();
      if (!ObjectCreate(0,objName,OBJ_HLINE,0,time1,price1))
      {
         Print(__FUNCTION__,": Failed to create HL: Error Code: ", GetLastError());
         return (false);
      }
      ObjectSetInteger(0,objName,OBJPROP_TIME,time1);
      ObjectSetDouble(0,objName,OBJPROP_PRICE,price1);
      ObjectSetInteger(0,objName,OBJPROP_COLOR,clr);
      ObjectSetInteger(0,objName,OBJPROP_BACK,false);
      ObjectSetInteger(0,objName,OBJPROP_STYLE,STYLE_SOLID);
      
      ChartRedraw(0);
      return (true);
   }
   
   void deleteObjects()
  {
   ObjectDelete(0,REC1);
   ObjectDelete(0,REC3);
   ObjectDelete(0,REC5);
   ObjectDelete(0,TP_HL);
   ObjectDelete(0,SL_HL);
   ObjectDelete(0,PR_HL);
   ObjectDelete(0,"Button1");
   ObjectDelete(0,"Button2");
   ObjectDelete(0,"Button3");
   
   ChartRedraw(0);
  }
  
  
  
  
  
  
  
/*
//+------------------------------------------------------------------+
//| Die Funktion erhÃƒÂ¤lt den Wert der HÃƒÂ¶he des Charts in Pixeln       |
//+------------------------------------------------------------------+
int ChartHeightInPixelsGet(const long chartID = 0, const int subwindow = 0)
{
   //--- Bereiten wir eine Variable, um den Wert der Eigenschaft zu erhalten
   long result = -1;
   //--- Setzen den Wert des Fehlers zurÃƒÂ¼ck
   ResetLastError();
   //--- Erhalten wir den Wert der Eigenschaft
   if (!ChartGetInteger(chartID, CHARTHEIGHT_IN_PIXELS, sub_window, result))
   {
      //--- Schreiben die Fehlermeldung in den Log "Experten"
      Print(__FUNCTION + ", Error Code = ", GetLastError());
   }
   //--- Geben den Wert der Eigenschaft zurÃƒÂ¼ck
   return ((int)result);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Die Funktion erhÃƒÂ¤lt den Wert der Breite des Charts in Pixeln     |
//+------------------------------------------------------------------+
int ChartWidthInPixels(const long chart_ID = 0)
{
   //--- Bereiten wir eine Variable, um den Wert der Eigenschaft zu erhalten
   long result = -1;
   //--- Setzen den Wert des Fehlers zurÃƒÂ¼ck
   ResetLastError();
   //--- Erhalten wir den Wert der Eigenschaft
   if (!ChartGetInteger(chart_ID, CHART_WIDTH_IN_PIXELS, 0, result))
   {
      //--- Schreiben die Fehlermeldung in den Log "Experten"
      Print(__FUNCTION + ", Error Code = ", GetLastError());
   }
   //--- Geben den Wert der Eigenschaft zurÃƒÂ¼ck
   return ((int)result);
}
int rechterxwert = ChartWidthInPixels(0) - breite_button - 20;
   int ywertmitte = ChartHeightInPixelsGet(0) / 2;

   createButton(REC1,"",rechterxwert,ywertmitte,400,30,clrWhite,clrGreen,13,clrWhite,"Arial Black");
CHARTEVENT_CHART_CHANGE 