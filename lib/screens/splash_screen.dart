import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../services/data_service.dart';
import '../services/storage_service.dart';
import 'user_select_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final data = context.read<DataService>();
    final storage = context.read<StorageService>();
    final subjects = await data.loadAll();
    if (!mounted) return;

    final users = storage.getUserList();
    final active = storage.getActiveUser();

    if (users.isEmpty || active.isEmpty || !users.contains(active)) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => UserSelectScreen(subjects: subjects)),
      );
    } else {
      await storage.resetDailyMissions();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(subjects: subjects)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌙', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

List<Subject> subjectsWithData(List<Subject> subjects) => subjects.where((s) => s.konular.isNotEmpty).toList();
