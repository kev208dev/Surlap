import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../providers/settings_provider.dart';

class MottoArea extends ConsumerStatefulWidget {
  const MottoArea({super.key});
  @override
  ConsumerState<MottoArea> createState() => _MottoAreaState();
}

class _MottoAreaState extends ConsumerState<MottoArea> {
  late TextEditingController _ctrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: ref.read(settingsProvider).motto);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final motto = ref.watch(settingsProvider).motto;
    if (!_editing && _ctrl.text != motto) _ctrl.text = motto;

    // 가장 약한 위계 — 보조 정보. 월 라벨보다 시각적으로 약해야 함.
    return Container(
      padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.xs),
      color: sh.bg,
      child: Row(
        children: [
          Text('"',
              style: AppType.label.copyWith(
                  color: sh.inkFaint.withValues(alpha: 0.6), height: 1)),
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: AppType.label.copyWith(
                  color: sh.inkFaint, fontStyle: FontStyle.italic),
              decoration: InputDecoration(
                hintText: '이달의 모토',
                hintStyle: AppType.label.copyWith(
                    color: sh.inkFaint.withValues(alpha: 0.45),
                    fontStyle: FontStyle.italic),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: Gap.xs),
              ),
              maxLines: 1,
              maxLength: 120,
              buildCounter: (_, {required int currentLength,
                    required bool isFocused, required int? maxLength}) =>
                  null,
              onTap: () => setState(() => _editing = true),
              onSubmitted: (v) {
                ref.read(settingsProvider.notifier).setMotto(v);
                setState(() => _editing = false);
              },
              onEditingComplete: () {
                ref.read(settingsProvider.notifier).setMotto(_ctrl.text);
                setState(() => _editing = false);
              },
            ),
          ),
          Text('"',
              style: AppType.label.copyWith(
                  color: sh.inkFaint.withValues(alpha: 0.6), height: 1)),
        ],
      ),
    );
  }
}
