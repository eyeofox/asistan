import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';

class StudentAddPage extends StatefulWidget {
  final Map<String, dynamic>? student;

  const StudentAddPage({Key? key, this.student}) : super(key: key);

  @override
  _StudentAddPageState createState() => _StudentAddPageState();
}

class _StudentAddPageState extends State<StudentAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _nameController.text = widget.student!['name'];
      _phoneController.text = widget.student!['phone'] ?? '';
      _emailController.text = widget.student!['email'] ?? '';
      _addressController.text = widget.student!['address'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.student == null ? 'Yeni Öğrenci' : 'Öğrenci Düzenle'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Ad Soyad',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen ad soyad girin';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Telefon',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Adres',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final student = {
                      if (widget.student != null) 'id': widget.student!['id'],
                      'name': _nameController.text,
                      'phone': _phoneController.text,
                      'email': _emailController.text,
                      'address': _addressController.text,
                    };

                    if (widget.student == null) {
                      await DatabaseHelper.instance.addStudent(student);
                    } else {
                      await DatabaseHelper.instance.updateStudent(student);
                    }

                    Navigator.pop(context, true);
                  }
                },
                child: Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
