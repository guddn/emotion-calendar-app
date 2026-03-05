//isar로 database 구현
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
  
part 'diary.g.dart';

@collection
class Diary {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late DateTime date;

  late String content;
  late String summary;
  late String emotion;
  late String colorHex;
}

class DiaryDatabase {
  DiaryDatabase._();

  static final DiaryDatabase instance = DiaryDatabase._();

  Isar? _isar;
  Future<void>? _initFuture;

  Future<void> init() async {
    if (_isar != null && _isar!.isOpen) {
      return;
    }

    _initFuture ??= _openIsar();
    try {
      await _initFuture;
    } catch (_) {
      _initFuture = null;
      rethrow;
    }
  }

  Future<void> _openIsar() async {
    final directoryPath = await _resolveDirectoryPath();

    _isar = await Isar.open(
      [DiarySchema],
      directory: directoryPath,
      name: 'emotion_calendar_db',
      inspector: kDebugMode,
    );
  }

  Future<Isar?> _getReadyIsar() async {
    try {
      await init();
    } catch (e, st) {
      debugPrint('Isar init failed: $e');
      debugPrintStack(stackTrace: st);
      return null;
    }

    final isar = _isar;
    if (isar == null || !isar.isOpen) {
      return null;
    }

    return isar;
  }

  Future<String> _resolveDirectoryPath() async {
    if (kIsWeb) {
      return '';
    }

    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }

  DateTime normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

  Future<void> upsertDiary({
    required DateTime date,
    required String content,
    required String summary,
    required String emotion,
    required String colorHex,
  }) async {
    final isar = _isar;
    if (isar == null || !isar.isOpen) {
      throw StateError('Isar is not initialized. Call DiaryDatabase.init() first.');
    }

    final targetDate = normalizeDate(date);

    await isar.writeTxn(() async {
      final items = await isar.collection<Diary>().where().findAll();
      Diary? existing;
      for (final item in items) {
        if (item.date == targetDate) {
          existing = item;
          break;
        }
      }

      final diary = existing ?? (Diary()..date = targetDate);

      diary.content = content;
      diary.summary = summary;
      diary.emotion = emotion;
      diary.colorHex = colorHex;

      await isar.collection<Diary>().put(diary);
    });
  }

  Future<void> upsertTodayDiary({
    required String content,
    required String summary,
    required String emotion,
    required String colorHex,
  }) {
    return upsertDiary(
      date: DateTime.now(),
      content: content,
      summary: summary,
      emotion: emotion,
      colorHex: colorHex,
    );
  }

  Future<Diary?> getDiaryByDate(DateTime date) async {
    final isar = _isar;
    if (isar == null || !isar.isOpen) {
      throw StateError('Isar is not initialized. Call DiaryDatabase.init() first.');
    }

    final target = normalizeDate(date);
    final items = await isar.collection<Diary>().where().findAll();
    for (final item in items) {
      if (item.date == target) {
        return item;
      }
    }
    return null;
  }

  Future<List<Diary>> getDiariesForMonth(DateTime month) async {
    final isar = _isar;
    if (isar == null || !isar.isOpen) {
      throw StateError('Isar is not initialized. Call DiaryDatabase.init() first.');
    }

    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);

    final items = await isar.collection<Diary>().where().findAll();
    return items.where((item) => !item.date.isBefore(first) && !item.date.isAfter(last)).toList();
  }
}