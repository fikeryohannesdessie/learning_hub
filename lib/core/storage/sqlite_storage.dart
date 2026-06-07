import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../utils/api_config.dart';

class _WebSQLiteClient {
  String get _baseUrl => '${ApiConfig.baseUrl}/storage';

  Future<List<Map<String, Object?>>> getBoxEntries(String boxName) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/${Uri.encodeComponent(boxName)}'),
    );

    if (response.statusCode != 200 || response.body.isEmpty) {
      return <Map<String, Object?>>[];
    }

    final raw = jsonDecode(response.body);
    if (raw is! List) {
      return <Map<String, Object?>>[];
    }

    return raw
        .map((dynamic row) => Map<String, Object?>.from(row as Map))
        .toList();
  }

  Future<void> putEntry(String boxName, String key, _EncodedValue value) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/${Uri.encodeComponent(boxName)}/${Uri.encodeComponent(key)}'),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, Object?>{
        'value_type': value.type,
        'text_value': value.textValue,
        'blob_value': value.blobValue == null
            ? null
            : base64Encode(value.blobValue!),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to store web SQLite entry for box "$boxName" and key "$key".',
      );
    }
  }

  Future<void> deleteEntry(String boxName, String key) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/${Uri.encodeComponent(boxName)}/${Uri.encodeComponent(key)}'),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to delete web SQLite entry for box "$boxName" and key "$key".',
      );
    }
  }
}

class SQLiteStorage {
  SQLiteStorage._();

  static Database? _database;
  static final _WebSQLiteClient _webClient = _WebSQLiteClient();
  static final Map<String, SQLiteBox<dynamic>> _boxes =
      <String, SQLiteBox<dynamic>>{};

  static Future<void> initFlutter() async {
    if (kIsWeb || _database != null) {
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

    final box = kIsWeb
        ? SQLiteBox<T>._web(name, _webClient)
        : SQLiteBox<T>._native(name, _database!);
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
  SQLiteBox._native(this.name, Database database)
    : _database = database,
      _webClient = null,
      _controller = StreamController<SQLiteBoxEvent>.broadcast(),
      _listenable = _SQLiteBoxListenable();

  SQLiteBox._web(this.name, _WebSQLiteClient webClient)
    : _database = null,
      _webClient = webClient,
      _controller = StreamController<SQLiteBoxEvent>.broadcast(),
      _listenable = _SQLiteBoxListenable();

  final String name;
  final Database? _database;
  final _WebSQLiteClient? _webClient;
  final StreamController<SQLiteBoxEvent> _controller;
  final _SQLiteBoxListenable _listenable;
  final LinkedHashMap<String, dynamic> _cache = LinkedHashMap<String, dynamic>();

  void _bindListenable() {
    _listenable._setBox(this);
  }

  Future<void> _load() async {
    final List<Map<String, Object?>> rows;
    if (_webClient != null) {
      rows = await _webClient.getBoxEntries(name);
    } else {
      rows = await _database!.query(
        'storage_entries',
        where: 'box_name = ?',
        whereArgs: <Object>[name],
        orderBy: 'updated_at ASC',
      );
    }

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

    if (_webClient != null) {
      await _webClient.putEntry(name, keyString, encoded);
    } else {
      await _database!.insert(
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
    }

    _cache[keyString] = encoded.cachedValue;
    _notify(SQLiteBoxEvent(key: keyString, value: encoded.cachedValue));
  }

  Future<void> delete(dynamic key) async {
    final keyString = key.toString();

    if (_webClient != null) {
      await _webClient.deleteEntry(name, keyString);
    } else {
      await _database!.delete(
        'storage_entries',
        where: 'box_name = ? AND entry_key = ?',
        whereArgs: <Object>[name, keyString],
      );
    }

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
        final raw = row['blob_value'];
        if (raw == null) {
          return null;
        }
        if (raw is Uint8List) {
          return raw;
        }
        if (raw is List<int>) {
          return Uint8List.fromList(raw);
        }
        if (raw is String && raw.isNotEmpty) {
          return Uint8List.fromList(base64Decode(raw));
        }
        return null;
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
