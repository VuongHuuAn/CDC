# Sơ đồ module / IP / hostname / port

Đã thay sơ đồ đầu tiên trong index.html bằng sơ đồ có khung từng VM:

| VM | Hostname | IP | Module |
|---|---|---|---|
| VM1 | miqa-cdc-1 | 192.168.139.162 | Ba PostgreSQL, host port 15432/25432/35432 |
| VM2 | miqa-cdc-3 | 192.168.139.163 | Redpanda, Connect, Console |
| VM3 | miqa-cdc-2 | 192.168.139.164 | ClickHouse, host port 18123/19000 |

Ba source và một sink là vai trò trong cùng container Connect. Kafka 9092 và Admin 9644 dùng trong mạng Docker VM2; Console mở 8080, Connect REST mở 8083; Admin host chỉ mở 127.0.0.1:19644. Nhãn arrow thể hiện đường dữ liệu; Console có đường điều khiển REST/Admin.

Hostname đã đọc trực tiếp từ ba VM. IP/port đối chiếu Compose, connector JSON và console/config.yaml. Source Windows không có Git nên không gán evidence commit. Kiểm tra artifact và trình duyệt tự động đã pass; chưa đánh giá ảnh bằng mắt. Một phần nút Viewer dùng tiếng Anh.

Lệnh tạo artifact (chạy trong môi trường Linux kiểm tra, đường dẫn skill tương ứng):

```bash
node skill/bin/archify.mjs finalize architecture candidate.json .archify/architecture-vm-ip-hostname-20261110-113808/vm-ip-hostname.html --out-dir review-4 --quality showcase --json # Validate, deliver, check và browser-check.
```
