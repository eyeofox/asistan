import 'package:flutter/material.dart';

class StudentListPage extends StatefulWidget {
  @override
  _StudentListPageState createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  List<Student> students = []; // Örnek öğrenci listesi

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          return StudentCard(student: students[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddStudentDialog();
        },
        child: Icon(Icons.add),
        tooltip: 'Öğrenci Ekle',
      ),
    );
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String name = '';
        String phone = '';
        String email = '';

        return AlertDialog(
          title: Text('Yeni Öğrenci Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Ad Soyad'),
                onChanged: (value) => name = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Telefon'),
                onChanged: (value) => phone = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'E-posta'),
                onChanged: (value) => email = value,
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
                  students.add(Student(
                    name: name,
                    phone: phone,
                    email: email,
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

class StudentCard extends StatelessWidget {
  final Student student;

  const StudentCard({Key? key, required this.student}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(student.name[0]),
        ),
        title: Text(student.name),
        subtitle: Text(student.phone),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Text('Düzenle'),
              value: 'edit',
            ),
            PopupMenuItem(
              child: Text('Sil'),
              value: 'delete',
            ),
          ],
          onSelected: (value) {
            // Düzenleme ve silme işlemleri buraya gelecek
          },
        ),
      ),
    );
  }
}

class Student {
  final String name;
  final String phone;
  final String email;

  Student({
    required this.name,
    required this.phone,
    required this.email,
  });
}
