#!/bin/bash

# Server details
export CH_HOST=0.0.0.0
export CH_PORT=9000
echo
echo "using CH HOST     : ${CH_HOST}"
echo "using CH PORT     : ${CH_PORT}"



# DB details
export DATA_DIR="/data/capture.copy"
export DB_NAME="Saxo"
export ASSET_CLASS="FxSpot"
export FQ_TAB="${DB_NAME}.${ASSET_CLASS}"

echo
echo "using DATA DIR    : ${DATA_DIR}"
echo "using DB NAME     : ${DB_NAME}"
echo "using ASSET CLASS : ${ASSET_CLASS}"
echo "using FQ TABLE    : ${FQ_TAB}"

echo
echo " === START ===" 


run_sql () {
    if [ $# -ne 1 ]; then
       echo "ERROR: expecting exactly 1 argument"
       return
    fi
    echo "executing SQL: $1"
    docker run --rm -it --net=host bitnami/clickhouse:24 clickhouse-client --host=${CH_HOST} --port=${CH_PORT} -q "$1"
}

run_insert_data_sql () {
    if [ $# -ne 1 ]; then
       echo "ERROR: expecting exactly 1 argument"
       return
    fi
    echo "Inserting data for : $1"
    #docker run --rm -it -v $1/:/$1 --net=host bitnami/clickhouse:24 clickhouse-client --host=${CH_HOST} --port=${CH_PORT} -q "insert into ${FQ_TAB} FROM INFILE '$1' FORMAT CSV"

    for i in 0 1 2 3 4 5 6 7 8 9; do
        echo $i
        head -n 1000  /tmp/AUDJPY.csv  | sed "s/000\"/00${i}\"/" > 
    done
}

run_sql "CREATE DATABASE IF NOT EXISTS ${DB_NAME}"
run_sql "DROP TABLE IF EXISTS ${FQ_TAB}"
run_sql "CREATE TABLE ${FQ_TAB} (d date, t DateTime64(6), pair char(6), bid Float64, bsz Float64, ask Float64, asz Float64) ENGINE = MergeTree() ORDER BY (d, t, pair)"


for p in `ls ${DATA_DIR}/${ASSET_CLASS}`; do
    echo === ${p} ===
    PAIR_DIR="${DATA_DIR}/${ASSET_CLASS}/${p}"
    TMP_FILE="/tmp/$p.csv"

    echo "    pair dir: ${PAIR_DIR}"
    echo "    tmp file: ${TMP_FILE}"
    
    pushd $PAIR_DIR
    cat $p-2*.csv | gawk -F\, -v PAIR=$p -v q=\" '{print q substr($1,0,10) q "," q $1 q "," q PAIR q "," $2 "," $3 "," $4 "," $5}' | sed "s/Z\"\,/\"\,/" > ${TMP_FILE}

    run_insert_data_sql ${TMP_FILE}

    # cat ${TMP_FILE} | sed "s/000\"/001\"/" > ${TMP_FILE}.1
    # docker run --rm -it -v /tmp/$p.csv/:/data/$p.csv --net=host bitnami/clickhouse:24 clickhouse-client --host=${CH_HOST} --port=${CH_PORT} -q "insert into ${FQ_TAB} FROM INFILE '/data/$p.csv' FORMAT CSV"

    break
done


# docker run --rm -it --net=host bitnami/clickhouse:24 clickhouse-client --host=${CH_HOST} --port=${CH_PORT} -q "CREATE DATABASE IF NOT EXISTS ${DB_NAME}"
# docker run --rm -it --net=host bitnami/clickhouse:24 clickhouse-client --host=${CH_HOST} --port=${CH_PORT} -q "DROP TABLE IF EXISTS ${FQ_TAB}"
# docker run --rm -it --net=host bitnami/clickhouse:24 clickhouse-client --host=${CH_HOST} --port=${CH_PORT} -q "CREATE TABLE ${FQ_TAB} (d date, t DateTime64(6), pair char(6), bid Float64, bsz Float64, ask Float64, asz Float64) ENGINE = MergeTree() ORDER BY (d, t, pair)"

# for p in `ls ${DATA_DIR}/${ASSET_CLASS}`; do
#     echo === ${p} ===
#     PAIR_DIR="${DATA_DIR}/${ASSET_CLASS}/${p}"
#     TMP_FILE="/tmp/$p.csv"

#     echo "    pair dir: ${PAIR_DIR}, tmp file: ${TMP_FILE}"
    
#     pushd $PAIR_DIR
#     cat $p-2*.csv | gawk -F\, -v PAIR=$p -v q=\" '{print q substr($1,0,10) q "," q $1 q "," q PAIR q "," $2 "," $3 "," $4 "," $5}' | sed "s/Z\"\,/\"\,/" > ${TMP_FILE}
#     docker run --rm -it -v /tmp/$p.csv/:/data/$p.csv --net=host bitnami/clickhouse:24 clickhouse-client --host=${CH_HOST} --port=${CH_PORT} -q "insert into ${FQ_TAB} FROM INFILE '/data/$p.csv' FORMAT CSV"
# done

echo
echo " === DONE ===" 
echo
