// Surlap — 계정 삭제 요청 처리 Edge Function.
// Play Console "데이터 보안 → 데이터 삭제 URL" 에 등록.
// GET  : 사용자에게 안내 + 이메일 입력 폼 HTML.
// POST : { email } → account_deletion_requests 테이블에 큐로 적재.
// 배포: supabase functions deploy account-delete-request --no-verify-jwt
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const HTML = `<!doctype html>
<html lang="ko"><head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Surlap 계정 삭제 요청</title>
<style>
body{font-family:-apple-system,BlinkMacSystemFont,'Pretendard',sans-serif;background:#FBF9FE;color:#14131A;margin:0;padding:24px;display:flex;justify-content:center}
.card{max-width:520px;width:100%;background:#fff;border-radius:24px;padding:28px;box-shadow:0 20px 44px -16px rgba(74,31,208,.18)}
h1{font-size:22px;font-weight:800;letter-spacing:-.4px;margin:0 0 8px}
p{color:#6E6B7A;line-height:1.55;font-size:14.5px;margin:6px 0}
label{display:block;font-size:13px;color:#6E6B7A;font-weight:700;margin-top:18px}
input{display:block;width:100%;box-sizing:border-box;height:48px;padding:0 14px;border:1px solid rgba(20,19,26,.08);border-radius:12px;font-size:15px;margin-top:6px;background:#F6F4FA}
button{margin-top:18px;background:#5A2DF4;color:#fff;border:0;height:50px;border-radius:14px;font-weight:800;font-size:15px;width:100%;cursor:pointer}
.note{background:#EDE8FD;color:#4A1FD0;padding:12px 14px;border-radius:12px;font-size:13px;margin-top:14px}
.ok{background:#E7F8EC;color:#1F7A33;padding:12px 14px;border-radius:12px;margin-top:14px;display:none}
</style></head><body><div class="card">
<h1>Surlap 계정 / 데이터 삭제 요청</h1>
<p>가입에 사용한 이메일을 입력하면 30일 안에 계정·일정·할 일·테마·생일·시간표 등 모든 사용자 데이터가 영구 삭제됩니다. 백업·로그 보관본도 90일 안에 제거됩니다.</p>
<p>처리 결과는 같은 이메일로 안내드립니다. 처리 완료 후에는 복구 불가합니다.</p>
<form id="f">
<label for="email">이메일</label>
<input id="email" name="email" type="email" required placeholder="you@example.com"/>
<button type="submit">삭제 요청 보내기</button>
</form>
<div id="ok" class="ok">접수되었습니다. 30일 안에 처리됩니다.</div>
<div class="note">앱 안에서 직접 삭제하려면: 프로필 → 설정 → 계정 → 계정 삭제. 로그인 상태에서 즉시 처리됩니다.</div>
</div>
<script>
document.getElementById('f').addEventListener('submit', async (e) => {
  e.preventDefault();
  const email = document.getElementById('email').value.trim();
  if (!email) return;
  const r = await fetch(location.pathname, { method:'POST', headers:{'content-type':'application/json'}, body: JSON.stringify({email}) });
  if (r.ok) { document.getElementById('f').style.display='none'; document.getElementById('ok').style.display='block'; }
  else { alert('요청 실패: ' + (await r.text())); }
});
</script></body></html>`;

Deno.serve(async (req: Request) => {
  if (req.method === "GET") {
    return new Response(HTML, { headers: { "content-type": "text/html; charset=utf-8" } });
  }
  if (req.method !== "POST") {
    return new Response("method not allowed", { status: 405 });
  }
  let body: { email?: string } = {};
  try { body = await req.json(); } catch { /* ignore */ }
  const email = (body.email ?? "").trim().toLowerCase();
  if (!email || !email.includes("@")) {
    return new Response("invalid email", { status: 400 });
  }
  const sb = createClient(SUPABASE_URL, SERVICE_ROLE);
  const { error } = await sb.from("account_deletion_requests").insert({ email });
  if (error) {
    console.error("insert failed:", error.message);
  }
  return new Response(JSON.stringify({ ok: true }), {
    headers: { "content-type": "application/json" },
  });
});
