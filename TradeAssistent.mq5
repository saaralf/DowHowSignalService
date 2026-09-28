#property copyright "Michael Keller, Steffen Kachold"
#property link ""
#property version "2.033"
#include <Trade\Trade.mqh>




#define TA_OVERVIEW_BG "TA_OVERVIEW_BG"
#define TA_OVERVIEW_TXT "TA_OVERVIEW_TXT"


#define SL_Long "SL_Long"
#define SL_Short "SL_Short"
#define LabelSLLong "LabelSLLong"
#define LabelSLShort "LabelSLShort"
#define Entry_Long "Entry_Long"
#define Entry_Short "Entry_Short"
#define LabelEntryLong "LabelEntryLong"
#define LabelEntryShort "LabelEntryShort"
#define ConfirmSabioInserts "ConfirmSabioInserts"
#define InfoBuyTargetReached "InfoBuyTargetReached"
#define LINE_TAG_SUFFIX "_TAG"

input group "===== Design ====="
input int DistancefromRight = 300; // Distance from right screen edge
input string           InpFont="Arial";             // Font
input int              InpFontSize=10;
input group "===== SabioEingabeFelder ====="
input bool Sabioedit = true;                                         // Sabio Prices Edit visible
input bool SabioPrices = true;
input string InpBotName = "DowHow Trading Signalservice";
input group "===== Webhooks ====="
input bool   InpRequireKnownSymbol = true; // wenn true: ohne Mapping kein Send
input string InpWebhook_system     = "";

input string InpWebhook_test     = "";
input string InpAlias_test = "test";
input string InpWebhook_EURUSD = "";
input string InpAlias_EURUSD   = "EURUSD,EURUSD*,*EURUSD*";

input string InpWebhook_GBPUSD = "";
input string InpAlias_GBPUSD   = "GBPUSD,GBPUSD*,*GBPUSD*";

input string InpWebhook_USDJPY = "";
input string InpAlias_USDJPY   = "USDJPY,USDJPY*,*USDJPY*";

input string InpWebhook_USDCHF = "";
input string InpAlias_USDCHF   = "USDCHF,USDCHF*,*USDCHF*";

input string InpWebhook_USDCAD = "";
input string InpAlias_USDCAD   = "USDCAD,USDCAD*,*USDCAD*";

input string InpWebhook_AUDUSD = "";
input string InpAlias_AUDUSD   = "AUDUSD,AUDUSD*,*AUDUSD*";

input string InpWebhook_NZDUSD = "";
input string InpAlias_NZDUSD   = "NZDUSD,NZDUSD*,*NZDUSD*";

input string InpWebhook_XAUUSD = "";
input string InpAlias_XAUUSD   = "XAUUSD,GOLD*,*GOLD*";

input string InpWebhook_WTI    = "";
input string InpAlias_WTI      = "WTI,USOIL*,CL*,OIL*";

input string InpWebhook_NASDAQ = "";
input string InpAlias_NASDAQ   = "NASDAQ,NAS100*,US100*,USTEC*,NQ*";

input string InpWebhook_EURJPY = "";
input string InpAlias_EURJPY   = "EURJPY,EURJPY*,*EURJPY*";

input string InpWebhook_EURNZD = "";
input string InpAlias_EURNZD   = "EURNZD,EURNZD*,*EURNZD*";



#define POSNB "EingabePos"
#include "ui_names.mqh"
input group "===== Debug ====="
input bool InpDebug = true;
input bool InpRequireDiscord = true;
#include "CVirtualTradeGUI.mqh"
#include "logger.mqh"
#include "gui_elemente.mqh"

#include "context.mqh"
#include "ui_base_groups.mqh"

#include "CTradesPanel.mqh"
#include "sonstige_methoden.mqh"
#include "CDiscordClient.mqh"
#include "CDBService.mqh"
#include "ui_state.mqh"
#include "CTradeManager.mqh"
#include "CUIManager.mqh"

#include "ui_registry.mqh"
#include "CWebhookRouter.mqh"
#include "CMyTradesPanelHandler.mqh"
#include "positions_cache.mqh"
#include "ta_controllers.mqh"

#include "trade_pos_line_registry.mqh"

CTradePosLineRegistry g_tradePosLines;   // Definition (genau 1x)

SContext m_ctx;
#include "event.mqh"


input group "===== Lines ====="
input color EntryLine = clrBlue; // Entry Line

input color color_SLLine = clrRed;               // SL Line at SL Button
input color color_EntryLine = clrBlue;
input color TradeEntryLineLong = clrGreen; // Active Trade SL Line Long

input color Tradecolor_SLLineLong = clrRed;      // Active Trade SL Line Long
input color TradeEntryLineShort = clrAqua; // Active Trade Entry Line Short

input color Tradecolor_SLLineShort = clrViolet;                            // Active Trade SL Line Long
input group "===== Defaults =====" input bool SendOnlyButton = true; // Send only (true) or Trade & Send (false)
// Sabio Prices already insert (true) or not (false)
// Button Cancel Order  Font Color
// Info Label  Font Size
input group "===== Button Farben und Fonts====="
input color SLButton_bgcolor = clrRed;                       // SL Button   Color
input color SLButton_font_color = clrWhite;                      // SL Button   Font Color
// SL Button   Font Size
input color PriceButton_bgcolor = clrAqua;                       // Price Button   Color
input color PriceButton_font_color = clrBlack;                   // Price Button   Font Color
// Price Button   Font Size
input color SendOnlyButton_bgcolor = clrForestGreen;             // Button Send only  Color
input color SendOnlyButton_font_color = clrWhite;                // Button Send only  Font Color
// Button Send only  Font Size
input color TSButton_bgcolor = clrGray;                          // Button Trade & Send  Color
input color TSButton_font_color = clrRed;                        // Button Trade & Send  Font Color


CTrade trade;



double Entry_Price;
double SL_Price;
double CurrentAskPrice;
double CurrentBidPrice;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckForExistingLongPosition();

bool is_long_trade = false, is_sell_trade = false;


bool HitEntryPriceLong = false;
bool HitEntryPriceShort = false;
bool is_sell_trade_pending = false;
// bool is_buy_trade_pending = false;



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


int yd2, xs2, ys2,
    xd3, yd3, xs3, ys3,
    xd4, yd4, xs4, ys4,
    xd5, yd5, xs5, ys5;



// ================= ENDE LINE PRICES =================
CVirtualTradeGUI g_vgui;
SUIState g_ui_state;
CDiscordClient g_Discord;
CDBService g_DB;
CUIManager g_ui;
CTradesPanel g_tp;
CWebhookRouter g_router;
CTradeManager g_TradeMgr;
CMyTradesPanelHandler g_panelHandler;
// Globale Instanzen (nur EINMAL definieren, nicht in .mqh ohne include-guard mehrfach!)
//CEntryGroupUI g_entry_ui;
//CSLGroupUI    g_sl_ui;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {

   Ctx_InitFromChart(m_ctx);



   CLogger::SetLogFileName("DowHowSignalService.log");
   CLogger::Add(LOG_LEVEL_INFO, "EA Startet OnInit()");
   CLogger::SetLogLevel(LOG_LEVEL_DEBUG);
   CLogger::SetMethod(LOGGING_METHOD_FILE);

   g_router.Init(InpRequireKnownSymbol, InpWebhook_system);
   g_router.Add("EURUSD", InpWebhook_EURUSD, InpAlias_EURUSD);
   g_router.Add("GBPUSD", InpWebhook_GBPUSD, InpAlias_GBPUSD);
   g_router.Add("USDJPY", InpWebhook_USDJPY, InpAlias_USDJPY);
   g_router.Add("USDCHF", InpWebhook_USDCHF, InpAlias_USDCHF);
   g_router.Add("USDCAD", InpWebhook_USDCAD, InpAlias_USDCAD);
   g_router.Add("AUDUSD", InpWebhook_AUDUSD, InpAlias_AUDUSD);
   g_router.Add("NZDUSD", InpWebhook_NZDUSD, InpAlias_NZDUSD);
   g_router.Add("XAUUSD", InpWebhook_XAUUSD, InpAlias_XAUUSD);
   g_router.Add("WTI",    InpWebhook_WTI,    InpAlias_WTI);
   g_router.Add("NASDAQ", InpWebhook_NASDAQ, InpAlias_NASDAQ);
   g_router.Add("EURNZD", InpWebhook_EURNZD, InpAlias_EURNZD);
   g_router.Add("EURJPY", InpWebhook_EURJPY, InpAlias_EURJPY);
   g_router.Add("test", InpWebhook_test, InpAlias_test);

   if(!g_router.Validate())
      return INIT_FAILED;



// Discord init: testWebhook + optional requireSymbolHook
   if(!g_Discord.Init(&g_router,InpBotName,InpWebhook_test,InpWebhook_system,InpRequireDiscord))
      return INIT_FAILED;

   if(!g_DB.Init())
      return INIT_FAILED;

   if(!g_TradeMgr.Init(&g_DB,&g_Discord,m_ctx))
      return INIT_FAILED;

   g_vgui.Init(&g_TradeMgr,  m_ctx);
   g_ui.Init(&g_DB, &g_TradeMgr);
   g_vgui.CreateDefaults();
   Print("TRNB readonly=", (int)ObjectGetInteger(0, TRNB, OBJPROP_READONLY),
         " selectable=", (int)ObjectGetInteger(0, TRNB, OBJPROP_SELECTABLE),
         " hidden=", (int)ObjectGetInteger(0, TRNB, OBJPROP_HIDDEN));


   g_TradeMgr.RestoreFromDB(m_ctx.symbol, m_ctx.tf);
   g_TradeMgr.TM_PublishTradePosToDB(m_ctx.symbol, m_ctx.tf);


// Jetzt existieren die Edit-Objekte -> also anwenden:
   g_vgui.ApplyTradePosFromDBToEdits();


   g_evt_router.SetContext(m_ctx);
   g_ui_state.is_long=true;
   bool loaded = false;
   g_panelHandler.SetContext(m_ctx);
   g_panelHandler.SetTradeManager(&g_TradeMgr);
// --- Panel: nur neue Klasse benutzen
   g_tp.DeleteByPrefix("TP_");        // hartes Cleanup: entfernt evtl. alte TP_ Objekte vom alten Panel
   g_tp.Create(10, 100, 420, 200,m_ctx);   // neues Panel

   g_tp.SetHandler(&g_panelHandler);

// statt FileExists(...) / LoadStateAndHistoryFromFile() / LoadEAState()

   g_TradeMgr.RestoreTradePosLines(m_ctx.symbol, m_ctx.tf);



   CLogger::Add(LOG_LEVEL_INFO, "OnInit(): Datenbank wurde restored");



   g_tp.RebuildRows();

// NEU: Trade-Linien (Pos1..Pos4) aus positions erzeugen
//   DB_RestoreTradeLines_All();
//   DB_PrintData();


//Standart Richtung beim Entry/SL Buttons ist Long



   ChartSetInteger(0, CHART_FOREGROUND, false);
   ChartRedraw(0);
   return (INIT_SUCCEEDED);
  }

/**
 * Beschreibung: EA-Cleanup. Löscht alle registrierten UI-Objekte und schließt DB.
 * Parameter:    reason - Deinit-Reason (MT5)
 * Rückgabewert: void
 * Hinweise:     UI_Reg_DeleteAll() ist Quelle der Wahrheit für Cleanup.
 * Fehlerfälle:  DB.Close kann fehlschlagen -> DB-Service loggt intern.
 */
void OnDeinit(const int reason)
  {
   int deleted = UI_Reg_DeleteAll();
   CLogger::Add(LOG_LEVEL_INFO, StringFormat("OnDeinit(reason=%d): UI Objekte gelöscht=%d", reason, deleted));
   TradePosLines_Reset();
   g_tp.Destroy();
//g_entry_ui.Destroy();
//g_sl_ui.Destroy();
   g_vgui.Destroy();
   g_DB.Close();
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   CurrentAskPrice = SymbolInfoDouble(m_ctx.symbol,  SYMBOL_ASK);
   CurrentBidPrice = SymbolInfoDouble(m_ctx.symbol,  SYMBOL_BID);

// Nur prüfen, wenn überhaupt etwas aktiv sein kann
   if(g_ui_state.active_trade_no_long > 0 || g_ui_state.active_trade_no_short > 0)
      TPSLReached(m_ctx);
// Base-HL Tags (PR_HL/SL_HL) komplett entfernen


   UI_ProcessRedraw();
   g_tp.ProcessRebuild();
  }


//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
