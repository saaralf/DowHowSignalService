//+------------------------------------------------------------------+
//|                                        Trade Assistent V1.20.mq5 |
//|                                 Michael Keller, Steffen Kachold |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Michael Keller, Steffen Kachold"
#property link ""
#property version "1.20"

//#include <GetOrderandPosition V1_11.mqh>
#include "methoden.mqh" // Funktionen/Methoden ausgelagert in eine eigene Datei
#include "discord_1.01.mqh" // alles rund ums senden an Discord

#include <Trade\Trade.mqh>
CTrade trade;
CPositionInfo PositionInfo;
COrderInfo OrderInfo;

// Default values for settings:
double EntryLevel = 0;
double StopLossLevel = 0;
double TakeProfitLevel = 0;
double StopPriceLevel = 0;

// Button1 = input parameters for Trade & Send = Send only
// Button2 = Send only
// Button3 = Trade & Send
// only one button is visible

input group "=====Trading Button=====" 
input color Button1_bgcolor = clrRed;                             // Label Please check settings      Color 
input color Button1_font_color = clrWhite;                        // Label Please check settings      Font Color 
input uint Button1_font_size = 15;                                // Label Please check settings      Font Size 
input color Button2_bgcolor = clrForestGreen;                     // Button Send only                   Color 
input color Button2_font_color = clrWhite;                        // Button Send only                   Font Color 
input uint Button2_font_size = 10;                                // Button Send only                   Font Size 
input color Button3_bgcolor = clrGray;                            // Button Trade & Send              Color 
input color Button3_font_color = clrRed;                          // Button Trade & Send              Font Color 
input uint Button3_font_size = 10;                                // Button Trade & Send              Font Size 
input group "=====Message Button====="
input color ButtonTargetReached_bgcolor = clrGreen;                // Button Target Reached           Color 
input color ButtonTargetReached_font_color = clrWhite;             // Button Target Reached           Font Color 
input uint ButtonTargetReached_font_size = 10;                    // Button Target Reached            Font Size 
input int ButtonTargetReached_XPosition = 400;                     // Button Target Reached           X-Position
input int ButtonTargetReached_YPosition = 100;                     // Button Target Reached           Y-Position
input int ButtonTargetReached_length = 200;                         // Button Target Reached           Lenght
input int ButtonTargetReached_high = 30;                             //Buttton Target Reached          High
input color ButtonStoppedout_bgcolor = clrRed;                    // Button Stopped out                Color 
input color ButtonStoppedout_font_color = clrWhite;               // Button Stopped out                Font Color
input uint ButtonStoppedout_font_size = 10;                      // Button Stopped out                Font Size 
input int ButtonStoppedout_XPosition = 400;                     // Button Stopped out           X-Position
input int ButtonStoppedout_YPosition = 100;                     // Button Stopped out           Y-Position
input int ButtonStoppedout_length = 200;                         // Button Stopped out                Lenght
input int ButtonStoppedout_high = 30;                             //Buttton Stopped out               High
input color ButtonCancelOrder_bgcolor = clrWhite;                // Button Cancel Order            Color 
input color ButtonCancelOrder_font_color = clrBlack;             // Button Cancel Order            Font Color 
input uint ButtonCancelOrder_font_size = 10;                    // Button Cancel Order             Font Size 
input int ButtonCancelOrder_XPosition = 400;                     // Button Cancel Order           X-Position
input int ButtonCancelOrder_YPosition = 100;                     // Button Cancel Order           Y-Position
input int ButtonCancelOrder_length = 200;                         // Button Cancel Order            Lenght
input int ButtonCancelOrder_high = 30;                             //Buttton Cancel Order           High


input group "=====Defaults====="                                  
input int SetXDistance = 1000;                                    // Trading Button X-Distance from Left
input bool Button2 = true; // Send only
input bool Button3 = false;    // Trade & Send
input double DefaultRisk = 0.5; // Risk in %

bool CheckForExistingLongPosition();

#define REC1 "REC1"
#define REC3 "REC3"
#define REC5 "REC5"
#define BTN1 "Button1"
#define BTN2 "Button2"
#define BTN3 "Button3"
#define TP_HL "TP_HL"
#define SL_HL "SL_HL"
#define PR_HL "PR_HL"

// string otype = "";

bool isBuy=1;

int
xd1,
yd1, xs1, ys1,
xd2, yd2, xs2, ys2,
xd3, yd3, xs3, ys3,
xd4, yd4, xs4, ys4,
xd5, yd5, xs5, ys5;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OTotal = OrdersTotal();
int PTotal = PositionsTotal();

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//Init und Test Discord Api
checkDiscord();
MessageButton();

   createButton(REC1, "", SetXDistance, 500, 350, 30, clrWhite, clrGreen, 13, clrGreen, "Arial Black");
// TP Button
   xd1 = (int)ObjectGetInteger(0, REC1, OBJPROP_XDISTANCE);
   yd1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YDISTANCE);
   xs1 = (int)ObjectGetInteger(0, REC1, OBJPROP_XSIZE);
   ys1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YSIZE);

// Button at price
   xd3 = xd1;
   yd3 = yd1 + (100);
   xs3 = xs1;
   ys3 = 30;

// SL Button
   xd5 = xd1;
   yd5 = yd3 + 100;
   xs5 = xs1;
   ys5 = 30;

SendButton();

   datetime dt_tp = 0, dt_sl = 0, dt_prc = 0;
   double price_tp = 0, price_sl = 0, price_prc = 0;
   int window = 0;

   ChartXYToTimePrice(0, xd1, yd1 + ys1, window, dt_tp, price_tp);
   ChartXYToTimePrice(0, xd3, yd3 + ys3, window, dt_prc, price_prc);
   ChartXYToTimePrice(0, xd5, yd5 + ys5, window, dt_sl, price_sl);

   createHL(TP_HL, dt_tp, price_tp, clrLime);
   createHL(PR_HL, dt_prc, price_prc, clrAqua);
   createHL(SL_HL, dt_sl, price_sl, clrWhite);

   createButton(REC3, "", xd3, yd3, xs3, ys3, clrBlack, clrAqua, 12, clrNONE, "Arial Black");
   createButton(REC5, "", xd5, yd5, xs5, ys5, clrWhite, clrRed, 13, clrNONE, "Arial Black");

   update_Text(REC1, "TP: " + DoubleToString(((Get_Price_d(TP_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
   update_Text(REC3, "Buy Stop @ " + Get_Price_s(PR_HL));
   update_Text(REC5, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   ChartRedraw(0);

   return (INIT_SUCCEEDED);
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // Identifikator des Ereignisses
                  const long &lparam,   // Parameter des Ereignisses des Typs long, X cordinates
                  const double &dparam, // Parameter des Ereignisses des Typs double, Y cordinates
                  const string &sparam)  // Parameter des Ereignisses des Typs string, name of the object, state

  {
   if(id == CHARTEVENT_MOUSE_MOVE)
     {
      int MouseD_X = (int)lparam;
      int MouseD_Y = (int)dparam;
      int MouseState = (int)sparam;

      int XD_R1 = (int)ObjectGetInteger(0, REC1, OBJPROP_XDISTANCE);
      int YD_R1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YDISTANCE);
      int XS_R1 = (int)ObjectGetInteger(0, REC1, OBJPROP_XSIZE);
      int YS_R1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YSIZE);

      int XD_R3 = (int)ObjectGetInteger(0, REC3, OBJPROP_XDISTANCE);
      int YD_R3 = (int)ObjectGetInteger(0, REC3, OBJPROP_YDISTANCE);
      int XS_R3 = (int)ObjectGetInteger(0, REC3, OBJPROP_XSIZE);
      int YS_R3 = (int)ObjectGetInteger(0, REC3, OBJPROP_YSIZE);

      int XD_R5 = (int)ObjectGetInteger(0, REC5, OBJPROP_XDISTANCE);
      int YD_R5 = (int)ObjectGetInteger(0, REC5, OBJPROP_YDISTANCE);
      int XS_R5 = (int)ObjectGetInteger(0, REC5, OBJPROP_XSIZE);
      int YS_R5 = (int)ObjectGetInteger(0, REC5, OBJPROP_YSIZE);

      if(prevMouseState == 0 && MouseState == 1)  // 1 = true: clicked left mouse btn
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

         if(MouseD_X >= XD_R1 && MouseD_X <= XD_R1 + XS_R1 &&
            MouseD_Y >= YD_R1 && MouseD_Y <= YD_R1 + YS_R1)
           {
            movingState_R1 = true;
           }

         if(MouseD_X >= XD_R3 && MouseD_X <= XD_R3 + XS_R3 &&
            MouseD_Y >= YD_R3 && MouseD_Y <= YD_R3 + YS_R3)
           {
            movingState_R3 = true;
           }

         if(MouseD_X >= XD_R5 && MouseD_X <= XD_R5 + XS_R5 &&
            MouseD_Y >= YD_R5 && MouseD_Y <= YD_R5 + YS_R5)
           {
            movingState_R5 = true;
           }
        }

      if(movingState_R1)
        {

         ChartSetInteger(0, CHART_MOUSE_SCROLL, false);

         ObjectSetInteger(0, REC1, OBJPROP_YDISTANCE, mlbDownYD_R1 + MouseD_Y - mlbDownY1);
         ObjectSetInteger(0, REC5, OBJPROP_YDISTANCE, mlbDownYD_R5 - MouseD_Y + mlbDownY1);

         datetime dt_TP = 0;
         double price_TP = 0;
         int window = 0;

         ChartXYToTimePrice(0, XD_R1, YD_R1 + YS_R1, window, dt_TP, price_TP);
         ObjectSetInteger(0, TP_HL, OBJPROP_TIME, dt_TP);
         ObjectSetDouble(0, TP_HL, OBJPROP_PRICE, price_TP);

         datetime dt_SL = 0;
         double price_SL = 0;

         ChartXYToTimePrice(0, XD_R5, YD_R5 + YS_R5, window, dt_SL, price_SL);
         ObjectSetInteger(0, SL_HL, OBJPROP_TIME, dt_SL);
         ObjectSetDouble(0, SL_HL, OBJPROP_PRICE, price_SL);

         update_Text(REC1, "TP: " + DoubleToString(((Get_Price_d(TP_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
         update_Text(REC5, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

         if((Get_Price_s(SL_HL)) > (Get_Price_s(TP_HL)))
           {
            isBuy=0;
            update_Text(REC3, "Sell Stop @ " + Get_Price_s(PR_HL));
            update_Text(REC1, "TP: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(TP_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
            update_Text(REC5, "SL: " + DoubleToString(((Get_Price_d(SL_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));
           }
         else
           {
            update_Text(REC3, "Buy Stop @ " + Get_Price_s(PR_HL));
            isBuy=1;
           }

         ChartRedraw(0);
        }

      if(movingState_R5)
        {
         ChartSetInteger(0, CHART_MOUSE_SCROLL, false);

         ObjectSetInteger(0, REC5, OBJPROP_YDISTANCE, mlbDownYD_R5 + MouseD_Y - mlbDownY5);
         ObjectSetInteger(0, REC1, OBJPROP_YDISTANCE, mlbDownYD_R1 - MouseD_Y + mlbDownY5);

         datetime dt_SL = 0;
         double price_SL = 0;
         int window = 0;

         ChartXYToTimePrice(0, XD_R5, YD_R5 + YS_R5, window, dt_SL, price_SL);
         ObjectSetInteger(0, SL_HL, OBJPROP_TIME, dt_SL);
         ObjectSetDouble(0, SL_HL, OBJPROP_PRICE, price_SL);

         datetime dt_TP = 0;
         double price_TP = 0;

         ChartXYToTimePrice(0, XD_R1, YD_R1 + YS_R1, window, dt_TP, price_TP);
         ObjectSetInteger(0, TP_HL, OBJPROP_TIME, dt_TP);
         ObjectSetDouble(0, TP_HL, OBJPROP_PRICE, price_TP);

         update_Text(REC1, "TP: " + DoubleToString(((Get_Price_d(TP_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
         update_Text(REC5, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

         if((Get_Price_s(SL_HL)) > (Get_Price_s(TP_HL)))
           {
            isBuy=0;
            update_Text(REC3, "Sell Stop @ " + Get_Price_s(PR_HL));
            update_Text(REC1, "TP: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(TP_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
            update_Text(REC5, "SL: " + DoubleToString(((Get_Price_d(SL_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));
           }
         else
           {
            update_Text(REC3, "Buy Stop @ " + Get_Price_s(PR_HL));
            isBuy=1;
           }

         ChartRedraw(0);
        }

      if(movingState_R3)
        {
         ChartSetInteger(0, CHART_MOUSE_SCROLL, false);

         ObjectSetInteger(0, REC3, OBJPROP_YDISTANCE, mlbDownYD_R3 + MouseD_Y - mlbDownY3);

         ObjectSetInteger(0, REC1, OBJPROP_YDISTANCE, mlbDownYD_R1 + MouseD_Y - mlbDownY1);

         ObjectSetInteger(0, REC5, OBJPROP_YDISTANCE, mlbDownYD_R5 + MouseD_Y - mlbDownY5);

         ObjectSetInteger(0, BTN2, OBJPROP_YDISTANCE, mlbDownYD_R3 + MouseD_Y - mlbDownY3);
         ObjectSetInteger(0, BTN3, OBJPROP_YDISTANCE, mlbDownYD_R3 + MouseD_Y - mlbDownY3);


         datetime dt_PRC = 0, dt_SL1 = 0, dt_TP1 = 0;
         double price_PRC = 0, price_SL1 = 0, price_TP1 = 0;
         int window = 0;

         ChartXYToTimePrice(0, XD_R3, YD_R3 + YS_R3, window, dt_PRC, price_PRC);

         ChartXYToTimePrice(0, XD_R3, YD_R3 + YS_R3, window, dt_PRC, price_PRC);

         ChartXYToTimePrice(0, XD_R5, YD_R5 + YS_R5, window, dt_SL1, price_SL1);
         ChartXYToTimePrice(0, XD_R1, YD_R1 + YS_R1, window, dt_TP1, price_TP1);

         ObjectSetInteger(0, PR_HL, OBJPROP_TIME, dt_PRC);
         ObjectSetDouble(0, PR_HL, OBJPROP_PRICE, price_PRC);

         ObjectSetInteger(0, TP_HL, OBJPROP_TIME, dt_TP1);
         ObjectSetDouble(0, TP_HL, OBJPROP_PRICE, price_TP1);

         ObjectSetInteger(0, SL_HL, OBJPROP_TIME, dt_SL1);
         ObjectSetDouble(0, SL_HL, OBJPROP_PRICE, price_SL1);

         update_Text(REC1, "TP: " + DoubleToString(((Get_Price_d(TP_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));

         if((Get_Price_s(SL_HL)) > (Get_Price_s(TP_HL)))
           {
            update_Text(REC3, "Sell Stop @ " + Get_Price_s(PR_HL));
            isBuy=0;
           }
         else
           {
            update_Text(REC3, "Buy Stop @ " + Get_Price_s(PR_HL));
            isBuy=1;
           }
         update_Text(REC5, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

         ChartRedraw(0);
        }
      if(MouseState == 0)
        {
         movingState_R1 = false;
         movingState_R3 = false;
         movingState_R5 = false;
         ChartSetInteger(0, CHART_MOUSE_SCROLL, true);
        }
      prevMouseState = MouseState;
     }

   if(ObjectGetInteger(0, "Button1", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "Button1", OBJPROP_STATE, 0);
      return;
     }

// Klick Button Send only

   if(ObjectGetInteger(0, "Button2", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "Button2", OBJPROP_STATE, 0);

      double Entry_Price = StringToDouble(Get_Price_s(PR_HL));
      double TP_Price = StringToDouble(Get_Price_s(TP_HL));
      double SL_Price = StringToDouble(Get_Price_s(SL_HL));
      TradeInfo tradeInfo;
      tradeInfo.tradenummer=++tradeInfo.tradenummer;
      tradeInfo.symbol = _Symbol;
      tradeInfo.type = isBuy ? "BUY" : "SELL";
      tradeInfo.price = Entry_Price;
//      tradeInfo.lots = 0.01;
      tradeInfo.sl = SL_Price;
      tradeInfo.tp = TP_Price;


// Send notification before placing trade
   string message = FormatTradeMessage(tradeInfo);
   bool ret= SendDiscordMessage(message);
   
//Todo: Zähler Messages to Discord 

      return;
     }

// Klick Button Trade & Send
   if(ObjectGetInteger(0, "Button3", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "Button3", OBJPROP_STATE, 0);

      double Entry_Price = StringToDouble(Get_Price_s(PR_HL));
      double TP_Price = StringToDouble(Get_Price_s(TP_HL));
      double SL_Price = StringToDouble(Get_Price_s(SL_HL));
      Entry_Price = NormalizeDouble(Entry_Price, _Digits);
      TP_Price = NormalizeDouble(TP_Price, _Digits);
      SL_Price = NormalizeDouble(SL_Price, _Digits);

      TradeInfo tradeInfo;
      tradeInfo.tradenummer=++tradeInfo.tradenummer;
      tradeInfo.symbol = _Symbol;
      tradeInfo.type = isBuy ? "BUY" : "SELL";
      tradeInfo.price = Entry_Price;
//      tradeInfo.lots = 0.01;
      tradeInfo.sl = SL_Price;
      tradeInfo.tp = TP_Price;
      
   // Send notification before placing trade
      string message = FormatTradeMessage(tradeInfo);
      bool ret= SendDiscordMessage(message);
      
   //Todo: Zähler Messages to Discord 

      double SL_Points = (Entry_Price - SL_Price) / _Point;
      SL_Points = NormalizeDouble(SL_Points, _Digits);

      string REC3Text = ObjectGetString(0,REC3,OBJPROP_TEXT);
      string REC3Text2 = StringSubstr(REC3Text,0,3);
      
   OrderProperties();
//   Print(type);      

      /*     if (PositionsTotal() != 0 || OrdersTotal() != 1)
               {
                  OpenPositionOrOrder();

                  if (otype = "Buy Stop")// || (ptype = "Buy"))
                     {
                        Alert("Buy Stop Order vorhanden");
                     }
               }
               else
      */
      // Buy Stop

      if(REC3Text2 == "Buy")
        {
         double lots = calcLots(Entry_Price - SL_Price);
         trade.BuyStop(lots, Entry_Price, _Symbol, SL_Price, TP_Price, ORDER_TIME_GTC);

         return;
        }

      // Sell Stop

      if(REC3Text2 == "Sel")
        {
         double lots = calcLots(SL_Price - Entry_Price);
         trade.SellStop(lots, Entry_Price, _Symbol, SL_Price, TP_Price, ORDER_TIME_GTC);

         return;
        }
     }
     
 
   // Klick Message Buttons 
   if(ObjectGetInteger(0, "ButtonTargetReached", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_STATE, 0);
      

      TradeInfo tradeInfo;
      tradeInfo.tradenummer=++tradeInfo.tradenummer;
      tradeInfo.symbol = _Symbol;
      
   // Send notification before placing trade
      string message = FormatTradeMessage(tradeInfo);
      bool ret= SendDiscordMessage(message);
      Print("@everyone Note: Trade 44 (euro long) - Target reached");
  }

   if(ObjectGetInteger(0, "ButtonStoppedout", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_STATE, 0);
      

      TradeInfo tradeInfo;
      tradeInfo.tradenummer=++tradeInfo.tradenummer;
      tradeInfo.symbol = _Symbol;
      
   // Send notification before placing trade
      string message = FormatTradeMessage(tradeInfo);
      bool ret= SendDiscordMessage(message);
      Print("@everyone Note: Trade 42 (EUR long) has been stopped out");
  }

   if(ObjectGetInteger(0, "ButtonCancelOrder", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_STATE, 0);
      

      TradeInfo tradeInfo;
      tradeInfo.tradenummer=++tradeInfo.tradenummer;
      tradeInfo.symbol = _Symbol;
      
   // Send notification before placing trade
      string message = FormatTradeMessage(tradeInfo);
      bool ret= SendDiscordMessage(message);
      Print("@everyone Attention: Trade 37 (Cable short) - cancel the order cause trend was broken");
  }
  
  
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool createButton(string objName, string text, int xD, int yD, int xS, int yS, color clrTxt, color clrBG, int fontsize = 12, color clrBorder = clrNONE, string font = "Calibri")
  {
   ResetLastError();
   if(!ObjectCreate(0, objName, OBJ_BUTTON, 0, 0, 0))
     {
      Print(__FUNCTION__, ": Failed to create Btn: Error Code: ", GetLastError());
      return (false);
     }
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, xD);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, yD);
   ObjectSetInteger(0, objName, OBJPROP_XSIZE, xS);
   ObjectSetInteger(0, objName, OBJPROP_YSIZE, yS);
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, fontsize);
   ObjectSetString(0, objName, OBJPROP_FONT, font);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrTxt);
   ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, clrBG);
   ObjectSetInteger(0, objName, OBJPROP_BORDER_COLOR, clrBorder);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_STATE, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);

   ChartRedraw(0);
   return (true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool createHL(string objName, datetime time1, double price1, color clr)
  {
   ResetLastError();
   if(!ObjectCreate(0, objName, OBJ_HLINE, 0, time1, price1))
     {
      Print(__FUNCTION__, ": Failed to create HL: Error Code: ", GetLastError());
      return (false);
     }
   ObjectSetInteger(0, objName, OBJPROP_TIME, time1);
   ObjectSetDouble(0, objName, OBJPROP_PRICE, price1);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);

   ChartRedraw(0);
   return (true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void deleteObjects()
  {
   ObjectDelete(0, REC1);
   ObjectDelete(0, REC3);
   ObjectDelete(0, REC5);
   ObjectDelete(0, TP_HL);
   ObjectDelete(0, SL_HL);
   ObjectDelete(0, PR_HL);
   ObjectDelete(0, "Button1");
   ObjectDelete(0, "Button2");
   ObjectDelete(0, "Button3");
   ObjectDelete(0, "ButtonTargetReached");
   ObjectDelete(0, "ButtonStoppedout");
   ObjectDelete(0, "ButtonCancelOrder");

   ChartRedraw(0);
  }

void MessageButton()
   {
      ObjectCreate(0, "ButtonTargetReached", OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_XDISTANCE, ButtonTargetReached_XPosition);               // X position
      ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_XSIZE, ButtonTargetReached_length);                   // width
      ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_YDISTANCE, ButtonTargetReached_YPosition);                                      // Y position
      ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_YSIZE, ButtonTargetReached_high);                    // height
      ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_CORNER, 0);                    // chart corner
      ObjectSetString(0, "ButtonTargetReached", OBJPROP_TEXT, "Target Reached"); // label
      ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_BGCOLOR, ButtonTargetReached_bgcolor);
      ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_COLOR, ButtonTargetReached_font_color);
      ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_FONTSIZE, ButtonTargetReached_font_size);
      
      ObjectCreate(0, "ButtonStoppedout", OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_XDISTANCE, ButtonStoppedout_XPosition);               // X position
      ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_XSIZE, ButtonStoppedout_length);                   // width
      ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_YDISTANCE, ButtonStoppedout_YPosition);                // Y position
      ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_YSIZE, ButtonStoppedout_high);                    // height
      ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_CORNER, 0);                    // chart corner
      ObjectSetString(0, "ButtonStoppedout", OBJPROP_TEXT, "Trade Stopped Out"); // label
      ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_BGCOLOR, ButtonStoppedout_bgcolor);
      ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_COLOR, ButtonStoppedout_font_color);
      ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_FONTSIZE, ButtonStoppedout_font_size);

      ObjectCreate(0, "ButtonCancelOrder", OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_XDISTANCE, ButtonCancelOrder_XPosition);               // X position
      ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_XSIZE, ButtonCancelOrder_length);                   // width
      ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_YDISTANCE, ButtonCancelOrder_YPosition);                // Y position
      ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_YSIZE, ButtonCancelOrder_high);                    // height
      ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_CORNER, 0);                    // chart corner
      ObjectSetString(0, "ButtonCancelOrder", OBJPROP_TEXT, "Cancel Order"); // label
      ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_BGCOLOR, ButtonCancelOrder_bgcolor);
      ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_COLOR, ButtonCancelOrder_font_color);
      ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_FONTSIZE, ButtonCancelOrder_font_size);
   }

void SendButton()
   {
      if((Button2 == true && Button3 == true) || (Button2 == false && Button3 == false))
        {
         ObjectCreate(0, "Button1", OBJ_BUTTON, 0, 0, 0);
         ObjectSetInteger(0, "Button1", OBJPROP_XDISTANCE, 400);               // X position
         ObjectSetInteger(0, "Button1", OBJPROP_XSIZE, 300);                   // width
         ObjectSetInteger(0, "Button1", OBJPROP_YDISTANCE, 50);                // Y position
         ObjectSetInteger(0, "Button1", OBJPROP_YSIZE, 50);                    // height
         ObjectSetInteger(0, "Button1", OBJPROP_CORNER, 0);                    // chart corner
         ObjectSetString(0, "Button1", OBJPROP_TEXT, "Please check settings"); // label
         ObjectSetInteger(0, "Button1", OBJPROP_BGCOLOR, Button1_bgcolor);
         ObjectSetInteger(0, "Button1", OBJPROP_COLOR, Button1_font_color);
         ObjectSetInteger(0, "Button1", OBJPROP_FONTSIZE, Button1_font_size);
        }
      else
   
         if(Button2 == true && Button3 == false)
           {
            ObjectCreate(0, "Button2", OBJ_BUTTON, 0, 0, 0);
            ObjectSetInteger(0, "Button2", OBJPROP_XDISTANCE, xd3-100);   // X position
            ObjectSetInteger(0, "Button2", OBJPROP_XSIZE, 100);       // width
            ObjectSetInteger(0, "Button2", OBJPROP_YDISTANCE, yd3);    // Y position
            ObjectSetInteger(0, "Button2", OBJPROP_YSIZE, 30);        // height
            ObjectSetInteger(0, "Button2", OBJPROP_CORNER, 0);        // chart corner
            ObjectSetString(0, "Button2", OBJPROP_TEXT, "Send only"); // label
            ObjectSetInteger(0, "Button2", OBJPROP_COLOR, Button2_font_color);
            ObjectSetInteger(0, "Button2", OBJPROP_FONTSIZE, Button2_font_size);
            ObjectSetInteger(0, "Button2", OBJPROP_BGCOLOR, Button2_bgcolor);
           }
         else
   
            if(Button2 == false && Button3 == true)
              {
               ObjectCreate(0, "Button3", OBJ_BUTTON, 0, 0, 0);
               ObjectSetInteger(0, "Button3", OBJPROP_XDISTANCE, xd3-100);      // X position
               ObjectSetInteger(0, "Button3", OBJPROP_XSIZE, 100);          // width
               ObjectSetInteger(0, "Button3", OBJPROP_YDISTANCE, yd3);       // Y position
               ObjectSetInteger(0, "Button3", OBJPROP_YSIZE, 30);           // height
               ObjectSetInteger(0, "Button3", OBJPROP_CORNER, 0);           // chart corner
               ObjectSetString(0, "Button3", OBJPROP_TEXT, "T & S"); // label
               ObjectSetInteger(0, "Button3", OBJPROP_BGCOLOR, Button3_bgcolor);
               ObjectSetInteger(0, "Button3", OBJPROP_COLOR, Button3_font_color);
               ObjectSetInteger(0, "Button3", OBJPROP_FONTSIZE, Button3_font_size);
              }   
   }
   
void OrderProperties() 
  { 
//--- in einer Schleife durch die Liste aller Orders des Kontos 
   int total=OrdersTotal(); 
   for(int i=0; i<total; i++) 
     { 
      //--- Abrufen des Order-Tickets in der Liste über den Schleifenindex 
      ulong ticket=OrderGetTicket(i); 
      if(ticket==0) 
         continue; 
       
      //--- Auftragstyp abrufen und Kopfzeile für die Liste der String-Eigenschaften des ausgewählten Auftrags anzeigen 
      string type=OrderTypeDescription((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)); 
      PrintFormat("String properties of an active pending order %s #%I64u:", type, ticket); 
      Print(type);
       
      //--- alle String-Eigenschaften des ausgewählten Auftrags unter der Kopfzeile drucken 
      OrderPropertiesStringPrint(13); 
     } 
   /* 
   Ergebnis: 
   String properties of an active pending order Sell Limit #2813781342: 
   Comment:     Test OrderGetString 
   Symbol:      EURUSD 
   External ID:  
   */ 
  } 
//+------------------------------------------------------------------+ 
//| String-Eigenschaften der ausgewählten Order im Journal anzeigen  | 
//+------------------------------------------------------------------+ 
void OrderPropertiesStringPrint(const uint header_width=0) 
  { 
//--- Kommentar im Journal anzeigen 
   OrderPropertyPrint("Comment:", header_width, ORDER_COMMENT); 
    
//--- Anzeige eines Symbols, für das der Auftrag im Journal ausgegeben wurde 
   OrderPropertyPrint("Symbol:", header_width, ORDER_SYMBOL); 
    
//--- Auftrags-ID in einem externen System im Journal anzeigen 
   OrderPropertyPrint("External ID:", header_width, ORDER_EXTERNAL_ID); 
  } 
//+------------------------------------------------------------------+ 
//| Display the order string property value in the journal           | 
//+------------------------------------------------------------------+ 
void OrderPropertyPrint(const string header, uint header_width, ENUM_ORDER_PROPERTY_STRING property) 
  { 
   string value=""; 
   if(!OrderGetString(property, value)) 
      PrintFormat("Cannot get property %s, error=%d", EnumToString(property), GetLastError()); 
   else 
     { 
      //--- Wenn der Funktion eine Breite der Kopfzeile von Null übergeben wird, dann wird der Breite die Größe der Kopfzeile + 1 zugewiesen. 
      uint w=(header_width==0 ? header.Length()+1 : header_width); 
      PrintFormat("%-*s%-s", w, header, value); 
     } 
  } 
//+------------------------------------------------------------------+ 
//| Rückgabe der Beschreibung des Auftragstyps                       | 
//+------------------------------------------------------------------+ 
string OrderTypeDescription(const ENUM_ORDER_TYPE type) 
  { 
   switch(type) 
     { 
      case ORDER_TYPE_BUY              :  return("Buy"); 
      case ORDER_TYPE_SELL             :  return("Sell"); 
      case ORDER_TYPE_BUY_LIMIT        :  return("Buy Limit"); 
      case ORDER_TYPE_SELL_LIMIT       :  return("Sell Limit"); 
      case ORDER_TYPE_BUY_STOP         :  return("Buy Stop"); 
      case ORDER_TYPE_SELL_STOP        :  return("Sell Stop"); 
      case ORDER_TYPE_BUY_STOP_LIMIT   :  return("Buy Stop Limit"); 
      case ORDER_TYPE_SELL_STOP_LIMIT  :  return("Sell Stop Limit"); 
      default                          :  return("Unknown order type: "+(string)type); 
     } 
  }   
/* History
   15.01.2025 -   Möglichkeit Einstellung Button X-Achse von Links  SK
                  Button Target für Target Reached, Trade Stopped Out und Cancel Trade hinzugefügt SK
                  SendButton in Void ausgelagert   SK
                  Senden an Discord bei Trade & Send implementiert   SK
   
   16.01.2025-    OnClick-Ereignis für die Messagebutton implementiert SK  
                  begonnen das Auslesen von laufenden Trades und platzierten Orders zu implementieren                