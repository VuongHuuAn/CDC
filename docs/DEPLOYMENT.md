# Triển khai setup-v1 — Lệnh hoặc Console GUI

## Chuẩn bị

Các file cấu hình được mở trực tiếp từ cây file trong index.html; code có highlight và giải thích từng dòng. .env chỉ chứa user/password. Mọi mount dùng bind, data phát sinh trên từng VM ở /opt/setup-v1/data.

## Khởi động

### .162, /opt/setup-v1/compose/postgres

```bash
cd /opt/setup-v1/compose/postgres
docker compose up -d --wait # Bật đúng nhóm.
```

### .164, /opt/setup-v1/compose/clickhouse

```bash
cd /opt/setup-v1/compose/clickhouse
docker compose up -d --wait # Bật đúng nhóm.
```

### .163, /opt/setup-v1/compose/redpanda

```bash
cd /opt/setup-v1/compose/redpanda
docker compose up -d --wait # Bật đúng nhóm.
```

## Cách A — Lệnh trên VM2

Thư mục: `/opt/setup-v1/compose/redpanda`.

```bash
docker compose exec -T redpanda rpk topic create \
  micall.public.outbox_event misales.public.outbox_event miqa.public.outbox_event \
  --partitions 1 --replicas 1 --if-not-exists \
  --config /redpanda/redpanda.yaml # Mỗi topic một partition, một replica.

curl -fsS -X PUT -H 'Content-Type: application/json' \
  --data-binary @../../connect/connectors/source-micall.json \
  http://192.168.139.163:8083/connectors/source-micall/config

curl -fsS -X PUT -H 'Content-Type: application/json' \
  --data-binary @../../connect/connectors/source-misales.json \
  http://192.168.139.163:8083/connectors/source-misales/config

curl -fsS -X PUT -H 'Content-Type: application/json' \
  --data-binary @../../connect/connectors/source-miqa.json \
  http://192.168.139.163:8083/connectors/source-miqa/config

curl -fsS -X PUT -H 'Content-Type: application/json' \
  --data-binary @../../connect/connectors/ch-sink-all.json \
  http://192.168.139.163:8083/connectors/ch-sink-all/config
```

## Cách B — Console GUI

1. Topics → Create topic: tên, Partitions=1, Replication factor=1, Cleanup policy=delete → Create. Lặp ba topic.
2. Connect → Kafka Connect → Clusters → setupv1-connect → Create connector.
3. Source: Import from PostgreSQL (Debezium) → JSON → bấm vùng code, Ctrl+A, dán toàn bộ file source → Next → Create. Lặp ba nguồn.
4. Sink: Export to ClickHouseSinkConnector → JSON → dán toàn bộ ch-sink-all.json → Next → Create.
5. Overview: Healthy, task Running. Sửa config: Configuration → JSON → Update Config. Giữ nguyên ${env:...}.

## Demo

VM1, /opt/setup-v1/compose/postgres:

```bash
docker compose exec -T pg-micall bash -c 'psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < ../../demo/insert-micall.sql

docker compose exec -T pg-misales bash -c 'psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < ../../demo/insert-misales.sql

docker compose exec -T pg-miqa bash -c 'psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < ../../demo/insert-miqa.sql
```

Console: Topics → topic nguồn → Messages → Repeat current search → Expand row → Value. Ctrl+End trong JSON để xem payload.

VM3, /opt/setup-v1/compose/clickhouse:

```bash
docker compose exec -T clickhouse bash -c 'clickhouse-client --user "$CLICKHOUSE_USER" --password "$CLICKHOUSE_PASSWORD" --multiquery' < ../../demo/select.sql
```

Kết quả: demo-micall-001, demo-misales-001, demo-miqa-001 có đúng source và scenario=console-demo.

## Hằng ngày

Đứng trong `/opt/setup-v1/compose/postgres`, `compose/redpanda` hoặc `compose/clickhouse` trên VM tương ứng:

```bash
docker compose stop # Giữ data trên host.
docker compose start # Chạy lại nhóm.
docker compose restart # Khởi động lại.
docker compose logs -f # Theo dõi log; Ctrl+C để thoát.
```

## Luồng

```text
PG .162:15432/25432/35432 --pgoutput--> source .163
source --Kafka:9092--> Redpanda --Kafka:9092--> sink .163
sink --HTTP .164:18123--> ClickHouse cdc.outbox_event
```

Đọc event cuối trên VM2, tại `/opt/setup-v1/compose/redpanda`:

```bash
docker compose exec -T redpanda rpk topic consume micall.public.outbox_event --offset=-1 --num=1 --config /redpanda/redpanda.yaml # Đọc event cuối; đổi tên topic để xem nguồn khác.
```

Connect dùng entrypoint mặc định và user: "0:0". Worker chạy bằng root, không cần lệnh gán owner Kafka. Healthcheck giữ nguyên để up --wait chờ REST sẵn sàng.

## Áp dụng thay đổi user Connect

Trên VM2 .163:

```bash
cd /opt/setup-v1/compose/redpanda # Thư mục bộ broker/worker/Console.
docker compose up -d --wait # Tạo lại Connect theo cấu hình mới và chờ sẵn sàng.
```

Không dùng restart để áp dụng thay đổi Compose; up tạo lại container khi cần. Đã xác minh user root, healthcheck healthy, bốn connector/task RUNNING và ba event mới tới ClickHouse.
