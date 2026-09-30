#ifndef __TA3_TYPES_MQH__
#define __TA3_TYPES_MQH__

struct TA3_Context
  {
   long              chart_id;
   string            symbol;
   ENUM_TIMEFRAMES   tf;
   int               digits;
  };

struct TA3_Draft
  {
   string            direction;
   double            entry;
   double            sl;
   string            sabio_entry;
   string            sabio_sl;
   int               requested_trade_no;
   int               requested_pos_no;
   bool              sabio_entry_user;
   bool              sabio_sl_user;
  };

struct TA3_Position
  {
   string            symbol;
   string            tf;
   string            direction;
   int               trade_no;
   int               pos_no;
   double            entry;
   double            sl;
   double            lots;
   string            sabio_entry;
   string            sabio_sl;
   string            status;
   int               was_sent;
   int               is_pending;
   long              created_at;
   long              updated_at;
  };

struct TA3_Result
  {
   bool              ok;
   string            error;
   int               trade_no;
   int               pos_no;
  };

string TA3_TFToString(const ENUM_TIMEFRAMES tf)
  {
   switch(tf)
     {
      case PERIOD_M1: return "M1";
      case PERIOD_M5: return "M5";
      case PERIOD_M15:return "M15";
      case PERIOD_M30:return "M30";
      case PERIOD_H1: return "H1";
      case PERIOD_H4: return "H4";
      case PERIOD_D1: return "D1";
      case PERIOD_W1: return "W1";
      case PERIOD_MN1:return "MN1";
      default: return IntegerToString((int)tf);
     }
  }

string TA3_Upper(string s)
  {
   StringToUpper(s);
   return s;
  }

bool TA3_IsClosed(const string status)
  {
   return (StringFind(status, "CLOSED", 0) == 0);
  }

#endif
