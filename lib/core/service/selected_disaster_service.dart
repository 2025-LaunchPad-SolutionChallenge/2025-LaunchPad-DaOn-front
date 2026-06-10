import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SelectedDisasterService {
  static final SelectedDisasterService instance = SelectedDisasterService._();
  SelectedDisasterService._();

  static const _storageKey = 'selected_disaster_id';
  static const _storage = FlutterSecureStorage();

  final ValueNotifier<int?> selectedId = ValueNotifier<int?>(null);

  Future<void> initFromStorage() async {
    if (selectedId.value != null) return;
    final saved = await _storage.read(key: _storageKey);
    if (saved != null) {
      selectedId.value = int.tryParse(saved);
      if (kDebugMode) debugPrint('[재난 선택] 저장된 userDisasterId 복원: ${selectedId.value}');
    }
  }

  Future<void> select(int id) async {
    if (kDebugMode) debugPrint('[재난 선택] userDisasterId=$id');
    selectedId.value = id;
    await _storage.write(key: _storageKey, value: id.toString());
  }

  Future<void> clear() async {
    selectedId.value = null;
    await _storage.delete(key: _storageKey);
  }
}
