\set ON_ERROR_STOP on
\getenv debezium_user DEBEZIUM_USER
\getenv debezium_password DEBEZIUM_PASSWORD
\getenv source_database POSTGRES_DB

CREATE TABLE IF NOT EXISTS public.outbox_event (
  event_id text PRIMARY KEY,
  call_id text NOT NULL,
  version bigint NOT NULL,
  payload jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()   -- thời điểm có múi giờ
);

SELECT format('CREATE ROLE %I', :'debezium_user')  -- tạo role
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = :'debezium_user')
\gexec
ALTER ROLE :"debezium_user" WITH LOGIN REPLICATION PASSWORD :'debezium_password';  -- quyền đọc WAL
GRANT CONNECT ON DATABASE :"source_database" TO :"debezium_user";  -- cho phép vào DB
GRANT USAGE ON SCHEMA public TO :"debezium_user";  -- dùng schema public
GRANT SELECT ON TABLE public.outbox_event TO :"debezium_user";  -- đọc bảng capture

SELECT 'CREATE PUBLICATION outbox_publication FOR TABLE public.outbox_event'  -- publication cho plugin pgoutput
WHERE NOT EXISTS (SELECT FROM pg_publication WHERE pubname = 'outbox_publication')
\gexec
ALTER PUBLICATION outbox_publication SET TABLE public.outbox_event;  -- chỉ phát thay đổi outbox
