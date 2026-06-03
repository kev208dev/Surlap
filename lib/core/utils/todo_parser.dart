import 'date_utils.dart' as du;

/// 자연어 할 일 입력 파싱 결과.
class ParsedTodo {
  final String? dateKey;   // 'YYYY-MM-DD' (인식 못 하면 null)
  final int priority;      // 1..3, 없으면 0
  final String content;    // 날짜/우선순위 토큰을 제거한 본문

  const ParsedTodo({this.dateKey, this.priority = 0, required this.content});
}

/// "내일 p1 빨래하기" → (dateKey=내일, priority=1, content="빨래하기")
///
/// 지원:
///  - 날짜: 오늘 / 내일 / 모레 / 글피 / 다음주 / 요일(월~일, "이번주/다음주" 접두) /
///          M월D일 / M/D
///  - 우선순위: p1~p3, P1~P3, 우선순위N, 중요(=1), !!!(개수)
///  - 나머지 텍스트 = content
ParsedTodo parseTodoInput(String input, {DateTime? now}) {
  final base = now ?? DateTime.now();
  var text = input.trim();
  if (text.isEmpty) return const ParsedTodo(content: '');

  String? dateKey;
  int priority = 0;

  // ── 우선순위: p1 / P2 / 우선순위3 ──────────────────────────────
  final pMatch = RegExp(r'(?:^|\s)[pP]\s*([1-3])(?=\s|$)').firstMatch(text);
  if (pMatch != null) {
    priority = int.parse(pMatch.group(1)!);
    text = text.replaceRange(pMatch.start, pMatch.end, ' ');
  } else {
    final pKo = RegExp(r'우선순위\s*([1-3])').firstMatch(text);
    if (pKo != null) {
      priority = int.parse(pKo.group(1)!);
      text = text.replaceRange(pKo.start, pKo.end, ' ');
    } else if (RegExp(r'(?:^|\s)(중요|긴급)(?:\s|$)').hasMatch(text)) {
      priority = 1;
      text = text.replaceAll(RegExp(r'(?:^|\s)(중요|긴급)(?=\s|$)'), ' ');
    }
  }

  // ── 상대 날짜: 오늘/내일/모레/글피 ─────────────────────────────
  const relWords = {'오늘': 0, '내일': 1, '낼': 1, '모레': 2, '글피': 3};
  for (final e in relWords.entries) {
    final re = RegExp('(?:^|\\s)${e.key}(?=\\s|\$)');
    if (re.hasMatch(text)) {
      dateKey = du.toDateKey(base.add(Duration(days: e.value)));
      text = text.replaceAll(re, ' ');
      break;
    }
  }

  // ── 요일: (이번주/다음주)? 월~일 ──────────────────────────────
  if (dateKey == null) {
    const dows = {
      '월': 1, '화': 2, '수': 3, '목': 4, '금': 5, '토': 6, '일': 7,
    };
    final dowMatch =
        RegExp(r'(?:^|\s)(다음주|담주|이번주)?\s*([월화수목금토일])요일?(?=\s|$)')
            .firstMatch(text);
    if (dowMatch != null) {
      final prefix = dowMatch.group(1);
      final targetDow = dows[dowMatch.group(2)]!; // 1=월..7=일
      DateTime target;
      if (prefix == null) {
        // 접두사 없음 → 다가오는 해당 요일(이번 주에 지났으면 다음 주).
        int delta = (targetDow - base.weekday) % 7;
        if (delta <= 0) delta += 7;
        target = base.add(Duration(days: delta));
      } else {
        // "이번주/다음주" → 해당 주의 월요일 기준으로 앵커링.
        final weekMonday = base.subtract(Duration(days: base.weekday - 1));
        final nextWeek = prefix == '다음주' || prefix == '담주';
        target = weekMonday
            .add(Duration(days: (targetDow - 1) + (nextWeek ? 7 : 0)));
      }
      dateKey = du.toDateKey(target);
      text = text.replaceRange(dowMatch.start, dowMatch.end, ' ');
    }
  }

  // ── 절대 날짜: M월D일 / M/D ───────────────────────────────────
  if (dateKey == null) {
    final md = RegExp(r'(\d{1,2})\s*월\s*(\d{1,2})\s*일?').firstMatch(text);
    if (md != null) {
      final m = int.parse(md.group(1)!);
      final d = int.parse(md.group(2)!);
      dateKey = _resolveMonthDay(base, m, d);
      text = text.replaceRange(md.start, md.end, ' ');
    } else {
      final slash =
          RegExp(r'(?:^|\s)(\d{1,2})/(\d{1,2})(?=\s|$)').firstMatch(text);
      if (slash != null) {
        final m = int.parse(slash.group(1)!);
        final d = int.parse(slash.group(2)!);
        dateKey = _resolveMonthDay(base, m, d);
        text = text.replaceRange(slash.start, slash.end, ' ');
      }
    }
  }

  // 남은 공백 정리
  final content = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return ParsedTodo(dateKey: dateKey, priority: priority, content: content);
}

/// M월 D일을 올해 기준으로 해석하되, 이미 지난 날짜면 내년으로.
String _resolveMonthDay(DateTime base, int month, int day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return du.toDateKey(base);
  }
  var candidate = DateTime(base.year, month, day);
  final today = DateTime(base.year, base.month, base.day);
  if (candidate.isBefore(today)) {
    candidate = DateTime(base.year + 1, month, day);
  }
  return du.toDateKey(candidate);
}
