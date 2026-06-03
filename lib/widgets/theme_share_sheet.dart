import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';

/// 테마 공유 — 화면 아래에서 올라오는 floating bottom sheet.
/// 설정 시트와 동일한 디자인 언어(dim+blur 배경, 둥근 surface, 카드 섹션).
Future<void> showThemeShareSheet(BuildContext context) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent, // 자체 dim/blur 사용
      builder: (_) => const ThemeShareSheet(),
    );

class ThemeShareSheet extends StatelessWidget {
  const ThemeShareSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return SizedBox(
      height: h,
      child: Stack(
        children: [
          // dim + 약한 blur 배경 (탭하면 닫힘)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: _ShareSheetBody(),
          ),
        ],
      ),
    );
  }
}

class _ShareSheetBody extends StatelessWidget {
  const _ShareSheetBody();

  // 추천 프리셋 데이터
  static const _presets = [
    (name: 'Space Purple',
        colors: [Color(0xFF5A2DF4), Color(0xFFF3EFFF), Color(0xFF15151A)]),
    (name: 'Warm Sand',
        colors: [Color(0xFFE7B980), Color(0xFFFFF7ED), Color(0xFF2B2118)]),
    (name: 'Midnight',
        colors: [Color(0xFF111827), Color(0xFF374151), Color(0xFF8B5CF6)]),
  ];

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final h = MediaQuery.of(context).size.height;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.md),
        constraints: BoxConstraints(maxHeight: h * 0.86),
        decoration: BoxDecoration(
          color: sh.bg,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // grab handle
            Container(
              width: 42,
              height: 5,
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              decoration: BoxDecoration(
                color: sh.ink.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('테마 공유',
                            style: AppType.title.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: sh.ink)),
                        const SizedBox(height: 2),
                        Text('내 캘린더 스타일을 저장하고 공유해요',
                            style: AppType.label.copyWith(
                                fontSize: 13, color: sh.inkSoft)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: sh.inkSoft),
                  ),
                ],
              ),
            ),
            // 본문
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 현재 테마 ──
                    _Section(
                      sh: sh,
                      title: '현재 테마',
                      child: Row(
                        children: [
                          const _MiniThemePreview(),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Space Purple',
                                    style: AppType.body.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: sh.ink)),
                                const SizedBox(height: 4),
                                Text('연보라 배경 · 보라색 포인트 · 글래스 하단바',
                                    style: AppType.label.copyWith(
                                        fontSize: 12,
                                        height: 1.4,
                                        color: sh.inkSoft)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── 빠른 액션 ──
                    Row(
                      children: [
                        Expanded(
                          child: ThemeShareAction(
                            sh: sh,
                            icon: Icons.bookmark_add_outlined,
                            label: '테마 저장',
                            solid: true,
                            onTap: () => _snack(context, '현재 테마를 저장했어요'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ThemeShareAction(
                            sh: sh,
                            icon: Icons.ios_share_rounded,
                            label: '테마 공유',
                            solid: false,
                            onTap: () =>
                                _snack(context, '테마 공유 기능은 곧 제공돼요'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ThemeShareAction(
                            sh: sh,
                            icon: Icons.download_rounded,
                            label: '불러오기',
                            solid: false,
                            onTap: () =>
                                _snack(context, '테마 불러오기 기능은 곧 제공돼요'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── 추천 테마 ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                      child: Text('추천 테마',
                          style: AppType.label.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: sh.ink.withValues(alpha: 0.42))),
                    ),
                    SizedBox(
                      height: 104,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        itemCount: _presets.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final p = _presets[i];
                          return ThemePresetCard(
                            sh: sh,
                            name: p.name,
                            colors: p.colors,
                            onTap: () =>
                                _snack(context, "'${p.name}' 테마는 곧 적용할 수 있어요"),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }
}

// ─── 섹션 카드 ───────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final SpaceHourColors sh;
  final String title;
  final Widget child;
  const _Section({required this.sh, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
          child: Text(title,
              style: AppType.label.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: sh.ink.withValues(alpha: 0.42))),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: sh.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: sh.ink.withValues(alpha: 0.04)),
          ),
          child: child,
        ),
      ],
    );
  }
}

// ─── 미니 캘린더 미리보기 ────────────────────────────────────────
class _MiniThemePreview extends StatelessWidget {
  const _MiniThemePreview();

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return Container(
      width: 96,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: sh.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sh.ink.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('6월',
              style: AppType.label.copyWith(
                  fontSize: 10, fontWeight: FontWeight.w700, color: sh.ink)),
          const SizedBox(height: 4),
          // 요일 점
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              7,
              (i) => Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: sh.ink.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // 날짜 1~7 (3은 브랜드 원)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day = i + 1;
              final isToday = day == 3;
              return Container(
                width: 11,
                height: 11,
                alignment: Alignment.center,
                decoration: isToday
                    ? BoxDecoration(color: sh.accent, shape: BoxShape.circle)
                    : null,
                child: Text('$day',
                    style: TextStyle(
                        fontSize: 7,
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isToday ? Colors.white : sh.inkSoft)),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── 빠른 액션 버튼 ──────────────────────────────────────────────
class ThemeShareAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool solid;
  final VoidCallback onTap;
  final SpaceHourColors sh;

  const ThemeShareAction({
    super.key,
    required this.icon,
    required this.label,
    required this.solid,
    required this.onTap,
    required this.sh,
  });

  @override
  Widget build(BuildContext context) {
    final fg = solid ? Colors.white : sh.ink;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: solid ? sh.accent : sh.card,
          borderRadius: BorderRadius.circular(16),
          border: solid
              ? null
              : Border.all(color: sh.ink.withValues(alpha: 0.06)),
          boxShadow: solid
              ? [
                  BoxShadow(
                    color: sh.accent.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(height: 6),
            Text(label,
                style: AppType.label.copyWith(
                    fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }
}

// ─── 추천 테마 프리셋 카드 ───────────────────────────────────────
class ThemePresetCard extends StatelessWidget {
  final String name;
  final List<Color> colors;
  final VoidCallback onTap;
  final SpaceHourColors sh;

  const ThemePresetCard({
    super.key,
    required this.name,
    required this.colors,
    required this.onTap,
    required this.sh,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sh.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: sh.ink.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 색상 원 3개
            Row(
              children: [
                for (int i = 0; i < colors.length; i++)
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: colors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: sh.ink.withValues(alpha: 0.06), width: 1),
                    ),
                  ),
              ],
            ),
            Text(name,
                style: AppType.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: sh.ink)),
          ],
        ),
      ),
    );
  }
}
