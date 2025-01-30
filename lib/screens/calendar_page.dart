import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selectedDate = DateTime.now();
  List<Lesson> lessons = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          selectedDate =
                              selectedDate.subtract(Duration(days: 1));
                        });
                      },
                    ),
                    Text(
                      DateFormat('dd MMMM yyyy').format(selectedDate),
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          selectedDate = selectedDate.add(Duration(days: 1));
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                return LessonCard(lesson: lessons[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddLessonDialog();
        },
        child: Icon(Icons.add),
        tooltip: 'Ders Ekle',
      ),
    );
  }

  void _showAddLessonDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String studentName = '';
        String subject = '';
        TimeOfDay time = TimeOfDay.now();

        return AlertDialog(
          title: Text('Yeni Ders Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Öğrenci Adı'),
                onChanged: (value) => studentName = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Ders Konusu'),
                onChanged: (value) => subject = value,
              ),
              TextButton(
                onPressed: () async {
                  final TimeOfDay? newTime = await showTimePicker(
                    context: context,
                    initialTime: time,
                  );
                  if (newTime != null) {
                    time = newTime;
                  }
                },
                child: Text('Saat Seç'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  lessons.add(Lesson(
                    studentName: studentName,
                    subject: subject,
                    time: time,
                  ));
                });
                Navigator.pop(context);
              },
              child: Text('Ekle'),
            ),
          ],
        );
      },
    );
  }
}

class Lesson {
  final String studentName;
  final String subject;
  final TimeOfDay time;

  Lesson({
    required this.studentName,
    required this.subject,
    required this.time,
  });
}

class LessonCard extends StatelessWidget {
  final Lesson lesson;

  const LessonCard({Key? key, required this.lesson}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(Icons.school),
        title: Text(lesson.studentName),
        subtitle: Text(lesson.subject),
        trailing: Text(
            '${lesson.time.hour}:${lesson.time.minute.toString().padLeft(2, '0')}'),
      ),
    );
  }
}
