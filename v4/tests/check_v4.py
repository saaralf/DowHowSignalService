"""SQLite contract/invariant tests plus module boundary checks, not an MQL compiler."""
from pathlib import Path
import sqlite3
import unittest
import sys
import re

ROOT = Path(__file__).resolve().parents[1]
SCHEMA = (ROOT / 'schema.sql').read_text()

def schema_header():
    lines = SCHEMA.splitlines()
    return ('// Generated from schema.sql by tests/check_v4.py --generate-schema\n'
            '#ifndef TA4_SCHEMA_MQH\n#define TA4_SCHEMA_MQH\nstring TA4_SchemaSQL() { return\n' +
            ''.join('   "' + line.replace('\\', '\\\\').replace('"', '\\"') + '\\n"\n' for line in lines) +
            '   ; }\n#endif\n')

if '--generate-schema' in sys.argv:
    (ROOT / 'TA4_Schema.mqh').write_text(schema_header())
    sys.exit(0)

class Contracts(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(':memory:', isolation_level=None)
        self.db.execute('PRAGMA foreign_keys=ON')
        self.db.executescript(SCHEMA)
        self.db.execute("INSERT INTO trades VALUES('ctx',1,'LONG','ACTIVE',0,1,1)")
    def tearDown(self):
        self.db.close()
    def position(self, po, status='PENDING', tr=1):
        self.db.execute("INSERT INTO positions VALUES('ctx',?,?, 'LONG',?,100,90,0,1,'100','90',1,1)", (tr, po, status))
    def test_active_cap_and_history_identity(self):
        for po in range(1, 5): self.position(po)
        with self.assertRaises(sqlite3.IntegrityError): self.position(5)
        self.db.execute("UPDATE positions SET status='CLOSED_SL' WHERE pos_no=3")
        self.position(5)
        self.assertEqual(self.db.execute("SELECT status FROM positions WHERE pos_no=3").fetchone()[0], 'CLOSED_SL')
        self.assertEqual(self.db.execute('SELECT count(*) FROM positions').fetchone()[0], 5)
        with self.assertRaises(sqlite3.IntegrityError): self.position(3, 'CLOSED_CANCEL')
    def test_one_active_trade_each_direction(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("INSERT INTO trades VALUES('ctx',2,'LONG','ACTIVE',0,1,1)")
        self.db.execute("INSERT INTO trades VALUES('ctx',2,'SHORT','ACTIVE',0,1,1)")
        self.db.execute("UPDATE trades SET status='CLOSED' WHERE trade_no=1")
        self.db.execute("INSERT INTO trades VALUES('ctx',3,'LONG','ACTIVE',0,1,1)")
    def test_context_isolation(self):
        self.db.execute("INSERT INTO trades VALUES('other-account',1,'LONG','ACTIVE',0,1,1)")
        self.db.execute("INSERT INTO trades VALUES('other-timeframe',1,'LONG','ACTIVE',0,1,1)")
        self.assertEqual(self.db.execute('SELECT count(*) FROM trades').fetchone()[0], 3)
    def test_state_event_outbox_rollback(self):
        self.db.execute('BEGIN IMMEDIATE')
        self.position(1)
        self.db.execute("INSERT INTO events VALUES('e1','ctx','SIGNAL_CREATED',1,1,'','PENDING','USER',1)")
        self.db.execute("INSERT INTO outbox(event_id,context,message,state,updated_at) VALUES('e1','ctx','message','QUEUED',1)")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("INSERT INTO outbox(event_id,context,message,state,updated_at) VALUES('e1','ctx','duplicate','QUEUED',1)")
        self.db.execute('ROLLBACK')
        for table in ('positions','events','outbox'):
            self.assertEqual(self.db.execute(f'SELECT count(*) FROM {table}').fetchone()[0], 0)
    def test_outbox_crash_and_order(self):
        for i, state in enumerate(('SENDING', 'QUEUED'), 1):
            self.db.execute("INSERT INTO events VALUES(?,'ctx','SIGNAL_CREATED',1,?,'','PENDING','USER',1)", (f'e{i}', i))
            self.db.execute("INSERT INTO outbox(event_id,context,message,state,updated_at) VALUES(?,'ctx','message',?,1)", (f'e{i}', state))
        self.db.execute("UPDATE outbox SET state='UNKNOWN' WHERE context='ctx' AND state='SENDING'")
        self.assertEqual(self.db.execute("SELECT state FROM outbox WHERE context='ctx' AND state!='SENT' ORDER BY id LIMIT 1").fetchone()[0], 'UNKNOWN')
        self.db.execute("UPDATE outbox SET state='SENT' WHERE event_id='e1'")
        self.assertEqual(self.db.execute("SELECT event_id FROM outbox WHERE state!='SENT' ORDER BY id LIMIT 1").fetchone()[0], 'e2')
    def test_mixed_cancel_query_and_pos1_cascade(self):
        self.position(1, 'OPEN');self.position(2);self.position(3, 'CLOSED_SL')
        self.db.execute("UPDATE positions SET status='CLOSED_POS1_SL' WHERE context='ctx' AND trade_no=1 AND pos_no!=1 AND status IN ('PENDING','OPEN')")
        self.db.execute("UPDATE positions SET status='CLOSED_SL' WHERE pos_no=1")
        self.assertEqual(self.db.execute("SELECT count(*) FROM positions WHERE status IN ('PENDING','OPEN')").fetchone()[0], 0)
        self.assertEqual(self.db.execute("SELECT status FROM positions WHERE pos_no=3").fetchone()[0], 'CLOSED_SL')
    def test_lease_takeover(self):
        sql = "INSERT INTO leases VALUES('ctx',?,?) ON CONFLICT(context) DO UPDATE SET owner=excluded.owner,expires=excluded.expires WHERE leases.expires<=? OR leases.owner=excluded.owner"
        self.db.execute(sql, ('first', 30, 0))
        self.db.execute(sql, ('second', 31, 1))
        self.assertEqual(self.db.execute('SELECT owner FROM leases').fetchone()[0], 'first')
        self.db.execute(sql, ('second', 61, 31))
        self.assertEqual(self.db.execute('SELECT owner FROM leases').fetchone()[0], 'second')
    def test_bad_states_and_foreign_keys(self):
        with self.assertRaises(sqlite3.IntegrityError):self.position(1, 'BOGUS')
        with self.assertRaises(sqlite3.IntegrityError):self.position(1, tr=99)
    def test_mql_delimiters_and_relative_includes(self):
        # Static syntax safeguard only; MetaEditor is still required.
        files = [ROOT.parent / 'TradeAssistantV4.mq5', *ROOT.glob('*.mqh'), *ROOT.joinpath('tests').glob('*.mq5')]
        token = r'//[^\n]*|/\*.*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\''
        for path in files:
            source = path.read_text()
            clean = re.sub(token, '', source, flags=re.S)
            stack = []
            for char in clean:
                if char in '({[': stack.append(char)
                elif char in ')}]':
                    self.assertTrue(stack, str(path))
                    self.assertEqual(stack.pop(), {')':'(', ']':'[', '}':'{'}[char], str(path))
            self.assertFalse(stack, str(path))
            for include in re.findall(r'#include "([^"]+)"', source):
                self.assertTrue((path.parent / include).exists(), (str(path), include))
    def test_generated_schema_and_boundaries(self):
        self.assertEqual((ROOT / 'TA4_Schema.mqh').read_text(), schema_header())
        for filename in ('TA4_InputUI.mqh', 'TA4_Panel.mqh'):
            code = (ROOT / filename).read_text()
            for forbidden in ('Database', 'WebRequest', 'TA4_Repository', 'TA4_Core', 'TA4_Discord'):
                self.assertNotIn(forbidden, code, filename)
        core = (ROOT / 'TA4_Core.mqh').read_text()
        for forbidden in ('ObjectSet', 'ObjectGet', 'WebRequest', 'BuyStop', 'SellStop', 'PositionClose', 'OrderDelete'):
            self.assertNotIn(forbidden, core)
        discord = (ROOT / 'TA4_Discord.mqh').read_text()
        self.assertNotIn('Database', discord)
        self.assertNotIn('TA4_Repository', discord)
        main = (ROOT.parent / 'TradeAssistantV4.mq5').read_text()
        for forbidden in ('BuyStop', 'SellStop', 'PositionClose', 'OrderDelete', 'DatabaseExecute'):
            self.assertNotIn(forbidden, main)

if __name__ == '__main__': unittest.main()
