// LocalDB - SQLite Offline Storage (Drafts + Sync Queue)
// Enterprise: Offline-First Strategy - Luu ban nhap khi mat mang

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class LocalOutletDraft {
  final String localId;
  final String jsonData;
  final String syncStatus;
  final String? syncErrorLog;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int retryCount;

  LocalOutletDraft({
    required this.localId, required this.jsonData,
    this.syncStatus = 'PENDING', this.syncErrorLog,
    required this.createdAt, required this.updatedAt,
    this.retryCount = 0,
  });

  factory LocalOutletDraft.fromMap(Map<String, dynamic> map) {
    return LocalOutletDraft(
      localId: map['local_id'] as String,
      jsonData: map['json_data'] as String,
      syncStatus: map['sync_status'] as String? ?? 'PENDING',
      syncErrorLog: map['sync_error_log'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      retryCount: map['retry_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'local_id': localId, 'json_data': jsonData,
      'sync_status': syncStatus, 'sync_error_log': syncErrorLog,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'retry_count': retryCount,
    };
  }
}
class LocalDB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final pathStr = path.join(dbPath, "dms_offline.db");
    return await openDatabase(
      pathStr, version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute("""
      CREATE TABLE IF NOT EXISTS local_outlet_drafts (
        local_id TEXT PRIMARY KEY,
        json_data TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT "PENDING" CHECK (sync_status IN ("PENDING", "SYNCED", "FAILED")),
        sync_error_log TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0
      )
    """);
    await db.execute("CREATE INDEX IF NOT EXISTS idx_draft_sync_status ON local_outlet_drafts(sync_status)");
    await db.execute("""
      CREATE TABLE IF NOT EXISTS app_config (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    """);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  Future<void> saveDraft(LocalOutletDraft draft) async {
    final db = await database;
    await db.insert("local_outlet_drafts", draft.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<LocalOutletDraft>> getAllDrafts() async {
    final db = await database;
    final maps = await db.query("local_outlet_drafts", orderBy: "created_at DESC");
    return maps.map((m) => LocalOutletDraft.fromMap(m)).toList();
  }

  Future<LocalOutletDraft?> getDraftById(String localId) async {
    final db = await database;
    final maps = await db.query("local_outlet_drafts", where: "local_id = ?", whereArgs: [localId]);
    if (maps.isEmpty) return null;
    return LocalOutletDraft.fromMap(maps.first);
  }

  Future<List<LocalOutletDraft>> getPendingDrafts() async {
    final db = await database;
    final maps = await db.query("local_outlet_drafts",
      where: "sync_status IN (?, ?)",
      whereArgs: ["PENDING", "FAILED"],
      orderBy: "created_at ASC");
    return maps.map((m) => LocalOutletDraft.fromMap(m)).toList();
  }

  Future<void> updateSyncStatus(String localId, String status, {String? errorLog, int? retryCount}) async {
    final db = await database;
    await db.update("local_outlet_drafts", {
      "sync_status": status,
      "sync_error_log": errorLog,
      "retry_count": retryCount ?? 0,
      "updated_at": DateTime.now().toIso8601String(),
    }, where: "local_id = ?", whereArgs: [localId]);
  }

  Future<void> deleteDraft(String localId) async {
    final db = await database;
    await db.delete("local_outlet_drafts", where: "local_id = ?", whereArgs: [localId]);
  }

  Future<Map<String, int>> getDraftCounts() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT sync_status, COUNT(*) as count FROM local_outlet_drafts GROUP BY sync_status");
    final counts = <String, int>{"PENDING": 0, "SYNCED": 0, "FAILED": 0};
    for (final row in result) {
      counts[row["sync_status"] as String] = row["count"] as int;
    }
    return counts;
  }

  Future<String?> getConfig(String key) async {
    final db = await database;
    final maps = await db.query("app_config", where: "key = ?", whereArgs: [key]);
    if (maps.isEmpty) return null;
    return maps.first["value"] as String?;
  }

  Future<void> setConfig(String key, String value) async {
    final db = await database;
    await db.insert("app_config", {"key": key, "value": value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete("local_outlet_drafts");
    await db.delete("app_config");
  }
}
