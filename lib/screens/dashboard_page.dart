import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/weekly_schedule_widget.dart';
import '../helpers/database_helper.dart';
import 'student_add_page.dart';
import 'lesson_add_page.dart';
import 'payment_add_page.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    await Provider.of<DashboardProvider>(context, listen: false)
        .updateDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Öğretmen Asistanı'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: Consumer<DashboardProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İstatistik Kartları
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Toplam Öğrenci',
                            provider.totalStudents.toString(),
                            Icons.people,
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            'Bugünkü Dersler',
                            provider.todaysLessons.toString(),
                            Icons.calendar_today,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if ((provider.dashboardData['pending_lessons'] ??
                                      0) >
                                  0) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Ödenmemiş Dersler'),
                                    content: FutureBuilder<
                                        List<Map<String, dynamic>>>(
                                      future: DatabaseHelper.instance
                                          .getUnpaidLessons(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Center(
                                              child:
                                                  CircularProgressIndicator());
                                        }

                                        if (!snapshot.hasData ||
                                            snapshot.data!.isEmpty) {
                                          return Text(
                                              'Ödenmemiş ders bulunamadı');
                                        }

                                        return SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: snapshot.data!
                                                .map((lesson) => ListTile(
                                                      title: Text(lesson[
                                                          'student_name']),
                                                      subtitle: Text(
                                                          '${lesson['date']} - ${lesson['subject']}'),
                                                      trailing: Text(
                                                          '₺${lesson['price']}'),
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                PaymentAddPage(
                                                                    lesson:
                                                                        lesson),
                                                          ),
                                                        );
                                                      },
                                                    ))
                                                .toList(),
                                          ),
                                        );
                                      },
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Kapat'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            child: Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Icon(Icons.monetization_on,
                                        color: Colors.orange, size: 32),
                                    SizedBox(height: 8),
                                    Text(
                                      'Kazanç Durumu',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '₺${(provider.dashboardData['total_received'] ?? 0.0).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Text(
                                      'Beklenen: ₺${(provider.dashboardData['total_expected'] ?? 0.0).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    if ((provider.dashboardData[
                                                'pending_lessons'] ??
                                            0) >
                                        0)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${provider.dashboardData['pending_lessons']} ders ödenmedi',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.red,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color: Colors.red,
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(Icons.access_time,
                                      color: Colors.purple, size: 32),
                                  SizedBox(height: 8),
                                  Text(
                                    'Ders Saatleri',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${provider.dashboardData['completed_hours'] ?? 0} / ${provider.dashboardData['total_hours'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  Text(
                                    'Tamamlanan: ${provider.dashboardData['completed_lessons'] ?? 0} / ${provider.dashboardData['total_lessons'] ?? 0} ders',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Haftalık Program
                  WeeklyScheduleWidget(),

                  // Bugünkü Dersler
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Bugünkü Dersler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (provider.todaysLessonsList.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Bugün ders yok'),
                    )
                  else
                    ...provider.todaysLessonsList.map((lesson) {
                      // Dersin zamanını kontrol edelim
                      final now = DateTime.now();
                      final lessonTime = TimeOfDay(
                        hour: int.parse(lesson['time'].split(':')[0]),
                        minute: int.parse(lesson['time'].split(':')[1]),
                      );
                      final lessonDateTime = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        lessonTime.hour,
                        lessonTime.minute,
                      );
                      final isLessonTime = now.isAfter(lessonDateTime);

                      return Card(
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                isLessonTime ? Colors.blue : Colors.grey[300],
                            child: Text(
                              lesson['student_name'][0].toUpperCase(),
                              style: TextStyle(
                                color: isLessonTime
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                          title: Text(
                            lesson['student_name'],
                            style: TextStyle(
                              color: isLessonTime
                                  ? Colors.black
                                  : Colors.grey[600],
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson['subject'],
                                style: TextStyle(
                                  color: isLessonTime
                                      ? Colors.black87
                                      : Colors.grey[600],
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: isLessonTime
                                        ? Colors.blue
                                        : Colors.grey,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    lesson['time'],
                                    style: TextStyle(
                                      color: isLessonTime
                                          ? Colors.blue
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (lesson['is_completed'] == 1) ...[
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Tamamlandı',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  if (lesson['payment_status'] == 1) ...[
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.paid,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Ödendi',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  lesson['is_completed'] == 1
                                      ? Icons.check_circle
                                      : Icons.check_circle_outline,
                                  color: !isLessonTime
                                      ? Colors.grey[300]
                                      : lesson['is_completed'] == 1
                                          ? Colors.green
                                          : Colors.grey,
                                ),
                                onPressed: isLessonTime
                                    ? () async {
                                        final updatedLesson = {
                                          'id': lesson['id'],
                                          'is_completed':
                                              lesson['is_completed'] == 1
                                                  ? 0
                                                  : 1,
                                        };

                                        await DatabaseHelper.instance
                                            .updateLesson(updatedLesson);

                                        if (updatedLesson['is_completed'] ==
                                                1 &&
                                            lesson['payment_status'] == 0) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('Ders Tamamlandı'),
                                              content: Text(
                                                  '${lesson['student_name']} için ders tamamlandı. Ödeme almak ister misiniz?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text('SONRA'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            PaymentAddPage(
                                                                lesson: lesson),
                                                      ),
                                                    );
                                                  },
                                                  child: Text('ÖDEME AL'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        Provider.of<DashboardProvider>(context,
                                                listen: false)
                                            .updateDashboard();
                                      }
                                    : null,
                              ),
                              if (lesson['is_completed'] == 1 &&
                                  lesson['payment_status'] == 0)
                                IconButton(
                                  icon:
                                      Icon(Icons.payment, color: Colors.orange),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PaymentAddPage(lesson: lesson),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                  // Bekleyen Ödemeler
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Bekleyen Ödemeler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (provider.upcomingPayments.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Bekleyen ödeme yok'),
                    )
                  else
                    ...provider.upcomingPayments
                        .map((payment) => Card(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: ListTile(
                                title: Text(payment['student_name']),
                                subtitle: Text(
                                    '${payment['date']} - ${payment['subject']}'),
                                trailing: Text('₺${payment['price']}'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PaymentAddPage(lesson: payment),
                                    ),
                                  );
                                },
                              ),
                            ))
                        .toList(),

                  // Son Ödemeler
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Son Ödemeler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (provider.recentPayments.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Henüz ödeme yapılmamış'),
                    )
                  else
                    ...provider.recentPayments
                        .map((payment) => Card(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: ListTile(
                                title: Text(payment['student_name']),
                                subtitle: Text(
                                    '${payment['date']} - ${payment['amount']}₺'),
                                trailing: Icon(Icons.check_circle,
                                    color: Colors.green),
                              ),
                            ))
                        .toList(),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.person_add),
                    title: Text('Yeni Öğrenci Ekle'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentAddPage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.add_box),
                    title: Text('Yeni Ders Ekle'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LessonAddPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
