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

    export COMBINED_TEMP=/tmp/tmp.csv
    rm -f ${COMBINED_TEMP}
    # tweak the micro on the timestamp which always ends in 000 in original data to "multiply" the data
    for i in $(seq -f "%03g" 0 100); do

        echo "adding data with us timestamp ${i}"

        # head -n 10  $1  | sed "s/000\"/${i}\"/" >>  ${COMBINED_TEMP}
        cat $1  | sed "s/000\"/${i}\"/" >>  ${COMBINED_TEMP}

    done

    #docker run --rm -it -v $1/:/$1 --net=host bitnami/clickhouse:24 clickhouse-client --host=${CH_HOST} --port=${CH_PORT} -q "insert into ${FQ_TAB} FROM INFILE '$1' FORMAT CSV"
    docker run --rm -it -v ${COMBINED_TEMP}:/${COMBINED_TEMP} --net=host bitnami/clickhouse:24 clickhouse-client --host=${CH_HOST} --port=${CH_PORT} -q "insert into ${FQ_TAB} FROM INFILE '${COMBINED_TEMP}' FORMAT CSV"
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

done


echo
echo " === DONE ===" 
echo
