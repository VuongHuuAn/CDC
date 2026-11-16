# Quan hệ tham chiếu file và kết nối module

Mục đích: xác định file cần sửa khi thay đổi địa chỉ kết nối. File chỉ khai báo; tiến trình Console hoặc Connect đọc cấu hình và mở kết nối.

```text
Compose --bind + CONFIG_FILEPATH--> Console đọc console/config.yaml
Console --Kafka:9092--> Redpanda
Console --HTTP Admin:9644--> Redpanda
Console --HTTP REST:8083--> Connect
.env --Compose environment--> Connect EnvVarConfigProvider
JSON --PUT /connectors/<name>/config:8083 hoặc GUI--> Connect
Connect --Kafka:9092--> Redpanda
Source x3 --pgoutput:15432/25432/35432--> PostgreSQL VM1
Sink x1 --HTTP:18123--> ClickHouse VM3
```

| File | Khóa | Endpoint / tham chiếu | Vai trò |
|---|---|---|---|
| compose/redpanda/compose.yaml | console.volumes + CONFIG_FILEPATH | ../../console → /console:ro; Console đọc /console/config.yaml | Chọn file cấu hình, chưa khai báo các đích Kafka/REST. |
| console/config.yaml | server.listenPort | 8080 trong container → 192.168.139.163:8080 trên VM | Cổng GUI; đây là cổng Console lắng nghe. |
| console/config.yaml | kafka.brokers | redpanda:9092 | Console → Kafka API để đọc topic/message. |
| console/config.yaml | redpanda.adminApi.urls | http://redpanda:9644 | Console → Redpanda Admin API. |
| console/config.yaml | kafkaConnect.clusters[].url | http://connect:8083 | Console → Connect REST để quản lý connector. |
| compose/redpanda/compose.yaml | connect.environment.BOOTSTRAP_SERVERS | redpanda:9092 | Worker Connect → broker. |
| compose/redpanda/.env | *_DEBEZIUM_USER/PASSWORD; CLICKHOUSE_USER/PASSWORD | Compose environment → Connect EnvVarConfigProvider | JSON dùng ${env:...}; chỉ worker giải tham chiếu, không đưa password vào guide. |
| connect/connectors/source-micall.json | database.hostname + database.port + database.dbname | 192.168.139.162:15432 / micall | Source micall → PostgreSQL; pgoutput. |
| connect/connectors/source-misales.json | database.hostname + database.port + database.dbname | 192.168.139.162:25432 / misales | Source misales → PostgreSQL; pgoutput. |
| connect/connectors/source-miqa.json | database.hostname + database.port + database.dbname | 192.168.139.162:35432 / miqa | Source miqa → PostgreSQL; pgoutput. |
| connect/connectors/ch-sink-all.json | hostname + port + database + topic2TableMap | 192.168.139.164:18123 / cdc.outbox_event | Sink → ClickHouse HTTP; ba topic cùng một bảng. |
| redpanda/redpanda.yaml | kafka_api + advertised_kafka_api + admin | 0.0.0.0:9092; redpanda:9092; 0.0.0.0:9644 | Broker lắng nghe và công bố DNS nội bộ; không dùng IP VM cho Kafka nội bộ. |
| postgres/postgresql.conf | listen_addresses + port | *:5432 trong từng container PG | Compose VM1 publish 15432/25432/35432 để source truy cập từ VM2. |
| clickhouse/init.sql | CREATE DATABASE + CREATE TABLE | cdc.outbox_event | Tạo bảng đích trên data mới; không khai báo kết nối ngược về Connect. |

VM1 miqa-cdc-1 / 192.168.139.162; VM2 miqa-cdc-3 / 192.168.139.163; VM3 miqa-cdc-2 / 192.168.139.164. Redpanda và Connect dùng DNS Docker trong VM2; liên VM dùng IP/host port. clusters[].name là nhãn hiển thị, không bắt buộc trùng GROUP_ID.

## Thao tác khi đổi kết nối

1. Sửa file và khóa tương ứng theo bảng, đồng bộ lên VM sở hữu module.
2. Sửa console/config.yaml: tại /opt/setup-v1/compose/redpanda chạy docker compose restart console để đọc lại YAML.
3. Sửa environment/mount/port trong Compose hoặc .env: tại cùng thư mục chạy docker compose up -d --wait.
4. Sửa JSON: gửi lại bằng PUT /connectors/<name>/config hoặc Configuration → JSON → Update Config trong Console. Copy JSON hoặc restart worker đơn thuần không đăng ký cấu hình JSON mới.

```bash
cd /opt/setup-v1/compose/redpanda # Thư mục triển khai VM2.
docker compose restart console # Dùng sau khi sửa YAML native của Console.
docker compose up -d --wait # Dùng sau khi sửa Compose hoặc environment.
# JSON: đường dẫn từ thư mục hiện tại, gửi cấu hình mới tới worker.
curl -fsS -X PUT -H 'Content-Type: application/json' --data-binary @../../connect/connectors/source-micall.json http://192.168.139.163:8083/connectors/source-micall/config
```

Tài liệu/sơ đồ đã đối chiếu source hiện tại. Artifact/browser-check tự động pass, chưa đánh giá ảnh bằng mắt. Đây là cập nhật tài liệu, không thay đổi runtime. Nút công cụ của Viewer dùng tiếng Anh. Source không có Git nên không gán evidence commit.

## Tạo sơ đồ

```bash
node skill/bin/archify.mjs finalize architecture console-references.json .archify/architecture-config-references-20261110-115313/console-references.html --quality showcase --json
node skill/bin/archify.mjs finalize architecture connect-references.json .archify/architecture-config-references-20261110-115313/connect-references.html --quality showcase --json
```
