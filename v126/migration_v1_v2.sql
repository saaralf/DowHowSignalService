DROP INDEX IF EXISTS one_active_direction;
ALTER TABLE positions RENAME TO positions_v1;
DROP TABLE schema_version;
