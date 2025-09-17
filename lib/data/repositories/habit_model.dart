import 'package:sqflite/sqflite.dart';

class Habit {
  final int? id;
  final String title;
  final String description;
  bool isFavorite;
  DateTime? createdTime;

  Habit({
    this.id,
    required this.title,
    required this.description,
    this.isFavorite = false,
    this.createdTime,
  });

  Habit copy({
    int? id,
    String? title,
    String? description,
    bool? isFavorite,
    DateTime? createdTime,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      createdTime: createdTime ?? this.createdTime,
    );
  }

  Map<String, Object?> toJson() => {
    HabitFields.id: id,
    HabitFields.title: title,
    HabitFields.description: description,
    HabitFields.isFavorite: isFavorite ? 1 : 0,
    HabitFields.createdTime: createdTime?.toIso8601String(),
  };

  factory Habit.fromJson(Map<String, Object?> json) => Habit(
    id: json[HabitFields.id] as int?,
    title: json[HabitFields.title] as String,
    description: json[HabitFields.description] as String,
    isFavorite: (json[HabitFields.isFavorite] as int) == 1,
    createdTime: DateTime.tryParse(
      json[HabitFields.createdTime] as String? ?? '',
    ),
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

  static const List<String> values = [
    id,
    title,
    description,
    isFavorite,
    createdTime,
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
    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  Future<void> _createDatabase(Database db, int version) async {
    return await db.execute('''
        CREATE TABLE ${HabitFields.tableName} (
          ${HabitFields.id} ${HabitFields.idType},
          ${HabitFields.title} ${HabitFields.textType},
          ${HabitFields.description} ${HabitFields.textType},
          ${HabitFields.isFavorite} ${HabitFields.intType},
          ${HabitFields.createdTime} ${HabitFields.textType}
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
