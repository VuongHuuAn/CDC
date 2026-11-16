-- Khởi tạo đích CDC: clickhouse-client --multiquery sau khi service healthy
CREATE DATABASE IF NOT EXISTS cdc;  -- schema chung cho ba sink connector

CREATE TABLE IF NOT EXISTS cdc.outbox_event (
  event_id String,  -- khóa dedup (ReplacingMergeTree)
  call_id String,  -- cùng ý nghĩa bảng PostgreSQL
  version Int64,  -- bigint từ nguồn
  payload String,  -- JSON lưu dạng chuỗi
  created_at DateTime64(6, 'UTC')  -- thời gian nguồn, micro giây UTC
)
ENGINE = ReplacingMergeTree  -- gộp bản trùng event_id khi merge
ORDER BY event_id;  -- sort key; đọc đã gộp trùng: SELECT ... FINAL
