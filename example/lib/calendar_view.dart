import 'package:flutter/material.dart';
import 'package:persistent_device_calendar/persistent_device_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart';

import 'main.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({Key? key}) : super(key: key);

  @override
  _CalendarViewState createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {

  static PersistentDeviceCalendar calPlugin = PersistentDeviceCalendar();

  @override
  void initState() {
    super.initState();
    run();
  }

  Future run() async {
    if (!await calPlugin.setup()) return;

    var start = TZDateTime.now(getLocation("America/Detroit"));
    var end = start.add(const Duration(hours: 2));

    var calendar = await calPlugin.getCalendar<CustomEvent>(name: "Custom Events",
        builder: (event, calendarId, eventId) => Event(calendarId, eventId: eventId, title: event.name, start: start, end: end),
        idSelector: (event) => event.id
    );
    await calendar.prune();

    var events = [CustomEvent(id: "a", name: "Event A"), CustomEvent(id: "b", name: "Event B"), CustomEvent(id: "c", name: "Event C")];
    await calendar.put(events);
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
