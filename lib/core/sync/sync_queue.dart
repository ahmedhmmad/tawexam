import '../constants/storage_keys.dart';
import '../storage/local_storage_service.dart';
import 'sync_task.dart';

class SyncQueue {
  const SyncQueue(this._storage);

  final LocalStorageService _storage;

  Future<void> enqueue(SyncTask task) async {
    final tasks = await pendingTasks();
    final updatedTasks = [...tasks, task];
    await _save(updatedTasks);
  }

  Future<List<SyncTask>> pendingTasks() async {
    final raw = await _storage.read<List<dynamic>>(
      StorageKeys.syncBox,
      StorageKeys.syncQueue,
    );
    return (raw ?? const []).map(_mapTask).toList(growable: false);
  }

  Future<void> remove(String id) async {
    final tasks = await pendingTasks();
    await _save(tasks.where((task) => task.id != id).toList());
  }

  Future<void> replace(SyncTask task) async {
    final tasks = await pendingTasks();
    await _save([
      for (final current in tasks) current.id == task.id ? task : current,
    ]);
  }

  Future<void> clear() {
    return _storage.write(
      StorageKeys.syncBox,
      StorageKeys.syncQueue,
      <dynamic>[],
    );
  }

  SyncTask _mapTask(dynamic value) {
    return SyncTask.fromJson(Map<dynamic, dynamic>.from(value as Map));
  }

  Future<void> _save(List<SyncTask> tasks) {
    final raw = tasks.map((task) => task.toJson()).toList(growable: false);
    return _storage.write(StorageKeys.syncBox, StorageKeys.syncQueue, raw);
  }
}
