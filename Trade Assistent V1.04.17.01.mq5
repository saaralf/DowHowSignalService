//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Michael Keller, Steffen Kachold"
#property link ""
#property version "01.04.17"
string tradenummer = "0";
#include <Trade\Trade.mqh>
CTrade trade;
#include <Controls\Dialog.mqh>
CAppDialog SabioConfirmation;

#include "methoden_4.15.mqh" // Funktionen/Methoden ausgelagert in eine eigene Datei
#include "discord_4.15.mqh" // alles rund ums senden an Discord
#include "LabelundMessageButton.mqh" // Label für die Message Button

// Default values for settings:
double EntryLevel = 0;
double StopLossLevel = 0;
double TakeProfitLevel = 0;
double StopPriceLevel = 0;

// only one button is visible

input group "===== Button ====="
input bool ShowTPButton = true;          // TP Button sichtbar (JA/NEIN)
input color TPButton_bgcolor = clrGreen;  // TP Button   Color
input color TPButton_font_color = clrWhite;  // TP Button   Font Color
input uint TPButton_font_size = 8;  // TP Button   Font Size
input int TPButtonDistancefromright = 70; // TPButton Distance from right
input color SLButton_bgcolor = clrRed; // SL Button   Color
input color SLButton_font_color = clrWhite;  // SL Button   Font Color
input uint SLButton_font_size = 8;  // SL Button   Font Size
input color PriceButton_bgcolor = clrAqua;   // Price Button   Color
input color PriceButton_font_color = clrBlack;  // Price Button   Font Color
input uint PriceButton_font_size = 8;  // Price Button   Font Size
input color SendOnlyButton_bgcolor = clrForestGreen;  // Button Send only  Color
input color SendOnlyButton_font_color = clrWhite;  // Button Send only  Font Color
input uint SendOnlyButton_font_size = 10; // Button Send only  Font Size
input color TSButton_bgcolor = clrGray;   // Button Trade & Send  Color
input color TSButton_font_color = clrRed; // Button Trade & Send  Font Color
input uint TSButton_font_size = 10; // Button Trade & Send  Font Size
input string NotizEdit_length = 500;   // Notiz field Length
input group "===== Lines ====="
input color EntryLine = clrBlue; // Entry Line
input color TPLine = clrGreen;   // TP Line at TP Button
input color SLLine = clrRed;  // SL Line at SL Button
input color TradeEntryLineLong = clrGreen; // Active Trade SL Line Long
input color TradeTPLineLong = clrGreen;   // Active Trade TP Line Long
input color TradeSLLineLong = clrRed;  // Active Trade SL Line Long
input color TradeEntryLineShort = clrAqua;   // Active Trade Entry Line Short
input color TradeTPLineShort = clrDarkOrange;   // Active Trade TP Line Short
input color TradeSLLineShort = clrViolet; // Active Trade SL Line Long
input group "===== Defaults ====="
input bool SendOnlyButton = true;   // Send only (true) or Trade & Send (false)
input bool Sabioedit = true;  // Sabio Prices Edit visible
input bool SabioPrices = true;   // Sabio Prices already insert (true) or not (false)
input bool MessageBoxSound = true;
//input double DefaultRisk = 0.5;   // Risk in %
//input int tradecounter=0;  // 1. Tradenummer
//int trade_counter=tradecounter;
input int DistancefromRight = 300;  //Distance from right screen edge

#define TPButton "TPButton"
#define EntryButton "EntryButton"
#define SLButton "SLButton"
#define BTN2 "SendOnlyButton"
#define TP_HL "TP_HL"
#define SL_HL "SL_HL"
#define PR_HL "PR_HL"
#define TRNB "EingabeTrade"
#define SabioTP "SabioTP"
#define SabioEntry "SabioEntry"
#define SabioSL "SabioSL"
#define TP_Long "TP_Long"
#define SL_Long "SL_Long"
#define TP_Short "TP_Short"
#define SL_Short "SL_Short"
#define LabelTPLong "LabelTPLong"
#define LabelSLLong "LabelSLLong"
#define LabelTPShort "LabelTPShort"
#define LabelSLShort "LabelSLShort"
#define Entry_Long "Entry_Long"
#define Entry_Short "Entry_Short"
#define LabelEntryLong "LabelEntryLong"
#define LabelEntryShort "LabelEntryShort"
#define ConfirmSabioInserts "ConfirmSabioInserts"

double Entry_Price;
double TP_Price;
double SL_Price;
double CurrentAskPrice;
double CurrentBidPrice;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckForExistingLongPosition();
bool isBuy=1;
bool is_long_trade=false,is_sell_trade=false;
bool send_TP_buy=false;
bool send_SL_buy=false;
bool send_CL_buy=false;
bool send_TP_sell=false;
bool send_SL_sell=false;
bool send_CL_sell=false;
bool HitEntryPriceLong = false;
bool HitEntryPriceShort = false;
bool is_sell_trade_pending = false;
bool is_buy_trade_pending = false;

int last_trade_nummer=0;
int last_buy_trade=-1;
int last_sell_trade=-1;
int
xd1,
yd1, xs1, ys1,
xd2, yd2, xs2, ys2,
xd3, yd3, xs3, ys3,
xd4, yd4, xs4, ys4,
xd5, yd5, xs5, ys5;

datetime dt_Labels = iTime(_Symbol, 0, 0);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//Init und Test Discord Api
   checkDiscord();
   MessageButton();
   InfoLabel();
   LabelTradeNumber();
   NotizEdit();

   createButton(TPButton, "", getChartWidthInPixels()-DistancefromRight-TPButtonDistancefromright,getChartHeightInPixels()/2,280, 30, TPButton_font_color, TPButton_bgcolor, TPButton_font_size, clrNONE, "Arial Black");

// EINZIGE NEUE ZEILE: Unsichtbar machen wenn gewünscht
   if(!ShowTPButton)
     {
      ObjectSetInteger(0, TPButton, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
     }

// TP Button
   xd1 = (int)ObjectGetInteger(0, TPButton, OBJPROP_XDISTANCE);
   yd1 = (int)ObjectGetInteger(0, TPButton, OBJPROP_YDISTANCE);
   xs1 = (int)ObjectGetInteger(0, TPButton, OBJPROP_XSIZE);
   ys1 = (int)ObjectGetInteger(0, TPButton, OBJPROP_YSIZE);

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

   datetime dt_tp = iTime(_Symbol, 0, 0), dt_sl = iTime(_Symbol, 0, 0), dt_prc = iTime(_Symbol, 0, 0);
   double price_tp = iClose(_Symbol, 0, 0), price_sl = iClose(_Symbol, 0, 0), price_prc = iClose(_Symbol, 0, 0);
   int window = 0;

   ChartXYToTimePrice(0, xd1, yd1 + ys1, window, dt_tp, price_tp);
   ChartXYToTimePrice(0, xd3, yd3 + ys3, window, dt_prc, price_prc);
   ChartXYToTimePrice(0, xd5, yd5 + ys5, window, dt_sl, price_sl);

   createHL(TP_HL, dt_tp, price_tp, TPLine);

   if(!ShowTPButton)
     {
      ObjectSetInteger(0, TP_HL, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
     }

   createHL(PR_HL, dt_prc, price_prc, EntryLine);
   createHL(SL_HL, dt_sl, price_sl, SLLine);

   ObjectMove(0, TPButton, 0, dt_tp, price_tp);
   ObjectMove(0, EntryButton, 0, dt_prc, price_prc);
   ObjectMove(0, SLButton, 0, dt_sl, price_sl);

//   DrawHL();
   if(Sabioedit)
     {
      SabioEdit();
      if(!ShowTPButton && Sabioedit)
        {
         ObjectSetInteger(0, SabioTP, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        }
     }

   SendButton();
   if(!SendOnlyButton)
     {
      ObjectSetString(0, BTN2, OBJPROP_TEXT, "T & S"); // label
      ObjectSetInteger(0, BTN2, OBJPROP_BGCOLOR, TSButton_bgcolor);
      ObjectSetInteger(0, BTN2, OBJPROP_COLOR, TSButton_font_color);
     }
   double lots = calcLots(SL_Price - Entry_Price);
   lots = NormalizeDouble(lots,2);

   createButton(EntryButton, "", xd3, yd3, xs3, ys3, PriceButton_font_color, PriceButton_bgcolor, PriceButton_font_size, clrNONE, "Arial Black");
   createButton(SLButton, "", xd5, yd5, xs5, ys5, SLButton_font_color, SLButton_bgcolor, SLButton_font_size, clrNONE, "Arial Black");
   if(ShowTPButton)
     {
      update_Text(TPButton, "TP: " + DoubleToString(((Get_Price_d(TP_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
     }
   update_Text(EntryButton, "Buy Stop @ " + Get_Price_s(PR_HL) +" | Lot: " + DoubleToString(lots,2));
   update_Text(SLButton, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   ChartRedraw(0);

   isBuy=true;
   last_trade_nummer=0;
   is_long_trade=false;
   is_sell_trade=false;

   Entry_Price = StringToDouble(Get_Price_s(PR_HL));
   TP_Price = StringToDouble(Get_Price_s(TP_HL));
   SL_Price = StringToDouble(Get_Price_s(SL_HL));

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
   ChartSetInteger(0,CHART_MOUSE_SCROLL,0,false);
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
   CurrentAskPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   CurrentBidPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);

   TPSLReached();

   if(is_long_trade)
     {
      CreateLabelsLong();
     }

   if(is_sell_trade)
     {
      CreateLabelsShort();
     }
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
   Entry_Price = StringToDouble(Get_Price_s(PR_HL));
   TP_Price = StringToDouble(Get_Price_s(TP_HL));
   SL_Price = StringToDouble(Get_Price_s(SL_HL));

   if(id == CHARTEVENT_MOUSE_MOVE)
     {
      int MouseD_X = (int)lparam;
      int MouseD_Y = (int)dparam;
      int MouseState = (int)sparam;

      int XD_R1 = (int)ObjectGetInteger(0, TPButton, OBJPROP_XDISTANCE);
      int YD_R1 = (int)ObjectGetInteger(0, TPButton, OBJPROP_YDISTANCE);
      int XS_R1 = (int)ObjectGetInteger(0, TPButton, OBJPROP_XSIZE);
      int YS_R1 = (int)ObjectGetInteger(0, TPButton, OBJPROP_YSIZE);

      int XD_R3 = (int)ObjectGetInteger(0, EntryButton, OBJPROP_XDISTANCE);
      int YD_R3 = (int)ObjectGetInteger(0, EntryButton, OBJPROP_YDISTANCE);
      int XS_R3 = (int)ObjectGetInteger(0, EntryButton, OBJPROP_XSIZE);
      int YS_R3 = (int)ObjectGetInteger(0, EntryButton, OBJPROP_YSIZE);

      int XD_R5 = (int)ObjectGetInteger(0, SLButton, OBJPROP_XDISTANCE);
      int YD_R5 = (int)ObjectGetInteger(0, SLButton, OBJPROP_YDISTANCE);
      int XS_R5 = (int)ObjectGetInteger(0, SLButton, OBJPROP_XSIZE);
      int YS_R5 = (int)ObjectGetInteger(0, SLButton, OBJPROP_YSIZE);

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

         if(ShowTPButton && MouseD_X >= XD_R1 && MouseD_X <= XD_R1 + XS_R1 &&
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

      if(ShowTPButton && movingState_R1)
        {

         ChartSetInteger(0, CHART_MOUSE_SCROLL, false);

         ObjectSetInteger(0, TPButton, OBJPROP_YDISTANCE, mlbDownYD_R1 + MouseD_Y - mlbDownY1);

         ObjectSetInteger(0, SLButton, OBJPROP_YDISTANCE, mlbDownYD_R5 - MouseD_Y + mlbDownY1);
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

         if(ShowTPButton)
           {
            update_Text(TPButton, "TP: " + DoubleToString(((Get_Price_d(TP_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
           }
         update_Text(SLButton, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

         if(SabioPrices)
           {
            update_Text(SabioEntry,"SABIO Entry: "+ Get_Price_s(PR_HL));
            if(ShowTPButton)
              {
               update_Text(SabioTP,"SABIO TP: "+ Get_Price_s(TP_HL));
              }
            update_Text(SabioSL,"SABIO SL: "+ Get_Price_s(SL_HL));
           }

         else
           {
            update_Text(SabioEntry,"SABIO ENTRY: ");
            if(ShowTPButton)
              {
               update_Text(SabioTP,"SABIO TP: ");
              }
            update_Text(SabioSL,"SABIO SL: ");
           }

         if((Get_Price_d(SL_HL)) > (Get_Price_d(TP_HL)))
           {
            double lots = calcLots(SL_Price - Entry_Price);
            lots = NormalizeDouble(lots,2);
            isBuy=0;
            update_Text(EntryButton, "Sell Stop @ " + Get_Price_s(PR_HL) +" | Lot: " + DoubleToString(lots,2));
            if(ShowTPButton)
              {
               update_Text(TPButton, "TP: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(TP_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
              }
            update_Text(SLButton, "SL: " + DoubleToString(((Get_Price_d(SL_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

           }
         else
           {
            double lots = calcLots(Entry_Price - SL_Price);
            lots = NormalizeDouble(lots,2);
            update_Text(EntryButton, "Buy Stop @ " + Get_Price_s(PR_HL) +" | Lot: " + DoubleToString(lots,2));
            isBuy=1;
           }

         ChartRedraw(0);
        }

      if(movingState_R5)
        {
         ChartSetInteger(0, CHART_MOUSE_SCROLL, false);

         ObjectSetInteger(0, SLButton, OBJPROP_YDISTANCE, mlbDownYD_R5 + MouseD_Y - mlbDownY5);
         if(ShowTPButton)
           {
            ObjectSetInteger(0, TPButton, OBJPROP_YDISTANCE, mlbDownYD_R1 - MouseD_Y + mlbDownY5);

            ObjectSetInteger(0, SabioTP, OBJPROP_YDISTANCE, mlbDownYD_R1 - MouseD_Y+30 + mlbDownY1);
           }
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

         double lots = calcLots(Entry_Price - SL_Price);
         lots = NormalizeDouble(lots,2);

         update_Text(EntryButton, "Buy Stop @ " + Get_Price_s(PR_HL) +" | Lot: " + DoubleToString(lots,2));
         if(ShowTPButton)
           {
            update_Text(TPButton, "TP: " + DoubleToString(((Get_Price_d(TP_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
           }
         update_Text(SLButton, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

         if(SabioPrices)
           {
            update_Text(SabioEntry,"SABIO Entry: "+ Get_Price_s(PR_HL));
            if(ShowTPButton)
              {
               update_Text(SabioTP,"SABIO TP: "+ Get_Price_s(TP_HL));

              }
            update_Text(SabioSL,"SABIO SL: "+ Get_Price_s(SL_HL));
           }

         else
           {
            update_Text(SabioEntry,"SABIO ENTRY: ");
            if(ShowTPButton)
              {
               update_Text(SabioTP,"SABIO TP: ");

              }
            update_Text(SabioSL,"SABIO SL: ");
           }

         if((Get_Price_d(SL_HL)) > (Get_Price_d(TP_HL)))
           {
            double lots = calcLots(SL_Price - Entry_Price);
            lots = NormalizeDouble(lots,2);
            isBuy=0;
            update_Text(EntryButton, "Sell Stop @ " + Get_Price_s(PR_HL) +" | Lot: " + DoubleToString(lots,2));
            if(ShowTPButton)
              {
               update_Text(TPButton, "TP: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(TP_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
              }
            update_Text(SLButton, "SL: " + DoubleToString(((Get_Price_d(SL_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));
           }
         else
           {
            isBuy=1;
           }

         ChartRedraw(0);
        }

      if(movingState_R3)
        {
         ChartSetInteger(0, CHART_MOUSE_SCROLL, false);
         ObjectSetInteger(0, EntryButton, OBJPROP_YDISTANCE, mlbDownYD_R3 + MouseD_Y - mlbDownY3);
         if(ShowTPButton)
           {
            ObjectSetInteger(0, TPButton, OBJPROP_YDISTANCE, mlbDownYD_R1 + MouseD_Y - mlbDownY1);
            ObjectSetInteger(0, SabioTP, OBJPROP_YDISTANCE, mlbDownYD_R1 + MouseD_Y+30 - mlbDownY1);
           }

         ObjectSetInteger(0, SLButton, OBJPROP_YDISTANCE, mlbDownYD_R5 + MouseD_Y - mlbDownY5);
         ObjectSetInteger(0, BTN2, OBJPROP_YDISTANCE, mlbDownYD_R3 + MouseD_Y - mlbDownY3);
         ObjectSetInteger(0, TRNB, OBJPROP_YDISTANCE, (mlbDownYD_R3 + MouseD_Y - mlbDownY3)+30);

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

         if(SabioPrices)
           {
            update_Text(SabioEntry,"SABIO Entry: "+ Get_Price_s(PR_HL));
            if(ShowTPButton)
              {    update_Text(SabioTP,"SABIO TP: "+ Get_Price_s(TP_HL));}
            update_Text(SabioSL,"SABIO SL: "+ Get_Price_s(SL_HL));
           }

         else
           {
            update_Text(SabioEntry,"SABIO ENTRY: ");
            if(ShowTPButton)
              {   update_Text(SabioTP,"SABIO TP: ");}
            update_Text(SabioSL,"SABIO SL: ");
           }

         if((Get_Price_d(SL_HL)) > (Get_Price_d(TP_HL)))
           {
            double lots = calcLots(SL_Price - Entry_Price);
            lots = NormalizeDouble(lots,2);

            update_Text(EntryButton, "Sell Stop @ " + Get_Price_s(PR_HL) +" | Lot: " + DoubleToString(lots,2));
            if(ShowTPButton)
              {
               update_Text(TPButton, "TP: " + DoubleToString(((Get_Price_d(PR_HL)-Get_Price_d(TP_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
              }
            update_Text(SLButton, "SL: " + DoubleToString(((Get_Price_d(SL_HL)-Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

            isBuy=0;
           }
         else
           {
            double lots = calcLots(Entry_Price - SL_Price);

            update_Text(EntryButton, "Buy Stop @ " + Get_Price_s(PR_HL) +" | Lot: " + DoubleToString(lots,2));
            update_Text(SLButton, "SL: " + DoubleToString(((Get_Price_d(PR_HL)-Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));
            if(ShowTPButton)
              {
               update_Text(TPButton, "TP: " + DoubleToString(((Get_Price_d(TP_HL)-Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
              }
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

   if(ObjectGetInteger(0, "SendOnlyButton", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "SendOnlyButton", OBJPROP_STATE, 0);
      if(Period()==PERIOD_M2 ||  Period()==PERIOD_M5 ||  Period()==PERIOD_H1)
         //      if(Period()==PERIOD_H1)
        {
         if(Sabioedit == true)
           {
            int result = MessageBox("Sabio Prices Insert?", NULL, MB_YESNO);
            //            MessageBoxSound = PlaySound(C:\Program Files\IC Markets (SC) Demo 51680033\Sounds\Alert2.wav);
            if(result == IDYES)
              {
               DiscordSend();
              }
           }
         else
           {
            DiscordSend();
           }
        }
      return;
     }

//+------------------------------------------------------------------+
//| Klick Button Cancel Long Order                                                             |
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
            HitEntryPriceLong = false;
            ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_COLOR, clrNONE);
            ObjectSetInteger(0,"ActiveLongTrade", OBJPROP_BGCOLOR, clrNONE);
            DeleteLinesandLabelsLong();
           }
        }
      return;
     }

//+------------------------------------------------------------------+
//|  Klick Button Cancel Short Order                                                                 |
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
            HitEntryPriceShort = false;
            ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_COLOR, clrNONE);
            ObjectSetInteger(0,"ActiveShortTrade", OBJPROP_BGCOLOR, clrNONE);
            DeleteLinesandLabelsShort();
           }
        }
     }

   if(id == CHARTEVENT_OBJECT_ENDEDIT)
     {
      if(sparam == SabioEntry || sparam == SabioSL)
        {
         UpdateSabioTP();
        }
     }
  }
//+------------------------------------------------------------------+
//| Create Trading Button                                                                 |
//+------------------------------------------------------------------+
bool createButton(string objName, string text, int xD, int yD, int xS, int yS, color clrTxt, color clrBG, int fontsize = 12, color clrBorder = clrNONE, string font = "Calibri")
  {
   ResetLastError();
   if(!ObjectCreate(0, objName, OBJ_BUTTON, 0, 0, TimeCurrent()))
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
   ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_CENTER);

   ChartRedraw(0);
   return (true);
  }

//+------------------------------------------------------------------+
//| Create Preislinien Trading Buttton                                                                 |
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
//| Send und T & S Button                                                                 |
//+------------------------------------------------------------------+
void SendButton()
  {
   ObjectCreate(0, "SendOnlyButton", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "SendOnlyButton", OBJPROP_XDISTANCE, xd3-100);   // X position
   ObjectSetInteger(0, "SendOnlyButton", OBJPROP_XSIZE, 100);       // width
   ObjectSetInteger(0, "SendOnlyButton", OBJPROP_YDISTANCE, yd3);    // Y position
   ObjectSetInteger(0, "SendOnlyButton", OBJPROP_YSIZE, 30);        // height
   ObjectSetInteger(0, "SendOnlyButton", OBJPROP_CORNER, 0);        // chart corner
   if(!SendOnlyButton)
     {
      ObjectSetString(0, "SendOnlyButton", OBJPROP_TEXT, "T & S"); // label
      ObjectSetInteger(0, "SendOnlyButton", OBJPROP_BGCOLOR, TSButton_bgcolor);
      ObjectSetInteger(0, "SendOnlyButton", OBJPROP_COLOR, TSButton_font_color);
     }
   else
     {
      ObjectSetString(0, "SendOnlyButton", OBJPROP_TEXT, "Send only"); // label
      ObjectSetInteger(0, "SendOnlyButton", OBJPROP_BGCOLOR, SendOnlyButton_bgcolor);
      ObjectSetInteger(0, "SendOnlyButton", OBJPROP_COLOR, SendOnlyButton_font_color);
     }
   ObjectSetInteger(0, "SendOnlyButton", OBJPROP_FONTSIZE, SendOnlyButton_font_size);

//+------------------------------------------------------------------+
//|   TradenummerneingabeFeld
//+------------------------------------------------------------------+

   ObjectCreate(0, TRNB, OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0,TRNB,OBJPROP_XDISTANCE,xd3-100);
   ObjectSetInteger(0,TRNB,OBJPROP_YDISTANCE,yd3+30);
//--- Objektgröße setzen
   ObjectSetInteger(0,TRNB,OBJPROP_XSIZE,100);
   ObjectSetInteger(0,TRNB,OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,TRNB,OBJPROP_TEXT,"0");
//--- Schriftgröße setzen
   ObjectSetInteger(0,TRNB, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, TRNB, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, TRNB, OBJPROP_ALIGN,ALIGN_CENTER);
//--- aktivieren (true) oder deaktivieren (false) den schreibgeschützten Modus
   ObjectSetInteger(0,TRNB,OBJPROP_READONLY,false);
  }

//+------------------------------------------------------------------+
//| Eingabefelder für Sabio Preise                                                                |
//+------------------------------------------------------------------+

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
   ObjectSetInteger(0,SabioTP,OBJPROP_XSIZE,280);
   ObjectSetInteger(0,SabioTP,OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,SabioTP,OBJPROP_TEXT,"SABIO TP: "+ Get_Price_s(TP_HL));
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
   ObjectSetInteger(0,SabioSL,OBJPROP_XSIZE,280);
   ObjectSetInteger(0,SabioSL,OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,SabioSL,OBJPROP_TEXT,"SABIO SL: "+ Get_Price_s(SL_HL));
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
   ObjectSetInteger(0,SabioEntry,OBJPROP_XSIZE,280);
   ObjectSetInteger(0,SabioEntry,OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,SabioEntry,OBJPROP_TEXT,"SABIO ENTRY: "+ Get_Price_s(PR_HL));
//--- Schriftgröße setzen
   ObjectSetInteger(0,SabioEntry, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, SabioEntry, OBJPROP_COLOR, clrBlack);

//--- aktivieren (true) oder deaktivieren (false) den schreibgeschützten Modus
   ObjectSetInteger(0,TRNB,OBJPROP_READONLY,false);
  }

//+------------------------------------------------------------------+
//| Feld für Notizen erstellen                                                                  |
//+------------------------------------------------------------------+
void NotizEdit()
  {
//SabioTPEdit
   ObjectCreate(0, "NotizEdit", OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0,"NotizEdit",OBJPROP_XDISTANCE,100);
   ObjectSetInteger(0,"NotizEdit",OBJPROP_YDISTANCE,getChartHeightInPixels() - 100);
//--- Objektgröße setzen
   ObjectSetInteger(0,"NotizEdit",OBJPROP_XSIZE,500);
   ObjectSetInteger(0,"NotizEdit",OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,"NotizEdit",OBJPROP_TEXT,"space for trade remarks ");
//--- Schriftgröße setzen
   ObjectSetInteger(0,"NotizEdit", OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, "NotizEdit", OBJPROP_COLOR, clrBlack);
  }

//+------------------------------------------------------------------+
//| an Discord senden                                                           |
//+------------------------------------------------------------------+
void DiscordSend()
  {
   string tradenummer_string;
   ObjectGetString(0,TRNB,OBJPROP_TEXT,0,tradenummer_string);
   tradenummer= (int) tradenummer_string;

   if((int) tradenummer > (int) last_trade_nummer)
     {
      if(isBuy)  // Long Trade zum senden
        {
         if(Entry_Price <= CurrentAskPrice)
           {
            int result = MessageBox("Entry price is lower then current price", NULL, MB_OK);
            if(result == IDOK);
           }
         else
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
               tradeInfo[0].is_trade_pending = true;
               is_buy_trade_pending = true;

               is_long_trade=true; // Jetzt ist ein Trade Long vorhanden

               ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_COLOR, InfoLabelFontSize_font_color);
               ObjectSetInteger(0,"ActiveLongTrade", OBJPROP_BGCOLOR, InfoLabelFontSize_bgcolor);
               update_Text("ActiveLongTrade", "ACTIVE POSITION");
               CreateTPSLLines(TP_Long,TimeCurrent(),TP_Price,TradeTPLineLong);

               if(!ShowTPButton)
                 {
                  ObjectSetInteger(0, TP_Long, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
                 }
               CreateTPSLLines(SL_Long,TimeCurrent(),SL_Price,TradeSLLineLong);
               CreateTPSLLines(Entry_Long,TimeCurrent(),tradeInfo[0].price,TradeEntryLineLong);
               CreateLabelsLong();
               update_Text("LabelTradenummer", "Last Trade Number: " + tradenummer);

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
               if(!SendOnlyButton)  // Trade und Send ist aktiviert
                 {
                  // Buy Stop
                  double lots = calcLots(Entry_Price - SL_Price);

                  if(!ShowTPButton)
                    {
                     trade.BuyStop(lots, Entry_Price, _Symbol, SL_Price, 0.0, ORDER_TIME_GTC);
                    }
                  else
                    {
                     trade.BuyStop(lots, Entry_Price, _Symbol, SL_Price, TP_Price, ORDER_TIME_GTC);
                    }
                  return;
                 }
              }
            else
              {
               int result = MessageBox("A Long Trade is already placed or running", NULL, MB_OK);
               if(result == IDOK);
              }
        }
      else // Ist Short eingestellt
        {
         if(Entry_Price > CurrentBidPrice)
           {
            int result = MessageBox("Entry price is higher then current price", NULL, MB_OK);
            if(result == IDOK);
           }
         else
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
               tradeInfo[1].is_trade_pending = true;
               is_sell_trade_pending = true;

               send_TP_sell=false;
               send_SL_sell=false;
               send_CL_sell=false;

               is_sell_trade=true; //Jetzt ist ein Sell Trade vorhanden

               ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_COLOR, clrWhite);
               ObjectSetInteger(0,"ActiveShortTrade", OBJPROP_BGCOLOR, clrRed);
               update_Text("ActiveShortTrade", "ACTIVE POSITION");
               CreateTPSLLines(TP_Short,TimeCurrent(),TP_Price,TradeTPLineShort);
               if(!ShowTPButton)
                 {
                  ObjectSetInteger(0, TP_Short, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
                 }
               CreateTPSLLines(SL_Short,TimeCurrent(),SL_Price,TradeSLLineShort);
               CreateTPSLLines(Entry_Short,TimeCurrent(),tradeInfo[1].price,TradeEntryLineShort);
               CreateLabelsShort();
               update_Text("LabelTradenummer", "Last Trade Number: " + tradenummer);

               string message = FormatTradeMessage(tradeInfo[1]);
               bool ret= SendDiscordMessage(message);
               SendScreenShot(_Symbol,_Period,getChartWidthInPixels(),getChartHeightInPixels());
               if(!ret)
                 {Print("Fehler beim senden zu Discord");}

               last_trade_nummer=tradenummer;
               last_sell_trade=tradenummer;

               if(!SendOnlyButton)  // Trade und Send ist aktiviert
                 {
                  // Sell Stop
                  double lots = calcLots(SL_Price - Entry_Price);
                  if(!ShowTPButton)
                    {
                     trade.SellStop(lots, Entry_Price, _Symbol, SL_Price, 0.0, ORDER_TIME_GTC);
                    }
                  else
                    {
                     trade.SellStop(lots, Entry_Price, _Symbol, SL_Price, TP_Price, ORDER_TIME_GTC);
                    }
                  return;
                 }
              }
            else
              {
               int result = MessageBox("A Short Trade is already placed or running", NULL, MB_OK);
               if(result == IDOK);
              }
        }
     }
   else // Errorhandle
     {
      int result = MessageBox("Insert a valid trade number, please", NULL, MB_OK);
      if(result == IDOK);
     }
  }

//+------------------------------------------------------------------+
//|  TP or SL reached                                                                |
//+------------------------------------------------------------------+
void TPSLReached()
  {
   double CurrentAskPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double CurrentBidPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);

//+------------------------------------------------------------------+
//|  Long TP or SL Reached                                                                 |
//+------------------------------------------------------------------+

   if(is_long_trade)
     {

      if(!send_CL_buy)
        {
         if(!HitEntryPriceLong && CurrentAskPrice >= tradeInfo[0].price)
           {
            HitEntryPriceLong = true;
            ObjectSetInteger(0, Entry_Long, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, TP_Long, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, SL_Long, OBJPROP_STYLE, STYLE_SOLID);
           }

         if(HitEntryPriceLong && tradeInfo[0].sl > 0 && (CurrentBidPrice <= tradeInfo[0].sl))
           {
            // Send notification before placing trade
            string message = FormatSLMessage(tradeInfo[0]);
            bool ret= SendDiscordMessage(message);
            is_long_trade=false;
            send_SL_buy=true;
            ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_COLOR, clrNONE);
            ObjectSetInteger(0,"ActiveLongTrade", OBJPROP_BGCOLOR, clrNONE);
            ObjectSetString(0,"ActiveLongTrade",OBJPROP_TEXT,"");
            DeleteLinesandLabelsLong();
            HitEntryPriceLong = false;
            Alert(_Symbol + " Long stopped out");
           }

         if(HitEntryPriceLong == true && tradeInfo[0].tp > 0 && (CurrentAskPrice >= tradeInfo[0].tp))
           {
            // Send notification before placing trade
            string message = FormatTPMessage(tradeInfo[0]);
            bool ret= SendDiscordMessage(message);
            is_long_trade=false;
            send_TP_buy=true;
            ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_COLOR, clrNONE);
            ObjectSetInteger(0,"ActiveLongTrade", OBJPROP_BGCOLOR, clrNONE);
            ObjectSetString(0,"ActiveLongTrade",OBJPROP_TEXT,"");
            DeleteLinesandLabelsLong();
            HitEntryPriceLong = false;
            Alert(_Symbol + " Long TP reached");
           }
        }
     }

//+------------------------------------------------------------------+
//| Short TP or SL Reached                                                                  |
//+------------------------------------------------------------------+

   if(is_sell_trade)
     {

      if(!HitEntryPriceShort && CurrentBidPrice <= tradeInfo[1].price)
        {
         HitEntryPriceShort = true;
         ObjectSetInteger(0, Entry_Short, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSetInteger(0, TP_Short, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSetInteger(0, SL_Short, OBJPROP_STYLE, STYLE_SOLID);
        }

      if(!send_CL_sell)
        {
         if(HitEntryPriceShort == true && tradeInfo[1].sl > 0 && (CurrentAskPrice >= tradeInfo[1].sl))
           {
            // Send notification before placing trade
            string message = FormatSLMessage(tradeInfo[1]);
            bool ret= SendDiscordMessage(message);
            is_sell_trade=false;
            send_SL_sell=true;
            ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_COLOR, clrNONE);
            ObjectSetInteger(0,"ActiveShortTrade", OBJPROP_BGCOLOR, clrNONE);
            ObjectSetString(0,"ActiveShortTrade",OBJPROP_TEXT,"");
            DeleteLinesandLabelsShort();
            HitEntryPriceShort = false;
            Alert(_Symbol + " Short stopped out");
           }

         if(HitEntryPriceShort == true &&  tradeInfo[1].tp > 0 && CurrentBidPrice <= tradeInfo[1].tp)
           {
            // Send notification before placing trade
            string message = FormatTPMessage(tradeInfo[1]);
            bool ret= SendDiscordMessage(message);
            is_sell_trade=false;
            send_TP_sell=true;
            ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_COLOR, clrNONE);
            ObjectSetInteger(0,"ActiveShortTrade", OBJPROP_BGCOLOR, clrNONE);
            ObjectSetString(0,"ActiveShortTrade",OBJPROP_TEXT,"");
            DeleteLinesandLabelsShort();
            HitEntryPriceShort = false;
            Alert(_Symbol + " Short TP reached");
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Label für Tradenummern                                                                |
//+------------------------------------------------------------------+
void LabelTradeNumber()
  {
   ObjectCreate(0, "LabelTradenummer", OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0,"LabelTradenummer",OBJPROP_XDISTANCE,100);
   ObjectSetInteger(0,"LabelTradenummer",OBJPROP_YDISTANCE,90+30+10+30+10);
   ObjectSetInteger(0,"LabelTradenummer",OBJPROP_XSIZE,330);
   ObjectSetInteger(0,"LabelTradenummer",OBJPROP_YSIZE,30);
   ObjectSetString(0,"LabelTradenummer",OBJPROP_TEXT,"Last Trade Number: " + tradenummer);
   ObjectSetInteger(0,"LabelTradenummer", OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, "LabelTradenummer", OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, "LabelTradenummer", OBJPROP_FONTSIZE, InfoLabelFontSize);
   ObjectSetString(0, "LabelTradenummer", OBJPROP_FONT, "Arial");
  }

//+------------------------------------------------------------------+
//| Sabio TP berechnen                                                                 |
//+------------------------------------------------------------------+
void UpdateSabioTP()
  {
   if(Entry_Price > CurrentAskPrice)
     {
      string EntryPriceString = ObjectGetString(0,SabioEntry,OBJPROP_TEXT,0);
      int Ergebnis = StringReplace(EntryPriceString,"SABIO ENTRY:","");
      double SabioEntryPrice = (double)EntryPriceString;
      string SabioSLPriceString = ObjectGetString(0,SabioSL,OBJPROP_TEXT,0);
      int ErgebnisSL = StringReplace(SabioSLPriceString,"SABIO SL:","");
      double SabioSLPrice = (double)SabioSLPriceString;
      if(SabioEntryPrice > 0 && SabioSLPrice > 0 && SabioEntryPrice != SabioSLPrice)
        {
         double SabioTPPrice = MathAbs(SabioEntryPrice - SabioSLPrice);
         update_Text(SabioTP, "SABIO TP: " + (int)(SabioTPPrice + SabioEntryPrice));
        }
     }

   if(Entry_Price < CurrentBidPrice)
     {
      string EntryPriceString = ObjectGetString(0,SabioEntry,OBJPROP_TEXT,0);
      int Ergebnis = StringReplace(EntryPriceString,"SABIO ENTRY:","");
      double SabioEntryPrice = (double)EntryPriceString;
      string SabioSLPriceString = ObjectGetString(0,SabioSL,OBJPROP_TEXT,0);
      int ErgebnisSL = StringReplace(SabioSLPriceString,"SABIO SL:","");

      double SabioSLPrice = (double)SabioSLPriceString;

      if(SabioEntryPrice > 0 && SabioSLPrice > 0 && SabioEntryPrice != SabioSLPrice)
        {
         double SabioTPPrice = MathAbs(SabioSLPrice -SabioEntryPrice);
         update_Text(SabioTP, "SABIO TP: " + (int)(SabioEntryPrice - SabioTPPrice));
        }
     }
  }

//+------------------------------------------------------------------+
//| Create Trading Lines
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CreateTPSLLines(string objName, datetime time1, double price1, color clr)
  {
   ResetLastError();

   if(!ObjectCreate(0, objName, OBJ_HLINE, 0, time1, price1))
     {
      Print(__FUNCTION__, ": Failed to create HL: Error Code: ", GetLastError());
      return (false);
     }
   ObjectSetInteger(0, objName, OBJPROP_TIME, TimeCurrent());
   ObjectSetDouble(0, objName, OBJPROP_PRICE, price1);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);


   ChartRedraw(0);
   return (true);
  }

//+------------------------------------------------------------------+
//| Create Line Labels
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateLabelsTPSLLines(string LABEL_NAME, string text, double price2, color clr1)
  {
   ResetLastError();

   if(!ObjectCreate(0, LABEL_NAME, OBJ_TEXT, 0, TimeCurrent(), price2))
     {
      Print(__FUNCTION__, ": Failed to create HL: Error Code: ", GetLastError());
     }
   ObjectCreate(0, LABEL_NAME, OBJ_TEXT, 0, TimeCurrent(), price2);
   ObjectSetInteger(0, LABEL_NAME, OBJPROP_COLOR, clr1);
   ObjectSetInteger(0, LABEL_NAME, OBJPROP_FONTSIZE, 12);
   ObjectSetString(0, LABEL_NAME, OBJPROP_TEXT, " ");


   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateLabelsLong()
  {
   CreateLabelsTPSLLines(LabelTPLong,"TP Long Trade", tradeInfo[0].tp,TradeTPLineLong);
   update_Text(LabelTPLong, "TP Long Trade");
// NEUE ZEILE: TP Label unsichtbar machen
   if(!ShowTPButton)
     {
      ObjectSetInteger(0, LabelTPLong, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
     }

   CreateLabelsTPSLLines(LabelSLLong,"SL Long Trade", tradeInfo[0].sl,TradeSLLineLong);
   update_Text(LabelSLLong, "SL Long Trade");
   CreateLabelsTPSLLines(LabelEntryLong,"Entry Long Trade", tradeInfo[0].price,TradeEntryLineLong);
   update_Text(LabelEntryLong, "Entry Long Trade");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateLabelsShort()
  {
   CreateLabelsTPSLLines(LabelTPShort,"TP Short Trade", tradeInfo[1].tp,TradeTPLineShort);
   update_Text(LabelTPShort, "TP Short Trade");
   if(!ShowTPButton)
     {
      ObjectSetInteger(0, LabelTPShort, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
     }

   CreateLabelsTPSLLines(LabelSLShort,"SL Short Trade", tradeInfo[1].sl,TradeSLLineShort);
   update_Text(LabelSLShort, "SL Short Trade");
   CreateLabelsTPSLLines(LabelEntryShort,"Entry Short Trade", tradeInfo[1].price,TradeEntryLineShort);
   update_Text(LabelEntryShort, "Entry Short Trade");
  }

//+------------------------------------------------------------------+
//|   Delete all objects                                 |
//+------------------------------------------------------------------+
void deleteObjects()
  {
   ObjectDelete(0, TPButton);
   ObjectDelete(0, EntryButton);
   ObjectDelete(0, SLButton);
   ObjectDelete(0, TP_HL);
   ObjectDelete(0, SL_HL);
   ObjectDelete(0, PR_HL);
   ObjectDelete(0, "SendOnlyButton");
   ObjectDelete(0, "ButtonTargetReached");
   ObjectDelete(0, "ButtonStoppedout");
   ObjectDelete(0, "ButtonCancelOrder");
   ObjectDelete(0, "ButtonTargetReachedSell");
   ObjectDelete(0, "ButtonStoppedoutSell");
   ObjectDelete(0, "ButtonCancelOrderSell");
   ObjectDelete(0, "EingabeTrade");
   ObjectDelete(0, "SabioEntry");
   ObjectDelete(0, "SabioTP");
   ObjectDelete(0, "SabioSL");
   ObjectDelete(0, "InfoButtonCancelOrder");
   ObjectDelete(0, "ActiveShortTrade");
   ObjectDelete(0, "InfoButtonStoppedoutSell");
   ObjectDelete(0, "InfoButtonCancelOrderSell");
   ObjectDelete(0, "ActiveLongTrade");
   ObjectDelete(0, "InfoButtonStoppedout");
   ObjectDelete(0, "TP_Long");
   ObjectDelete(0, "SL_Long");
   ObjectDelete(0, "TP_Short");
   ObjectDelete(0, "SL_Short");
   ObjectDelete(0, "LabelTPLong");
   ObjectDelete(0, "LabelSLLong");
   ObjectDelete(0, "LabelTPShort");
   ObjectDelete(0, "LabelSLShort");
   ObjectDelete(0, "LabelTradenummer");
   ObjectDelete(0, "NotizEdit");
   ObjectDelete(0, "Entry_Long");
   ObjectDelete(0, "Entry_Short");
   ObjectDelete(0, "LabelEntryLong");
   ObjectDelete(0, "LabelEntryShort");

   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| Tradelinien Long löschen                                                                  |
//+------------------------------------------------------------------+
void DeleteLinesandLabelsLong()
  {
   ObjectDelete(0, "TP_Long");
   ObjectDelete(0, "SL_Long");
   ObjectDelete(0, "LabelTPLong");
   ObjectDelete(0, "LabelSLLong");
   ObjectDelete(0, "Entry_Long");
   ObjectDelete(0, "LabelEntryLong");

  }
//+------------------------------------------------------------------+
//| Tradelinien Short löschen                                                                 |
//+------------------------------------------------------------------+
void DeleteLinesandLabelsShort()
  {
   ObjectDelete(0, "TP_Short");
   ObjectDelete(0, "SL_Short");
   ObjectDelete(0, "LabelTPShort");
   ObjectDelete(0, "LabelSLShort");
   ObjectDelete(0, "Entry_Short");
   ObjectDelete(0, "LabelEntryShort");
  }

//+------------------------------------------------------------------+
