//+------------------------------------------------------------------+
//|                                        Trade Assistent V1.20.mq5 |
//|                                 Michael Keller, Steffen Kachold |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Michael Keller, Steffen Kachold"
#property link      "https://github.com/saaralf/DowHowSignalService"
#property version   "1.31.01"
string    Version = "1.31.01";


#property description "Calculates risk-based position size for your account."
#property description "Allows trade execution based the calculation results.\r\n"
#property description "WARNING: No warranty. This EA is offered \"as is\". Use at your own risk.\r\n"



#include "Dialog.mqh"
#include <Trade\Trade.mqh>
#include "methoden.mqh"
/* History
   21.01.2025     Ein Panel erzeugt und alle Buttons in dieses Panel übernommen. Die HR Linien sind nun mit den Buttons verbunden.
                  Bekannte Fehler: Beim starten des AE werden die HR Linien falsch gezeichnet. Erst ein Klick auf einen Button zeichnet die an der korrekten Stelle.
   
   16.01.2025-    OnClick-Ereignis für die Messagebutton implementiert SK
                  begonnen das Auslesen von laufenden Trades und platzierten Orders zu implementieren
   ´
   
   15.01.2025 -   Möglichkeit Einstellung Button X-Achse von Links  SK
                  Button Target für Target Reached, Trade Stopped Out und Cancel Trade hinzugefügt SK
                  SendButton in Void ausgelagert   SK
                  Senden an Discord bei Trade & Send implementiert   SK

   
*/






//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+

CTrade trade;
CPositionInfo PositionInfo;
COrderInfo OrderInfo;

// Default values for settings: // saaralf: ??? warum
double EntryLevel = 0;
double StopLossLevel = 0;
double TakeProfitLevel = 0;
double StopPriceLevel = 0;
// Ende warum

double Entry_Price;
double TP_Price ;
double SL_Price ;


//Prüfen ob wir die noch brauchen!!!
int
xd1,
yd1, xs1, ys1,
xd2, yd2, xs2, ys2,
xd3, yd3, xs3, ys3,
xd4, yd4, xs4, ys4,
xd5, yd5, xs5, ys5;

int OTotal = OrdersTotal();
int PTotal = PositionsTotal();


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



// string otype = "";



CControlsDialog ExtDialog;



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
   ExtDialog.updatePriceHLTP();
   ExtDialog.updatePriceHLSL();
   ExtDialog.updatePriceHLTP();
   ChartRedraw(0);

   ExtDialog.setIsBuy(true);

   ExtDialog.updateTextSchiebeButtonTP("TP: " + DoubleToString(((ExtDialog.GetPriceDHLTP() - ExtDialog.GetPriceDHLPR()) / _Point), 0) + " Points | " + ExtDialog.GetPriceSHLTP());
   ExtDialog.updateTextSchiebeButtonPR("Buy Stop @ " + ExtDialog.GetPriceSHLPR());
   ExtDialog.updateTextSchiebeButtonSL("SL: " + DoubleToString(((ExtDialog.GetPriceDHLPR() - ExtDialog.GetPriceDHLSL()) / _Point), 0) + " Points | " + ExtDialog.GetPriceSHLSL());

   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE,0, true);
   ChartSetInteger(0,CHART_MOUSE_SCROLL,0,false);
   ChartSetInteger(0,CHART_SHIFT,0,true);
   ChartSetInteger(0,CHART_SHOW_GRID,0,false);

   ChartRedraw(0);
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
   ExtDialog.updatePriceHLTP();
   ExtDialog.updatePriceHLSL();
   ExtDialog.updatePriceHLTP();
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

   if(id==CHARTEVENT_OBJECT_CREATE)
     {
      ExtDialog.updatePriceHLTP();
      ExtDialog.updatePriceHLSL();
      ExtDialog.updatePriceHLTP();
     }
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


      int XD_R1 = ExtDialog.getXSchiebeButtonTP(); // int XD_R1 = (int)ObjectGetInteger(0, REC1, OBJPROP_XDISTANCE);
      int YD_R1 = ExtDialog.getYSchiebeButtonTP(); //  int YD_R1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YDISTANCE);
      int XS_R1 = ExtDialog.getXSIZESchiebeButtonTP(); //   int XS_R1 = (int)ObjectGetInteger(0, REC1, OBJPROP_XSIZE);
      int YS_R1 = ExtDialog.getYSIZESchiebeButtonTP(); //   int YS_R1 = (int)ObjectGetInteger(0, REC1, OBJPROP_YSIZE);



      int XD_R3 = ExtDialog.getXSchiebeButtonPR();
      int YD_R3 = ExtDialog.getYSchiebeButtonPR();
      int XS_R3 = ExtDialog.getXSIZESchiebeButtonPR();
      int YS_R3 = ExtDialog.getYSIZESchiebeButtonPR();


      int XD_R5 = ExtDialog.getXSchiebeButtonSL();
      int YD_R5 = ExtDialog.getYSchiebeButtonSL();
      int XS_R5 = ExtDialog.getXSIZESchiebeButtonSL();
      int YS_R5 = ExtDialog.getYSIZESchiebeButtonSL();



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
         Print("movingState_R1");
         ChartSetInteger(0, CHART_MOUSE_SCROLL, false);


         ExtDialog.SchiebeButtonMoveTP(XD_R1,mlbDownYD_R1 + MouseD_Y - mlbDownY1);
         ExtDialog.SchiebeButtonMoveSL(XD_R5,mlbDownYD_R5 - MouseD_Y + mlbDownY1);

         ExtDialog.updatePriceHLTP();
         ExtDialog.updatePriceHLSL();

         ExtDialog.updateTextSchiebeButtonTP("TP: " + DoubleToString(((ExtDialog.GetPriceDHLTP() - ExtDialog.GetPriceDHLPR()) / _Point), 0) + " Points | " + ExtDialog.GetPriceSHLTP());
         ExtDialog.updateTextSchiebeButtonSL("SL: " + DoubleToString(((ExtDialog.GetPriceDHLPR() - ExtDialog.GetPriceDHLSL()) / _Point), 0) + " Points | " + ExtDialog.GetPriceSHLSL());

         if((ExtDialog.GetPriceDHLSL()) > (ExtDialog.GetPriceDHLTP())) // Dann ist SELL Preise
           {
            ExtDialog.setIsBuy(false);
            ExtDialog.updateTextSchiebeButtonPR("Sell Stop @ " + ExtDialog.GetPriceSHLPR());
            ExtDialog.updateTextSchiebeButtonTP("TP: " + DoubleToString(((ExtDialog.GetPriceDHLPR() - ExtDialog.GetPriceDHLTP()) / _Point), 0) + " Points | " + ExtDialog.GetPriceSHLTP());
            ExtDialog.updateTextSchiebeButtonSL("SL: " + DoubleToString(((ExtDialog.GetPriceDHLSL() - ExtDialog.GetPriceDHLPR()) / _Point), 0) + " Points | " + ExtDialog.GetPriceSHLSL());
           }
         else
           {
            ExtDialog.updateTextSchiebeButtonPR("Buy Stop @ " + ExtDialog.GetPriceSHLPR());
            ExtDialog.setIsBuy(true);
           }
         ChartRedraw(0);
        }

      if(movingState_R5)
        {
         // Print ("movingState_R5");
         ChartSetInteger(0, CHART_MOUSE_SCROLL, false);

         ExtDialog.SchiebeButtonMoveSL(XD_R5,mlbDownYD_R5 + MouseD_Y - mlbDownY5);
         ExtDialog.SchiebeButtonMoveTP(XD_R1,mlbDownYD_R1 - MouseD_Y + mlbDownY5);
         ExtDialog.updatePriceHLTP();
         ExtDialog.updatePriceHLSL();



         ExtDialog.updateTextSchiebeButtonTP("TP: " + DoubleToString(((ExtDialog.GetPriceDHLTP() - ExtDialog.GetPriceDHLPR()) / _Point), 0) + " Points | " + ExtDialog.GetPriceSHLTP());
         ExtDialog.updateTextSchiebeButtonSL("SL: " + DoubleToString(((ExtDialog.GetPriceDHLPR() - ExtDialog.GetPriceDHLSL()) / _Point), 0) + " Points | " + ExtDialog.GetPriceSHLSL());

         if((ExtDialog.GetPriceDHLSL()) > (ExtDialog.GetPriceDHLTP())) // Dann ist SELL Preise
           {
            ExtDialog.setIsBuy(false);
            ExtDialog.updateTextSchiebeButtonPR("Sell Stop @ " + ExtDialog.GetPriceSHLPR());
            ExtDialog.updateTextSchiebeButtonTP("TP: " + DoubleToString(((ExtDialog.GetPriceDHLPR() - ExtDialog.GetPriceDHLTP()) / _Point), 0) + " Points | " + ExtDialog.GetPriceSHLTP());
            ExtDialog.updateTextSchiebeButtonSL("SL: " + DoubleToString(((ExtDialog.GetPriceDHLSL() - ExtDialog.GetPriceDHLPR()) / _Point), 0) + " Points | " + ExtDialog.GetPriceSHLSL());

           }
         else
           {
            ExtDialog.updateTextSchiebeButtonPR("Buy Stop @ " + ExtDialog.GetPriceSHLPR());
            ExtDialog.setIsBuy(true);
           }
         ChartRedraw(0);
        }

      if(movingState_R3)

        {
         ChartSetInteger(0, CHART_MOUSE_SCROLL, false);
         ExtDialog.SchiebeButtonMovePR(XD_R3,mlbDownYD_R3 + MouseD_Y - mlbDownY3);
         ExtDialog.SchiebeButtonMoveTP(XD_R1, mlbDownYD_R1 + MouseD_Y - mlbDownY1);

         ExtDialog.SchiebeButtonMoveSL(XD_R5,mlbDownYD_R5 + MouseD_Y - mlbDownY5);
         ExtDialog.SchiebeButtonMoveTradeNSend(ExtDialog.getXSchiebeButtonTradeNSend(),  mlbDownYD_R3 + MouseD_Y - mlbDownY3);

         ExtDialog.updatePriceHLTP();
         ExtDialog.updatePriceHLSL();
         ExtDialog.updatePriceHLTP();
         ExtDialog.updateTextSchiebeButtonTP("TP: " + DoubleToString(((ExtDialog.GetPriceDHLTP() - ExtDialog.GetPriceDHLPR()) / _Point), 0) + " Points | " + ExtDialog.GetPriceSHLTP());
         ExtDialog.updateTextSchiebeButtonSL("SL: " + DoubleToString(((ExtDialog.GetPriceDHLPR() - ExtDialog.GetPriceDHLSL()) / _Point), 0) + " Points | " + ExtDialog.GetPriceSHLSL());
         if((ExtDialog.GetPriceDHLSL()) > (ExtDialog.GetPriceDHLTP())) // Dann ist SELL Preise
           {
            ExtDialog.updateTextSchiebeButtonPR("Sell Stop @ " + ExtDialog.GetPriceSHLPR());
            ExtDialog.setIsBuy(false);
            //Update Tradeinfo

           }
         else
           {
            ExtDialog.updateTextSchiebeButtonPR("Buy Stop @ " + ExtDialog.GetPriceSHLPR());
            ExtDialog.setIsBuy(true);

           }

         ChartRedraw(0);
        }


      if((ExtDialog.GetPriceDHLSL()) > (ExtDialog.GetPriceDHLTP())) // Dann ist SELL Preise
        {
         ExtDialog.updateTextSchiebeButtonPR("Sell Stop @ " + ExtDialog.GetPriceSHLPR());
         ExtDialog.setIsBuy(false);
         //Update Tradeinfo

        }
      else
        {
         ExtDialog.updateTextSchiebeButtonPR("Buy Stop @ " + ExtDialog.GetPriceSHLPR());
         ExtDialog.setIsBuy(true);

        }



 
         double Entry_Price = ExtDialog.GetPriceDHLPR();
         double TP_Price = ExtDialog.GetPriceDHLTP();
         double SL_Price = ExtDialog.GetPriceDHLSL();
         

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

// Klick Button Trade & Send
   if(Trade_n_Send == true)
     {
      if(ObjectGetInteger(0, "Trade_n_Send", OBJPROP_STATE) != 0)
        {
         ObjectSetInteger(0, "Trade_n_Send", OBJPROP_STATE, 0);


         double Entry_Price = ExtDialog.GetPriceDHLPR();
         double TP_Price = ExtDialog.GetPriceDHLTP();
         double SL_Price = ExtDialog.GetPriceDHLSL();
         
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
