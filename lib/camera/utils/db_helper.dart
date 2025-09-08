/*
* Created by : Syed Bipul Rahman
* Author     : Syed Bipul Rahman
* github     : @Syed-bipul-rahman
* All right reserved
*
* */
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'log_helper.dart';

// Base model interface for type safety
abstract class DatabaseModel {
  Map<String, dynamic> toMap();

  String get tableName;

  String get primaryKey => 'id';
}

// Table schema definition
class TableSchema {
  final String name;
  final Map<String, String> columns; // column_name: SQL_TYPE
  final List<String> constraints;
  final List<String> indexes;

  TableSchema({
    required this.name,
    required this.columns,
    this.constraints = const [],
    this.indexes = const [],
  });

  String get createTableSQL {
    final columnDefs = columns.entries
        .map((e) => '${e.key} ${e.value}')
        .toList();

    columnDefs.addAll(constraints);

    return 'CREATE TABLE $name (${columnDefs.join(', ')})';
  }
}

// Query builder for common operations
class QueryBuilder {
  String _table = '';
  List<String> _columns = ['*'];
  String _where = '';
  List<dynamic> _whereArgs = [];
  String _orderBy = '';
  String _groupBy = '';
  String _having = '';
  int? _limit;
  int? _offset;

  QueryBuilder table(String tableName) {
    _table = tableName;
    return this;
  }

  QueryBuilder select(List<String> columns) {
    _columns = columns;
    return this;
  }

  QueryBuilder where(String condition, [List<dynamic>? args]) {
    _where = _where.isEmpty ? condition : '$_where AND $condition';
    if (args != null) _whereArgs.addAll(args);
    return this;
  }

  QueryBuilder orderBy(String column, {bool desc = false}) {
    _orderBy = _orderBy.isEmpty
        ? '$column${desc ? ' DESC' : ''}'
        : '$_orderBy, $column${desc ? ' DESC' : ''}';
    return this;
  }

  QueryBuilder groupBy(String columns) {
    _groupBy = columns;
    return this;
  }

  QueryBuilder having(String condition) {
    _having = condition;
    return this;
  }

  QueryBuilder limit(int count) {
    _limit = count;
    return this;
  }

  QueryBuilder offset(int count) {
    _offset = count;
    return this;
  }

  Map<String, dynamic> build() {
    return {
      'table': _table,
      'columns': _columns,
      'where': _where.isEmpty ? null : _where,
      'whereArgs': _whereArgs.isEmpty ? null : _whereArgs,
      'orderBy': _orderBy.isEmpty ? null : _orderBy,
      'groupBy': _groupBy.isEmpty ? null : _groupBy,
      'having': _having.isEmpty ? null : _having,
      'limit': _limit,
      'offset': _offset,
    };
  }
}

class DatabaseHelper {
  static Database? _database;
  final String dbName;
  final int version;
  final Map<String, TableSchema> _schemas = {};

  DatabaseHelper({required this.dbName, this.version = 1});

  // Register table schemas
  void registerSchema(TableSchema schema) {
    LoggerHelper.info(
      "==========>> Registering schema for table: ${schema.name} <<==========",
    );
    _schemas[schema.name] = schema;
    LoggerHelper.info(
      "==========>> Schema registered successfully for table: ${schema.name} <<==========",
    );
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, dbName);

      return await openDatabase(
        path,
        version: version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw DatabaseException('Failed to initialize database: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.transaction((txn) async {
        for (final schema in _schemas.values) {
          await txn.execute(schema.createTableSQL);

          // Create indexes
          for (final index in schema.indexes) {
            await txn.execute(index);
          }
        }
      });
    } catch (e) {
      throw DatabaseException('Failed to create tables: $e');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Override this method for custom migration logic
  }

  // Enhanced insert with better error handling
  Future<int> insert(String tableName, Map<String, dynamic> data) async {
    try {
      final db = await database;
      await _ensureTableExists(db, tableName, data);
      return await db.insert(tableName, data);
    } catch (e) {
      throw DatabaseException('Failed to insert into $tableName: $e');
    }
  }

  // Type-safe insert for models
  Future<int> insertModel<T extends DatabaseModel>(T model) async {
    return await insert(model.tableName, model.toMap());
  }

  // Bulk insert with transaction
  Future<List<int>> bulkInsert(
    String tableName,
    List<Map<String, dynamic>> dataList,
  ) async {
    try {
      final db = await database;
      final results = <int>[];

      await db.transaction((txn) async {
        for (final data in dataList) {
          final result = await txn.insert(tableName, data);
          results.add(result);
        }
      });

      return results;
    } catch (e) {
      throw DatabaseException('Failed bulk insert into $tableName: $e');
    }
  }

  // Enhanced update
  Future<int> update(
    String tableName,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    try {
      final db = await database;
      return await db.update(
        tableName,
        data,
        where: where,
        whereArgs: whereArgs,
      );
    } catch (e) {
      throw DatabaseException('Failed to update $tableName: $e');
    }
  }

  // Update by ID (common operation)
  Future<int> updateById(
    String tableName,
    int id,
    Map<String, dynamic> data,
  ) async {
    return await update(tableName, data, where: 'id = ?', whereArgs: [id]);
  }

  // Enhanced delete
  Future<int> delete(
    String tableName, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    try {
      final db = await database;
      return await db.delete(tableName, where: where, whereArgs: whereArgs);
    } catch (e) {
      throw DatabaseException('Failed to delete from $tableName: $e');
    }
  }

  // Delete by ID
  Future<int> deleteById(String tableName, int id) async {
    return await delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Enhanced query with builder support
  Future<List<Map<String, dynamic>>> query(
    String tableName, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await database;
      return await db.query(
        tableName,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw DatabaseException('Failed to query $tableName: $e');
    }
  }

  // Query with builder
  Future<List<Map<String, dynamic>>> queryWithBuilder(
    QueryBuilder builder,
  ) async {
    final params = builder.build();
    return await query(
      params['table'],
      columns: params['columns'],
      where: params['where'],
      whereArgs: params['whereArgs'],
      orderBy: params['orderBy'],
      groupBy: params['groupBy'],
      having: params['having'],
      limit: params['limit'],
      offset: params['offset'],
    );
  }

  // Get single record
  Future<Map<String, dynamic>?> findById(String tableName, int id) async {
    final results = await query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isEmpty ? null : results.first;
  }

  // Get first record matching condition
  Future<Map<String, dynamic>?> findFirst(
    String tableName, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    final results = await query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: 1,
    );
    return results.isEmpty ? null : results.first;
  }

  // Count records
  Future<int> count(
    String tableName, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableName${where != null ? ' WHERE $where' : ''}',
        whereArgs,
      );
      return result.first['count'] as int;
    } catch (e) {
      throw DatabaseException('Failed to count records in $tableName: $e');
    }
  }

  // Execute raw query
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    try {
      final db = await database;
      return await db.rawQuery(sql, arguments);
    } catch (e) {
      throw DatabaseException('Failed to execute raw query: $e');
    }
  }

  // Execute raw SQL
  Future<void> execute(String sql, [List<dynamic>? arguments]) async {
    try {
      final db = await database;
      await db.execute(sql, arguments);
    } catch (e) {
      throw DatabaseException('Failed to execute SQL: $e');
    }
  }

  // Transaction support
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    try {
      final db = await database;
      return await db.transaction(action);
    } catch (e) {
      throw DatabaseException('Transaction failed: $e');
    }
  }

  Future<void> _ensureTableExists(
    Database db,
    String tableName,
    Map<String, dynamic> data,
  ) async {
    if (_schemas.containsKey(tableName)) return;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'",
    );

    if (tables.isEmpty) {
      await _createTableFromData(db, tableName, data);
    }
  }

  Future<void> _createTableFromData(
    Database db,
    String tableName,
    Map<String, dynamic> data,
  ) async {
    LoggerHelper.info(
      "==========>> Creating table $tableName from data structure <<==========",
    );

    List<String> columns = ['id INTEGER PRIMARY KEY AUTOINCREMENT'];

    data.forEach((key, value) {
      if (key != 'id') {
        if (value is int) {
          columns.add('$key INTEGER');
        } else if (value is String) {
          columns.add('$key TEXT');
        } else if (value is double) {
          columns.add('$key REAL');
        } else if (value is bool) {
          columns.add('$key INTEGER'); // SQLite doesn't have boolean
        } else {
          columns.add('$key TEXT'); // Default to TEXT
        }
      }
    });

    final query = 'CREATE TABLE $tableName (${columns.join(', ')})';
    LoggerHelper.info(
      "==========>> Creating table with SQL: $query <<==========",
    );

    await db.execute(query);
    LoggerHelper.info(
      "==========>> Table $tableName created successfully <<==========",
    );
  }

  Future<bool> tableExists(String tableName) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'",
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteAllTables() async {
    try {
      final db = await database;

      await db.transaction((txn) async {
        final tables = await txn.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
        );

        for (var table in tables) {
          final tableName = table['name'];
          await txn.execute('DROP TABLE IF EXISTS $tableName');
        }
      });
    } catch (e) {
      throw DatabaseException('Failed to delete all tables: $e');
    }
  }

  Future<void> close() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
    } catch (e) {
      throw DatabaseException('Failed to close database: $e');
    }
  }
}

// Custom exception for better error handling
class DatabaseException implements Exception {
  final String message;

  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}
