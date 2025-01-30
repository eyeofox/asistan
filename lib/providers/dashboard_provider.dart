import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../helpers/database_helper.dart';

class DashboardProvider with ChangeNotifier {
  bool isLoading = true;
  int totalStudents = 0;
  int todaysLessons = 0;
  double totalEarnings = 0.0;
  double expectedEarnings = 0.0;
  int completedLessons = 0;
  int totalLessons = 0;
  List<Map<String, dynamic>> todaysLessonsList = [];
  List<Map<String, dynamic>> weeklyLessons = [];

  DashboardProvider() {
    updateDashboard();
  }

  Future<void> updateDashboard() async {
    isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;

      await db.transaction((txn) async {
        // Öğrenci sayısı
        final studentsCount = Sqflite.firstIntValue(
                await txn.rawQuery('SELECT COUNT(*) FROM students')) ??
            0;
        totalStudents = studentsCount;

        // Bugünkü dersler
        final today = DateTime.now();
        final todayStr =
            "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

        todaysLessonsList = await txn.rawQuery('''
          SELECT l.*, s.name as student_name
          FROM lessons l
          JOIN students s ON l.student_id = s.id
          WHERE l.date = ?
          ORDER BY l.time
        ''', [todayStr]);

        todaysLessons = todaysLessonsList.length;

        // Haftalık program
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekEnd = weekStart.add(Duration(days: 6));

        weeklyLessons = await txn.rawQuery('''
          SELECT l.*, s.name as student_name
          FROM lessons l
          JOIN students s ON l.student_id = s.id
          WHERE l.date BETWEEN ? AND ?
          ORDER BY l.date, l.time
        ''', [
          weekStart.toString().split(' ')[0],
          weekEnd.toString().split(' ')[0]
        ]);

        // Kazanç ve ders istatistikleri
        final stats = await txn.rawQuery('''
          SELECT 
            (SELECT COALESCE(SUM(amount), 0) FROM payments) as total_earnings,
            (
              SELECT COALESCE(SUM(price), 0) 
              FROM lessons 
              WHERE payment_status != 1 
              AND date <= date('now')
            ) as expected_earnings,
            (SELECT COUNT(*) FROM lessons) as total_lessons,
            (SELECT COUNT(*) FROM lessons WHERE is_completed = 1) as completed_lessons
        ''');

        if (stats.isNotEmpty) {
          totalEarnings =
              (stats.first['total_earnings'] as num?)?.toDouble() ?? 0.0;
          expectedEarnings =
              (stats.first['expected_earnings'] as num?)?.toDouble() ?? 0.0;
          totalLessons = stats.first['total_lessons'] as int? ?? 0;
          completedLessons = stats.first['completed_lessons'] as int? ?? 0;
        }
      });
    } catch (e) {
      print('Dashboard güncelleme hatası: $e');
      totalStudents = 0;
      todaysLessons = 0;
      totalEarnings = 0.0;
      expectedEarnings = 0.0;
      completedLessons = 0;
      totalLessons = 0;
      todaysLessonsList = [];
      weeklyLessons = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> getLessonsForDay(int dayIndex) {
    return weeklyLessons.where((lesson) {
      final lessonDate = DateTime.parse(lesson['date']);
      return lessonDate.weekday == dayIndex;
    }).toList();
  }

  String formatPrice(double price) {
    return '₺${price.toStringAsFixed(2)}';
  }

  String formatDate(String date) {
    final parts = date.split('-');
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  bool isLessonCompleted(Map<String, dynamic> lesson) {
    return lesson['is_completed'] == 1;
  }

  bool isPaymentReceived(Map<String, dynamic> lesson) {
    return lesson['payment_status'] == 1;
  }

  String getLessonStatus(Map<String, dynamic> lesson) {
    final lessonDate = DateTime.parse(lesson['date']);
    final isPassedLesson = lessonDate.isBefore(DateTime.now());

    if (isPaymentReceived(lesson)) {
      return 'Ödeme Alındı';
    }

    if (isLessonCompleted(lesson)) {
      return 'Ders Tamamlandı, Ödeme Bekleniyor';
    }

    if (!isPassedLesson) {
      return 'Planlandı';
    }

    return 'Ödeme Bekleniyor';
  }

  Color getLessonStatusColor(Map<String, dynamic> lesson) {
    final lessonDate = DateTime.parse(lesson['date']);
    final isPassedLesson = lessonDate.isBefore(DateTime.now());

    if (isPaymentReceived(lesson)) {
      return Colors.green;
    }

    if (isLessonCompleted(lesson)) {
      return Colors.orange;
    }

    if (!isPassedLesson) {
      return Colors.blue;
    }

    return Colors.red;
  }

  IconData getLessonStatusIcon(Map<String, dynamic> lesson) {
    if (isPaymentReceived(lesson)) return Icons.check_circle;
    if (isLessonCompleted(lesson)) return Icons.pending_actions;
    return Icons.schedule;
  }

  Future<void> updateLessonStatus(Map<String, dynamic> lesson,
      {bool? completed, bool? paid}) async {
    try {
      final updatedLesson = Map<String, dynamic>.from(lesson);

      if (completed != null) {
        updatedLesson['is_completed'] = completed ? 1 : 0;
      }

      if (paid != null) {
        updatedLesson['payment_status'] = paid ? 1 : 0;
      }

      updatedLesson.remove('student_name');

      await DatabaseHelper.instance.updateLesson(updatedLesson);
      await updateDashboard();
    } catch (e) {
      print('Ders durumu güncelleme hatası: $e');
      rethrow;
    }
  }

  Future<void> updateLessonDate(
      Map<String, dynamic> lesson, DateTime newDate, TimeOfDay newTime) async {
    try {
      final updatedLesson = Map<String, dynamic>.from(lesson);
      updatedLesson['date'] = newDate.toString().split(' ')[0];
      updatedLesson['time'] =
          '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}';

      updatedLesson.remove('student_name');

      await DatabaseHelper.instance.updateLesson(updatedLesson);
      await updateDashboard();
    } catch (e) {
      print('Ders tarihi güncelleme hatası: $e');
      rethrow;
    }
  }
}
