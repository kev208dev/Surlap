import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../providers/settings_provider.dart';
import '../providers/themes_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/birthdays_provider.dart';
import '../utils/vcf_parser.dart';
import '../modals/neis_setup_modal.dart';
import '../modals/timetable_template_modal.dart';
import 'coach_mark.dart';

/// 설정 · 보기 옵션 — 화면 아래에서 올라오는 floating bottom sheet.
/// 뒤 배경은 dim + 약한 blur, 시트는 둥근 surface로 떠 있는 느낌.
Future<void> showCalendarSettingsSheet(BuildContext context) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // 자체 dim/blur를 그리므로 기본 barrier는 투명.
      barrierColor: Colors.transparent,
      builder: (_) => const CalendarSettingsSheet(),
    );

class CalendarSettingsSheet extends StatelessWidget {
  const CalendarSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return SizedBox(
      height: h,
      child: Stack(
        children: [
          // ── dim + 약한 blur 배경 (탭하면 닫힘) ──
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.28),
                ),
              ),
            ),
          ),
          // ── 떠 있는 설정 시트 ──
          const Align(
            alignment: Alignment.bottomCenter,
            child: _SheetBody(),
          ),
        ],
      ),
    );
  }
}

class _SheetBody extends ConsumerWidget {
  const _SheetBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final h = MediaQuery.of(context).size.height;

    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final themes = ref.watch(themesProvider);
    final hidden = ref.watch(filterProvider);
    final birthdays = ref.watch(birthdaysProvider);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.md),
        constraints: BoxConstraints(maxHeight: h * 0.86),
        decoration: BoxDecoration(
          color: sh.bg, // appSurface — 완전 흰색보다 부드러운 톤
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
                children: [
                  Expanded(
                    child: Text(
                      '보기 설정',
                      style: AppType.title.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: sh.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: sh.inkSoft),
                  ),
                ],
              ),
            ),
            // 본문 (스크롤)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 카테고리 ──
                    _SectionCard(
                      sh: sh,
                      title: '카테고리',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          CategoryFilterChip(
                            label: '전체',
                            color: sh.inkSoft,
                            selected: hidden.isEmpty,
                            sh: sh,
                            onTap: () {
                              final f = ref.read(filterProvider.notifier);
                              if (hidden.isEmpty) {
                                f.setAll(themes.map((t) => t.id).toList());
                              } else {
                                f.clear();
                              }
                            },
                          ),
                          ...themes.map((t) => CategoryFilterChip(
                                label: t.name,
                                color: t.colorValue,
                                selected: !hidden.contains(t.id),
                                sh: sh,
                                onTap: () => ref
                                    .read(filterProvider.notifier)
                                    .toggle(t.id),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── 보기 옵션 ──
                    _SectionCard(
                      sh: sh,
                      title: '보기 옵션',
                      child: Column(
                        children: [
                          SettingsRow(
                            sh: sh,
                            icon: Icons.history_rounded,
                            title: '지난 날 표시',
                            trailing: _IosSwitch(
                              value: settings.showPast,
                              onChanged: notifier.setShowPast,
                              sh: sh,
                            ),
                          ),
                          SettingsRow(
                            sh: sh,
                            icon: Icons.notifications_outlined,
                            title: '알림',
                            trailing: _IosSwitch(
                              value: settings.notifyEnabled,
                              onChanged: notifier.setNotify,
                              sh: sh,
                            ),
                          ),
                          SettingsRow(
                            sh: sh,
                            icon: Icons.view_stream_outlined,
                            title: '연속 보기',
                            trailing: _IosSwitch(
                              value: settings.continuousView,
                              onChanged: notifier.setContinuousView,
                              sh: sh,
                            ),
                          ),
                          SettingsRow(
                            sh: sh,
                            icon: Icons.calendar_today_outlined,
                            title: '주 시작일',
                            trailing: _WeekStartPill(
                              dow: settings.weekStartDow,
                              onSelected: notifier.setWeekStart,
                              sh: sh,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── 더보기 ──
                    _SectionCard(
                      sh: sh,
                      title: '더보기',
                      child: Column(
                        children: [
                          SettingsRow(
                            sh: sh,
                            icon: Icons.lightbulb_outline_rounded,
                            title: '사용법 안내',
                            onTap: () {
                              final rootCtx = Navigator.of(context,
                                      rootNavigator: true)
                                  .context;
                              Navigator.pop(context);
                              WidgetsBinding.instance.addPostFrameCallback(
                                  (_) => showCoachMarks(rootCtx));
                            },
                          ),
                          SettingsRow(
                            sh: sh,
                            icon: Icons.grid_view_rounded,
                            title: '반복 시간표 설정',
                            onTap: () {
                              final rootCtx = Navigator.of(context,
                                      rootNavigator: true)
                                  .context;
                              Navigator.pop(context);
                              showTimetableTemplateModal(rootCtx);
                            },
                          ),
                          SettingsRow(
                            sh: sh,
                            icon: Icons.school_outlined,
                            title: '학교 연결 (NEIS)',
                            onTap: () {
                              final rootCtx = Navigator.of(context,
                                      rootNavigator: true)
                                  .context;
                              Navigator.pop(context);
                              showNeisSetupModal(rootCtx);
                            },
                          ),
                          SettingsRow(
                            sh: sh,
                            icon: Icons.cake_outlined,
                            title: birthdays.isEmpty
                                ? '생일 연락처 가져오기 (.vcf)'
                                : '생일 연락처 (${birthdays.length}명)',
                            onTap: () => _importVcf(context, ref),
                          ),
                        ],
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
}

// ─── 섹션 카드 ───────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final SpaceHourColors sh;
  final String title;
  final Widget child;
  const _SectionCard({required this.sh, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
          child: Text(
            title,
            style: AppType.label.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: sh.ink.withValues(alpha: 0.42),
            ),
          ),
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

// ─── 카테고리 칩 ─────────────────────────────────────────────────
class CategoryFilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final SpaceHourColors sh;

  const CategoryFilterChip({
    super.key,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.sh,
  });

  @override
  Widget build(BuildContext context) {
    final brand = sh.accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? brand.withValues(alpha: 0.10)
              : sh.ink.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? brand.withValues(alpha: 0.28) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: AppType.label.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? brand : sh.ink.withValues(alpha: 0.5),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_rounded, size: 15, color: brand),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── 설정 행 ─────────────────────────────────────────────────────
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final SpaceHourColors sh;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.sh,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 20, color: sh.ink.withValues(alpha: 0.48)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppType.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: sh.ink,
                ),
              ),
            ),
            ?trailing,
            if (trailing == null && onTap != null)
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: sh.inkFaint),
          ],
        ),
      ),
    );
  }
}

// ─── iOS 스타일 스위치 ───────────────────────────────────────────
class _IosSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final SpaceHourColors sh;
  const _IosSwitch(
      {required this.value, required this.onChanged, required this.sh});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.88,
      child: Switch.adaptive(
        value: value,
        activeThumbColor: sh.accent,
        activeTrackColor: sh.accent.withValues(alpha: 0.24),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: sh.ink.withValues(alpha: 0.10),
        onChanged: onChanged,
      ),
    );
  }
}

// ─── 주 시작일 pill ──────────────────────────────────────────────
class _WeekStartPill extends StatelessWidget {
  final int dow; // 0=일, 1=월, 6=토
  final ValueChanged<int> onSelected;
  final SpaceHourColors sh;
  const _WeekStartPill(
      {required this.dow, required this.onSelected, required this.sh});

  static const _labels = {1: '월요일', 0: '일요일', 6: '토요일'};

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      onSelected: onSelected,
      color: sh.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (_) => [
        for (final e in _labels.entries)
          PopupMenuItem(
            value: e.key,
            child: Text(e.value,
                style: AppType.body.copyWith(
                    color: sh.ink,
                    fontWeight:
                        e.key == dow ? FontWeight.w700 : FontWeight.w400)),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: sh.ink.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _labels[dow] ?? '월요일',
              style: AppType.body.copyWith(
                  fontSize: 14, fontWeight: FontWeight.w700, color: sh.ink),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: sh.ink.withValues(alpha: 0.55)),
          ],
        ),
      ),
    );
  }
}

// ─── .vcf 생일 가져오기 ──────────────────────────────────────────
Future<void> _importVcf(BuildContext context, WidgetRef ref) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['vcf'],
  );
  if (result == null || result.files.single.path == null) return;
  try {
    final content = await File(result.files.single.path!).readAsString();
    final parsed = parseVcf(content);
    ref.read(birthdaysProvider.notifier).addAll(parsed);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('생일 ${parsed.length}명 가져오기 완료')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('가져오기 오류: $e')),
      );
    }
  }
}
