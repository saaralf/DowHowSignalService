#ifndef DH126_SCHEMA
#define DH126_SCHEMA
string DH126Schema() { return
"CREATE TABLE IF NOT EXISTS schema_version(version INTEGER NOT NULL CHECK(version=1));\n"
"INSERT INTO schema_version SELECT 1 WHERE NOT EXISTS(SELECT 1 FROM schema_version);\n"
"CREATE TABLE IF NOT EXISTS contexts(context TEXT PRIMARY KEY,last_trade_no INTEGER NOT NULL CHECK(last_trade_no>=0));\n"
"CREATE TABLE IF NOT EXISTS leases(context TEXT PRIMARY KEY,owner TEXT NOT NULL,expires INTEGER NOT NULL);\n"
"CREATE TABLE IF NOT EXISTS positions(context TEXT NOT NULL,trade_no INTEGER NOT NULL CHECK(trade_no>0),pos_no INTEGER NOT NULL CHECK(pos_no=1),direction TEXT NOT NULL CHECK(direction IN ('BUY','SELL')),status TEXT NOT NULL CHECK(status IN ('PENDING','OPEN','CLOSED_SL','CLOSED_CANCEL')),entry REAL NOT NULL CHECK(entry>0),sl REAL NOT NULL CHECK(sl>0),lots REAL NOT NULL CHECK(lots>0),sabio_entry TEXT NOT NULL,sabio_sl TEXT NOT NULL,PRIMARY KEY(context,trade_no,pos_no),FOREIGN KEY(context) REFERENCES contexts(context));\n"
"CREATE UNIQUE INDEX IF NOT EXISTS one_active_direction ON positions(context,direction) WHERE status IN ('PENDING','OPEN');\n"
"CREATE TABLE IF NOT EXISTS events(id INTEGER PRIMARY KEY AUTOINCREMENT,context TEXT NOT NULL,trade_no INTEGER NOT NULL,pos_no INTEGER NOT NULL,kind TEXT NOT NULL,old_value TEXT NOT NULL,new_value TEXT NOT NULL,created_at INTEGER NOT NULL);\n"
; }
#endif
