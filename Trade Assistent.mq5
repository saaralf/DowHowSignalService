//+------------------------------------------------------------------+
//|                                              Trade Assistant.mq5 |
//|                                 Michael Keller & Steffen Kachold |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Michael Keller & Steffen Kachold"
#property link ""
#property version "2.00"
#include "methoden.mqh"
#include "DowHowClassen.mqh"
#include <Trade/Trade.mqh>
CTrade trade;

// Default values for settings:
double EntryLevel = 0;
double StopLossLevel = 0;
double TakeProfitLevel = 0;
double StopPriceLevel = 0;
double Entry_Price = 0;
double TP_Price = 0;
double SL_Price = 0;

datetime dt_tp = 0;                               // datetime der TP HL Linie
datetime dt_sl = 0;                               // Datetime der SL HL Linie
datetime dt_prc = 0;                              // Datetime der Preis HL Linie
double price_tp = 0, price_sl = 0, price_prc = 0; // Preis der entsprechenden TP. SL und Preis HL Linie
int window = 0;

// Größe der Buttons
int button_breite = 500;
int button_hoehe = 30;

// Button1 = input parameters for Trade & Send = Send only
// Button2 = Send only
// Button3 = Trade & Send
// only one button is visible

input group "label & fonts" input color Button1_bgcolor = clrRed; // Button Color Please check settings
input color Button1_font_color = clrBlack;                        // Font Color Button Please check settings
input uint Button1_font_size = 15;                                // Font Size Button Please check settings
input color Button2_bgcolor = clrForestGreen;                     // Button Color Send only
input color Button2_font_color = clrBlack;                        // Font Color Button Send only
input uint Button2_font_size = 10;                                // Font Size Button Trade & Send
input color Button3_bgcolor = clrGray;                            // Button Color Trade & Send
input color Button3_font_color = clrRed;                          // Font Color Button Trade & Send
input uint Button3_font_size = 10;                                // Font Size Button Trade & Send
// input string font_face = "Courier"; // Labels Font Face
// input color entry_line_color = clrAqua; // Entry Line Color
// input color stoploss_line_color = clrRed; // Stop-Loss Line Color
// input color takeprofit_line_color = clrLime; // Take-Profit Line Color
// input color stopprice_line_color = clrPurple; // Stop Price Line Color
// input color be_line_color = clrNONE; // BE Line Color
// input ENUM_LINE_STYLE entry_line_style = STYLE_SOLID; // Entry Line Style
// input ENUM_LINE_STYLE stoploss_line_style = STYLE_SOLID; // Stop-Loss Line Stylek
// input ENUM_LINE_STYLE takeprofit_line_style = STYLE_SOLID; // Take-Profit Line Style
// input ENUM_LINE_STYLE stopprice_line_style = STYLE_DOT; // Stop Price Line Style
// input ENUM_LINE_STYLE be_line_style = STYLE_DOT; // BE Line Style
// input uint entry_line_width = 1; // Entry Line Width
// input uint stoploss_line_width = 1; // Stop-Loss Line Width
// input uint takeprofit_line_width = 1; // Take-Profit Line Width
// input uint stopprice_line_width = 1; // Stop Price Line Width
// input uint be_line_width = 1; // BE Line Width
input group "Defaults"
    // input int buttonwidth =200; // Button breite in Pixel
    // input int buttonhigh =80;// Button Höhe in Pixel
    input bool Button2 = true; // Send only
input bool Button3 = false;    // Trade & Send
// input bool TradeandSend = false;
//input double DefaultRisk = 1; // Risk in %
// input double DefaultMoneyRisk = 0; // MoneyRisk: If > 0, money risk tolerance in currency.
// input double DefaultPositionSize = 0; // PositionSize: If > 0, position size in lots.
// input int DefaultMagicNumber = 2022052714; // MagicNumber: Default magic number for Trading tab.
// input bool DefaultTPLockedOnSL = true; // TPLockedOnSL: Lock TP to (multiplied) SL distance.
// input double TP_Multiplier = 1.00; // TP Multiplier for SL value, appears in Take-profit button.
// input group "Discord"
// input string Target_Channel = "Intraday-M2"; //Target Channel

bool CheckForExistingLongPosition();

#define REC_TP "REC_TP"
#define REC_BS "REC_BS"
#define REC_SL "REC_SL"
#define BTN1 "Button1"
#define BTN2 "Button2"
#define BTN3 "Button3"
#define POINTDIGITS 0
#define TP_HL "TP_HL"
#define SL_HL "SL_HL"
#define PR_HL "PR_HL"


// Classen instancen erzeugen
ButtonWithHL tp_button(REC_TP);
ButtonWithHL bs_button(REC_BS);
ButtonWithHL sl_button(REC_SL);


       
string m_webhook = "https://discord.com/api/webhooks/1313603118768062575/TPHxceiomoSnyZmp4RZnKtwzM2U4ptc-lTCcnUxj4qqpo1UdXedoyRQaB_Gv-gE9JDSP";

/*
void get_tp_line_price()
{
   // Ermittelt den Preis und Datum der TP Preis Linie, abhängig vom Rechtec REC_TP
   // Der Preis für die Linie ist immer die Mitte des Rechecks, welches wir über der Linie gezeichnet haben.
   // ChartXYToTimePrice(0,x_pos_rec_tp  ,y_pos_rec_tp+y_size_rec_tp/2,window     , dt_tp  , price_tp);

   int XD_R1 = (int)ObjectGetInteger(0, REC_TP, OBJPROP_XDISTANCE);
   int YD_R1 = (int)ObjectGetInteger(0, REC_TP, OBJPROP_YDISTANCE);
   int XS_R1 = (int)ObjectGetInteger(0, REC_TP, OBJPROP_XSIZE);
   int YS_R1 = (int)ObjectGetInteger(0, REC_TP, OBJPROP_YSIZE);

   ChartXYToTimePrice(0, (int)ObjectGetInteger(0, REC_TP, OBJPROP_XDISTANCE), (int)ObjectGetInteger(0, REC_TP, OBJPROP_YDISTANCE) + (int)ObjectGetInteger(0, REC_TP, OBJPROP_YSIZE) / 2, window, dt_tp, price_tp);
}*/
double y_pos_rec_pr; // Damit tp_button.getydistance() + (100 * DefaultRisk); korrekt funktioniert
int
    x_pos_rec_tp,
    y_pos_rec_tp, x_size_rec_tp, y_size_rec_tp,
    xd2, yd2, xs2, ys2,
    y_size_rec_pr,
    xd4, yd4, xs4, ys4,
    x_pos_rec_sl, y_pos_rec_sl, x_size_rec_sl, y_size_rec_sl;
int x_pos_rec_pr,  x_size_rec_pr;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{

  //--- enable object create events
   ChartSetInteger(ChartID(),CHART_EVENT_OBJECT_CREATE,true);

    // TP Button
    int x_position = ChartWidthInPixels() - 500 - 20;
    int y_position = ChartHeightInPixelsGet() / 2;
    tp_button.CreateButton("", x_position, button_breite, y_position, button_hoehe, clrWhite, clrGreen, 12, clrWhite, clrGreen, TP_HL, "Arial Black");

    x_pos_rec_tp = tp_button.getXdistance();
    y_pos_rec_tp = tp_button.getydistance();
    x_size_rec_tp = tp_button.getxsize();
    y_size_rec_tp = tp_button.getysize();
    tp_button.toString();

    // Button at price (PEC_BS)
    x_pos_rec_pr = x_position;
    y_pos_rec_pr = tp_button.getydistance() + (100 * DefaultRisk);
    x_size_rec_pr = button_breite;
    y_size_rec_pr = button_hoehe;

    bs_button.CreateButton("", x_pos_rec_pr, x_size_rec_pr, (int)y_pos_rec_pr, y_size_rec_pr, clrBlack, clrAqua, 12, clrNONE, clrAqua, PR_HL, "Arial Black");
    bs_button.toString();

    // SL Button
    x_pos_rec_sl = x_position;
    y_pos_rec_sl = bs_button.getydistance() + 100;
    x_size_rec_sl = button_breite;
    y_size_rec_sl = button_hoehe;
    sl_button.CreateButton("", x_pos_rec_sl, x_size_rec_sl, y_pos_rec_sl, y_size_rec_sl, clrWhite, clrRed, 12, clrNONE, clrWhite, SL_HL, "Arial Black");
    sl_button.toString();
   
    tp_button.update_Text("TP: " + DoubleToString(((1.0*tp_button.gethlpricedouble() - bs_button.gethlpricedouble()) / _Point), POINTDIGITS) + " Points | " + tp_button.gethlpricestring());
    
    //update_Text(REC_TP, "TP: " + DoubleToString(((1.0*tp_button.gethlpricedouble() - bs_button.gethlpricedouble()) / _Point), POINTDIGITS) + " Points | " + tp_button.gethlpricestring());
   bs_button.update_Text("Buy Stop @ " + bs_button.gethlpricestring());
   // update_Text(REC_BS, "Buy Stop @ " + bs_button.gethlpricestring());

    //update_Text(REC_SL, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), POINTDIGITS) + " Points | " + Get_Price_s(SL_HL));
sl_button.update_Text("SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), POINTDIGITS) + " Points | " + Get_Price_s(SL_HL));
   
   
   
    if ((Button2 == true && Button3 == true) || (Button2 == false && Button3 == false))
    {
        ObjectCreate(0, "Button1", OBJ_BUTTON, 0, 0, 0);
        ObjectSetInteger(0, "Button1", OBJPROP_XDISTANCE, 600);               // X position
        ObjectSetInteger(0, "Button1", OBJPROP_XSIZE, 300);                   // width
        ObjectSetInteger(0, "Button1", OBJPROP_YDISTANCE, 300);               // Y position
        ObjectSetInteger(0, "Button1", OBJPROP_YSIZE, 50);                    // height
        ObjectSetInteger(0, "Button1", OBJPROP_CORNER, 0);                    // chart corner
        ObjectSetString(0, "Button1", OBJPROP_TEXT, "Please check settings"); // label
        ObjectSetInteger(0, "Button1", OBJPROP_BGCOLOR, Button1_bgcolor);
        ObjectSetInteger(0, "Button1", OBJPROP_COLOR, Button1_font_color);
        ObjectSetInteger(0, "Button1", OBJPROP_FONTSIZE, Button1_font_size);
    }
    else

        if (Button2 == true && Button3 == false)
    {
        ObjectCreate(0, "Button2", OBJ_BUTTON, 0, 0, 0);
        ObjectSetInteger(0, "Button2", OBJPROP_XDISTANCE, x_pos_rec_pr - 100); // X position
        ObjectSetInteger(0, "Button2", OBJPROP_XSIZE, 100);                    // width
        ObjectSetInteger(0, "Button2", OBJPROP_YDISTANCE, (int)y_pos_rec_pr);       // Y position
        ObjectSetInteger(0, "Button2", OBJPROP_YSIZE, 30);                     // height
        ObjectSetInteger(0, "Button2", OBJPROP_CORNER, 0);                     // chart corner
        ObjectSetString(0, "Button2", OBJPROP_TEXT, "Send only");              // label
        ObjectSetInteger(0, "Button2", OBJPROP_COLOR, Button2_font_color);
        ObjectSetInteger(0, "Button2", OBJPROP_FONTSIZE, Button2_font_size);
        ObjectSetInteger(0, "Button2", OBJPROP_BGCOLOR, Button2_bgcolor);
    }
    else

        if (Button2 == false && Button3 == true)
    {
        ObjectCreate(0, "Button3", OBJ_BUTTON, 0, 0, 0);
        ObjectSetInteger(0, "Button3", OBJPROP_XDISTANCE, (int)x_pos_rec_pr - 100); // X position
        ObjectSetInteger(0, "Button3", OBJPROP_XSIZE, 100);                         // width
        ObjectSetInteger(0, "Button3", OBJPROP_YDISTANCE, (int)y_pos_rec_pr);       // Y position
        ObjectSetInteger(0, "Button3", OBJPROP_YSIZE, 30);                          // height
        ObjectSetInteger(0, "Button3", OBJPROP_CORNER, 0);                          // chart corner
        ObjectSetString(0, "Button3", OBJPROP_TEXT, "T & S");                       // label
        ObjectSetInteger(0, "Button3", OBJPROP_BGCOLOR, Button3_bgcolor);
        ObjectSetInteger(0, "Button3", OBJPROP_COLOR, Button3_font_color);
        ObjectSetInteger(0, "Button3", OBJPROP_FONTSIZE, Button3_font_size);
    }

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

int mlbDownX3 = 0;
int mlbDownY3 = 0;
int mlbDownXD_R3 = 0;
int mlbDownYD_R3 = 0;

int mlbDownX5 = 0;
int mlbDownY5 = 0;
int mlbDownXD_R5 = 0;
int mlbDownYD_R5 = 0;

int mlbDownXButton1 = 0;
int mlbDownYButton1 = 0;
int mlbDownXD_Button1 = 0;
int mlbDownYD_Button1 = 0;

int mlbDownXButton2 = 0;
int mlbDownYButton2 = 0;
int mlbDownXD_Button2 = 0;
int mlbDownYD_Button2 = 0;

int mlbDownXButton3 = 0;
int mlbDownYButton3 = 0;
int mlbDownXD_Button3 = 0;
int mlbDownYD_Button3 = 0;

bool movingState_Rec_tp_1 = false;
bool movingState_R3 = false;
bool movingState_R5 = false;
bool movingState_Button1 = false;
bool movingState_Button2 = false;
bool movingState_Button3 = false;

void OnChartEvent(const int id,         // Identifikator des Ereignisses
                  const long &lparam,   // Parameter des Ereignisses des Typs long, X cordinates
                  const double &dparam, // Parameter des Ereignisses des Typs double, Y cordinates
                  const string &sparam  // Parameter des Ereignisses des Typs string, name of the object, state
)
{
/*
Print ("HL TP Price: "+(string)tp_button.gethlpricedouble());
Print ("HL TP difference zu BS: "+DoubleToString(((tp_button.gethlpricedouble() - Get_Price_d(PR_HL)) / _Point), POINTDIGITS));
Print ("HL BS Price: "+(string)bs_button.gethlpricedouble());
Print ("HL SL Price: "+(string)sl_button.gethlpricedouble());
*/

    tp_button.setXdistance(ChartWidthInPixels() - 500 - 20);
    bs_button.setXdistance(ChartWidthInPixels() - 500 - 20);
    sl_button.setXdistance(ChartWidthInPixels() - 500 - 20);
    tp_button.setydistance(tp_button.getydistance());
    bs_button.setydistance(bs_button.getydistance());
    sl_button.setydistance(sl_button.getydistance());
    if (id == CHART_SHIFT)
    {
        ChartRedraw(0);
    }

    if (ChartGetInteger(0, CHART_IS_MAXIMIZED))
    {

        tp_button.setXdistance(ChartWidthInPixels() - 500 - 20);
        bs_button.setXdistance(ChartWidthInPixels() - 500 - 20);
        sl_button.setXdistance(ChartWidthInPixels() - 500 - 20);
        tp_button.setydistance(tp_button.getydistance());
        bs_button.setydistance(bs_button.getydistance());
        sl_button.setydistance(sl_button.getydistance());
        ChartRedraw(0);
        
        
    }

if (id ==CHARTEVENT_OBJECT_CLICK )
{

   if (sparam=="Button2")
   {
                      ObjectSetInteger(0,"Button2", OBJPROP_BGCOLOR,clrDarkOrange);// Farbe vorübergehend ändern - zur Verdeutlichung, dass der Klick angekommen ist
        Print("senden an Discord");
            SendWebhook();
          
          
           ObjectSetInteger(0,"Button2", OBJPROP_BGCOLOR,Button2_bgcolor);// Farbe vorübergehend ändern - zur Verdeutlichung, dass der Klick angekommen ist
   }


}


    if (id == CHARTEVENT_MOUSE_MOVE)
    {
        int MouseD_X = (int)lparam;
        int MouseD_Y = (int)dparam;
        int MouseState = (int)sparam;

        // Speichere Koordinaten vom TP Button
        int XD_R1 = tp_button.getXdistance();
        int YD_R1 = tp_button.getydistance();
        int XS_R1 = tp_button.getxsize();
        int YS_R1 = tp_button.getysize();

        /*
         int XD_R1 = (int)ObjectGetInteger(0, REC_TP, OBJPROP_XDISTANCE);
         int YD_R1 = (int)ObjectGetInteger(0, REC_TP, OBJPROP_YDISTANCE);
         int XS_R1 = (int)ObjectGetInteger(0, REC_TP, OBJPROP_XSIZE);
         int YS_R1 = (int)ObjectGetInteger(0, REC_TP, OBJPROP_YSIZE);
   */
        
               
        int XD_R3 = bs_button.getXdistance(); //(int)ObjectGetInteger(0, REC_BS, OBJPROP_XDISTANCE);
        /*   int YD_R3 = (int)ObjectGetInteger(0, REC_BS, OBJPROP_YDISTANCE);
        int XS_R3 = (int)ObjectGetInteger(0, REC_BS, OBJPROP_XSIZE);
        int YS_R3 = (int)ObjectGetInteger(0, REC_BS, OBJPROP_YSIZE); 
          */
        //int XD_R3 = (int)ObjectGetInteger(0, REC_BS, OBJPROP_XDISTANCE);
        int YD_R3 = (int)ObjectGetInteger(0, REC_BS, OBJPROP_YDISTANCE);
        int XS_R3 = (int)ObjectGetInteger(0, REC_BS, OBJPROP_XSIZE);
        int YS_R3 = (int)ObjectGetInteger(0, REC_BS, OBJPROP_YSIZE);

        int XD_R5 = (int)ObjectGetInteger(0, REC_SL, OBJPROP_XDISTANCE);
        int YD_R5 = (int)ObjectGetInteger(0, REC_SL, OBJPROP_YDISTANCE);
        int XS_R5 = (int)ObjectGetInteger(0, REC_SL, OBJPROP_XSIZE);
        int YS_R5 = (int)ObjectGetInteger(0, REC_SL, OBJPROP_YSIZE);

        int XD_Button1 = (int)ObjectGetInteger(0, BTN1, OBJPROP_XDISTANCE);
        int YD_Button1 = (int)ObjectGetInteger(0, BTN1, OBJPROP_YDISTANCE);
        int XS_Button1 = (int)ObjectGetInteger(0, BTN1, OBJPROP_XSIZE);
        int YS_Button1 = (int)ObjectGetInteger(0, BTN1, OBJPROP_YSIZE);

        int XD_Button2 = (int)ObjectGetInteger(0, BTN2, OBJPROP_XDISTANCE);
        int YD_Button2 = (int)ObjectGetInteger(0, BTN2, OBJPROP_YDISTANCE);
        int XS_Button2 = (int)ObjectGetInteger(0, BTN2, OBJPROP_XSIZE);
        int YS_Button2 = (int)ObjectGetInteger(0, BTN2, OBJPROP_YSIZE);

        int XD_Button3 = (int)ObjectGetInteger(0, BTN3, OBJPROP_XDISTANCE);
        int YD_Button3 = (int)ObjectGetInteger(0, BTN3, OBJPROP_YDISTANCE);
        int XS_Button3 = (int)ObjectGetInteger(0, BTN3, OBJPROP_XSIZE);
        int YS_Button3 = (int)ObjectGetInteger(0, BTN3, OBJPROP_YSIZE);

        if (prevMouseState == 0 && MouseState == 1) // 1 = true: clicked left mouse btn
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

            mlbDownXButton1 = MouseD_X;
            mlbDownYButton1 = MouseD_Y;
            mlbDownXD_Button1 = XD_Button1;
            mlbDownYD_Button1 = YD_Button1;

            mlbDownXButton2 = MouseD_X;
            mlbDownYButton2 = MouseD_Y;
            mlbDownXD_Button2 = XD_Button2;
            mlbDownYD_Button2 = YD_Button2;

            mlbDownXButton3 = MouseD_X;
            mlbDownYButton3 = MouseD_Y;
            mlbDownXD_Button3 = XD_Button3;
            mlbDownYD_Button3 = YD_Button3;

            if (MouseD_X >= XD_R1 && MouseD_X <= XD_R1 + XS_R1 &&
                MouseD_Y >= YD_R1 && MouseD_Y <= YD_R1 + YS_R1)
            {
                movingState_Rec_tp_1 = true; // TP Rechteck wurde gemoved
            }

            if (MouseD_X >= XD_R3 && MouseD_X <= XD_R3 + XS_R3 &&
                MouseD_Y >= YD_R3 && MouseD_Y <= YD_R3 + YS_R3)
            {
                movingState_R3 = true;
            }

            if (MouseD_X >= XD_R5 && MouseD_X <= XD_R5 + XS_R5 &&
                MouseD_Y >= YD_R5 && MouseD_Y <= YD_R5 + YS_R5)
            {
                movingState_R5 = true;
            }

            if (MouseD_X >= XD_Button1 && MouseD_X <= XD_Button1 + XS_Button1 &&
                MouseD_Y >= YD_Button1 && MouseD_Y <= YD_Button1 + YS_Button1)
            {
                movingState_Button1 = true;
            }

            if (MouseD_X >= XD_Button2 && MouseD_X <= XD_Button2 + XS_Button2 &&
                MouseD_Y >= YD_Button2 && MouseD_Y <= YD_Button2 + YS_Button2)
            {
                movingState_Button2 = true;
            }

            if (MouseD_X >= XD_Button3 && MouseD_X <= XD_Button3 + XS_Button3 &&
                MouseD_Y >= YD_Button3 && MouseD_Y <= YD_Button3 + YS_Button3)
            {
                movingState_Button3 = true;
            }
        }

        if (movingState_Rec_tp_1)
        {
              ObjectSetInteger(0, tp_button.getName(),OBJPROP_STATE,true); 
            ChartSetInteger(0,CHART_AUTOSCROLL,false); // disable autoscroll 
            ChartSetInteger(0, CHART_MOUSE_SCROLL, false);
            tp_button.setydistance(mlbDownYD_R1 + MouseD_Y - mlbDownY1);

           
            sl_button.setydistance(mlbDownYD_R5 - MouseD_Y + mlbDownY1);

            update_Text(REC_TP, "TP: " + DoubleToString(((Get_Price_d(TP_HL) - Get_Price_d(PR_HL)) / _Point), POINTDIGITS) + " Points | " + Get_Price_s(TP_HL));
            update_Text(REC_SL, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), POINTDIGITS) + " Points | " + Get_Price_s(SL_HL));
            
      

            

            if ((Get_Price_s(SL_HL)) > (Get_Price_s(TP_HL)))
            {
                update_Text(REC_BS, "Sell Stop @ " + Get_Price_s(PR_HL));
                update_Text(REC_TP, "TP: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(TP_HL)) / _Point), POINTDIGITS) + " Points | " + Get_Price_s(TP_HL));
                update_Text(REC_SL, "SL: " + DoubleToString(((Get_Price_d(SL_HL) - Get_Price_d(PR_HL)) / _Point), POINTDIGITS) + " Points | " + Get_Price_s(SL_HL));
            }
            else
                update_Text(REC_BS, "Buy Stop @ " + Get_Price_s(PR_HL));

            ChartRedraw(0);
              ObjectSetInteger(0, tp_button.getName(),OBJPROP_STATE,false);       ChartRedraw(); 
        }

        if (movingState_R5)
        {   ChartSetInteger(0,CHART_AUTOSCROLL,false); // disable autoscroll 
            ChartSetInteger(0, CHART_MOUSE_SCROLL, false);
            sl_button.setydistance(mlbDownYD_R5 + MouseD_Y - mlbDownY5);

            tp_button.setydistance(mlbDownYD_R1 - MouseD_Y + mlbDownY5);

            tp_button.update_Text("TP: " + DoubleToString(((Get_Price_d(TP_HL) - Get_Price_d(PR_HL)) / _Point), POINTDIGITS) + " Points | " + Get_Price_s(TP_HL));
            // update_Text(REC_TP, "TP: " + DoubleToString(((Get_Price_d(TP_HL) - Get_Price_d(PR_HL)) / _Point), POINTDIGITS) + " Points | " + Get_Price_s(TP_HL));
            update_Text(REC_SL, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), POINTDIGITS) + " Points | " + Get_Price_s(SL_HL));

            if ((Get_Price_s(SL_HL)) > (Get_Price_s(TP_HL)))
            {
                update_Text(REC_BS, "Sell Stop @ " + Get_Price_s(PR_HL));
                update_Text(REC_TP, "TP: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(TP_HL)) / _Point), POINTDIGITS) + " Points | " + Get_Price_s(TP_HL));
                update_Text(REC_SL, "SL: " + DoubleToString(((Get_Price_d(SL_HL) - Get_Price_d(PR_HL)) / _Point), POINTDIGITS) + " Points | " + Get_Price_s(SL_HL));
            }
            else
                update_Text(REC_BS, "Buy Stop @ " + Get_Price_s(PR_HL));

            ChartRedraw(0);
        }

        if (movingState_R3)
        {   ChartSetInteger(0,CHART_AUTOSCROLL,false); // disable autoscroll 
            ChartSetInteger(0, CHART_MOUSE_SCROLL, false);
            bs_button.setydistance(mlbDownYD_R3 + MouseD_Y - mlbDownY3);
            tp_button.setydistance(mlbDownYD_R1 + MouseD_Y - mlbDownY1);
            sl_button.setydistance(mlbDownYD_R5 + MouseD_Y - mlbDownY5);
            ObjectSetInteger(0, BTN2, OBJPROP_YDISTANCE, mlbDownYD_Button2 + MouseD_Y - mlbDownYButton2);
            ObjectSetInteger(0, BTN3, OBJPROP_YDISTANCE, mlbDownYD_Button3 + MouseD_Y - mlbDownYButton3);

            update_Text(REC_TP, "TP: " + DoubleToString(((Get_Price_d(TP_HL) - Get_Price_d(PR_HL)) / _Point), POINTDIGITS) + " Points | " + Get_Price_s(TP_HL)); // nicht geprüft

            if ((Get_Price_s(SL_HL)) > (Get_Price_s(TP_HL)))
            {
                update_Text(REC_BS, "Sell Stop @ " + Get_Price_s(PR_HL));
            }
            else

                update_Text(REC_BS, "Buy Stop @ " + Get_Price_s(PR_HL));

//saaralf: Warum hier? gehört das nicht in die IF anweisung? Könnte der Grund für die negativen Zahlen sein... 
//TODO: ausprobieren
            update_Text(REC_SL, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL)) / _Point), POINTDIGITS) + " Points | " + Get_Price_s(SL_HL)); // nicht geprüft

            ChartRedraw(0);
        }

        /*            if (movingState_Button1)
                    {
                       ChartSetInteger(0,CHART_MOUSE_SCROLL,false);

                       ObjectSetInteger(0,BTN1,OBJPROP_XDISTANCE,mlbDownXD_Button1 + MouseD_X -mlbDownXButton1);
                       ObjectSetInteger(0,BTN1,OBJPROP_YDISTANCE,mlbDownYD_Button1 + MouseD_Y -mlbDownYButton1);

                       ChartRedraw(0);
                    }

                    if (movingState_Button2)
                    {
                       ChartSetInteger(0,CHART_MOUSE_SCROLL,false);

                       ObjectSetInteger(0,BTN2,OBJPROP_XDISTANCE,mlbDownXD_Button2 + MouseD_X -mlbDownXButton2);
                       ObjectSetInteger(0,BTN2,OBJPROP_YDISTANCE,mlbDownYD_Button2 + MouseD_Y -mlbDownYButton2);

                       ChartRedraw(0);
                    }

                    if (movingState_Button3)
                    {
                       ChartSetInteger(0,CHART_MOUSE_SCROLL,false);

                       ObjectSetInteger(0,BTN3,OBJPROP_XDISTANCE,mlbDownXD_Button3 + MouseD_X -mlbDownXButton3);
                       ObjectSetInteger(0,BTN3,OBJPROP_YDISTANCE,mlbDownYD_Button3 + MouseD_Y -mlbDownYButton3);

                       ChartRedraw(0);
                    }
        */
        if (MouseState == 0)
        {
            movingState_Rec_tp_1 = false;
            movingState_R3 = false;
            movingState_R5 = false;
            movingState_Button1 = false;
            movingState_Button2 = false;
            movingState_Button3 = false;

            ChartSetInteger(0, CHART_MOUSE_SCROLL, true);
               ChartSetInteger(0,CHART_AUTOSCROLL,false); 
                     ChartRedraw(); 
        }
        prevMouseState = MouseState;
    }

    if (ObjectGetInteger(0, "Button1", OBJPROP_STATE) != 0)
    {
        ObjectSetInteger(0, "Button1", OBJPROP_STATE, 0);
        Print("Eigenschaften öffnen");
        return;

        // Öffnen/Schließen der Eingabemaske
        Print("Eigenschaften öffnen");
    }

    // Klick Button Send only
    if (ObjectGetInteger(0, "Button2", OBJPROP_STATE) != 0)
    {
        ObjectSetInteger(0, "Button2", OBJPROP_STATE, 0);
                       ObjectSetInteger(0,"Button2", OBJPROP_BGCOLOR,clrDarkOrange);// Farbe vorübergehend ändern - zur Verdeutlichung, dass der Klick angekommen ist
        Print("senden an Discord");
       
   //  SendWebhook();
        //sendeToDiscord("Example message", "Example", "This is an example message");
        //               Discord-Befehl string params=("{"content":"" + msgName + "","tts":false,"embeds":[{"title":"" + msgTitle + "","description":"" + message + ""}]}");

        return;
    }

    // Klick Button Trade & Send
    if (ObjectGetInteger(0, "Button3", OBJPROP_STATE) != 0)
    {
        ObjectSetInteger(0, "Button3", OBJPROP_STATE, 0);
        //             Discord-Befehl          string params=("{"content":"" + msgName + "","tts":false,"embeds":[{"title":"" + msgTitle + "","description":"" + message + ""}]}");
        //              return;

        Entry_Price = StringToDouble(Get_Price_s(PR_HL));
        TP_Price = StringToDouble(Get_Price_s(TP_HL));
        SL_Price = StringToDouble(Get_Price_s(SL_HL));
        Entry_Price = NormalizeDouble(Entry_Price, _Digits);
        TP_Price = NormalizeDouble(TP_Price, _Digits);
        SL_Price = NormalizeDouble(SL_Price, _Digits);

        double SL_Points = (Entry_Price - SL_Price) / _Point;
        SL_Points = NormalizeDouble(SL_Points, _Digits);

        // Buy Stop

        if (PositionsTotal() == 0 && OrdersTotal() == 0)
        {
            double lots = calcLots(Entry_Price - SL_Price);
            trade.BuyStop(lots, Entry_Price, _Symbol, SL_Price, TP_Price, ORDER_TIME_GTC);
            //                   Discord-Befehl          string params=("{"content":"" + msgName + "","tts":false,"embeds":[{"title":"" + msgTitle + "","description":"" + message + ""}]}");
            return;
        }

        else
        {
            Print(__FUNCTION__, "Order vorhanden");
            Print("Order vorhanden");
            return;
        }

        // Sell Stop
        if (PositionsTotal() == 0 && OrdersTotal() == 0)

        //                  if (ORDER_TYPE_SELL_STOP < 1)

        {
            double lots = calcLots(SL_Price - Entry_Price);
            trade.SellStop(lots, Entry_Price, _Symbol, SL_Price, TP_Price, ORDER_TIME_GTC);
            Print("Sell Order öffnen");
            return;
        }
        else
        {
            Print(__FUNCTION__, "Order vorhanden");

            Print("Order vorhanden");
            return;
        }
    }
}

void deleteObjects()
{
    ObjectDelete(0, REC_TP);
    ObjectDelete(0, REC_BS);
    ObjectDelete(0, REC_SL);
    ObjectDelete(0, TP_HL);
    ObjectDelete(0, SL_HL);
    ObjectDelete(0, PR_HL);
    ObjectDelete(0, "Button1");
    ObjectDelete(0, "Button2");
    ObjectDelete(0, "Button3");

    ChartRedraw(0);
}

