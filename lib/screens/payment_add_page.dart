import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../helpers/database_helper.dart';
import '../providers/dashboard_provider.dart';

class PaymentAddPage extends StatefulWidget {
  final Map<String, dynamic>? lesson;
  final Map<String, dynamic>? student;

  const PaymentAddPage({Key? key, this.lesson, this.student}) : super(key: key);

  @override
  _PaymentAddPageState createState() => _PaymentAddPageState();
}

class _PaymentAddPageState extends State<PaymentAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.lesson != null) {
      _amountController.text = widget.lesson!['price'].toString();
    }
  }

  Future<void> _savePayment() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Ödeme kaydı
        final payment = {
          'student_id': widget.student!['id'],
          'lesson_id': widget.lesson?['id'],
          'amount': double.parse(_amountController.text),
          'date': _selectedDate.toString().split(' ')[0],
          'note': _noteController.text,
        };

        await DatabaseHelper.instance.addPayment(payment);

        // Ders durumunu güncelle
        if (widget.lesson != null) {
          final lessonUpdate = Map<String, dynamic>.from(widget.lesson!);
          lessonUpdate['payment_status'] = 1;
          lessonUpdate.remove('student_name'); // Join'den gelen alanı kaldır

          await DatabaseHelper.instance.updateLesson(lessonUpdate);
        }

        // Dashboard'ı güncelle
        if (!mounted) return;
        await Provider.of<DashboardProvider>(context, listen: false)
            .updateDashboard();

        // Başarı mesajı ve geri dön
        if (!mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ödeme başarıyla kaydedildi')),
        );
      } catch (e) {
        print('Ödeme kaydetme hatası: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ödeme kaydedilirken bir hata oluştu')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ödeme Al'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Öğrenci bilgisi
              Card(
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text(widget.student?['name'] ?? ''),
                ),
              ),
              SizedBox(height: 16),

              // Ders bilgisi
              if (widget.lesson != null)
                Card(
                  child: ListTile(
                    leading: Icon(Icons.book),
                    title: Text(widget.lesson!['subject']),
                    subtitle: Text(
                        '${widget.lesson!['date']} ${widget.lesson!['time']}'),
                  ),
                ),
              if (widget.lesson != null) SizedBox(height: 16),

              // Tutar
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Tutar',
                  prefixText: '₺',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen tutar girin';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Not
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Not',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),

              // Tarih seçici
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
                    firstDate: DateTime.now().subtract(Duration(days: 365)),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
              SizedBox(height: 24),

              // Kaydet butonu
              ElevatedButton(
                onPressed: _savePayment,
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
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
