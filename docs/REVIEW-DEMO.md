# Review setup-v1 và hướng đi tới demo

Ngày review: 2026-11-16. Phạm vi: đọc `index.html`, `bao_cao_cdc_a4_map_day_du (1).html`, toàn bộ file cấu hình trong `D:/setup-v1`. Chưa chạy lệnh nào trên VM; mọi nhận định về runtime dựa trên file và ảnh trong báo cáo.

## 1. Kết luận

| Hạng mục | Kết luận |
|---|---|
| Cấu hình + guide `index.html` | Đạt phần nền: 14/14 file nhúng khớp file thật, không lộ password, happy-path INSERT đã nghiệm thu (theo SOURCE-OF-TRUTH) |
| Kịch bản KB1–KB4 (báo cáo) | **Chưa đạt để demo**: đúng ý tưởng, thiếu bằng chứng đo đếm, có ảnh từ môi trường cũ |
| Runbook theo quy tắc CLAUDE.md | Chưa đủ: thiếu bài toán BA, debug theo thứ tự, audit có output thật, Q&A bảo vệ, KB1–KB4 |

## 2. Lỗi cần sửa trước demo (P0)

- [ ] **Thiếu thư mục `demo/`** trên đĩa Windows. `index.html` và `docs/DEPLOYMENT.md` gọi `../../demo/insert-*.sql`, `../../demo/select.sql`; nội dung chỉ tồn tại trong HTML. Triển khai lại từ đầu sẽ lỗi `No such file`.
- [ ] **Bằng chứng KB chỉ lọc đúng 1 dòng cuối** (`kb1-call-10000`, `kb2-call-9999`, `call-90000`, `kb4-call-999`). Có dòng cuối chưa chứng minh đủ N dòng. Con số `1,000,004 rows` ở sidebar giống hệt trong KB1, KB2, KB4 nên là metadata, không phải bằng chứng.
- [ ] **Hình 12, 11, 16 (KB3) từ môi trường cũ**: container `miqa-demo-pg-miqa`, user `postgres`, bảng `call_state`/`cdc_wal_demo`, view `voip_cdr_analytics`, ngày 28/09. `invalidation_reason=idle_timeout` trong khi `postgres/postgresql.conf` hiện tại không có `idle_replication_slot_timeout`. Phải chạy lại KB3 trên setup-v1.
- [ ] **Hình 01 sai hostname/IP**: ghi `.163 = miqa-cdc-2`, `.165 = miqa-cdc-3`. Thực tế `.163 = miqa-cdc-3`, `.164 = miqa-cdc-2`, không có `.165`. Tên topic trên hình (`outbox.event.micall`) khác thực tế (`micall.public.outbox_event`).
- [ ] **Chú thích sai** trong viewer `index.html`: dòng `port = 5432` (postgresql.conf) đang ghi "Port HTTP host 18123 của ClickHouse".

## 3. Đánh giá từng kịch bản

| KB | Mục tiêu | Vấn đề | Cách sửa |
|---|---|---|---|
| KB1 | PG sập, CDC bù đủ | Pause connector trước, nên không thử "PG chết khi CDC đang chạy" | Thêm biến thể không pause: tải liên tục, `docker compose stop pg-miqa`, quan sát task có tự phục hồi hay FAILED |
| KB2 | Connect sập | Mới chỉ `stop` connector, chưa chết container Connect | Thêm `docker compose kill connect` rồi `up -d --wait`, kiểm tra offset còn |
| KB3 | Slot mất WAL | DROP slot thủ công; chứng cứ từ môi trường cũ; snapshot phát lại 3 ngày nên có trùng | Chứng minh `wal_status=lost` trên setup-v1, coi DROP + DELETE offsets + resume là **runbook phục hồi**; kiểm bằng `uniqExact`; nêu rõ event cũ hơn 3 ngày không được bù |
| KB4 | ClickHouse sập | Thiếu lệnh; sink có thể FAILED nếu CH sập lâu hơn thời gian retry (cần kiểm chứng) | Sau start CH, kiểm status; nếu FAILED thì restart task (lệnh ở mục 5) |
| (thiếu) KB5 | Redpanda sập | Broker đơn, replication=1, là thành phần giữa nhưng chưa có kịch bản | Thêm: stop redpanda, INSERT, start, kiểm đủ event |

Mọi KB đều thiếu: tiêu chí đạt (N gửi = N nhận), thời gian phục hồi, lệnh ở các bước 3/4 của KB1, KB2 và toàn bộ KB4.

## 4. Điểm cấu hình cần biết (P1/P2)

- `compose/clickhouse/compose.yaml`: `CLICKHOUSE_USER`/`CLICKHOUSE_PASSWORD` không có `:?` (hai compose kia có). Thiếu `.env` thì user mặc định không mật khẩu.
- `max_slot_wal_keep_size = 64MB` thấp có chủ đích cho KB3; demo tải lớn có thể làm mất slot ngoài ý muốn. Ghi chú trong guide.
- `connect/connectors/README.md` trỏ "DEPLOYMENT.md bước 8 và 9" nhưng DEPLOYMENT.md không đánh số bước.
- `index.html` 4.9MB: 5 iframe srcdoc ~0.9MB mỗi cái (~4.5MB), có thể lặp cùng runtime (chưa kiểm); iframe đầu không `loading="lazy"`.
- SOURCE-OF-TRUTH ghi không dùng systemd, trong khi CLAUDE.md quy định Docker Compose + systemd. Cần chốt lựa chọn.
- Lab không bảo mật: Connect REST `:8083`, Console `:8080` không xác thực; ClickHouse HTTP không TLS; user sink quyền rộng. Chuẩn bị câu trả lời cho Q&A.
- Chưa nghiệm thu: UPDATE/DELETE (unwrap mặc định bỏ tombstone), HA, backup/restore, tải lớn (SOURCE-OF-TRUTH đã tự nêu).

## 5. Lệnh kiểm chuẩn (dùng cho mọi KB)

Thay `kb1_` bằng tiền tố của KB đang kiểm. Dùng `starts_with`/`startsWith`, không dùng `LIKE 'kb1_%'` vì `_` là ký tự đại diện.

```bash
# VM1 .162 | cd /opt/setup-v1/compose/postgres
# Đếm số event gốc tại PostgreSQL (nguồn)
docker compose exec -T pg-miqa bash -c 'psql -X -U "$POSTGRES_USER" -d "$POSTGRES_DB"' <<'SQL'
SELECT count(*) AS pg_total
FROM public.outbox_event
WHERE starts_with(event_id, 'kb1_');
SQL

# VM3 .164 | cd /opt/setup-v1/compose/clickhouse
# Đếm số event duy nhất tại ClickHouse (đích). Kỳ vọng ch_unique = pg_total.
# ch_rows có thể lớn hơn nếu có trùng (snapshot/giao lại); ReplacingMergeTree chỉ gộp khi merge.
docker compose exec -T clickhouse bash -c 'clickhouse-client --user "$CLICKHOUSE_USER" --password "$CLICKHOUSE_PASSWORD" --multiquery' <<'SQL'
SELECT uniqExact(event_id) AS ch_unique, count() AS ch_rows
FROM cdc.outbox_event
WHERE startsWith(event_id, 'kb1_');
SQL
```

```bash
# VM2 .163 | trạng thái 4 connector và task (RUNNING / FAILED / PAUSED / STOPPED)
curl -fsS "http://192.168.139.163:8083/connectors?expand=status"

# VM2 .163 | restart task FAILED của sink sau khi ClickHouse trở lại
curl -fsS -X POST "http://192.168.139.163:8083/connectors/ch-sink-all/restart?includeTasks=true&onlyFailed=true"

# VM1 .162 | trạng thái slot (KB3): kỳ vọng active=t bình thường; wal_status=lost khi bị mất WAL
cd /opt/setup-v1/compose/postgres
docker compose exec -T pg-miqa bash -c 'psql -X -U "$POSTGRES_USER" -d "$POSTGRES_DB"' <<'SQL'
SELECT slot_name, active, wal_status, invalidation_reason FROM pg_replication_slots;
SQL
```

## 6. Danh sách việc tiếp theo để demo (theo thứ tự)

- [ ] 1. Sửa 5 lỗi P0 (mục 2): tạo `demo/*.sql`, vẽ lại Hình 01, sửa chú thích, thay ảnh KB3.
- [ ] 2. Pre-flight trên 3 VM: 7 container healthy, 4 connector RUNNING, ghi baseline `count` ở PG và CH.
- [ ] 3. Chạy lại KB1–KB4 trên setup-v1 bằng lệnh mục 5; mỗi KB ghi: số gửi, số nhận, thời gian phục hồi, ảnh/output thật.
- [ ] 4. Bổ sung KB2b (kill container Connect) và KB5 (Redpanda sập).
- [ ] 5. Gom thành bảng kết quả một trang (KB, thao tác, kỳ vọng, thực tế, đạt/không).
- [ ] 6. Dựng kịch bản trình bày 10–15 phút: happy-path live (3 INSERT → Console → ClickHouse FINAL), 1 sự cố live ngắn (KB4), KB3 trình bày bằng số đo đã có.
- [ ] 7. Viết bổ sung vào guide theo quy tắc runbook: bài toán BA, debug theo thứ tự (PG → Connect source → Redpanda → Connect sink → ClickHouse), phần Q&A bảo vệ.
