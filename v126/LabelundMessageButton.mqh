//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Michael Keller, Steffen Kachold"
#property link      ""

//Hintergrundfarbe auslesen
color chart_bg = (color)ChartGetInteger(0, CHART_COLOR_BACKGROUND);


input group "====== Message Button and Label ======"
input color ButtonCancelOrder_bgcolor = clrLightGray; // Button Cancel Order  Color
input color ButtonCancelOrder_font_color = clrBlack;  // Button Cancel Order  Font Color
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
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "ButtonCancelOrder", OBJPROP_SELECTED, false);

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
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "ButtonCancelOrderSell", OBJPROP_SELECTED, false);
  }

//+------------------------------------------------------------------+
//| Label zur Anzeige, dass eine Order oder ein Trade aktiv ist                                                                  |
//+------------------------------------------------------------------+
void InfoLabel()
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
//--- Schriftgröße setzen
   ObjectSetInteger(0,"ActiveLongTrade", OBJPROP_BGCOLOR, clrNONE);
   ObjectSetInteger(0,"ActiveLongTrade", OBJPROP_BORDER_COLOR, chart_bg);
   ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_COLOR, clrNONE);
   ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_FONTSIZE, InfoLabelFontSize);
   ObjectSetString(0, "ActiveLongTrade", OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_READONLY, true);
   ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_SELECTED, false);
   ObjectSetInteger(0, "ActiveLongTrade", OBJPROP_BACK, true);

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
   ObjectSetInteger(0,"ActiveShortTrade", OBJPROP_BORDER_COLOR, chart_bg);
   ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_COLOR, clrNONE);
   ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_FONTSIZE, InfoLabelFontSize);
   ObjectSetString(0, "ActiveShortTrade", OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_READONLY, true);
   ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_SELECTED, false);
   ObjectSetInteger(0, "ActiveShortTrade", OBJPROP_BACK, true);
  }

//+------------------------------------------------------------------+
