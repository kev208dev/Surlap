# 무인 작업 진행 기록 (feature/polish)

## feature/polish 진행 현황

### 디자인 시안 정렬

| 화면 | 상태 | 비고 |
|------|------|------|
| 상단 chrome — 날짜 앵커·뷰 세그먼트·4탭 하단 네비 | [완료] | feat(chrome) 커밋 |
| 월간 뷰 | [완료] | 기존 구조 시안과 일치, 추가 변경 불필요 |
| 연간 뷰 | [완료] | 3열 미니카드, 현재 월 강조 테두리 확인 |
| 주간 뷰 | [완료] | 7컬럼 시간 그리드 확인 |
| 일별 뷰 | [완료] | 시간축 + 현재 시각 표시선 확인 |
| 시간표 뷰 | [완료] | 주간 그리드 확인, NEIS 연동 설정 접근 가능 |
| 테마 관리 | [건너뜀] | 기능 동작 이상 없음, 미세 시각 폴리시는 다음 이터레이션 |

### 히어로 전환 점검

| 항목 | 상태 | 비고 |
|------|------|------|
| 연간→월간 커스텀 오버레이 줌 전환 | [완료] | easeInOutCubic 360ms, 콘텐츠 스케일 — 이미 구현됨 |

### 앱 이름 통일

| 항목 | 상태 | 비고 |
|------|------|------|
| android:label | [완료] | HourSpace |
| iOS CFBundleDisplayName | [완료] | HourSpace |
| UI 텍스트 (AppHeader) | [완료] | HourSpace |

### 배포 준비

| 항목 | 상태 | 비고 |
|------|------|------|
| flutter analyze 경고 | [완료] | 0 이슈 |
| 디버그 print | [완료] | 전부 debugPrint (릴리스 모드 자동 억제) |
| Android 빌드 설정 점검 | [완료] | applicationId/권한/딥링크 확인 |
| RELEASE_CHECKLIST.md 작성 | [완료] | 직접 해야 할 항목 목록화 |

### 확인 필요 (위험/미검증)
- 릴리스 키 서명 미설정 (debug key 사용 중) → RELEASE_CHECKLIST.md 참고
- assetlinks.json에 릴리스 SHA256 미추가 → RELEASE_CHECKLIST.md 참고
- Supabase RLS 수동 검증 필요 → RELEASE_CHECKLIST.md 참고

---

## 이전 작업 기록 (feature/finish-remaining)

### Baseline
- 커밋: d81ddd9 (master)
- 브랜치: feature/finish-remaining

### 1. 날짜 메모 → 월간 뷰 표시 (calendar-memos-v1)
상태: **완료** ✓
- month_grid.dart: 6×7 그리드 리팩토링, 앞쪽/뒤쪽 여백 셀을 _MemoCell로 교체
- month_view.dart: memosProvider 연결, _editMemo 다이얼로그 추가
- month_view.dart: onDayLongPress → _showDayActionMenu로 통합

### 2. 날짜 셀 위젯 입력값 표시 (calendar-day-widget-values-v1)
상태: **완료** ✓
- day_cell.dart: applicableTemplates, dateWidgetValues 파라미터 추가
- day_cell.dart: _buildWidgetRows() — 빈 값 스킵, 최대 3행, dimmed opacity
- month_grid.dart: dayTemplatesProvider/widgetValuesProvider 연결, _buildDayCell helper

### 3. 반복 시간표 → 시간표 뷰 반영 (timetable-template + overrides)
상태: **완료** ✓
- timetable_view.dart: _buildTemplateData() — JSON 파싱, weekdays/날짜범위/override/extra 처리
- timetable_view.dart: 우선순위 user > NEIS > template 적용

### 4. NEIS 데이터 화면 연결
상태: **완료** ✓
- timetable_view.dart: _fetchNeisIfNeeded() initState에서 비동기 호출
- timetable_view.dart: 교시→시간 매핑, 급식 첫 메뉴 점심 행 표시

### 1.5. 비주얼 정밀 보정
상태: **완료** ✓
- bottom_nav_bar.dart: minWidth 46→52, padding horizontal 8→10

### 5. 연속 보기 (ContinuousMonthView)
상태: **완료** ✓
- continuous_month_view.dart: PageView.builder + PageController 기반 무한 월간 스크롤
- _pageToYearMonth / _yearMonthToPage: 월 산술 계산
- ref.listen<ViewState>: 외부 nav 변경 시 PageController 동기화 (피드백 루프 차단)
- main_shell.dart: settings.continuousView에 따라 MonthView ↔ ContinuousMonthView 전환

### 6. 이미지 저장 / 공유
상태: **완료** ✓
- screenshot_util.dart: captureAndShare() — RepaintBoundary → PNG → share_plus
- app_header.dart: iOS 공유 아이콘 버튼 추가
- main_shell.dart: RepaintBoundary(key: screenshotKey) 래핑

### 7. 클라우드 백업 (Supabase)
상태: **완료** ✓
- backup_modal.dart: 로그인 시 클라우드 동기화 섹션 추가
- _cloudPush: EventsSync + UserDataSync 업로드
- _cloudPull: UserDataSync 다운로드 + provider 무효화

### 9. 테마 공유 Supabase
상태: **완료** ✓
- theme_share_service.dart: shareTheme (upload) / fetchByCode (download)
- theme_manager_modal.dart: 공유 버튼, 초대 코드 배지, 가져오기 다이얼로그

### 10. 생일 연락처
상태: **완료** ✓
- birthdays_provider.dart: BirthdaysNotifier — addAll/remove/clear/eventsForYear
- vcf_parser.dart: FN/N/BDAY(YYYYMMDD, MMDD) 파싱
- sidebar_drawer.dart: .vcf 파일 선택 → parseVcf → addAll
- month_view.dart + continuous_month_view.dart: 🎂 생일 이벤트 filteredEvents에 병합

### 8. Hero 전환 애니메이션
상태: 스킵 (기존 AnimatedSwitcher + SlideTransition으로 충분)

### 11. 튜토리얼 coach mark
상태: 대기

### 12. (선택) 월간 주 단위 스냅
상태: 대기
