
import 'package:shared_preferences/shared_preferences.dart';

import '../persistent_device_calendar.dart';

abstract class DeviceCalendarEventStore {

  Future<Map<ForeignEventId, NativeEventId>> getStoredEvents();
  Future storeEvents(Map<ForeignEventId, NativeEventId> data);

}

class SharedPreferencesDeviceCalendarStore extends DeviceCalendarEventStore {

  final String listKey;

  SharedPreferencesDeviceCalendarStore({
    this.listKey = "deviceCalendarEvents",
  });

  @override
  Future<Map<ForeignEventId, NativeEventId>> getStoredEvents() async {
    var preferences = await SharedPreferences.getInstance();
    var entries = (preferences.getStringList(listKey)??[]).map((e) {
      var spliced = e.split(":");
      return MapEntry(spliced[0], spliced[1]);
    });
    return Map<ForeignEventId, NativeEventId>.fromEntries(entries);
  }

  @override
  Future storeEvents(Map<ForeignEventId, NativeEventId> data) async {
    var preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(listKey, data.entries.map((e) => "${e.key}:${e.value}").toList());
  }
}