--DROP DATABASE IF EXISTS Fx;
CREATE DATABASE IF NOT EXISTS Saxo;

DROP TABLE IF EXISTS Saxo.FxQuotes;
CREATE TABLE Saxo.FxQuotes (d date, t DateTime64(6), pair char(6), bid Float64, bsz Float64, ask Float64, asz Float64)
    ENGINE = MergeTree()
    ORDER BY (d, t, pair);

-- insert into Saxo.FxQuotes values ('2022-12-31', timestamp('2022-12-31T12:12:23.001122Z'), 'GBPUSD', 1, 1, 2, 2)

-- insert into Saxo.FxQuotes FROM INFILE '/data/xo.csv' FORMAT CSV -- works!!