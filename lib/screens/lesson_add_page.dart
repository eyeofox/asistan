import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../helpers/database_helper.dart';
import '../providers/dashboard_provider.dart';

class LessonAddPage extends StatefulWidget {
  final Map<String, dynamic>? student;

  const LessonAddPage({Key? key, this.student}) : super(key: key);

  @override
  _LessonAddPageState createState() => _LessonAddPageState();
}

class _LessonAddPageState extends State<LessonAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _timeController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _selectedStudent;
  bool _isRecurring = false;
  int _selectedRecurringDay = 1;
  DateTime? _recurringUntilDate;
  bool _isLoading = false;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _durationController.text = '60'; // Varsayılan süre
    if (widget.student != null) {
      _selectedStudent = widget.student;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudents();
    });
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await DatabaseHelper.instance.getAllStudents();
      if (mounted) {
        setState(() {
          _students = students;
          if (_selectedStudent == null && students.isNotEmpty) {
            _selectedStudent = students.first;
          } else if (widget.student != null) {
            _selectedStudent = widget.student;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Öğrenci yükleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Öğrenciler yüklenirken bir hata oluştu')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _saveLesson() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final lesson = {
          'student_id': _selectedStudent!['id'],
          'subject': _subjectController.text,
          'price': double.parse(_priceController.text),
          'duration': int.parse(_durationController.text),
          'date': _selectedDate.toString().split(' ')[0],
          'time': _timeController.text,
          'is_completed': 0,
          'payment_status': 0,
          'is_recurring': _isRecurring ? 1 : 0,
          'recurring_day': _selectedRecurringDay,
          'recurring_until': _recurringUntilDate?.toString().split(' ')[0],
        };

        if (_isRecurring && _recurringUntilDate != null) {
          // Tekrarlanan dersler için
          var currentDate = _selectedDate;
          while (currentDate.isBefore(_recurringUntilDate!)) {
            final currentLesson = Map<String, dynamic>.from(lesson);
            currentLesson['date'] = currentDate.toString().split(' ')[0];
            await DatabaseHelper.instance.addLesson(currentLesson);

            // Bir sonraki dersin tarihini hesapla
            currentDate = currentDate.add(Duration(days: 7));
          }
        } else {
          // Tek seferlik ders için
          await DatabaseHelper.instance.addLesson(lesson);
        }

        // Dashboard'ı hemen güncelle
        if (!mounted) return;
        await Provider.of<DashboardProvider>(context, listen: false)
            .updateDashboard();

        // Başarı mesajı göster ve geri dön
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ders başarıyla eklendi')),
        );
      } catch (e) {
        print('Ders ekleme hatası: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ders eklenirken bir hata oluştu')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yeni Ders Ekle'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.student == null) ...[
                      DropdownButtonFormField<int>(
                        value: _selectedStudent?['id'],
                        decoration: InputDecoration(
                          labelText: 'Öğrenci',
                          border: OutlineInputBorder(),
                        ),
                        items: _students.map((student) {
                          return DropdownMenuItem<int>(
                            value: student['id'],
                            child: Text(student['name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedStudent = _students.firstWhere(
                                  (student) => student['id'] == newValue);
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null) return 'Lütfen öğrenci seçin';
                          return null;
                        },
                        isExpanded: true,
                      ),
                      SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        labelText: 'Ders Konusu',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen ders konusu girin';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Ücret',
                        prefixText: '₺',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen ücret girin';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _durationController,
                      decoration: InputDecoration(
                        labelText: 'Süre (dakika)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen süre girin';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text('Tarih'),
                      subtitle: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _timeController,
                      decoration: InputDecoration(
                        labelText: 'Saat',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      readOnly: true,
                      onTap: _selectTime,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen saat seçin';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    SwitchListTile(
                      title: Text('Tekrarlanan Ders'),
                      value: _isRecurring,
                      onChanged: (value) {
                        setState(() => _isRecurring = value);
                      },
                    ),
                    if (_isRecurring) ...[
                      DropdownButtonFormField<int>(
                        value: _selectedRecurringDay,
                        decoration: InputDecoration(
                          labelText: 'Tekrar Günü',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(value: 1, child: Text('Pazartesi')),
                          DropdownMenuItem(value: 2, child: Text('Salı')),
                          DropdownMenuItem(value: 3, child: Text('Çarşamba')),
                          DropdownMenuItem(value: 4, child: Text('Perşembe')),
                          DropdownMenuItem(value: 5, child: Text('Cuma')),
                          DropdownMenuItem(value: 6, child: Text('Cumartesi')),
                          DropdownMenuItem(value: 7, child: Text('Pazar')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedRecurringDay = value);
                          }
                        },
                      ),
                      SizedBox(height: 16),
                      ListTile(
                        title: Text('Tekrar Bitiş Tarihi'),
                        subtitle: Text(
                          _recurringUntilDate != null
                              ? '${_recurringUntilDate!.day}/${_recurringUntilDate!.month}/${_recurringUntilDate!.year}'
                              : 'Seçilmedi',
                        ),
                        trailing: Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _recurringUntilDate ??
                                _selectedDate.add(Duration(days: 30)),
                            firstDate: _selectedDate,
                            lastDate: _selectedDate.add(Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => _recurringUntilDate = date);
                          }
                        },
                      ),
                    ],
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveLesson,
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
    _subjectController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _timeController.dispose();
    super.dispose();
  }
}
