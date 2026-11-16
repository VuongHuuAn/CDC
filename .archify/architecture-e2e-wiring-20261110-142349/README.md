# Sơ đồ tích hợp E2E và khai báo đấu nối

Mục tiêu: nhìn một hình để hiểu dữ liệu đi đâu và muốn đổi kết nối thì sửa file nào. Guide: index.html#references.

## Cách đọc

- Nét liền xanh: dữ liệu, theo số 1 → 6.
- Nét đứt tím: khai báo/khởi tạo module. File không tự mở kết nối.
- Nét liền xám: Console quản trị broker và worker.
- Rê chuột hoặc focus vào ô trong guide để xem đường dẫn file, khóa và endpoint; Escape để đóng tooltip.
- Không có bước đọc .env trên sơ đồ. Các ô là vai trò; PostgreSQL/source gộp ba nguồn cho dễ đọc.

```text
INSERT public.outbox_event
  → PostgreSQL ghi WAL
  → source x3 đọc bằng pgoutput :15432/25432/35432
  → Produce Kafka :9092 → Redpanda / ba topic outbox
  → sink x1 Fetch Kafka :9092
  → HTTP 192.168.139.164:18123 → ClickHouse cdc.outbox_event
  → SELECT ... FINAL qua SQL :9000 trong container
```

## VM và module

| VM | Hostname | IP | Module |
|---|---|---|---|
| VM1 | miqa-cdc-1 | 192.168.139.162 | PostgreSQL micall/misales/miqa, host port 15432/25432/35432 |
| VM2 | miqa-cdc-3 | 192.168.139.163 | Redpanda, một worker Connect (source x3 + sink x1), Console |
| VM3 | miqa-cdc-2 | 192.168.139.164 | ClickHouse, HTTP host 18123 → 8123; SQL host 19000 → 9000 |

## File và khóa khai báo

### pg_config

```text
compose/postgres/compose.yaml
  command: config_file=/postgres/postgresql.conf
  volumes: SQL init -> /docker-entrypoint-initdb.d/10-outbox.sql
postgres/postgresql.conf
  wal_level=logical; port=5432
postgres/init.sql
  outbox_event + CDC role + publication
```

### pg

```text
compose/postgres/compose.yaml
  pg-micall:15432 / pg-misales:25432 / pg-miqa:35432 -> 5432
postgres/init.sql
  INSERT public.outbox_event -> WAL
```

### source_config

```text
connect/connectors/source-micall.json
connect/connectors/source-misales.json
connect/connectors/source-miqa.json
  database.hostname=192.168.139.162
  database.port=15432 / 25432 / 35432
  plugin.name=pgoutput; slot.name; topic.prefix
  PUT /connectors/<name>/config :8083 hoặc Console GUI
```

### source

```text
compose/redpanda/compose.yaml
  connect.environment.BOOTSTRAP_SERVERS=redpanda:9092
connect/connectors/source-*.json
  table.include.list=public.outbox_event
  transforms.unwrap.type=ExtractNewRecordState
Ba source chạy cùng worker với sink, không phải ba container riêng.
```

### broker_config

```text
redpanda/redpanda.yaml
  kafka_api: 0.0.0.0:9092
  advertised_kafka_api: redpanda:9092
  admin: 0.0.0.0:9644
compose/redpanda/compose.yaml
  rpk redpanda start --config /redpanda/redpanda.yaml
```

### broker

```text
redpanda/redpanda.yaml
  Kafka API :9092
Topics: micall.public.outbox_event
        misales.public.outbox_event
        miqa.public.outbox_event
```

### sink_config

```text
connect/connectors/ch-sink-all.json
  hostname=192.168.139.164; port=18123
  database=cdc; topic2TableMap -> outbox_event
  topics: ba topic outbox
  exactlyOnce=false
  PUT /connectors/ch-sink-all/config :8083 hoặc Console GUI
```

### sink

```text
compose/redpanda/compose.yaml
  connect.environment.BOOTSTRAP_SERVERS=redpanda:9092
connect/connectors/ch-sink-all.json
  connector.class=ClickHouseSinkConnector
Một sink chạy cùng worker với ba source.
```

### console_config

```text
compose/redpanda/compose.yaml
  console.environment.CONFIG_FILEPATH=/console/config.yaml
  console.volumes: ../../console:/console:ro
console/config.yaml
  kafka.brokers -> redpanda:9092
  redpanda.adminApi.urls -> http://redpanda:9644
  kafkaConnect.clusters[].url -> http://connect:8083
```

### console

```text
console/config.yaml
  server.listenPort=8080
  Kafka :9092 / Admin HTTP :9644 / Connect REST :8083
compose/redpanda/compose.yaml
  console.ports: 192.168.139.163:8080 -> 8080
```

### ch_config

```text
compose/clickhouse/compose.yaml
  clickhouse.volumes: init.sql -> /docker-entrypoint-initdb.d/10-outbox.sql
clickhouse/init.sql
  CREATE DATABASE cdc
  CREATE TABLE cdc.outbox_event
SQL init chỉ tự chạy khi data mới.
```

### ch

```text
clickhouse/init.sql
  cdc.outbox_event / ReplacingMergeTree
  ORDER BY event_id
compose/clickhouse/compose.yaml
  192.168.139.164:18123 -> 8123 (HTTP)
  192.168.139.164:19000 -> 9000 (SQL)
```

### read

```text
Lệnh SELECT ... FROM cdc.outbox_event FINAL
  FINAL gộp bản trùng theo event_id khi đọc.
compose/clickhouse/compose.yaml
  client minh họa chạy trong container, SQL :9000.
```

## Áp dụng khi thay kết nối

```bash
# VM2; source đã đồng bộ đúng thư mục.
cd /opt/setup-v1/compose/redpanda
docker compose up -d --wait # Áp dụng thay đổi Compose.
docker compose restart console # Đọc lại console/config.yaml sau khi sửa YAML native.
# JSON: dùng REST PUT hoặc Update Config trên Console, không chỉ copy file.
curl -fsS -X PUT -H 'Content-Type: application/json' --data-binary @../../connect/connectors/source-micall.json http://192.168.139.163:8083/connectors/source-micall/config
```

## Phạm vi kiểm tra

Đã đối chiếu Compose, console/config.yaml, redpanda/redpanda.yaml và connector JSON hiện tại. Hostname theo đối chiếu SSH trong cùng phiên. Source Windows không có Git nên không gán provenance commit. Native artifact đã qua validate/deliver/check/browser-check; đã xem ảnh desktop dark: nhãn không bị che và các đường không cắt nhau sau sửa bố trí nhánh Console. Tooltip là phần bổ sung của guide khi iframe load, không sửa artifact đã xác minh. Chưa thao tác hover trực tiếp trong tab Codex do Computer Use đang bị tắt. Nút công cụ Viewer dùng tiếng Anh. Chỉ cập nhật tài liệu, không đổi runtime.

## Lệnh tạo và chụp sơ đồ

```bash
node skill/bin/archify.mjs finalize architecture e2e-wiring.json .archify/architecture-e2e-wiring-20261110-142349/e2e-wiring.html --out-dir .archify/architecture-e2e-wiring-20261110-142349/review-2 --quality showcase --json
node skill/bin/archify.mjs visual-check .archify/architecture-e2e-wiring-20261110-142349/e2e-wiring.html --out-dir .archify/architecture-e2e-wiring-20261110-142349/visual-check --summary --require-provenance
```
