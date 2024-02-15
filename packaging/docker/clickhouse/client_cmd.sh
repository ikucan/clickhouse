
docker run --rm -it --net=host bitnami/clickhouse:23 clickhouse-client

docker run --rm -it --net=host bitnami/clickhouse:23 clickhouse-client --port=9000

docker run --rm -it -v /data/capture.copy/FxSpot/:/data/ --net=host bitnami/clickhouse:23 clickhouse-client --host=192.168.0.201 --port=9000i
