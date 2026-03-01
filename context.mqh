//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#ifndef __CONTEXT_MQH__
#define __CONTEXT_MQH__

struct SContext
  {
   long              chart_id;
   string            symbol;
   ENUM_TIMEFRAMES   tf;

   // bereits genutzt in deinem Code:
   bool              send_only_mode;

   // NEU: Sabio-Editfelder ein/aus
   bool              sabio_edit_visible;
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Ctx_InitFromChart(SContext &ctx)
  {
   ctx.chart_id = ChartID();
   ctx.symbol   = _Symbol;
   ctx.tf       = (ENUM_TIMEFRAMES)_Period;

// Defaults (werden in OnInit überschrieben)
   ctx.send_only_mode       = true;
   ctx.sabio_edit_visible   = true;
  }

#endif
//+------------------------------------------------------------------+
