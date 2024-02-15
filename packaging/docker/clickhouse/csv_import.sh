#!/bin/bash

export DATA_DIR="/data/capture.copy"
export DB_NAME="Saxo"
export ASSET_CLASS="FxSpot"
export FQ_TAB="${DB_NAME}.${ASSET_CLASS}"

#export CH_HOST=192.168.0.201
export CH_HOST=0.0.0.0

export CH_PORT=9000

docker run --rm -it --net=host bitnami/clickhouse:23 clickhouse-client --host=${CH_HOST} --port=${CH_PORT} -q "CREATE DATABASE IF NOT EXISTS ${DB_NAME}"
docker run --rm -it --net=host bitnami/clickhouse:23 clickhouse-client --host=${CH_HOST} --port=${CH_PORT} -q "DROP TABLE IF EXISTS ${FQ_TAB}"
docker run --rm -it --net=host bitnami/clickhouse:23 clickhouse-client --host=${CH_HOST} --port=${CH_PORT} -q "CREATE TABLE ${FQ_TAB} (d date, t DateTime64(6), pair char(6), bid Float64, bsz Float64, ask Float64, asz Float64) ENGINE = MergeTree() ORDER BY (d, t, pair)"

for p in `ls ${DATA_DIR}/${ASSET_CLASS}`; do
    echo === ${p} ===
    PAIR_DIR="${DATA_DIR}/${ASSET_CLASS}/${p}"
    TMP_FILE="/tmp/$p.csv"

    echo "    pair dir: ${PAIR_DIR}, tmp file: ${TMP_FILE}"
    
    pushd $PAIR_DIR
    cat $p-2*.csv | gawk -F\, -v PAIR=$p -v q=\" '{print q substr($1,0,10) q "," q $1 q "," q PAIR q "," $2 "," $3 "," $4 "," $5}' | sed "s/Z\"\,/\"\,/" > ${TMP_FILE}
    docker run --rm -it -v /tmp/$p.csv/:/data/$p.csv --net=host bitnami/clickhouse:23 clickhouse-client --host=${CH_HOST} --port=${CH_PORT} -q "insert into ${FQ_TAB} FROM INFILE '/data/$p.csv' FORMAT CSV"
done

echo "" 
echo " === DONE ===" 