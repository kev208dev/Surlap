import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Surlap 브랜드 로고 컴포넌트.
/// - `variant`: symbol(심볼만) / wordmark(워드만) / lockup(가로 락업)
/// - `size`: 심볼/락업의 심볼 변 길이. 52 이하면 자동으로 -small 변형 사용.
/// - `mono`: true 면 currentColor 단색(외부 `color` 로 색 제어).
///
/// 핸드오프 사양:
///  - SVG stroke-width / dasharray / rotate 임의 변경 금지(시각 밸런스 핵심).
///  - 워드마크 = Space Grotesk w600, letter-spacing -0.025em.
class SurlapLogo extends StatelessWidget {
  final SurlapLogoVariant variant;
  final double size;
  final bool mono;
  final Color? color;

  const SurlapLogo({
    super.key,
    this.variant = SurlapLogoVariant.symbol,
    this.size = 56,
    this.mono = false,
    this.color,
  });

  static const _assetSymbol = 'assets/brand/surlap-symbol.svg';
  static const _assetSymbolMono = 'assets/brand/surlap-symbol-mono.svg';
  static const _assetIconSmall = 'assets/brand/surlap-app-icon-small.svg';

  @override
  Widget build(BuildContext context) {
    final symbol = _buildSymbol();
    switch (variant) {
      case SurlapLogoVariant.symbol:
        return symbol;
      case SurlapLogoVariant.wordmark:
        return _buildWordmark(context);
      case SurlapLogoVariant.lockup:
        final wordSize = size * (38 / 56); // 핸드오프: 심볼 56일 때 워드 38.
        final gap = size / 3;              // gap = 심볼 변의 1/3.
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            symbol,
            SizedBox(width: gap),
            _buildWordmark(context, fontSize: wordSize),
          ],
        );
    }
  }

  Widget _buildSymbol() {
    final small = size <= 52;
    final asset = mono
        ? _assetSymbolMono
        : (small ? _assetIconSmall : _assetSymbol);
    final tint = mono ? (color ?? const Color(0xFF6D28D9)) : null;
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: tint == null
          ? null
          : ColorFilter.mode(tint, BlendMode.srcIn),
      semanticsLabel: 'Surlap',
    );
  }

  Widget _buildWordmark(BuildContext context, {double? fontSize}) {
    final fs = fontSize ?? (size * (38 / 56));
    final c = color ?? (mono
        ? (DefaultTextStyle.of(context).style.color ?? const Color(0xFF1B0A3A))
        : const Color(0xFF1B0A3A));
    return Text(
      'Surlap',
      style: GoogleFonts.spaceGrotesk(
        fontSize: fs,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.025 * fs,
        color: c,
        height: 1.0,
      ),
    );
  }
}

enum SurlapLogoVariant { symbol, wordmark, lockup }

/// 앱 아이콘(라운드 그라데이션) 단독 사용용. SwiftUI/Glance 단에서 PNG 변환 후
/// 런처 아이콘으로 쓰는 게 정석이지만, 앱 안 카드 헤더 같은 곳에 미리보기로 노출 가능.
class SurlapAppIconBadge extends StatelessWidget {
  final double size;
  const SurlapAppIconBadge({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final asset = size <= 52
        ? 'assets/brand/surlap-app-icon-small.svg'
        : 'assets/brand/surlap-app-icon.svg';
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      semanticsLabel: 'Surlap app icon',
    );
  }
}
