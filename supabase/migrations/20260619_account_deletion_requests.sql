-- account_deletion_requests — Play Console 데이터 삭제 URL 의 Edge Function 이
-- 적재하는 큐. 운영자가 status='pending' 인 행을 정기적으로 처리.
create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  status text not null default 'pending'
    check (status in ('pending','processed','failed'))
);

create index if not exists account_deletion_requests_email_idx
  on public.account_deletion_requests (email);

alter table public.account_deletion_requests enable row level security;

-- 익명/일반 사용자는 접근 금지. Edge Function 의 service_role 만 RLS 우회로 insert.
revoke all on public.account_deletion_requests from anon, authenticated;
