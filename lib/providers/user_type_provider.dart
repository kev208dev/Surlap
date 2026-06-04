import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/storage_keys.dart';
import '../models/user_type.dart';
import '../storage/local_store.dart';

/// 사용자 유형(일반인/초·중·고·대) — 로그인 없이 기기에 로컬 저장.
///
/// null = 아직 선택 안 함(온보딩 전). 온보딩에서 선택하면 영속 저장된다.
/// 계정 스코프/동기화 대상이 아니다(기기 설정성 값).
class UserTypeNotifier extends Notifier<UserType?> {
  @override
  UserType? build() {
    return UserType.fromStorage(
      LocalStore.instance.getString(StorageKeys.userType),
    );
  }

  Future<void> set(UserType type) async {
    state = type;
    await LocalStore.instance.setString(
      StorageKeys.userType,
      type.storageValue,
    );
  }
}

final userTypeProvider =
    NotifierProvider<UserTypeNotifier, UserType?>(UserTypeNotifier.new);
