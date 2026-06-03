import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../supabase/auth_service.dart';
import 'login_modal.dart';

/// 첫 진입 로그인 — 바닥 시트가 아니라 화면 중앙에 떠 있는 floating modal.
/// 배경 blur + dim, 가운데 rounded card.
Future<void> showLoginDialog(BuildContext context) => showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'login',
      barrierColor: Colors.transparent, // 자체 dim/blur 사용
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => const _LoginDialog(),
      transitionBuilder: (_, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        child: child,
      ),
    );

class _LoginDialog extends ConsumerStatefulWidget {
  const _LoginDialog();

  @override
  ConsumerState<_LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends ConsumerState<_LoginDialog> {
  bool _loading = false;

  Future<void> _google() async {
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).signInGoogle();
      // OAuth 리다이렉트 — 성공 시 onAuthStateChange로 상태 갱신.
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('로그인 오류: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final w = MediaQuery.of(context).size.width;
    final cardW = (w - 40).clamp(0.0, 360.0);

    return Stack(
      children: [
        // dim + blur 배경 (탭하면 닫힘)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.32)),
            ),
          ),
        ),
        // 중앙 카드
        Center(
          child: SizedBox(
            width: cardW,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 44,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/logo.png',
                        height: 44, fit: BoxFit.contain),
                    const SizedBox(height: 14),
                    Text('HourSpace에 로그인',
                        style: AppType.title.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF15151A))),
                    const SizedBox(height: 6),
                    Text('내 일정과 설정을 안전하게 동기화해요',
                        textAlign: TextAlign.center,
                        style: AppType.body.copyWith(
                            fontSize: 13,
                            color: Colors.black.withValues(alpha: 0.45))),
                    const SizedBox(height: 22),
                    // Google 로그인
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _loading ? null : _google,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF15151A),
                          side: BorderSide(
                              color: Colors.black.withValues(alpha: 0.08)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const _GoogleG(size: 18),
                                  const SizedBox(width: 10),
                                  Text('Google로 계속하기',
                                      style: AppType.body.copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 아이디로 로그인 (기존 폼)
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.pop(context);
                              showLoginModal(context);
                            },
                      child: Text('아이디로 로그인',
                          style: AppType.body.copyWith(
                              fontWeight: FontWeight.w600, color: sh.accent)),
                    ),
                    // 나중에 하기
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('나중에 하기',
                          style: AppType.label.copyWith(
                              fontSize: 13,
                              color: Colors.black.withValues(alpha: 0.4))),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 깔끔한 Google "G" 아이콘 (4색) ──────────────────────────────
class _GoogleG extends StatelessWidget {
  final double size;
  const _GoogleG({required this.size});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _GoogleGPainter());
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Rect.fromLTWH(s * 0.06, s * 0.06, s * 0.88, s * 0.88);
    final sw = s * 0.20;
    Paint p(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;
    // 빨강(상단 왼쪽) → 노랑(왼쪽) → 초록(하단) → 파랑(오른쪽)
    canvas.drawArc(rect, -0.35, -1.25, false, p(const Color(0xFFEA4335)));
    canvas.drawArc(rect, -1.6, -1.5, false, p(const Color(0xFFFBBC05)));
    canvas.drawArc(rect, 3.14, 1.45, false, p(const Color(0xFF34A853)));
    canvas.drawArc(rect, 1.5, 1.0, false, p(const Color(0xFF4285F4)));
    // 가로 막대(파랑) — G의 안쪽 바
    final bar = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(s * 0.52, s * 0.5), Offset(s * 0.92, s * 0.5), bar);
  }

  @override
  bool shouldRepaint(_GoogleGPainter old) => false;
}
