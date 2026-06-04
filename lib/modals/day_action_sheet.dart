import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../core/utils/todo_style.dart';
import '../providers/events_provider.dart';
import '../providers/todos_provider.dart';
import '../providers/day_widget_provider.dart';
import '../providers/view_provider.dart';
import 'add_edit_event_modal.dart';
import 'add_todo_modal.dart';
import 'day_widget_input_modal.dart';
import 'day_template_manager_modal.dart';

/// 달력에서 날짜를 탭하면 뜨는 공용 액션 시트.
/// 월간/연속 보기 양쪽에서 동일하게 사용한다.
Future<void> showDayActionSheet(
        BuildContext context, String dateKey, DateTime date) =>
    showModalBottomSheet(
      context: context,
      builder: (_) => DayActionSheet(dateKey: dateKey, date: date),
    );

class DayActionSheet extends ConsumerWidget {
  final String dateKey;
  final DateTime date;
  const DayActionSheet({super.key, required this.dateKey, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final events =
        (ref.watch(eventsProvider)[dateKey] ?? []).where((e) => !e.isTimetable).toList();
    final todos = ref.watch(todosProvider).where((t) => t.dateKey == dateKey).toList();

    return Container(
      color: sh.card,
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.xl),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${date.month}월 ${date.day}일',
                style: AppType.body
                    .copyWith(fontWeight: FontWeight.w700, color: sh.ink)),
            const SizedBox(height: Gap.md),
            _Tile(
              icon: Icons.event_rounded,
              label: '일정 추가',
              color: sh.accent,
              onTap: () {
                Navigator.pop(context);
                showAddEditEventModal(context, dateKey: dateKey);
              },
            ),
            _Tile(
              icon: Icons.check_circle_outline_rounded,
              label: '할 일 추가',
              color: sh.accent,
              onTap: () {
                Navigator.pop(context);
                showAddTodoModal(context, dateKey: dateKey);
              },
            ),
            _Tile(
              icon: Icons.widgets_outlined,
              label: '위젯 추가',
              color: sh.ink,
              onTap: () {
                Navigator.pop(context);
                _showWidgetPicker(context, ref, dateKey);
              },
            ),
            _Tile(
              icon: Icons.today_outlined,
              label: '이날 자세히 보기',
              color: sh.ink,
              onTap: () {
                Navigator.pop(context);
                ref.read(viewProvider.notifier).setDayView(dateKey);
              },
            ),

            // 이 날의 일정
            if (events.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('이 날의 일정 (${events.length})',
                  style: AppType.label.copyWith(
                      fontWeight: FontWeight.w700, color: sh.inkSoft)),
              ...events.asMap().entries.map((e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(Icons.circle, size: 8, color: sh.accent),
                    title: Text(e.value.t,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.body.copyWith(color: sh.ink)),
                    trailing:
                        Icon(Icons.edit_outlined, size: 16, color: sh.inkFaint),
                    onTap: () {
                      Navigator.pop(context);
                      showAddEditEventModal(context,
                          dateKey: dateKey, editIndex: e.key);
                    },
                  )),
            ],

            // 이 날의 할 일
            if (todos.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('이 날의 할 일 (${todos.length})',
                  style: AppType.label.copyWith(
                      fontWeight: FontWeight.w700, color: sh.inkSoft)),
              ...todos.map((t) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: GestureDetector(
                      onTap: () =>
                          ref.read(todosProvider.notifier).toggleDone(t.id),
                      child: Icon(
                        t.done
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 20,
                        color: t.done
                            ? sh.accent
                            : todoPriorityColor(t.priority, sh),
                      ),
                    ),
                    title: Text(t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.body.copyWith(
                            color: t.done ? sh.inkFaint : sh.ink,
                            decoration: t.done
                                ? TextDecoration.lineThrough
                                : null)),
                    trailing:
                        Icon(Icons.edit_outlined, size: 16, color: sh.inkFaint),
                    onTap: () {
                      Navigator.pop(context);
                      showAddTodoModal(context, edit: t);
                    },
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 위젯 추가: 만들어진 위젯 중 선택 또는 새로 만들기 ──────────────
void _showWidgetPicker(BuildContext context, WidgetRef ref, String dateKey) {
  showModalBottomSheet(
    context: context,
    builder: (sheetCtx) {
      final sh = sheetCtx.sh;
      final templates = ref.read(dayTemplatesProvider);
      return Container(
        color: sh.card,
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('위젯 추가',
                style: AppType.section
                    .copyWith(fontWeight: FontWeight.w800, color: sh.ink)),
            const SizedBox(height: 4),
            Text(
                templates.isEmpty
                    ? '아직 만든 위젯이 없어요. 새로 만들어 보세요.'
                    : '추가할 위젯을 선택하세요.',
                style: AppType.label.copyWith(color: sh.inkSoft)),
            const SizedBox(height: Gap.sm),
            ...templates.map((tpl) {
              final applied = tpl.scope.appliesTo(dateKey);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.dashboard_customize_outlined,
                    size: 20, color: sh.accent),
                title: Text(tpl.name,
                    style: AppType.body.copyWith(color: sh.ink)),
                subtitle: Text('${tpl.fields.length}개 항목',
                    style: AppType.caption.copyWith(color: sh.inkSoft)),
                trailing: applied
                    ? Icon(Icons.check_rounded, size: 18, color: sh.accent)
                    : Icon(Icons.add_rounded, size: 18, color: sh.inkSoft),
                onTap: () {
                  // 이 날짜에 적용되도록 보장한 뒤 입력 모달을 연다.
                  if (!applied) {
                    ref.read(dayTemplatesProvider.notifier).update(
                          tpl.copyWith(scope: tpl.scope.withDay(dateKey)),
                        );
                  }
                  Navigator.pop(sheetCtx);
                  showDayWidgetInputModal(context, dateKey);
                },
              );
            }),
            const SizedBox(height: Gap.xs),
            // 새 위젯 만들기
            InkWell(
              onTap: () {
                Navigator.pop(sheetCtx);
                showDayTemplateManagerModal(context);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: sh.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sh.accent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 20, color: sh.accent),
                    const SizedBox(width: 6),
                    Text('새 위젯 만들기',
                        style: AppType.body.copyWith(
                            fontWeight: FontWeight.w800, color: sh.accent)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Tile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: AppType.body.copyWith(color: color)),
      onTap: onTap,
    );
  }
}
