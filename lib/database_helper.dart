import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const String columnFishCount = 'fish_count';
  static const String columnFishSpeed = 'fish_speed';
  static const String columnDefaultColor = 'default_color';

  static Database? _database;

  static const String tableSettings = 'settings';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  initDB() async {
    String path = join(await getDatabasesPath(), 'aquarium.db');
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  _createDB(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableSettings (
            $columnFishCount INTEGER,
            $columnFishSpeed REAL,
            $columnDefaultColor INTEGER
          )
          ''');
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert(tableSettings, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await database;
    return await db.query(tableSettings);
  }

  static DatabaseHelper instance = DatabaseHelper();
}