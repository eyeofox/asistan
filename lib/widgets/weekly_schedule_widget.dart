import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../screens/payment_add_page.dart';

class WeeklyScheduleWidget extends StatelessWidget {
  final List<String> _days = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar'
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Haftalık Program',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () => provider.updateDashboard(),
                  ),
                ],
              ),
            ),
            for (int i = 0; i < _days.length; i++)
              _buildDaySchedule(context, provider, i + 1, _days[i]),
          ],
        );
      },
    );
  }

  Widget _buildDaySchedule(BuildContext context, DashboardProvider provider,
      int dayIndex, String dayName) {
    final lessonsForDay = provider.getLessonsForDay(dayIndex);
    final isToday = DateTime.now().weekday == dayIndex;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isToday ? Colors.blue.withOpacity(0.1) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.blue : null,
                  ),
                ),
                if (isToday)
                  Container(
                    margin: EdgeInsets.only(left: 8),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Bugün',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (lessonsForDay.isEmpty)
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Ders yok',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...lessonsForDay
                .map((lesson) => _buildLessonCard(context, provider, lesson)),
        ],
      ),
    );
  }

  Widget _buildLessonCard(BuildContext context, DashboardProvider provider,
      Map<String, dynamic> lesson) {
    final lessonDate = DateTime.parse(lesson['date']);
    final isPassedLesson = lessonDate.isBefore(DateTime.now());

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: provider.getLessonStatusColor(lesson),
          child: Icon(
            provider.getLessonStatusIcon(lesson),
            color: Colors.white,
          ),
        ),
        title: Text(lesson['student_name'] ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${lesson['time']} - ${lesson['subject']}'),
            Text(
              provider.formatPrice(lesson['price'].toDouble()),
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              provider.getLessonStatus(lesson),
              style: TextStyle(
                color: provider.getLessonStatusColor(lesson),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing:
            _buildLessonActions(context, provider, lesson, isPassedLesson),
      ),
    );
  }

  Widget _buildLessonActions(BuildContext context, DashboardProvider provider,
      Map<String, dynamic> lesson, bool isPassedLesson) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.event_repeat),
          color: Colors.blue,
          tooltip: 'Dersi Taşı',
          onPressed: () =>
              _showRescheduleLessonDialog(context, provider, lesson),
        ),
        if (isPassedLesson && !provider.isLessonCompleted(lesson))
          IconButton(
            icon: Icon(Icons.check_circle_outline),
            color: Colors.green,
            tooltip: 'Dersi Tamamla',
            onPressed: () => _completeLesson(context, provider, lesson),
          ),
        if (isPassedLesson &&
            provider.isLessonCompleted(lesson) &&
            !provider.isPaymentReceived(lesson))
          IconButton(
            icon: Icon(Icons.payment),
            color: Colors.orange,
            tooltip: 'Ödeme Al',
            onPressed: () => _showPaymentPage(context, provider, lesson),
          ),
      ],
    );
  }

  Future<void> _showRescheduleLessonDialog(BuildContext context,
      DashboardProvider provider, Map<String, dynamic> lesson) async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    // Mevcut ders saatini al
    final currentTime = lesson['time'].toString().split(':');
    final currentHour = int.parse(currentTime[0]);
    final currentMinute = int.parse(currentTime[1]);

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Dersi Taşı'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Tarih Seç'),
                subtitle: Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
                  }
                },
              ),
              ListTile(
                title: Text('Saat Seç'),
                subtitle: Text(
                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime:
                        TimeOfDay(hour: currentHour, minute: currentMinute),
                  );
                  if (time != null) {
                    setState(() => selectedTime = time);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('İptal'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('Taşı'),
              onPressed: () async {
                try {
                  await provider.updateLessonDate(
                      lesson, selectedDate, selectedTime);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ders başarıyla taşındı')),
                  );
                } catch (e) {
                  print('Ders taşıma hatası: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ders taşınırken bir hata oluştu')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeLesson(BuildContext context, DashboardProvider provider,
      Map<String, dynamic> lesson) async {
    try {
      await provider.updateLessonStatus(lesson, completed: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ders tamamlandı')),
      );
    } catch (e) {
      print('Ders tamamlama hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ders tamamlanırken bir hata oluştu')),
      );
    }
  }

  void _showPaymentPage(BuildContext context, DashboardProvider provider,
      Map<String, dynamic> lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentAddPage(
          student: {'id': lesson['student_id'], 'name': lesson['student_name']},
          lesson: lesson,
        ),
      ),
    ).then((_) => provider.updateDashboard());
  }
}
