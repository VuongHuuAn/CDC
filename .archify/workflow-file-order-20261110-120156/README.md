# Workflow quan hệ file theo thứ tự

Một sơ đồ duy nhất tại index.html#references. Mũi tên biểu diễn thứ tự triển khai lab; không có nghĩa file này tự gọi file kia.

```text
compose/postgres/compose.yaml
  → postgres/postgresql.conf → postgres/init.sql (data mới) → PostgreSQL x3 sẵn sàng
  → compose/clickhouse/compose.yaml → clickhouse/init.sql (data mới)
  → compose/redpanda/compose.yaml → redpanda/redpanda.yaml → Connect worker
  → console/config.yaml
  → connect/connectors/source-{micall,misales,miqa}.json
  → connect/connectors/ch-sink-all.json
```

- PostgreSQL: miqa-cdc-1 / 192.168.139.162, host port 15432/25432/35432.
- Broker/Connect/Console: miqa-cdc-3 / 192.168.139.163. Worker lấy BOOTSTRAP_SERVERS=redpanda:9092 từ Compose.
- Console: CONFIG_FILEPATH=/console/config.yaml. YAML khai báo kafka.brokers=redpanda:9092, redpanda.adminApi.urls=http://redpanda:9644, kafkaConnect.clusters[].url=http://connect:8083.
- JSON source: database.hostname/port chọn PostgreSQL tương ứng. Đăng ký bằng REST PUT /connectors/<name>/config :8083 hoặc GUI.
- JSON sink: hostname=192.168.139.164, port=18123, database=cdc, topic2TableMap trỏ outbox_event; đích là miqa-cdc-2.
- Ba source và một sink cùng chạy trong container Connect. Worker không tự đọc các JSON từ thư mục.

## Lệnh áp dụng theo thư mục

```bash
# Trên VM1 .162
cd /opt/setup-v1/compose/postgres
docker compose up -d --wait # Khởi động ba nguồn.
# Trên VM3 .164
cd /opt/setup-v1/compose/clickhouse
docker compose up -d --wait # Khởi động đích.
# Trên VM2 .163
cd /opt/setup-v1/compose/redpanda
docker compose up -d --wait # Khởi động broker, worker, Console.
# Tiếp tục đăng ký ba source và một sink theo mục Topic / connector trong guide.
```

Sơ đồ được đối chiếu Compose, native config và connector JSON hiện tại. Kiểm tra artifact/browser tự động pass; chưa đánh giá ảnh bằng mắt. Nút Viewer dùng tiếng Anh. Source không có Git nên không gán provenance commit. Không thay đổi runtime.

## Nhãn vai trò và tên file khi hover

Sơ đồ dùng vai trò trên các ô; rê chuột lên ô để xem đường dẫn file bằng tooltip SVG title. Guide gắn tên file khi iframe load, không thay đổi nội dung artifact Archify đã kiểm tra. Mỗi ô cũng có nhãn truy cập chứa vai trò + file; có thể bấm mở file trong danh sách bên dưới sơ đồ.

| Ô | File tham chiếu khi hover |
|---|---|
| pgcompose | compose/postgres/compose.yaml |
| pgconf | postgres/postgresql.conf |
| pginit | postgres/init.sql |
| pgready | compose/postgres/compose.yaml → healthcheck |
| chcompose | compose/clickhouse/compose.yaml |
| chinit | clickhouse/init.sql |
| rpcompose | compose/redpanda/compose.yaml |
| rpconf | redpanda/redpanda.yaml |
| worker | compose/redpanda/compose.yaml → connect.environment.BOOTSTRAP_SERVERS |
| consoleconf | console/config.yaml; compose/redpanda/compose.yaml → CONFIG_FILEPATH |
| sources | connect/connectors/source-micall.json; connect/connectors/source-misales.json; connect/connectors/source-miqa.json |
| sink | connect/connectors/ch-sink-all.json |
