import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';

/// 스케줄표 셀 디자인(배경색/글자색/굵게). 키: '${col}_$hour'.
class CellDesign {
  final Color? bg;
  final Color? textColor;
  final bool bold;
  const CellDesign({this.bg, this.textColor, this.bold = false});

  bool get isEmpty => bg == null && textColor == null && !bold;

  static CellDesign fromJson(Map<String, dynamic> j) => CellDesign(
        bg: j['bg'] != null ? _hex(j['bg'] as String) : null,
        textColor: j['color'] != null ? _hex(j['color'] as String) : null,
        bold: j['bold'] == true,
      );

  Map<String, dynamic> toJson() => {
        if (bg != null) 'bg': _toHex(bg!),
        if (textColor != null) 'color': _toHex(textColor!),
        if (bold) 'bold': true,
      };

  static Color _hex(String h) {
    final s = h.replaceAll('#', '');
    return Color(int.parse(s.length == 6 ? 'FF$s' : s, radix: 16));
  }

  static String _toHex(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}

String cellDesignKey(int col, int hour) => '${col}_$hour';

class CellDesignNotifier extends Notifier<Map<String, CellDesign>> {
  @override
  Map<String, CellDesign> build() => _load();

  Map<String, CellDesign> _load() {
    final raw = LocalStore.instance.getString(StorageKeys.cellDesign);
    final out = <String, CellDesign>{};
    if (raw == null) return out;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      for (final e in map.entries) {
        if (e.value is Map<String, dynamic>) {
          out[e.key] = CellDesign.fromJson(e.value as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return out;
  }

  void _persist() {
    LocalStore.instance.setString(
      StorageKeys.cellDesign,
      jsonEncode(state.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  CellDesign forCell(int col, int hour) =>
      state[cellDesignKey(col, hour)] ?? const CellDesign();

  void setDesign(int col, int hour, CellDesign design) {
    final next = Map<String, CellDesign>.from(state);
    final key = cellDesignKey(col, hour);
    if (design.isEmpty) {
      next.remove(key);
    } else {
      next[key] = design;
    }
    state = next;
    _persist();
  }

  /// 계정 전환/클라우드 pull 후 다시 읽기.
  void reload() => state = _load();
}

final cellDesignProvider =
    NotifierProvider<CellDesignNotifier, Map<String, CellDesign>>(
        CellDesignNotifier.new);
