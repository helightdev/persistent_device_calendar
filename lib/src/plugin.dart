import 'dart:developer';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'calendar.dart';
import 'store.dart';

typedef ForeignEventId = String;
typedef NativeEventId = String;

typedef PCEventBuilder<T> = Event Function(T event, String calendarId, String? eventId);
typedef PCIdSelector<T> = String Function(T);

class PersistentDeviceCalendar {

  var plugin = DeviceCalendarPlugin();

  PersistentDeviceCalendar();

  /// Requests device calendar READ & WRITE permissions.
  /// Returns the status of the permission grant.
  Future<bool> requestPermissions() async => (await plugin.requestPermissions()).data ?? false;

  /// Checks if device calendar READ & WRITE permissions are granted.
  Future<bool> hasPermissions() async => (await plugin.hasPermissions()).data ?? false;

  /// Setup READ & WRITE permissions for the device_calendar and return
  /// whether or not the setup has been successful.
  Future<bool> setup() async {
    if (!await hasPermissions()) return await requestPermissions();
    return true;
  }

  /// Wrapper for the createCalendar method
  Future<String?> pluginCreateCalendar(String? calendarName, {Color? calendarColor, String? localAccountName,}) async => (await plugin.createCalendar(calendarName, calendarColor: calendarColor, localAccountName: localAccountName)).data;


  /// Wrapper for the retrieveCalendars method
  Future<List<Calendar>?> pluginRetrieveCalendars() async => (await plugin.retrieveCalendars()).data;

  /// Wrapper for the retrieveEvents method
  Future<List<Event>?> pluginRetrieveEvents(String? calendarId, RetrieveEventsParams? args) async {
    var result = (await plugin.retrieveEvents(calendarId, args));
    if (result.errors.isNotEmpty) {
      for (var element in result.errors) { log(element.errorMessage); }
    }
    return result.data;
  }

  /// Wrapper for the deleteEvent method
  Future<bool> pluginDeleteEvent(String? calendarId, String? eventId) async => (await plugin.deleteEvent(calendarId, eventId)).data ?? false;

  /// Instantiates a [PersistentCalendarInstance] for the specified generic type [T].
  /// This will automatically create or get the device calendar identified by [name].
  ///
  /// Native events will be mapped to their foreign id provided by [idSelector]
  /// with the mapping being stored in [store]. Events will be constructed via
  /// [builder].
  Future<PersistentCalendarInstance<T>> getCalendar<T>({
    required String name,
    required PCEventBuilder<T> builder,
    required PCIdSelector<T> idSelector,
    DeviceCalendarEventStore? store
  }) async {
    var calendar = await getOrCreateCalendar(name);
    return PersistentCalendarInstance(this, builder, idSelector, calendar, store ?? SharedPreferencesDeviceCalendarStore());
  }

  Future<Calendar> getOrCreateCalendar(String name) async {
    var matching = (await pluginRetrieveCalendars())!.where((element) => element.name == name);
    if (matching.isNotEmpty) return matching.first;
    await pluginCreateCalendar(name);
    return getOrCreateCalendar(name);
  }

  Future<void> addInternal(Map<ForeignEventId, Event> data, DeviceCalendarEventStore store) async {
    var events = await store.getStoredEvents();
    var futures = List<Future<MapEntry<ForeignEventId, NativeEventId>>>.empty(growable: true);
    for (var e in data.entries) {
      futures.add(createOrUpdateEvent(e.value, e.key));
    }
    var results = await Future.wait(futures);
    events.addEntries(results);
    store.storeEvents(events);
  }

  Future<void> deleteInternal(Map<ForeignEventId, Event> data, DeviceCalendarEventStore store) async {
    var events = await store.getStoredEvents();
    var futures = List<Future<bool>>.empty(growable: true);
    var toDelete = data.map((key, value) => MapEntry(events[key], value));
    for (var e in toDelete.entries) {
      futures.add(pluginDeleteEvent(e.value.calendarId, e.key));
    }
    var results = await Future.wait(futures);
    events.removeWhere((key, value) => data.containsKey(key));
    store.storeEvents(events);
  }

  Future<MapEntry<ForeignEventId, NativeEventId>> createOrUpdateEvent(Event event, ForeignEventId id) async {
    var result = (await plugin.createOrUpdateEvent(event))!;
    if (result.errors.isNotEmpty) {
      for (var element in result.errors) { log(element.errorMessage); }
    }
    return MapEntry(id, result.data!);
  }
}