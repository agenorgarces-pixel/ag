import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Guarda registros de clientes que no se pudieron enviar al servidor local
/// (por ejemplo, un corte de señal WiFi dentro del salón) para reintentar
/// el envío más tarde. Esto es lo que evita perder una venta si la app
/// pierde la conexión a mitad de un registro.
class DbHelper {
  DbHelper._interno();
  static final DbHelper instancia = DbHelper._interno();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _iniciar();
    return _db!;
  }

  Future<Database> _iniciar() async {
    final ruta = join(await getDatabasesPath(), 'peluqueria_pendientes.db');
    return openDatabase(
      ruta,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE pendientes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cliente TEXT NOT NULL,
            items_json TEXT NOT NULL,
            creado_en TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Guarda un registro que no pudo enviarse al servidor.
  Future<void> guardarPendiente(String cliente, List<Map<String, dynamic>> items) async {
    final database = await db;
    await database.insert('pendientes', {
      'cliente': cliente,
      'items_json': jsonEncode(items),
      'creado_en': DateTime.now().toIso8601String(),
    });
  }

  /// Devuelve todos los registros que siguen pendientes de sincronizar.
  Future<List<Map<String, dynamic>>> obtenerPendientes() async {
    final database = await db;
    return database.query('pendientes', orderBy: 'creado_en ASC');
  }

  /// Elimina un pendiente ya sincronizado con éxito.
  Future<void> eliminarPendiente(int id) async {
    final database = await db;
    await database.delete('pendientes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> contarPendientes() async {
    final database = await db;
    final resultado = await database.rawQuery('SELECT COUNT(*) as total FROM pendientes');
    return Sqflite.firstIntValue(resultado) ?? 0;
  }
}
