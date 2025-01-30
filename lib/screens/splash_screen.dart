import 'package:flutter/material.dart';
import 'dart:async';
import 'package:teacher_assistant/main.dart'; // Doğru import yap

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/splash_logo.png', width: 200), // Logonu ekle
            SizedBox(height: 20),
            CircularProgressIndicator(), // Yüklenme animasyonu
          ],
        ),
      ),
    );
  }
}
