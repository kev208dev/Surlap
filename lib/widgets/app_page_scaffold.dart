import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';

/// 서브 페이지 공통 스캐폴드 — 뒤로가기 + 중앙 제목 + 스크롤 본문.
/// 설정/테마 공유 등 floating nav에서 push로 진입하는 페이지에 사용.
class AppPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const AppPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return Scaffold(
      backgroundColor: sh.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── 헤더 (뒤로가기 + 중앙 제목) ──
            SizedBox(
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 4,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20, color: sh.ink),
                    ),
                  ),
                  Text(
                    title,
                    style: AppType.title.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: sh.ink,
                    ),
                  ),
                ],
              ),
            ),
            // ── 본문 (스크롤) ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                children: [
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14, left: 4),
                      child: Text(
                        subtitle!,
                        style: AppType.label
                            .copyWith(fontSize: 13, color: sh.inkSoft),
                      ),
                    ),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
