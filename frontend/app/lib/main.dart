import 'dart:async';
import 'package:flutter/material.dart';

import 'data/diary.dart';
import 'screens/calendar_screen.dart';
import 'screens/character_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await DiaryDatabase.instance.init();
  // runApp(const EmotionCalendarApp());

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    Zone.current.handleUncaughtError(
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };

  ErrorWidget.builder = (details) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '화면을 표시하는 중 오류가 발생했습니다.\n\n${details.exceptionAsString()}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  };

  await runZonedGuarded(() async {
    try {
      await DiaryDatabase.instance.init();
    } catch (e, st) {
      debugPrint('DiaryDatabase init failed: $e');
      debugPrintStack(stackTrace: st);
    }

    runApp(const EmotionCalendarApp());
  }, (error, stackTrace) {
    debugPrint('Uncaught app error: $error');
    debugPrintStack(stackTrace: stackTrace);
  });
}

class EmotionCalendarApp extends StatelessWidget {
  const EmotionCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      ),
      home: const RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    MainChatScreen(),
    CalendarScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: '캐릭터',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '캘린더',
          ),
        ],
      ),
    );
  }
}