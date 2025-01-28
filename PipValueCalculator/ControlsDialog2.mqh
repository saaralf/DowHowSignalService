//+------------------------------------------------------------------+
//|                                              ControlsDialog2.mqh |
//|                                                   Michael Keller |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Saaralf (c) Michael Keller"
#property link      ""
#property version   "V2.00.00"

#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Edit.mqh>
#include <Controls\Label.mqh>
#include <Controls\DatePicker.mqh>
#include <Controls\ListView.mqh>
#include <Controls\ComboBox.mqh>
#include <Controls\SpinEdit.mqh>
#include <Controls\RadioGroup.mqh>
#include <Controls\CheckGroup.mqh>
#include <Layouts\Box.mqh>
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
//--- for buttons
#define BUTTON_WIDTH                        (100)     // size by X coordinate
#define BUTTON_HEIGHT                       (20)      // size by Y coordinate
//--- for the indication area
#define EDIT_HEIGHT                         (20)      // size by Y coordinate
//--- for group controls
#define GROUP_WIDTH                         (150)     // size by X coordinate
#define LIST_HEIGHT                         (179)     // size by Y coordinate
#define RADIO_HEIGHT                        (56)      // size by Y coordinate
#define CHECK_HEIGHT                        (93)      // size by Y coordinate
//+------------------------------------------------------------------+
//| Class CControlsDialog                                            |
//| Usage: main dialog of the Controls application                   |
//+------------------------------------------------------------------+
class CControlsDialog : public CAppDialog
  {
private:
   CBox              m_main;
   CBox              m_edit_row;
   CEdit             m_edit;                          // the display field object
   CBox              m_button_row;
   CButton           m_button1;                       // the button object
   CButton           m_button2;                       // the button object
   CButton           m_button3;

   //Edit saaralf
   CLabel            m_BuyLabel;
   CLabel            m_BuyLabelTrendnummer;
   CButton           m_buttonBuyTP;
   CButton           m_buttonBuySL;
   CButton           m_buttonBuyCL;
   CLabel            m_BuyLabelEntry;
   CLabel            m_BuyLabelSL;
   CLabel            m_BuyLabelTP;
   CLabel            m_BuyLabelSabioEntry;
   CLabel            m_BuyLabelSabioSL;
   CLabel            m_BuyLabelSabioTP;
   CCheckBox         m_BuySendToDiscord;
   CCheckBox         m_Buyisrunning;

   CLabel            m_SellLabel;
   CLabel            m_SellLabelTrendnummer;
   CButton           m_buttonSellTP;
   CButton           m_buttonSellSL;
   CButton           m_buttonSellCL;
   CLabel            m_SellLabelEntry;
   CLabel            m_SellLabelSL;
   CLabel            m_SellLabelTP;
   CLabel            m_SellLabelSabioEntry;
   CLabel            m_SellLabelSabioSL;
   CLabel            m_SellLabelSabioTP;
   CCheckBox         m_SellSendToDiscord;
   CCheckBox         m_Sellisrunning;
   CLabel            m_dummyLabel;

   //


   CSpinEdit         m_spin_edit;                     // the up-down object
   CDatePicker       m_date;                          // the datepicker object
   CBox              m_lists_row;
   CBox              m_lists_column1_CBox;
   CComboBox         m_combo_box;                     // the dropdown list object
   CRadioGroup       m_radio_group;                   // the radio buttons group object
   CCheckGroup       m_check_group;                   // the check box group object
   CBox              m_lists_column2_CBox;
   CBox              m_lists_column1a_CBox;
   CBox              m_lists_column2a_CBox;
   CListView         m_list_view;                     // the list object

public:
                     CControlsDialog(void);
                    ~CControlsDialog(void);
   //--- create
   virtual bool      Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2);
   //--- chart event handler
   virtual bool      OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);

protected:
   //--- create dependent controls
   bool              CreateEdit(void);

   bool              CreateBuyLabel(void);
   bool              CreateBuyTPButton(void);
   bool              CreateBuySLButton(void);
   bool              CreateBuyCLButton(void);
   bool              CreateSellLabel(void);
   bool              CreateSellTPButton(void);
   bool              CreateSellSLButton(void);
   bool              CreateSellCLButton(void);


   bool              CreateBuyLabelTrendnummer(void);
   bool              CreateBuyLabelEntry(void);
   bool              CreateBuyLabelSL(void);
   bool              CreateBuyLabelTP(void);
   bool              CreateBuyCheckBoxisSended(void);
   bool              CreateBuyCheckBoxisRunning(void);
   bool              CreateBuyLabelSabioEntry(void);
   bool              CreateBuyLabelSabioTP(void);
   bool              CreateBuyLabelSabioSL(void);


   bool              CreateSellLabelSabioEntry(void);
   bool              CreateSellLabelSabioTP(void);
   bool              CreateSellLabelSabioSL(void);

bool CreateSellCheckBoxisRunning(void);
bool CreateSellCheckBoxisSended(void);

   bool              CreateDummyLabel(void);
   bool              CreateSellLabelTrendnummer(void);
   bool              CreateSellLabelEntry(void);
   bool              CreateSellLabelSL(void);
   bool              CreateSellLabelTP(void);


   bool              CreateButton1(void);
   bool              CreateButton2(void);
   bool              CreateButton3(void);


   bool              CreateListView(void);
   bool              CreateComboBox(void);
   bool              CreateRadioGroup(void);
   bool              CreateCheckGroup(void);
   //--- handlers of the dependent controls events
   void              OnClickButton1(void);
   void              OnClickButton2(void);
   void              OnClickButton3(void);
   void              OnChangeSpinEdit(void);
   void              OnChangeDate(void);
   void              OnChangeListView(void);
   void              OnChangeComboBox(void);
   void              OnChangeRadioGroup(void);
   void              OnChangeCheckGroup(void);
   //--- containers
   virtual bool      CreateMain(const long chart,const string name,const int subwin);
   virtual bool      CreateEditRow(const long chart,const string name,const int subwin);
   virtual bool      CreateButtonRow(const long chart,const string name,const int subwin);

   virtual bool      CreateListsRow(const long chart,const string name,const int subwin);
   virtual bool      CreateListsColumn1CBox(const long chart,const string name,const int subwin);
   virtual bool      CreateListsColumn2CBox(const long chart,const string name,const int subwin);
   virtual bool      CreateListsColumn1aCBox(const long chart,const string name,const int subwin);
   virtual bool      CreateListsColumn2aCBox(const long chart,const string name,const int subwin);
  };
//+------------------------------------------------------------------+
//| Event Handling                                                   |
//+------------------------------------------------------------------+
EVENT_MAP_BEGIN(CControlsDialog)
ON_EVENT(ON_CLICK,m_button1,OnClickButton1)
ON_EVENT(ON_CLICK,m_button2,OnClickButton2)
ON_EVENT(ON_CLICK,m_button3,OnClickButton3)
ON_EVENT(ON_CHANGE,m_spin_edit,OnChangeSpinEdit)
ON_EVENT(ON_CHANGE,m_date,OnChangeDate)
ON_EVENT(ON_CHANGE,m_list_view,OnChangeListView)
ON_EVENT(ON_CHANGE,m_combo_box,OnChangeComboBox)
ON_EVENT(ON_CHANGE,m_radio_group,OnChangeRadioGroup)
ON_EVENT(ON_CHANGE,m_check_group,OnChangeCheckGroup)
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
//| Create                                                           |
//+------------------------------------------------------------------+
bool CControlsDialog::Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2)
  {
   if(!CAppDialog::Create(chart,name,subwin,x1,y1,x2,y2))
      return(false);
   if(!CreateMain(chart,name,subwin))
      return(false);
   m_main.VerticalAlign(VERTICAL_ALIGN_TOP);
   if(!CreateEditRow(chart,name,subwin))
      return(false);
   if(!CreateButtonRow(chart,name,subwin))
      return(false);

   if(!CreateListsRow(chart,name,subwin))
      return(false);
   if(!m_main.Add(m_edit_row))
      return(false);
   if(!m_main.Add(m_button_row))
      return(false);

   if(!m_main.Add(m_lists_row))
      return(false);
   if(!m_main.Pack())
      return(false);
   if(!Add(m_main))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateMain(const long chart,const string name,const int subwin)
  {
   if(!m_main.Create(chart,name+"main",subwin,0,0,CDialog::ClientAreaWidth(),CDialog::ClientAreaHeight()))
      return(false);
   m_main.LayoutStyle(LAYOUT_STYLE_VERTICAL);
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateEditRow(const long chart,const string name,const int subwin)
  {
   if(!m_edit_row.Create(chart,name+"editrow",subwin,0,0,CDialog::ClientAreaWidth(),EDIT_HEIGHT*1.5))
      return(false);
   if(!CreateEdit())
      return(false);
   m_edit_row.PaddingLeft(8);
   m_edit_row.PaddingRight(8);
   m_edit_row.Add(m_edit);
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateButtonRow(const long chart,const string name,const int subwin)
  {
   if(!m_button_row.Create(chart,name+"buttonrow",subwin,0,0,CDialog::ClientAreaWidth(),BUTTON_HEIGHT*1.5))
      return(false);
   if(!CreateButton1())
      return(false);
   if(!CreateButton2())
      return(false);
   if(!CreateButton3())
      return(false);
   m_button_row.Add(m_button1);
   m_button_row.Add(m_button2);
   m_button_row.Add(m_button3);
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateListsRow(const long chart,const string name,const int subwin)
  {
   if(!m_lists_row.Create(chart,name+"listsrow",subwin,0,0,CDialog::ClientAreaWidth(),LIST_HEIGHT))
      return(false);
   m_lists_row.PaddingLeft(0);
   m_lists_row.PaddingRight(0);
   if(!CreateListsColumn1CBox(chart,name,subwin))
      return(false);
   if(!CreateListsColumn1aCBox(chart,name,subwin))
      return(false);
   if(!CreateListsColumn2CBox(chart,name,subwin))
      return(false);
   if(!CreateListsColumn2aCBox(chart,name,subwin))
      return(false);
   m_lists_row.Add(m_lists_column1_CBox);
   m_lists_row.Add(m_lists_column1a_CBox);
   m_lists_row.Add(m_lists_column2_CBox);
   m_lists_row.Add(m_lists_column2a_CBox);
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateListsColumn1CBox(const long chart,const string name,const int subwin)
  {
   if(!m_lists_column1_CBox.Create(chart,name+"listscolumn1",subwin,0,0,GROUP_WIDTH,LIST_HEIGHT))
      return(false);
   m_lists_column1_CBox.Padding(0);
   m_lists_column1_CBox.LayoutStyle(LAYOUT_STYLE_VERTICAL);
   m_lists_column1_CBox.VerticalAlign(VERTICAL_ALIGN_CENTER_NOSIDES);

   if(!CreateBuyLabel())
      return (false);
   if(!CreateBuyLabelTrendnummer())
      return (false);

   if(!CreateBuyTPButton())
      return (false);
   if(!CreateBuySLButton())
      return (false);
   if(!CreateBuyCLButton())
      return (false);
   if(!CreateBuyLabelEntry())
      return (false);
   if(!CreateBuyLabelSL())
      return (false);
   if(!CreateBuyLabelTP())
      return (false);
   if(!CreateBuyCheckBoxisSended())
      return (false);
   if(!CreateBuyCheckBoxisRunning())
      return (false);
   if(!CreateBuyLabelSabioEntry())
      return (false);
   if(!CreateBuyLabelSabioTP())
      return (false);
   if(!CreateBuyLabelSabioSL())
      return (false);


   m_lists_column1_CBox.Add(m_BuyLabel);
   m_lists_column1_CBox.Add(m_BuyLabelTrendnummer);
   m_lists_column1_CBox.Add(m_buttonBuyTP);
   m_lists_column1_CBox.Add(m_buttonBuySL);
   m_lists_column1_CBox.Add(m_buttonBuyCL);
   m_lists_column1_CBox.Add(m_BuyLabelEntry);
   m_lists_column1_CBox.Add(m_BuyLabelSL);
   m_lists_column1_CBox.Add(m_BuyLabelTP);
   m_lists_column1_CBox.Add(m_BuySendToDiscord);
   m_lists_column1_CBox.Add(m_Buyisrunning);


   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateListsColumn1aCBox(const long chart,const string name,const int subwin)
  {
   if(!m_lists_column1a_CBox.Create(chart,name+"listscolumn1a",subwin,0,0,GROUP_WIDTH,LIST_HEIGHT))
      return(false);
   m_lists_column1a_CBox.Padding(0);
   m_lists_column1a_CBox.LayoutStyle(LAYOUT_STYLE_VERTICAL);
   m_lists_column1a_CBox.VerticalAlign(VERTICAL_ALIGN_CENTER_NOSIDES);

   if(!CreateDummyLabel())
      return (false);
   if(!CreateDummyLabel())
      return (false);

   if(!CreateDummyLabel())
      return (false);
   if(!CreateDummyLabel())
      return (false);
   if(!CreateDummyLabel())
      return (false);
   if(!CreateBuyLabelSabioEntry())
      return (false);
   if(!CreateBuyLabelSabioSL())
      return (false);
   if(!CreateBuyLabelSabioTP())
      return (false);
   if(!CreateDummyLabel())
      return (false);
   if(!CreateDummyLabel())
      return (false);

   m_lists_column1a_CBox.Add(m_dummyLabel);
   m_lists_column1a_CBox.Add(m_dummyLabel);
   m_lists_column1a_CBox.Add(m_dummyLabel);
   m_lists_column1a_CBox.Add(m_dummyLabel);
   m_lists_column1a_CBox.Add(m_dummyLabel);
   m_lists_column1a_CBox.Add(m_BuyLabelSabioEntry);
   m_lists_column1a_CBox.Add(m_BuyLabelSabioSL);
   m_lists_column1a_CBox.Add(m_BuyLabelSabioTP);
   m_lists_column1a_CBox.Add(m_dummyLabel);
   m_lists_column1a_CBox.Add(m_dummyLabel);


   return(true);
  }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateListsColumn2aCBox(const long chart,const string name,const int subwin)
  {
   if(!m_lists_column2a_CBox.Create(chart,name+"listscolumn2a",subwin,0,0,GROUP_WIDTH,LIST_HEIGHT))
      return(false);
   m_lists_column2a_CBox.Padding(0);
   m_lists_column2a_CBox.LayoutStyle(LAYOUT_STYLE_VERTICAL);
   m_lists_column2a_CBox.VerticalAlign(VERTICAL_ALIGN_CENTER_NOSIDES);

   if(!CreateDummyLabel())
      return (false);
   if(!CreateDummyLabel())
      return (false);

   if(!CreateDummyLabel())
      return (false);
   if(!CreateDummyLabel())
      return (false);
   if(!CreateDummyLabel())
      return (false);
   if(!CreateSellLabelSabioEntry())
      return (false);
   if(!CreateSellLabelSabioSL())
      return (false);
   if(!CreateSellLabelSabioTP())
      return (false);
   if(!CreateDummyLabel())
      return (false);
   if(!CreateDummyLabel())
      return (false);

   m_lists_column2a_CBox.Add(m_dummyLabel);
   m_lists_column2a_CBox.Add(m_dummyLabel);
   m_lists_column2a_CBox.Add(m_dummyLabel);
   m_lists_column2a_CBox.Add(m_dummyLabel);
   m_lists_column2a_CBox.Add(m_dummyLabel);
   m_lists_column2a_CBox.Add(m_SellLabelSabioEntry);
   m_lists_column2a_CBox.Add(m_SellLabelSabioSL);
   m_lists_column2a_CBox.Add(m_SellLabelSabioTP);
   m_lists_column2a_CBox.Add(m_dummyLabel);
   m_lists_column2a_CBox.Add(m_dummyLabel);


   return(true);
  }

//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSellLabelSabioEntry(void)
  {
//--- create
   if(!m_SellLabelSabioEntry.Create(m_chart_id,m_name+"LABELSELLSABIOENTRY",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_SellLabelSabioEntry.Text("Sabio Entry: "))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSellLabelSabioSL(void)
  {
//--- create
   if(!m_SellLabelSabioSL.Create(m_chart_id,m_name+"LABELSELLSABIOSL",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_SellLabelSabioSL.Text("Sabio SL: "))
      return(false);
//--- succeed
   return(true);
  }//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSellLabelSabioTP(void)
  {
//--- create
   if(!m_SellLabelSabioTP.Create(m_chart_id,m_name+"LABELSELLSABIOTP",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_SellLabelSabioTP.Text("Sabio TP:"))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateBuyLabelSabioEntry(void)
  {
//--- create
   if(!m_BuyLabelSabioEntry.Create(m_chart_id,m_name+"LABELBUYSABIOENTRY",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_BuyLabelSabioEntry.Text("Sabio Entry: "))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateBuyLabelSabioSL(void)
  {
//--- create
   if(!m_BuyLabelSabioSL.Create(m_chart_id,m_name+"LABELBUYSABIOSL",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_BuyLabelSabioSL.Text("Sabio SL: )"))
      return(false);
//--- succeed
   return(true);
  }//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateBuyLabelSabioTP(void)
  {
//--- create
   if(!m_BuyLabelSabioTP.Create(m_chart_id,m_name+"LABELBUYSABIOTP",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_BuyLabelSabioTP.Text("Sabio TP:"))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateDummyLabel(void)
  {
//--- create
   if(!m_dummyLabel.Create(m_chart_id,m_name+"LABELDUMMY",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_dummyLabel.Text("---------------"))
      return(false);
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateBuyLabel(void)
  {
//--- create
   if(!m_BuyLabel.Create(m_chart_id,m_name+"LABELBUY",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_BuyLabel.Text("Long Trade"))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateBuyLabelTrendnummer(void)
  {
//--- create
   if(!m_BuyLabelTrendnummer.Create(m_chart_id,m_name+"LABELBUYTRNR",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_BuyLabelTrendnummer.Text("Trendnummer: 0"))
      return(false);
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateBuyTPButton(void)
  {
//--- create
   if(!m_buttonBuyTP.Create(m_chart_id,m_name+"TPBUY",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_buttonBuyTP.Text("TP Erreicht"))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateBuySLButton(void)
  {
//--- create
   if(!m_buttonBuySL.Create(m_chart_id,m_name+"SLBUY",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_buttonBuySL.Text("SL Erreicht"))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateBuyCLButton(void)
  {
//--- create
   if(!m_buttonBuyCL.Create(m_chart_id,m_name+"CLBUY",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_buttonBuyCL.Text("Cancel Trade"))
      return(false);
//--- succeed
   return(true);
  }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateBuyLabelEntry(void)
  {
//--- create
   if(!m_BuyLabelEntry.Create(m_chart_id,m_name+"LABELBUYENTRY",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_BuyLabelEntry.Text("Entry: 0"))
      return(false);
//--- succeed
   return(true);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateBuyLabelSL(void)
  {
//--- create
   if(!m_BuyLabelSL.Create(m_chart_id,m_name+"LABELBUYSL",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_BuyLabelSL.Text("SL: 0"))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateBuyLabelTP(void)
  {
//--- create
   if(!m_BuyLabelTP.Create(m_chart_id,m_name+"LABELBUYTP",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_BuyLabelTP.Text("TP: 0"))
      return(false);
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateBuyCheckBoxisSended(void)
  {
//--- create
   if(!m_BuySendToDiscord.Create(m_chart_id,m_name+"CHECKBOXBUYSENDDISCORD",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_BuySendToDiscord.Text("Gesendet an Discord"))
      return(false);
//--- succeed
   return(true);
  }//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateBuyCheckBoxisRunning(void)
  {
//--- create
   if(!m_Buyisrunning.Create(m_chart_id,m_name+"CHECKBOXBUYISRUNNING",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_Buyisrunning.Text("Trade läuft noch"))
      return(false);
//--- succeed
   return(true);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateListsColumn2CBox(const long chart,const string name,const int subwin)
  {
   if(!m_lists_column2_CBox.Create(chart,name+"listscolumn2",subwin,0,0,GROUP_WIDTH,LIST_HEIGHT))
      return(false);
   m_lists_column2_CBox.Padding(0);
   m_lists_column2_CBox.LayoutStyle(LAYOUT_STYLE_VERTICAL);
   m_lists_column2_CBox.VerticalAlign(VERTICAL_ALIGN_CENTER_NOSIDES);
   if(!CreateSellLabel())
      return (false);
   if(!CreateSellLabelTrendnummer())
      return (false);
   if(!CreateSellTPButton())
      return (false);
   if(!CreateSellSLButton())
      return (false);
   if(!CreateSellCLButton())
      return (false);
   if(!CreateSellLabelEntry())
      return (false);
   if(!CreateSellLabelSL())
      return (false);
   if(!CreateSellLabelTP())
      return (false);

   if(!CreateSellCheckBoxisSended())
      return (false);
   if(!CreateSellCheckBoxisRunning())
      return (false);

   m_lists_column2_CBox.Add(m_SellLabel);
   m_lists_column2_CBox.Add(m_SellLabelTrendnummer);
   m_lists_column2_CBox.Add(m_buttonSellTP);
   m_lists_column2_CBox.Add(m_buttonSellSL);
   m_lists_column2_CBox.Add(m_buttonSellCL);
   m_lists_column2_CBox.Add(m_SellLabelEntry);
   m_lists_column2_CBox.Add(m_SellLabelSL);
   m_lists_column2_CBox.Add(m_SellLabelTP);

   return(true);
  }


//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSellLabel(void)
  {
//--- create
   if(!m_SellLabel.Create(m_chart_id,m_name+"LABELSELL",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_SellLabel.Text("Sell Trade"))
      return(false);
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSellLabelTrendnummer(void)
  {
//--- create
   if(!m_SellLabelTrendnummer.Create(m_chart_id,m_name+"LABELSELLTRNR",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_SellLabelTrendnummer.Text("Trendnummer: 0"))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSellTPButton(void)
  {
//--- create
   if(!m_buttonSellTP.Create(m_chart_id,m_name+"TPSELL",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_buttonSellTP.Text("TP Erreicht"))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSellSLButton(void)
  {
//--- create
   if(!m_buttonSellSL.Create(m_chart_id,m_name+"SLSELL",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_buttonSellSL.Text("SL Erreicht"))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSellCLButton(void)
  {
//--- create
   if(!m_buttonSellCL.Create(m_chart_id,m_name+"CLSELL",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_buttonSellCL.Text("Cancel Trade"))
      return(false);
//--- succeed
   return(true);
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSellLabelEntry(void)
  {
//--- create
   if(!m_SellLabelEntry.Create(m_chart_id,m_name+"LABELSELLENTRY",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_SellLabelEntry.Text("Entry: 0"))
      return(false);
//--- succeed
   return(true);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSellLabelSL(void)
  {
//--- create
   if(!m_SellLabelSL.Create(m_chart_id,m_name+"LABELSELLSL",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_SellLabelSL.Text("SL: 0"))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSellLabelTP(void)
  {
//--- create
   if(!m_SellLabelTP.Create(m_chart_id,m_name+"LABELSELLTP",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_SellLabelTP.Text("TP: 0"))
      return(false);
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSellCheckBoxisSended(void)
  {
//--- create
   if(!m_SellSendToDiscord.Create(m_chart_id,m_name+"CHECKBOXSELLSENDDISCORD",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_SellSendToDiscord.Text("Gesendet an Discord"))
      return(false);
//--- succeed
   return(true);
  }//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSellCheckBoxisRunning(void)
  {
//--- create
   if(!m_Sellisrunning.Create(m_chart_id,m_name+"CHECKBOXSELLISRUNNING",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_Sellisrunning.Text("Trade läuft noch"))
      return(false);
//--- succeed
   return(true);
  }

















//+------------------------------------------------------------------+
//| Create the display field                                         |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateEdit(void)
  {
//--- create
   if(!m_edit.Create(m_chart_id,m_name+"Edit",m_subwin,0,0,CDialog::ClientAreaWidth(),EDIT_HEIGHT))
      return(false);
   if(!m_edit.ReadOnly(true))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateButton1(void)
  {
//--- create
   if(!m_button1.Create(m_chart_id,m_name+"Button1",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_button1.Text("TP Erreicht"))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "Button2" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateButton2(void)
  {
//--- create
   if(!m_button2.Create(m_chart_id,m_name+"Button2",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_button2.Text("Button2"))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "Button3" fixed button                                |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateButton3(void)
  {
//--- create
   if(!m_button3.Create(m_chart_id,m_name+"Button3",m_subwin,0,0,BUTTON_WIDTH,BUTTON_HEIGHT))
      return(false);
   if(!m_button3.Text("Locked"))
      return(false);
   m_button3.Locking(true);
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//| Create the "ListView" element                                    |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateListView(void)
  {
//--- create
   if(!m_list_view.Create(m_chart_id,m_name+"ListView",m_subwin,0,0,GROUP_WIDTH,LIST_HEIGHT))
      return(false);
//--- fill out with strings
   for(int i=0;i<16;i++)
      if(!m_list_view.AddItem("Item "+IntegerToString(i)))
         return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "ComboBox" element                                    |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateComboBox(void)
  {
//--- create
   if(!m_combo_box.Create(m_chart_id,m_name+"ComboBox",m_subwin,0,0,GROUP_WIDTH,EDIT_HEIGHT))
      return(false);
//--- fill out with strings
   for(int i=0;i<16;i++)
      if(!m_combo_box.ItemAdd("Item "+IntegerToString(i)))
         return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "RadioGroup" element                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateRadioGroup(void)
  {
//--- create
   if(!m_radio_group.Create(m_chart_id,m_name+"RadioGroup",m_subwin,0,0,GROUP_WIDTH,RADIO_HEIGHT))
      return(false);
//--- fill out with strings
   for(int i=0;i<3;i++)
      if(!m_radio_group.AddItem("Item "+IntegerToString(i),1<<i))
         return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "CheckGroup" element                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateCheckGroup(void)
  {
//--- create
   if(!m_check_group.Create(m_chart_id,m_name+"CheckGroup",m_subwin,0,0,GROUP_WIDTH,CHECK_HEIGHT))
      return(false);
//--- fill out with strings
   for(int i=0;i<5;i++)
      if(!m_check_group.AddItem("Item "+IntegerToString(i),1<<i))
         return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickButton1(void)
  {
   m_edit.Text(__FUNCTION__);
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickButton2(void)
  {
   m_edit.Text(__FUNCTION__);
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickButton3(void)
  {
   if(m_button3.Pressed())
      m_edit.Text(__FUNCTION__+"On");
   else
      m_edit.Text(__FUNCTION__+"Off");
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::OnChangeSpinEdit()
  {
   m_edit.Text(__FUNCTION__+" : Value="+IntegerToString(m_spin_edit.Value()));
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::OnChangeDate(void)
  {
   m_edit.Text(__FUNCTION__+" \""+TimeToString(m_date.Value(),TIME_DATE)+"\"");
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::OnChangeListView(void)
  {
   m_edit.Text(__FUNCTION__+" \""+m_list_view.Select()+"\"");
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::OnChangeComboBox(void)
  {
   m_edit.Text(__FUNCTION__+" \""+m_combo_box.Select()+"\"");
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::OnChangeRadioGroup(void)
  {
   m_edit.Text(__FUNCTION__+" : Value="+IntegerToString(m_radio_group.Value()));
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::OnChangeCheckGroup(void)
  {
   m_edit.Text(__FUNCTION__+" : Value="+IntegerToString(m_check_group.Value()));
  }
//+------------------------------------------------------------------+
