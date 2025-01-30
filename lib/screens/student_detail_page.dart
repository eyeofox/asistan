import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import 'lesson_add_page.dart';
import 'payment_add_page.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';

class StudentDetailPage extends StatefulWidget {
  final Map<String, dynamic> student;

  StudentDetailPage({required this.student});

  @override
  _StudentDetailPageState createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  List<Map<String, dynamic>> _lessons = [];
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {
    'total_lessons': 0,
    'completed_lessons': 0,
    'total_payments': 0.0,
    'expected_payments': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Öğrencinin dersleri
      final lessons = await DatabaseHelper.instance
          .getLessonsForStudent(widget.student['id']);

      // Öğrencinin ödemeleri
      final payments = await DatabaseHelper.instance
          .getPaymentsForStudent(widget.student['id']);

      // İstatistikleri hesapla
      double totalPayments = 0.0;
      double expectedPayments = 0.0;
      int completedLessons = 0;

      for (var lesson in lessons) {
        if (lesson['is_completed'] == 1) {
          completedLessons++;
        }
        expectedPayments += lesson['price'];
      }

      for (var payment in payments) {
        totalPayments += payment['amount'];
      }

      setState(() {
        _lessons = lessons;
        _payments = payments;
        _statistics = {
          'total_lessons': lessons.length,
          'completed_lessons': completedLessons,
          'total_payments': totalPayments,
          'expected_payments': expectedPayments,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Veri yükleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veriler yüklenirken bir hata oluştu')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.student['name']),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Dersler'),
              Tab(text: 'Ödemeler'),
            ],
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // İstatistik Kartları
                  Container(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Text(
                                    'Toplam Ders',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    '${_statistics['total_lessons']}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Tamamlanan: ${_statistics['completed_lessons']}',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Text(
                                    'Ödemeler',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    '₺${_statistics['total_payments'].toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'Beklenen: ₺${_statistics['expected_payments'].toStringAsFixed(2)}',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Sekmeli İçerik
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Dersler Sekmesi
                        _lessons.isEmpty
                            ? Center(child: Text('Henüz ders yok'))
                            : ListView.builder(
                                itemCount: _lessons.length,
                                itemBuilder: (context, index) {
                                  final lesson = _lessons[index];
                                  return Card(
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: ListTile(
                                      title: Text(lesson['subject']),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              '${lesson['date']} ${lesson['time']}'),
                                          Text(
                                            '₺${lesson['price']}',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (lesson['is_completed'] != 1)
                                            IconButton(
                                              icon: Icon(
                                                  Icons.check_circle_outline),
                                              color: Colors.green,
                                              tooltip: 'Dersi Tamamla',
                                              onPressed: () async {
                                                await DatabaseHelper.instance
                                                    .updateLesson({
                                                  ...lesson,
                                                  'is_completed': 1,
                                                });
                                                _loadData();
                                                Provider.of<DashboardProvider>(
                                                        context,
                                                        listen: false)
                                                    .updateDashboard();
                                              },
                                            ),
                                          if (lesson['is_completed'] == 1 &&
                                              lesson['payment_status'] != 1)
                                            IconButton(
                                              icon: Icon(Icons.payment),
                                              color: Colors.orange,
                                              tooltip: 'Ödeme Al',
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        PaymentAddPage(
                                                      student: widget.student,
                                                      lesson: lesson,
                                                    ),
                                                  ),
                                                ).then((_) {
                                                  _loadData();
                                                  Provider.of<DashboardProvider>(
                                                          context,
                                                          listen: false)
                                                      .updateDashboard();
                                                });
                                              },
                                            ),
                                          if (lesson['payment_status'] == 1)
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                        // Ödemeler Sekmesi
                        _payments.isEmpty
                            ? Center(child: Text('Henüz ödeme yok'))
                            : ListView.builder(
                                itemCount: _payments.length,
                                itemBuilder: (context, index) {
                                  final payment = _payments[index];
                                  return Card(
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.green,
                                        child: Icon(Icons.payment,
                                            color: Colors.white),
                                      ),
                                      title: Text(
                                        '₺${payment['amount']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(payment['date']),
                                          if (payment['lesson_subject'] != null)
                                            Text(
                                              payment['lesson_subject'],
                                              style:
                                                  TextStyle(color: Colors.blue),
                                            ),
                                          if (payment['note'] != null &&
                                              payment['note'].isNotEmpty)
                                            Text(
                                              payment['note'],
                                              style: TextStyle(
                                                  fontStyle: FontStyle.italic),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
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
                      leading: Icon(Icons.book),
                      title: Text('Yeni Ders Ekle'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LessonAddPage(student: widget.student),
                          ),
                        ).then((_) {
                          _loadData();
                          Provider.of<DashboardProvider>(context, listen: false)
                              .updateDashboard();
                        });
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.payment),
                      title: Text('Yeni Ödeme Ekle'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PaymentAddPage(student: widget.student),
                          ),
                        ).then((_) {
                          _loadData();
                          Provider.of<DashboardProvider>(context, listen: false)
                              .updateDashboard();
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
