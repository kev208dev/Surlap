-- 회원 탈퇴 RPC.
-- 클라이언트(앱)에서 supabase.rpc('delete_account') 로 호출.
-- 현재 로그인 사용자(auth.uid())의 auth 계정을 삭제한다.
-- user_data / events / themes 등 사용자 소유 테이블이 auth.users(id) 를
-- ON DELETE CASCADE 로 참조하면 연결 데이터도 함께 삭제된다.
-- (참조가 cascade 가 아니라면 아래 주석 블록처럼 명시적으로 삭제할 것)

create or replace function public.delete_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not authenticated';
  end if;

  -- 소유 데이터 명시 삭제(테이블/컬럼명은 실제 스키마에 맞게 조정).
  -- delete from public.events       where user_id = uid;
  -- delete from public.user_data    where user_id = uid;
  -- delete from public.themes       where user_id = uid;

  -- auth 사용자 삭제(연결 FK 가 cascade 면 소유 데이터도 함께 삭제).
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;
