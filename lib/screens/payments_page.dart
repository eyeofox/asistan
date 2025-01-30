import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';

class PaymentsPage extends StatefulWidget {
  @override
  _PaymentsPageState createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final payments = await db.rawQuery('''
        SELECT p.*, s.name as student_name 
        FROM payments p 
        JOIN students s ON p.student_id = s.id 
        ORDER BY p.date DESC
      ''');
      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      print('Ödemeler yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Henüz ödeme kaydı yok',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(
                payment['is_paid'] == 1 ? Icons.check : Icons.pending,
                color: Colors.white,
              ),
              backgroundColor:
                  payment['is_paid'] == 1 ? Colors.green : Colors.orange,
            ),
            title: Text(payment['student_name']),
            subtitle: Text(payment['date']),
            trailing: Text(
              '₺${payment['amount']}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: payment['is_paid'] == 1 ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }
}
