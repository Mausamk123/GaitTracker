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

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Add filePath column in version 2
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE patients ADD COLUMN filePath TEXT;");
      } catch (e) {
        // ignore if column already exists or other issues
        print('DB upgrade note: $e');
      }
    }

    // Update date_of_injury column format in version 3
    if (oldVersion < 3) {
      try {
        // Backup the old table
        await db.execute('ALTER TABLE patients RENAME TO patients_backup;');

        // Create new table with correct schema
        await db.execute('''
          CREATE TABLE patients (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fileName TEXT,
            filePath TEXT UNIQUE,
            name TEXT,
            age INTEGER,
            gender TEXT,
            disease TEXT,
            phone TEXT,
            email TEXT,
            address TEXT,
            diagnosis TEXT,
            date_of_injury DATE,
            medical_history TEXT,
            medications TEXT
          );
        ''');

        // Copy data with date conversion
        await db.execute('''
          INSERT INTO patients 
          SELECT 
            id,
            fileName,
            filePath,
            name,
            age,
            gender,
            disease,
            phone,
            email,
            address,
            diagnosis,
            CASE 
              WHEN date_of_injury IS NULL THEN NULL
              WHEN date_of_injury LIKE '%/%' THEN 
                substr(date_of_injury, -4) || '-' || -- year
                substr('0' || substr(date_of_injury, instr(date_of_injury, '/', 1) + 1, 
                  instr(date_of_injury, '/', instr(date_of_injury, '/') + 1) - instr(date_of_injury, '/') - 1), -2) || '-' || -- month
                substr('0' || substr(date_of_injury, 1, instr(date_of_injury, '/') - 1), -2) -- day
              ELSE date_of_injury
            END,
            medical_history,
            medications
          FROM patients_backup;
        ''');

        // If everything succeeded, drop the backup
        await db.execute('DROP TABLE patients_backup;');
      } catch (e) {
        print('Error upgrading database to version 3: $e');
        // If anything goes wrong, ensure we don't lose data
        try {
          await db.execute('DROP TABLE IF EXISTS patients_temp;');
        } catch (e) {
          print('Error cleaning up after failed upgrade: $e');
        }
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Enable foreign key enforcement
    await db.execute('PRAGMA foreign_keys = ON;');

    // Patients table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS patients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fileName TEXT,
        filePath TEXT UNIQUE,
        name TEXT,
        age INTEGER,
        gender TEXT,
        disease TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        diagnosis TEXT,
        date_of_injury DATE,
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

  Future<int> deletePatientById(int id) async {
    final db = await database;
    return await db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletePatientByFilePath(String filePath) async {
    final db = await database;
    return await db.delete(
      'patients',
      where: 'filePath = ?',
      whereArgs: [filePath],
    );
  }

  Future<int> deletePatientByFileName(String fileName) async {
    final db = await database;
    return await db.delete(
      'patients',
      where: 'fileName = ?',
      whereArgs: [fileName],
    );
  }

  // Helper method to validate and format date
  String? _formatDateForDB(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    // Try to parse the date from various formats
    DateTime? date;
    try {
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          // Make sure all parts are numbers and year is 4 digits
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);

          // Validate ranges
          if (year < 1900 || year > 2100) throw FormatException('Invalid year');
          if (month < 1 || month > 12) throw FormatException('Invalid month');
          if (day < 1 || day > 31) throw FormatException('Invalid day');

          // Create date - DateTime constructor will validate valid day for month
          date = DateTime(year, month, day);

          // If we got here, it's a valid date
        }
      } else if (dateStr.contains('-')) {
        // Parse yyyy-MM-dd format
        date = DateTime.parse(dateStr);
      } else {
        throw FormatException('Invalid date format');
      }

      if (date == null) {
        throw FormatException('Could not parse date');
      }

      // Additional validation for reasonable date ranges
      final now = DateTime.now();
      if (date.isAfter(now)) {
        throw FormatException('Date cannot be in the future');
      }
      if (date.isBefore(DateTime(1900))) {
        throw FormatException('Date cannot be before year 1900');
      }
    } catch (e) {
      throw FormatException(
        'Invalid date format. Please use dd/mm/yyyy or yyyy-MM-dd format.\n'
        'Example: 31/12/2025 or 2025-12-31',
      );
    }

    // Return date in SQLite compatible format (yyyy-MM-dd)
    return date.toIso8601String().split('T')[0];
  }

  Future<void> upsertPatientWithFile(Map<String, dynamic> patient) async {
    final db = await database;

    // Always require filePath for new entries
    if (!patient.containsKey('filePath') || patient['filePath'] == null) {
      throw ArgumentError('filePath is required for patient records');
    }

    // Format date of injury if present
    if (patient.containsKey('date_of_injury')) {
      try {
        patient['date_of_injury'] = _formatDateForDB(
          patient['date_of_injury'] as String?,
        );
      } catch (e) {
        throw ArgumentError('Invalid date_of_injury: ${e.toString()}');
      }
    }

    // Try to find existing record by filePath
    final existing = await db.query(
      'patients',
      where: 'filePath = ?',
      whereArgs: [patient['filePath']],
    );

    if (existing.isNotEmpty) {
      // Update existing record
      await db.update(
        'patients',
        patient,
        where: 'filePath = ?',
        whereArgs: [patient['filePath']],
      );
    } else {
      // Insert new record
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
