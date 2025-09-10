/*
* Created by : Syed Bipul Rahman
* Author     : Syed Bipul Rahman
* github     : @Syed-bipul-rahman
* All right reserved
* */
import 'dart:io';

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

  // ========== PHOTO-SPECIFIC OPTIMIZED METHODS ==========

  /// Get photos with pagination - optimized for large datasets
  Future<List<Map<String, dynamic>>> getPhotosPaginated({
    int limit = 50,
    int offset = 0,
    String? orderBy = 'taken_date DESC',
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    try {
      LoggerHelper.info(
        "==========>> Loading photos: limit=$limit, offset=$offset <<==========",
      );

      final stopwatch = Stopwatch()..start();

      final results = await query(
        'photos',
        orderBy: orderBy,
        limit: limit,
        offset: offset,
        where: where,
        whereArgs: whereArgs,
      );

      stopwatch.stop();
      LoggerHelper.info(
        "==========>> Loaded ${results.length} photos in ${stopwatch.elapsedMilliseconds}ms <<==========",
      );

      return results;
    } catch (e) {
      LoggerHelper.error('Error loading paginated photos: $e');
      throw DatabaseException('Failed to load paginated photos: $e');
    }
  }

  /// Get total photo count for progress tracking
  Future<int> getPhotoCount({String? where, List<dynamic>? whereArgs}) async {
    try {
      return await count('photos', where: where, whereArgs: whereArgs);
    } catch (e) {
      LoggerHelper.error('Error getting photo count: $e');
      return 0;
    }
  }

  /// Get photos grouped by date for better organization
  Future<Map<String, List<Map<String, dynamic>>>> getPhotosGroupedByDate({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final photos = await getPhotosPaginated(limit: limit, offset: offset);

      final Map<String, List<Map<String, dynamic>>> groupedPhotos = {};

      for (final photo in photos) {
        final takenDate = photo['taken_date'];
        if (takenDate != null) {
          final dateKey = _formatDateKey(DateTime.parse(takenDate.toString()));
          if (!groupedPhotos.containsKey(dateKey)) {
            groupedPhotos[dateKey] = [];
          }
          groupedPhotos[dateKey]!.add(photo);
        }
      }

      return groupedPhotos;
    } catch (e) {
      LoggerHelper.error('Error getting grouped photos: $e');
      return {};
    }
  }

  /// Search photos by metadata (path, name, etc.)
  Future<List<Map<String, dynamic>>> searchPhotos({
    required String searchTerm,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final searchPattern = '%${searchTerm.toLowerCase()}%';

      return await query(
        'photos',
        where: 'LOWER(path) LIKE ? OR LOWER(location) LIKE ?',
        whereArgs: [searchPattern, searchPattern],
        orderBy: 'taken_date DESC',
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      LoggerHelper.error('Error searching photos: $e');
      return [];
    }
  }

  /// Get photos within a date range
  Future<List<Map<String, dynamic>>> getPhotosInDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      return await query(
        'photos',
        where: 'taken_date BETWEEN ? AND ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'taken_date DESC',
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      LoggerHelper.error('Error getting photos in date range: $e');
      return [];
    }
  }

  /// Check if photo exists by path (to avoid duplicates)
  Future<bool> photoExists(String path) async {
    try {
      final result = await findFirst(
        'photos',
        where: 'path = ?',
        whereArgs: [path],
      );
      return result != null;
    } catch (e) {
      LoggerHelper.error('Error checking photo existence: $e');
      return false;
    }
  }

  /// Batch insert photos with conflict resolution
  Future<List<int>> bulkInsertPhotos(
    List<Map<String, dynamic>> photos, {
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.ignore,
  }) async {
    try {
      final db = await database;
      final results = <int>[];

      final stopwatch = Stopwatch()..start();

      await db.transaction((txn) async {
        for (final photo in photos) {
          try {
            final result = await txn.insert(
              'photos',
              photo,
              conflictAlgorithm: conflictAlgorithm,
            );
            results.add(result);
          } catch (e) {
            LoggerHelper.error('Error inserting photo: $e');
            results.add(-1); // Indicate failure
          }
        }
      });

      stopwatch.stop();
      final successCount = results.where((id) => id != -1).length;

      LoggerHelper.info(
        "==========>> Bulk inserted $successCount/${photos.length} photos in ${stopwatch.elapsedMilliseconds}ms <<==========",
      );

      return results;
    } catch (e) {
      throw DatabaseException('Failed to bulk insert photos: $e');
    }
  }

  /// Get database statistics for monitoring
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final db = await database;
      final stats = <String, dynamic>{};

      // Get photo count
      stats['totalPhotos'] = await getPhotoCount();

      // Get database size
      final dbPath = db.path;
      if (dbPath != null) {
        try {
          final file = File(dbPath);
          stats['databaseSizeBytes'] = await file.length();
          stats['databaseSizeMB'] = (stats['databaseSizeBytes'] / (1024 * 1024))
              .toStringAsFixed(2);
        } catch (e) {
          stats['databaseSizeBytes'] = 0;
          stats['databaseSizeMB'] = '0.00';
        }
      }

      // Get earliest and latest photo dates
      try {
        final earliest = await findFirst('photos', orderBy: 'taken_date ASC');
        final latest = await findFirst('photos', orderBy: 'taken_date DESC');

        stats['earliestPhoto'] = earliest?['taken_date'];
        stats['latestPhoto'] = latest?['taken_date'];
      } catch (e) {
        stats['earliestPhoto'] = null;
        stats['latestPhoto'] = null;
      }

      return stats;
    } catch (e) {
      LoggerHelper.error('Error getting database stats: $e');
      return {};
    }
  }

  /// Cleanup orphaned photo records (photos that don't exist on disk)
  Future<int> cleanupOrphanedPhotos() async {
    try {
      final db = await database;
      int deletedCount = 0;

      // Get all photos
      final allPhotos = await query('photos', columns: ['id', 'path']);

      await db.transaction((txn) async {
        for (final photo in allPhotos) {
          final path = photo['path'] as String;
          final file = File(path);

          if (!await file.exists()) {
            await txn.delete(
              'photos',
              where: 'id = ?',
              whereArgs: [photo['id']],
            );
            deletedCount++;
          }
        }
      });

      LoggerHelper.info(
        "==========>> Cleaned up $deletedCount orphaned photo records <<==========",
      );

      return deletedCount;
    } catch (e) {
      LoggerHelper.error('Error cleaning up orphaned photos: $e');
      throw DatabaseException('Failed to cleanup orphaned photos: $e');
    }
  }

  /// Optimize database by running VACUUM and ANALYZE
  Future<void> optimizeDatabase() async {
    try {
      final db = await database;
      final stopwatch = Stopwatch()..start();

      LoggerHelper.info(
        "==========>> Starting database optimization <<==========",
      );

      // Run VACUUM to reclaim space and defragment
      await db.execute('VACUUM');

      // Run ANALYZE to update query planner statistics
      await db.execute('ANALYZE');

      stopwatch.stop();
      LoggerHelper.info(
        "==========>> Database optimization completed in ${stopwatch.elapsedMilliseconds}ms <<==========",
      );
    } catch (e) {
      LoggerHelper.error('Error optimizing database: $e');
      throw DatabaseException('Failed to optimize database: $e');
    }
  }

  /// Create indexes for better query performance
  Future<void> createPhotoIndexes() async {
    try {
      final db = await database;

      // Index on taken_date for chronological ordering
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_photos_taken_date ON photos(taken_date DESC)',
      );

      // Index on path for duplicate checking
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_photos_path ON photos(path)',
      );

      // Index on location for searching
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_photos_location ON photos(location)',
      );

      // Composite index for date range queries
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_photos_date_range ON photos(taken_date, id)',
      );

      LoggerHelper.info(
        "==========>> Photo indexes created successfully <<==========",
      );
    } catch (e) {
      LoggerHelper.error('Error creating photo indexes: $e');
      throw DatabaseException('Failed to create photo indexes: $e');
    }
  }

  // Helper method to format date keys for grouping
  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final photoDate = DateTime(date.year, date.month, date.day);

    if (photoDate == today) {
      return 'Today';
    } else if (photoDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return '${_getDayName(date.weekday)} ${date.day}/${date.month}';
    } else if (date.year == now.year) {
      return '${_getMonthName(date.month)} ${date.day}';
    } else {
      return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

// Custom exception for better error handling
class DatabaseException implements Exception {
  final String message;

  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}
