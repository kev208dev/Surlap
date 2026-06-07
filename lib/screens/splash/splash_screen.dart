import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// HourSpace 인트로/스플래시 화면.
///
/// 스토리보드(코드 기반, Rive/Lottie 미사용):
///  1) 낙하   — 마스코트가 위에서 부드럽게 떨어짐 (easeOutCubic, 중력감)
///  2) 착지    — 바닥 기준 squash&stretch 1회(또렷) → 살짝 팝 + 주변 스파클 버스트
///  3) 리빌   — 워드마크 "HourSpace"가 아래에서 슬라이드 + 페이드
///  4) 호흡   — 데이터/auth 로딩 동안 위아래 부드러운 보빙 + 글로우 호흡
///
/// 화면 전환/타이밍은 [SplashGate]가 담당(완료 후 페이드 → MainShell).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // 인트로 시퀀스(1회) — 전체 2.6s.
  late final AnimationController _intro;
  // 호흡/보빙 반복.
  late final AnimationController _loop;

  late final Animation<double> _drop; // 낙하: 위 → 제자리
  late final Animation<double> _scaleIn; // 0.86 → 1.0
  late final Animation<double> _land; // 착지 스쿼시 게이트(0→1)
  late final Animation<double> _pop; // 착지 직후 살짝 점프(0→1)
  late final Animation<double> _sparkle; // 스파클 게이트(0→1)
  late final Animation<double> _wordFade;
  late final Animation<double> _wordSlide;
  late final Animation<double> _dotsFade;

  static double _bell(double a) =>
      a <= 0 || a >= 1 ? 0.0 : math.sin(a * math.pi); // 0..1..0

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    // 낙하 — 위에서 부드럽게(중력감), 착지 지점에서 멈춤.
    _drop = Tween<double>(begin: -150, end: 0).animate(CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOutCubic)));
    _scaleIn = Tween<double>(begin: 0.86, end: 1.0).animate(CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.0, 0.34, curve: Curves.easeOut)));
    // 착지 스쿼시 — 낙하 끝과 맞물려 바닥에서 한 번 또렷하게.
    _land = CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.33, 0.55, curve: Curves.easeInOut));
    // 착지 반동으로 살짝 통 튀어오름.
    _pop = CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.52, 0.74, curve: Curves.easeInOut));
    _sparkle = CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.38, 0.80, curve: Curves.easeOut));
    _wordFade = CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.66, 0.92, curve: Curves.easeOut));
    _wordSlide = Tween<double>(begin: 1, end: 0).animate(CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.66, 0.92, curve: Curves.easeOutCubic)));
    _dotsFade = CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.86, 1.0, curve: Curves.easeOut));

    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        // 네이티브 splash 색(#6B3DF9)과 동일 — 첫 프레임 끊김 없이 이어지게.
        backgroundColor: const Color(0xFF6B3DF9),
        body: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF6B3DF9)),
          child: Stack(
            children: [
              Positioned(
                top: -120,
                right: -90,
                child: _SoftCircle(
                    size: 320, color: Colors.white.withValues(alpha: 0.10)),
              ),
              Positioned(
                bottom: -140,
                left: -110,
                child: _SoftCircle(
                    size: 340,
                    color: const Color(0xFF9B6BFF).withValues(alpha: 0.30)),
              ),

              // ── 중앙: 마스코트 + 워드마크 ──
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_intro, _loop]),
                  builder: (context, _) {
                    final done = _intro.isCompleted;
                    final landB = _bell(_land.value); // 0..1..0
                    final popB = _bell(_pop.value); // 0..1..0
                    // 인트로 끝난 뒤 부드러운 호흡(0..1..0 반복).
                    final breathe = done ? _bell(_loop.value) : 0.0;

                    // 착지 스쿼시: 가로 늘고 세로 눌림(바닥 기준).
                    final sx = 1.0 + landB * 0.16 - breathe * 0.02;
                    final sy = 1.0 - landB * 0.18 + breathe * 0.02 + popB * 0.06;
                    // 착지 후 살짝 떠오르는 보빙 + 팝 점프.
                    final bobY = -breathe * 5 - popB * 10;
                    final halo = math.max(landB * 0.7, breathe);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 250,
                          height: 250,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 호흡/착지 글로우 헤일로
                              Container(
                                width: 150 + 38 * halo,
                                height: 150 + 38 * halo,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white
                                          .withValues(alpha: 0.18 + 0.12 * halo),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                              // 착지 스파클 버스트
                              ..._sparkles(_sparkle.value),
                              // 마스코트(낙하 + 보빙 + 스케일 + 바닥 스쿼시)
                              Transform.translate(
                                offset: Offset(0, _drop.value + bobY),
                                child: Transform.scale(
                                  scaleX: _scaleIn.value * sx,
                                  scaleY: _scaleIn.value * sy,
                                  alignment: Alignment.bottomCenter,
                                  child: Image.asset(
                                    'assets/mascot/splash_icon.png',
                                    width: 196,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        // 워드마크
                        Opacity(
                          opacity: _wordFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _wordSlide.value * 10),
                            child: Column(
                              children: [
                                const Text(
                                  'HourSpace',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '나만의 일정 · 시간표 · 위젯',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                    color:
                                        Colors.white.withValues(alpha: 0.72),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ── 하단: 미니멀 로딩 인디케이터 ──
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 64),
                  child: FadeTransition(
                    opacity: _dotsFade,
                    child: const _LoadingDots(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 착지 순간 마스코트 주변으로 톡톡 터지는 스파클 7개.
  List<Widget> _sparkles(double s) {
    if (s <= 0 || s >= 1) return const [];
    const n = 7;
    return List.generate(n, (i) {
      // 위상차로 또르르 순차 팝.
      final t = ((s * 1.3) - i * 0.05).clamp(0.0, 1.0);
      final pop = _bell(t);
      if (pop <= 0) return const SizedBox.shrink();
      final ang = (i / n) * 2 * math.pi - math.pi / 2;
      final dist = 86.0 * (0.55 + 0.55 * t);
      return Transform.translate(
        offset: Offset(math.cos(ang) * dist, math.sin(ang) * dist),
        child: Opacity(
          opacity: pop.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.3 + pop * 1.1,
            child: Icon(
              i.isEven ? Icons.star_rounded : Icons.circle,
              size: i.isEven ? 15 : 7,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ),
      );
    });
  }
}

/// 흐릿한 원형 글로우(배경 깊이감).
class _SoftCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _SoftCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}

/// 점 3개 pulsing 로더 — 기본 애니메이션만 사용한 미니멀 인디케이터.
class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_c.value + i * 0.18) % 1.0;
            final t = (math.sin(phase * 2 * math.pi) + 1) / 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: 0.75 + 0.45 * t,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.35 + 0.55 * t),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
