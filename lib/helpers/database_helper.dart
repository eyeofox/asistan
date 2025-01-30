import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('teacher_assistant.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Öğrenciler tablosu
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT
      )
    ''');

    // Dersler tablosu
    await db.execute('''
      CREATE TABLE lessons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        subject TEXT NOT NULL,
        price REAL NOT NULL,
        duration INTEGER NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        payment_status INTEGER DEFAULT 0,
        is_recurring INTEGER DEFAULT 0,
        recurring_day INTEGER,
        recurring_until TEXT,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE
      )
    ''');

    // Ödemeler tablosu
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        lesson_id INTEGER,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE,
        FOREIGN KEY (lesson_id) REFERENCES lessons (id) ON DELETE SET NULL
      )
    ''');
  }

  // Öğrenci işlemleri
  Future<int> addStudent(Map<String, dynamic> student) async {
    final db = await database;
    return await db.insert('students', student);
  }

  Future<List<Map<String, dynamic>>> getAllStudents() async {
    final db = await database;
    return await db.query('students', orderBy: 'name');
  }

  Future<Map<String, dynamic>?> getStudent(int id) async {
    final db = await database;
    final results = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateStudent(Map<String, dynamic> student) async {
    final db = await database;
    return await db.update(
      'students',
      student,
      where: 'id = ?',
      whereArgs: [student['id']],
    );
  }

  Future<int> deleteStudent(int id) async {
    final db = await database;
    return await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Ders işlemleri
  Future<int> addLesson(Map<String, dynamic> lesson) async {
    final db = await database;
    return await db.insert('lessons', lesson);
  }

  Future<List<Map<String, dynamic>>> getAllLessons() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT l.*, s.name as student_name
      FROM lessons l
      JOIN students s ON l.student_id = s.id
      ORDER BY l.date DESC, l.time DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getLessonsForStudent(int studentId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT l.*, s.name as student_name
      FROM lessons l
      JOIN students s ON l.student_id = s.id
      WHERE l.student_id = ?
      ORDER BY l.date DESC, l.time DESC
    ''', [studentId]);
  }

  Future<List<Map<String, dynamic>>> getWeeklyLessons() async {
    final db = await database;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(Duration(days: 6));

    return await db.rawQuery('''
      SELECT l.*, s.name as student_name
      FROM lessons l
      JOIN students s ON l.student_id = s.id
      WHERE l.date BETWEEN ? AND ?
      ORDER BY l.date, l.time
    ''',
        [weekStart.toString().split(' ')[0], weekEnd.toString().split(' ')[0]]);
  }

  Future<List<Map<String, dynamic>>> getTodaysLessons() async {
    final db = await database;
    final today = DateTime.now().toString().split(' ')[0];

    return await db.rawQuery('''
      SELECT l.*, s.name as student_name
      FROM lessons l
      JOIN students s ON l.student_id = s.id
      WHERE l.date = ?
      ORDER BY l.time
    ''', [today]);
  }

  Future<int> updateLesson(Map<String, dynamic> lesson) async {
    final db = await database;

    // student_name gibi join ile gelen alanları temizleyelim
    final cleanLesson = {
      'id': lesson['id'],
      'student_id': lesson['student_id'],
      'subject': lesson['subject'],
      'price': lesson['price'],
      'duration': lesson['duration'],
      'date': lesson['date'],
      'time': lesson['time'],
      'is_completed': lesson['is_completed'],
      'payment_status': lesson['payment_status'],
      'is_recurring': lesson['is_recurring'],
      'recurring_day': lesson['recurring_day'],
      'recurring_until': lesson['recurring_until'],
    };

    return await db.update(
      'lessons',
      cleanLesson,
      where: 'id = ?',
      whereArgs: [lesson['id']],
    );
  }

  Future<int> deleteLesson(int id) async {
    final db = await database;
    return await db.delete(
      'lessons',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Ödeme işlemleri
  Future<int> addPayment(Map<String, dynamic> payment) async {
    final db = await database;
    return await db.insert('payments', payment);
  }

  Future<List<Map<String, dynamic>>> getAllPayments() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.*, s.name as student_name, l.subject as lesson_subject
      FROM payments p
      JOIN students s ON p.student_id = s.id
      LEFT JOIN lessons l ON p.lesson_id = l.id
      ORDER BY p.date DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getPaymentsForStudent(
      int studentId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.*, s.name as student_name, l.subject as lesson_subject
      FROM payments p
      JOIN students s ON p.student_id = s.id
      LEFT JOIN lessons l ON p.lesson_id = l.id
      WHERE p.student_id = ?
      ORDER BY p.date DESC
    ''', [studentId]);
  }

  // İstatistik işlemleri
  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;
    final now = DateTime.now().toString().split(' ')[0];

    // Toplam öğrenci sayısı
    final totalStudents = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM students')) ??
        0;

    // Bugünkü ders sayısı
    final todaysLessons = Sqflite.firstIntValue(await db
            .rawQuery('SELECT COUNT(*) FROM lessons WHERE date = ?', [now])) ??
        0;

    // Toplam kazanç
    final totalEarnings = Sqflite.firstIntValue(await db
            .rawQuery('SELECT COALESCE(SUM(amount), 0) FROM payments')) ??
        0;

    // Beklenen kazanç
    final expectedEarnings = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COALESCE(SUM(price), 0) FROM lessons WHERE payment_status = 0')) ??
        0;

    return {
      'total_students': totalStudents,
      'todays_lessons': todaysLessons,
      'total_earnings': totalEarnings,
      'expected_earnings': expectedEarnings,
    };
  }

  // Veritabanını kapat
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
