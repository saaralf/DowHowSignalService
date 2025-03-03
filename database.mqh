#ifndef __TRADEDB_MQH__
#define __TRADEDB_MQH__


// Unsere TradeInfo-Struktur – exakt wie von Dir vorgegeben
struct TradeInfo
{
   int    tradenummer;      // Wird automatisch als PRIMARY KEY (AUTOINCREMENT) vergeben
   string symbol;
   string type;            // "LONG" oder "SHORT"
   double price;
   double lots;
   double sl;
   double tp;
   string sabioentry;
   string sabiosl;
   string sabiotp;
   bool   was_send;
   bool   is_trade_pending;
};

// Klasse zur Verwaltung der Datenbank (Tabelle Tradeinfo)
class CTradeDB
{
private:
   string m_dbFilename;
   int    m_dbHandle; // Datenbank-Handle (INVALID_HANDLE bei Fehler)

public:
   // Konstruktor: speichert den Dateinamen
   CTradeDB(string filename)
   {
      m_dbFilename = filename;
      m_dbHandle   = INVALID_HANDLE;
   }
   
   // Destruktor: schließt die DB, falls sie geöffnet ist
   ~CTradeDB()
   {
      if(m_dbHandle != INVALID_HANDLE)
         DatabaseClose(m_dbHandle);
   }
   
   // Öffnet die Datenbank mit den Flags für READ/WRITE, CREATE und COMMON. Legt danach die Tabelle an.
   bool Open()
   {
      uint flags = DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON;
      m_dbHandle = DatabaseOpen(m_dbFilename, flags);
      if(m_dbHandle == INVALID_HANDLE)
      {
         Print("Fehler beim Öffnen der DB: ", m_dbFilename, " Code: ", GetLastError());
         return false;
      }
      return CreateTables();
   }
   
   // Legt die Tabelle Tradeinfo an, falls sie noch nicht existiert.
   bool CreateTables()
   {
      // Wir legen nun eine Tabelle mit den Spalten an, die unserer TradeInfo-Struktur entsprechen.
      // Für bool-Felder speichern wir als INTEGER (0/1).
      string query = "CREATE TABLE IF NOT EXISTS Tradeinfo ("
                     "tradenummer INTEGER PRIMARY KEY AUTOINCREMENT, "
                     "symbol TEXT, "
                     "type TEXT, "
                     "price REAL, "
                     "lots REAL, "
                     "sl REAL, "
                     "tp REAL, "
                     "sabioentry TEXT, "
                     "sabiosl TEXT, "
                     "sabiotp TEXT, "
                     "was_send INTEGER, "
                     "is_trade_pending INTEGER"
                     ")";
      if(!DatabaseExecute(m_dbHandle, query))
      {
         Print("Fehler beim Erstellen der Tabelle Tradeinfo. Code: ", GetLastError());
         return false;
      }
      return true;
   }
   
   // Fügt einen neuen TradeInfo-Datensatz ein. Die tradenummer wird automatisch vergeben.
   bool InsertTradeInfo(const TradeInfo &trade)
   {
      // Boolesche Werte werden als Integer gespeichert: 1 (true) bzw. 0 (false)
      int wasSend       = trade.was_send ? 1 : 0;
      int isTradePending = trade.is_trade_pending ? 1 : 0;
      
      // Die Spalte 'tradenummer' wird nicht explizit gesetzt, da sie AUTOINCREMENT ist.
      string query = StringFormat("INSERT INTO Tradeinfo (symbol, type, price, lots, sl, tp, sabioentry, sabiosl, sabiotp, was_send, is_trade_pending) "
                                  "VALUES ('%s', '%s', %f, %f, %f, %f, '%s', '%s', '%s', %d, %d)",
                                  trade.symbol, trade.type, trade.price, trade.lots, trade.sl, trade.tp,
                                  trade.sabioentry, trade.sabiosl, trade.sabiotp, wasSend, isTradePending);
      if(!DatabaseExecute(m_dbHandle, query))
      {
         Print("Fehler beim Einfügen der Tradeinfo. Code: ", GetLastError());
         return false;
      }
      return true;
   }
   
 // Ermittelt die zuletzt vergebene TradeNumber (MAX-Wert)
int GetLastTradeNumber()
{
   string query = "SELECT MAX(tradenummer) FROM Tradeinfo";
   int request = DatabasePrepare(m_dbHandle, query);
   if(request == INVALID_HANDLE)
   {
      Print("Fehler bei der Vorbereitung der Abfrage. Code: ", GetLastError());
      return -1;
   }
   int lastTrade = 0;
   if(DatabaseRead(request))
   {
      string text;
      if(DatabaseColumnText(request, 0, text))
         lastTrade = (int)StringToInteger(text);
      else
         Print("Fehler beim Auslesen der Spalte. Code: ", GetLastError());
   }
   DatabaseFinalize(request);
   return lastTrade;
}

   
   // Liest aus den letzten 10 Datensätzen (absteigend sortiert) jeweils den letzten LONG- und SHORT-Trade.
   bool GetLastTwoTrades(TradeInfo &lastLong, TradeInfo &lastShort)
   {
      string query = "SELECT tradenummer, symbol, type, price, lots, sl, tp, sabioentry, sabiosl, sabiotp, was_send, is_trade_pending "
                     "FROM Tradeinfo ORDER BY tradenummer DESC LIMIT 10";
      int request = DatabasePrepare(m_dbHandle, query);
      if(request == INVALID_HANDLE)
      {
         Print("Fehler bei der Vorbereitung der Abfrage für letzte Trades. Code: ", GetLastError());
         return false;
      }
      bool foundLong = false;
      bool foundShort = false;
      TradeInfo temp;
      // Mit DatabaseReadBind() wird die aktuelle Zeile direkt in die Struktur 'temp' gebunden.
      while(DatabaseReadBind(request, temp))
      {
         // Wir nehmen an, dass im Feld 'type' die Werte "LONG" oder "SHORT" stehen.
         if(!foundLong && (StringFind(temp.type, "LONG") != -1))
         {
            lastLong = temp;
            foundLong = true;
         }
         if(!foundShort && (StringFind(temp.type, "SHORT") != -1))
         {
            lastShort = temp;
            foundShort = true;
         }
         if(foundLong && foundShort)
            break;
      }
      DatabaseFinalize(request);
      return (foundLong && foundShort);
   }
};

#endif
