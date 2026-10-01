"""Executable SQLite contracts and source wiring; no MQL compilation claim."""
import json
from pathlib import Path
import re
import sqlite3
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
V = ROOT / 'v126'
SCHEMA = (V / 'schema.sql').read_text()
OLD_SCHEMA = (V / 'tests/schema_v1.sql').read_text()
BEGIN_MIGRATION = (V / 'migration_v1_v2.sql').read_text()
END_MIGRATION = (V / 'migration_v1_v2_finish.sql').read_text()


def connect(path=':memory:', schema=SCHEMA):
    db = sqlite3.connect(path, isolation_level=None)
    db.execute('PRAGMA foreign_keys=ON')
    for sql in schema.splitlines():
        db.execute(sql)
    return db


def next_numbers(db, ctx, direction):
    row = db.execute("SELECT trade_no FROM trades WHERE context=? AND direction=? AND status='ACTIVE'", (ctx, direction)).fetchone()
    if row:
        last = db.execute('SELECT MAX(pos_no) FROM positions WHERE context=? AND trade_no=?', (ctx, row[0])).fetchone()[0]
        return row[0], last + 1
    return db.execute('SELECT last_trade_no+1 FROM contexts WHERE context=?', (ctx,)).fetchone()[0], 1


def signal(db, ctx, direction, tn, pn, fault=False):
    db.execute('BEGIN IMMEDIATE')
    try:
        if tn <= 0 or pn <= 0:
            raise ValueError('positive identity required')
        active = db.execute("SELECT trade_no FROM trades WHERE context=? AND direction=? AND status='ACTIVE'", (ctx, direction)).fetchone()
        if active and active[0] != tn:
            raise ValueError('finish active trade first')
        if not active:
            db.execute("INSERT INTO trades VALUES(?,?,?,'ACTIVE')", (ctx, tn, direction))
        previous = db.execute('SELECT COALESCE(MAX(pos_no),0) FROM positions WHERE context=? AND trade_no=?', (ctx, tn)).fetchone()[0]
        if pn <= previous:
            raise ValueError('position ID must increase')
        db.execute('UPDATE contexts SET last_trade_no=MAX(last_trade_no,?) WHERE context=?', (tn, ctx))
        db.execute("INSERT INTO positions VALUES(?,?,?,?,'PENDING',100,90,0.1,?,?)", (ctx, tn, pn, direction, "Sabio's entry", 'SL'))
        if fault:
            raise RuntimeError('fault between state and event')
        db.execute("INSERT INTO events(context,trade_no,pos_no,kind,old_value,new_value,created_at) VALUES(?,?,?,'SIGNAL_CREATED','','PENDING',1)", (ctx, tn, pn))
        db.execute('COMMIT')
    except Exception:
        db.execute('ROLLBACK')
        raise


def close(db, ctx, tn, pn, reason='CLOSED_CANCEL', fault=False):
    db.execute('BEGIN IMMEDIATE')
    try:
        db.execute("UPDATE positions SET status=? WHERE context=? AND trade_no=? AND pos_no=? AND status IN ('PENDING','OPEN')", (reason, ctx, tn, pn))
        if reason == 'CLOSED_SL' and pn == 1:
            db.execute("INSERT INTO events(context,trade_no,pos_no,kind,old_value,new_value,created_at) SELECT context,trade_no,pos_no,'TRADE_ENDED_BY_POS1_SL',status,'CLOSED_POS1_SL',2 FROM positions WHERE context=? AND trade_no=? AND status IN ('PENDING','OPEN')", (ctx, tn))
            db.execute("UPDATE positions SET status='CLOSED_POS1_SL' WHERE context=? AND trade_no=? AND status IN ('PENDING','OPEN')", (ctx, tn))
        db.execute("UPDATE trades SET status='CLOSED' WHERE context=? AND trade_no=? AND NOT EXISTS(SELECT 1 FROM positions WHERE context=? AND trade_no=? AND status IN ('PENDING','OPEN'))", (ctx, tn, ctx, tn))
        if fault:
            raise RuntimeError('fault during closure')
        db.execute('COMMIT')
    except Exception:
        db.execute('ROLLBACK')
        raise


def migrate(db, fault=False):
    db.execute('BEGIN IMMEDIATE')
    try:
        for sql in (BEGIN_MIGRATION + SCHEMA + END_MIGRATION).splitlines():
            db.execute(sql)
            if fault and sql.startswith('INSERT INTO positions SELECT'):
                raise RuntimeError('fault before migration finish')
        db.execute('COMMIT')
    except Exception:
        db.execute('ROLLBACK')
        raise


class Contracts(unittest.TestCase):
    def setUp(self):
        self.db = connect()
        self.db.execute("INSERT INTO contexts VALUES('c',0)")

    def tearDown(self):
        self.db.close()

    def test_active_trade_continues_across_direction_switch(self):
        signal(self.db, 'c', 'BUY', 2, 1)
        self.assertEqual(next_numbers(self.db, 'c', 'BUY'), (2, 2))
        signal(self.db, 'c', 'BUY', 2, 2)
        self.assertEqual(next_numbers(self.db, 'c', 'SELL'), (3, 1))
        signal(self.db, 'c', 'SELL', 3, 1)
        self.assertEqual(next_numbers(self.db, 'c', 'BUY'), (2, 3))
        self.assertEqual(next_numbers(self.db, 'c', 'SELL'), (3, 2))

    def test_manual_production_number_and_position_import(self):
        signal(self.db, 'c', 'BUY', 127, 3)
        self.assertEqual(next_numbers(self.db, 'c', 'BUY'), (127, 4))
        self.assertEqual(next_numbers(self.db, 'c', 'SELL'), (128, 1))
        signal(self.db, 'c', 'BUY', 127, 8)
        self.assertEqual(next_numbers(self.db, 'c', 'BUY'), (127, 9))

    def test_failure_rolls_back_manual_number_new_trade_state_and_event(self):
        with self.assertRaises(RuntimeError):
            signal(self.db, 'c', 'BUY', 127, 1, fault=True)
        self.assertEqual(self.db.execute('SELECT last_trade_no FROM contexts').fetchone()[0], 0)
        for table in ['trades', 'positions', 'events']:
            self.assertEqual(self.db.execute(f'SELECT COUNT(*) FROM {table}').fetchone()[0], 0)

    def test_other_trade_in_active_direction_rejected(self):
        signal(self.db, 'c', 'BUY', 2, 1)
        with self.assertRaises(ValueError):
            signal(self.db, 'c', 'BUY', 3, 1)
        self.assertEqual(next_numbers(self.db, 'c', 'BUY'), (2, 2))
        self.assertEqual(self.db.execute('SELECT last_trade_no FROM contexts').fetchone()[0], 2)

    def test_duplicate_and_closed_position_ids_not_reused(self):
        signal(self.db, 'c', 'BUY', 2, 1)
        signal(self.db, 'c', 'BUY', 2, 2)
        with self.assertRaises(ValueError):
            signal(self.db, 'c', 'BUY', 2, 2)
        close(self.db, 'c', 2, 2)
        with self.assertRaises(ValueError):
            signal(self.db, 'c', 'BUY', 2, 2)
        self.assertEqual(next_numbers(self.db, 'c', 'BUY'), (2, 3))

    def test_four_active_positions_can_have_ids_greater_than_four(self):
        for pn in range(1, 5):
            signal(self.db, 'c', 'BUY', 2, pn)
        with self.assertRaises(sqlite3.IntegrityError):
            signal(self.db, 'c', 'BUY', 2, 5)
        close(self.db, 'c', 2, 3)
        signal(self.db, 'c', 'BUY', 2, 5)
        self.assertEqual(next_numbers(self.db, 'c', 'BUY'), (2, 6))

    def test_trade_ends_only_after_last_active_position(self):
        signal(self.db, 'c', 'BUY', 2, 1)
        signal(self.db, 'c', 'BUY', 2, 2)
        signal(self.db, 'c', 'SELL', 3, 1)
        close(self.db, 'c', 2, 1)
        self.assertEqual(next_numbers(self.db, 'c', 'BUY'), (2, 3))
        close(self.db, 'c', 2, 2)
        self.assertEqual(next_numbers(self.db, 'c', 'BUY'), (4, 1))
        self.assertEqual(next_numbers(self.db, 'c', 'SELL'), (3, 2))
        with self.assertRaises(sqlite3.IntegrityError):
            signal(self.db, 'c', 'BUY', 2, 3)

    def test_position_one_sl_atomic_cascade_preserves_opposite_direction(self):
        signal(self.db, 'c', 'BUY', 2, 1)
        signal(self.db, 'c', 'BUY', 2, 2)
        signal(self.db, 'c', 'SELL', 3, 1)
        with self.assertRaises(RuntimeError):
            close(self.db, 'c', 2, 1, 'CLOSED_SL', fault=True)
        self.assertEqual(self.db.execute("SELECT COUNT(*) FROM positions WHERE status='PENDING'").fetchone()[0], 3)
        close(self.db, 'c', 2, 1, 'CLOSED_SL')
        self.assertEqual(self.db.execute('SELECT status FROM positions ORDER BY trade_no,pos_no').fetchall(), [('CLOSED_SL',), ('CLOSED_POS1_SL',), ('PENDING',)])
        self.assertEqual(self.db.execute("SELECT COUNT(*) FROM events WHERE kind='TRADE_ENDED_BY_POS1_SL'").fetchone()[0], 1)

    def test_identity_and_closed_history_are_immutable(self):
        signal(self.db, 'c', 'BUY', 2, 1)
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('UPDATE positions SET pos_no=7')
        close(self.db, 'c', 2, 1)
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('UPDATE positions SET sl=80')

    def test_foreign_direction_same_trade_rejected(self):
        signal(self.db, 'c', 'BUY', 127, 1)
        with self.assertRaises(sqlite3.IntegrityError):
            signal(self.db, 'c', 'SELL', 127, 1)
        self.assertEqual(next_numbers(self.db, 'c', 'SELL'), (128, 1))

    def test_contexts_do_not_share_numbers(self):
        self.db.execute("INSERT INTO contexts VALUES('H1 other account',40)")
        signal(self.db, 'H1 other account', 'BUY', 41, 1)
        self.assertEqual(next_numbers(self.db, 'c', 'BUY'), (1, 1))

    def test_restart_restores_all_positions_and_sabio(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = str(Path(tmp) / 'state.sqlite')
            db = connect(path)
            db.execute("INSERT INTO contexts VALUES('c',0)")
            signal(db, 'c', 'BUY', 127, 1)
            signal(db, 'c', 'BUY', 127, 2)
            signal(db, 'c', 'SELL', 128, 1)
            db.execute("UPDATE positions SET status='OPEN',sl=95 WHERE trade_no=127 AND pos_no=1")
            db.close()
            db = connect(path)
            self.assertEqual(next_numbers(db, 'c', 'BUY'), (127, 3))
            self.assertEqual(next_numbers(db, 'c', 'SELL'), (128, 2))
            self.assertEqual(db.execute('SELECT COUNT(*) FROM positions').fetchone()[0], 3)
            self.assertEqual(db.execute('SELECT status,sl,sabio_entry FROM positions WHERE trade_no=127 AND pos_no=1').fetchone(), ('OPEN', 95.0, "Sabio's entry"))
            db.close()

    def old_database(self):
        db = connect(schema=OLD_SCHEMA)
        db.execute("INSERT INTO contexts VALUES('c',2)")
        db.execute("INSERT INTO positions VALUES('c',1,1,'BUY','CLOSED_SL',100,90,0.1,'old','90')")
        db.execute("INSERT INTO positions VALUES('c',2,1,'BUY','OPEN',100,95,0.1,'current','95')")
        db.execute("INSERT INTO events VALUES(1,'c',2,1,'SIGNAL_CREATED','','original',1)")
        return db

    def test_migrate_current_trade_two_without_losing_history(self):
        db = self.old_database()
        migrate(db)
        self.assertEqual(db.execute('SELECT version FROM schema_version').fetchone()[0], 2)
        self.assertEqual(next_numbers(db, 'c', 'BUY'), (2, 2))
        self.assertEqual(db.execute('SELECT COUNT(*) FROM events').fetchone()[0], 1)
        self.assertEqual(db.execute('SELECT COUNT(*) FROM positions').fetchone()[0], 2)
        signal(db, 'c', 'BUY', 2, 2)
        self.assertEqual(db.execute('PRAGMA foreign_key_check').fetchall(), [])
        db.close()

    def test_failed_migration_rolls_back_schema_and_original_rows(self):
        db = self.old_database()
        with self.assertRaises(RuntimeError):
            migrate(db, fault=True)
        self.assertEqual(db.execute('SELECT version FROM schema_version').fetchone()[0], 1)
        self.assertEqual(db.execute('SELECT COUNT(*) FROM positions').fetchone()[0], 2)
        self.assertEqual(db.execute("SELECT COUNT(*) FROM sqlite_master WHERE name='positions_v1'").fetchone()[0], 0)
        db.close()

    def test_lease_lost_owner_cannot_reacquire_without_restart(self):
        self.db.execute("INSERT INTO leases VALUES('c','first',130)")
        self.db.execute("UPDATE leases SET owner='second',expires=161 WHERE expires<=131")
        self.db.execute("UPDATE leases SET expires=200 WHERE context='c' AND owner='first' AND expires>170")
        self.assertEqual(self.db.execute('SELECT owner,expires FROM leases').fetchone(), ('second', 161))

    def test_test_only_routing_editable_fields_and_distribution(self):
        main = (ROOT / 'TradeAssistantV126_SQLite.mq5').read_text()
        discord = (V / 'discord_4.23.mqh').read_text()
        self.assertNotIn('GlobalVariable', main)
        self.assertNotIn('#resource', main)
        self.assertNotIn('BuyStop(', main)
        self.assertNotIn('SellStop(', main)
        self.assertIn('cfg.TestWebhook()', discord)
        self.assertNotIn('cfg.SystemWebhook()', discord)
        self.assertNotIn('cfg.RouteWebhook(', discord)
        self.assertIn('TradeInfo tradeInfo[];', discord)
        self.assertIn('ReadPositiveNumber(TRNB,p.tradenummer)', main)
        self.assertIn('ReadPositiveNumber(POSNB,p.position)', main)
        self.assertNotIn('OBJPROP_READONLY,true', main)
        self.assertIn('g_numbers_editing', main)
        self.assertNotIn('ArrayCopy(', main)
        self.assertIn('dst[i]=src[i]', main)
        self.assertIn('allowed_mentions', discord)
        for path in [ROOT / 'TradeAssistantV126_SQLite.mq5', *V.glob('*.mqh'), *V.glob('tests/*.mq5')]:
            source = path.read_text()
            self.assertFalse(re.search(r'https?://discord(?:app)?\.com/api/webhooks/\d', source), path)
            for relative in re.findall(r'^#include "([^"]+)"', source, re.M):
                self.assertTrue((path.parent / relative).exists(), (path, relative))
            clean = re.sub(r'//[^\n]*|/\*.*?\*/|"(?:\\.|[^"\\])*"', '', source, flags=re.S)
            stack = []
            for c in clean:
                if c in '{(': stack.append(c)
                if c in '})':
                    self.assertTrue(stack, path)
                    self.assertEqual(stack.pop(), '{' if c == '}' else '(', path)
            self.assertFalse(stack, path)

    def test_shipped_mql_sql_and_migrations_match(self):
        actual = (V / 'SQLiteSchema.mqh').read_text()
        for name, expected in [('DH126Schema', SCHEMA), ('DH126MigrateBegin', BEGIN_MIGRATION), ('DH126MigrateFinish', END_MIGRATION)]:
            segment = actual.split('string ' + name + '()', 1)[1].split('; }', 1)[0]
            embedded = ''.join(json.loads(line) for line in segment.splitlines() if line.startswith('"'))
            self.assertEqual(embedded, expected)


if __name__ == '__main__':
    unittest.main()
