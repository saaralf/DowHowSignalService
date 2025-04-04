//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Michael Keller, Steffen Kachold"
#property link      ""

input group "====== Message Button and Label ======"
input color ButtonCancelOrder_bgcolor = clrLightGray; // Button Cancel Order  Color
input color ButtonCancelOrder_font_color = clrBlack;  // Button Cancel Order  Font Color
input color ButtonCancelOrderOthers_bgcolor = clrLightPink; // Button Cancel Order Others Color
input color ButtonCancelOthers_font_color = clrBlack;  // Button Cancel Order Others Font Color
input uint ButtonCancelOrder_font_size = 8;  // Button Cancel Order  Font Size
input color InfoLabelFontSize_bgcolor = clrRed; // Info Label  Color
input color InfoLabelFontSize_font_color = clrWhite;  // Info Label  Font Color
input uint InfoLabelFontSize = 8;   // Info Label  Font Size

#define InfoBuyTargetReached "InfoBuyTargetReached";

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MessageButton()
  {

   ObjectCreate(0, "ButtonCancelOrder", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_XDISTANCE, 100);               // X position
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_XSIZE, 150);                   // width
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_YDISTANCE, 90+30+10);                // Y position
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_YSIZE, 30);                    // height
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_CORNER, 0);                    // chart corner
   ObjectSetString(0, "ButtonCancelOrder", OBJPROP_TEXT, "Cancel Buy Order"); // label
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_BGCOLOR, ButtonCancelOrder_bgcolor);
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_COLOR, ButtonCancelOrder_font_color);
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_FONTSIZE, ButtonCancelOrder_font_size);

   ObjectCreate(0, "ButtonCancelOrderSell", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_XDISTANCE, 100+150+30);               // X position
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_XSIZE, 150);                   // width
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_YDISTANCE,  90+30+10);                // Y position
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_YSIZE, 30);                    // height
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_CORNER, 0);                    // chart corner
   ObjectSetString(0, "ButtonCancelOrderSell", OBJPROP_TEXT, "Cancel Sell Order"); // label
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_BGCOLOR, ButtonCancelOrder_bgcolor);
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_COLOR, ButtonCancelOrder_font_color);
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_FONTSIZE, ButtonCancelOrder_font_size);
   
   ObjectCreate(0, "ButtonCancelOrderLongOthers", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "ButtonCancelOrderLongOthers", OBJPROP_XDISTANCE, 100);               // X position
   ObjectSetInteger(0, "ButtonCancelOrderLongOthers", OBJPROP_XSIZE, 150);                   // width
   ObjectSetInteger(0, "ButtonCancelOrderLongOthers", OBJPROP_YDISTANCE,  130+30+10+30+10);                // Y position
   ObjectSetInteger(0, "ButtonCancelOrderLongOthers", OBJPROP_YSIZE, 30);                    // height
   ObjectSetInteger(0, "ButtonCancelOrderLongOthers", OBJPROP_CORNER, 0);                    // chart corner
   ObjectSetString(0, "ButtonCancelOrderLongOthers", OBJPROP_TEXT, "Cancel Buy Order"); // label
   ObjectSetInteger(0, "ButtonCancelOrderLongOthers", OBJPROP_BGCOLOR, ButtonCancelOrderOthers_bgcolor);
   ObjectSetInteger(0, "ButtonCancelOrderLongOthers", OBJPROP_COLOR, ButtonCancelOrder_font_color);
   ObjectSetInteger(0, "ButtonCancelOrderLongOthers", OBJPROP_FONTSIZE, ButtonCancelOrder_font_size);
   
   ObjectCreate(0, "ButtonCancelOrderSellOthers", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "ButtonCancelOrderSellOthers", OBJPROP_XDISTANCE, 100+150+30);               // X position
   ObjectSetInteger(0, "ButtonCancelOrderSellOthers", OBJPROP_XSIZE, 150);                   // width
   ObjectSetInteger(0, "ButtonCancelOrderSellOthers", OBJPROP_YDISTANCE,  130+30+10+30+10);                // Y position
   ObjectSetInteger(0, "ButtonCancelOrderSellOthers", OBJPROP_YSIZE, 30);                    // height
   ObjectSetInteger(0, "ButtonCancelOrderSellOthers", OBJPROP_CORNER, 0);                    // chart corner
   ObjectSetString(0, "ButtonCancelOrderSellOthers", OBJPROP_TEXT, "Cancel Sell Order"); // label
   ObjectSetInteger(0, "ButtonCancelOrderSellOthers", OBJPROP_BGCOLOR, ButtonCancelOrderOthers_bgcolor);
   ObjectSetInteger(0, "ButtonCancelOrderSellOthers", OBJPROP_COLOR, ButtonCancelOrder_font_color);
   ObjectSetInteger(0, "ButtonCancelOrderSellOthers", OBJPROP_FONTSIZE, ButtonCancelOrder_font_size);

   
  }
/*
   ObjectCreate(0, "ButtonTargetReached", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_XDISTANCE, 100);               // X position
   ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_XSIZE, 150);                   // width
   ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_YDISTANCE, 130);                // Y position
   ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_YSIZE, 30);                    // height
   ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_CORNER, 0);                    // chart corner
   ObjectSetString(0, "ButtonTargetReached", OBJPROP_TEXT, "Buy Target Reached"); // label
   ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_BGCOLOR, ButtonTargetReached_bgcolor);
   ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_COLOR, ButtonTargetReached_font_color);
   ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_FONTSIZE, ButtonTargetReached_font_size);
   ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "ButtonTargetReached", OBJPROP_SELECTED, true);


   ObjectCreate(0, "ButtonStoppedout", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_XDISTANCE, 100);               // X position
   ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_XSIZE, 150);                   // width
   ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_YDISTANCE, 130+30+10);                // Y position
   ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_YSIZE, 30);                    // height
   ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_CORNER, 0);                    // chart corner
   ObjectSetString(0, "ButtonStoppedout", OBJPROP_TEXT, "Buy Stopped Out"); // label
   ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_BGCOLOR, ButtonStoppedout_bgcolor);
   ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_COLOR, ButtonStoppedout_font_color);
   ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_FONTSIZE, ButtonStoppedout_font_size);
   ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "ButtonStoppedout", OBJPROP_SELECTED, false);

   ObjectCreate(0, "ButtonTargetReachedSell", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "ButtonTargetReachedSell", OBJPROP_XDISTANCE, 100+150+30);               // X position
   ObjectSetInteger(0, "ButtonTargetReachedSell", OBJPROP_XSIZE, 150);                   // width
   ObjectSetInteger(0, "ButtonTargetReachedSell", OBJPROP_YDISTANCE, 130);                // Y position
   ObjectSetInteger(0, "ButtonTargetReachedSell", OBJPROP_YSIZE, 30);                    // height
   ObjectSetInteger(0, "ButtonTargetReachedSell", OBJPROP_CORNER, 0);                    // chart corner
   ObjectSetString(0, "ButtonTargetReachedSell", OBJPROP_TEXT, "Sell Target Reached"); // label
   ObjectSetInteger(0, "ButtonTargetReachedSell", OBJPROP_BGCOLOR, ButtonTargetReached_bgcolor);
   ObjectSetInteger(0, "ButtonTargetReachedSell", OBJPROP_COLOR, ButtonTargetReached_font_color);
   ObjectSetInteger(0, "ButtonTargetReachedSell", OBJPROP_FONTSIZE, ButtonTargetReached_font_size);
   ObjectSetInteger(0, "ButtonTargetReachedSell", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "ButtonTargetReachedSell", OBJPROP_SELECTED, false);

   ObjectCreate(0, "ButtonStoppedoutSell", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "ButtonStoppedoutSell", OBJPROP_XDISTANCE, 100+150+30);               // X position
   ObjectSetInteger(0, "ButtonStoppedoutSell", OBJPROP_XSIZE, 150);                   // width
   ObjectSetInteger(0, "ButtonStoppedoutSell", OBJPROP_YDISTANCE, 130+30+10);                // Y position
   ObjectSetInteger(0, "ButtonStoppedoutSell", OBJPROP_YSIZE, 30);                    // height
   ObjectSetInteger(0, "ButtonStoppedoutSell", OBJPROP_CORNER, 0);                    // chart corner
   ObjectSetString(0, "ButtonStoppedoutSell", OBJPROP_TEXT, "Sell Stopped Out"); // label
   ObjectSetInteger(0, "ButtonStoppedoutSell", OBJPROP_BGCOLOR, ButtonStoppedout_bgcolor);
   ObjectSetInteger(0, "ButtonStoppedoutSell", OBJPROP_COLOR, ButtonStoppedout_font_color);
   ObjectSetInteger(0, "ButtonStoppedoutSell", OBJPROP_FONTSIZE, ButtonStoppedout_font_size);
   ObjectSetInteger(0, "ButtonStoppedoutSell", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "ButtonStoppedoutSell", OBJPROP_SELECTED, false);
*/
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InfoLabelLong()
  {
//Info BuyTargetReached
   ObjectCreate(0,"ActiveLongTrade", OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0,"ActiveLongTrade",OBJPROP_XDISTANCE,100);
   ObjectSetInteger(0,"ActiveLongTrade",OBJPROP_YDISTANCE,90);
//--- Objektgröße setzen
   ObjectSetInteger(0,"ActiveLongTrade",OBJPROP_XSIZE,150);
   ObjectSetInteger(0,"ActiveLongTrade",OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,"ActiveLongTrade",OBJPROP_TEXT,"");
   ObjectSetInteger(0,"ActiveLongTrade", OBJPROP_BGCOLOR, clrNONE);
   ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_COLOR, clrNONE);
   ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_FONTSIZE, InfoLabelFontSize);
   ObjectSetString(0, "ActiveLongTrade", OBJPROP_FONT, "Arial");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InfoLabelShort()
  {
//Info Button ActiveShortTrade
   ObjectCreate(0, "ActiveShortTrade", OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0,"ActiveShortTrade",OBJPROP_XDISTANCE,100+150+30);
   ObjectSetInteger(0,"ActiveShortTrade",OBJPROP_YDISTANCE,90);
//--- Objektgröße setzen
   ObjectSetInteger(0,"ActiveShortTrade",OBJPROP_XSIZE,150);
   ObjectSetInteger(0,"ActiveShortTrade",OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,"ActiveShortTrade",OBJPROP_TEXT,"");
//--- Schriftgröße setzen
   ObjectSetInteger(0,"ActiveShortTrade", OBJPROP_BGCOLOR, clrNONE);
   ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_COLOR, clrNONE);
   ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_FONTSIZE, InfoLabelFontSize);
   ObjectSetString(0, "ActiveShortTrade", OBJPROP_FONT, "Arial");

  }

/*
//Info ButtonStoppedout
   ObjectCreate(0, "InfoButtonStoppedout", OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0,"InfoButtonStoppedout",OBJPROP_XDISTANCE,100);
   ObjectSetInteger(0,"InfoButtonStoppedout",OBJPROP_YDISTANCE,100+30+30+10+30);
//--- Objektgröße setzen
   ObjectSetInteger(0,"InfoButtonStoppedout",OBJPROP_XSIZE,150);
   ObjectSetInteger(0,"InfoButtonStoppedout",OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,"InfoButtonStoppedout",OBJPROP_TEXT," ");
//--- Schriftgröße setzen
   ObjectSetInteger(0,"InfoButtonStoppedout", OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, "InfoButtonStoppedout", OBJPROP_COLOR, clrBlack);

//Info ButtonCancelOrder
   ObjectCreate(0, "InfoButtonCancelOrder", OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0,"InfoButtonCancelOrder",OBJPROP_XDISTANCE,100);
   ObjectSetInteger(0,"InfoButtonCancelOrder",OBJPROP_YDISTANCE,100+30+30+10+30+30+10+30);
//--- Objektgröße setzen
   ObjectSetInteger(0,"InfoButtonCancelOrder",OBJPROP_XSIZE,150);
   ObjectSetInteger(0,"InfoButtonCancelOrder",OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,"InfoButtonCancelOrder",OBJPROP_TEXT," ");
//--- Schriftgröße setzen
   ObjectSetInteger(0,"InfoButtonCancelOrder", OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, "InfoButtonCancelOrder", OBJPROP_COLOR, clrBlack);


//Info ButtonStoppedoutSell
ObjectCreate(0, "InfoButtonStoppedoutSell", OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
ObjectSetInteger(0,"InfoButtonStoppedoutSell",OBJPROP_XDISTANCE,100+150+30);
ObjectSetInteger(0,"InfoButtonStoppedoutSell",OBJPROP_YDISTANCE,100+30+30+10+30);
//--- Objektgröße setzen
ObjectSetInteger(0,"InfoButtonStoppedoutSell",OBJPROP_XSIZE,150);
ObjectSetInteger(0,"InfoButtonStoppedoutSell",OBJPROP_YSIZE,30);
//--- den Text setzen
ObjectSetString(0,"InfoButtonStoppedoutSell",OBJPROP_TEXT," ");
//--- Schriftgröße setzen
ObjectSetInteger(0,"InfoButtonStoppedoutSell", OBJPROP_BGCOLOR, clrWhite);
ObjectSetInteger(0, "InfoButtonStoppedoutSell", OBJPROP_COLOR, clrBlack);

//Info ButtonCancelOrderSell
ObjectCreate(0, "InfoButtonCancelOrderSell", OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
ObjectSetInteger(0,"InfoButtonCancelOrderSell",OBJPROP_XDISTANCE,100+150+30);
ObjectSetInteger(0,"InfoButtonCancelOrderSell",OBJPROP_YDISTANCE,100+30+30+10+30+30+10+30);
//--- Objektgröße setzen
ObjectSetInteger(0,"InfoButtonCancelOrderSell",OBJPROP_XSIZE,150);
ObjectSetInteger(0,"InfoButtonCancelOrderSell",OBJPROP_YSIZE,30);
//--- den Text setzen
ObjectSetString(0,"InfoButtonCancelOrderSell",OBJPROP_TEXT," ");
//--- Schriftgröße setzen
ObjectSetInteger(0,"InfoButtonCancelOrderSell", OBJPROP_BGCOLOR, clrWhite);
ObjectSetInteger(0, "InfoButtonCancelOrderSell", OBJPROP_COLOR, clrBlack);

}
*/


//+------------------------------------------------------------------+
