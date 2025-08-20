import 'package:delegate/Login_screen.dart';
import 'package:delegate/orders_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(
      const Duration(milliseconds: 1500),
    ); // تقليل زمن الانتظار

    final user = FirebaseAuth.instance.currentUser;
    final route = user != null
        ? MaterialPageRoute(builder: (_) => OrdersScreen())
        : MaterialPageRoute(builder: (_) => LoginScreen());

    if (!mounted) return;
    Navigator.pushReplacement(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, const Color(0xFF8B0000).withOpacity(0.1)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة متحركة بسيطة
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.8, end: 1.2),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B0000).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF8B0000).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.card_giftcard,
                        size: 60,
                        color: const Color(0xFF8B0000),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              // مؤشر تقدم مع تصميم مخصص
              SizedBox(
                width: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF8B0000),
                    ),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // نص بسيط مع تأثير ظهور تدريجي
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 500),
                child: const Text(
                  'جاري التحميل...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8B0000),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
