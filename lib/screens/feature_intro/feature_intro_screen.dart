import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../widgets/mascot/mascot.dart';

/// 주요 기능 소개 — 대형 앱 스타일 풀스크린 캐러셀.
/// 각 페이지에 실제 앱 UI를 닮은 미니 목업을 보여준다.
Future<void> showFeatureIntro(BuildContext context) =>
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, _, _) => const FeatureIntroScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );

enum _Mock { calendar, timetable, tracker, share, sports, start }

class _Feature {
  final Color c1, c2;
  final String title;
  final String desc;
  final _Mock mock;
  const _Feature({
    required this.c1,
    required this.c2,
    required this.title,
    required this.desc,
    required this.mock,
  });
}

const _features = <_Feature>[
  _Feature(
    c1: Color(0xFF6B3DF9),
    c2: Color(0xFF9B6BFF),
    title: '일정을 한눈에',
    desc: '월·주·일을 자유롭게 오가며, 흩어진 일정을 색으로 구분해 한눈에 정리해요.',
    mock: _Mock.calendar,
  ),
  _Feature(
    c1: Color(0xFF14B8C4),
    c2: Color(0xFF35B97A),
    title: '시간표도 자동으로',
    desc: '학교만 연결하면 NEIS 시간표와 급식 메뉴가 스케줄표에 자동으로 채워져요.',
    mock: _Mock.timetable,
  ),
  _Feature(
    c1: Color(0xFFF2A33C),
    c2: Color(0xFFEC6AA8),
    title: '매일을 기록해요',
    desc: '공부·독서·운동을 기간 단위로 트래킹. 달력 셀에 이모지와 숫자로 한눈에 보여요.',
    mock: _Mock.tracker,
  ),
  _Feature(
    c1: Color(0xFF4F8DFD),
    c2: Color(0xFF6B3DF9),
    title: '함께 보는 캘린더',
    desc: '공유 코드로 일정을 나누면, 추가·수정이 구독자에게 실시간으로 반영돼요.',
    mock: _Mock.share,
  ),
  _Feature(
    c1: Color(0xFF35B97A),
    c2: Color(0xFF4F8DFD),
    title: '좋아하는 팀 경기까지',
    desc: '팀·대회를 구독하면 경기 일정이 색으로 캘린더에 자동으로 표시돼요.',
    mock: _Mock.sports,
  ),
  _Feature(
    c1: Color(0xFF6B3DF9),
    c2: Color(0xFF9B6BFF),
    title: '이제 시작해요',
    desc: '당신의 하루를 더 단순하고 단단하게. HourSpace와 함께해요.',
    mock: _Mock.start,
  ),
];

class FeatureIntroScreen extends StatefulWidget {
  const FeatureIntroScreen({super.key});
  @override
  State<FeatureIntroScreen> createState() => _FeatureIntroScreenState();
}

class _FeatureIntroScreenState extends State<FeatureIntroScreen> {
  final _pc = PageController();
  double _pageVal = 0;
  int get _page => _pageVal.round();

  @override
  void initState() {
    super.initState();
    _pc.addListener(() => setState(() => _pageVal = _pc.page ?? 0));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_page >= _features.length - 1) {
      Navigator.of(context).maybePop();
    } else {
      _pc.nextPage(
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final last = _page >= _features.length - 1;

    return Scaffold(
      backgroundColor: sh.bg,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: last ? 0 : 1,
                  child: TextButton(
                    onPressed:
                        last ? null : () => Navigator.of(context).maybePop(),
                    child: Text('건너뛰기',
                        style: AppType.body.copyWith(
                            fontWeight: FontWeight.w700, color: sh.inkSoft)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: _features.length,
                itemBuilder: (_, i) => _FeaturePage(
                  feature: _features[i],
                  offset: _pageVal - i,
                  sh: sh,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.xl, 8, Gap.xl, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_features.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active
                              ? sh.accent
                              : sh.ink.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: sh.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: _next,
                      child: Text(last ? '시작하기' : '다음',
                          style: const TextStyle(
                              fontSize: 16.5, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePage extends StatelessWidget {
  final _Feature feature;
  final double offset;
  final SpaceHourColors sh;
  const _FeaturePage(
      {required this.feature, required this.offset, required this.sh});

  @override
  Widget build(BuildContext context) {
    final p = offset.clamp(-1.0, 1.0);
    final heroDx = -p * 46;
    final scale = (1 - p.abs() * 0.07).clamp(0.0, 1.0);
    final contentDy = p.abs() * 18;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.xl, 6, Gap.xl, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [feature.c1, feature.c2],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: feature.c1.withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned(
                    top: -50,
                    right: -40,
                    child: _circle(150, Colors.white.withValues(alpha: 0.12)),
                  ),
                  Positioned(
                    bottom: -60,
                    left: -50,
                    child: _circle(180, Colors.white.withValues(alpha: 0.08)),
                  ),
                  // 중앙: 실제 UI 미니 목업 (패럴랙스)
                  Center(
                    child: Transform.translate(
                      offset: Offset(heroDx, 0),
                      child: Transform.scale(
                        scale: scale,
                        child: _mock(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          Transform.translate(
            offset: Offset(0, contentDy),
            child: Opacity(
              opacity: (1 - p.abs() * 0.7).clamp(0.0, 1.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(feature.title,
                      style: AppType.title.copyWith(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                          color: sh.ink)),
                  const SizedBox(height: 12),
                  Text(feature.desc,
                      style: AppType.body.copyWith(
                          fontSize: 15.5, height: 1.5, color: sh.inkSoft)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _circle(double s, Color c) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [c, c.withValues(alpha: 0)]),
        ),
      );

  Widget _mock() {
    switch (feature.mock) {
      case _Mock.start:
        return const MascotView(
            expression: MascotExpression.cheering, size: 168);
      case _Mock.calendar:
        return _MockCard(child: _calendarMock());
      case _Mock.timetable:
        return _MockCard(child: _timetableMock());
      case _Mock.tracker:
        return _MockCard(child: _trackerMock());
      case _Mock.share:
        return _MockCard(child: _shareMock());
      case _Mock.sports:
        return _MockCard(child: _sportsMock());
    }
  }

  // ── 미니 캘린더 ──
  Widget _calendarMock() {
    const ink = Color(0xFF2B2540);
    const faint = Color(0xFF9A93B0);
    final bars = {
      3: const Color(0xFF6B3DF9),
      4: const Color(0xFFE8943A),
      9: const Color(0xFF35B97A),
      12: const Color(0xFF6B3DF9),
      15: const Color(0xFFEC6AA8),
      16: const Color(0xFF4F8DFD),
      22: const Color(0xFF35B97A),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          const Text('6월',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w900, color: ink)),
          const Spacer(),
          Icon(Icons.chevron_left_rounded, size: 16, color: faint),
          Icon(Icons.chevron_right_rounded, size: 16, color: faint),
        ]),
        const SizedBox(height: 8),
        Row(
          children: ['일', '월', '화', '수', '목', '금', '토']
              .map((d) => Expanded(
                  child: Center(
                      child: Text(d,
                          style: const TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: faint)))))
              .toList(),
        ),
        const SizedBox(height: 4),
        ...List.generate(4, (r) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: List.generate(7, (c) {
                final day = r * 7 + c + 1;
                final bar = bars[day];
                return Expanded(
                  child: Column(
                    children: [
                      Text('$day',
                          style: const TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: ink)),
                      const SizedBox(height: 2),
                      Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: bar ?? Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  // ── 미니 시간표 ──
  Widget _timetableMock() {
    const ink = Color(0xFF2B2540);
    const purple = Color(0xFF6B3DF9);
    Widget block(String s, [Color c = purple]) => Expanded(
          child: Container(
            height: 26,
            margin: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(s,
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w800, color: c)),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: ['월', '화', '수', '목']
              .map((d) => Expanded(
                  child: Center(
                      child: Text(d,
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: ink)))))
              .toList(),
        ),
        const SizedBox(height: 4),
        Row(children: [block('국어'), block('수학'), block('영어'), block('과학')]),
        Row(children: [block('수학'), block('체육'), block('국어'), block('미술')]),
        Row(children: [
          Expanded(
            child: Container(
              height: 24,
              margin: const EdgeInsets.all(2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE8943A).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🍱 급식',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB46A1E))),
                ],
              ),
            ),
          ),
        ]),
      ],
    );
  }

  // ── 기록 트래커 ──
  Widget _trackerMock() {
    const ink = Color(0xFF2B2540);
    const accent = Color(0xFF6B3DF9);
    Widget tag(String t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
              color: accent, borderRadius: BorderRadius.circular(20)),
          child: Text(t,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.menu_book_rounded, size: 18, color: accent),
          SizedBox(width: 6),
          Text('공부 트래커',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w900, color: ink)),
        ]),
        const SizedBox(height: 10),
        const Row(crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('4.5',
                style: TextStyle(
                    fontSize: 34, fontWeight: FontWeight.w900, color: accent)),
            SizedBox(width: 3),
            Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: Text('시간',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: ink)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(children: [tag('수학'), const SizedBox(width: 6), tag('영어')]),
        const SizedBox(height: 12),
        // 달력 셀 미리보기
        Row(
          children: List.generate(5, (i) {
            final on = i == 1 || i == 2 || i == 4;
            return Expanded(
              child: Container(
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on
                      ? accent.withValues(alpha: 0.08)
                      : const Color(0xFFF0EEF6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(on ? '📚' : '',
                    style: const TextStyle(fontSize: 12)),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── 공유 코드 ──
  Widget _shareMock() {
    const ink = Color(0xFF2B2540);
    const accent = Color(0xFF4F8DFD);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('공유 코드',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9A93B0))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: const Color(0xFFF0EEF6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('T7K2QX',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      fontFamily: 'monospace',
                      color: ink)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: accent, borderRadius: BorderRadius.circular(10)),
            child: const Row(children: [
              Icon(Icons.copy_rounded, size: 14, color: Colors.white),
              SizedBox(width: 4),
              Text('복사',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF35B97A).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(children: [
            Icon(Icons.sync_rounded, size: 14, color: Color(0xFF2E9E68)),
            SizedBox(width: 6),
            Text('실시간 동기화 중',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E9E68))),
          ]),
        ),
      ],
    );
  }

  // ── 스포츠 ──
  Widget _sportsMock() {
    const ink = Color(0xFF2B2540);
    const orange = Color(0xFFE8943A);
    Widget chip(String t, Color c, bool on) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: on ? c.withValues(alpha: 0.14) : const Color(0xFFF0EEF6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: on ? c.withValues(alpha: 0.4) : Colors.transparent),
          ),
          child: Row(children: [
            Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(t,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: on ? c : const Color(0xFF9A93B0))),
          ]),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          chip('⚽ 토트넘', orange, true),
          chip('🏀 NBA', const Color(0xFF4F8DFD), false),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: orange, width: 3)),
          ),
          child: const Row(children: [
            Text('22:00  ',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800, color: orange)),
            Expanded(
              child: Text('토트넘 vs 아스널',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: ink)),
            ),
          ]),
        ),
      ],
    );
  }
}

/// 흰 카드(폰 화면처럼) — 컬러 그라데이션 위에 떠 있는 미리보기.
class _MockCard extends StatelessWidget {
  final Widget child;
  const _MockCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}
