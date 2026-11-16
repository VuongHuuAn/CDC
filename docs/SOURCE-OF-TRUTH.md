# Source of Truth — Docker Compose / CLI hoặc Console GUI

Ngày: 2026-11-09. Nguồn Windows `D:/setup-v1`; đường dẫn chạy trên mỗi VM `/opt/setup-v1`. Guide offline `index.html`; hướng dẫn lệnh/GUI `docs/DEPLOYMENT.md`; giải thích từng dòng `docs/FILES.md`.

## Cấu hình thuộc về đâu

- `.env`: chỉ 14 khóa của bảy cặp user/password, riêng cho admin PG và CDC của ba nguồn, cùng ClickHouse `ch_sink`. `.env.example` giữ cùng tập khóa với password mẫu; không commit `.env`.
- `compose/postgres/compose.yaml`, `compose/redpanda/compose.yaml`, `compose/clickhouse/compose.yaml`: IP bind, host port, image/tag, timezone, environment, entrypoint và bind mounts. Project cố định `setup-v1-3vm`.
- PostgreSQL/Redpanda/Console: file native trong thư mục module. SQL init được image entrypoint chạy khi data mới, không phải migration cho data đã có.
- Bốn JSON connector: endpoint/topic/slot/snapshot/mapping; `${env:...}` được EnvVarConfigProvider của Kafka lấy từ environment worker. Không dùng script thay JSON.
- Lệnh vận hành là Docker Compose; không có systemd trong bản ship. Các unit của bản trước đã tắt để không quản lý chồng lên Compose.

## Hostname / IP / port / module

| VM | Hostname | Nhóm Compose | Module / host port | Image |
|---|---|---|---|---|
| .162 | miqa-cdc-1 | vm1 | PG micall 15432, misales 25432, miqa 35432 → 5432 | postgres:18.4 |
| .163 | miqa-cdc-3 | vm2 | Redpanda Kafka 9092 nội bộ, Admin localhost 19644→9644 | docker.redpanda.com/redpandadata/redpanda:v26.1.12 |
| .163 | miqa-cdc-3 | vm2 | Connect REST 8083 | quay.io/debezium/connect:3.6.0.Final |
| .163 | miqa-cdc-3 | vm2 | Console GUI 8080 | docker.redpanda.com/redpandadata/console:v3.12.0 |
| .164 | miqa-cdc-2 | vm3 | ClickHouse 18123→8123, 19000→9000 | clickhouse/clickhouse-server:25.8.33.6 |

IP đầy đủ là `192.168.139.162/163/164`. Connect chứa ba source và một sink, mỗi connector một task; plugin ClickHouse v1.5.0 là JAR đi kèm. DNS `redpanda`/`connect` chỉ dùng trong Docker network VM2; liên VM dùng IP và host port.

## Bind mount 100%

| Thư mục host trên VM | Đường dẫn container | Vai trò |
|---|---|---|
| data/pg-micall, data/pg-misales, data/pg-miqa trên VM1 | /var/lib/postgresql | Ba database nguồn |
| data/redpanda trên VM2 | /var/lib/redpanda/data | Event, connector config/status/offset và consumer offsets |
| data/connect/config trên VM2 | /kafka/config | Worker properties do entrypoint image tạo |
| data/connect/data trên VM2 | /kafka/data | Runtime directory của image Connect |
| data/connect/logs trên VM2 | /kafka/logs | Runtime logs của image Connect |
| data/clickhouse trên VM3 | /var/lib/clickhouse | Bảng phân tích |
| postgres, redpanda, console, clickhouse, connect/plugins | Theo từng mount trong Compose | Config, SQL, plugin |

Tất cả mount đang gắn vào bảy container đã được kiểm tra có Type=bind, gồm cả ba thư mục mà image Connect trước đây tự tạo anonymous volume. Thư mục data chỉ phát sinh trên VM, được bỏ qua khi quản lý/sync source Windows. Không copy hoặc ghi đè data khi đồng bộ cấu hình.

Entrypoint Redpanda chuẩn bị thư mục rồi chạy bằng user redpanda UID/GID 101. Connect dùng user root (0:0) và entrypoint mặc định của image; không cần chuẩn bị owner Kafka cho thư mục bind. PostgreSQL/ClickHouse dùng entrypoint chính thức. Guide không có bước gán owner Kafka và không có script Python tùy biến. Dữ liệu cũ đã được copy sau khi container dừng; volumes cũ được giữ riêng để rollback, không còn gắn vào container.

## Luồng và thao tác GUI đã làm thực tế

1. Topics → Create topic → tên, Partitions=1, Replication factor=1, Cleanup policy=delete → Create.
2. Connect → Kafka Connect → Clusters → setupv1-connect → Create connector.
3. Source: Import from PostgreSQL (Debezium) → JSON → bấm vùng code, Ctrl+A, dán nguyên JSON → Next → Create.
4. Sink: Export to ClickHouseSinkConnector → JSON → dán nguyên JSON → Next → Create.
5. Overview hiển thị Healthy và task Running. Configuration → JSON → Update Config dùng để chỉnh connector.
6. Topics → topic nguồn → Messages → Expand row → Value. Ctrl+End trong editor để xem payload ở cuối.

Đã tạo topic và cặp source/sink minh họa qua Computer Use trong Codex, quan sát event thật; sau đó dọn riêng topic/connector/slot minh họa. Pipeline chính vẫn chỉ có source-micall, source-misales, source-miqa và ch-sink-all. Ảnh GUI trong guide dùng tên guide-source/guide-sink để phân biệt thao tác minh họa.

## Demo và quy tắc dữ liệu

`demo/insert-*.sql` tạo ba event `demo-micall-001`, `demo-misales-001`, `demo-miqa-001`; `demo/select.sql` đọc đúng ba event bằng FINAL. Đã đối chiếu đúng payload.source và scenario=console-demo tại ClickHouse sau khi chuyển bind mount; giữ dữ liệu demo để tiếp tục sử dụng guide.

Source đọc public.outbox_event, snapshot ba ngày rồi streaming qua pgoutput. Snapshot window không lọc timestamp của INSERT streaming. Sink đọc ba topic và ghi chung cdc.outbox_event; event_id phải duy nhất xuyên nguồn. ReplacingMergeTree theo event_id, chưa dùng version làm tham số engine; exactlyOnce=false. Slot, source offset và consumer offset là ba trạng thái riêng.

## Đồng bộ và phạm vi

Sửa source Windows rồi đồng bộ các file cấu hình/tài liệu tới `/opt/setup-v1`; bỏ qua data/. Sửa Compose/native config thì chạy lại up -d --wait đúng file Compose; sửa JSON thì PUT hoặc Update Config. Đổi credential trên DB hiện hữu còn cần cập nhật tài khoản thật, không chỉ copy `.env`.

Môi trường đã có Ubuntu 24.04.4, Docker 29.4.0, Compose v5.1.3. Luồng INSERT lab đã chạy; chưa nghiệm thu HA, mất WAL, UPDATE/DELETE, backup/restore hoặc tải lớn. Bằng chứng nội bộ, bản source cũ và công cụ soạn guide nằm ngoài bản ship tại `D:/setup-v1-authoring-gui-20261109`. HTML guide tự chứa code viewer, ảnh GUI và bốn sơ đồ Archify; `.env` trong viewer chỉ là bản mẫu.

## Bằng chứng triển khai đã kiểm tra

- Đồng bộ 24 file source/config/docs từ Windows tới `/opt/setup-v1` trên cả ba VM; SHA-256 từng file khớp, không đồng bộ thư mục `data/`.
- Ba PostgreSQL, Redpanda, Kafka Connect, Console và ClickHouse đang chạy từ Compose; mọi mount của bảy container có `Type=bind`.
- Kafka Connect REST trên `192.168.139.163:8083` trả trạng thái RUNNING cho `source-micall`, `source-misales`, `source-miqa`, `ch-sink-all`; cả bốn task đều RUNNING.
- ClickHouse `cdc.outbox_event FINAL` trả đúng ba event demo `demo-micall-001`, `demo-misales-001`, `demo-miqa-001` cùng payload `scenario=console-demo`.
- Console GUI đã được thao tác trong Codex: tạo topic, tạo connector JSON source/sink, quan sát task và event; các artefact học thao tác đã được dọn sau đó.

## Tách Compose theo module — 2026-11-10

Ba bộ Compose nằm trong compose/postgres, compose/redpanda, compose/clickhouse. Mỗi bộ có compose.yaml và .env; chạy từ /opt/setup-v1/compose/postgres, compose/redpanda hoặc compose/clickhouse để Compose tự đọc hai file. Các bind source dùng ../../ để luôn trỏ đúng config và data ở thư mục gốc. Giữ project setup-v1-3vm và DNS Docker trên VM2. Không dùng --remove-orphans vì các bộ cùng project. Compose gốc đã lưu ngoài source để rollback.

Kiểm tra sau khi tách: Compose config hợp lệ và up --wait thành công trên ba VM; INSERT mới tạo demo-micall-compose-split-001, demo-misales-compose-split-001, demo-miqa-compose-split-001 đã tới cdc.outbox_event với đúng payload. Bốn connector/task RUNNING. File compose.yaml cũ trên VM chuyển ra /home/pbxa/setup-v1-compose-before-split-20261110.yaml.

## Lệnh rút gọn — 2026-11-10

- Mỗi thư mục compose/postgres, compose/redpanda, compose/clickhouse dùng tên chuẩn compose.yaml và .env; không cần -f hay --env-file.
- .env gốc là bản quản lý tài khoản; .env từng bộ là phần khóa cần cho bộ đó, cùng giá trị. Khi đổi tài khoản phải đồng bộ các file liên quan; không sửa password trong HTML.
- Chạy cd /opt/setup-v1/compose/<module> trước docker compose up -d --wait. File SQL demo ở ../../demo; JSON connector ở ../../connect/connectors.
- Bind vẫn dùng ../../ từ vị trí Compose để trỏ về config và data gốc; không đổi data hoặc port.

Đã nghiệm thu lệnh ngắn trên ba VM: config --quiet, up -d --wait thành công; ba INSERT mới demo-<nguồn>-short-guide-001 tới ClickHouse với đúng payload. Lệnh SELECT dùng ../../demo/select.sql trong guide trả đủ ba event demo chuẩn.

## Connect chạy bằng root — 2026-11-10

Compose đặt user: "0:0", không ghi đè entrypoint/command của Debezium. Worker chạy bằng root suốt thời gian hoạt động, không hạ về Kafka. Thư mục bind thông thường do Docker tạo được root ghi; bỏ lệnh install -d gán owner Kafka khỏi guide.

Đã áp dụng bằng docker compose up -d --wait tại /opt/setup-v1/compose/redpanda. Inspect xác nhận user 0:0 và entrypoint /docker-entrypoint.sh; id trả uid=0(root), container healthy. Ba INSERT mới demo-micall-root-connect-001, demo-misales-root-connect-001, demo-miqa-root-connect-001 tới cdc.outbox_event FINAL với đúng source và scenario=root-connect. Bốn connector/task RUNNING.

## Sơ đồ IP / hostname — 2026-11-10

Sơ đồ đầu tiên trong index.html đã thay bằng bản Archify trong .archify/architecture-vm-ip-hostname-20261110-113808/vm-ip-hostname.html. Nhãn mỗi khung ghi VM, hostname và IP đầy đủ; port nằm trên module/luồng. Ba source và một sink cùng thuộc container Connect trên .163. Hostname đối chiếu bằng SSH, cấu hình port theo Compose và JSON hiện tại. Xem README.md trong thư mục artifact để biết nguồn và giới hạn kiểm tra.

## Sơ đồ đấu nối theo màu module — 2026-11-10

index.html#references dùng bản giản lược 5 module trong .archify/architecture-module-colors-20261110-144523/module-colors.html: PostgreSQL tím, Connect xanh lá, Redpanda cam, ClickHouse vàng, Console cyan. File và khóa cấu hình gộp vào tooltip từng module; không có ô khai báo riêng hay bước đọc .env. Ba source và một sink ở đúng một khối Connect. Màu ClickHouse chỉ phân biệt module, không chỉ môi trường cloud. docs/CONFIG-REFERENCES.md và README của artifact chứa nguồn/lệnh/giới hạn kiểm tra.

Quy ước sơ đồ đấu nối: mũi tên từ bên mở kết nối tới bên nhận. Connect → PostgreSQL (pgoutput), Connect → Redpanda cho cả Produce và Fetch, Connect → ClickHouse; Console → Redpanda/Connect. Chiều dữ liệu WAL/event trả về không phải chiều mũi tên của sơ đồ này.
