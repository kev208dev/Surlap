import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../storage/local_store.dart';
import '../../core/constants/storage_keys.dart';
import '../../providers/recurring_provider.dart';
import '../../providers/cell_design_provider.dart';
import '../../providers/neis_cache_provider.dart';
import '../../providers/academic_schedule_provider.dart';
import '../../modals/neis_setup_modal.dart';
import 'dart:convert';

// ─── Row definition ───────────────────────────────────────────────

enum _RType { free, school, lunch, divider }

class _RowDef {
  final _RType type;
  final String label;
  final int hour;   // -1 for divider
  final int period; // 1..N for school rows, -1 otherwise
  const _RowDef({required this.type, this.label = '', this.hour = -1, this.period = -1});
  bool get isDivider => type == _RType.divider;
}

// ─── Merge group ──────────────────────────────────────────────────

class _MergeGroup {
  final int col;
  final int startRow;
  final int span;
  final String text;
  final double topOffset;

  const _MergeGroup({
    required this.col,
    required this.startRow,
    required this.span,
    required this.text,
    required this.topOffset,
  });
}

/// 과목명 표시용 정리 — 원본 데이터는 그대로 두고 UI 표시만 줄인다.
/// 글자 단위로 어색하게 쪼개지지 않도록 단어/접미사 기준으로 다듬는다.
String getDisplaySubjectName(String raw, {bool lunch = false}) {
  final s = raw.trim();
  if (s.isEmpty) return '';
  // 점심 행은 급식 메뉴를 줄별로 정리해 그대로 보여준다.
  if (lunch) return _formatLunchMenu(s);
  // 다중 공백 → 단일 공백.
  var t = s.replaceAll(RegExp(r'\s+'), ' ');
  // 흔한 군더더기 접미사 제거(결과가 2자 이상일 때만).
  for (final suf in const ['일반', '기초', '입문', '개론']) {
    final stripped = t.replaceAll(' ', '');
    if (stripped.length > suf.length + 1 && stripped.endsWith(suf)) {
      t = stripped.substring(0, stripped.length - suf.length);
      break;
    }
  }
  return t;
}

/// 급식 메뉴 정리 — 구분자(줄바꿈/`*`/`/`) 기준으로 나눠 줄별 표시.
/// 알레르기 표기 등은 그대로 둔다.
String _formatLunchMenu(String raw) {
  final parts = raw
      .split(RegExp(r'[\n*/]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  return parts.isEmpty ? '' : parts.join('\n');
}

// ─── 표시 밀도 프리셋 ─────────────────────────────────────────────
/// "넓게 보기 / 촘촘히 보기" 같은 밀도 값을 한곳에 모아 둔다.
class _Density {
  final double dayColW;
  final double headerH;
  final double schoolH;
  final double lunchH;
  final double freeH;
  final double cardMargin;
  final double cardRadius;
  final int subjectMaxLines;
  final double subjectFont;
  const _Density({
    required this.dayColW,
    required this.headerH,
    required this.schoolH,
    required this.lunchH,
    required this.freeH,
    required this.cardMargin,
    required this.cardRadius,
    required this.subjectMaxLines,
    required this.subjectFont,
  });

  // 넓지만 꽉 찬 시간표 — 카드가 셀 대부분을 채우도록 여백은 작게.
  static const wide = _Density(
    dayColW: 92, headerH: 60, schoolH: 82, lunchH: 96, freeH: 50,
    cardMargin: 3, cardRadius: 10, subjectMaxLines: 2, subjectFont: 13,
  );
  static const compact = _Density(
    dayColW: 74, headerH: 46, schoolH: 60, lunchH: 76, freeH: 40,
    cardMargin: 2.5, cardRadius: 9, subjectMaxLines: 1, subjectFont: 11.5,
  );
}

// ─── Main widget ──────────────────────────────────────────────────

class TimetableView extends ConsumerStatefulWidget {
  const TimetableView({super.key});

  @override
  ConsumerState<TimetableView> createState() => _TimetableViewState();
}

class _TimetableViewState extends ConsumerState<TimetableView> {
  static const _dowNames = ['월', '화', '수', '목', '금', '토', '일'];
  static const _divH = 3.0;

  // 디자인 모드(셀 꾸미기) — 화면 로컬 UI 상태.
  bool _designMode = false;
  // 보기 모드 — 넓게(기본) / 압축.
  bool _compact = false;

  // 가로/세로 스크롤 — 고정 라벨열·헤더가 본문을 따라가도록 동기화.
  final _bodyV = ScrollController();
  final _bodyH = ScrollController();
  final _labelV = ScrollController();
  final _headerH = ScrollController();
  bool _didAutoScroll = false;

  static const _palette = [
    Color(0xFFFFE4E4), Color(0xFFFFF3CD), Color(0xFFD4EDDA), Color(0xFFD1ECF1),
    Color(0xFFE2D9F3), Color(0xFFFFF5EE), Color(0xFFF0F0F0), Color(0xFFFFE8D6),
  ];

  // ── 보기 모드별 치수(밀도 프리셋) ──────────────────────────────
  _Density get _d => _compact ? _Density.compact : _Density.wide;
  double get _dayColW => _d.dayColW;
  double get _labelW => _compact ? 54 : 70;
  double get _headerBandH => _d.headerH;
  double get _schoolH => _d.schoolH;
  double get _lunchH => _d.lunchH;
  double get _freeH => _d.freeH;
  int get _maxLines => _d.subjectMaxLines;
  double get _subjectFont => _d.subjectFont;

  @override
  void initState() {
    super.initState();
    _bodyV.addListener(_syncV);
    _bodyH.addListener(_syncH);
  }

  @override
  void dispose() {
    _bodyV.removeListener(_syncV);
    _bodyH.removeListener(_syncH);
    _bodyV.dispose();
    _bodyH.dispose();
    _labelV.dispose();
    _headerH.dispose();
    super.dispose();
  }

  void _syncV() {
    if (!_labelV.hasClients || !_bodyV.hasClients) return;
    final o = _bodyV.offset
        .clamp(_labelV.position.minScrollExtent, _labelV.position.maxScrollExtent);
    if (_labelV.offset != o) _labelV.jumpTo(o);
  }

  void _syncH() {
    if (!_headerH.hasClients || !_bodyH.hasClients) return;
    final o = _bodyH.offset
        .clamp(_headerH.position.minScrollExtent, _headerH.position.maxScrollExtent);
    if (_headerH.offset != o) _headerH.jumpTo(o);
  }

  // 첫 진입 시 오늘 요일이 보이도록 가로 스크롤.
  void _autoScrollToToday() {
    if (_didAutoScroll || !_bodyH.hasClients) return;
    _didAutoScroll = true;
    final todayCol = DateTime.now().weekday - 1; // 월=0
    final target = (todayCol * _dayColW)
        .clamp(0.0, _bodyH.position.maxScrollExtent);
    if (target > 0) _bodyH.jumpTo(target);
  }

  // ── Data builders ─────────────────────────────────────────────

  List<DateTime> _weekDays() {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (i) => DateTime(monday.year, monday.month, monday.day + i));
  }

  int _maxPeriod(Map<int, Map<int, String>> neis) {
    int mp = 7;
    for (final pm in neis.values) {
      for (final p in pm.keys) {
        if (p > mp) mp = p;
      }
    }
    return mp;
  }

  List<_RowDef> _buildRows(int maxPeriod) {
    final rows = <_RowDef>[];
    for (int h = 0; h <= 8; h++) {
      rows.add(_RowDef(type: _RType.free, label: '$h:00', hour: h));
    }
    rows.add(const _RowDef(type: _RType.divider));
    final topPeriods = maxPeriod < 4 ? maxPeriod : 4;
    for (int p = 1; p <= topPeriods; p++) {
      rows.add(_RowDef(type: _RType.school, label: '$p교시', hour: 8 + p, period: p));
    }
    rows.add(const _RowDef(type: _RType.lunch, label: '점심', hour: 13));
    for (int p = 5; p <= maxPeriod; p++) {
      rows.add(_RowDef(type: _RType.school, label: '$p교시', hour: 9 + p, period: p));
    }
    rows.add(const _RowDef(type: _RType.divider));
    final afterSchool = 10 + maxPeriod;
    for (int h = afterSchool; h <= 23; h++) {
      rows.add(_RowDef(type: _RType.free, label: '$h:00', hour: h));
    }
    return rows;
  }

  // 행 높이 — 내용 길이가 아니라 행 종류·보기 모드로 결정(넓고 일정하게).
  double _heightFor(_RowDef r) => switch (r.type) {
        _RType.divider => _divH,
        _RType.school => _schoolH,
        _RType.lunch => _lunchH,
        _RType.free => _freeH,
      };

  List<double> _rowHeights(List<_RowDef> rows) =>
      [for (final r in rows) _heightFor(r)];

  List<double> _rowOffsets(List<double> heights) {
    final offsets = <double>[];
    double acc = 0;
    for (final h in heights) {
      offsets.add(acc);
      acc += h;
    }
    offsets.add(acc);
    return offsets;
  }

  Map<int, Map<int, String>> _buildTemplateData(List<DateTime> days) {
    final result = <int, Map<int, String>>{};
    for (int di = 0; di < 7; di++) { result[di] = {}; }

    final rawTpl = LocalStore.instance.getString(StorageKeys.timetableTemplate);
    if (rawTpl == null) return result;
    Map<String, dynamic> tpl;
    try {
      tpl = jsonDecode(rawTpl) as Map<String, dynamic>;
    } catch (_) {
      return result;
    }

    final blocks = (tpl['blocks'] as List? ?? []).cast<Map<String, dynamic>>();
    final weekdays = (tpl['weekdays'] as List? ?? [0, 1, 2, 3, 4])
        .map((e) => e as int).toSet();
    final startDate = tpl['startDate'] as String?;
    final endDate = tpl['endDate'] as String?;

    Map<String, dynamic> overrides = {};
    final rawOv = LocalStore.instance.getString(StorageKeys.timetableOverrides);
    if (rawOv != null) {
      try {
        overrides = jsonDecode(rawOv) as Map<String, dynamic>;
      } catch (_) {}
    }

    for (int di = 0; di < 7; di++) {
      final date = days[di];
      final dow = (date.weekday - 1) % 7;
      if (!weekdays.contains(dow)) continue;
      final dk = du.toDateKey(date);
      if (startDate != null && dk.compareTo(startDate) < 0) continue;
      if (endDate != null && dk.compareTo(endDate) > 0) continue;
      final ov = overrides[dk] as Map<String, dynamic>? ?? {};
      final hiddenIds = ((ov['hiddenBlockIds'] as List?) ?? [])
          .map((e) => e.toString()).toSet();
      for (final b in blocks) {
        if ((b['day'] as int?) != dow) continue;
        final id = b['id']?.toString() ?? '';
        if (hiddenIds.contains(id)) continue;
        final tm = b['tm'] as String? ?? '';
        if (tm.isEmpty) continue;
        final hour = int.tryParse(tm.split(':')[0]) ?? -1;
        if (hour < 0 || hour > 23) continue;
        result[di]![hour] = b['t']?.toString() ?? '';
      }
      final extra = (ov['extra'] as List? ?? []).cast<Map<String, dynamic>>();
      for (final e in extra) {
        final tm = e['tm'] as String? ?? '';
        if (tm.isEmpty) continue;
        final hour = int.tryParse(tm.split(':')[0]) ?? -1;
        if (hour < 0 || hour > 23) continue;
        result[di]![hour] = e['t']?.toString() ?? '';
      }
    }
    return result;
  }

  Map<int, Map<int, String>> _buildNeisHourData(Map<int, Map<int, String>> neis) {
    final result = <int, Map<int, String>>{};
    neis.forEach((di, periodMap) {
      result[di] = {};
      periodMap.forEach((period, subject) {
        final h = period <= 4 ? 8 + period : 9 + period;
        result[di]![h] = subject;
      });
    });
    return result;
  }

  Map<int, Map<int, String>> _buildDisplayData(
    Map<int, Map<int, String>> neisData,
    Map<int, Map<int, String>> tplData,
    Map<int, Map<int, String>> freeData,
    Map<int, String> neisLunch,
    List<_RowDef> rows,
  ) {
    final result = <int, Map<int, String>>{};
    for (int col = 0; col < 7; col++) {
      result[col] = {};
      for (final row in rows) {
        if (row.isDivider || row.hour < 0) continue;
        final n = neisData[col]?[row.hour] ?? '';
        final t = tplData[col]?[row.hour] ?? '';
        final u = freeData[col]?[row.hour] ?? '';
        if (row.type == _RType.school) {
          result[col]![row.hour] = n.isNotEmpty ? n : t.isNotEmpty ? t : u;
        } else if (row.type == _RType.lunch) {
          final lunch = neisLunch[col] ?? '';
          // 급식 메뉴 전체를 보여준다(첫 줄만 자르지 않음).
          result[col]![row.hour] = u.isNotEmpty ? u : lunch;
        } else {
          result[col]![row.hour] = u.isNotEmpty ? u : t;
        }
      }
    }
    return result;
  }

  List<_MergeGroup> _computeMerges(
    List<_RowDef> rows,
    List<double> offsets,
    Map<int, Map<int, String>> displayData,
  ) {
    final groups = <_MergeGroup>[];
    for (int col = 0; col < 7; col++) {
      int i = 0;
      while (i < rows.length) {
        if (rows[i].isDivider || rows[i].hour < 0) { i++; continue; }
        final text = displayData[col]?[rows[i].hour] ?? '';
        if (text.isEmpty) { i++; continue; }
        int j = i + 1;
        while (j < rows.length &&
               !rows[j].isDivider &&
               rows[j].hour >= 0 &&
               (displayData[col]?[rows[j].hour] ?? '') == text) {
          j++;
        }
        if (j - i >= 2) {
          groups.add(_MergeGroup(
            col: col, startRow: i, span: j - i,
            text: text, topOffset: offsets[i],
          ));
        }
        i = j;
      }
    }
    return groups;
  }

  Set<(int, int)> _buildMergeSet(List<_MergeGroup> groups) {
    final set = <(int, int)>{};
    for (final g in groups) {
      for (int k = g.startRow; k < g.startRow + g.span; k++) {
        set.add((g.col, k));
      }
    }
    return set;
  }

  // ── Cell edit / design handlers ───────────────────────────────

  void _editCell(BuildContext ctx, int col, int hour, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: ctx,
      builder: (dctx) {
        final sh = ctx.sh;
        return AlertDialog(
          backgroundColor: sh.card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22)),
          title: Text('${_dowNames[col]}요일 $hour:00 · 매주 반복',
              style: AppType.section.copyWith(
                  fontWeight: FontWeight.w800, color: sh.ink)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '예) 수학, 영어...',
              hintStyle: TextStyle(color: sh.inkFaint),
            ),
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _saveCell(dctx, col, hour, ctrl.text.trim()),
          ),
          actions: [
            if (current.isNotEmpty)
              TextButton(
                onPressed: () => _saveCell(dctx, col, hour, ''),
                style: TextButton.styleFrom(foregroundColor: sh.danger),
                child: const Text('삭제'),
              ),
            TextButton(
                onPressed: () => Navigator.pop(dctx), child: const Text('취소')),
            FilledButton(
              onPressed: () => _saveCell(dctx, col, hour, ctrl.text.trim()),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _saveCell(BuildContext ctx, int col, int hour, String text) {
    Navigator.pop(ctx);
    ref.read(recurringProvider.notifier).setCell(col, hour, text);
  }

  void _showDesignPanel(BuildContext ctx, int col, int hour, SpaceHourColors sh) {
    final current = ref.read(cellDesignProvider.notifier).forCell(col, hour);
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _DesignPanel(
        currentDesign: current,
        palette: _palette,
        sh: sh,
        onApply: (design) =>
            ref.read(cellDesignProvider.notifier).setDesign(col, hour, design),
      ),
    );
  }

  // 햄버거 메뉴 — 보기 모드 + 셀 디자인 토글 + 학교 연결 + 새로고침.
  void _openMenu(BuildContext ctx, SpaceHourColors sh) {
    showModalBottomSheet(
      context: ctx,
      builder: (mctx) => Container(
        color: sh.card,
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.palette_outlined,
                  color: _designMode ? sh.accent : sh.inkSoft),
              title: Text('셀 디자인',
                  style: AppType.body.copyWith(color: sh.ink)),
              subtitle: Text(_designMode ? '켜짐 — 셀을 눌러 꾸미기' : '꺼짐',
                  style: AppType.caption.copyWith(color: sh.inkSoft)),
              trailing: Switch.adaptive(
                value: _designMode,
                activeThumbColor: sh.accent,
                onChanged: (v) {
                  setState(() => _designMode = v);
                  Navigator.pop(mctx);
                },
              ),
              onTap: () {
                setState(() => _designMode = !_designMode);
                Navigator.pop(mctx);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.school_outlined, color: sh.inkSoft),
              title: Text('학교 연결 (NEIS)',
                  style: AppType.body.copyWith(color: sh.ink)),
              onTap: () {
                Navigator.pop(mctx);
                showNeisSetupModal(context);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.refresh_rounded, color: sh.inkSoft),
              title: Text('시간표·학사일정 새로고침',
                  style: AppType.body.copyWith(color: sh.ink)),
              onTap: () {
                Navigator.pop(mctx);
                ref.read(neisCacheProvider.notifier).refresh();
                ref.read(academicScheduleProvider.notifier).refresh();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final days = _weekDays();
    final now = DateTime.now();

    final neis = ref.watch(neisCacheProvider);
    final designs = ref.watch(cellDesignProvider);
    CellDesign designOf(int col, int hour) =>
        designs[cellDesignKey(col, hour)] ?? const CellDesign();

    final maxPeriod = _maxPeriod(neis.timetable);
    final rows = _buildRows(maxPeriod);
    final neisHourData = _buildNeisHourData(neis.timetable);
    final weekly = ref.watch(recurringProvider);
    final freeData = {
      for (int c = 0; c < 7; c++) c: Map<int, String>.from(weekly[c] ?? const {}),
    };
    final tplData = _buildTemplateData(days);
    final displayData =
        _buildDisplayData(neisHourData, tplData, freeData, neis.lunch, rows);
    final rowHeights = _rowHeights(rows);
    final offsets = _rowOffsets(rowHeights);
    final totalH = offsets.last;
    final mergeGroups = _computeMerges(rows, offsets, displayData);
    final mergeSet = _buildMergeSet(mergeGroups);

    final tableW = 7 * _dayColW;
    final bottomPad = 120.0 + MediaQuery.of(context).padding.bottom;

    // 오늘 위치로 자동 스크롤(첫 프레임 후).
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoScrollToToday());

    return Column(
      children: [
        // ── 제목 + 보기 모드 토글 + 햄버거 ─────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xs, Gap.lg, Gap.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('스케줄표',
                        style: AppType.title.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: sh.ink)),
                    const SizedBox(height: 2),
                    Text(
                        _designMode
                            ? '디자인 모드 — 셀을 눌러 꾸며요'
                            : '좌우로 넘겨 일주일을 봐요',
                        style: AppType.label.copyWith(
                            color: _designMode ? sh.accent : sh.inkSoft)),
                  ],
                ),
              ),
              _ViewModeToggle(
                compact: _compact,
                sh: sh,
                onChanged: (v) => setState(() => _compact = v),
              ),
              const SizedBox(width: Gap.sm),
              _HamburgerBtn(onTap: () => _openMenu(context, sh)),
            ],
          ),
        ),

        // ── 헤더 밴드 (고정) — 좌상단 코너 + 요일 헤더(가로 동기) ──
        SizedBox(
          height: _headerBandH,
          child: Row(
            children: [
              // 좌상단 코너
              Container(
                width: _labelW,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sh.card2,
                  border: Border(
                    right: BorderSide(color: _gridLine(sh), width: 1),
                    bottom: BorderSide(color: _gridLine(sh), width: 1.5),
                  ),
                ),
                child: Icon(Icons.schedule_rounded, size: 16, color: sh.inkSoft),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _headerH,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    width: tableW,
                    child: Row(
                      children: List.generate(7, (i) =>
                          _dayHeader(i, days[i], now, sh)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── 본문 — 좌측 고정 라벨열 + 가로/세로 스크롤 그리드 ──────
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 고정 시간/교시 라벨열 (세로 동기)
              SizedBox(
                width: _labelW,
                child: SingleChildScrollView(
                  controller: _labelV,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      for (int ri = 0; ri < rows.length; ri++)
                        _labelCell(rows[ri], rowHeights[ri], sh),
                      SizedBox(height: bottomPad),
                    ],
                  ),
                ),
              ),
              // 그리드 본문
              Expanded(
                child: SingleChildScrollView(
                  controller: _bodyV,
                  child: SingleChildScrollView(
                    controller: _bodyH,
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: tableW,
                          height: totalH,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // 그리드 셀
                              Column(
                                children: List.generate(rows.length, (ri) {
                                  final row = rows[ri];
                                  if (row.isDivider) {
                                    return Container(
                                      height: _divH,
                                      width: tableW,
                                      color: sh.accent.withValues(alpha: 0.28),
                                    );
                                  }
                                  return SizedBox(
                                    height: rowHeights[ri],
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: List.generate(7, (col) =>
                                          _gridCell(
                                            col: col, ri: ri, row: row,
                                            days: days, now: now,
                                            displayData: displayData,
                                            mergeSet: mergeSet,
                                            designOf: designOf,
                                            freeData: freeData, sh: sh,
                                          )),
                                    ),
                                  );
                                }),
                              ),
                              // 병합(연속 교시) 카드 오버레이
                              ...mergeGroups.map((mg) => _mergeCard(
                                    mg, rows, offsets, days, now,
                                    designOf, sh,
                                  )),
                            ],
                          ),
                        ),
                        SizedBox(height: bottomPad),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 요일 헤더 셀 ───────────────────────────────────────────────
  Widget _dayHeader(int i, DateTime date, DateTime now, SpaceHourColors sh) {
    final isTodayDow = now.weekday - 1 == i;
    final isSat = i == 5;
    final isSun = i == 6;
    final nameColor = isTodayDow
        ? Colors.white
        : isSun ? sh.sun : isSat ? sh.sat : sh.ink;
    return SizedBox(
      width: _dayColW,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sh.card2.withValues(alpha: sh.dark ? 1 : 0.6),
          border: Border(
            left: BorderSide(color: _gridLine(sh), width: 1),
            right: i == 6
                ? BorderSide(color: _gridLine(sh), width: 1)
                : BorderSide.none,
            bottom: BorderSide(color: _gridLine(sh), width: 1.5),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: isTodayDow
              ? BoxDecoration(
                  color: sh.accent,
                  borderRadius: BorderRadius.circular(999),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_dowNames[i],
                  style: AppType.body.copyWith(
                      fontSize: _compact ? 13 : 15,
                      fontWeight: FontWeight.w800,
                      color: nameColor)),
              if (!_compact) ...[
                const SizedBox(height: 1),
                Text('${date.day}',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isTodayDow
                            ? Colors.white.withValues(alpha: 0.85)
                            : sh.inkFaint)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── 시간/교시 라벨 셀 ──────────────────────────────────────────
  Widget _labelCell(_RowDef row, double h, SpaceHourColors sh) {
    if (row.isDivider) {
      return SizedBox(height: _divH, width: _labelW);
    }
    final isSchool = row.type == _RType.school;
    final isLunch = row.type == _RType.lunch;
    return Container(
      height: h,
      width: _labelW,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSchool
            ? sh.accentBg.withValues(alpha: 0.35)
            : isLunch
                ? sh.accentBg.withValues(alpha: 0.55)
                : sh.card2,
        border: Border(
          right: BorderSide(color: _gridLine(sh), width: 1),
          bottom: BorderSide(color: _gridLine(sh), width: 1),
        ),
      ),
      child: isSchool
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${row.period}',
                    style: TextStyle(
                        fontSize: _compact ? 14 : 17,
                        fontWeight: FontWeight.w800,
                        color: sh.accentInk,
                        height: 1.0)),
                Text('교시',
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: sh.accentInk.withValues(alpha: 0.7))),
              ],
            )
          : Text(row.label,
              style: TextStyle(
                fontSize: isLunch ? 12 : 11,
                color: isLunch ? sh.accentInk : sh.inkSoft,
                fontWeight: isLunch ? FontWeight.w700 : FontWeight.w500,
              )),
    );
  }

  // ── 그리드 셀(단일) ───────────────────────────────────────────
  Widget _gridCell({
    required int col,
    required int ri,
    required _RowDef row,
    required List<DateTime> days,
    required DateTime now,
    required Map<int, Map<int, String>> displayData,
    required Set<(int, int)> mergeSet,
    required CellDesign Function(int, int) designOf,
    required Map<int, Map<int, String>> freeData,
    required SpaceHourColors sh,
  }) {
    final isMerged = mergeSet.contains((col, ri));
    final isToday = du.isSameDay(days[col], now);
    final text = displayData[col]?[row.hour] ?? '';
    final design = designOf(col, row.hour);
    final isLunch = row.type == _RType.lunch;
    final filled = text.isNotEmpty;

    void onTap() {
      if (_designMode) {
        _showDesignPanel(context, col, row.hour, sh);
      } else {
        _editCell(context, col, row.hour, freeData[col]?[row.hour] ?? '');
      }
    }

    // 병합 멤버 셀은 비워 두고(오버레이 카드가 그려짐), 오늘 컬럼 틴트만.
    Widget? child;
    if (!isMerged && filled) {
      child = _classCard(
        text: text, isToday: isToday, isLunch: isLunch,
        design: design, sh: sh,
      );
    }

    // 빈 셀도 아주 옅게 채워 허전함 제거(오늘 컬럼은 살짝 보랏빛).
    final cellBg = isToday
        ? sh.accent.withValues(alpha: sh.dark ? 0.10 : 0.06)
        : sh.ink.withValues(alpha: sh.dark ? 0.022 : 0.012);
    // 오늘 컬럼 좌우 구분선만 보라색으로 살짝 강조.
    final sideColor =
        isToday ? sh.accent.withValues(alpha: 0.30) : _gridLine(sh);
    final sideWidth = isToday ? 1.0 : 0.5;

    return SizedBox(
      width: _dayColW,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: cellBg,
            border: Border(
              left: BorderSide(color: sideColor, width: sideWidth),
              right: (col == 6 || isToday)
                  ? BorderSide(color: sideColor, width: sideWidth)
                  : BorderSide.none,
              bottom: BorderSide(color: _gridLine(sh), width: 0.5),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // ── 수업 카드 — 셀을 거의 채우는 블록형 ───────────────────────
  Widget _classCard({
    required String text,
    required bool isToday,
    required bool isLunch,
    required CellDesign design,
    required SpaceHourColors sh,
    bool merged = false,
  }) {
    final display = getDisplaySubjectName(text, lunch: isLunch);
    // 급식 메뉴는 줄별로 더 많이 보이게(작은 폰트·여러 줄).
    final isMenu = isLunch;
    final maxLines = isMenu ? (_compact ? 4 : 6) : _maxLines;
    final font = isMenu ? (_compact ? 8.5 : 10.0) : _subjectFont;

    final baseBg = isLunch
        ? (isToday
            ? sh.accent.withValues(alpha: 0.20)
            : (sh.dark ? sh.card2 : const Color(0xFFFFF3EC)))
        : sh.accent.withValues(
            alpha: isToday ? (sh.dark ? 0.34 : 0.22) : (sh.dark ? 0.20 : 0.12));
    final textColor = design.textColor ?? (sh.dark ? sh.ink : sh.accentInk);

    // 병합(연속 교시) 카드는 은은한 대각 그라데이션으로 큰 면적을 채운다.
    final useGradient = design.bg == null && merged && !isLunch;

    return Container(
      width: double.infinity,
      height: double.infinity,
      margin: EdgeInsets.all(_d.cardMargin),
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: isMenu ? 5 : 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: design.bg ?? (useGradient ? null : baseBg),
        gradient: useGradient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  sh.accent.withValues(
                      alpha: isToday ? (sh.dark ? 0.40 : 0.26) : (sh.dark ? 0.24 : 0.15)),
                  sh.accent.withValues(
                      alpha: isToday ? (sh.dark ? 0.24 : 0.15) : (sh.dark ? 0.13 : 0.08)),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(_d.cardRadius),
        border: Border.all(
          color: isToday
              ? sh.accent.withValues(alpha: 0.55)
              : sh.ink.withValues(alpha: sh.dark ? 0.14 : 0.07),
          width: isToday ? 1.2 : 1,
        ),
      ),
      child: Text(
        display,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: font,
          height: isMenu ? 1.18 : 1.2,
          letterSpacing: -0.2,
          color: textColor,
          fontWeight: design.bold ? FontWeight.w800 : FontWeight.w700,
        ),
      ),
    );
  }

  // ── 병합(연속 교시) 오버레이 카드 ─────────────────────────────
  Widget _mergeCard(
    _MergeGroup mg,
    List<_RowDef> rows,
    List<double> offsets,
    List<DateTime> days,
    DateTime now,
    CellDesign Function(int, int) designOf,
    SpaceHourColors sh,
  ) {
    final row = rows[mg.startRow];
    final isToday = du.isSameDay(days[mg.col], now);
    final isLunch = row.type == _RType.lunch;
    final design = designOf(mg.col, row.hour);
    final top = offsets[mg.startRow];
    final height = offsets[mg.startRow + mg.span] - top;
    return Positioned(
      top: top,
      left: mg.col * _dayColW,
      width: _dayColW,
      height: height,
      child: IgnorePointer(
        child: _classCard(
          text: mg.text, isToday: isToday, isLunch: isLunch,
          design: design, sh: sh, merged: true,
        ),
      ),
    );
  }

  // 그리드 선은 은은하게 — 카드가 주인공이 되도록.
  Color _gridLine(SpaceHourColors sh) =>
      sh.ink.withValues(alpha: sh.dark ? 0.10 : 0.07);
}

// ─── 보기 모드 토글 (넓게 / 압축) ─────────────────────────────────
class _ViewModeToggle extends StatelessWidget {
  final bool compact;
  final SpaceHourColors sh;
  final ValueChanged<bool> onChanged;
  const _ViewModeToggle(
      {required this.compact, required this.sh, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: sh.card2,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: sh.ink.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          _seg('넓게', !compact, () => onChanged(false)),
          _seg('압축', compact, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _seg(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: active ? sh.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : sh.inkSoft)),
      ),
    );
  }
}

// ─── 햄버거 버튼 ──────────────────────────────────────────────────
class _HamburgerBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _HamburgerBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: sh.card2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sh.ink.withValues(alpha: 0.06)),
        ),
        child: Icon(Icons.menu_rounded, size: 20, color: sh.inkSoft),
      ),
    );
  }
}

// ─── Design panel bottom sheet ────────────────────────────────────

class _DesignPanel extends StatefulWidget {
  final CellDesign currentDesign;
  final List<Color> palette;
  final SpaceHourColors sh;
  final void Function(CellDesign) onApply;

  const _DesignPanel({
    required this.currentDesign,
    required this.palette,
    required this.sh,
    required this.onApply,
  });

  @override
  State<_DesignPanel> createState() => _DesignPanelState();
}

class _DesignPanelState extends State<_DesignPanel> {
  late Color? _bg;
  late bool _bold;

  @override
  void initState() {
    super.initState();
    _bg = widget.currentDesign.bg;
    _bold = widget.currentDesign.bold;
  }

  @override
  Widget build(BuildContext context) {
    final sh = widget.sh;
    return Container(
      decoration: BoxDecoration(
        color: sh.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: sh.ink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(children: [
            Text('셀 디자인', style: AppType.section.copyWith(
                fontWeight: FontWeight.w800, color: sh.ink)),
            const Spacer(),
            TextButton(
              onPressed: () {
                widget.onApply(const CellDesign());
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: sh.danger),
              child: const Text('초기화'),
            ),
          ]),
          const SizedBox(height: Gap.md),
          Text('배경색', style: AppType.caption.copyWith(color: sh.inkSoft)),
          const SizedBox(height: Gap.xs),
          Wrap(
            spacing: Gap.sm,
            children: [
              GestureDetector(
                onTap: () => setState(() => _bg = null),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _bg == null ? sh.ink : sh.border, width: 2),
                  ),
                  child: const Center(child: Text('✕',
                      style: TextStyle(fontSize: 12, color: Color(0xFF888888)))),
                ),
              ),
              ...widget.palette.map((c) => GestureDetector(
                onTap: () => setState(() => _bg = c),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _bg == c ? sh.ink : Colors.transparent, width: 2),
                    boxShadow: _bg == c
                        ? [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 6)]
                        : null,
                  ),
                ),
              )),
            ],
          ),
          const SizedBox(height: Gap.md),
          Row(children: [
            Text('굵게', style: AppType.caption.copyWith(color: sh.inkSoft)),
            const SizedBox(width: Gap.sm),
            Switch(
              value: _bold,
              onChanged: (v) => setState(() => _bold = v),
            ),
          ]),
          const SizedBox(height: Gap.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onApply(CellDesign(bg: _bg, bold: _bold));
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: sh.accent,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('적용',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
