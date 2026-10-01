// Generated from schema.sql by tests/check_v4.py --generate-schema
#ifndef TA4_SCHEMA_MQH
#define TA4_SCHEMA_MQH
string TA4_SchemaSQL() { return
   "CREATE TABLE IF NOT EXISTS schema_version(version INTEGER NOT NULL);\n"
   "INSERT INTO schema_version(version) SELECT 1 WHERE NOT EXISTS(SELECT 1 FROM schema_version);\n"
   "CREATE TABLE IF NOT EXISTS leases(context TEXT PRIMARY KEY,owner TEXT NOT NULL,expires INTEGER NOT NULL);\n"
   "CREATE TABLE IF NOT EXISTS contexts(context TEXT PRIMARY KEY,last_trade_no INTEGER NOT NULL DEFAULT 0);\n"
   "CREATE TABLE IF NOT EXISTS drafts(context TEXT PRIMARY KEY,entry REAL NOT NULL,sl REAL NOT NULL,tp REAL NOT NULL,sabio_entry TEXT NOT NULL,sabio_sl TEXT NOT NULL,entry_override INTEGER NOT NULL,sl_override INTEGER NOT NULL,updated_at INTEGER NOT NULL);\n"
   "CREATE TABLE IF NOT EXISTS trades(context TEXT NOT NULL,trade_no INTEGER NOT NULL,direction TEXT NOT NULL CHECK(direction IN ('LONG','SHORT')),status TEXT NOT NULL CHECK(status IN ('ACTIVE','CLOSED')),last_pos_no INTEGER NOT NULL DEFAULT 0,created_at INTEGER NOT NULL,updated_at INTEGER NOT NULL,PRIMARY KEY(context,trade_no));\n"
   "CREATE UNIQUE INDEX IF NOT EXISTS one_active_direction ON trades(context,direction) WHERE status='ACTIVE';\n"
   "CREATE TABLE IF NOT EXISTS positions(context TEXT NOT NULL,trade_no INTEGER NOT NULL,pos_no INTEGER NOT NULL CHECK(pos_no>0),direction TEXT NOT NULL,status TEXT NOT NULL CHECK(status IN ('PENDING','OPEN','CLOSED_SL','CLOSED_TP','CLOSED_CANCEL','CLOSED_POS1_SL')),entry REAL NOT NULL CHECK(entry>0),sl REAL NOT NULL CHECK(sl>0),tp REAL NOT NULL DEFAULT 0,lots REAL NOT NULL CHECK(lots>0),sabio_entry TEXT NOT NULL,sabio_sl TEXT NOT NULL,created_at INTEGER NOT NULL,updated_at INTEGER NOT NULL,PRIMARY KEY(context,trade_no,pos_no),FOREIGN KEY(context,trade_no) REFERENCES trades(context,trade_no));\n"
   "CREATE TRIGGER IF NOT EXISTS max_active_positions BEFORE INSERT ON positions WHEN NEW.status IN ('PENDING','OPEN') AND (SELECT COUNT(*) FROM positions WHERE context=NEW.context AND trade_no=NEW.trade_no AND status IN ('PENDING','OPEN'))>=4 BEGIN SELECT RAISE(ABORT,'maximum four active positions'); END;\n"
   "CREATE TABLE IF NOT EXISTS events(event_id TEXT PRIMARY KEY,context TEXT NOT NULL,kind TEXT NOT NULL,trade_no INTEGER NOT NULL,pos_no INTEGER NOT NULL,old_value TEXT NOT NULL,new_value TEXT NOT NULL,source TEXT NOT NULL,occurred_at INTEGER NOT NULL);\n"
   "CREATE TABLE IF NOT EXISTS outbox(id INTEGER PRIMARY KEY AUTOINCREMENT,event_id TEXT NOT NULL UNIQUE,context TEXT NOT NULL,message TEXT NOT NULL,image TEXT NOT NULL DEFAULT '',state TEXT NOT NULL CHECK(state IN ('QUEUED','SENDING','SENT','FAILED','UNKNOWN')),attempts INTEGER NOT NULL DEFAULT 0,next_attempt INTEGER NOT NULL DEFAULT 0,last_error TEXT NOT NULL DEFAULT '',updated_at INTEGER NOT NULL,FOREIGN KEY(event_id) REFERENCES events(event_id));\n"
   "CREATE INDEX IF NOT EXISTS outbox_context ON outbox(context,id);\n"
   ; }
#endif
