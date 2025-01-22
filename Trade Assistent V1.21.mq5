//+------------------------------------------------------------------+
//|                                        Trade Assistent V1.20.mq5 |
//|                                 Michael Keller, Steffen Kachold |
//|                                                                  |
//+------------------------------------------------------------------+


/* History
   15.01.2025 -   Möglichkeit Einstellung Button X-Achse von Links  SK
                  Button Target für Target Reached, Trade Stopped Out und Cancel Trade hinzugefügt SK
                  SendButton in Void ausgelagert   SK
                  Senden an Discord bei Trade & Send implementiert   SK

   16.01.2025-    OnClick-Ereignis für die Messagebutton implementiert SK
                  begonnen das Auslesen von laufenden Trades und platzierten Orders zu implementieren

*/



#property copyright "Michael Keller, Steffen Kachold"
#property link ""
#property version "1.20"

//#include <GetOrderandPosition V1_11.mqh>

#include "includes.mqh" // alles rund ums senden an Discord

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+

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
// Send_Only = Send only
// Trade_n_Send = Trade & Send
// only one button is visible

input group "=====Trading Button====="
input color Button1_bgcolor = clrRed;                             // Label Please check settings      Color
input color Button1_font_color = clrWhite;                        // Label Please check settings      Font Color
input uint Button1_font_size = 9;                                // Label Please check settings      Font Size
input color Send_Only_bgcolor = clrForestGreen;                     // Button Send only                   Color
input color Send_Only_font_color = clrWhite;                        // Button Send only                   Font Color
input uint Send_Only_font_size = 10;                                // Button Send only                   Font Size

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
//input int SetXDistance =500;                                    // Trading Button X-Distance from Left



bool CheckForExistingLongPosition();


double Entry_Price;
double TP_Price ;
double SL_Price ;

// string otype = "";



CControlsDialog ExtDialog;

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

//--- create application dialog
   if(!ExtDialog.Create(0,"Controls",0,20,20,360,324))
      return(INIT_FAILED);
//--- run application
   ExtDialog.Run();

  // createButton(REC1, "", getChartWidthInPixels()-200-50,  getChartHeightInPixels()/2,200, 30, clrWhite, clrGreen, 9, clrGreen, "Arial Black");
// TP Button

xd1= ExtDialog.getXTPSchiebeButton();
yd1= ExtDialog.getYTPSchiebeButton();
xs1= ExtDialog.getXSIZETPSchiebeButton();
ys1= ExtDialog.getYSIZETPSchiebeButton();

/*
   xd1 = (int)ObjectGetInteger(0, REC1, OBJPROP_XDISTANCE);
   yd1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YDISTANCE);
   xs1 = (int)ObjectGetInteger(0, REC1, OBJPROP_XSIZE);
   ys1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YSIZE);
*/
// Button at price
   xd3 = xd1;
   yd3 = yd1 + (100);
   xs3 = xs1;
   ys3 = 30;

ExtDialog.setXd3Yd3(xd3,yd3);
ExtDialog.createButttonTrade_n_Send(xd3,yd3);
ExtDialog.setIsBuy(true);
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

   createButton(REC3, "", xd3, yd3, xs3, ys3, clrBlack, clrAqua, 9, clrNONE, "Arial Black");
   createButton(REC5, "", xd5, yd5, xs5, ys5, clrWhite, clrRed, 9, clrNONE, "Arial Black");

   ExtDialog.setNameTPSchiebeButton( "REC1: TP: " + DoubleToString(((Get_Price_d(TP_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
   //update_Text(REC1, "TP: " + DoubleToString(((Get_Price_d(TP_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
   update_Text(REC3, "Buy Stop @ " + Get_Price_s(PR_HL));
   update_Text(REC5, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));



   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE,0, true);
   ChartSetInteger(0,CHART_MOUSE_SCROLL,0,false);
   ChartSetInteger(0,CHART_SHIFT,0,true);
   ChartSetInteger(0,CHART_SHOW_GRID,0,false);
   ChartRedraw(0);



   double Entry_Price = StringToDouble(Get_Price_s(PR_HL));
   double TP_Price = StringToDouble(Get_Price_s(TP_HL));
   double SL_Price = StringToDouble(Get_Price_s(SL_HL));

   ChartRedraw();
   return (INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   ExtDialog.Destroy(reason);
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
bool buy_trade_exists=false;




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // Identifikator des Ereignisses
                  const long &lparam,   // Parameter des Ereignisses des Typs long, X cordinates
                  const double &dparam, // Parameter des Ereignisses des Typs double, Y cordinates
                  const string &sparam)  // Parameter des Ereignisses des Typs string, name of the object, state

  {
   ExtDialog.ChartEvent(id,lparam,dparam,sparam);


     
     
     
//+-----------------------------------------------------------------------------------------------------------------------------+
//|  Für die Ereignisse CHARTEVENT_MOUSE_MOVE enthält der Stringparameter sparam eine Zahl, die den Zustand der Tasten übergibt:|
//|  Bit |Beschreibung                                   |                                                                      |
//|   1  |Der Zustand der linken Maustaste               |                                                                      |
//|   2  |Der Zustand der rechten Maustaste              |                                                                      |
//|   3  |Der Zustand der SHIFT-Taste                    |                                                                      |
//|   4  |Der Zustand der CTRL-Taste                     |                                                                      |
//|   5  |Der Zustand der mittleren Maustaste            |                                                                      |
//|   6  |Der Zustand der ersten zusätzlichen Maustaste  |                                                                      |
//|   7  |Der Zustand der zweiten zusätzlichen Maustaste |                                                                      |
//+-----------------------------------------------------------------------------------------------------------------------------+
if(id == CHARTEVENT_MOUSE_MOVE)
  {
  
   int MouseD_X = (int)
                  lparam;
   int MouseD_Y = (int)dparam;
   int MouseState = (int)sparam;


int XD_R1 = ExtDialog.getXTPSchiebeButton(); // int XD_R1 = (int)ObjectGetInteger(0, REC1, OBJPROP_XDISTANCE);
int YD_R1 = ExtDialog.getYTPSchiebeButton(); //  int YD_R1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YDISTANCE);
int XS_R1 = ExtDialog.getXSIZETPSchiebeButton(); //   int XS_R1 = (int)ObjectGetInteger(0, REC1, OBJPROP_XSIZE);
int YS_R1 = ExtDialog.getYSIZETPSchiebeButton(); //   int YS_R1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YSIZE);

/*
   int XD_R1 = (int)ObjectGetInteger(0, REC1, OBJPROP_XDISTANCE);
   int YD_R1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YDISTANCE);
   int XS_R1 = (int)ObjectGetInteger(0, REC1, OBJPROP_XSIZE);
   int YS_R1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YSIZE);

*/
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
      Print ("movingState_R1");
      ChartSetInteger(0, CHART_MOUSE_SCROLL, false);

      //ObjectSetInteger(0, REC1, OBJPROP_YDISTANCE, mlbDownYD_R1 + MouseD_Y - mlbDownY1);
       ExtDialog.SchiebeButtonTPMove(XD_R1,mlbDownYD_R1 + MouseD_Y - mlbDownY1);
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

      update_Text(REC1, "REC1: TP: " + DoubleToString(((Get_Price_d(TP_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
      update_Text(REC5, "REC5: SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

      if((Get_Price_s(SL_HL)) > (Get_Price_s(TP_HL)))
        {
         ExtDialog.setIsBuy(true);
         update_Text(REC3, "Sell Stop @ " + Get_Price_s(PR_HL));
         update_Text(REC1, "REC1: TP: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(TP_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
         update_Text(REC5, "SL: " + DoubleToString(((Get_Price_d(SL_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));



        }
      else
        {
         update_Text(REC3, "Buy Stop @ " + Get_Price_s(PR_HL));
         ExtDialog.setIsBuy(false);

        }

      ChartRedraw(0);
     }

   if(movingState_R5)
     {
    // Print ("movingState_R5");
      ChartSetInteger(0, CHART_MOUSE_SCROLL, false);

      ObjectSetInteger(0, REC5, OBJPROP_YDISTANCE, mlbDownYD_R5 + MouseD_Y - mlbDownY5);
      ObjectSetInteger(0, REC1, OBJPROP_YDISTANCE, mlbDownYD_R1 - MouseD_Y + mlbDownY5);
      ExtDialog.SchiebeButtonTPMove(XD_R1,mlbDownYD_R1 - MouseD_Y + mlbDownY5);

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

      update_Text(REC1, "REC1: TP: " + DoubleToString(((Get_Price_d(TP_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
      update_Text(REC5, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

      if((Get_Price_s(SL_HL)) > (Get_Price_s(TP_HL)))
        {
        ExtDialog.setIsBuy(true);
         update_Text(REC3, "Sell Stop @ " + Get_Price_s(PR_HL));
         update_Text(REC1, "REC1: TP: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(TP_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));
         update_Text(REC5, "SL: " + DoubleToString(((Get_Price_d(SL_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

        }
      else
        {
         update_Text(REC3, "Buy Stop @ " + Get_Price_s(PR_HL));
       ExtDialog.setIsBuy(false);

        }

      ChartRedraw(0);
     }

   if(movingState_R3)
   
     {
   //  Print ("movingState_R3");
     
      ChartSetInteger(0, CHART_MOUSE_SCROLL, false);

      ObjectSetInteger(0, REC3, OBJPROP_YDISTANCE, mlbDownYD_R3 + MouseD_Y - mlbDownY3);

   
      //ObjectSetInteger(0, REC1, OBJPROP_YDISTANCE, mlbDownYD_R1 + MouseD_Y - mlbDownY1);
    ExtDialog.SchiebeButtonTPMove(XD_R1, mlbDownYD_R1 + MouseD_Y - mlbDownY1);
      ObjectSetInteger(0, REC5, OBJPROP_YDISTANCE, mlbDownYD_R5 + MouseD_Y - mlbDownY5);

      ObjectSetInteger(0, BTN2, OBJPROP_YDISTANCE, mlbDownYD_R3 + MouseD_Y - mlbDownY3);
      ObjectSetInteger(0, BTN3, OBJPROP_YDISTANCE, mlbDownYD_R3 + MouseD_Y - mlbDownY3);
      ExtDialog.setzeSendeButtonYDistance();
 

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

      update_Text(REC1, "REC1: TP: " + DoubleToString(((Get_Price_d(TP_HL) - Get_Price_d(PR_HL)) / _Point), 0) + " Points | " + Get_Price_s(TP_HL));

      if((Get_Price_s(SL_HL)) > (Get_Price_s(TP_HL)))
        {
         update_Text(REC3, "Sell Stop @ " + Get_Price_s(PR_HL));
        ExtDialog.setIsBuy(true);
         //Update Tradeinfo

        }
      else
        {
         update_Text(REC3, "Buy Stop @ " + Get_Price_s(PR_HL));
   ExtDialog.setIsBuy(false);

        }
      update_Text(REC5, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), 0) + " Points | " + Get_Price_s(SL_HL));

      ChartRedraw(0);
     }
     
     
      double Entry_Price = StringToDouble(Get_Price_s(PR_HL));
      double TP_Price = StringToDouble(Get_Price_s(TP_HL));
      double SL_Price = StringToDouble(Get_Price_s(SL_HL));

     ExtDialog.setPrices(Entry_Price,TP_Price,SL_Price);
     
   if(MouseState == 0)
     {
      movingState_R1 = false;
      movingState_R3 = false;
      movingState_R5 = false;
      ChartSetInteger(0, CHART_MOUSE_SCROLL, true);
     }
   prevMouseState = MouseState;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
if(ObjectGetInteger(0, "Button1", OBJPROP_STATE) != 0)
  {
   ObjectSetInteger(0, "Button1", OBJPROP_STATE, 0);
   return;
  }


// Klick Button Trade & Send
if(Trade_n_Send == true)
  {
   if(ObjectGetInteger(0, "Trade_n_Send", OBJPROP_STATE) != 0)
     {
      ObjectSetInteger(0, "Trade_n_Send", OBJPROP_STATE, 0);


      double Entry_Price = StringToDouble(Get_Price_s(PR_HL));
      double TP_Price = StringToDouble(Get_Price_s(TP_HL));
      double SL_Price = StringToDouble(Get_Price_s(SL_HL));



      // Send notification before placing trade
      //TODO:: Implement senden

      //Todo: Zähler Messages to Discord

      double SL_Points = (Entry_Price - SL_Price) / _Point;
      SL_Points = NormalizeDouble(SL_Points, _Digits);

      string REC3Text = ObjectGetString(0,REC3,OBJPROP_TEXT);
      string REC3Text2 = StringSubstr(REC3Text,0,3);

      string m_type= OrderProperties();
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

  }




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
   ObjectDelete(0, "Send_Only");
   ObjectDelete(0, "Trade_n_Send");
   ObjectDelete(0, "ButtonTargetReached");
   ObjectDelete(0, "ButtonStoppedout");
   ObjectDelete(0, "ButtonCancelOrder");

   ChartRedraw(0);
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string OrderProperties()
  {
//--- in einer Schleife durch die Liste aller Orders des Kontos
   int total=OrdersTotal();
   string type;
   for(int i=0; i<total; i++)
     {
      //--- Abrufen des Order-Tickets in der Liste über den Schleifenindex
      ulong ticket=OrderGetTicket(i);
      if(ticket==0)
         continue;

      //--- Auftragstyp abrufen und Kopfzeile für die Liste der String-Eigenschaften des ausgewählten Auftrags anzeigen
      type=OrderTypeDescription((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE));
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
   return type;
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
      case ORDER_TYPE_BUY              :
         return("Buy");
      case ORDER_TYPE_SELL             :
         return("Sell");
      case ORDER_TYPE_BUY_LIMIT        :
         return("Buy Limit");
      case ORDER_TYPE_SELL_LIMIT       :
         return("Sell Limit");
      case ORDER_TYPE_BUY_STOP         :
         return("Buy Stop");
      case ORDER_TYPE_SELL_STOP        :
         return("Sell Stop");
      case ORDER_TYPE_BUY_STOP_LIMIT   :
         return("Buy Stop Limit");
      case ORDER_TYPE_SELL_STOP_LIMIT  :
         return("Sell Stop Limit");
      default                          :
         return("Unknown order type: "+(string)type);
     }
  }
//+------------------------------------------------------------------+




//+------------------------------------------------------------------+


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
