//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Controls\Label.mqh>
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Edit.mqh>
#include "Dialog.mqh"

//input color Trade_n_Send_bgcolor = clrGreen;                            // Button Trade & Send              Color
//input color Trade_n_Send_font_color = clrWhite;                          // Button Trade & Send              Font Color
//input uint Trade_n_Send_font_size = 10;                                // Button Trade & Send              Font Size
#define TradeButton_font_size 10


#define TradeButton_font_color clrWhite
#define TradeButtonBuy_BG_Color clrGreen
#define TradeButtonSell_BG_Color clrRed

#define TradeButton_X 100
#define TradeButton_Y 100
#define TradeButton_Gap 5
#define Tradebutton_distance 10
#define TradeButtonHeight 20
#define TradeButtonWidth 150
int m_TradeButtonWidth= TradeButtonWidth;
int m_TradeButtonHeight=TradeButtonHeight;

//Neue Varianten

CButton m_buttonTargetReached;
CButton m_buttonTargetReachedBuy;
CButton m_buttonStoppedOutBuy;
CButton m_buttonCancelBuy;
CButton m_buttonTargetReachedSell;
CButton m_buttonStoppedOutSell;
CButton m_buttonCancelSell;

CButton m_button_Trade_n_Send;


CLabel m_labelPriceBuy;
CLabel m_labelSLBuy;
CLabel m_labelTPBuy;

CEdit  m_editPriceBuy;
CEdit  m_editSLBuy;
CEdit  m_editTPBuy;

CLabel m_labelPriceSell;
CLabel m_labelSLSell;
CLabel m_labelTPSell;

CEdit  m_editPriceSell;
CEdit  m_editSLSell;
CEdit  m_editTPSell;






#define PANEL_NAME "Order Panel"
#define PANEL_WIDTH 500
#define PANEL_HIEIGHT 500
#define ROW_HEIGHT 20
#define BUY_BTN_NAME "Buy BTN"
#define SELL_BTN_NAME "Sell BTN"
#define CLOSE_BTN_NAME "Close BTN"
#define EDIT_NAME "Lot Size"

//+------------------------------------------------------------------+



//Alte Varianten
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MessageButton()
  {

  //createButttonTrade_n_Send();
   //createButttonTargetReachedBuy();
   //createButttonStoppedOutBuy();
   /*
   createButttonCancelBuy();
   createButttonTargetReachedSell();
   createButttonStoppedOutSell();
   createButttonCancelSell();
 
   createEditPriceBuy();
   createEditPriceSell();
   createLabelPriceBuy();
   createLabelPriceSell();
   createLabelPriceBuy();
   createEditSLBuy();
   createLabelSLSell();
   createEditSLSell();


   Print("TPBuy"+m_buttonTargetReachedBuy.Top());
   Print("SLBUY"+m_buttonStoppedOutBuy.Top());
   Print("C BUY"+m_buttonCancelBuy.Top());
   Print("Label1Buy"+m_labelPriceBuy.Top());
   Print("EditBuy"+m_editPriceBuy.Top());
   Print("EditBuy Unten"+m_editPriceBuy.Bottom());
   Print("EditBuy2"+m_labelSLBuy.Top());
   Print("EditBuy Unten2"+m_labelSLBuy.Bottom());
   Print("EditBuy2"+m_editSLBuy.Top());
   Print("EditBuy Unten2"+m_editSLBuy.Bottom());
*/




  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SendButton()
  {
   /*
   // Neue Logic für Trade & Send oder SendOnly
   // Es wird nur noch eine Auswahl benötigt:

      if(Trade_n_Send == true)
        {
         // Send_Only == false && Trade_n_Send == true)
           {
            ObjectCreate(0, "Trade_n_Send", OBJ_BUTTON, 0, 0, 0);
            ObjectSetInteger(0, "Trade_n_Send", OBJPROP_XDISTANCE, xd3-100);      // X position
            ObjectSetInteger(0, "Trade_n_Send", OBJPROP_XSIZE, 100);          // width
            ObjectSetInteger(0, "Trade_n_Send", OBJPROP_YDISTANCE, yd3);       // Y position
            ObjectSetInteger(0, "Trade_n_Send", OBJPROP_YSIZE, 30);           // height
            ObjectSetInteger(0, "Trade_n_Send", OBJPROP_CORNER, 0);           // chart corner
            ObjectSetString(0, "Trade_n_Send", OBJPROP_TEXT, "T & S"); // label
            ObjectSetInteger(0, "Trade_n_Send", OBJPROP_BGCOLOR, Trade_n_Send_bgcolor);
            ObjectSetInteger(0, "Trade_n_Send", OBJPROP_COLOR, Trade_n_Send_font_color);
            ObjectSetInteger(0, "Trade_n_Send", OBJPROP_FONTSIZE, Trade_n_Send_font_size);
           }
        }
      else
        {
           {
            //Send Only
            ObjectCreate(0, "Send_Only", OBJ_BUTTON, 0, 0, 0);
            ObjectSetInteger(0, "Send_Only", OBJPROP_XDISTANCE, xd3-100);   // X position
            ObjectSetInteger(0, "Send_Only", OBJPROP_XSIZE, 100);       // width
            ObjectSetInteger(0, "Send_Only", OBJPROP_YDISTANCE, yd3);    // Y position
            ObjectSetInteger(0, "Send_Only", OBJPROP_YSIZE, 30);        // height
            ObjectSetInteger(0, "Send_Only", OBJPROP_CORNER, 0);        // chart corner
            ObjectSetString(0, "Send_Only", OBJPROP_TEXT, "Send only"); // label
            ObjectSetInteger(0, "Send_Only", OBJPROP_COLOR, Send_Only_font_color);
            ObjectSetInteger(0, "Send_Only", OBJPROP_FONTSIZE, Send_Only_font_size);
            ObjectSetInteger(0, "Send_Only", OBJPROP_BGCOLOR, Send_Only_bgcolor);
           }
        }

      /*
         if((Send_Only == true && Trade_n_Send == true) || (Send_Only == false && Trade_n_Send == false))
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

            if(Send_Only == true && Trade_n_Send == false)
              {
               ObjectCreate(0, "Send_Only", OBJ_BUTTON, 0, 0, 0);
               ObjectSetInteger(0, "Send_Only", OBJPROP_XDISTANCE, xd3-100);   // X position
               ObjectSetInteger(0, "Send_Only", OBJPROP_XSIZE, 100);       // width
               ObjectSetInteger(0, "Send_Only", OBJPROP_YDISTANCE, yd3);    // Y position
               ObjectSetInteger(0, "Send_Only", OBJPROP_YSIZE, 30);        // height
               ObjectSetInteger(0, "Send_Only", OBJPROP_CORNER, 0);        // chart corner
               ObjectSetString(0, "Send_Only", OBJPROP_TEXT, "Send only"); // label
               ObjectSetInteger(0, "Send_Only", OBJPROP_COLOR, Send_Only_font_color);
               ObjectSetInteger(0, "Send_Only", OBJPROP_FONTSIZE, Send_Only_font_size);
               ObjectSetInteger(0, "Send_Only", OBJPROP_BGCOLOR, Send_Only_bgcolor);
              }
            else

               if(Send_Only == false && Trade_n_Send == true)
                 {
                  ObjectCreate(0, "Trade_n_Send", OBJ_BUTTON, 0, 0, 0);
                  ObjectSetInteger(0, "Trade_n_Send", OBJPROP_XDISTANCE, xd3-100);      // X position
                  ObjectSetInteger(0, "Trade_n_Send", OBJPROP_XSIZE, 100);          // width
                  ObjectSetInteger(0, "Trade_n_Send", OBJPROP_YDISTANCE, yd3);       // Y position
                  ObjectSetInteger(0, "Trade_n_Send", OBJPROP_YSIZE, 30);           // height
                  ObjectSetInteger(0, "Trade_n_Send", OBJPROP_CORNER, 0);           // chart corner
                  ObjectSetString(0, "Trade_n_Send", OBJPROP_TEXT, "T & S"); // label
                  ObjectSetInteger(0, "Trade_n_Send", OBJPROP_BGCOLOR, Trade_n_Send_bgcolor);
                  ObjectSetInteger(0, "Trade_n_Send", OBJPROP_COLOR, Trade_n_Send_font_color);
                  ObjectSetInteger(0, "Trade_n_Send", OBJPROP_FONTSIZE, Trade_n_Send_font_size);
                 }
                 */

  }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool createButton(string objName, string text, int xD, int yD, int xS, int yS, color clrTxt, color clrBG, int fontsize = 9, color clrBorder = clrNONE, string font = "Calibri")
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



//----------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createButttonTargetReachedBuy()
  {
   m_buttonTargetReachedBuy.Create(0,"ButtonTargetReachedBuy",0,3,40,0,0);
   m_buttonTargetReachedBuy.Width(50);
   m_buttonTargetReachedBuy.Height(ROW_HEIGHT);
   m_buttonTargetReachedBuy.ColorBackground(clrGreen);
   m_buttonTargetReachedBuy.Color(TradeButton_font_color); //--- Set text color of the close button
   m_buttonTargetReachedBuy.Font("Arial Black"); //--- Set font of the close button to Arial Black
   m_buttonTargetReachedBuy.FontSize(TradeButton_font_size); //--- Set font size of the close button
   m_buttonTargetReachedBuy.Text("Buy TP Reached");
  

   ChartRedraw(0);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createButttonStoppedOutBuy()
  {
   m_buttonStoppedOutBuy.Create(0,"ButtonStoppedOutBuy",0,3,40+ROW_HEIGHT+5,0,0);
   m_buttonStoppedOutBuy.Width(50);
   m_buttonStoppedOutBuy.Height(ROW_HEIGHT);
   m_buttonStoppedOutBuy.ColorBackground(TradeButtonBuy_BG_Color);
   m_buttonStoppedOutBuy.Color(TradeButton_font_color); //--- Set text color of the close button
   m_buttonStoppedOutBuy.Font("Arial Black"); //--- Set font of the close button to Arial Black
   m_buttonStoppedOutBuy.FontSize(TradeButton_font_size); //--- Set font size of the close button
   m_buttonStoppedOutBuy.Text("Buy Stopped Out");

   ChartRedraw(0);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createButttonCancelBuy()
  {
   m_buttonCancelBuy.Create(0,"ButtonCancelBuy",0,TradeButton_X,TradeButton_Y+TradeButton_Gap+TradeButtonHeight+TradeButton_Gap+TradeButtonHeight,0,0);
   m_buttonCancelBuy.Size(m_TradeButtonWidth,m_TradeButtonHeight);
   m_buttonCancelBuy.ColorBackground(TradeButtonBuy_BG_Color);
   m_buttonCancelBuy.Color(TradeButton_font_color); //--- Set text color of the close button
   m_buttonCancelBuy.Font("Arial Black"); //--- Set font of the close button to Arial Black
   m_buttonCancelBuy.FontSize(TradeButton_font_size); //--- Set font size of the close button
   m_buttonCancelBuy.Text("Buy Cancel ");
// m_buttonTargetReached.Hide();

   ChartRedraw(0);

  }


//+--------------------------
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createButttonTargetReachedSell()
  {
   m_buttonTargetReachedSell.Create(0,"ButtonTargetReachedSell",0,TradeButton_X+TradeButton_Gap+TradeButtonWidth,TradeButton_Y,0,0);
   m_buttonTargetReachedSell.Size(m_TradeButtonWidth,m_TradeButtonHeight);
   m_buttonTargetReachedSell.ColorBackground(TradeButtonSell_BG_Color);
   m_buttonTargetReachedSell.Color(TradeButton_font_color); //--- Set text color of the close button
   m_buttonTargetReachedSell.Font("Arial Black"); //--- Set font of the close button to Arial Black
   m_buttonTargetReachedSell.FontSize(TradeButton_font_size); //--- Set font size of the close button
   m_buttonTargetReachedSell.Text("Sell TP Reached");
//  m_buttonTargetReached.Hide();

   ChartRedraw(0);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createButttonStoppedOutSell()
  {
   m_buttonStoppedOutSell.Create(0,"ButtonStoppedOutSell",0,TradeButton_X+TradeButton_Gap+TradeButtonWidth,TradeButton_Y+TradeButton_Gap+TradeButtonHeight,0,0);
   m_buttonStoppedOutSell.Size(m_TradeButtonWidth,m_TradeButtonHeight);
   m_buttonStoppedOutSell.ColorBackground(TradeButtonSell_BG_Color);
   m_buttonStoppedOutSell.Color(TradeButton_font_color); //--- Set text color of the close button
   m_buttonStoppedOutSell.Font("Arial Black"); //--- Set font of the close button to Arial Black
   m_buttonStoppedOutSell.FontSize(TradeButton_font_size); //--- Set font size of the close button
   m_buttonStoppedOutSell.Text("Sell Stopped Out");
//  m_buttonTargetReached.Hide();

   ChartRedraw(0);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createButttonCancelSell()
  {
   m_buttonCancelSell.Create(0,"ButtonCancelSell",0,TradeButton_X+TradeButton_Gap+TradeButtonWidth,TradeButton_Y+TradeButton_Gap+TradeButtonHeight+TradeButton_Gap+TradeButtonHeight,0,0);
   m_buttonCancelSell.Size(m_TradeButtonWidth,m_TradeButtonHeight);
   m_buttonCancelSell.ColorBackground(TradeButtonSell_BG_Color);
   m_buttonCancelSell.Color(TradeButton_font_color); //--- Set text color of the close button
   m_buttonCancelSell.Font("Arial Black"); //--- Set font of the close button to Arial Black
   m_buttonCancelSell.FontSize(TradeButton_font_size); //--- Set font size of the close button
   m_buttonCancelSell.Text("Sell Cancel");
// m_buttonTargetReached.Hide();

   ChartRedraw(0);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createButttonTrade_n_Send()
  {
   string name;
   if(Trade_n_Send == true)
     {
      name = "T & S";
     }
   else
     {
      name = "Send Only";
     }
   m_buttonTargetReached.Create(0,"Trade_n_Send",0,xd3-100,yd3,0,0);
   m_buttonTargetReached.Size(100,30);
   m_buttonTargetReached.ColorBackground(Trade_n_Send_bgcolor);
   m_buttonTargetReached.Color(Trade_n_Send_font_color); //--- Set text color of the close button
   m_buttonTargetReached.Font("Arial Black"); //--- Set font of the close button to Arial Black
   m_buttonTargetReached.FontSize(Trade_n_Send_font_size); //--- Set font size of the close button
   m_buttonTargetReached.Text(name);
// m_buttonTargetReached.Hide();

   ChartRedraw(0);

  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createLabelPriceBuy()
  {
   m_labelPriceBuy.Create(0,"LabelPriceBuy",0,TradeButton_X,m_buttonCancelBuy.Top()+TradeButton_Gap+TradeButtonHeight,0,0);
   m_labelPriceBuy.Size(m_TradeButtonWidth,m_TradeButtonHeight);
   m_labelPriceBuy.ColorBackground(TradeButtonSell_BG_Color);
   m_labelPriceBuy.Color(clrWhite); //--- Set text color of the close button
   m_labelPriceBuy.Font("Arial Black"); //--- Set font of the close button to Arial Black
   m_labelPriceBuy.FontSize(TradeButton_font_size); //--- Set font size of the close button
   m_labelPriceBuy.Text("EntryPrice Long");
// m_buttonTargetReached.Hide();

   ChartRedraw(0);

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createLabelPriceSell()
  {
   m_labelPriceSell.Create(0,"LabelPriceSell",0,TradeButton_X+TradeButton_Gap+TradeButtonWidth,m_buttonCancelSell.Top()+TradeButton_Gap+TradeButtonHeight,0,0);
   m_labelPriceSell.Size(m_TradeButtonWidth,m_TradeButtonHeight);
   m_labelPriceSell.ColorBackground(TradeButtonSell_BG_Color);
   m_labelPriceSell.Color(clrWhite); //--- Set text color of the close button
   m_labelPriceSell.Font("Arial Black"); //--- Set font of the close button to Arial Black
   m_labelPriceSell.FontSize(TradeButton_font_size); //--- Set font size of the close button
   m_labelPriceSell.Text("EntryPrice Short");
// m_buttonTargetReached.Hide();

   ChartRedraw(0);

  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createEditPriceBuy()
  {
   m_editPriceBuy.Create(0,"EditPriceBuy",0,TradeButton_X,m_buttonCancelBuy.Top()+TradeButton_Gap+TradeButtonHeight+TradeButton_Gap+TradeButtonHeight,0,0);
   m_editPriceBuy.Size(m_TradeButtonWidth,m_TradeButtonHeight);
   m_editPriceBuy.ColorBackground(clrWhite);
   m_editPriceBuy.Color(clrBlack); //--- Set text color of the close button
   m_editPriceBuy.Font("Arial Black"); //--- Set font of the close button to Arial Black
   m_editPriceBuy.FontSize(TradeButton_font_size); //--- Set font size of the close button
   m_editPriceBuy.Text("");
// m_buttonTargetReached.Hide();

   ChartRedraw(0);

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createEditPriceSell()
  {
   m_editPriceSell.Create(0,"EditPriceSell",0,TradeButton_X+TradeButton_Gap+TradeButtonWidth,m_buttonCancelSell.Top()+TradeButton_Gap+TradeButtonHeight+TradeButton_Gap+TradeButtonHeight,0,0);
   m_editPriceSell.Size(m_TradeButtonWidth,m_TradeButtonHeight);
   m_editPriceSell.ColorBackground(clrWhite);
   m_editPriceSell.Color(clrBlack); //--- Set text color of the close button
   m_editPriceSell.Font("Arial Black"); //--- Set font of the close button to Arial Black
   m_editPriceSell.FontSize(TradeButton_font_size); //--- Set font size of the close button
   m_editPriceSell.Text("");
// m_buttonTargetReached.Hide();

   ChartRedraw(0);

  }





//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createLabelSLBuy()
  {
   m_labelSLSell.Create(0,"LabelSLBuy",0,TradeButton_X+TradeButton_Gap+TradeButtonWidth,m_editPriceBuy.Top()+TradeButton_Gap+TradeButtonHeight,0,0);
   m_labelSLSell.Size(m_TradeButtonWidth,m_TradeButtonHeight);
   m_labelSLSell.ColorBackground(clrWhite);
   m_labelSLSell.Color(clrBlack); //--- Set text color of the close button
   m_labelSLSell.Font("Arial Black"); //--- Set font of the close button to Arial Black
   m_labelSLSell.FontSize(TradeButton_font_size); //--- Set font size of the close button
   m_labelSLSell.Text("StoppLoss Buy");
// m_buttonTargetReached.Hide();

   ChartRedraw(0);

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createEditSLBuy()
  {
   m_editSLSell.Create(0,"EditSLBuy",0,TradeButton_X+TradeButton_Gap+TradeButtonWidth,m_buttonCancelBuy.Top()+TradeButton_Gap+TradeButtonHeight+TradeButton_Gap+TradeButtonHeight,0,0);
   m_editSLSell.Size(m_TradeButtonWidth,m_TradeButtonHeight);
   m_editSLSell.ColorBackground(clrWhite);
   m_editSLSell.Color(clrBlack); //--- Set text color of the close button
   m_editSLSell.Font("Arial Black"); //--- Set font of the close button to Arial Black
   m_editSLSell.FontSize(TradeButton_font_size); //--- Set font size of the close button
   m_editSLSell.Text("");
// m_buttonTargetReached.Hide();

   ChartRedraw(0);

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createLabelSLSell()
  {
   m_labelSLSell.Create(0,"LabelSLSell",0,TradeButton_X+TradeButton_Gap+TradeButtonWidth,m_editPriceSell.Top()+TradeButton_Gap+TradeButtonHeight,0,0);
   m_labelSLSell.Size(m_TradeButtonWidth,m_TradeButtonHeight);
   m_labelSLSell.ColorBackground(clrWhite);
   m_labelSLSell.Color(clrBlack); //--- Set text color of the close button
   m_labelSLSell.Font("Arial Black"); //--- Set font of the close button to Arial Black
   m_labelSLSell.FontSize(TradeButton_font_size); //--- Set font size of the close button
   m_labelSLSell.Text("StoppLoss Sell");
// m_buttonTargetReached.Hide();

   ChartRedraw(0);

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createEditSLSell()
  {
   m_editSLSell.Create(0,"EditSLSell",0,TradeButton_X+TradeButton_Gap+TradeButtonWidth,m_buttonCancelSell.Top()+TradeButton_Gap+TradeButtonHeight+TradeButton_Gap+TradeButtonHeight,0,0);
   m_editSLSell.Size(m_TradeButtonWidth,m_TradeButtonHeight);
   m_editSLSell.ColorBackground(clrWhite);
   m_editSLSell.Color(clrBlack); //--- Set text color of the close button
   m_editSLSell.Font("Arial Black"); //--- Set font of the close button to Arial Black
   m_editSLSell.FontSize(TradeButton_font_size); //--- Set font size of the close button
   m_editSLSell.Text("");
// m_buttonTargetReached.Hide();

   ChartRedraw(0);

  }





