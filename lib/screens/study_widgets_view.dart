import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../widgets/study/study_time_input_card.dart';
import '../widgets/study/today_subject_study_card.dart';
import '../widgets/study/review_round_selector.dart';
import '../widgets/study/today_study_summary_card.dart';
import '../widgets/study/study_goal_card.dart';
import '../widgets/study/exam_prep_card.dart';
import '../widgets/study/study_routine_check_card.dart';
import 'theme_share_page.dart';

/// 추가 가능한 공부 위젯 종류.
enum StudyWidgetType {
  summary,
  focusTime,
  subjects,
  reviewRound,
  goal,
  exam,
  routine,
}

extension StudyWidgetTypeLabel on StudyWidgetType {
  String get label => switch (this) {
        StudyWidgetType.summary => '오늘 공부 요약',
        StudyWidgetType.focusTime => '순공시간',
        StudyWidgetType.subjects => '오늘 공부한 과목',
        StudyWidgetType.reviewRound => '회독 상태',
        StudyWidgetType.goal => '오늘 목표',
        StudyWidgetType.exam => '수행평가 · 시험',
        StudyWidgetType.routine => '루틴 체크',
      };
}

/// 공부 위젯 보관함 — 학생이 자주 쓰는 기록 위젯을 골라 캘린더/일간/시간표에
/// 추가하는 뷰. 좌우 viewer(ViewMode.study) 안에 포함되며 push 페이지가 아니다.
class StudyWidgetsView extends StatefulWidget {
  const StudyWidgetsView({super.key});

  @override
  State<StudyWidgetsView> createState() => _StudyWidgetsViewState();
}

class _StudyWidgetsViewState extends State<StudyWidgetsView> {
  // ── 데모 상태 (실제 저장 로직 연결 전까지 미리보기용) ──
  Duration _studyTime = const Duration(hours: 3, minutes: 20);
  ReviewRound _round = ReviewRound.second;

  final _subjects = const [
    StudySubjectEntry(
        subject: '수학',
        duration: Duration(hours: 1, minutes: 20),
        color: Color(0xFF5A2DF4)),
    StudySubjectEntry(
        subject: '영어',
        duration: Duration(minutes: 45),
        color: Color(0xFF2E9E6B)),
    StudySubjectEntry(
        subject: '국어',
        duration: Duration(minutes: 30),
        color: Color(0xFFE8554E)),
    StudySubjectEntry(
        subject: '과학',
        duration: Duration(minutes: 20),
        color: Color(0xFFE7913F)),
    StudySubjectEntry(subject: '사회', color: Color(0xFF3B82C4), active: false),
  ];

  List<StudyGoal> _goals = const [
    StudyGoal(title: '수학 문제집 30문제', done: true),
    StudyGoal(title: '영어 단어 80개'),
    StudyGoal(title: '국어 문학 복습'),
  ];

  final _exams = const [
    ExamItem(title: '영어 발표', dday: 3),
    ExamItem(title: '과학 보고서', dday: 5),
    ExamItem(title: '수학 단원평가', dday: 7),
  ];

  List<RoutineItem> _routines = const [
    RoutineItem(title: '아침 단어', streak: 12),
    RoutineItem(title: '학교 복습', streak: 5),
    RoutineItem(title: '수학 오답', streak: 8),
    RoutineItem(title: '자기 전 암기', streak: 3),
  ];

  // + 버튼 → 위젯을 현재 날짜/일간 화면에 추가 (지금은 SnackBar placeholder).
  void _addWidget(StudyWidgetType type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${type.label} 위젯을 추가했어요.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final goalProgress = _goals.isEmpty
        ? 0.0
        : _goals.where((g) => g.done).length / _goals.length;
    final activeSubjects = _subjects.where((s) => s.active).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, 120),
      children: [
        // ── 자체 헤더 (AppHeader는 study 모드에서 숨김) ──
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          child: Text('공부 위젯',
              style: AppType.title.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: sh.ink)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
          child: Text('자주 쓰는 공부 기록 위젯을 바로 가져와요',
              style: AppType.body.copyWith(color: sh.inkSoft)),
        ),

        // ── 오늘 공부 요약 ──
        TodayStudySummaryCard(
          studyTime: _studyTime,
          subjectCount: activeSubjects,
          reviewLabel: _round.label,
          goalProgress: goalProgress,
          onAdd: () => _addWidget(StudyWidgetType.summary),
        ),
        const SizedBox(height: 16),

        // ── 순공시간 입력 ──
        StudyTimeInputCard(
          studyTime: _studyTime,
          onChanged: (d) => setState(() => _studyTime = d),
          onManualInput: () => _snack('직접 입력은 준비 중이에요'),
          onAdd: () => _addWidget(StudyWidgetType.focusTime),
        ),
        const SizedBox(height: 16),

        // ── 오늘 공부한 과목 ──
        TodaySubjectStudyCard(
          subjects: _subjects,
          onSubjectTap: (s) => _snack('${s.subject} 상세는 준비 중이에요'),
          onAdd: () => _addWidget(StudyWidgetType.subjects),
        ),
        const SizedBox(height: 16),

        // ── 회독 상태 ──
        ReviewRoundSelector(
          selectedRound: _round,
          onChanged: (r) => setState(() => _round = r),
          onAdd: () => _addWidget(StudyWidgetType.reviewRound),
        ),
        const SizedBox(height: 16),

        // ── 오늘 목표 ──
        StudyGoalCard(
          goals: _goals,
          onToggle: (i) => setState(() {
            _goals = [
              for (int k = 0; k < _goals.length; k++)
                k == i ? _goals[k].copyWith(done: !_goals[k].done) : _goals[k],
            ];
          }),
          onAdd: () => _addWidget(StudyWidgetType.goal),
        ),
        const SizedBox(height: 16),

        // ── 수행평가 · 시험 ──
        ExamPrepCard(
          items: _exams,
          onTap: (e) => _snack('${e.title} 상세는 준비 중이에요'),
          onAdd: () => _addWidget(StudyWidgetType.exam),
        ),
        const SizedBox(height: 16),

        // ── 루틴 체크 ──
        StudyRoutineCheckCard(
          routines: _routines,
          onToggle: (i) => setState(() {
            _routines = [
              for (int k = 0; k < _routines.length; k++)
                if (k == i)
                  RoutineItem(
                    title: _routines[k].title,
                    done: !_routines[k].done,
                    streak: _routines[k].streak,
                  )
                else
                  _routines[k],
            ];
          }),
          onAdd: () => _addWidget(StudyWidgetType.routine),
        ),
        const SizedBox(height: 16),

        // ── 일정 테마 · 시간표 템플릿 공유 (옵션 A: 공부 위젯 안 섹션) ──
        _ShareEntry(
          sh: sh,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ThemeSharePage()),
          ),
        ),
      ],
    );
  }
}

// ─── 테마·템플릿 공유 진입 행 ────────────────────────────────────
class _ShareEntry extends StatelessWidget {
  final SpaceHourColors sh;
  final VoidCallback onTap;
  const _ShareEntry({required this.sh, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: sh.card,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: sh.ink.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sh.accentBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.ios_share_rounded,
                  size: 18, color: sh.accentInk),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('테마 · 템플릿 공유',
                      style: AppType.body.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: sh.ink)),
                  Text('일정 루틴과 시간표 템플릿을 공유해요',
                      style: AppType.label.copyWith(
                          fontSize: 12, color: sh.inkSoft)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: sh.inkFaint),
          ],
        ),
      ),
    );
  }
}
