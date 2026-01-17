//+------------------------------------------------------------------+
//| logger.mqh                                                      |
//|                                                                |
//| A simple logging library for MQL5 Expert Advisors.              |
//|                                                                |
//| This logger implements a small subset of the features shown in |
//| the MQL5 article "Error Handling and Logging in MQL5".  It     |
//| provides multiple log levels, configurable output methods and   |
//| writes messages to an external file or to the terminal.  In     |
//| addition, it can be extended to support notifications.          |
//|                                                                |
//| Use this class to replace bare Print() calls in your EA and     |
//| structure logs by severity.                                     |
//+------------------------------------------------------------------+

#ifndef __LOGGER_MQH_
#define __LOGGER_MQH_

//--- Logging levels.  Messages below the configured level will be ignored.
enum ENUM_LOG_LEVEL
  {
   LOG_LEVEL_DEBUG = 0,
   LOG_LEVEL_INFO  = 1,
   LOG_LEVEL_WARNING = 2,
   LOG_LEVEL_ERROR = 3,
   LOG_LEVEL_FATAL = 4
  };

//--- Logging output methods
enum ENUM_LOGGING_METHOD
  {
   LOGGING_METHOD_FILE = 0,  // write to external log file
   LOGGING_METHOD_PRINT = 1  // use Print() as fallback
  };

//--- Simple logger class
class CLogger
  {
private:
   // static configuration variables
   static ENUM_LOG_LEVEL    m_minLevel;       // minimal log level to output
   static ENUM_LOGGING_METHOD m_method;       // output method
   static string            m_logFileName;    // name of log file

   //--- returns a textual representation of a log level
   static string LevelToString(ENUM_LOG_LEVEL level)
     {
      switch(level)
        {
         case LOG_LEVEL_FATAL:   return "FATAL";
         case LOG_LEVEL_ERROR:   return "ERROR";
         case LOG_LEVEL_WARNING: return "WARNING";
         case LOG_LEVEL_INFO:    return "INFO";
         case LOG_LEVEL_DEBUG:   return "DEBUG";
         default:                return "UNKNOWN";
        }
     }

   //--- writes a formatted message to an external file.  If writing fails,
   //    falls back to Print().  The file is opened in append mode and
   //    resides in the "Common Files" sandbox.  See MQL5 documentation for
   //    FileOpen() and FILE_COMMON for details【174191595510984†L639-L670】.
   static void WriteToFile(const string text)
     {
      // attempt to open the file.  FILE_COMMON writes to the shared
      // Terminal\Common\Files directory so that other programs can read it.
      int handle = FileOpen(m_logFileName,
                            FILE_TXT | FILE_WRITE | FILE_READ | FILE_COMMON);
      if(handle == INVALID_HANDLE)
        {
         // fallback to Print() if file cannot be opened
         Print(text);
         return;
        }
      // seek to end of file and append
      FileSeek(handle, 0, SEEK_END);
      FileWrite(handle, text);
      FileClose(handle);
     }

public:
   //--- configure the logger
   static void SetLogLevel(ENUM_LOG_LEVEL level)   { m_minLevel = level; }
   static void SetMethod(ENUM_LOGGING_METHOD method) { m_method   = method; }
   static void SetLogFileName(const string fileName) { m_logFileName = fileName; }

   //--- main entry point: log a message with specified severity.  If the
   //    message level is below the configured minimum, it is ignored.  The
   //    message is automatically prefixed with a timestamp and level.  Use
   //    __FILE__, __FUNCSIG__ and __LINE__ in the call site for extra context.
   static void Add(const ENUM_LOG_LEVEL level, const string message)
     {
      if(level < m_minLevel)
         return;

      // format timestamp (local time) and assemble the final message
      string timestamp = TimeToString(TimeLocal(), TIME_DATE|TIME_SECONDS);
      string text = timestamp + " " + LevelToString(level) + ": " + message;

      // write to selected destination
      if(m_method == LOGGING_METHOD_FILE)
         WriteToFile(text);
      else
         Print(text);
     }
  };

//--- static member definitions
ENUM_LOG_LEVEL       CLogger::m_minLevel   = LOG_LEVEL_INFO;
ENUM_LOGGING_METHOD  CLogger::m_method     = LOGGING_METHOD_PRINT;
string               CLogger::m_logFileName = "EA.log";

#endif // __LOGGER_MQH_
