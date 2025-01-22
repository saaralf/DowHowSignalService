//+------------------------------------------------------------------+
//| Expert Advisor                                                   |
//+------------------------------------------------------------------+


// Datei für das Speichern und Laden
input string FileName = "VirtualTrades.csv";

// Struktur für virtuelle Trades
struct VirtualTrade {
    int trade_id;                // Eindeutige ID
    string type;                 // "buy" oder "sell"
    string symbol;               // Symbol des Charts
    ENUM_TIMEFRAMES timeframe;   // Zeitrahmen des Charts
    double entry_price;          // Einstiegspreis
    double stop_loss;            // SL
    double take_profit;          // TP
    bool tp_sent;                // TP erreicht (Discord gesendet)
    bool sl_sent;                // SL erreicht (Discord gesendet)
    bool closed;                 // Virtuell geschlossen
};

// Globale Variablen
int trade_counter = 0;                          // Zähler für Trades
bool buy_trade_exists = false, sell_trade_exists = false;  // Status
VirtualTrade last_buy_trade, last_sell_trade;   // Letzter Buy/Sell-Trade

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit() {
    Print("Expert Advisor gestartet");
    CreateButton("btn_buy", 10, 10, "Virtueller Buy");
    CreateButton("btn_sell", 10, 50, "Virtueller Sell");
    CreateButton("btn_close_buy", 10, 90, "Close Buy");
    CreateButton("btn_close_sell", 10, 130, "Close Sell");

    // Datei laden und Trades wiederherstellen
    LoadTradesFromFile();
    ShowOpenTradesOnChart();
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    CheckVirtualTradeStatus();  // Virtuelle Trades überwachen
}

//+------------------------------------------------------------------+
//| Button-Events                                                    |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
    if (id == CHARTEVENT_OBJECT_CLICK) {
        if (sparam == "btn_buy") {
            CreateTradeButtonHandler("buy");
        }
        if (sparam == "btn_sell") {
            CreateTradeButtonHandler("sell");
        }
        if (sparam == "btn_close_buy") {
            CloseVirtualTrade("buy");
        }
        if (sparam == "btn_close_sell") {
            CloseVirtualTrade("sell");
        }
    }
}

//+------------------------------------------------------------------+
//| Virtuelle Trades erstellen                                       |
//+------------------------------------------------------------------+
void CreateTradeButtonHandler(string type) {
    double price = SymbolInfoDouble(Symbol(), (type == "buy") ? SYMBOL_ASK : SYMBOL_BID);
    double sl = (type == "buy") ? price - 50 * Point : price + 50 * Point;
    double tp = (type == "buy") ? price + 50 * Point : price - 50 * Point;

    VirtualTrade new_trade;
    new_trade.trade_id = ++trade_counter;
    new_trade.type = type;
    new_trade.symbol = Symbol();
    new_trade.timeframe = Period();
    new_trade.entry_price = price;
    new_trade.stop_loss = sl;
    new_trade.take_profit = tp;
    new_trade.tp_sent = false;
    new_trade.sl_sent = false;
    new_trade.closed = false;

    if (type == "buy") {
        last_buy_trade = new_trade;
        buy_trade_exists = true;
    } else if (type == "sell") {
        last_sell_trade = new_trade;
        sell_trade_exists = true;
    }

    SaveTradesToFile();
    Print("Virtueller ", type, "-Trade erstellt: ID=", new_trade.trade_id);
}

//+------------------------------------------------------------------+
//| Virtuelle Trades schließen                                       |
//+------------------------------------------------------------------+
bool CloseVirtualTrade(string type) {
    if (type == "buy" && buy_trade_exists && !last_buy_trade.closed) {
        last_buy_trade.closed = true;
        SendToDiscord("Virtueller Buy-Trade #" + IntegerToString(last_buy_trade.trade_id) + " geschlossen.");
        SaveTradesToFile();
        return true;
    }
    if (type == "sell" && sell_trade_exists && !last_sell_trade.closed) {
        last_sell_trade.closed = true;
        SendToDiscord("Virtueller Sell-Trade #" + IntegerToString(last_sell_trade.trade_id) + " geschlossen.");
        SaveTradesToFile();
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Trades in Datei speichern                                        |
//+------------------------------------------------------------------+
void SaveTradesToFile() {
    ResetLastError();
    int handle = FileOpen(FileName, FILE_WRITE | FILE_CSV | FILE_COMMON);
    if (handle == INVALID_HANDLE) {
        Print("Fehler beim Öffnen der Datei: ", GetLastError());
        return;
    }

    // Tradenummer speichern
    FileWrite(handle, "TradeCounter", trade_counter);

    // Buy-Trade speichern
    if (buy_trade_exists) {
        FileWrite(handle, last_buy_trade.trade_id, last_buy_trade.type, last_buy_trade.symbol,
                  last_buy_trade.timeframe, last_buy_trade.entry_price, last_buy_trade.stop_loss,
                  last_buy_trade.take_profit, last_buy_trade.tp_sent, last_buy_trade.sl_sent, last_buy_trade.closed);
    }

    // Sell-Trade speichern
    if (sell_trade_exists) {
        FileWrite(handle, last_sell_trade.trade_id, last_sell_trade.type, last_sell_trade.symbol,
                  last_sell_trade.timeframe, last_sell_trade.entry_price, last_sell_trade.stop_loss,
                  last_sell_trade.take_profit, last_sell_trade.tp_sent, last_sell_trade.sl_sent, last_sell_trade.closed);
    }

    FileClose(handle);
}

//+------------------------------------------------------------------+
//| Trades aus Datei laden                                           |
//+------------------------------------------------------------------+
void LoadTradesFromFile() {
    ResetLastError();
    int handle = FileOpen(FileName, FILE_READ | FILE_CSV | FILE_COMMON);
    if (handle == INVALID_HANDLE) {
        Print("Keine gespeicherte Datei gefunden oder Fehler beim Öffnen: ", GetLastError());
        return;
    }

    // Tradenummer laden
    string key;
    trade_counter = 0;
    if (FileReadString(handle) == "TradeCounter") {
        trade_counter = FileReadInteger(handle);
    }

    // Buy-Trade laden
    if (!FileIsEnding(handle)) {
        last_buy_trade.trade_id = FileReadInteger(handle);
        last_buy_trade.type = FileReadString(handle);
        last_buy_trade.symbol = FileReadString(handle);
        last_buy_trade.timeframe = (ENUM_TIMEFRAMES)FileReadInteger(handle);
        last_buy_trade.entry_price = FileReadDouble(handle);
        last_buy_trade.stop_loss = FileReadDouble(handle);
        last_buy_trade.take_profit = FileReadDouble(handle);
        last_buy_trade.tp_sent = FileReadInteger(handle);
        last_buy_trade.sl_sent = FileReadInteger(handle);
        last_buy_trade.closed = FileReadInteger(handle);
        buy_trade_exists = true;
    }

    // Sell-Trade laden
    if (!FileIsEnding(handle)) {
        last_sell_trade.trade_id = FileReadInteger(handle);
        last_sell_trade.type = FileReadString(handle);
        last_sell_trade.symbol = FileReadString(handle);
        last_sell_trade.timeframe = (ENUM_TIMEFRAMES)FileReadInteger(handle);
        last_sell_trade.entry_price = FileReadDouble(handle);
        last_sell_trade.stop_loss = FileReadDouble(handle);
        last_sell_trade.take_profit = FileReadDouble(handle);
        last_sell_trade.tp_sent = FileReadInteger(handle);
        last_sell_trade.sl_sent = FileReadInteger(handle);
        last_sell_trade.closed = FileReadInteger(handle);
        sell_trade_exists = true;
    }

    FileClose(handle);
}

//+------------------------------------------------------------------+
//| Offene Trades im Chart anzeigen                                  |
//+------------------------------------------------------------------+
void ShowOpenTradesOnChart() {
    if (buy_trade_exists && !last_buy_trade.closed) {
        string text = "Buy-Trade #" + IntegerToString(last_buy_trade.trade_id) + ": " +
                      "EP=" + DoubleToString(last_buy_trade.entry_price, 5) +
                      ", SL=" + DoubleToString(last_buy_trade.stop_loss, 5) +
                      ", TP=" + DoubleToString(last_buy_trade.take_profit, 5);
        ObjectCreate(0, "buy_trade_text", OBJ_LABEL, 0, 0, 0);
        ObjectSetString(0, "buy_trade_text", OBJPROP_TEXT, text);
        ObjectSetInteger(0, "buy_trade_text", OBJPROP_CORNER, 0);
        ObjectSetInteger(0, "buy_trade_text", OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, "buy_trade_text", OBJPROP_YDISTANCE, 200);
    }
    if (sell_trade_exists && !last_sell_trade.closed) {
        string text = "Sell-Trade #" + IntegerToString(last_sell_trade.trade_id) + ": " +
                      "EP=" + DoubleToString(last_sell_trade.entry_price, 5) +
                      ", SL=" + DoubleToString(last_sell_trade.stop_loss, 5) +
                      ", TP=" + DoubleToString(last_sell_trade.take_profit, 5);
        ObjectCreate(0, "sell_trade_text", OBJ_LABEL, 0, 0, 0);
        ObjectSetString(0, "sell_trade_text", OBJPROP_TEXT, text);
        ObjectSetInteger(0, "sell_trade_text", OBJPROP_CORNER, 0);
        ObjectSetInteger(0, "sell_trade_text", OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, "sell_trade_text", OBJPROP_YDISTANCE, 220);
    }
}
void SendToDiscord(string message) {
    string url = "https://discord.com/api/webhooks/...";  // Deinen Webhook-Link einfügen
    string headers;
    string body = "{\"content\": \"" + message + "\"}";
    int timeout = 10;
    char result[];

    int res = WebRequest("POST", url, headers, timeout, body, 0, result);
    if (res == 200) {
        Print("Nachricht an Discord gesendet: ", message);
    } else {
        Print("Fehler beim Senden an Discord: ", GetLastError());
    }
}
void CheckVirtualTradeStatus() {
    double price = SymbolInfoDouble(Symbol(), SYMBOL_BID);

    // Überprüfung Buy-Trade
    if (buy_trade_exists && !last_buy_trade.closed) {
        if (!last_buy_trade.tp_sent && price >= last_buy_trade.take_profit) {
            SendToDiscord("TP erreicht für virtuellen Buy-Trade #" + IntegerToString(last_buy_trade.trade_id));
            last_buy_trade.tp_sent = true;
        }
        if (!last_buy_trade.sl_sent && price <= last_buy_trade.stop_loss) {
            SendToDiscord("SL erreicht für virtuellen Buy-Trade #" + IntegerToString(last_buy_trade.trade_id));
            last_buy_trade.sl_sent = true;
        }
    }

    // Überprüfung Sell-Trade
    if (sell_trade_exists && !last_sell_trade.closed) {
        if (!last_sell_trade.tp_sent && price <= last_sell_trade.take_profit) {
            SendToDiscord("TP erreicht für virtuellen Sell-Trade #" + IntegerToString(last_sell_trade.trade_id));
            last_sell_trade.tp_sent = true;
        }
        if (!last_sell_trade.sl_sent && price >= last_sell_trade.stop_loss) {
            SendToDiscord("SL erreicht für virtuellen Sell-Trade #" + IntegerToString(last_sell_trade.trade_id));
            last_sell_trade.sl_sent = true;
        }
    }
}
