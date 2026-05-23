import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class SQLiteStorage {
  SQLiteStorage._();

  static Database? _database;
  static final Map<String, SQLiteBox<dynamic>> _boxes =
      <String, SQLiteBox<dynamic>>{};

  static Future<void> initFlutter() async {
    if (_database != null) {
      return;
    }

    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, 'chpa_sqlite_store.db');

    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE storage_entries (
            box_name TEXT NOT NULL,
            entry_key TEXT NOT NULL,
            value_type TEXT NOT NULL,
            text_value TEXT,
            blob_value BLOB,
            updated_at INTEGER NOT NULL,
            PRIMARY KEY (box_name, entry_key)
          )
        ''');
      },
    );
  }

  static Future<SQLiteBox<T>> openBox<T>(String name) async {
    await initFlutter();

    final existing = _boxes[name];
    if (existing != null) {
      return existing as SQLiteBox<T>;
    }

    final box = SQLiteBox<T>._(name, _database!);
    await box._load();
    box._bindListenable();
    _boxes[name] = box;
    return box;
  }

  static SQLiteBox<T> box<T>(String name) {
    final box = _boxes[name];
    if (box == null) {
      throw StateError('SQLite box "$name" has not been opened yet.');
    }
    return box as SQLiteBox<T>;
  }
}

class SQLiteBox<T> {
  SQLiteBox._(this.name, this._database)
    : _controller = StreamController<SQLiteBoxEvent>.broadcast(),
      _listenable = _SQLiteBoxListenable();

  final String name;
  final Database _database;
  final StreamController<SQLiteBoxEvent> _controller;
  final _SQLiteBoxListenable _listenable;
  final LinkedHashMap<String, dynamic> _cache = LinkedHashMap<String, dynamic>();

  void _bindListenable() {
    _listenable._setBox(this);
  }

  Future<void> _load() async {
    final rows = await _database.query(
      'storage_entries',
      where: 'box_name = ?',
      whereArgs: <Object>[name],
      orderBy: 'updated_at ASC',
    );

    for (final row in rows) {
      final key = row['entry_key'] as String;
      _cache[key] = _decodeRow(row);
    }
  }

  Iterable<dynamic> get keys => _cache.keys;

  Iterable<dynamic> get values => _cache.values;

  dynamic get(dynamic key) => _cache[key.toString()];

  bool containsKey(dynamic key) => _cache.containsKey(key.toString());

  Future<void> put(dynamic key, dynamic value) async {
    final keyString = key.toString();
    final encoded = _encodeValue(value);

    await _database.insert(
      'storage_entries',
      <String, Object?>{
        'box_name': name,
        'entry_key': keyString,
        'value_type': encoded.type,
        'text_value': encoded.textValue,
        'blob_value': encoded.blobValue,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _cache[keyString] = encoded.cachedValue;
    _notify(SQLiteBoxEvent(key: keyString, value: encoded.cachedValue));
  }

  Future<void> delete(dynamic key) async {
    final keyString = key.toString();

    await _database.delete(
      'storage_entries',
      where: 'box_name = ? AND entry_key = ?',
      whereArgs: <Object>[name, keyString],
    );

    _cache.remove(keyString);
    _notify(SQLiteBoxEvent(key: keyString, value: null, deleted: true));
  }

  Stream<SQLiteBoxEvent> watch({dynamic key}) {
    if (key == null) {
      return _controller.stream;
    }

    final keyString = key.toString();
    return _controller.stream.where(
      (SQLiteBoxEvent event) => event.key == keyString,
    );
  }

  ValueListenable<SQLiteBox<T>> listenable() {
    return _listenable as ValueListenable<SQLiteBox<T>>;
  }

  void _notify(SQLiteBoxEvent event) {
    _controller.add(event);
    _listenable._notify(this);
  }

  dynamic _decodeRow(Map<String, Object?> row) {
    final valueType = row['value_type'] as String? ?? 'string';

    switch (valueType) {
      case 'blob':
        return row['blob_value'] as Uint8List?;
      case 'string':
        return row['text_value'] as String?;
      case 'json':
      case 'primitive':
        final textValue = row['text_value'] as String?;
        if (textValue == null || textValue.isEmpty) {
          return null;
        }
        return jsonDecode(textValue);
      default:
        return row['text_value'];
    }
  }

  _EncodedValue _encodeValue(dynamic value) {
    if (value == null) {
      return const _EncodedValue(
        type: 'primitive',
        textValue: 'null',
        cachedValue: null,
      );
    }

    if (value is Uint8List) {
      return _EncodedValue(
        type: 'blob',
        blobValue: value,
        cachedValue: value,
      );
    }

    if (value is String) {
      return _EncodedValue(
        type: 'string',
        textValue: value,
        cachedValue: value,
      );
    }

    if (value is num || value is bool) {
      return _EncodedValue(
        type: 'primitive',
        textValue: jsonEncode(value),
        cachedValue: value,
      );
    }

    if (value is Map || value is List) {
      return _EncodedValue(
        type: 'json',
        textValue: jsonEncode(value),
        cachedValue: value,
      );
    }

    try {
      final dynamic jsonValue = (value as dynamic).toJson();
      return _EncodedValue(
        type: 'json',
        textValue: jsonEncode(jsonValue),
        cachedValue: jsonValue,
      );
    } catch (_) {
      return _EncodedValue(
        type: 'string',
        textValue: value.toString(),
        cachedValue: value.toString(),
      );
    }
  }
}

class SQLiteBoxEvent {
  const SQLiteBoxEvent({
    required this.key,
    required this.value,
    this.deleted = false,
  });

  final String key;
  final dynamic value;
  final bool deleted;
}

class _SQLiteBoxListenable extends ChangeNotifier
    implements ValueListenable<SQLiteBox<dynamic>> {
  SQLiteBox<dynamic>? _box;

  @override
  SQLiteBox<dynamic> get value {
    if (_box == null) {
      throw StateError('SQLiteBoxListenable has not been initialized.');
    }
    return _box!;
  }

  void _notify(SQLiteBox<dynamic> box) {
    _box = box;
    notifyListeners();
  }

  void _setBox(SQLiteBox<dynamic> box) {
    _box = box;
  }
}

class _EncodedValue {
  const _EncodedValue({
    required this.type,
    this.textValue,
    this.blobValue,
    required this.cachedValue,
  });

  final String type;
  final String? textValue;
  final Uint8List? blobValue;
  final dynamic cachedValue;
}
