//+------------------------------------------------------------------+
//|                                               ControlsDialog.mqh |
//|                             Copyright 2000-2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include "VirtualTrade.mqh"
#include "discord.mqh"

#include <ChartObjects\ChartObjectsLines.mqh>
#include <Controls\Button.mqh>
#include <Controls\Dialog.mqh>
#include <Controls\Edit.mqh>
#include <Controls\Label.mqh>
#include <Controls\CheckBox.mqh>

#define REC1                  "REC1"
#define REC3                  "REC3"
#define REC5                  "REC5"
#define BTN1                  "Button1"
#define BTN2                  "Send_Only"
#define BTN3                  "Trade_n_Send"
#define TP_HL                 "TP_HL"
#define SL_HL                 "SL_HL"
#define PR_HL                 "PR_HL"

#define SCHIEBEBUTTONWIDTH    200
#define SCHIEBEBUTTONHEIGHT   20
#define TradeButton_font_size 10

input group "=====Trading Und Send Button=====" input color Trade_n_Send_bgcolor    = clrGreen;   // Button Trade & Send              Color
input color                                                 Trade_n_Send_font_color = clrWhite;   // Button Trade & Send              Font Color
input uint                                                  Trade_n_Send_font_size  = 9;          // Button Trade & Send              Font Size
input bool                                                  Trade_n_Send            = false;      // Traden und an Discord senden oder nur an Discord senden

//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
//--- indents and gaps
#define INDENT_LEFT    (11)   // indent from left (with allowance for border width)
#define INDENT_TOP     (11)   // indent from top (with allowance for border width)
#define INDENT_RIGHT   (11)   // indent from right (with allowance for border width)
#define INDENT_BOTTOM  (11)   // indent from bottom (with allowance for border width)
#define CONTROLS_GAP_X (5)    // gap by X coordinate
#define CONTROLS_GAP_Y (5)    // gap by Y coordinate
//--- for buttons
#define BUTTON_WIDTH  (150)   // size by X coordinate
#define BUTTON_HEIGHT (20)    // size by Y coordinate
//--- for the indication area
#define EDIT_HEIGHT (20)   // size by Y coordinate
//--- for group controls
#define GROUP_WIDTH  (150)   // size by X coordinate
#define LIST_HEIGHT  (179)   // size by Y coordinate
#define RADIO_HEIGHT (56)    // size by Y coordinate
#define CHECK_HEIGHT (93)    // size by Y coordinate

//+------------------------------------------------------------------+
//| Class CControlsDialog                                            |
//| Usage: main dialog of the Controls application                   |
//+------------------------------------------------------------------+
class CControlsDialog : public CAppDialog
  {
private:
   CVirtualTrade     m_virtual_trade_buy;
   CVirtualTrade     m_virtual_trade_sell;
   // Globale Variablen
   int               trade_counter;   // Zähler für Trades
   bool              buy_trade_exists;
   bool              sell_trade_exists;   // Status
   string            m_webhook;
   bool              Trade_n_Send;
   double            m_Entry_Price;
   double            m_TP_Price;
   double            m_SL_Price;
   int               m_xd3;
   int               m_yd3;
   bool              isxyd3;
   bool              isBuy;

   CVirtualTrade     last_buy_trade;
   CVirtualTrade     last_sell_trade;   // Letzter Buy/Sell-Trade

   CLabel            m_buy_trendnummer_label;
   CLabel            m_buy_entry_label;
   CLabel            m_buy_sl_label;
   CLabel            m_buy_tp_label;

   CLabel            m_sell_trendnummer_label;
   CLabel            m_sell_entry_label;
   CLabel            m_sell_sl_label;
   CLabel            m_sell_tp_label;

   CEdit             m_buy_entry_edit;
   CEdit             m_buy_tp_edit;
   CEdit             m_buy_sl_edit;

   CEdit             m_sell_entry_edit;
   CEdit             m_sell_tp_edit;
   CEdit             m_sell_sl_edit;

   CCheckBox         m_buy_trend_send_to_discord_CheckBox;
   CCheckBox         m_buy_tp_send_to_discord_CheckBox;
   CCheckBox         m_buy_sl__send_to_discord_CheckBox;
   CCheckBox         m_buy_cancel_send_to_discord_CheckBox;

   CCheckBox         m_sell_trend_send_to_discord_CheckBox;
   CCheckBox         m_sell_tp_send_to_discord_CheckBox;
   CCheckBox         m_sell_sl__send_to_discord_CheckBox;
   CCheckBox         m_sell_cancel_send_to_discord_CheckBox;

   CButton           m_TP_Buy;       // the button object
   CButton           m_SL_Buy;       // the button object
   CButton           m_Cancel_Buy;   // the fixed button object

   CButton           m_TP_Sell;
   CButton           m_SL_Sell;
   CButton           m_Cancel_Sell;

   // Buttons die dan der Preis HL Linie kleben
   CButton           m_Trade_n_Send_Button;
   CButton           m_Schiebe_ButtonTP;
   CButton           m_Schiebe_ButtonPR;
   CButton           m_Schiebe_ButtonSL;

   CChartObjectHLine m_HLine_TP;
   CChartObjectHLine m_HLine_PR;
   CChartObjectHLine m_HLine_SL;

public:
                     CControlsDialog(void);
                    ~CControlsDialog(void);

   //--- create
   virtual bool      Create(const long chart, const string name, const int subwin, const int x1, const int y1, const int x2, const int y2);
   //--- chart event handler
   virtual bool      OnEvent(const int id, const long &lparam, const double &dparam, const string &sparam);

   void              setPrices(double Entry_Price, double TP_Price, double SL_Price);

   void              CreateVirtualTrade(string type);

   bool              getBuyTradeExists();
   bool              getSellTradeExists();

   void              setTradeNSend(bool tradeNSend);
   void              setIsBuy(bool isbuy);
   bool              getisBuy();
   void              toString(void);

   // Alles für den TP Schiebe Button
   int               getXSchiebeButtonTP();
   int               getYSchiebeButtonTP();
   int               getXSIZESchiebeButtonTP();
   int               getYSIZESchiebeButtonTP();
   void              setNameSchiebeButtonTP(string name);

   int               getXSchiebeButtonPR();
   int               getYSchiebeButtonPR();
   int               getXSIZESchiebeButtonPR();
   int               getYSIZESchiebeButtonPR();
   void              setNameSchiebeButtonPR(string name);

   int               getXSchiebeButtonSL();
   int               getYSchiebeButtonSL();
   int               getXSIZESchiebeButtonSL();
   int               getYSIZESchiebeButtonSL();
   void              setNameSchiebeButtonSL(string name);

   bool              updateTextSchiebeButtonTP(string text);
   bool              updateTextSchiebeButtonPR(string text);
   bool              updateTextSchiebeButtonSL(string text);

   int               getXSchiebeButtonTradeNSend();
   int               getYSchiebeButtonTradeNSend();
   int               getXSIZESchiebeButtonTradeNSendL();
   int               getYSIZESchiebeButtonTradeNSend();
   void              setNameSchiebeButtonTradeNSend(string name);

   bool              SchiebeButtonMoveTP(const int x = 0, const int y = 0);
   bool              SchiebeButtonMovePR(const int x = 0, const int y = 0);
   bool              SchiebeButtonMoveSL(const int x = 0, const int y = 0);
   bool              SchiebeButtonMoveTradeNSend(const int x = 0, const int y = 0);

   double            GetPriceDHLTP();
   double            GetPriceDHLSL();
   double            GetPriceDHLPR();
   string            GetPriceSHLTP();
   string            GetPriceSHLPR();
   string            GetPriceSHLSL();

   bool              updatePriceHLTP(void);

   bool              updatePriceHLPR(void);
   bool              updatePriceHLSL(void);

   // Breite und Höhe des Charts
   int               getChartHeightInPixels(const long chartID = 0, const int subwindow = 0);
   int               getChartWidthInPixels(const long chart_ID = 0);

   bool              createHL(string objName, datetime time1, double price1, color clr);

protected:
   bool              CreateButtonTPBuy(void);
   bool              CreateButtonSLBuy(void);
   bool              CreateButtonCancelBuy(void);

   bool              CreateButtonTPSell(void);
   bool              CreateButtonSLSell(void);
   bool              CreateButtonCancelSell(void);

   bool              createButttonTrade_n_Send(void);

   bool              CreateSchiebeButtonTP(void);
   bool              CreateSchiebeButtonPR(void);
   bool              CreateSchiebeButtonSL(void);

   bool              CreateHLineTP(void);
   bool              CreateHLinePR(void);
   bool              CreateHLineSL(void);

   bool              CreateLabelBuyTrendnummer(void);   // m_buy_trendnummer_label;
   bool              CreateLabelBuyEntry(void);         // m_buy_entry_label;
   bool              CreateLabelBuySlPrice(void);       // m_buy_sl_label;
   bool              CreateLabelBuyTPPrice(void);       // m_buy_tp_label;

   bool              CreateLabelSellTrendnummer(void);   // m_sell_trendnummer_label
   bool              CreateLabelSellEntry(void);         // m_sell_entry_label;
   bool              CreateLabelSellSlPrice(void);       // m_sell_sl_label;
   bool              CreateLabelSellTPPrice(void);       // m_sell_tp_label;

   bool              CreateBuyEntryEdit(void);   // m_buy_entry_edit;
   bool              CreateBuyTPEdit(void);      // m_buy_tp_edit;
   bool              CreateBuySLEdit(void);      // m_buy_sl_edit;

   bool              CreateSellEntryEdit(void);   // m_sell_entry_edit;
   bool              CreateSellTPEdit(void);      // m_sell_tp_edit;
   bool              CreateSellSLEdit(void);      // m_sell_sl_edit;

   bool              CreateBuyTradeSendCheckbox(void);    // m_buy_trade_send_to_discord_CheckBox;
   bool              CreateBuyTPSendCheckbox(void);       // m_buy_tp_send_to_discord_CheckBox;
   bool              CreateBuySLSendCheckbox(void);       // m_buy_sl_send_to_discord_CheckBox;
   bool              CreateBuyCancelSendCheckbox(void);   // m_buy_Cancel_send_to_discord_CheckBox;

   bool              CreateSellTradeSendCheckbox(void);    // m_sell_trade_send_to_discord_CheckBox;
   bool              CreateSellTPSendCheckbox(void);       // m_sell_tp_send_to_discord_CheckBox;
   bool              CreateSellSLSendCheckbox(void);       // m_sell_sl_send_to_discord_CheckBox;
   bool              CreateSellCancelSendCheckbox(void);   // m_sell_Cancel_send_to_discord_CheckBox;

   //--- handlers of the dependent controls events
   void              OnClickButtonTPBuy(void);
   void              OnClickButtonSLBuy(void);
   void              OnClickButtonCancelBuy(void);

   void              OnClickButtonTPSell(void);
   void              OnClickButtonSLSell(void);
   void              OnClickButtonCancelSell(void);

   void              OnClickButtonTradeNSend(void);
  };

#define OBJECTNAMELABELBUYT LabelTrendnummerBuy
#define OBJECTNAMELABELBUYT LabelTrendnummerBuy
#define OBJECTNAMELABELBUYT LabelTrendnummerBuy
#define OBJECTNAMELABELBUYT LabelTrendnummerBuy
#define OBJECTNAMELABELBUYT LabelTrendnummerBuy
#define OBJECTNAMELABELBUYT LabelTrendnummerBuy
#define OBJECTNAMELABELBUYT LabelTrendnummerBuy
#define OBJECTNAMELABELBUYT LabelTrendnummerBuy
#define OBJECTNAMELABELBUYT LabelTrendnummerBuy




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateLabelBuyTrendnummer(void)
  {

//--- coordinates
   int x1 = INDENT_LEFT;   //+2*(BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1 = INDENT_TOP + (BUTTON_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y);
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
//--- create
   if(!m_buy_trendnummer_label.Create(m_chart_id, m_name + "OBJECTNAMELABELBUYTRENDNUMMER", m_subwin, x1, y1, x2, y2))
      return (false);
   if(!m_buy_trendnummer_label.Text("Trendnummer"))
      return (false);
   if(!Add(m_buy_trendnummer_label))
      return (false);

//--- succeed

   return true;
  }   // m_buy_trendnummer_label;
  
bool CControlsDialog::CreateLabelBuyEntry(void)       //--- coordinates
  {
   int x1 = INDENT_LEFT;   //+2*(BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1 = INDENT_TOP + (BUTTON_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y)+ (BUTTON_HEIGHT + CONTROLS_GAP_Y);
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
//--- create
   if(!m_buy_entry_label.Create(m_chart_id, m_name + "OBJECTNAMELABELBUYENTRY", m_subwin, x1, y1, x2, y2))
      return (false);
   if(!m_buy_entry_label.Text("Entry Price"))
      return (false);
   if(!Add(m_buy_entry_label))
      return (false);

//--- succeed
   return true;
  }     // m_buy_entry_label;
  


bool CControlsDialog::CreateLabelBuySlPrice(void)      //--- coordinates
  {
   int x1 = INDENT_LEFT;   //+2*(BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1 = INDENT_TOP + (BUTTON_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y)+ (BUTTON_HEIGHT + CONTROLS_GAP_Y)+ (BUTTON_HEIGHT + CONTROLS_GAP_Y);
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
//--- create
   if(!m_buy_sl_label.Create(m_chart_id, m_name + "OBJECTNAMELABELBUYSLPRICE", m_subwin, x1, y1, x2, y2))
      return (false);
   if(!m_buy_sl_label.Text("SL Price"))
      return (false);
   if(!Add(m_buy_sl_label))
      return (false);

//--- succeed
   return true;
  }   // m_buy_sl_label;
bool CControlsDialog::CreateLabelBuyTPPrice(void)       //--- coordinates
  {
   int x1 = INDENT_LEFT;   //+2*(BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1 = INDENT_TOP + (BUTTON_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y)+ (BUTTON_HEIGHT + CONTROLS_GAP_Y)+ (BUTTON_HEIGHT + CONTROLS_GAP_Y)+ (BUTTON_HEIGHT + CONTROLS_GAP_Y);
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
//--- create
   if(!m_buy_tp_label.Create(m_chart_id, m_name + "OBJECTNAMELABELBUYTPPRICE", m_subwin, x1, y1, x2, y2))
      return (false);
   if(!m_buy_tp_label.Text("TP Price"))
      return (false);
   if(!Add(m_buy_tp_label))
      return (false);

//--- succeed
   return true;
  }   // m_buy_tp_label;


  #define OBJECTNAMELABELBUYTRENDNUMMER LabelTrendnummerBuy
#define OBJECTNAMELABELBUYENTRY LabelBuyEntry  
#define OBJECTNAMELABELBUYSLPRICE LabelBuySLPrice
  #define OBJECTNAMELABELBUYTPPRICE LabelBuyTPPrice
  #define OBJECTNAMELABELSELLTRENDNUMMER LabelTrendnummerBuy
#define OBJECTNAMELABELSELLENTRY LabelBuyEntry  
#define OBJECTNAMELABELSELLSLPRICE LabelBuySLPrice
  #define OBJECTNAMELABELSELLTPPRICE LabelBuyTPPrice
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateLabelSellTrendnummer(void)      //--- coordinates
  {
   int x1 = INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP + (BUTTON_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y);
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
//--- create
   if(!m_sell_trendnummer_label.Create(m_chart_id, m_name + "OBJECTNAMELABELSELLTRENDNUMMER", m_subwin, x1, y1, x2, y2))
      return (false);
   if(!m_sell_trendnummer_label.Text("Trendnummer"))
      return (false);
   if(!Add(m_sell_trendnummer_label))
      return (false);

//--- succeed
   return true;
  }   // m_sell_trendnummer_label
bool CControlsDialog::CreateLabelSellEntry(void)      //--- coordinates
  {
   int x1 =  INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP + (BUTTON_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y)+ (BUTTON_HEIGHT + CONTROLS_GAP_Y);
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
//--- create
   if(!m_sell_entry_label.Create(m_chart_id, m_name + "OBJECTNAMELABELSELLENTRY", m_subwin, x1, y1, x2, y2))
      return (false);
   if(!m_sell_entry_label.Text("Entry Price"))
      return (false);
   if(!Add(m_sell_entry_label))
      return (false);

//--- succeed
   return true;
  }         // m_sell_entry_label;
bool CControlsDialog::CreateLabelSellSlPrice(void)      //--- coordinates
  {
   int x1 =  INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP + (BUTTON_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y)+ (BUTTON_HEIGHT + CONTROLS_GAP_Y)+ (BUTTON_HEIGHT + CONTROLS_GAP_Y);
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
//--- create
   if(!m_sell_sl_label.Create(m_chart_id, m_name + "OBJECTNAMELABELSELLSLPRICE", m_subwin, x1, y1, x2, y2))
      return (false);
   if(!m_sell_sl_label.Text("SL Price"))
      return (false);
   if(!Add(m_sell_sl_label))
      return (false);

//--- succeed
   return true;
  }       // m_sell_sl_label;
bool CControlsDialog::CreateLabelSellTPPrice(void)      //--- coordinates
  {
   int x1 =  INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP + (BUTTON_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y)+ (BUTTON_HEIGHT + CONTROLS_GAP_Y)+ (BUTTON_HEIGHT + CONTROLS_GAP_Y)+ (BUTTON_HEIGHT + CONTROLS_GAP_Y);
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
//--- create
   if(!m_sell_tp_label.Create(m_chart_id, m_name + "OBJECTNAMELABELSELLTPPRICE", m_subwin, x1, y1, x2, y2))
      return (false);
   if(!m_sell_tp_label.Text("TP Price"))
      return (false);
   if(!Add(m_sell_tp_label))
      return (false);

//--- succeed
   return true;
  }       // m_sell_tp_label;


#define OBJECTNAMEEDITBUYENTRYPRICE m_buy_entry_edit
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateBuyEntryEdit(void)
  {
//--- coordinates
 int x1 = INDENT_LEFT+(BUTTON_WIDTH+CONTROLS_GAP_X);   //+2*(BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1 = INDENT_TOP + (BUTTON_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y)+ (BUTTON_HEIGHT + CONTROLS_GAP_Y);
   int x2=ClientAreaWidth()-INDENT_RIGHT;
   int y2=y1+EDIT_HEIGHT;
//--- create
   if(!m_buy_entry_edit.Create(m_chart_id,m_name+"OBJECTNAMEEDITBUYENTRYPRICE",m_subwin,x1,y1,x2,y2))
      return(false);
//--- allow editing the content
   if(!m_buy_entry_edit.ReadOnly(false))
      return(false);
   if(!Add(m_buy_entry_edit))
      return(false);

//--- succeed
   return true;
  }   // m_buy_entry_edit;
bool CControlsDialog::CreateBuyTPEdit(void)
  {
 

//--- succeed
   return true;
  }      // m_buy_tp_edit;
bool CControlsDialog::CreateBuySLEdit(void) { return true; }      // m_buy_sl_edit;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSellEntryEdit(void) { return true; }   // m_sell_entry_edit;
bool CControlsDialog::CreateSellTPEdit(void) { return true; }      // m_sell_tp_edit;
bool CControlsDialog::CreateSellSLEdit(void) { return true; }      // m_sell_sl_edit;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateBuyTradeSendCheckbox(void) { return true; }    // m_buy_trade_send_to_discord_CheckBox;
bool CControlsDialog::CreateBuyTPSendCheckbox(void) { return true; }       // m_buy_tp_send_to_discord_CheckBox;
bool CControlsDialog::CreateBuySLSendCheckbox(void) { return true; }       // m_buy_sl_send_to_discord_CheckBox;
bool CControlsDialog::CreateBuyCancelSendCheckbox(void) { return true; }   // m_buy_Cancel_send_to_discord_CheckBox;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSellTradeSendCheckbox(void) { return true; }    // m_sell_trade_send_to_discord_CheckBox;
bool CControlsDialog::CreateSellTPSendCheckbox(void) { return true; }       // m_sell_tp_send_to_discord_CheckBox;
bool CControlsDialog::CreateSellSLSendCheckbox(void) { return true; }       // m_sell_sl_send_to_discord_CheckBox;
bool CControlsDialog::CreateSellCancelSendCheckbox(void) { return true; }   // m_sell_Cancel_send_to_discord_CheckBox;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateHLineTP(void)
  {

   int xd = getXSchiebeButtonTP();
   int yd = getYSchiebeButtonTP();
   int xs = getXSIZESchiebeButtonTP();
   int ys = getYSIZESchiebeButtonTP();

   double   price;
   datetime dt;
   int      window = 0;
   ChartXYToTimePrice(0, xd, yd, window, dt, price);

   if(!m_HLine_TP.Create(0, TP_HL, 0, price))
     {
      return false;
     }

   m_HLine_TP.Color(clrGreen);
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateHLinePR(void)
  {

   int xd3 = getXSchiebeButtonPR();
   int yd3 = getYSchiebeButtonPR();
   int xs3 = getXSIZESchiebeButtonPR();
   int ys3 = getYSIZESchiebeButtonPR();

   datetime dt = 0;
   double   price;
   int      window = 0;

   ChartXYToTimePrice(0, xd3, yd3, window, dt, price);
   if(!m_HLine_PR.Create(0, PR_HL, 0, price))
     {
      return false;
     }

   m_HLine_PR.Color(clrBlue);
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateHLineSL(void)
  {

   int xd = getXSchiebeButtonSL();
   int yd = getYSchiebeButtonSL();
   int xs = getXSIZESchiebeButtonSL();
   int ys = getYSIZESchiebeButtonSL();

   datetime dt = 0;
   double   price;
   int      window = 0;

   ChartXYToTimePrice(0, xd, yd, window, dt, price);
   if(!m_HLine_PR.Create(0, SL_HL, 0, price))
     {
      return false;
     }

   m_HLine_SL.Color(clrRed);
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::updatePriceHLTP()
  {
   datetime dt = 0;
   double   price;
   int      window = 0;
   /*
       int   xd = (int)ObjectGetInteger(0, "SchiebeButtonTP", OBJPROP_XDISTANCE);
       int   yd = (int)ObjectGetInteger(0, "SchiebeButtonTP", OBJPROP_YDISTANCE);
       int   xs = (int)ObjectGetInteger(0, "SchiebeButtonTP", OBJPROP_XSIZE);
         int   ys = (int)ObjectGetInteger(0, "SchiebeButtonTP", OBJPROP_YSIZE);
   */
   int xd = getXSchiebeButtonTP();
   int yd = getYSchiebeButtonTP();
   int xs = getXSIZESchiebeButtonTP();
   int ys = getYSIZESchiebeButtonTP();

   ChartXYToTimePrice(0, xd, yd, window, dt, price);
   ObjectSetInteger(0, TP_HL, OBJPROP_TIME, dt);
   ObjectSetDouble(0, TP_HL, OBJPROP_PRICE, price);

   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::updatePriceHLPR(void)
  {
   datetime dt = 0;
   double   price;
   int      window = 0;

   int xd = getXSchiebeButtonPR();
   int yd = getYSchiebeButtonPR();
   int xs = getXSIZESchiebeButtonPR();
   int ys = getYSIZESchiebeButtonPR();

   ChartXYToTimePrice(0, xd, yd, window, dt, price);
   ObjectSetInteger(0, PR_HL, OBJPROP_TIME, dt);
   ObjectSetDouble(0, PR_HL, OBJPROP_PRICE, price);
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::updatePriceHLSL(void)
  {
   datetime dt = 0;
   double   price;
   int      window = 0;

   int xd = getXSchiebeButtonSL();
   int yd = getYSchiebeButtonSL();
   int xs = getXSIZESchiebeButtonSL();
   int ys = getYSIZESchiebeButtonSL();

   ChartXYToTimePrice(0, xd, yd, window, dt, price);
   ObjectSetInteger(0, SL_HL, OBJPROP_TIME, dt);
   ObjectSetDouble(0, SL_HL, OBJPROP_PRICE, price);
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CControlsDialog::setIsBuy(bool arg_isbuy)
  {
   isBuy = arg_isbuy;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::getisBuy()
  {
   return isBuy;
  }

//+------------------------------------------------------------------+
//| Event Handling                                                   |
//+------------------------------------------------------------------+
EVENT_MAP_BEGIN(CControlsDialog)
ON_EVENT(ON_CLICK, m_TP_Buy, OnClickButtonTPBuy)
ON_EVENT(ON_CLICK, m_SL_Buy, OnClickButtonSLBuy)
ON_EVENT(ON_CLICK, m_Cancel_Buy, OnClickButtonCancelBuy)
ON_EVENT(ON_CLICK, m_TP_Buy, OnClickButtonTPSell)
ON_EVENT(ON_CLICK, m_SL_Buy, OnClickButtonSLSell)
ON_EVENT(ON_CLICK, m_Cancel_Buy, OnClickButtonCancelSell)

EVENT_MAP_END(CAppDialog)

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CControlsDialog::CControlsDialog(void)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CControlsDialog::~CControlsDialog(void)
  {
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::getBuyTradeExists(void)
  {
   return buy_trade_exists;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::getSellTradeExists(void)
  {
   return sell_trade_exists;
  }
//+------------------------------------------------------------------+
//| Create                                                           |
//+------------------------------------------------------------------+
bool CControlsDialog::Create(const long chart, const string name, const int subwin, const int x1, const int y1, const int x2, const int y2)
  {
   if(!CAppDialog::Create(chart, name, subwin, x1, y1, x2, y2))
      return (false);
//--- create dependent controls
// Buy Objekte
   if(!CreateButtonTPBuy())
      return (false);
   if(!CreateButtonSLBuy())
      return (false);
   if(!CreateButtonCancelBuy())
      return (false);

   if(!CreateLabelBuyTrendnummer())
      return (false);
   if(!CreateLabelBuyEntry())
      return (false);
   if(!CreateLabelBuySlPrice())
      return (false);
   if(!CreateLabelBuyTPPrice())
      return (false);

   if(!CreateBuyEntryEdit())
      return (false);
   if(!CreateBuyTPEdit())
      return (false);
   if(!CreateBuySLEdit())
      return (false);

   if(!CreateBuyTradeSendCheckbox())
      return (false);
   if(!CreateBuyTPSendCheckbox())
      return (false);
   if(!CreateBuySLSendCheckbox())
      return (false);
   if(!CreateBuyCancelSendCheckbox())
      return (false);

// Sell Objekte
   if(!CreateButtonTPSell())
      return (false);
   if(!CreateButtonSLSell())
      return (false);
   if(!CreateButtonCancelSell())
      return (false);

   if(!CreateLabelSellTrendnummer())
      return (false);
   if(!CreateLabelSellEntry())
      return (false);
   if(!CreateLabelSellSlPrice())
      return (false);
   if(!CreateLabelSellTPPrice())
      return (false);

   if(!CreateSellEntryEdit())
      return (false);
   if(!CreateSellTPEdit())
      return (false);
   if(!CreateSellSLEdit())
      return (false);

   if(!CreateSellTradeSendCheckbox())
      return (false);
   if(!CreateSellTPSendCheckbox())
      return (false);
   if(!CreateSellSLSendCheckbox())
      return (false);
   if(!CreateSellCancelSendCheckbox())
      return (false);


// Schiebe Button
   if(!CreateSchiebeButtonTP())
      return (false);

   if(!CreateSchiebeButtonPR())
      return (false);
   if(!CreateSchiebeButtonSL())
      return (false);

   if(!createButttonTrade_n_Send())
      return (false);

// Erzeuge die VirtualTrade für Buy und Short
//   m_virtual_trade_buy.Create();
//   m_virtual_trade_sell.Create();

//--- succeed
   return (true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CControlsDialog::setTradeNSend(bool tradeNSend)
  {

   tradeNSend = tradeNSend;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::createButttonTrade_n_Send()
  {

   Print("erzeuge Button Trade & Send");
   string name;
   if(Trade_n_Send == true)
     {
      name = "T & S";
      Print("T & S");
     }
   else
     {
      name = "Send Only";
      Print("Send Only");
     }
   if(!m_Trade_n_Send_Button.Create(0, "Trade_n_Send", 0, m_Schiebe_ButtonPR.Left() - (SCHIEBEBUTTONWIDTH / 2) - 10, (int)ObjectGetInteger(0, "SchiebeButtonPR", OBJPROP_YDISTANCE), 0, 0))
     {
      Print(__FUNCTION__, ": Failed to create Btn: Error Code: ", GetLastError());
      return (false);
     }
   m_Trade_n_Send_Button.Size(SCHIEBEBUTTONWIDTH / 2, SCHIEBEBUTTONHEIGHT);
   m_Trade_n_Send_Button.ColorBackground(Trade_n_Send_bgcolor);
   m_Trade_n_Send_Button.Color(Trade_n_Send_font_color);     //--- Set text color of the close button
   m_Trade_n_Send_Button.Font("Arial Black");                //--- Set font of the close button to Arial Black
   m_Trade_n_Send_Button.FontSize(Trade_n_Send_font_size);   //--- Set font size of the close button
   m_Trade_n_Send_Button.Text(name);
// m_buttonTargetReached.Hide();

   ChartRedraw(0);
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CControlsDialog::getXSchiebeButtonTradeNSend()
  {
   return m_Trade_n_Send_Button.Left();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CControlsDialog::getYSchiebeButtonTradeNSend()
  {
   return m_Trade_n_Send_Button.Top();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CControlsDialog::getXSIZESchiebeButtonTradeNSendL()
  {
   return m_Trade_n_Send_Button.Width();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CControlsDialog::getYSIZESchiebeButtonTradeNSend()
  {
   return m_Trade_n_Send_Button.Height();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CControlsDialog::setNameSchiebeButtonTradeNSend(string name)
  {
   m_Trade_n_Send_Button.Text(name);
  }

//-------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CControlsDialog::getXSchiebeButtonTP()
  {
   return m_Schiebe_ButtonTP.Left();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CControlsDialog::getYSchiebeButtonTP()
  {
   return m_Schiebe_ButtonTP.Top();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CControlsDialog::getXSIZESchiebeButtonTP()
  {
   return m_Schiebe_ButtonTP.Width();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CControlsDialog::getYSIZESchiebeButtonTP()
  {
   return m_Schiebe_ButtonTP.Height();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CControlsDialog::getXSchiebeButtonPR()
  {
   return m_Schiebe_ButtonPR.Left();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CControlsDialog::getYSchiebeButtonPR()
  {
   return m_Schiebe_ButtonPR.Top();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CControlsDialog::getXSIZESchiebeButtonPR()
  {
   return m_Schiebe_ButtonPR.Width();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CControlsDialog::getYSIZESchiebeButtonPR()
  {
   return m_Schiebe_ButtonPR.Height();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CControlsDialog::getXSchiebeButtonSL()
  {
   return m_Schiebe_ButtonSL.Left();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CControlsDialog::getYSchiebeButtonSL()
  {
   return m_Schiebe_ButtonSL.Top();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CControlsDialog::getXSIZESchiebeButtonSL()
  {
   return m_Schiebe_ButtonSL.Width();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CControlsDialog::getYSIZESchiebeButtonSL()
  {
   return m_Schiebe_ButtonSL.Height();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSchiebeButtonTP()
  {
   Print("erzeuge Schiebe Button TP");
   string name;
//  createButton(m_Schiebe_ButtonTP, "", getChartWidthInPixels()-200-50,  getChartHeightInPixels()/2,0, 0, clrWhite, clrGreen, 9, clrGreen, "Arial Black");

   if(!m_Schiebe_ButtonTP.Create(0, "SchiebeButtonTP", 0, getChartWidthInPixels() - 200 - 50, getChartHeightInPixels() / 2, 0, 0))
     {
      Print(__FUNCTION__, ": Failed to create Btn: Error Code: ", GetLastError());
      return (false);
     }
   m_Schiebe_ButtonTP.Size(SCHIEBEBUTTONWIDTH, SCHIEBEBUTTONHEIGHT);
   m_Schiebe_ButtonTP.ColorBackground(clrGreen);
   m_Schiebe_ButtonTP.Color(clrWhite);       //--- Set text color of the close button
   m_Schiebe_ButtonTP.Font("Arial Black");   //--- Set font of the close button to Arial Black
   m_Schiebe_ButtonTP.FontSize(9);           //--- Set font size of the close button
   m_Schiebe_ButtonTP.Text(name);
   m_Schiebe_ButtonTP.ColorBorder(clrGreen);

   int xd = getXSchiebeButtonTP();
   int yd = getYSchiebeButtonTP();
   int xs = getXSIZESchiebeButtonTP();
   int ys = getYSIZESchiebeButtonTP();

   datetime dt = 0;
   double   price;
   int      window = 0;

   ChartXYToTimePrice(0, xd, yd, window, dt, price);
   CreateHLineTP();
// createHL(TP_HL, dt, price, clrGreen);
   ChartRedraw(0);

   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSchiebeButtonPR()
  {

   Print("erzeuge Schiebe Button PR");
   string name;
//  createButton(m_Schiebe_ButtonTP, "", getChartWidthInPixels()-200-50,  getChartHeightInPixels()/2,0, 0, clrWhite, clrGreen, 9, clrGreen, "Arial Black");

   if(!m_Schiebe_ButtonPR.Create(0, "SchiebeButtonPR", 0, m_Schiebe_ButtonTP.Left(), m_Schiebe_ButtonTP.Top() + 100, 0, 0))
     {
      Print(__FUNCTION__, ": Failed to create Btn: Error Code: ", GetLastError());
      return (false);
     }
   m_Schiebe_ButtonPR.Size(SCHIEBEBUTTONWIDTH, SCHIEBEBUTTONHEIGHT);
   m_Schiebe_ButtonPR.ColorBackground(clrAqua);
   m_Schiebe_ButtonPR.Color(clrBlack);       //--- Set text color of the close button
   m_Schiebe_ButtonPR.Font("Arial Black");   //--- Set font of the close button to Arial Black
   m_Schiebe_ButtonPR.FontSize(9);           //--- Set font size of the close button
   m_Schiebe_ButtonPR.Text(name);
   m_Schiebe_ButtonPR.ColorBorder(clrAqua);

   int xd = getXSchiebeButtonPR();
   int yd = getYSchiebeButtonPR();
   int xs = getXSIZESchiebeButtonPR();
   int ys = getYSIZESchiebeButtonPR();

   datetime dt;
   double   price;
   int      window = 0;

   ChartXYToTimePrice(0, xd, yd, window, dt, price);
   CreateHLinePR();
// createHL(PR_HL, dt, price, clrAqua);

   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSchiebeButtonSL()
  {
   Print("erzeuge Schiebe Button SL");
   string name;

   if(!m_Schiebe_ButtonSL.Create(0, "SchiebeButtonSL", 0, m_Schiebe_ButtonPR.Left(), m_Schiebe_ButtonPR.Top() + 100, 0, 0))
     {
      Print(__FUNCTION__, ": Failed to create Btn: Error Code: ", GetLastError());
      return (false);
     }
   m_Schiebe_ButtonSL.Size(SCHIEBEBUTTONWIDTH, SCHIEBEBUTTONHEIGHT);
   m_Schiebe_ButtonSL.ColorBackground(clrRed);
   m_Schiebe_ButtonSL.Color(clrWhite);       //--- Set text color of the close button
   m_Schiebe_ButtonSL.Font("Arial Black");   //--- Set font of the close button to Arial Black
   m_Schiebe_ButtonSL.FontSize(9);           //--- Set font size of the close button
   m_Schiebe_ButtonSL.Text(name);
   m_Schiebe_ButtonSL.ColorBorder(clrRed);

   int xd = getXSchiebeButtonSL();
   int yd = getYSchiebeButtonSL();
   int xs = getXSIZESchiebeButtonSL();
   int ys = getYSIZESchiebeButtonSL();

   datetime dt;
   double   price;
   int      window = 0;

   ChartXYToTimePrice(0, xd, yd, window, dt, price);
   CreateHLineSL();
// createHL(SL_HL, dt, price, clrRed);

   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::updateTextSchiebeButtonTP(string text)
  {

   setNameSchiebeButtonTP(text);
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::updateTextSchiebeButtonPR(string text)
  {

   setNameSchiebeButtonPR(text);
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::updateTextSchiebeButtonSL(string text)
  {

   setNameSchiebeButtonSL(text);
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CControlsDialog::GetPriceDHLTP()
  {

   return ObjectGetDouble(0, TP_HL, OBJPROP_PRICE);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CControlsDialog::GetPriceDHLSL()
  {

   return ObjectGetDouble(0, SL_HL, OBJPROP_PRICE);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CControlsDialog::GetPriceDHLPR()
  {

   return ObjectGetDouble(0, PR_HL, OBJPROP_PRICE);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CControlsDialog::GetPriceSHLTP()
  {
   return DoubleToString(ObjectGetDouble(0, TP_HL, OBJPROP_PRICE), _Digits);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CControlsDialog::GetPriceSHLPR()
  {
   return DoubleToString(ObjectGetDouble(0, PR_HL, OBJPROP_PRICE), _Digits);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CControlsDialog::GetPriceSHLSL()
  {
   return DoubleToString(ObjectGetDouble(0, SL_HL, OBJPROP_PRICE), _Digits);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::createHL(string objName, datetime time1, double price1, color clr)
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
   ObjectSetInteger(0, objName, OBJPROP_BACK, true);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);

   ChartRedraw(0);
   return (true);
  }

#define REC3 "REC3"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::SchiebeButtonMoveTP(const int x = 0, const int y = 0)
  {

   if(m_Schiebe_ButtonTP.Move(x, y))
     {
      Print("Move SchiebeButtonTP nach X,Y:" + x + "," + +y);
      updatePriceHLTP();
      return (true);
     }
   else

     {
      Print("Fehler beim Move von " + m_Schiebe_ButtonTP.Name());
      return false;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::SchiebeButtonMovePR(const int x = 0, const int y = 0)
  {

   if(m_Schiebe_ButtonPR.Move(x, y))
     {
      Print("Move SchiebeButtonPR nach X,Y:" + x + "," + +y);
      updatePriceHLPR();
      return (true);
     }
   else

     {
      Print("Fehler beim Move von " + m_Schiebe_ButtonPR.Name());
      return false;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::SchiebeButtonMoveSL(const int x = 0, const int y = 0)
  {

   if(m_Schiebe_ButtonSL.Move(x, y))
     {
      Print("Move SchiebeButtonSL nach X,Y:" + x + "," + +y);
      updatePriceHLSL();
      return (true);
     }
   else

     {
      Print("Fehler beim Move von " + m_Schiebe_ButtonSL.Name());
      return false;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::SchiebeButtonMoveTradeNSend(const int x = 0, const int y = 0)
  {

   if(m_Trade_n_Send_Button.Move(x, y))
     {
      Print("Move SchiebeButtonMoveTradeNSend nach X,Y:" + x + "," + +y);
      return (true);
     }
   else

     {
      Print("Fehler beim Move von " + m_Trade_n_Send_Button.Name());
      return false;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CControlsDialog::setNameSchiebeButtonTP(string name)
  {
   m_Schiebe_ButtonTP.Text(name);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CControlsDialog::setNameSchiebeButtonPR(string name)
  {
   m_Schiebe_ButtonPR.Text(name);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CControlsDialog::setNameSchiebeButtonSL(string name)
  {
   m_Schiebe_ButtonSL.Text(name);
  }

//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateButtonTPBuy(void)
  {
//--- coordinates
   int x1 = INDENT_LEFT;
   int y1 = INDENT_TOP;   //+(EDIT_HEIGHT+CONTROLS_GAP_Y);
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
//--- create
   if(!m_TP_Buy.Create(m_chart_id, m_name + "ButtonTPBuy", m_subwin, x1, y1, x2, y2))
      return (false);
   if(!m_TP_Buy.Text("Buy Target reached"))
      return (false);

   if(!Add(m_TP_Buy))
      return (false);

   m_TP_Buy.ColorBackground(clrGreen);
   m_TP_Buy.Color(clrWhite);
   m_TP_Buy.FontSize(9);
//--- succeed
   return (true);
  }
//+------------------------------------------------------------------+
//| Create the "Button2" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateButtonSLBuy(void)
  {
//--- coordinates
   int x1 = INDENT_LEFT;   //+(BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1 = INDENT_TOP + (BUTTON_HEIGHT + CONTROLS_GAP_Y);
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
//--- create
   if(!m_SL_Buy.Create(m_chart_id, m_name + "ButtonSLBuy", m_subwin, x1, y1, x2, y2))
      return (false);
   if(!m_SL_Buy.Text("Buy Stopped Out"))
      return (false);

   if(!Add(m_SL_Buy))
      return (false);
   m_SL_Buy.ColorBackground(clrGreen);
   m_SL_Buy.Color(clrWhite);
   m_SL_Buy.FontSize(9);

//--- succeed
   return (true);
  }
//+------------------------------------------------------------------+
//| Create the "Button3" fixed button                                |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateButtonCancelBuy(void)
  {
//--- coordinates
   int x1 = INDENT_LEFT;   //+2*(BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1 = INDENT_TOP + (BUTTON_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y);
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
//--- create
   if(!m_Cancel_Buy.Create(m_chart_id, m_name + "ButtonCancelBuy", m_subwin, x1, y1, x2, y2))
      return (false);
   if(!m_Cancel_Buy.Text("Buy Trade cancel"))
      return (false);
   if(!Add(m_Cancel_Buy))
      return (false);

   m_Cancel_Buy.ColorBackground(clrGreen);
   m_Cancel_Buy.Color(clrWhite);
   m_Cancel_Buy.FontSize(9);
   m_Cancel_Buy.Locking(true);
//--- succeed
   return (true);
  }

//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateButtonTPSell(void)
  {
//--- coordinates
   int x1 = INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP;   //+(EDIT_HEIGHT+CONTROLS_GAP_Y);
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
//--- create
   if(!m_TP_Sell.Create(m_chart_id, m_name + "ButtonTPSell", m_subwin, x1, y1, x2, y2))
      return (false);
   if(!m_TP_Sell.Text("Sell Target reached"))
      return (false);

   if(!Add(m_TP_Sell))
      return (false);

   m_TP_Sell.ColorBackground(clrRed);
   m_TP_Sell.Color(clrWhite);
   m_TP_Sell.FontSize(10);
//--- succeed
   return (true);
  }
//+------------------------------------------------------------------+
//| Create the "Button2" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateButtonSLSell(void)
  {
//--- coordinates
   int x1 = INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP + (BUTTON_HEIGHT + CONTROLS_GAP_Y);
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
//--- create
   if(!m_SL_Sell.Create(m_chart_id, m_name + "ButtonSLSell", m_subwin, x1, y1, x2, y2))
      return (false);
   if(!m_SL_Sell.Text("Sell Stopped Out"))
      return (false);

   if(!Add(m_SL_Sell))
      return (false);
   m_SL_Sell.ColorBackground(clrRed);
   m_SL_Sell.Color(clrWhite);
   m_SL_Sell.FontSize(10);

//--- succeed
   return (true);
  }
//+------------------------------------------------------------------+
//| Create the "Button3" fixed button                                |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateButtonCancelSell(void)
  {
//--- coordinates
   int x1 = INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP + (BUTTON_HEIGHT + CONTROLS_GAP_Y) + (BUTTON_HEIGHT + CONTROLS_GAP_Y);
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
//--- create
   if(!m_Cancel_Sell.Create(m_chart_id, m_name + "ButtonCancelSell", m_subwin, x1, y1, x2, y2))
      return (false);
   if(!m_Cancel_Sell.Text("Sell Trade cancel"))
      return (false);
   if(!Add(m_Cancel_Sell))
      return (false);

   m_Cancel_Sell.ColorBackground(clrRed);
   m_Cancel_Sell.Color(clrWhite);
   m_Cancel_Sell.FontSize(10);
   m_Cancel_Sell.Locking(true);
//--- succeed
   return (true);
  }

//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickButtonTPBuy(void)
  {
   ;
   if(!m_virtual_trade_buy.CloseVirtualTrade())
     {
      Print("Fehler beim Schließen des Buy Trades");
     }
   else
     {
      buy_trade_exists = false;
     }
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickButtonSLBuy(void)
  {
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickButtonCancelBuy(void)
  {
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickButtonTPSell(void)
  {
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickButtonSLSell(void)
  {
  }

//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickButtonCancelSell(void)
  {
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickButtonTradeNSend(void)
  {
   Print("Button Send_Only gedrückt");
   if(!Trade_n_Send == true)
     {

      if(getisBuy())
        {
         if(!getBuyTradeExists())
           {
            CreateVirtualTrade("buy");
            // Kauf-Trade mit spezifischen Preisen erstellen
            // CreateVirtualTrade("buy");
           }
         else
           {
            Print("Ein Buy-Trade existiert bereits.");
           }
        }

      ChartRedraw(0);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CControlsDialog::toString(void)
  {
   Print("isBuy: " + getisBuy());
   Print("Buy Trade_vorhanden " + buy_trade_exists);
   Print("Sell Trade Vorhanden: " + sell_trade_exists);
   Print("");
   Print("");
   Print("");
   Print("");
   Print("");
   Print("");
   Print("");
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CControlsDialog::setPrices(double Entry_Price, double TP_Price, double SL_Price)
  {

   m_Entry_Price = Entry_Price;
   m_TP_Price    = TP_Price;
   m_SL_Price    = SL_Price;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CControlsDialog::CreateVirtualTrade(string type)
  {

   if(type == "buy")
     {
      m_virtual_trade_buy.Create(0, "buy", _Symbol, Period(), m_Entry_Price, m_SL_Price, m_TP_Price, false, false, false);
      buy_trade_exists = true;
     }

   if(type == "sell")
     {
      m_virtual_trade_sell.Create(0, "buy", _Symbol, Period(), m_Entry_Price, m_SL_Price, m_TP_Price, false, false, false);
      sell_trade_exists = true;
     }
  }

/*


      if(sparam == "ButtonTargetReachedBuy")
        {
         Print("Button ButtonTargetReachedBuy gedrückt");
         if(isBuy)
           {
            if(!CloseVirtualTradeTP("buy"))
              {
               Print("Kein aktiver Buy-Trade vorhanden, der geschlossen werden kann.");
              }
           }
         else
           {
            if(!CloseVirtualTradeTP("sell"))
              {
               Print("Kein aktiver Sell-Trade vorhanden, der geschlossen werden kann.");
              }

           }

        }
      if(sparam == "ButtonStoppedout")
        {

         if(isBuy)
           {
            if(!CloseVirtualTradeSL("buy"))
              {
               Print("Kein aktiver Buy-Trade vorhanden, der geschlossen werden kann.");
              }
           }
         else
           {
            if(!CloseVirtualTradeSL("sell"))
              {
               Print("Kein aktiver Sell-Trade vorhanden, der geschlossen werden kann.");
              }

           }

        }*/
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Die Funktion erhält den Wert der Höhe des Charts in Pixeln       |
//+------------------------------------------------------------------+
int CControlsDialog::getChartHeightInPixels(const long chartID = 0, const int subwindow = 0)
  {
//--- Bereiten wir eine Variable, um den Wert der Eigenschaft zu erhalten
   long result = -1;
//--- Setzen den Wert des Fehlers zurück
   ResetLastError();
//--- Erhalten wir den Wert der Eigenschaft
   if(!ChartGetInteger(chartID, CHART_HEIGHT_IN_PIXELS, 0, result))
     {
      //--- Schreiben die Fehlermeldung in den Log "Experten"
      Print(__FUNCTION__ + ", Error Code = ", GetLastError());
     }
//--- Geben den Wert der Eigenschaft zurück
   return ((int)result);
  }

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Die Funktion erhält den Wert der Breite des Charts in Pixeln     |
//+------------------------------------------------------------------+
int CControlsDialog::getChartWidthInPixels(const long chart_ID = 0)
  {
//--- Bereiten wir eine Variable, um den Wert der Eigenschaft zu erhalten
   long result = -1;
//--- Setzen den Wert des Fehlers zurück
   ResetLastError();
//--- Erhalten wir den Wert der Eigenschaft
   if(!ChartGetInteger(chart_ID, CHART_WIDTH_IN_PIXELS, 0, result))
     {
      //--- Schreiben die Fehlermeldung in den Log "Experten"
      Print(__FUNCTION__ + ", Error Code = ", GetLastError());
     }
//--- Geben den Wert der Eigenschaft zurück
   return ((int)result);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
