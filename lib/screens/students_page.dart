import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import 'student_add_page.dart';
import 'student_detail_page.dart';

class StudentsPage extends StatefulWidget {
  @override
  _StudentsPageState createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final students = await DatabaseHelper.instance.getAllStudents();
    setState(() {
      _students = students;
      _isLoading = false;
    });
  }

  void _filterStudents(String query) {
    if (query.isEmpty) {
      _loadStudents();
    } else {
      setState(() {
        _students = _students.where((student) {
          final name = student['name'].toString().toLowerCase();
          final phone = (student['phone'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || phone.contains(searchLower);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Öğrenciler'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStudents,
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama Çubuğu
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Öğrenci Ara',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onChanged: _filterStudents,
            ),
          ),

          // Öğrenci Listesi
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Henüz öğrenci eklenmemiş'
                              : 'Aranan kriterlere uygun öğrenci bulunamadı',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          return Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  student['name'][0].toUpperCase(),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                student['name'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (student['phone'] != null &&
                                      student['phone'].isNotEmpty)
                                    Text('📞 ${student['phone']}'),
                                  if (student['email'] != null &&
                                      student['email'].isNotEmpty)
                                    Text('📧 ${student['email']}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              StudentAddPage(student: student),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadStudents();
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('Öğrenciyi Sil'),
                                          content: Text(
                                              '${student['name']} isimli öğrenciyi silmek istediğinize emin misiniz?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text('İPTAL'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                await DatabaseHelper.instance
                                                    .deleteStudent(
                                                        student['id']);
                                                Navigator.pop(context);
                                                _loadStudents();
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          'Öğrenci silindi')),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red),
                                              child: Text('SİL'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        StudentDetailPage(student: student),
                                  ),
                                ).then((_) => _loadStudents());
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentAddPage(),
            ),
          );
          if (result == true) {
            _loadStudents();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
