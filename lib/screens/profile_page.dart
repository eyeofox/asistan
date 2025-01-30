import 'package:flutter/material.dart';
import 'login_screen.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isDarkMode = false;
  bool _isNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    // Örnek veriler
    _nameController.text = "Ahmet Yılmaz";
    _emailController.text = "ahmet@email.com";
    _phoneController.text = "555-123-4567";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            SizedBox(height: 32),
            _buildProfileForm(),
            SizedBox(height: 32),
            _buildSettings(),
            SizedBox(height: 32),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            'Profil Bilgileri',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kişisel Bilgiler',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Ad Soyad',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        SizedBox(height: 16),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'E-posta',
            prefixIcon: Icon(Icons.email),
          ),
        ),
        SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Telefon',
            prefixIcon: Icon(Icons.phone),
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            // Profil güncelleme işlemi
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Profil güncellendi')),
            );
          },
          child: Text('Bilgileri Güncelle'),
        ),
      ],
    );
  }

  Widget _buildSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ayarlar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        SwitchListTile(
          title: Text('Karanlık Mod'),
          value: _isDarkMode,
          onChanged: (value) {
            setState(() {
              _isDarkMode = value;
            });
          },
        ),
        SwitchListTile(
          title: Text('Bildirimler'),
          value: _isNotificationsEnabled,
          onChanged: (value) {
            setState(() {
              _isNotificationsEnabled = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Çıkış Yap'),
              content: Text('Çıkış yapmak istediğinizden emin misiniz?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('İptal'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text('Çıkış Yap'),
                ),
              ],
            ),
          );
        },
        icon: Icon(Icons.logout),
        label: Text('Çıkış Yap'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
