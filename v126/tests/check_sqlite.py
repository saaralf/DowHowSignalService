"""SQLite contract tests; these do not compile or execute MQL5."""
import json
from pathlib import Path
import re
import sqlite3
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SCHEMA = (ROOT / 'v126/schema.sql').read_text()


def connect(path=':memory:'):
    db = sqlite3.connect(path, isolation_level=None)
    db.execute('PRAGMA foreign_keys=ON')
    db.executescript(SCHEMA)
    return db


def signal(db, context, direction, fail_event=False):
    db.execute('BEGIN IMMEDIATE')
    try:
        n = db.execute('SELECT last_trade_no FROM contexts WHERE context=?', (context,)).fetchone()[0] + 1
        db.execute('UPDATE contexts SET last_trade_no=? WHERE context=?', (n, context))
        db.execute('INSERT INTO positions VALUES(?,?,1,?,\'PENDING\',100,90,0.1,?,?)', (context, n, direction, "Sabio's entry", 'SL'))
        if fail_event:
            raise RuntimeError('fault before event write')
        db.execute("INSERT INTO events(context,trade_no,pos_no,kind,old_value,new_value,created_at) VALUES(?,?,1,'SIGNAL_CREATED','','PENDING',1)", (context, n))
        db.execute('COMMIT')
        return n
    except Exception:
        db.execute('ROLLBACK')
        raise


class Contracts(unittest.TestCase):
    def setUp(self):
        self.db = connect()
        self.db.execute("INSERT INTO contexts VALUES('c',0)")

    def tearDown(self):
        self.db.close()

    def test_shared_counter_and_no_reuse_after_close(self):
        self.assertEqual(signal(self.db, 'c', 'BUY'), 1)
        self.assertEqual(signal(self.db, 'c', 'SELL'), 2)
        self.db.execute("UPDATE positions SET status='CLOSED_SL' WHERE trade_no=1")
        self.assertEqual(signal(self.db, 'c', 'BUY'), 3)
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM positions').fetchone()[0], 3)

    def test_failure_rolls_back_number_state_and_event(self):
        with self.assertRaises(RuntimeError):
            signal(self.db, 'c', 'BUY', True)
        self.assertEqual(self.db.execute('SELECT last_trade_no FROM contexts').fetchone()[0], 0)
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM positions').fetchone()[0], 0)
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM events').fetchone()[0], 0)
        self.assertEqual(signal(self.db, 'c', 'BUY'), 1)

    def test_second_active_direction_rejected_without_counter_gap(self):
        signal(self.db, 'c', 'BUY')
        with self.assertRaises(sqlite3.IntegrityError):
            signal(self.db, 'c', 'BUY')
        self.assertEqual(signal(self.db, 'c', 'SELL'), 2)

    def test_contexts_do_not_share_counters(self):
        self.db.execute("INSERT INTO contexts VALUES('another timeframe',40)")
        self.assertEqual(signal(self.db, 'another timeframe', 'BUY'), 41)
        self.assertEqual(signal(self.db, 'c', 'BUY'), 1)

    def test_restart_keeps_open_pending_history_and_sabio(self):
        with tempfile.TemporaryDirectory() as t:
            p = str(Path(t) / 'state.sqlite')
            db = connect(p)
            db.execute("INSERT INTO contexts VALUES('c',7)")
            signal(db, 'c', 'BUY')
            signal(db, 'c', 'SELL')
            db.execute("UPDATE positions SET status='OPEN',sl=95 WHERE direction='BUY'")
            db.close()
            db = connect(p)
            self.assertEqual(db.execute('SELECT last_trade_no FROM contexts').fetchone()[0], 9)
            self.assertEqual(db.execute("SELECT status,sl,sabio_entry FROM positions WHERE direction='BUY'").fetchone(), ('OPEN', 95.0, "Sabio's entry"))
            self.assertEqual(db.execute("SELECT status FROM positions WHERE direction='SELL'").fetchone()[0], 'PENDING')
            db.close()

    def test_lease_prevents_second_owner_and_old_owner_writes(self):
        q = '''INSERT INTO leases VALUES('c',?,?) ON CONFLICT(context) DO UPDATE SET owner=excluded.owner,expires=excluded.expires WHERE leases.owner=excluded.owner OR leases.expires<=?'''
        self.db.execute(q, ('first', 130, 100))
        self.db.execute(q, ('second', 140, 110))
        self.assertEqual(self.db.execute('SELECT owner FROM leases').fetchone()[0], 'first')
        self.db.execute(q, ('second', 161, 131))
        self.assertEqual(self.db.execute("SELECT COUNT(*) FROM leases WHERE owner='first' AND expires>131").fetchone()[0], 0)
        self.assertEqual(self.db.execute('SELECT owner FROM leases').fetchone()[0], 'second')

    def test_distribution_and_test_only_routing(self):
        main = (ROOT / 'TradeAssistantV126_SQLite.mq5').read_text()
        discord = (ROOT / 'v126/discord_4.23.mqh').read_text()
        self.assertNotIn('GlobalVariable', main)
        self.assertNotIn('#resource', main)
        self.assertNotIn('BuyStop(', main)
        self.assertNotIn('SellStop(', main)
        self.assertIn('cfg.TestWebhook()', discord)
        self.assertNotIn('cfg.SystemWebhook()', discord)
        self.assertNotIn('cfg.RouteWebhook(', discord)
        self.assertIn('return discord_webhook_test;', discord)
        self.assertIn('if(get_discord_webhook()=="") return;', discord)
        self.assertIn('allowed_mentions', discord)
        for p in [ROOT / 'TradeAssistantV126_SQLite.mq5', *(ROOT / 'v126').glob('*.mqh')]:
            s = p.read_text()
            self.assertFalse(re.search(r'https?://discord(?:app)?\.com/api/webhooks/\d', s), p)
            for relative in re.findall(r'^#include "([^"]+)"', s, re.M):
                self.assertTrue((p.parent / relative).exists(), (p, relative))
            clean = re.sub(r'//[^\n]*|/\*.*?\*/|"(?:\\.|[^"\\])*"', '', s, flags=re.S)
            stack = []
            for c in clean:
                if c in '{(': stack.append(c)
                if c in '})':
                    self.assertTrue(stack, p)
                    self.assertEqual(stack.pop(), '{' if c == '}' else '(', p)
            self.assertFalse(stack, p)

    def test_shipped_mql_schema_matches_sql(self):
        actual = (ROOT / 'v126/SQLiteSchema.mqh').read_text()
        embedded = ''.join(json.loads(s) for s in actual.splitlines() if s.startswith('"'))
        self.assertEqual(embedded, SCHEMA)


if __name__ == '__main__':
    unittest.main()
