import 'package:sqflite/sqflite.dart';

enum HabitRecurrence { daily, weekly, monthly }

extension HabitRecurrenceLabel on HabitRecurrence {
  String get displayName {
    switch (this) {
      case HabitRecurrence.daily:
        return 'Daily';
      case HabitRecurrence.weekly:
        return 'Weekly';
      case HabitRecurrence.monthly:
        return 'Monthly';
    }
  }
}

DateTime habitDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// [weekStartsOnMonday] `true`: ISO week (Mon–Sun). `false`: week starts Sunday (Sun–Sat).
DateTime weekStartForDate(DateTime date, {required bool weekStartsOnMonday}) {
  final d = habitDateOnly(date);
  if (weekStartsOnMonday) {
    return d.subtract(Duration(days: d.weekday - 1));
  }
  final daysFromSunday = d.weekday % 7;
  return d.subtract(Duration(days: daysFromSunday));
}

/// Whether [habit] is in effect on this calendar [date] (start date rule).
bool habitAppliesOnDate(Habit habit, DateTime date) {
  final d = habitDateOnly(date);
  if (habit.startDate == null) return true;
  final s = habitDateOnly(habit.startDate!);
  return !d.isBefore(s);
}

class Habit {
  int? id;
  String title;
  String description;
  bool isFavorite;
  DateTime? createdTime;
  /// User-defined label, e.g. "Health", "Work".
  String category;
  HabitRecurrence recurrence;
  /// First day this habit applies (optional). Compared as calendar dates only.
  DateTime? startDate;

  Habit({
    this.id,
    required this.title,
    required this.description,
    this.isFavorite = false,
    this.createdTime,
    this.category = '',
    this.recurrence = HabitRecurrence.daily,
    this.startDate,
  });

  Habit copy({
    int? id,
    String? title,
    String? description,
    bool? isFavorite,
    DateTime? createdTime,
    String? category,
    HabitRecurrence? recurrence,
    DateTime? startDate,
    bool clearStartDate = false,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      createdTime: createdTime ?? this.createdTime,
      category: category ?? this.category,
      recurrence: recurrence ?? this.recurrence,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
    );
  }

  Map<String, Object?> toJson() => {
    HabitFields.id: id,
    HabitFields.title: title,
    HabitFields.description: description,
    HabitFields.isFavorite: isFavorite ? 1 : 0,
    HabitFields.createdTime: createdTime?.toIso8601String(),
    HabitFields.category: category,
    HabitFields.recurrence: recurrence.name,
    HabitFields.startDate: startDate != null ? _dateKeyForJson(startDate!) : null,
  };

  factory Habit.fromJson(Map<String, Object?> json) => Habit(
    id: json[HabitFields.id] as int?,
    title: json[HabitFields.title] as String,
    description: json[HabitFields.description] as String,
    isFavorite: (json[HabitFields.isFavorite] as int? ?? 0) == 1,
    createdTime: DateTime.tryParse(
      json[HabitFields.createdTime] as String? ?? '',
    ),
    category: (json[HabitFields.category] as String?) ?? '',
    recurrence: _parseRecurrence(json[HabitFields.recurrence] as String?),
    startDate: _parseStartDate(json[HabitFields.startDate] as String?),
  );
}

String _dateKeyForJson(DateTime d) {
  final x = habitDateOnly(d);
  return '${x.year.toString().padLeft(4, '0')}-'
      '${x.month.toString().padLeft(2, '0')}-'
      '${x.day.toString().padLeft(2, '0')}';
}

DateTime? _parseStartDate(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

HabitRecurrence _parseRecurrence(String? raw) {
  if (raw == null) return HabitRecurrence.daily;
  return HabitRecurrence.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => HabitRecurrence.daily,
  );
}

class HabitFields {
  static const String tableName = 'habits';
  static const String idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
  static const String textType = 'TEXT NOT NULL';
  static const String intType = 'INTEGER NOT NULL';
  static const String id = 'id';
  static const String title = 'title';
  static const String description = 'description';
  static const String isFavorite = 'is_favorite';
  static const String createdTime = 'created_time';
  static const String category = 'category';
  static const String recurrence = 'recurrence';
  static const String startDate = 'start_date';

  static const List<String> values = [
    id,
    title,
    description,
    isFavorite,
    createdTime,
    category,
    recurrence,
    startDate,
  ];
}

class HabitDatabase {
  static final HabitDatabase instance = HabitDatabase._internal();

  static Database? _database;

  HabitDatabase._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = '$databasePath/habits.db';
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE ${HabitFields.tableName}
        ADD COLUMN ${HabitFields.category} TEXT NOT NULL DEFAULT ''
      ''');
      await db.execute('''
        ALTER TABLE ${HabitFields.tableName}
        ADD COLUMN ${HabitFields.recurrence} TEXT NOT NULL DEFAULT 'daily'
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE ${HabitFields.tableName}
        ADD COLUMN ${HabitFields.startDate} TEXT
      ''');
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    return await db.execute('''
        CREATE TABLE ${HabitFields.tableName} (
          ${HabitFields.id} ${HabitFields.idType},
          ${HabitFields.title} ${HabitFields.textType},
          ${HabitFields.description} ${HabitFields.textType},
          ${HabitFields.isFavorite} ${HabitFields.intType},
          ${HabitFields.createdTime} ${HabitFields.textType},
          ${HabitFields.category} TEXT NOT NULL DEFAULT '',
          ${HabitFields.recurrence} TEXT NOT NULL DEFAULT 'daily',
          ${HabitFields.startDate} TEXT
        )
      ''');
  }

  Future<Habit> create(Habit habit) async {
    final db = await instance.database;
    final id = await db.insert(HabitFields.tableName, habit.toJson());
    return habit.copy(id: id);
  }

  Future<Habit> read(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      HabitFields.tableName,
      columns: HabitFields.values,
      where: '${HabitFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Habit.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Habit>> readAll() async {
    final db = await instance.database;
    const orderBy = '${HabitFields.createdTime} DESC';
    final result = await db.query(HabitFields.tableName, orderBy: orderBy);
    return result.map((json) => Habit.fromJson(json)).toList();
  }

  Future<int> update(Habit habit) async {
    final db = await instance.database;
    return db.update(
      HabitFields.tableName,
      habit.toJson(),
      where: '${HabitFields.id} = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      HabitFields.tableName,
      where: '${HabitFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
