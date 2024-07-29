// storage_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = FlutterSecureStorage();

  Future<void> saveUserProgress(String userId, int progress) async {
    await _storage.write(key: 'progress_$userId', value: progress.toString());
  }

  Future<int> getUserProgress(String userId) async {
    String? progress = await _storage.read(key: 'progress_$userId');
    return progress != null ? int.parse(progress) : 0;
  }

  Future<void> clearUserProgress(String userId) async {
    await _storage.delete(key: 'progress_$userId');
  }
}
