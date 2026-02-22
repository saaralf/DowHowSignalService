#ifndef __CONTEXT_MQH__
#define __CONTEXT_MQH__

struct SContext
  {
   long            chart_id;
   string          symbol;
   ENUM_TIMEFRAMES tf;
  };

 void Ctx_InitFromChart(SContext &ctx)
  {
   ctx.chart_id = ChartID();
   ctx.symbol   = _Symbol;
   ctx.tf       = (ENUM_TIMEFRAMES)_Period;
  }

#endif // __CONTEXT_MQH__