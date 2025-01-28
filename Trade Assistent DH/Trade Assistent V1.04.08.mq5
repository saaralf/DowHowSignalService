//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Michael Keller, Steffen Kachold"
#property link ""
#property version "1.04.08" // 1.04.02 wird am 23.01.2025 Markus vorgestellt
string tradenummer=0;
#include <Trade\Trade.mqh>
CTrade trade;

#include "methoden.mqh" // Funktionen/Methoden ausgelagert in eine eigene Datei
#include "discord.mqh" // alles rund ums senden an Discord

//CPositionInfo PositionInfo;
//COrderInfo OrderInfo;

// Default values for settings:
double EntryLevel = 0;
double StopLossLevel = 0;
double TakeProfitLevel = 0;
double StopPriceLevel = 0;

// Button1 = input parameters for Trade & Send = Send only
// Button2 = Send only
// Button3 = Trade & Send
// only one button is visible

input group "=====Button====="
input color TPButton_bgcolor = clrGreen;                              // TP Button                      Color
input color TPButton_font_color = clrWhite;                          // TP Button                      Font Color
input uint TPButton_font_size = 10;                                  // TP Button                      Font Size
input int TPButtonDistancefromright = 70;                            // TPButton                       Distance from right
input color SLButton_bgcolor = clrRed;                              // SL Button                      Color
input color SLButton_font_color = clrWhite;                          // SL Button                      Font Color
input uint SLButton_font_size = 10;                                  // SL Button                      Font Size
input color PriceButton_bgcolor = clrAqua;                           // Price Button                   Color
input color PriceButton_font_color = clrBlack;                       // Price Button                   Font Color
input uint PriceButton_font_size = 10;                               // Price Button                   Font Size
input color Button2_bgcolor = clrForestGreen;                     // Button Send only                   Color
input color Button2_font_color = clrWhite;                        // Button Send only                   Font Color
input uint Button2_font_size = 10;                                // Button Send only                   Font Size
input color Button3_bgcolor = clrGray;                            // Button Trade & Send              Color
input color Button3_font_color = clrRed;                          // Button Trade & Send              Font Color
input uint Button3_font_size = 10;                                // Button Trade & Send              Font Size
input color ButtonTargetReached_bgcolor = clrGreen;                // Button Target Reached           Color
input color ButtonTargetReached_font_color = clrWhite;             // Button Target Reached           Font Color
input uint ButtonTargetReached_font_size = 8;                    // Button Target Reached            Font Size
input color ButtonStoppedout_bgcolor = clrRed;                    // Button Stopped out                Color
input color ButtonStoppedout_font_color = clrWhite;               // Button Stopped out                Font Color
input uint ButtonStoppedout_font_size = 8;                      // Button Stopped out                Font Size
input color ButtonCancelOrder_bgcolor = clrWhite;                // Button Cancel Order            Color
input color ButtonCancelOrder_font_color = clrBlack;             // Button Cancel Order            Font Color
input uint ButtonCancelOrder_font_size = 8;                    // Button Cancel Order             Font Size
input group "=====Defaults====="
input bool Button2 = true;                                        // Send only (true) or Trade & Send (false)
input bool Sabioedit = true;                                    // Sabio Prices visible
//input int RiskAmount = 250;                                        // Risk Amount in Account Currency
//input double DefaultRisk = 0.5;                                   // Risk in %
input int tradecounter=0;  // 1. Tradenummer
int trade_counter=tradecounter;
input int DistancefromRight = 250;                                      //Distance from right screen edge


bool CheckForExistingLongPosition();

#define REC1 "REC1"
#define REC3 "REC3"
#define REC5 "REC5"

#define BTN2 "Button2"

#define TP_HL "TP_HL"
#define SL_HL "SL_HL"
#define PR_HL "PR_HL"
#define TRNB "EingabeTrend"
#define SabioTP "SabioTP"
#define SabioEntry "SabioEntry"
#define SabioSL "SabioSL"

bool isBuy=1;
bool is_long_trade=false,is_sell_trade=false;
int last_trade_nummer=0;
int last_buy_trade=-1;
int last_sell_trade=-1;

double Entry_Price;
double TP_Price;
double SL_Price;

bool send_TP_buy=false;
bool send_SL_buy=false;
bool send_CL_buy=false;
bool send_TP_sell=false;
bool send_SL_sell=false;
bool send_CL_sell=false;
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
//int OTotal = OrdersTotal();
//int PTotal = PositionsTotal();

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//Init und Test Discord Api
   checkDiscord();
   MessageButton();

   datetime dt_tp = 0, dt_sl = 0, dt_prc = 0;
   double price_tp = 0, price_sl = 0, price_prc = 0;
   int window = 0;

   ChartXYToTimePrice(0, xd1, yd1 + ys1, window, dt_tp, price_tp);
   ChartXYToTimePrice(0, xd3, yd3 + ys3, window, dt_prc, price_prc);
   ChartXYToTimePrice(0, xd5, yd5 + ys5, window, dt_sl, price_sl);

   createHL(TP_HL, dt_tp, price_tp, clrLime);
   createHL(PR_HL, dt_prc, price_prc, clrAqua);
   createHL(SL_HL, dt_sl, price_sl, clrWhite);

   createButton(REC1, "", getChartWidthInPixels()-DistancefromRight-TPButtonDistancefromright,getChartHeightInPixels()/2,270, 30, TPButton_font_color, TPButton_bgcolor, TPButton_font_size, clrNONE, "Arial Black");
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


   if(Sabioedit)
     {
      SabioEdit();
     }

   SendButton();
   if(!Button2)
     {
      ObjectSetString(0, BTN2, OBJPROP_TEXT, "T & S"); // label
      ObjectSetInteger(0, BTN2, OBJPROP_BGCOLOR, Button3_bgcolor);
      ObjectSetInteger(0, BTN2, OBJPROP_COLOR, Button3_font_color);
     }

   createButton(REC3, "", xd3, yd3, xs3, ys3, PriceButton_font_color, PriceButton_bgcolor, PriceButton_font_size, clrNONE, "Arial Black");
   createButton(REC5, "", xd5, yd5, xs5, ys5, SLButton_font_color, SLButton_bgcolor, SLButton_font_size, clrNONE, "Arial Black");

   update_Text(REC1, "TP: " + DoubleToString(((Get_Price_d(TP_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
   update_Text(REC3, "Buy Stop @ " + Get_Price_s(PR_HL));
   update_Text(REC5, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   ChartRedraw(0);

   isBuy=true;
   last_trade_nummer=0;
   is_long_trade=false;
   is_sell_trade=false;

   double Entry_Price = StringToDouble(Get_Price_s(PR_HL));
   double TP_Price = StringToDouble(Get_Price_s(TP_HL));
   double SL_Price = StringToDouble(Get_Price_s(SL_HL));
   tradeInfo[0].tradenummer=-1;
   tradeInfo[0].symbol = _Symbol;
   tradeInfo[0].type = "BUY";
   tradeInfo[0].price = Entry_Price;
   tradeInfo[0].sl = SL_Price;
   tradeInfo[0].tp = TP_Price;
   tradeInfo[0].was_send=false;

   tradeInfo[1].tradenummer=-1;
   tradeInfo[1].symbol = _Symbol;
   tradeInfo[1].type = "SELL";
   tradeInfo[1].price = Entry_Price;
   tradeInfo[1].sl = SL_Price;
   tradeInfo[1].tp = TP_Price;
   tradeInfo[1].was_send=false;
// ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE,0, true);
   ChartSetInteger(0,CHART_MOUSE_SCROLL,0,false);
//ChartSetInteger(0,CHART_SHIFT,0,true);
   ChartSetInteger(0,CHART_SHOW_GRID,0,false);

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
         ObjectSetInteger(0, SabioTP, OBJPROP_YDISTANCE, mlbDownYD_R1 + MouseD_Y+30 - mlbDownY1);
         ObjectSetInteger(0, SabioSL, OBJPROP_YDISTANCE, mlbDownYD_R5 - MouseD_Y+30 + mlbDownY1);

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
         update_Text(SabioEntry,"Sabio Entry: "+ Get_Price_s(PR_HL));
         update_Text(SabioTP,"Sabio TP: "+ Get_Price_s(TP_HL));
         update_Text(SabioSL,"Sabio SL: "+ Get_Price_s(SL_HL));

         if((Get_Price_d(SL_HL)) > (Get_Price_d(TP_HL)))
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
         ObjectSetInteger(0, SabioTP, OBJPROP_YDISTANCE, mlbDownYD_R1 - MouseD_Y+30 + mlbDownY1);
         ObjectSetInteger(0, SabioSL, OBJPROP_YDISTANCE, mlbDownYD_R5 + MouseD_Y+30 - mlbDownY1);

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

         update_Text(REC3, "Buy Stop @ " + Get_Price_s(PR_HL));


         update_Text(REC1, "TP: " + DoubleToString(((Get_Price_d(TP_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
         update_Text(REC5, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));
         update_Text(SabioEntry,"Sabio Entry: "+ Get_Price_s(PR_HL));
         update_Text(SabioTP,"Sabio TP: "+ Get_Price_s(TP_HL));
         update_Text(SabioSL,"Sabio SL: "+ Get_Price_s(SL_HL));

         if((Get_Price_d(SL_HL)) > (Get_Price_d(TP_HL)))
           {
            isBuy=0;
            update_Text(REC3, "Sell Stop @ " + Get_Price_s(PR_HL));
            update_Text(REC1, "TP: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(TP_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
            update_Text(REC5, "SL: " + DoubleToString(((Get_Price_d(SL_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));
           }
         else
           {
            //            update_Text(REC3, "Buy Stop @ " + Get_Price_s(PR_HL));
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
         ObjectSetInteger(0, TRNB, OBJPROP_YDISTANCE, (mlbDownYD_R3 + MouseD_Y - mlbDownY3)+30);
         ObjectSetInteger(0, SabioTP, OBJPROP_YDISTANCE, mlbDownYD_R1 + MouseD_Y+30 - mlbDownY1);
         ObjectSetInteger(0, SabioEntry, OBJPROP_YDISTANCE, mlbDownYD_R3 + MouseD_Y+30 - mlbDownY1);
         ObjectSetInteger(0, SabioSL, OBJPROP_YDISTANCE, mlbDownYD_R5 + MouseD_Y+30 - mlbDownY1);

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

         update_Text(SabioEntry,"Sabio Entry: "+ Get_Price_s(PR_HL));
         update_Text(SabioTP,"Sabio TP: "+ Get_Price_s(TP_HL));
         update_Text(SabioSL,"Sabio SL: "+ Get_Price_s(SL_HL));

         if((Get_Price_d(SL_HL)) > (Get_Price_d(TP_HL)))
           {
            update_Text(REC3, "Sell Stop @ " + Get_Price_s(PR_HL));
            update_Text(REC1, "TP: " + DoubleToString(((Get_Price_d(PR_HL)-Get_Price_d(TP_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
            update_Text(REC5, "SL: " + DoubleToString(((Get_Price_d(SL_HL)-Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

            isBuy=0;
           }
         else
           {
            update_Text(REC3, "Buy Stop @ " + Get_Price_s(PR_HL));
            update_Text(REC5, "SL: " + DoubleToString(((Get_Price_d(PR_HL)-Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));
            update_Text(REC1, "TP: " + DoubleToString(((Get_Price_d(TP_HL)-Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
            isBuy=1;
           }

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

//ÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖ
   if(ObjectGetInteger(0, "Button2", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "Button2", OBJPROP_STATE, 0);
      if(Period()==PERIOD_M2 ||  Period()==PERIOD_M5)
        {
         Entry_Price = StringToDouble(Get_Price_s(PR_HL));
         TP_Price = StringToDouble(Get_Price_s(TP_HL));
         SL_Price = StringToDouble(Get_Price_s(SL_HL));

         string tradenummer_string;
         ObjectGetString(0,TRNB,OBJPROP_TEXT,0,tradenummer_string);
         tradenummer= (int) tradenummer_string;
         Print("Tradenummer "+tradenummer);
         Print("Tradenummer "+tradenummer_string);
         Print("LastTradenummer "+last_trade_nummer);

         if((int) tradenummer > (int) last_trade_nummer)
           {
            if(isBuy)  // Long Trade zum senden
              {
               if(!is_long_trade)      // Noch kein Longtrade vorhanden.
                 {

                  // Erzeuge Array TradeInfo
                  tradeInfo[0].tradenummer=tradenummer;
                  tradeInfo[0].symbol = _Symbol;
                  tradeInfo[0].type = "BUY";
                  tradeInfo[0].price = Entry_Price;
                  tradeInfo[0].sl = SL_Price;
                  tradeInfo[0].tp = TP_Price;
                  tradeInfo[0].sabioentry = ObjectGetString(0,SabioEntry,OBJPROP_TEXT,0);
                  tradeInfo[0].sabiosl = ObjectGetString(0,SabioSL,OBJPROP_TEXT,0);
                  tradeInfo[0].sabiotp = ObjectGetString(0,SabioTP,OBJPROP_TEXT,0);
                  tradeInfo[0].was_send=false;

                  is_long_trade=true; // Jetzt ist ein Trade Long vorhanden

                  send_TP_buy=false;
                  send_SL_buy=false;
                  send_CL_buy=false;
                  string message = FormatTradeMessage(tradeInfo[0]);
                  bool ret= SendDiscordMessage(message);
                  if(!ret)
                    {Print("Fehler beim senden zu Discord");}

                  SendScreenShot(_Symbol,_Period,getChartWidthInPixels(),getChartHeightInPixels());
                  tradeInfo[0].was_send=true;
                  last_trade_nummer=tradenummer;
                  last_buy_trade=tradenummer;
                  if(!Button2)  // Trade und Send ist aktiviert
                    {
                     // Buy Stop
                     double lots = calcLots(Entry_Price - SL_Price);
                     trade.BuyStop(lots, Entry_Price, _Symbol, SL_Price, TP_Price, ORDER_TIME_GTC);
                     return;

                    }

                 }
               else
                 {
                  Alert("Schon ein Longtrade vorhanden");
                 }
              }
            else // Ist Short eingestellt
              {
               if(!is_sell_trade)
                 {
                  tradeInfo[1].tradenummer=tradenummer;
                  tradeInfo[1].symbol = _Symbol;
                  tradeInfo[1].type = "SELL";
                  tradeInfo[1].price = Entry_Price;
                  tradeInfo[1].sl = SL_Price;
                  tradeInfo[1].tp = TP_Price;
                  tradeInfo[1].sabioentry = ObjectGetString(0,SabioEntry,OBJPROP_TEXT,0);
                  tradeInfo[1].sabiosl = ObjectGetString(0,SabioSL,OBJPROP_TEXT,0);
                  tradeInfo[1].sabiotp = ObjectGetString(0,SabioTP,OBJPROP_TEXT,0);
                  tradeInfo[1].was_send=false;

                  send_TP_sell=false;
                  send_SL_sell=false;
                  send_CL_sell=false;

                  is_sell_trade=true; //Jetzt ist ein Sell Trade vorhanden
                  string message = FormatTradeMessage(tradeInfo[1]);
                  bool ret= SendDiscordMessage(message);
                  SendScreenShot(_Symbol,_Period,getChartWidthInPixels(),getChartHeightInPixels());
                  if(!ret)
                    {Print("Fehler beim senden zu Discord");}

                  last_trade_nummer=tradenummer;
                  last_sell_trade=tradenummer;

                  if(!Button2)  // Trade und Send ist aktiviert
                    {
                     // Sell Stop
                     double lots = calcLots(SL_Price - Entry_Price);
                     trade.SellStop(lots, Entry_Price, _Symbol, SL_Price, TP_Price, ORDER_TIME_GTC);
                     return;
                    }
                 }

               else
                 {
                  Alert("Schon ein Selltrade vorhanden");
                 }
              }
           }
         else // Errorhandle
           {
            Alert("Bitte eine gültige/neue Tradenummer eingeben oder ein Long/Sell Trade ist schon vorhanden");
           }
        }
      return;
     }
//ENde //ÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖÖ

// Klick Message Buttons

//   string otype = GetOrderInfo();

   if(ObjectGetInteger(0, "ButtonTargetReached", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_STATE, 0);
      if(is_long_trade)
        {
         if(!send_TP_buy && !send_SL_buy || !send_CL_buy)
           {
            // Send notification before placing trade
            string message = FormatTPMessage(tradeInfo[0]);
            bool ret= SendDiscordMessage(message);

            is_long_trade=false;

            send_TP_buy=true;
           }
        }
     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(ObjectGetInteger(0, "ButtonStoppedout", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_STATE, 0);
      if(is_long_trade)
        {
         if(!send_TP_buy && !send_SL_buy || !send_CL_buy)
           {
            // Send notification before placing trade
            string message = FormatSLMessage(tradeInfo[0]);
            bool ret= SendDiscordMessage(message);
            is_long_trade=false;

            send_SL_buy=true;
           }
        }
     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(ObjectGetInteger(0, "ButtonCancelOrder", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_STATE, 0);
      if(is_long_trade)
        {
         if(!send_TP_buy && !send_SL_buy || !send_CL_buy)
           {
            //            // Send notification before placing trade
            string message = FormatCancelTradeMessage(tradeInfo[0]);
            bool ret= SendDiscordMessage(message);
            // Close open Buy Order
            DeleteBuyStopOrderForCurrentChart();
            is_long_trade=false;
            send_CL_buy=true;
           }
        }
     }

   if(ObjectGetInteger(0, "ButtonTargetReachedSell", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "ButtonTargetReachedSell", OBJPROP_STATE, 0);

      if(is_sell_trade)
        {
         if(!send_TP_sell && !send_SL_sell || !send_CL_sell)
           {
            // Send notification before placing trade
            string message = FormatTPMessage(tradeInfo[1]);
            bool ret= SendDiscordMessage(message);

            is_sell_trade=false;
            send_TP_sell=true;
           }
        }
     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(ObjectGetInteger(0, "ButtonStoppedoutSell", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "ButtonStoppedoutSell", OBJPROP_STATE, 0);
      if(is_sell_trade)
        {
         if(!send_TP_sell && !send_SL_sell || !send_CL_sell)
           {
            // Send notification before placing trade
            string message = FormatSLMessage(tradeInfo[1]);
            bool ret= SendDiscordMessage(message);
            is_sell_trade=false;

            send_SL_sell=true;
           }
        }
     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(ObjectGetInteger(0, "ButtonCancelOrderSell", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_STATE, 0);
      if(is_sell_trade)
        {
         if(!send_TP_sell && !send_SL_sell || !send_CL_sell)
           {
            // Send notification before placing trade
            string message = FormatCancelTradeMessage(tradeInfo[1]);
            bool ret= SendDiscordMessage(message);

            // Close open Sell Order
            DeleteSellStopOrderForCurrentChart();         
            is_sell_trade=false;
            send_CL_sell=true;
           }
        }
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
   ObjectDelete(0, "Button2");
   ObjectDelete(0, "ButtonTargetReached");
   ObjectDelete(0, "ButtonStoppedout");
   ObjectDelete(0, "ButtonCancelOrder");
   ObjectDelete(0, "ButtonTargetReachedSell");
   ObjectDelete(0, "ButtonStoppedoutSell");
   ObjectDelete(0, "ButtonCancelOrderSell");
   ObjectDelete(0, "EingabeTrend");
   ObjectDelete(0, "SabioEntry");
   ObjectDelete(0, "SabioTP");
   ObjectDelete(0, "SabioSL");

   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MessageButton()
  {
   ObjectCreate(0, "ButtonTargetReached", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_XDISTANCE, 100);               // X position
   ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_XSIZE, 150);                   // width
   ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_YDISTANCE, 100);                // Y position
   ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_YSIZE, 30);                    // height
   ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_CORNER, 0);                    // chart corner
   ObjectSetString(0, "ButtonTargetReached", OBJPROP_TEXT, "Buy Target Reached"); // label
   ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_BGCOLOR, ButtonTargetReached_bgcolor);
   ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_COLOR, ButtonTargetReached_font_color);
   ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_FONTSIZE, ButtonTargetReached_font_size);

   ObjectCreate(0, "ButtonStoppedout", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_XDISTANCE, 100);               // X position
   ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_XSIZE, 150);                   // width
   ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_YDISTANCE, 100+30+10);                // Y position
   ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_YSIZE, 30);                    // height
   ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_CORNER, 0);                    // chart corner
   ObjectSetString(0, "ButtonStoppedout", OBJPROP_TEXT, "Buy Stopped Out"); // label
   ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_BGCOLOR, ButtonStoppedout_bgcolor);
   ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_COLOR, ButtonStoppedout_font_color);
   ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_FONTSIZE, ButtonStoppedout_font_size);

   ObjectCreate(0, "ButtonCancelOrder", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_XDISTANCE, 100);               // X position
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_XSIZE, 150);                   // width
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_YDISTANCE, 100+30+10+30+10);                // Y position
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_YSIZE, 30);                    // height
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_CORNER, 0);                    // chart corner
   ObjectSetString(0, "ButtonCancelOrder", OBJPROP_TEXT, "Cancel Buy Order"); // label
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_BGCOLOR, ButtonCancelOrder_bgcolor);
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_COLOR, ButtonCancelOrder_font_color);
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_FONTSIZE, ButtonCancelOrder_font_size);


   ObjectCreate(0, "ButtonTargetReachedSell", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "ButtonTargetReachedSell", OBJPROP_XDISTANCE, 100+150+30);               // X position
   ObjectSetInteger(0, "ButtonTargetReachedSell", OBJPROP_XSIZE, 150);                   // width
   ObjectSetInteger(0, "ButtonTargetReachedSell", OBJPROP_YDISTANCE, 100);                // Y position
   ObjectSetInteger(0, "ButtonTargetReachedSell", OBJPROP_YSIZE, 30);                    // height
   ObjectSetInteger(0, "ButtonTargetReachedSell", OBJPROP_CORNER, 0);                    // chart corner
   ObjectSetString(0, "ButtonTargetReachedSell", OBJPROP_TEXT, "Sell Target Reached"); // label
   ObjectSetInteger(0, "ButtonTargetReachedSell", OBJPROP_BGCOLOR, ButtonTargetReached_bgcolor);
   ObjectSetInteger(0, "ButtonTargetReachedSell", OBJPROP_COLOR, ButtonTargetReached_font_color);
   ObjectSetInteger(0, "ButtonTargetReachedSell", OBJPROP_FONTSIZE, ButtonTargetReached_font_size);

   ObjectCreate(0, "ButtonStoppedoutSell", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "ButtonStoppedoutSell", OBJPROP_XDISTANCE, 100+150+30);               // X position
   ObjectSetInteger(0, "ButtonStoppedoutSell", OBJPROP_XSIZE, 150);                   // width
   ObjectSetInteger(0, "ButtonStoppedoutSell", OBJPROP_YDISTANCE, 100+30+10);                // Y position
   ObjectSetInteger(0, "ButtonStoppedoutSell", OBJPROP_YSIZE, 30);                    // height
   ObjectSetInteger(0, "ButtonStoppedoutSell", OBJPROP_CORNER, 0);                    // chart corner
   ObjectSetString(0, "ButtonStoppedoutSell", OBJPROP_TEXT, "Sell Stopped Out"); // label
   ObjectSetInteger(0, "ButtonStoppedoutSell", OBJPROP_BGCOLOR, ButtonStoppedout_bgcolor);
   ObjectSetInteger(0, "ButtonStoppedoutSell", OBJPROP_COLOR, ButtonStoppedout_font_color);
   ObjectSetInteger(0, "ButtonStoppedoutSell", OBJPROP_FONTSIZE, ButtonStoppedout_font_size);

   ObjectCreate(0, "ButtonCancelOrderSell", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_XDISTANCE, 100+150+30);               // X position
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_XSIZE, 150);                   // width
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_YDISTANCE,  100+30+10+30+10);                // Y position
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_YSIZE, 30);                    // height
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_CORNER, 0);                    // chart corner
   ObjectSetString(0, "ButtonCancelOrderSell", OBJPROP_TEXT, "Cancel Sell Order"); // label
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_BGCOLOR, ButtonCancelOrder_bgcolor);
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_COLOR, ButtonCancelOrder_font_color);
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_FONTSIZE, ButtonCancelOrder_font_size);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SendButton()
  {
   ObjectCreate(0, "Button2", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "Button2", OBJPROP_XDISTANCE, xd3-100);   // X position
   ObjectSetInteger(0, "Button2", OBJPROP_XSIZE, 100);       // width
   ObjectSetInteger(0, "Button2", OBJPROP_YDISTANCE, yd3);    // Y position
   ObjectSetInteger(0, "Button2", OBJPROP_YSIZE, 30);        // height
   ObjectSetInteger(0, "Button2", OBJPROP_CORNER, 0);        // chart corner
   if(!Button2)
     {
      ObjectSetString(0, "Button2", OBJPROP_TEXT, "T & S"); // label
      ObjectSetInteger(0, "Button2", OBJPROP_BGCOLOR, Button3_bgcolor);
      ObjectSetInteger(0, "Button2", OBJPROP_COLOR, Button3_font_color);
     }
   else
     {
      ObjectSetString(0, "Button2", OBJPROP_TEXT, "Send only"); // label
      ObjectSetInteger(0, "Button2", OBJPROP_BGCOLOR, Button2_bgcolor);
      ObjectSetInteger(0, "Button2", OBJPROP_COLOR, Button2_font_color);
     }
   ObjectSetInteger(0, "Button2", OBJPROP_FONTSIZE, Button2_font_size);

//TrendnummereingabeFeld
   ObjectCreate(0, TRNB, OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0,TRNB,OBJPROP_XDISTANCE,xd3-100);
   ObjectSetInteger(0,TRNB,OBJPROP_YDISTANCE,yd3+30);
//--- Objektgröße setzen
   ObjectSetInteger(0,TRNB,OBJPROP_XSIZE,100);
   ObjectSetInteger(0,TRNB,OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,TRNB,OBJPROP_TEXT,00);
//--- Schriftgröße setzen
   ObjectSetInteger(0,TRNB, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, TRNB, OBJPROP_COLOR, clrBlack);

//--- aktivieren (true) oder deaktivieren (false) den schreibgeschützten Modus
   ObjectSetInteger(0,TRNB,OBJPROP_READONLY,false);
//--- setzen die Ecke des Diagramms, in Bezug auf die die Koordinaten des Objekts bestimmt werden


//--- die erfolgreiche Umsetzung
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SabioEdit()
  {
//SabioTPEdit
   ObjectCreate(0, SabioTP, OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0,SabioTP,OBJPROP_XDISTANCE,xd1);
   ObjectSetInteger(0,SabioTP,OBJPROP_YDISTANCE,yd1+30);
//--- Objektgröße setzen
   ObjectSetInteger(0,SabioTP,OBJPROP_XSIZE,270);
   ObjectSetInteger(0,SabioTP,OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,SabioTP,OBJPROP_TEXT,"SABIO TP: ");
//--- Schriftgröße setzen
   ObjectSetInteger(0,SabioTP, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, SabioTP, OBJPROP_COLOR, clrBlack);

//--- aktivieren (true) oder deaktivieren (false) den schreibgeschützten Modus
   ObjectSetInteger(0,TRNB,OBJPROP_READONLY,false);

//SabioSLEdit
   ObjectCreate(0, SabioSL, OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0,SabioSL,OBJPROP_XDISTANCE,xd1);
   ObjectSetInteger(0,SabioSL,OBJPROP_YDISTANCE,yd5+30);
//--- Objektgröße setzen
   ObjectSetInteger(0,SabioSL,OBJPROP_XSIZE,270);
   ObjectSetInteger(0,SabioSL,OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,SabioSL,OBJPROP_TEXT,"SABIO SL: ");
//--- Schriftgröße setzen
   ObjectSetInteger(0,SabioSL, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, SabioSL, OBJPROP_COLOR, clrBlack);

//--- aktivieren (true) oder deaktivieren (false) den schreibgeschützten Modus
   ObjectSetInteger(0,TRNB,OBJPROP_READONLY,false);

//SabioEntryEdit
   ObjectCreate(0, SabioEntry, OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0,SabioEntry,OBJPROP_XDISTANCE,xd1);
   ObjectSetInteger(0,SabioEntry,OBJPROP_YDISTANCE,yd3+30);
//--- Objektgröße setzen
   ObjectSetInteger(0,SabioEntry,OBJPROP_XSIZE,270);
   ObjectSetInteger(0,SabioEntry,OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,SabioEntry,OBJPROP_TEXT,"Sabio Entry: "+ Get_Price_s(PR_HL));
//--- Schriftgröße setzen
   ObjectSetInteger(0,SabioEntry, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, SabioEntry, OBJPROP_COLOR, clrBlack);

//--- aktivieren (true) oder deaktivieren (false) den schreibgeschützten Modus
   ObjectSetInteger(0,TRNB,OBJPROP_READONLY,false);
  }
//+------------------------------------------------------------------+
//| Funktionen: Schließen der offenen Orders                        |
//+------------------------------------------------------------------+
/*
