INSERT INTO trades(context,trade_no,direction,status) SELECT context,trade_no,direction,CASE WHEN status IN ('PENDING','OPEN') THEN 'ACTIVE' ELSE 'CLOSED' END FROM positions_v1;
INSERT INTO positions SELECT context,trade_no,pos_no,direction,status,entry,sl,lots,sabio_entry,sabio_sl FROM positions_v1;
DROP TABLE positions_v1;
