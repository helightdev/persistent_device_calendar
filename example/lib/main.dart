import 'package:example/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:persistent_device_calendar/persistent_device_calendar.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  tz.initializeTimeZones();
  runApp(const MyApp());
}

class CustomEvent {
  
  String id;
  String name;

  CustomEvent({
    required this.id,
    required this.name,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CalendarView()
    );
  }
}