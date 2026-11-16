# Đấu nối theo màu module

Guide index.html#references dùng một sơ đồ đơn giản với 5 module. File và khóa không tách thành các ô riêng; xem bằng hover module.

| Màu | Module | Host |
|---|---|---|
| Tím | PostgreSQL x3 | miqa-cdc-1 / 192.168.139.162 |
| Xanh lá | Kafka Connect: 3 source + 1 sink | miqa-cdc-3 / 192.168.139.163 |
| Cam | Redpanda | miqa-cdc-3 / 192.168.139.163 |
| Vàng | ClickHouse | miqa-cdc-2 / 192.168.139.164 |
| Cyan | Redpanda Console | miqa-cdc-3 / 192.168.139.163:8080 |

Màu phân biệt module, không phân loại đường nối. Các đường có nhãn method/protocol và port. Mũi tên luôn từ bên chủ động mở kết nối tới bên nhận; không biểu diễn chiều dữ liệu trả về. ClickHouse dùng màu vàng với icon database; không hàm ý triển khai trên cloud.

```text
Connect --pgoutput:15432/25432/35432--> PostgreSQL x3
Connect --Produce:9092--> Redpanda
Connect --Fetch:9092--> Redpanda
Connect --HTTP:18123 -> 8123--> ClickHouse
Console --Kafka:9092 / Admin:9644--> Redpanda
Console --REST:8083--> Connect
```

## File/khóa khi hover

### pg

```text
POSTGRESQL x3 | miqa-cdc-1 | 192.168.139.162
compose/postgres/compose.yaml
  pg-micall:15432 / pg-misales:25432 / pg-miqa:35432 -> 5432
postgres/postgresql.conf
  wal_level=logical; port=5432
postgres/init.sql
  public.outbox_event + CDC role + publication
```

### connect

```text
KAFKA CONNECT | miqa-cdc-3 | 192.168.139.163
Một worker: 3 source + 1 sink.
compose/redpanda/compose.yaml
  connect.environment.BOOTSTRAP_SERVERS=redpanda:9092
connect/connectors/source-micall.json
connect/connectors/source-misales.json
connect/connectors/source-miqa.json
  database.hostname=192.168.139.162
  database.port=15432 / 25432 / 35432
  plugin.name=pgoutput; slot.name; topic.prefix
connect/connectors/ch-sink-all.json
  hostname=192.168.139.164; port=18123
  database=cdc; topic2TableMap -> outbox_event
JSON đăng ký qua REST PUT /connectors/<name>/config :8083 hoặc Console GUI.
```

### broker

```text
REDPANDA | miqa-cdc-3 | 192.168.139.163
redpanda/redpanda.yaml
  kafka_api: 0.0.0.0:9092
  advertised_kafka_api: redpanda:9092
  admin: 0.0.0.0:9644
compose/redpanda/compose.yaml
  --config /redpanda/redpanda.yaml
Ba topic: micall / misales / miqa .public.outbox_event
```

### ch

```text
CLICKHOUSE | miqa-cdc-2 | 192.168.139.164
compose/clickhouse/compose.yaml
  HTTP 18123 -> 8123; SQL 19000 -> 9000
clickhouse/init.sql
  cdc.outbox_event / ReplacingMergeTree / ORDER BY event_id
  SQL init khi data mới. Đọc gộp trùng bằng SELECT ... FINAL.
```

### console

```text
CONSOLE | miqa-cdc-3 | 192.168.139.163:8080
compose/redpanda/compose.yaml
  console.environment.CONFIG_FILEPATH=/console/config.yaml
  console.volumes: ../../console:/console:ro
console/config.yaml
  kafka.brokers -> redpanda:9092
  redpanda.adminApi.urls -> http://redpanda:9644
  kafkaConnect.clusters[].url -> http://connect:8083
```

## Lệnh áp dụng

```bash
cd /opt/setup-v1/compose/redpanda # Trên VM2, khi cập nhật cấu hình vận hành.
docker compose up -d --wait # Áp dụng Compose mới.
docker compose restart console # Đọc lại YAML Console khi sửa native config.
# Đăng ký lại JSON bằng REST hoặc GUI khi thay cấu hình connector.
curl -fsS -X PUT -H 'Content-Type: application/json' --data-binary @../../connect/connectors/ch-sink-all.json http://192.168.139.163:8083/connectors/ch-sink-all/config
```

Chỉ sửa tài liệu trong lượt này, không đổi runtime. Source đối chiếu Compose/native config/JSON hiện tại; source không có Git nên không gán commit. Native artifact đã qua các gate tự động và xem ảnh dark desktop 1440x900: nhãn đọc được, không có đường cắt nhau. Tooltip là phần guide gắn khi iframe load; chưa xác minh thao tác hover trực tiếp trong Codex vì Computer Use bị tắt. Viewer controls dùng tiếng Anh.
