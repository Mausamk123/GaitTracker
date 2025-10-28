import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('patients.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Check if running on web or unsupported platform
    if (kIsWeb) {
      throw UnsupportedError(
        'SQLite is not supported on web platform. '
        'This app currently only works on mobile platforms (iOS/Android).',
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // Enable foreign key enforcement
    await db.execute('PRAGMA foreign_keys = ON;');

    // Patients table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS patients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fileName TEXT UNIQUE,
        name TEXT,
        age INTEGER,
        gender TEXT,
        disease TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        diagnosis TEXT,
        date_of_injury TEXT,
        medical_history TEXT,
        medications TEXT
      );
    ''');

    // Sessions table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        session_name TEXT,
        FOREIGN KEY(patient_id) REFERENCES patients(id) ON DELETE CASCADE
      );
    ''');

    // Gait data table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS gait_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER,
        serial INTEGER,
        x_acc REAL,
        y_acc REAL,
        z_acc REAL,
        x_gyro REAL,
        y_gyro REAL,
        z_gyro REAL,
        FOREIGN KEY(session_id) REFERENCES sessions(id) ON DELETE CASCADE
      );
    ''');
  }

  // Patient operations
  Future<int> insertPatient(Map<String, dynamic> patient) async {
    final db = await database;
    return await db.insert('patients', patient);
  }

  Future<List<Map<String, dynamic>>> getAllPatients() async {
    final db = await database;
    return await db.query('patients');
  }

  Future<Map<String, dynamic>?> getPatientById(int id) async {
    final db = await database;
    final results = await db.query(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<int> updatePatient(int id, Map<String, dynamic> patient) async {
    final db = await database;
    return await db.update(
      'patients',
      patient,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> upsertPatientWithFile(Map<String, dynamic> patient) async {
    final db = await database;

    final existing = await db.query(
      'patients',
      where: 'fileName = ?',
      whereArgs: [patient['fileName']],
    );

    if (existing.isNotEmpty) {
      await db.update(
        'patients',
        patient,
        where: 'fileName = ?',
        whereArgs: [patient['fileName']],
      );
    } else {
      await db.insert('patients', patient);
    }
  }

  // Session operations
  Future<int> insertSession(int patientId, String sessionName) async {
    final db = await database;
    final data = {'patient_id': patientId, 'session_name': sessionName};
    return await db.insert('sessions', data);
  }

  Future<List<Map<String, dynamic>>> getSessionsByPatientId(
    int patientId,
  ) async {
    final db = await database;
    return await db.query(
      'sessions',
      where: 'patient_id = ?',
      whereArgs: [patientId],
    );
  }

  // Gait data operations
  Future<void> insertGaitData(List<Map<String, dynamic>> gaitData) async {
    final db = await database;
    final batch = db.batch();

    for (final row in gaitData) {
      batch.insert('gait_data', row);
    }

    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getGaitDataBySessionId(
    int sessionId,
  ) async {
    final db = await database;
    return await db.query(
      'gait_data',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
