import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/helpers.dart';
import 'lock_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // الانتقال لشاشة القفل بعد 3 ثوانٍ
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LockScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F766E), // اللون الزمردي الأساسي
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // الأيقونة
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  // قراءة الأيقونة من مجلد assets
                  child: Image.asset(
                    'assets/icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // في حال عدم وجود الصورة، تظهر أيقونة افتراضية
                      return const Icon(Icons.school, size: 80, color: Color(0xFF0F766E));
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // اسم التطبيق
            const Text(
              'رسومك الدراسية',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'نظام إدارة الرسوم والطلاب',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const Spacer(),
            // بيانات المطور
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  Text(
                    'تطوير وتصميم',
                    style: TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Abu Almulla',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '+249922008009',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
