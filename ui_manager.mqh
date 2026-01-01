// ui_manager.mqh
//
// This header defines the CUIManager class used to encapsulate all user
// interface related operations. The goal of this class is to remove
// scattered UI code from the main EA and related modules. It will be
// responsible for creating panels, buttons, and chart objects, as well
// as handling chart events. By grouping these operations into a
// dedicated class we achieve better separation of concerns and make
// the code easier to maintain. When adding new UI elements, you should
// implement them here rather than directly in the EA.



#include <Trade/Trade.mqh>
#include "logger.mqh"
#include "db_service.mqh"
#include "trade_manager.mqh"

// CUIManager encapsulates all user interface operations. It should be
// initialised in the EA's OnInit() with pointers to the database and
// trade manager so it can coordinate user actions with business logic.
class CUIManager
  {
private:
   CDBService    *m_db;         // Pointer to database service
   CTradeManager *m_tradeMgr;   // Pointer to trade manager
   CConfig       *m_config;     // Pointer to configuration

public:
   // Default constructor initialises pointers to nullptr
   CUIManager() : m_db(NULL), m_tradeMgr(NULL), m_config(NULL) {}

   // Initialise the UI manager with references to other modules
   // Returns true on success, false on failure
   bool Init(CDBService *db, CTradeManager *tradeMgr, CConfig *config)
     {
      m_db      = db;
      m_tradeMgr = tradeMgr;
      m_config  = config;
      return(true);
     }

   // Create the main panel and user interface elements. Call this
   // during OnInit() after initialising the other modules.
   void CreateMainPanel()
     {
      // Determine chart size for positioning
      int chartId = ChartID();
      long width  = 0;
      long height = 0;
      ChartGetInteger(chartId, CHART_WIDTH_IN_PIXELS, 0, width);
      ChartGetInteger(chartId, CHART_HEIGHT_IN_PIXELS, 0, height);
      // Create a background rectangle at the top of the chart
      string bgName = "UI_MainPanel";
      if(!ObjectCreate(chartId, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0))
        {
         CLogger::Add(LOG_LEVEL_ERROR, "UIManager: failed to create panel background");
         return;
        }
      // Position panel at top (0..1 relative coordinates) with fixed height
      double topHeight = 60;
      ObjectSetInteger(chartId, bgName, OBJPROP_XSIZE, width);
      ObjectSetInteger(chartId, bgName, OBJPROP_YSIZE, topHeight);
      ObjectSetInteger(chartId, bgName, OBJPROP_COLOR, clrDimGray);
    
      ObjectSetInteger(chartId, bgName, OBJPROP_BACK, true);

      // Create BUY button
      string buyName = "btn_buy";
      if(!ObjectCreate(chartId, buyName, OBJ_BUTTON, 0, 0, 0))
        {
         CLogger::Add(LOG_LEVEL_ERROR, "UIManager: failed to create buy button");
        }
      ObjectSetInteger(chartId, buyName, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(chartId, buyName, OBJPROP_YDISTANCE, 10);
      ObjectSetInteger(chartId, buyName, OBJPROP_XSIZE, 80);
      ObjectSetInteger(chartId, buyName, OBJPROP_YSIZE, 30);
      ObjectSetInteger(chartId, buyName, OBJPROP_COLOR, clrGreen);
      ObjectSetInteger(chartId, buyName, OBJPROP_CORNER, 0);
      ObjectSetString(chartId, buyName, OBJPROP_TEXT, "BUY");
      ObjectSetInteger(chartId, buyName, OBJPROP_SELECTABLE, true);

      // Create SELL button
      string sellName = "btn_sell";
      if(!ObjectCreate(chartId, sellName, OBJ_BUTTON, 0, 0, 0))
        {
         CLogger::Add(LOG_LEVEL_ERROR, "UIManager: failed to create sell button");
        }
      ObjectSetInteger(chartId, sellName, OBJPROP_XDISTANCE, 100);
      ObjectSetInteger(chartId, sellName, OBJPROP_YDISTANCE, 10);
      ObjectSetInteger(chartId, sellName, OBJPROP_XSIZE, 80);
      ObjectSetInteger(chartId, sellName, OBJPROP_YSIZE, 30);
      ObjectSetInteger(chartId, sellName, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(chartId, sellName, OBJPROP_CORNER, 0);
      ObjectSetString(chartId, sellName, OBJPROP_TEXT, "SELL");
      ObjectSetInteger(chartId, sellName, OBJPROP_SELECTABLE, true);

      CLogger::Add(LOG_LEVEL_INFO, "UIManager: main panel created");
     }

   // Handle chart events and dispatch to the appropriate UI element. This
   // method should be called from OnChartEvent() in the main EA. It
   // returns true if the event was consumed by the UI manager and no
   // further processing is required, otherwise false.
   bool HandleChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
     {
      // Handle button clicks
      if(id == CHARTEVENT_OBJECT_CLICK)
        {
         string objName = sparam;
         if(objName == "btn_buy" || objName == "btn_sell")
           {
            string direction = (objName == "btn_buy") ? "BUY" : "SELL";
            // Determine entry and SL. For demonstration we use current price
            double entry = 0.0;
            double sl    = 0.0;
            double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
            if(direction == "BUY")
              {
               entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);
               sl    = entry - 20 * point; // 20 pips SL
              }
            else
              {
               entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
               sl    = entry + 20 * point;
              }
            // Create draft trade
            if(!m_tradeMgr.CreateDraft(direction, entry, sl))
              {
               CLogger::Add(LOG_LEVEL_ERROR, "UIManager: failed to create draft from UI");
              }
            return true;
           }
        }
      // Log other events for debugging
      CLogger::Add(LOG_LEVEL_DEBUG, StringFormat("UIManager: event id=%d name=%s", id, sparam));
      return false;
     }

   // Additional helper methods for creating buttons, labels, and
   // persistent objects on the chart will be added here. Keep each
   // operation encapsulated to maintain readability.
  };