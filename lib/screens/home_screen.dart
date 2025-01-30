import 'package:flutter/material.dart';
import 'student_list_page.dart';
import 'calendar_page.dart';
import 'payments_page.dart';
import 'profile_page.dart';
import 'dashboard_page.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static List<Widget> _pages = <Widget>[
    DashboardPage(),
    StudentListPage(),
    CalendarPage(),
    PaymentsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Bildirimler için
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Öğrenciler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Takvim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments),
            label: 'Ödemeler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Ana Sayfa';
      case 1:
        return 'Öğrenciler';
      case 2:
        return 'Takvim';
      case 3:
        return 'Ödemeler';
      case 4:
        return 'Profil';
      default:
        return 'Öğretmen Asistanı';
    }
  }
}
