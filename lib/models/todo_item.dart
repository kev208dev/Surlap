import 'dart:convert';

/// 일정(EventItem)과 분리된 별도 "할 일" 항목.
/// 우선순위(priority)와 완료 여부(done)를 가지며, 날짜는 선택값.
class TodoItem {
  final String id;
  final String title;
  final int priority;       // 1=높음, 2=보통, 3=낮음 (0=없음)
  final String? dateKey;    // 'YYYY-MM-DD' (없으면 날짜 미지정)
  final bool done;
  final String? createdAt;  // ISO8601

  const TodoItem({
    required this.id,
    required this.title,
    this.priority = 0,
    this.dateKey,
    this.done = false,
    this.createdAt,
  });

  bool get hasPriority => priority >= 1 && priority <= 3;

  TodoItem copyWith({
    String? id,
    String? title,
    int? priority,
    Object? dateKey = _noChange,
    bool? done,
    String? createdAt,
  }) =>
      TodoItem(
        id: id ?? this.id,
        title: title ?? this.title,
        priority: priority ?? this.priority,
        dateKey: dateKey == _noChange ? this.dateKey : dateKey as String?,
        done: done ?? this.done,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        't': title,
        if (priority != 0) 'p': priority,
        if (dateKey != null) 'd': dateKey,
        if (done) 'done': true,
        if (createdAt != null) 'created_at': createdAt,
      };

  factory TodoItem.fromJson(Map<String, dynamic> j) => TodoItem(
        id: (j['id'] ?? '').toString(),
        title: (j['t'] ?? '').toString(),
        priority: (j['p'] as num?)?.toInt() ?? 0,
        dateKey: j['d'] as String?,
        done: j['done'] == true,
        createdAt: j['created_at'] as String?,
      );
}

// copyWith에서 "변경 안 함"과 "null로 변경"을 구분하기 위한 sentinel.
const Object _noChange = Object();

/// 전체 Todo 리스트 직렬화. 형태: `[ item, ... ]`
List<TodoItem> todosFromJson(String raw) {
  try {
    final list = jsonDecode(raw) as List;
    return list
        .whereType<Map<String, dynamic>>()
        .map(TodoItem.fromJson)
        .toList();
  } catch (_) {
    return [];
  }
}

String todosToJson(List<TodoItem> todos) =>
    jsonEncode(todos.map((t) => t.toJson()).toList());
