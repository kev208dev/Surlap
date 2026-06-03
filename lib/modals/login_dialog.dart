import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../supabase/auth_service.dart';
import 'login_modal.dart';

const _deepInk = Color(0xFF15151A);

/// 첫 진입 로그인 — 바닥 시트가 아니라 화면 중앙에 떠 있는 floating modal.
/// 배경 blur + dim, 가운데 공중에 뜬 rounded card (iOS 첫 진입 화면 톤).
Future<void> showLoginDialog(BuildContext context) => showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'login',
      barrierColor: Colors.transparent, // 자체 dim/blur 사용
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, _, _) => const _LoginDialog(),
      transitionBuilder: (_, anim, _, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          // 살짝 떠오르며 등장 — 공중에 뜨는 느낌 강화.
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
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
      // OAuth 리다이렉트 — 성공 시 onAuthStateChange로 상태 갱신되고
      // 아래 ref.listen이 모달을 자동으로 닫는다.
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인에 실패했어요. 잠시 후 다시 시도해주세요')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final w = MediaQuery.of(context).size.width;
    final cardW = (w - 48).clamp(0.0, 360.0); // 좌우 margin 24

    // 로그인 성공(세션 확보) 시 모달 자동 닫기.
    ref.listen<dynamic>(authProvider, (prev, next) {
      if (next != null && mounted) {
        Navigator.of(context).pop();
      }
    });

    return Stack(
      children: [
        // ── dim + blur 배경 (탭하면 닫힘) ──
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _loading ? null : () => Navigator.pop(context),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.22)),
            ),
          ),
        ),
        // ── 중앙 floating 카드 ──
        Center(
          child: SizedBox(
            width: cardW,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.70), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 48,
                      offset: const Offset(0, 24),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── 로고 (연한 브랜드 배경 위) ──
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EFFF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 34,
                        height: 34,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ── 제목 ──
                    const Text(
                      'HourSpace에 로그인',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: _deepInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ── 부제 ──
                    Text(
                      '내 일정과 설정을 안전하게 동기화해요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        color: Colors.black.withValues(alpha: 0.48),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // ── Google 로그인 (아이콘 없는 깔끔한 버튼) ──
                    _PrimaryButton(
                      label: 'Google로 계속하기',
                      loading: _loading,
                      onTap: _loading ? null : _google,
                    ),
                    const SizedBox(height: 14),
                    // ── 아이디로 로그인 (보조 액션) ──
                    SizedBox(
                      height: 44,
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : () {
                                Navigator.pop(context);
                                // 곧장 아이디·비번 폼으로(Google 선택 화면 건너뜀).
                                showLoginModal(context, startWithForm: true);
                              },
                        style: TextButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          '아이디로 로그인',
                          style: AppType.body.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: sh.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // ── 나중에 하기 (약한 tertiary 액션) ──
                    SizedBox(
                      height: 40,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(double.infinity, 40),
                        ),
                        child: Text(
                          '나중에 하기',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withValues(alpha: 0.32),
                          ),
                        ),
                      ),
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

// ─── 1차 액션 버튼 (흰 배경 + 부드러운 그림자) ────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        shadowColor: Colors.black.withValues(alpha: 0.04),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: Colors.black.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _deepInk),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _deepInk,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
