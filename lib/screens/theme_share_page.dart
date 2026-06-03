import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../modals/theme_manager_modal.dart';

/// 테마 관리 탭 — 카테고리(테마) 생성·편집·공유·구독을 한 화면에서 바로.
/// (예전엔 모달 뒤에 숨어 있던 관리 UI를 페이지에 직접 노출.)
class ThemeSharePage extends ConsumerWidget {
  const ThemeSharePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, 120),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          child: Text('테마 관리',
              style: AppType.title.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: sh.ink)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
          child: Text('카테고리를 만들고 색을 정하거나, 코드로 공유·구독해요',
              style: AppType.body.copyWith(color: sh.inkSoft)),
        ),
        // 관리 UI를 모달이 아니라 화면에 바로 노출.
        const ThemeManagerBody(),
      ],
    );
  }
}
