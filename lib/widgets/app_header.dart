import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../core/constants/color_presets.dart';
import '../providers/color_preset_provider.dart';
import '../widgets/sidebar_drawer.dart';
import '../widgets/coach_mark.dart';
import '../modals/theme_manager_modal.dart';
import '../modals/profile_modal.dart';
import '../utils/screenshot_util.dart';

// ─── 더보기 메뉴에서 선택한 액션 ─────────────────────────────────
enum _MoreAction { category, settings, profile }

class AppHeader extends ConsumerWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    return Container(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xs, Gap.md, 0),
      color: sh.bg,
      child: Row(
        children: [
          // ── 브랜드 (compact, 보조 위계) ─────────────────────────
          _SpaceHourLogo(color: sh.inkFaint),
          const SizedBox(width: Gap.xs),
          Text('spaceHour',
              style: AppType.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: sh.inkSoft,
                  letterSpacing: -0.2)),
          const Spacer(),
          // ── 공유 ────────────────────────────────────────────────
          _IconBtn(
            icon: Icons.ios_share_outlined,
            sh: sh,
            onTap: captureAndShare,
          ),
          // coach mark anchor for category (0×0, 더보기 버튼 바로 옆)
          SizedBox(key: coachKeyBtnCategory, width: 0, height: 0),
          // ── 더보기 (⋯) — 나머지 액션 모두 여기로 ────────────────
          _IconBtn(
            key: coachKeyBtnSettings,
            icon: Icons.more_horiz,
            sh: sh,
            onTap: () => _openMore(context, ref, sh),
          ),
        ],
      ),
    );
  }

  void _openMore(BuildContext context, WidgetRef ref, SpaceHourColors sh) {
    showModalBottomSheet<_MoreAction>(
      context: context,
      builder: (_) => _MoreSheet(ref: ref, sh: sh),
    ).then((action) {
      if (action == null || !context.mounted) return;
      switch (action) {
        case _MoreAction.category:
          showThemeManagerModal(context);
        case _MoreAction.settings:
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const FractionallySizedBox(
              heightFactor: 0.85,
              child: SidebarDrawer(),
            ),
          );
        case _MoreAction.profile:
          showProfileModal(context);
      }
    });
  }
}

// ─── 아이콘 전용 버튼 (44×44 터치 영역) ──────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final SpaceHourColors sh;
  final VoidCallback onTap;
  const _IconBtn({super.key, required this.icon, required this.sh, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kMinTouch,
      height: kMinTouch,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kMinTouch / 2),
        child: Center(child: Icon(icon, size: 20, color: sh.inkSoft)),
      ),
    );
  }
}

// ─── 더보기 바텀시트 ──────────────────────────────────────────────

class _MoreSheet extends ConsumerWidget {
  final WidgetRef ref;
  final SpaceHourColors sh;
  const _MoreSheet({required this.ref, required this.sh});

  @override
  Widget build(BuildContext context, WidgetRef watchRef) {
    final preset = watchRef.watch(colorPresetProvider);
    return Container(
      color: sh.card,
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 색상 테마 ──────────────────────────────────────────
          Text('색상 테마',
              style: AppType.caption.copyWith(
                  fontWeight: FontWeight.w700, color: sh.inkSoft)),
          const SizedBox(height: Gap.sm),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: kColorPresets.map((p) {
              final selected = p.id == preset.id;
              return GestureDetector(
                onTap: () {
                  ref.read(colorPresetProvider.notifier).setPreset(p.id);
                },
                child: Tooltip(
                  message: p.name,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: p.dot,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? sh.ink : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(
                              color: p.dot.withValues(alpha: 0.4),
                              blurRadius: 6)]
                          : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: Gap.md),
          Divider(color: sh.border, height: 1),
          // ── 액션 목록 ──────────────────────────────────────────
          ListTile(
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: Gap.xl,
            leading: Icon(Icons.label_outline_rounded, size: 20, color: sh.inkSoft),
            title: Text('카테고리 관리',
                style: AppType.body.copyWith(color: sh.ink)),
            trailing: Icon(Icons.chevron_right_rounded, size: 18, color: sh.inkFaint),
            onTap: () => Navigator.pop(context, _MoreAction.category),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: Gap.xl,
            leading: Icon(Icons.settings_outlined, size: 20, color: sh.inkSoft),
            title: Text('설정', style: AppType.body.copyWith(color: sh.ink)),
            trailing: Icon(Icons.chevron_right_rounded, size: 18, color: sh.inkFaint),
            onTap: () => Navigator.pop(context, _MoreAction.settings),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: Gap.xl,
            leading: Icon(Icons.person_outline_rounded, size: 20, color: sh.inkSoft),
            title: Text('프로필', style: AppType.body.copyWith(color: sh.ink)),
            trailing: Icon(Icons.chevron_right_rounded, size: 18, color: sh.inkFaint),
            onTap: () => Navigator.pop(context, _MoreAction.profile),
          ),
        ],
      ),
    );
  }
}

// ─── spaceHour 로고 ──────────────────────────────────────────────

class _SpaceHourLogo extends StatelessWidget {
  final Color color;
  const _SpaceHourLogo({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(16, 16),
      painter: _LogoPainter(color: color),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color color;
  _LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final s = size.width;
    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1.5, s - 2, s - 2.5), const Radius.circular(2.5));
    canvas.drawRRect(rrect, p);
    canvas.drawLine(Offset(1, s * 0.36), Offset(s - 1, s * 0.36), p);
    canvas.drawLine(Offset(s * 0.29, 0), Offset(s * 0.29, s * 0.22), p);
    canvas.drawLine(Offset(s * 0.71, 0), Offset(s * 0.71, s * 0.22), p);
    final dp = Paint()..color = color..style = PaintingStyle.fill;
    for (final x in [s * 0.3, s * 0.5, s * 0.7]) {
      canvas.drawCircle(Offset(x, s * 0.59), 1.0, dp);
    }
    canvas.drawCircle(Offset(s * 0.3, s * 0.78), 1.0, dp);
    canvas.drawCircle(Offset(s * 0.5, s * 0.78), 1.0, dp);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.color != color;
}
