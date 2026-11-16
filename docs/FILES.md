# File cấu hình và giải thích từng dòng

## .env

| Dòng | Code | Giải thích |
|---|---|---|
| 1 | `# MICALL_PG` | MICALL_PG |
| 2 | `MICALL_PG_USER=micall_pg` | Tên tài khoản cho MICALL_PG. Giá trị hiển thị là mẫu. |
| 3 | `MICALL_PG_PASSWORD=change-me-micall_pg` | Password riêng cho MICALL_PG. Giá trị hiển thị là mẫu. |
| 4 | `` | Ngắt nhóm cấu hình để dễ đọc. |
| 5 | `# MICALL_DEBEZIUM` | MICALL_DEBEZIUM |
| 6 | `MICALL_DEBEZIUM_USER=micall_debezium` | Tên tài khoản cho MICALL_DEBEZIUM. Giá trị hiển thị là mẫu. |
| 7 | `MICALL_DEBEZIUM_PASSWORD=change-me-micall_debezium` | Password riêng cho MICALL_DEBEZIUM. Giá trị hiển thị là mẫu. |
| 8 | `` | Ngắt nhóm cấu hình để dễ đọc. |
| 9 | `# MISALES_PG` | MISALES_PG |
| 10 | `MISALES_PG_USER=misales_pg` | Tên tài khoản cho MISALES_PG. Giá trị hiển thị là mẫu. |
| 11 | `MISALES_PG_PASSWORD=change-me-misales_pg` | Password riêng cho MISALES_PG. Giá trị hiển thị là mẫu. |
| 12 | `` | Ngắt nhóm cấu hình để dễ đọc. |
| 13 | `# MISALES_DEBEZIUM` | MISALES_DEBEZIUM |
| 14 | `MISALES_DEBEZIUM_USER=misales_debezium` | Tên tài khoản cho MISALES_DEBEZIUM. Giá trị hiển thị là mẫu. |
| 15 | `MISALES_DEBEZIUM_PASSWORD=change-me-misales_debezium` | Password riêng cho MISALES_DEBEZIUM. Giá trị hiển thị là mẫu. |
| 16 | `` | Ngắt nhóm cấu hình để dễ đọc. |
| 17 | `# MIQA_PG` | MIQA_PG |
| 18 | `MIQA_PG_USER=miqa_pg` | Tên tài khoản cho MIQA_PG. Giá trị hiển thị là mẫu. |
| 19 | `MIQA_PG_PASSWORD=change-me-miqa_pg` | Password riêng cho MIQA_PG. Giá trị hiển thị là mẫu. |
| 20 | `` | Ngắt nhóm cấu hình để dễ đọc. |
| 21 | `# MIQA_DEBEZIUM` | MIQA_DEBEZIUM |
| 22 | `MIQA_DEBEZIUM_USER=miqa_debezium` | Tên tài khoản cho MIQA_DEBEZIUM. Giá trị hiển thị là mẫu. |
| 23 | `MIQA_DEBEZIUM_PASSWORD=change-me-miqa_debezium` | Password riêng cho MIQA_DEBEZIUM. Giá trị hiển thị là mẫu. |
| 24 | `` | Ngắt nhóm cấu hình để dễ đọc. |
| 25 | `# CLICKHOUSE` | CLICKHOUSE |
| 26 | `CLICKHOUSE_USER=ch_sink` | Tên tài khoản cho CLICKHOUSE. Giá trị hiển thị là mẫu. |
| 27 | `CLICKHOUSE_PASSWORD=change-me-clickhouse` | Password riêng cho CLICKHOUSE. Giá trị hiển thị là mẫu. |

## postgres/postgresql.conf

| Dòng | Code | Giải thích |
|---|---|---|
| 1 | `# Runtime PostgreSQL cho CDC — sửa file rồi restart service pg-*` | Runtime PostgreSQL cho CDC — sửa file rồi restart service pg-* |
| 2 | `` | Ngắt nhóm cấu hình để dễ đọc. |
| 3 | `listen_addresses = '*'  # lắng nghe mọi interface trong container` | PG lắng nghe kết nối từ bên ngoài container. |
| 4 | `port = 5432` | Port HTTP host 18123 của ClickHouse; container vẫn dùng 8123. |
| 5 | `wal_level = logical  # ghi WAL đủ chi tiết cho logical replication / Debezium` | logical cung cấp dữ liệu cho Debezium. |
| 6 | `max_replication_slots = 10  # số slot replication tối đa (mỗi connector thường 1 slot)` | Giới hạn số logical replication slot. |
| 7 | `max_wal_senders = 10  # số process gửi WAL tối đa` | Giới hạn tiến trình gửi WAL. |
| 8 | `max_slot_wal_keep_size = '64MB'  # WAL tối đa giữ cho mỗi slot` | Giới hạn WAL được giữ cho slot; hiện tại 64 MB. |

## postgres/init.sql

| Dòng | Code | Giải thích |
|---|---|---|
| 1 | `\set ON_ERROR_STOP on` | Dừng khi có lỗi SQL để tránh init dở dang. |
| 2 | `\getenv debezium_user DEBEZIUM_USER` | Lấy biến môi trường container vào biến psql, không hardcode credential. |
| 3 | `\getenv debezium_password DEBEZIUM_PASSWORD` | Lấy biến môi trường container vào biến psql, không hardcode credential. |
| 4 | `\getenv source_database POSTGRES_DB` | Lấy biến môi trường container vào biến psql, không hardcode credential. |
| 5 | `` | Ngắt nhóm cấu hình để dễ đọc. |
| 6 | `CREATE TABLE IF NOT EXISTS public.outbox_event (` | Tạo bảng outbox có cùng hợp đồng cột nguồn/đích. |
| 7 | `  event_id text PRIMARY KEY,` | ID event duy nhất xuyên ba nguồn; dùng làm khóa nhận diện. |
| 8 | `  call_id text NOT NULL,` | Mã nghiệp vụ đi cùng event. |
| 9 | `  version bigint NOT NULL,` | Phiên bản dữ liệu kiểu số; chưa dùng làm tham số của ReplacingMergeTree. |
| 10 | `  payload jsonb NOT NULL,` | Nội dung JSON của event; PG jsonb, ClickHouse lưu chuỗi JSON. |
| 11 | `  created_at timestamptz NOT NULL DEFAULT now()   -- thời điểm có múi giờ` | Thời điểm event; PostgreSQL timestamptz, đích DateTime64 UTC. |
| 12 | `);` | Mở/đóng nhóm dữ liệu hoặc câu lệnh. |
| 13 | `` | Ngắt nhóm cấu hình để dễ đọc. |
| 14 | `SELECT format('CREATE ROLE %I', :'debezium_user')  -- tạo role` | Chỉ tạo role/publication khi chưa tồn tại. |
| 15 | `WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = :'debezium_user')` | Chỉ tạo role/publication khi chưa tồn tại. |
| 16 | `\gexec` | Thực thi câu SQL được SELECT sinh ra ở trên. |
| 17 | `ALTER ROLE :"debezium_user" WITH LOGIN REPLICATION PASSWORD :'debezium_password';  -- quyền đọc WAL` | Cho role CDC đăng nhập và logical replication bằng password từ environment. |
| 18 | `GRANT CONNECT ON DATABASE :"source_database" TO :"debezium_user";  -- cho phép vào DB` | Cấp quyền kết nối/đọc đúng database, schema hoặc bảng outbox. |
| 19 | `GRANT USAGE ON SCHEMA public TO :"debezium_user";  -- dùng schema public` | Cấp quyền kết nối/đọc đúng database, schema hoặc bảng outbox. |
| 20 | `GRANT SELECT ON TABLE public.outbox_event TO :"debezium_user";  -- đọc bảng capture` | Cấp quyền kết nối/đọc đúng database, schema hoặc bảng outbox. |
| 21 | `` | Ngắt nhóm cấu hình để dễ đọc. |
| 22 | `SELECT 'CREATE PUBLICATION outbox_publication FOR TABLE public.outbox_event'  -- publication cho plugin pgoutput` | Publication chỉ bao gồm public.outbox_event để pgoutput phát thay đổi. |
| 23 | `WHERE NOT EXISTS (SELECT FROM pg_publication WHERE pubname = 'outbox_publication')` | Chỉ tạo role/publication khi chưa tồn tại. |
| 24 | `\gexec` | Thực thi câu SQL được SELECT sinh ra ở trên. |
| 25 | `ALTER PUBLICATION outbox_publication SET TABLE public.outbox_event;  -- chỉ phát thay đổi outbox` | Publication chỉ bao gồm public.outbox_event để pgoutput phát thay đổi. |

## redpanda/redpanda.yaml

| Dòng | Code | Giải thích |
|---|---|---|
| 1 | `# Broker 1 node — sửa advertised nếu đổi tên service Compose` | Broker 1 node — sửa advertised nếu đổi tên service Compose |
| 2 | `redpanda:` | Nhóm redpanda chứa các thiết lập con bên dưới. |
| 3 | `  data_directory: /var/lib/redpanda/data` | Thư mục dữ liệu Redpanda, được bind ra data/redpanda. |
| 4 | `  node_id: 0  # ID broker (cluster lab một node)` | ID của broker duy nhất trong lab. |
| 5 | `  seed_servers: []  # không cần seed khi chỉ một broker` | Danh sách broker seed; một node không cần seed khác. |
| 6 | `  rpc_server: {address: 0.0.0.0, port: 33145}  # RPC nội bộ Redpanda` | RPC nội bộ giữa các broker; hiện chỉ có một node. |
| 7 | `  advertised_rpc_api: {address: redpanda, port: 33145}  # địa chỉ RPC các node khác thấy` | Địa chỉ RPC được công bố bằng DNS Docker. |
| 8 | `  kafka_api: [{address: 0.0.0.0, port: 9092}]  # Kafka API lắng nghe trong container` | Listener Kafka trong container. |
| 9 | `  advertised_kafka_api: [{address: redpanda, port: 9092}]  # endpoint client/Connect trong mạng Compose` | Địa chỉ Kafka mà client nội bộ VM2 nhận được. |
| 10 | `  admin: [{address: 0.0.0.0, port: 9644}]  # Admin API (health, rpk, Console)` | Listener Admin HTTP để rpk/Console quản lý broker. |
| 11 | `` | Ngắt nhóm cấu hình để dễ đọc. |
| 12 | `rpk:` | Nhóm rpk chứa các thiết lập con bên dưới. |
| 13 | `  kafka_api:` | Listener Kafka trong container. |
| 14 | `    brokers: ["redpanda:9092"]` | Kafka endpoint mà Console/rpk sử dụng trong Docker VM2. |
| 15 | `  admin_api:` | Nhóm admin_api chứa các thiết lập con bên dưới. |
| 16 | `    addresses: ["redpanda:9644"]` | Admin endpoint mà rpk gọi. |

## console/config.yaml

| Dòng | Code | Giải thích |
|---|---|---|
| 1 | `# Redpanda Console — file mount vào container, không chứa secret` | Redpanda Console — file mount vào container, không chứa secret |
| 2 | `` | Ngắt nhóm cấu hình để dễ đọc. |
| 3 | `server:` | Nhóm server chứa các thiết lập con bên dưới. |
| 4 | `  listenPort: 8080  # cổng HTTP GUI (map host 8080 trong compose)` | Cổng HTTP trong container Console. |
| 5 | `` | Ngắt nhóm cấu hình để dễ đọc. |
| 6 | `kafka:` | Nhóm kafka chứa các thiết lập con bên dưới. |
| 7 | `  brokers: ["redpanda:9092"]  # kết nối xem topic / message Kafka API` | Kafka endpoint mà Console/rpk sử dụng trong Docker VM2. |
| 8 | `` | Ngắt nhóm cấu hình để dễ đọc. |
| 9 | `redpanda:` | Nhóm redpanda chứa các thiết lập con bên dưới. |
| 10 | `  adminApi:` | Nhóm adminApi chứa các thiết lập con bên dưới. |
| 11 | `    enabled: true  # bật trang quản trị broker trên GUI` | Bật tính năng tương ứng trong Console. |
| 12 | `    urls: ["http://redpanda:9644"]  # Admin API nội bộ Docker network` | URL nội bộ của Admin API hoặc Connect. |
| 13 | `` | Ngắt nhóm cấu hình để dễ đọc. |
| 14 | `kafkaConnect:` | Nhóm kafkaConnect chứa các thiết lập con bên dưới. |
| 15 | `  enabled: true  # bật trang connector trên GUI` | Bật tính năng tương ứng trong Console. |
| 16 | `  clusters:` | Nhóm clusters chứa các thiết lập con bên dưới. |
| 17 | `    - name: setupv1-connect  # tên hiển thị (khớp GROUP_ID worker)` | Tham số/thành phần tiếp theo của cấu hình đang mở. |
| 18 | `      url: http://connect:8083  # REST Kafka Connect (Debezium + sink)` | Địa chỉ REST của worker để Console quản lý connector. |

## clickhouse/init.sql

| Dòng | Code | Giải thích |
|---|---|---|
| 1 | `-- Khởi tạo đích CDC: clickhouse-client --multiquery sau khi service healthy` | Khởi tạo đích CDC: clickhouse-client --multiquery sau khi service healthy |
| 2 | `CREATE DATABASE IF NOT EXISTS cdc;  -- schema chung cho ba sink connector` | Tạo database cdc nếu chưa có. |
| 3 | `` | Ngắt nhóm cấu hình để dễ đọc. |
| 4 | `CREATE TABLE IF NOT EXISTS cdc.outbox_event (` | Tạo bảng outbox có cùng hợp đồng cột nguồn/đích. |
| 5 | `  event_id String,  -- khóa dedup (ReplacingMergeTree)` | ID event duy nhất xuyên ba nguồn; dùng làm khóa nhận diện. |
| 6 | `  call_id String,  -- cùng ý nghĩa bảng PostgreSQL` | Mã nghiệp vụ đi cùng event. |
| 7 | `  version Int64,  -- bigint từ nguồn` | Phiên bản dữ liệu kiểu số; chưa dùng làm tham số của ReplacingMergeTree. |
| 8 | `  payload String,  -- JSON lưu dạng chuỗi` | Nội dung JSON của event; PG jsonb, ClickHouse lưu chuỗi JSON. |
| 9 | `  created_at DateTime64(6, 'UTC')  -- thời gian nguồn, micro giây UTC` | Thời điểm event; PostgreSQL timestamptz, đích DateTime64 UTC. |
| 10 | `)` | Mở/đóng nhóm dữ liệu hoặc câu lệnh. |
| 11 | `ENGINE = ReplacingMergeTree  -- gộp bản trùng event_id khi merge` | ID event duy nhất xuyên ba nguồn; dùng làm khóa nhận diện. |
| 12 | `ORDER BY event_id;  -- sort key; đọc đã gộp trùng: SELECT ... FINAL` | Khóa gộp/sắp xếp theo event_id. |

## connect/connectors/source-micall.json

| Dòng | Code | Giải thích |
|---|---|---|
| 1 | `{` | Mở/đóng nhóm dữ liệu hoặc câu lệnh. |
| 2 | `  "name": "source-micall",` | Tên connector/project để quản lý và lưu trạng thái độc lập. |
| 3 | `  "connector.class": "io.debezium.connector.postgresql.PostgresConnector",` | Chọn plugin thực thi connector: PostgreSQL source hoặc ClickHouse sink. |
| 4 | `  "database.hostname": "192.168.139.162",` | IP VM1 chứa ba PostgreSQL; không dùng DNS Docker xuyên VM. |
| 5 | `  "database.port": "15432",` | Host port của PostgreSQL tương ứng: 15432, 25432 hoặc 35432. |
| 6 | `  "database.dbname": "micall",` | Database mà source đọc trong PostgreSQL đã chọn. |
| 7 | `  "database.user": "${env:MICALL_DEBEZIUM_USER}",` | Provider env lấy user CDC tương ứng từ environment worker. |
| 8 | `  "database.password": "${env:MICALL_DEBEZIUM_PASSWORD}",` | Provider env lấy password CDC; JSON không chứa password thật. |
| 9 | `  "topic.prefix": "micall",` | Namespace topic theo nguồn; kết hợp với public.outbox_event. |
| 10 | `  "plugin.name": "pgoutput",` | pgoutput đọc logical replication có sẵn trong PostgreSQL. |
| 11 | `  "table.include.list": "public.outbox_event",` | Chỉ capture đúng bảng public.outbox_event. |
| 12 | `  "publication.name": "outbox_publication",` | Publication đã được init.sql tạo trong PG nguồn. |
| 13 | `  "publication.autocreate.mode": "disabled",` | Không tự tạo publication; sử dụng publication được chuẩn bị trước. |
| 14 | `  "slot.name": "micall_outbox_slot",` | Slot riêng của từng source, giữ WAL cần đọc tiếp. |
| 15 | `  "snapshot.mode": "when_needed",` | Snapshot khi cần, rồi chuyển sang đọc WAL; không phải lịch snapshot. |
| 16 | `  "snapshot.select.statement.overrides": "public.outbox_event",` | Bảng được áp dụng SELECT riêng khi snapshot. |
| 17 | `  "snapshot.select.statement.overrides.public.outbox_event": "SELECT * FROM public.outbox_event WHERE created_at >= CURRENT_TIMESTAMP - INTERVAL '3 days'",` | Chỉ snapshot ba ngày gần nhất; không lọc INSERT streaming. |
| 18 | `  "transforms": "unwrap",` | Chuỗi biến đổi message trước khi đưa lên Kafka. |
| 19 | `  "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",` | Bỏ envelope Debezium, giữ các cột outbox cho sink. |
| 20 | `  "key.converter": "org.apache.kafka.connect.json.JsonConverter",` | Định dạng JSON của message key. |
| 21 | `  "value.converter": "org.apache.kafka.connect.json.JsonConverter",` | Định dạng JSON của message value. |
| 22 | `  "key.converter.schemas.enable": "true",` | Key JSON có schema để mô tả kiểu dữ liệu. |
| 23 | `  "value.converter.schemas.enable": "true"` | Value JSON có schema, khớp cách sink giải mã. |
| 24 | `}` | Mở/đóng nhóm dữ liệu hoặc câu lệnh. |

## connect/connectors/source-misales.json

| Dòng | Code | Giải thích |
|---|---|---|
| 1 | `{` | Mở/đóng nhóm dữ liệu hoặc câu lệnh. |
| 2 | `  "name": "source-misales",` | Tên connector/project để quản lý và lưu trạng thái độc lập. |
| 3 | `  "connector.class": "io.debezium.connector.postgresql.PostgresConnector",` | Chọn plugin thực thi connector: PostgreSQL source hoặc ClickHouse sink. |
| 4 | `  "database.hostname": "192.168.139.162",` | IP VM1 chứa ba PostgreSQL; không dùng DNS Docker xuyên VM. |
| 5 | `  "database.port": "25432",` | Host port của PostgreSQL tương ứng: 15432, 25432 hoặc 35432. |
| 6 | `  "database.dbname": "misales",` | Database mà source đọc trong PostgreSQL đã chọn. |
| 7 | `  "database.user": "${env:MISALES_DEBEZIUM_USER}",` | Provider env lấy user CDC tương ứng từ environment worker. |
| 8 | `  "database.password": "${env:MISALES_DEBEZIUM_PASSWORD}",` | Provider env lấy password CDC; JSON không chứa password thật. |
| 9 | `  "topic.prefix": "misales",` | Namespace topic theo nguồn; kết hợp với public.outbox_event. |
| 10 | `  "plugin.name": "pgoutput",` | pgoutput đọc logical replication có sẵn trong PostgreSQL. |
| 11 | `  "table.include.list": "public.outbox_event",` | Chỉ capture đúng bảng public.outbox_event. |
| 12 | `  "publication.name": "outbox_publication",` | Publication đã được init.sql tạo trong PG nguồn. |
| 13 | `  "publication.autocreate.mode": "disabled",` | Không tự tạo publication; sử dụng publication được chuẩn bị trước. |
| 14 | `  "slot.name": "misales_outbox_slot",` | Slot riêng của từng source, giữ WAL cần đọc tiếp. |
| 15 | `  "snapshot.mode": "when_needed",` | Snapshot khi cần, rồi chuyển sang đọc WAL; không phải lịch snapshot. |
| 16 | `  "snapshot.select.statement.overrides": "public.outbox_event",` | Bảng được áp dụng SELECT riêng khi snapshot. |
| 17 | `  "snapshot.select.statement.overrides.public.outbox_event": "SELECT * FROM public.outbox_event WHERE created_at >= CURRENT_TIMESTAMP - INTERVAL '3 days'",` | Chỉ snapshot ba ngày gần nhất; không lọc INSERT streaming. |
| 18 | `  "transforms": "unwrap",` | Chuỗi biến đổi message trước khi đưa lên Kafka. |
| 19 | `  "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",` | Bỏ envelope Debezium, giữ các cột outbox cho sink. |
| 20 | `  "key.converter": "org.apache.kafka.connect.json.JsonConverter",` | Định dạng JSON của message key. |
| 21 | `  "value.converter": "org.apache.kafka.connect.json.JsonConverter",` | Định dạng JSON của message value. |
| 22 | `  "key.converter.schemas.enable": "true",` | Key JSON có schema để mô tả kiểu dữ liệu. |
| 23 | `  "value.converter.schemas.enable": "true"` | Value JSON có schema, khớp cách sink giải mã. |
| 24 | `}` | Mở/đóng nhóm dữ liệu hoặc câu lệnh. |

## connect/connectors/source-miqa.json

| Dòng | Code | Giải thích |
|---|---|---|
| 1 | `{` | Mở/đóng nhóm dữ liệu hoặc câu lệnh. |
| 2 | `  "name": "source-miqa",` | Tên connector/project để quản lý và lưu trạng thái độc lập. |
| 3 | `  "connector.class": "io.debezium.connector.postgresql.PostgresConnector",` | Chọn plugin thực thi connector: PostgreSQL source hoặc ClickHouse sink. |
| 4 | `  "database.hostname": "192.168.139.162",` | IP VM1 chứa ba PostgreSQL; không dùng DNS Docker xuyên VM. |
| 5 | `  "database.port": "35432",` | Host port của PostgreSQL tương ứng: 15432, 25432 hoặc 35432. |
| 6 | `  "database.dbname": "miqa",` | Database mà source đọc trong PostgreSQL đã chọn. |
| 7 | `  "database.user": "${env:MIQA_DEBEZIUM_USER}",` | Provider env lấy user CDC tương ứng từ environment worker. |
| 8 | `  "database.password": "${env:MIQA_DEBEZIUM_PASSWORD}",` | Provider env lấy password CDC; JSON không chứa password thật. |
| 9 | `  "topic.prefix": "miqa",` | Namespace topic theo nguồn; kết hợp với public.outbox_event. |
| 10 | `  "plugin.name": "pgoutput",` | pgoutput đọc logical replication có sẵn trong PostgreSQL. |
| 11 | `  "table.include.list": "public.outbox_event",` | Chỉ capture đúng bảng public.outbox_event. |
| 12 | `  "publication.name": "outbox_publication",` | Publication đã được init.sql tạo trong PG nguồn. |
| 13 | `  "publication.autocreate.mode": "disabled",` | Không tự tạo publication; sử dụng publication được chuẩn bị trước. |
| 14 | `  "slot.name": "miqa_outbox_slot",` | Slot riêng của từng source, giữ WAL cần đọc tiếp. |
| 15 | `  "snapshot.mode": "when_needed",` | Snapshot khi cần, rồi chuyển sang đọc WAL; không phải lịch snapshot. |
| 16 | `  "snapshot.select.statement.overrides": "public.outbox_event",` | Bảng được áp dụng SELECT riêng khi snapshot. |
| 17 | `  "snapshot.select.statement.overrides.public.outbox_event": "SELECT * FROM public.outbox_event WHERE created_at >= CURRENT_TIMESTAMP - INTERVAL '3 days'",` | Chỉ snapshot ba ngày gần nhất; không lọc INSERT streaming. |
| 18 | `  "transforms": "unwrap",` | Chuỗi biến đổi message trước khi đưa lên Kafka. |
| 19 | `  "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",` | Bỏ envelope Debezium, giữ các cột outbox cho sink. |
| 20 | `  "key.converter": "org.apache.kafka.connect.json.JsonConverter",` | Định dạng JSON của message key. |
| 21 | `  "value.converter": "org.apache.kafka.connect.json.JsonConverter",` | Định dạng JSON của message value. |
| 22 | `  "key.converter.schemas.enable": "true",` | Key JSON có schema để mô tả kiểu dữ liệu. |
| 23 | `  "value.converter.schemas.enable": "true"` | Value JSON có schema, khớp cách sink giải mã. |
| 24 | `}` | Mở/đóng nhóm dữ liệu hoặc câu lệnh. |

## connect/connectors/ch-sink-all.json

| Dòng | Code | Giải thích |
|---|---|---|
| 1 | `{` | Mở/đóng nhóm dữ liệu hoặc câu lệnh. |
| 2 | `  "name": "ch-sink-all",` | Tên connector/project để quản lý và lưu trạng thái độc lập. |
| 3 | `  "connector.class": "com.clickhouse.kafka.connect.ClickHouseSinkConnector",` | Chọn plugin thực thi connector: PostgreSQL source hoặc ClickHouse sink. |
| 4 | `  "topics": "micall.public.outbox_event,misales.public.outbox_event,miqa.public.outbox_event",` | Một sink đọc đủ ba topic nguồn. |
| 5 | `  "topic2TableMap": "micall.public.outbox_event=outbox_event,misales.public.outbox_event=outbox_event,miqa.public.outbox_event=outbox_event",` | Ánh xạ từng topic về cùng bảng outbox_event. |
| 6 | `  "hostname": "192.168.139.164",` | IP VM3 ClickHouse, khác VM của Connect. |
| 7 | `  "port": "18123",` | Port HTTP host 18123 của ClickHouse; container vẫn dùng 8123. |
| 8 | `  "database": "cdc",` | Database đích cdc. |
| 9 | `  "username": "${env:CLICKHOUSE_USER}",` | User ClickHouse từ environment worker; tách khỏi tài khoản PG. |
| 10 | `  "password": "${env:CLICKHOUSE_PASSWORD}",` | Password ClickHouse từ environment; không điền password thật vào JSON. |
| 11 | `  "ssl": "false",` | false vì endpoint lab này dùng HTTP. |
| 12 | `  "exactlyOnce": "false",` | false; bảng đích gộp event_id trùng khi đọc FINAL. |
| 13 | `  "key.converter": "org.apache.kafka.connect.json.JsonConverter",` | Định dạng JSON của message key. |
| 14 | `  "value.converter": "org.apache.kafka.connect.json.JsonConverter",` | Định dạng JSON của message value. |
| 15 | `  "key.converter.schemas.enable": "true",` | Key JSON có schema để mô tả kiểu dữ liệu. |
| 16 | `  "value.converter.schemas.enable": "true",` | Value JSON có schema, khớp cách sink giải mã. |
| 17 | `  "tasks.max": "1"` | Một task sink đọc ba topic. |
| 18 | `}` | Mở/đóng nhóm dữ liệu hoặc câu lệnh. |

## demo/insert-micall.sql

| Dòng | Code | Giải thích |
|---|---|---|
| 1 | `-- Event riêng của nguồn micall; chạy trên pg-micall / database micall.` | Event riêng của nguồn micall; chạy trên pg-micall / database micall. |
| 2 | `INSERT INTO public.outbox_event (event_id, call_id, version, payload)` | ID event duy nhất xuyên ba nguồn; dùng làm khóa nhận diện. |
| 3 | `VALUES ('demo-micall-001', 'call-micall-001', 1,` | Giá trị riêng của nguồn để nhận diện ở topic và ClickHouse. |
| 4 | `        '{"source":"micall","scenario":"console-demo"}'::jsonb)` | Tiếp tục câu lệnh SQL trong nhóm phía trên. |
| 5 | `ON CONFLICT (event_id) DO NOTHING;` | Chạy lại demo không tạo thêm event cùng ID. |

## demo/insert-misales.sql

| Dòng | Code | Giải thích |
|---|---|---|
| 1 | `-- Event riêng của nguồn misales; chạy trên pg-misales / database misales.` | Event riêng của nguồn misales; chạy trên pg-misales / database misales. |
| 2 | `INSERT INTO public.outbox_event (event_id, call_id, version, payload)` | ID event duy nhất xuyên ba nguồn; dùng làm khóa nhận diện. |
| 3 | `VALUES ('demo-misales-001', 'call-misales-001', 1,` | Giá trị riêng của nguồn để nhận diện ở topic và ClickHouse. |
| 4 | `        '{"source":"misales","scenario":"console-demo"}'::jsonb)` | Tiếp tục câu lệnh SQL trong nhóm phía trên. |
| 5 | `ON CONFLICT (event_id) DO NOTHING;` | Chạy lại demo không tạo thêm event cùng ID. |

## demo/insert-miqa.sql

| Dòng | Code | Giải thích |
|---|---|---|
| 1 | `-- Event riêng của nguồn miqa; chạy trên pg-miqa / database miqa.` | Event riêng của nguồn miqa; chạy trên pg-miqa / database miqa. |
| 2 | `INSERT INTO public.outbox_event (event_id, call_id, version, payload)` | ID event duy nhất xuyên ba nguồn; dùng làm khóa nhận diện. |
| 3 | `VALUES ('demo-miqa-001', 'call-miqa-001', 1,` | Giá trị riêng của nguồn để nhận diện ở topic và ClickHouse. |
| 4 | `        '{"source":"miqa","scenario":"console-demo"}'::jsonb)` | Tiếp tục câu lệnh SQL trong nhóm phía trên. |
| 5 | `ON CONFLICT (event_id) DO NOTHING;` | Chạy lại demo không tạo thêm event cùng ID. |

## demo/select.sql

| Dòng | Code | Giải thích |
|---|---|---|
| 1 | `-- Đọc đúng ba event demo, gộp bản giao lại trùng event_id.` | Đọc đúng ba event demo, gộp bản giao lại trùng event_id. |
| 2 | `SELECT event_id, call_id, version, payload` | ID event duy nhất xuyên ba nguồn; dùng làm khóa nhận diện. |
| 3 | `FROM cdc.outbox_event FINAL` | FINAL gộp các bản giao lại trùng ID khi đọc. |
| 4 | `WHERE event_id IN ('demo-micall-001', 'demo-misales-001', 'demo-miqa-001')` | ID event duy nhất xuyên ba nguồn; dùng làm khóa nhận diện. |
| 5 | `ORDER BY event_id;` | Khóa gộp/sắp xếp theo event_id. |

## compose/postgres/compose.yaml

| Dòng | Code | Giải thích |
|---|---|---|
| 1 | `name: setup-v1-3vm` | Tên connector/project để quản lý và lưu trạng thái độc lập. |
| 2 | `services:` | Nhóm services chứa các thiết lập con bên dưới. |
| 3 | `  pg-micall:` | Tham số/thành phần tiếp theo của cấu hình đang mở. |
| 4 | `    image: postgres:18.4` | Image và tag cố định của module; Compose tải đúng bản này. |
| 5 | `    restart: unless-stopped` | Docker tự chạy lại container khi tiến trình thoát hoặc Docker khởi động lại. |
| 6 | `    command: [postgres, -c, config_file=/postgres/postgresql.conf]` | Tham số chạy tiến trình; khối nhiều dòng là một đối số cho entrypoint. |
| 7 | `    environment:` | Các biến truyền vào container; credential lấy từ .env. |
| 8 | `      POSTGRES_INITDB_ARGS: --auth-host=scram-sha-256` | Init PostgreSQL mới với xác thực TCP bằng SCRAM và password. |
| 9 | `      POSTGRES_DB: micall` | Database nguồn được tạo khi thư mục dữ liệu còn mới. |
| 10 | `      POSTGRES_USER: ${MICALL_PG_USER:?}` | User riêng theo module; lấy từ .env và truyền vào container. |
| 11 | `      POSTGRES_PASSWORD: ${MICALL_PG_PASSWORD:?}` | Password riêng theo module; lấy từ .env, không hardcode. |
| 12 | `      DEBEZIUM_USER: ${MICALL_DEBEZIUM_USER:?}` | User riêng theo module; lấy từ .env và truyền vào container. |
| 13 | `      DEBEZIUM_PASSWORD: ${MICALL_DEBEZIUM_PASSWORD:?}` | Password riêng theo module; lấy từ .env, không hardcode. |
| 14 | `      TZ: Asia/Ho_Chi_Minh` | Múi giờ của container; dữ liệu timestamptz vẫn biểu diễn thời điểm tuyệt đối. |
| 15 | `    ports: ['192.168.139.162:15432:5432']` | Ánh xạ IP host:port host:port container; dùng host port khi đi qua VM. |
| 16 | `    volumes:` | Các bind mount từ thư mục host; :ro chỉ đọc, data cần đọc/ghi. |
| 17 | `    - ../../postgres:/postgres:ro` | Host ./postgres → container /postgres; chỉ đọc. |
| 18 | `    - ../../data/pg-micall:/var/lib/postgresql` | Host ./data/pg-micall → container /var/lib/postgresql; đọc/ghi, dữ liệu hiện trên host. |
| 19 | `    - ../../postgres/init.sql:/docker-entrypoint-initdb.d/10-outbox.sql:ro` | Host ./postgres/init.sql → container /docker-entrypoint-initdb.d/10-outbox.sql; chỉ đọc. |
| 20 | `    healthcheck:` | Trạng thái sẵn sàng để Compose up --wait và depends_on điều phối. |
| 21 | `      test: [CMD-SHELL, 'PGPASSWORD="$${POSTGRES_PASSWORD}" psql -h 127.0.0.1 -U "$${POSTGRES_USER}" -d "$${POSTGRES_DB}" -c "SELECT 1" >/dev/null']` | Lệnh readiness của container, không phải một bước người dùng cần chạy. |
| 22 | `      interval: 5s` | Khoảng thời gian giữa các lần readiness. |
| 23 | `      retries: 30` | Số lần chờ readiness trước khi coi dịch vụ chưa sẵn sàng. |
| 24 | `  pg-misales:` | Tham số/thành phần tiếp theo của cấu hình đang mở. |
| 25 | `    image: postgres:18.4` | Image và tag cố định của module; Compose tải đúng bản này. |
| 26 | `    restart: unless-stopped` | Docker tự chạy lại container khi tiến trình thoát hoặc Docker khởi động lại. |
| 27 | `    command: [postgres, -c, config_file=/postgres/postgresql.conf]` | Tham số chạy tiến trình; khối nhiều dòng là một đối số cho entrypoint. |
| 28 | `    environment:` | Các biến truyền vào container; credential lấy từ .env. |
| 29 | `      POSTGRES_INITDB_ARGS: --auth-host=scram-sha-256` | Init PostgreSQL mới với xác thực TCP bằng SCRAM và password. |
| 30 | `      POSTGRES_DB: misales` | Database nguồn được tạo khi thư mục dữ liệu còn mới. |
| 31 | `      POSTGRES_USER: ${MISALES_PG_USER:?}` | User riêng theo module; lấy từ .env và truyền vào container. |
| 32 | `      POSTGRES_PASSWORD: ${MISALES_PG_PASSWORD:?}` | Password riêng theo module; lấy từ .env, không hardcode. |
| 33 | `      DEBEZIUM_USER: ${MISALES_DEBEZIUM_USER:?}` | User riêng theo module; lấy từ .env và truyền vào container. |
| 34 | `      DEBEZIUM_PASSWORD: ${MISALES_DEBEZIUM_PASSWORD:?}` | Password riêng theo module; lấy từ .env, không hardcode. |
| 35 | `      TZ: Asia/Ho_Chi_Minh` | Múi giờ của container; dữ liệu timestamptz vẫn biểu diễn thời điểm tuyệt đối. |
| 36 | `    ports: ['192.168.139.162:25432:5432']` | Ánh xạ IP host:port host:port container; dùng host port khi đi qua VM. |
| 37 | `    volumes:` | Các bind mount từ thư mục host; :ro chỉ đọc, data cần đọc/ghi. |
| 38 | `    - ../../postgres:/postgres:ro` | Host ./postgres → container /postgres; chỉ đọc. |
| 39 | `    - ../../data/pg-misales:/var/lib/postgresql` | Host ./data/pg-misales → container /var/lib/postgresql; đọc/ghi, dữ liệu hiện trên host. |
| 40 | `    - ../../postgres/init.sql:/docker-entrypoint-initdb.d/10-outbox.sql:ro` | Host ./postgres/init.sql → container /docker-entrypoint-initdb.d/10-outbox.sql; chỉ đọc. |
| 41 | `    healthcheck:` | Trạng thái sẵn sàng để Compose up --wait và depends_on điều phối. |
| 42 | `      test: [CMD-SHELL, 'PGPASSWORD="$${POSTGRES_PASSWORD}" psql -h 127.0.0.1 -U "$${POSTGRES_USER}" -d "$${POSTGRES_DB}" -c "SELECT 1" >/dev/null']` | Lệnh readiness của container, không phải một bước người dùng cần chạy. |
| 43 | `      interval: 5s` | Khoảng thời gian giữa các lần readiness. |
| 44 | `      retries: 30` | Số lần chờ readiness trước khi coi dịch vụ chưa sẵn sàng. |
| 45 | `  pg-miqa:` | Tham số/thành phần tiếp theo của cấu hình đang mở. |
| 46 | `    image: postgres:18.4` | Image và tag cố định của module; Compose tải đúng bản này. |
| 47 | `    restart: unless-stopped` | Docker tự chạy lại container khi tiến trình thoát hoặc Docker khởi động lại. |
| 48 | `    command: [postgres, -c, config_file=/postgres/postgresql.conf]` | Tham số chạy tiến trình; khối nhiều dòng là một đối số cho entrypoint. |
| 49 | `    environment:` | Các biến truyền vào container; credential lấy từ .env. |
| 50 | `      POSTGRES_INITDB_ARGS: --auth-host=scram-sha-256` | Init PostgreSQL mới với xác thực TCP bằng SCRAM và password. |
| 51 | `      POSTGRES_DB: miqa` | Database nguồn được tạo khi thư mục dữ liệu còn mới. |
| 52 | `      POSTGRES_USER: ${MIQA_PG_USER:?}` | User riêng theo module; lấy từ .env và truyền vào container. |
| 53 | `      POSTGRES_PASSWORD: ${MIQA_PG_PASSWORD:?}` | Password riêng theo module; lấy từ .env, không hardcode. |
| 54 | `      DEBEZIUM_USER: ${MIQA_DEBEZIUM_USER:?}` | User riêng theo module; lấy từ .env và truyền vào container. |
| 55 | `      DEBEZIUM_PASSWORD: ${MIQA_DEBEZIUM_PASSWORD:?}` | Password riêng theo module; lấy từ .env, không hardcode. |
| 56 | `      TZ: Asia/Ho_Chi_Minh` | Múi giờ của container; dữ liệu timestamptz vẫn biểu diễn thời điểm tuyệt đối. |
| 57 | `    ports: ['192.168.139.162:35432:5432']` | Ánh xạ IP host:port host:port container; dùng host port khi đi qua VM. |
| 58 | `    volumes:` | Các bind mount từ thư mục host; :ro chỉ đọc, data cần đọc/ghi. |
| 59 | `    - ../../postgres:/postgres:ro` | Host ./postgres → container /postgres; chỉ đọc. |
| 60 | `    - ../../data/pg-miqa:/var/lib/postgresql` | Host ./data/pg-miqa → container /var/lib/postgresql; đọc/ghi, dữ liệu hiện trên host. |
| 61 | `    - ../../postgres/init.sql:/docker-entrypoint-initdb.d/10-outbox.sql:ro` | Host ./postgres/init.sql → container /docker-entrypoint-initdb.d/10-outbox.sql; chỉ đọc. |
| 62 | `    healthcheck:` | Trạng thái sẵn sàng để Compose up --wait và depends_on điều phối. |
| 63 | `      test: [CMD-SHELL, 'PGPASSWORD="$${POSTGRES_PASSWORD}" psql -h 127.0.0.1 -U "$${POSTGRES_USER}" -d "$${POSTGRES_DB}" -c "SELECT 1" >/dev/null']` | Lệnh readiness của container, không phải một bước người dùng cần chạy. |
| 64 | `      interval: 5s` | Khoảng thời gian giữa các lần readiness. |
| 65 | `      retries: 30` | Số lần chờ readiness trước khi coi dịch vụ chưa sẵn sàng. |

## compose/postgres/.env

| Dòng | Code | Giải thích |
|---|---|---|
| 1 | `MICALL_PG_USER=micall_pg` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |
| 2 | `MICALL_PG_PASSWORD=change-me-micall_pg` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |
| 3 | `MICALL_DEBEZIUM_USER=micall_debezium` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |
| 4 | `MICALL_DEBEZIUM_PASSWORD=change-me-micall_debezium` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |
| 5 | `MISALES_PG_USER=misales_pg` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |
| 6 | `MISALES_PG_PASSWORD=change-me-misales_pg` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |
| 7 | `MISALES_DEBEZIUM_USER=misales_debezium` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |
| 8 | `MISALES_DEBEZIUM_PASSWORD=change-me-misales_debezium` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |
| 9 | `MIQA_PG_USER=miqa_pg` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |
| 10 | `MIQA_PG_PASSWORD=change-me-miqa_pg` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |
| 11 | `MIQA_DEBEZIUM_USER=miqa_debezium` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |
| 12 | `MIQA_DEBEZIUM_PASSWORD=change-me-miqa_debezium` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |

## compose/redpanda/compose.yaml

| Dòng | Code | Giải thích |
|---|---|---|
| 1 | `name: setup-v1-3vm` | Tên connector/project để quản lý và lưu trạng thái độc lập. |
| 2 | `services:` | Nhóm services chứa các thiết lập con bên dưới. |
| 3 | `  redpanda:` | Nhóm redpanda chứa các thiết lập con bên dưới. |
| 4 | `    image: docker.redpanda.com/redpandadata/redpanda:v26.1.12` | Image và tag cố định của module; Compose tải đúng bản này. |
| 5 | `    restart: unless-stopped` | Docker tự chạy lại container khi tiến trình thoát hoặc Docker khởi động lại. |
| 6 | `    entrypoint: [bash, -ec]` | Tiến trình đầu tiên trong container, chuẩn bị runtime rồi chạy dịch vụ. |
| 7 | `    command:` | Tham số chạy tiến trình; khối nhiều dòng là một đối số cho entrypoint. |
| 8 | `    - \|` | Tham số/thành phần tiếp theo của cấu hình đang mở. |
| 9 | `      chown redpanda:redpanda /var/lib/redpanda/data` | Entrypoint chuẩn bị thư mục broker cho user redpanda của image. |
| 10 | `      exec runuser -u redpanda -- rpk redpanda start --config /redpanda/redpanda.yaml --smp 1` | Chạy broker bằng user redpanda, không chạy tiến trình broker bằng root. |
| 11 | `    ports: ['127.0.0.1:19644:9644']` | Ánh xạ IP host:port host:port container; dùng host port khi đi qua VM. |
| 12 | `    volumes:` | Các bind mount từ thư mục host; :ro chỉ đọc, data cần đọc/ghi. |
| 13 | `    - ../../redpanda:/redpanda` | Host ./redpanda → container /redpanda; đọc/ghi, dữ liệu hiện trên host. |
| 14 | `    - ../../data/redpanda:/var/lib/redpanda/data` | Host ./data/redpanda → container /var/lib/redpanda/data; đọc/ghi, dữ liệu hiện trên host. |
| 15 | `    healthcheck:` | Trạng thái sẵn sàng để Compose up --wait và depends_on điều phối. |
| 16 | `      test: [CMD, rpk, cluster, health, --config, /redpanda/redpanda.yaml, --exit-when-healthy]` | Lệnh readiness của container, không phải một bước người dùng cần chạy. |
| 17 | `      interval: 5s` | Khoảng thời gian giữa các lần readiness. |
| 18 | `      retries: 30` | Số lần chờ readiness trước khi coi dịch vụ chưa sẵn sàng. |
| 19 | `    user: 0:0` | Root chỉ chuẩn bị thư mục bind; entrypoint hạ quyền trước khi chạy broker/worker. |
| 20 | `  connect:` | Nhóm connect chứa các thiết lập con bên dưới. |
| 21 | `    image: quay.io/debezium/connect:3.6.0.Final` | Image và tag cố định của module; Compose tải đúng bản này. |
| 22 | `    user: "0:0" # Connect chạy bằng root để ghi thư mục bind.` | Chạy Connect bằng root suốt thời gian hoạt động, giữ entrypoint mặc định; không cần lệnh chuẩn bị owner Kafka. |
| 23 | `    restart: unless-stopped` | Docker tự chạy lại container khi tiến trình thoát hoặc Docker khởi động lại. |
| 24 | `    environment:` | Các biến truyền vào container; credential lấy từ .env. |
| 25 | `      BOOTSTRAP_SERVERS: redpanda:9092` | Worker dùng DNS redpanda:9092 trong mạng Docker VM2. |
| 26 | `      GROUP_ID: setupv1-connect` | Nhóm worker Kafka Connect; không phải consumer group của sink. |
| 27 | `      CONFIG_STORAGE_TOPIC: _connect_configs` | Topic giữ cấu hình connector. |
| 28 | `      OFFSET_STORAGE_TOPIC: _connect_offsets` | Topic giữ tiến độ source. |
| 29 | `      STATUS_STORAGE_TOPIC: _connect_status` | Topic giữ trạng thái connector/task. |
| 30 | `      CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR: '1'` | Một replica cho topic nội bộ vì lab có một broker. |
| 31 | `      CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR: '1'` | Một replica cho topic nội bộ vì lab có một broker. |
| 32 | `      CONNECT_STATUS_STORAGE_REPLICATION_FACTOR: '1'` | Một replica cho topic nội bộ vì lab có một broker. |
| 33 | `      REST_HOST_NAME: 0.0.0.0` | REST lắng nghe mọi interface trong container. |
| 34 | `      ADVERTISED_HOST_NAME: connect` | Địa chỉ worker công bố cho các task/worker khác trong VM2. |
| 35 | `      CONNECT_CONFIG_PROVIDERS: env` | Bật provider tên env để JSON tham chiếu environment. |
| 36 | `      CONNECT_CONFIG_PROVIDERS_ENV_CLASS: org.apache.kafka.common.config.provider.EnvVarConfigProvider` | Provider có sẵn của Kafka; không cần sửa JSON bằng script. |
| 37 | `      MICALL_DEBEZIUM_USER: ${MICALL_DEBEZIUM_USER:?}` | User riêng theo module; lấy từ .env và truyền vào container. |
| 38 | `      MICALL_DEBEZIUM_PASSWORD: ${MICALL_DEBEZIUM_PASSWORD:?}` | Password riêng theo module; lấy từ .env, không hardcode. |
| 39 | `      MISALES_DEBEZIUM_USER: ${MISALES_DEBEZIUM_USER:?}` | User riêng theo module; lấy từ .env và truyền vào container. |
| 40 | `      MISALES_DEBEZIUM_PASSWORD: ${MISALES_DEBEZIUM_PASSWORD:?}` | Password riêng theo module; lấy từ .env, không hardcode. |
| 41 | `      MIQA_DEBEZIUM_USER: ${MIQA_DEBEZIUM_USER:?}` | User riêng theo module; lấy từ .env và truyền vào container. |
| 42 | `      MIQA_DEBEZIUM_PASSWORD: ${MIQA_DEBEZIUM_PASSWORD:?}` | Password riêng theo module; lấy từ .env, không hardcode. |
| 43 | `      CLICKHOUSE_PASSWORD: ${CLICKHOUSE_PASSWORD:?}` | Password riêng theo module; lấy từ .env, không hardcode. |
| 44 | `      CLICKHOUSE_USER: ${CLICKHOUSE_USER:?}` | User riêng theo module; lấy từ .env và truyền vào container. |
| 45 | `    depends_on:` | Chờ dependency trong cùng VM; không điều phối dịch vụ xuyên VM. |
| 46 | `      redpanda:` | Nhóm redpanda chứa các thiết lập con bên dưới. |
| 47 | `        condition: service_healthy` | Chỉ chạy worker/Console sau khi broker healthy. |
| 48 | `    ports: ['192.168.139.163:8083:8083']` | Ánh xạ IP host:port host:port container; dùng host port khi đi qua VM. |
| 49 | `    volumes:` | Các bind mount từ thư mục host; :ro chỉ đọc, data cần đọc/ghi. |
| 50 | `    - ../../connect/plugins/clickhouse-kafka-connect-v1.5.0:/kafka/connect/clickhouse-kafka-connect:ro` | Host ./connect/plugins/clickhouse-kafka-connect-v1.5.0 → container /kafka/connect/clickhouse-kafka-connect; chỉ đọc. |
| 51 | `    - ../../data/connect/config:/kafka/config` | Host ./data/connect/config → container /kafka/config; đọc/ghi, dữ liệu hiện trên host. |
| 52 | `    - ../../data/connect/data:/kafka/data` | Host ./data/connect/data → container /kafka/data; đọc/ghi, dữ liệu hiện trên host. |
| 53 | `    - ../../data/connect/logs:/kafka/logs` | Host ./data/connect/logs → container /kafka/logs; đọc/ghi, dữ liệu hiện trên host. |
| 54 | `    healthcheck:` | Trạng thái sẵn sàng để Compose up --wait và depends_on điều phối. |
| 55 | `      test: [CMD-SHELL, 'curl -fsS http://127.0.0.1:8083/']` | Lệnh readiness của container, không phải một bước người dùng cần chạy. |
| 56 | `      interval: 5s` | Khoảng thời gian giữa các lần readiness. |
| 57 | `      retries: 30` | Số lần chờ readiness trước khi coi dịch vụ chưa sẵn sàng. |
| 58 | `  console:` | Nhóm console chứa các thiết lập con bên dưới. |
| 59 | `    image: docker.redpanda.com/redpandadata/console:v3.12.0` | Image và tag cố định của module; Compose tải đúng bản này. |
| 60 | `    restart: unless-stopped` | Docker tự chạy lại container khi tiến trình thoát hoặc Docker khởi động lại. |
| 61 | `    depends_on:` | Chờ dependency trong cùng VM; không điều phối dịch vụ xuyên VM. |
| 62 | `      redpanda:` | Nhóm redpanda chứa các thiết lập con bên dưới. |
| 63 | `        condition: service_healthy` | Chỉ chạy worker/Console sau khi broker healthy. |
| 64 | `    environment:` | Các biến truyền vào container; credential lấy từ .env. |
| 65 | `      CONFIG_FILEPATH: /console/config.yaml` | Chỉ đường dẫn file native Console được bind mount. |
| 66 | `    ports: ['192.168.139.163:8080:8080']` | Ánh xạ IP host:port host:port container; dùng host port khi đi qua VM. |
| 67 | `    volumes:` | Các bind mount từ thư mục host; :ro chỉ đọc, data cần đọc/ghi. |
| 68 | `    - ../../console:/console:ro` | Host ./console → container /console; chỉ đọc. |

## compose/redpanda/.env

| Dòng | Code | Giải thích |
|---|---|---|
| 1 | `MICALL_DEBEZIUM_USER=micall_debezium` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |
| 2 | `MICALL_DEBEZIUM_PASSWORD=change-me-micall_debezium` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |
| 3 | `MISALES_DEBEZIUM_USER=misales_debezium` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |
| 4 | `MISALES_DEBEZIUM_PASSWORD=change-me-misales_debezium` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |
| 5 | `MIQA_DEBEZIUM_USER=miqa_debezium` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |
| 6 | `MIQA_DEBEZIUM_PASSWORD=change-me-miqa_debezium` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |
| 7 | `CLICKHOUSE_USER=ch_sink` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |
| 8 | `CLICKHOUSE_PASSWORD=change-me-clickhouse` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |

## compose/clickhouse/compose.yaml

| Dòng | Code | Giải thích |
|---|---|---|
| 1 | `name: setup-v1-3vm` | Tên connector/project để quản lý và lưu trạng thái độc lập. |
| 2 | `services:` | Nhóm services chứa các thiết lập con bên dưới. |
| 3 | `  clickhouse:` | Nhóm clickhouse chứa các thiết lập con bên dưới. |
| 4 | `    image: clickhouse/clickhouse-server:25.8.33.6` | Image và tag cố định của module; Compose tải đúng bản này. |
| 5 | `    restart: unless-stopped` | Docker tự chạy lại container khi tiến trình thoát hoặc Docker khởi động lại. |
| 6 | `    environment:` | Các biến truyền vào container; credential lấy từ .env. |
| 7 | `      CLICKHOUSE_USER: ${CLICKHOUSE_USER}` | User riêng theo module; lấy từ .env và truyền vào container. |
| 8 | `      CLICKHOUSE_PASSWORD: ${CLICKHOUSE_PASSWORD}` | Password riêng theo module; lấy từ .env, không hardcode. |
| 9 | `      TZ: Asia/Ho_Chi_Minh` | Múi giờ của container; dữ liệu timestamptz vẫn biểu diễn thời điểm tuyệt đối. |
| 10 | `    ports: ['192.168.139.164:18123:8123', '192.168.139.164:19000:9000']` | Ánh xạ IP host:port host:port container; dùng host port khi đi qua VM. |
| 11 | `    volumes:` | Các bind mount từ thư mục host; :ro chỉ đọc, data cần đọc/ghi. |
| 12 | `    - ../../clickhouse:/clickhouse:ro` | Host ./clickhouse → container /clickhouse; chỉ đọc. |
| 13 | `    - ../../data/clickhouse:/var/lib/clickhouse` | Host ./data/clickhouse → container /var/lib/clickhouse; đọc/ghi, dữ liệu hiện trên host. |
| 14 | `    - ../../clickhouse/init.sql:/docker-entrypoint-initdb.d/10-outbox.sql:ro` | Host ./clickhouse/init.sql → container /docker-entrypoint-initdb.d/10-outbox.sql; chỉ đọc. |
| 15 | `    healthcheck:` | Trạng thái sẵn sàng để Compose up --wait và depends_on điều phối. |
| 16 | `      test: [CMD-SHELL, 'wget --spider -q http://127.0.0.1:8123/ping']` | Lệnh readiness của container, không phải một bước người dùng cần chạy. |
| 17 | `      interval: 5s` | Khoảng thời gian giữa các lần readiness. |
| 18 | `      retries: 30` | Số lần chờ readiness trước khi coi dịch vụ chưa sẵn sàng. |

## compose/clickhouse/.env

| Dòng | Code | Giải thích |
|---|---|---|
| 1 | `CLICKHOUSE_USER=ch_sink` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |
| 2 | `CLICKHOUSE_PASSWORD=change-me-clickhouse` | Tài khoản riêng cho nhóm dịch vụ; giá trị ở viewer là bản mẫu. |

