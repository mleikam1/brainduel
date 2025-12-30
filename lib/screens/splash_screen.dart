import 'package:flutter/material.dart';
import '../app.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(TriviaApp.routeHome);
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: error == null
            ? const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Brain Duel', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            SizedBox(height: 12),
            CircularProgressIndicator(),
          ],
        )
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Boot failed: $error'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _boot, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
