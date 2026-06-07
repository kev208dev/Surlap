import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 스크롤로 상단 헤더 접힘/펼침 상태(전역). true = 접힘.
final headerCollapsedProvider = StateProvider<bool>((ref) => false);

/// 스크롤되는 캘린더 뷰를 감싸 스크롤 방향에 따라 헤더 접힘 상태를 토글.
/// - 아래로(콘텐츠 위로) 충분히 스크롤 → 접힘
/// - 위로 스크롤 / 맨 위 → 펼침
/// 짧은 스크롤 떨림 방지용 임계값(_threshold) 적용.
class CollapseOnScroll extends ConsumerStatefulWidget {
  final Widget child;
  const CollapseOnScroll({super.key, required this.child});

  @override
  ConsumerState<CollapseOnScroll> createState() => _CollapseOnScrollState();
}

class _CollapseOnScrollState extends ConsumerState<CollapseOnScroll> {
  static const double _threshold = 12;
  double _accum = 0;

  @override
  void initState() {
    super.initState();
    // 이 뷰로 진입하면 항상 펼친 상태에서 시작(이전 뷰의 접힘 상태 잔존 방지).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _set(false);
    });
  }

  void _set(bool v) {
    if (ref.read(headerCollapsedProvider) != v) {
      ref.read(headerCollapsedProvider.notifier).state = v;
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is ScrollUpdateNotification) {
      final px = n.metrics.pixels;
      // 펼침은 '맨 위로 끌어올렸을 때'만 — 위로 스크롤하는 도중엔 헤더 안 나옴.
      if (px <= 4) {
        _accum = 0;
        _set(false);
        return false;
      }
      final d = n.scrollDelta ?? 0;
      // 아래로(콘텐츠 위로) 충분히 → 접힘. 위로 스크롤로는 펼치지 않는다.
      _accum = d > 0 ? _accum + d : 0;
      if (_accum > _threshold) {
        _accum = 0;
        _set(true);
      }
    } else if (n is UserScrollNotification &&
        n.direction == ScrollDirection.idle) {
      _accum = 0;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: widget.child,
    );
  }
}

/// 헤더를 부드럽게 접었다 폄. [collapsed]면 높이 0으로 줄어듦.
class CollapsibleHeader extends StatelessWidget {
  final bool collapsed;
  final Widget child;
  const CollapsibleHeader(
      {super.key, required this.collapsed, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: collapsed
            ? const SizedBox(width: double.infinity, height: 0)
            : child,
      ),
    );
  }
}
