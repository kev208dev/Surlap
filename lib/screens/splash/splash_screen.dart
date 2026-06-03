import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// HourSpace 브랜드 스플래시/로딩 화면.
///
/// 보라색 gradient 위에 로고가 fade + scale + slight slide 로 부드럽게 등장하고,
/// 하단에 미니멀한 pulsing dots 로더가 표시된다. 데이터/auth 로딩은 [SplashGate]
/// 가 담당하고, 이 위젯은 순수하게 비주얼만 그린다. (Rive/Lottie 미사용 — 기본
/// Flutter 애니메이션만 사용)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // 로고/워드마크 등장(1회)
  late final AnimationController _intro;
  // 글로우 호흡(반복)
  late final AnimationController _loop;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _wordFade;
  late final Animation<double> _dotsFade;

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _logoFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.70, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic));
    _wordFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );
    _dotsFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.60, 1.0, curve: Curves.easeOut),
    );

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
        statusBarIconBrightness: Brightness.light, // 어두운 보라 배경 → 밝은 아이콘
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF5A2DF4),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5A2DF4), Color(0xFF7C4DFF)],
            ),
          ),
          child: Stack(
            children: [
              // 깊이감을 위한 은은한 상단 글로우(고정).
              Positioned(
                top: -120,
                right: -90,
                child: _SoftCircle(
                  size: 320,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              Positioned(
                bottom: -140,
                left: -110,
                child: _SoftCircle(
                  size: 340,
                  color: const Color(0xFF9B6BFF).withValues(alpha: 0.30),
                ),
              ),

              // ── 중앙: 로고 + 워드마크 ──
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _logoFade,
                      child: SlideTransition(
                        position: _logoSlide,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: _LogoMark(loop: _loop),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeTransition(
                      opacity: _wordFade,
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
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
}

/// 로고 — 흰 라운드 타일(앱 아이콘 톤) + 뒤에서 호흡하는 soft glow.
class _LogoMark extends StatelessWidget {
  final Animation<double> loop;
  const _LogoMark({required this.loop});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 호흡하는 글로우
          AnimatedBuilder(
            animation: loop,
            builder: (_, _) {
              final t = Curves.easeInOut.transform(loop.value);
              return Container(
                width: 150 + 30 * t,
                height: 150 + 30 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.22 + 0.10 * t),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              );
            },
          ),
          // 흰 라운드 타일 + 로고
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3A1A9E).withValues(alpha: 0.35),
                  blurRadius: 38,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.30),
                  blurRadius: 24,
                  spreadRadius: -6,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
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
            // 점마다 위상차를 줘서 물결처럼 pulse.
            final phase = (_c.value + i * 0.18) % 1.0;
            final t = (math.sin(phase * 2 * math.pi) + 1) / 2; // 0..1
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
