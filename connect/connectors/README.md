# Bốn connector trong một worker

| File | Nguồn / topic | Đích |
|---|---|---|
| `source-micall.json` | `.162:15432/micall` | `micall.public.outbox_event` |
| `source-misales.json` | `.162:25432/misales` | `misales.public.outbox_event` |
| `source-miqa.json` | `.162:35432/miqa` | `miqa.public.outbox_event` |
| `ch-sink-all.json` | Cả ba topic trên | `.164:18123`, `cdc.outbox_event` |

JSON được gửi nguyên file qua HTTP PUT. `${env:...}` là cú pháp EnvVarConfigProvider có sẵn của Kafka; nó đọc credential đã được Compose truyền vào environment của container `connect`. Không điền password thật vào JSON.

Source snapshot ba ngày gần nhất rồi đọc WAL bằng pgoutput; unwrap đưa các cột outbox ra ngoài envelope. Sink dùng JSON có schema, một task và `topic2TableMap` để gom ba topic về một bảng. ID event phải duy nhất xuyên ba nguồn.

Lệnh đăng ký từng file và giải thích cờ nằm tại `docs/DEPLOYMENT.md`, bước 8 và 9. File JSON trên host và config connector đang chạy là hai trạng thái; sau sửa file cần PUT lại đúng connector.
