#property copyright "DowHowSignalService V3"
#property link      ""
#property version   "3.000"
#property strict

#include "logger.mqh"
#include "CWebhookRouter.mqh"
#include "WebhookConfig.mqh"
#include "CDiscordClient.mqh"
#include "TA3_Types.mqh"
#include "TA3_Repository.mqh"
#include "TA3_Application.mqh"
#include "TA3_UI.mqh"

input group "===== V3 Allgemein ====="
input string InpBotNameV3 = "DowHow Trading Signalservice V3";
input double InpRiskPercentV3 = 1.0; // Prozent vom Equity
input string InpDatabaseFileV3 = "DowHowSignalServiceV3.sqlite";

input group "===== Discord ====="
input string InpWebhookConfigFileV3 = "DowHowSignalService_webhooks.cfg";
input bool   InpRequireKnownSymbolV3 = true;
input bool   InpRequireDiscordV3 = true;

TA3_Context      g_ta3_ctx;
CTA3Repository   g_ta3_repo;
CWebhookRouter   g_ta3_router;
CWebhookConfig   g_ta3_webhook_cfg;
CDiscordClient   g_ta3_discord;
CTA3Application  g_ta3_app;
CTA3UI           g_ta3_ui;

int OnInit()
  {
   g_ta3_ctx.chart_id=ChartID();
   g_ta3_ctx.symbol=_Symbol;
   g_ta3_ctx.tf=(ENUM_TIMEFRAMES)_Period;
   g_ta3_ctx.digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);

   CLogger::SetLogFileName("DowHowSignalServiceV3.log");
   CLogger::SetLogLevel(LOG_LEVEL_DEBUG);
   CLogger::SetMethod(LOGGING_METHOD_FILE);
   CLogger::Add(LOG_LEVEL_INFO,"TradeAssistant V3 OnInit");

   if(!g_ta3_webhook_cfg.Load(InpWebhookConfigFileV3))
     {
      CLogger::Add(LOG_LEVEL_ERROR,"V3 webhook config konnte nicht geladen werden");
      return INIT_FAILED;
     }

   g_ta3_router.Init(InpRequireKnownSymbolV3,g_ta3_webhook_cfg.SystemWebhook());
   for(int i=0;i<g_ta3_webhook_cfg.RouteCount();i++)
     {
      g_ta3_router.Add(g_ta3_webhook_cfg.RouteKey(i),
                       g_ta3_webhook_cfg.RouteWebhook(i),
                       g_ta3_webhook_cfg.RouteAliases(i));
     }

   if(!g_ta3_router.Validate())
      return INIT_FAILED;

   if(!g_ta3_discord.Init(&g_ta3_router,
                          InpBotNameV3,
                          g_ta3_webhook_cfg.TestWebhook(),
                          g_ta3_webhook_cfg.SystemWebhook(),
                          InpRequireDiscordV3))
      return INIT_FAILED;

   if(!g_ta3_repo.Open(InpDatabaseFileV3))
      return INIT_FAILED;

   if(!g_ta3_app.Init(&g_ta3_repo,&g_ta3_discord,g_ta3_ctx))
      return INIT_FAILED;

   g_ta3_app.SetRiskPercent(InpRiskPercentV3/100.0);

   if(!g_ta3_ui.Init(&g_ta3_app,g_ta3_ctx))
      return INIT_FAILED;

   g_ta3_ui.Create();

   ChartSetInteger(g_ta3_ctx.chart_id,CHART_EVENT_OBJECT_CREATE,true);
   ChartSetInteger(g_ta3_ctx.chart_id,CHART_EVENT_OBJECT_DELETE,true);
   ChartRedraw(g_ta3_ctx.chart_id);

   CLogger::Add(LOG_LEVEL_INFO,"TradeAssistant V3 bereit");
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   g_ta3_ui.Destroy();
   g_ta3_repo.Close();
   CLogger::Add(LOG_LEVEL_INFO,"TradeAssistant V3 OnDeinit reason="+IntegerToString(reason));
  }

void OnTick()
  {
   g_ta3_ui.OnTick();
  }

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   g_ta3_ui.OnChartEvent(id,lparam,dparam,sparam);
  }
