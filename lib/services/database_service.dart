import "dart:async";
import "dart:io" as io;
import "package:path/path.dart";
import "package:sqflite/sqflite.dart";
import "package:path_provider/path_provider.dart";
import "package:StreamingRadio/models/models.dart";

class DatabaseService {
  static final DatabaseService _instance = new DatabaseService.internal();
  factory DatabaseService() => _instance;
  DatabaseService.internal();

  static Database _db;
  String _dbFile = "main.db";

  Future<Database> get db async {
    if (_db != null) return _db;
    _db = await initDb();
    return _db;
  }

  initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbFile);
    var theDb = await openDatabase(path, version: 1, onCreate: _onCreate);
    return theDb;
  }

  Future<String> deleteDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbFile);
    await deleteDatabase(path);
    // _db.close();
    _db = null;

    return path;
  }

  void _onCreate(Database db, int version) async {
    await db.execute("CREATE TABLE StarredStations(radioUrl TEXT);");
  }

  // ----------
  // starred stations
  // ----------
  Future<bool> saveStarredStation(Station station) async {
    var dbClient = await db;
    int count = await dbClient.insert("StarredStations", station.toMap());
    return count > 0;
  }

  Future<bool> removeStarredStation(Station station) async {
    var dbClient = await db;
    int count = await dbClient.rawDelete("delete from StarredStations where radioUrl = ?", [station.radioUrl]);
    return count == 1;
  }

  Future<List<String>> getStarredStations() async {
    var dbClient = await db;
    var res = await dbClient.query("StarredStations");
    List<String> list = new List<String>();
    res.forEach((data) {
      list.add(data["radioUrl"]);
    });
    return list;
  }
}