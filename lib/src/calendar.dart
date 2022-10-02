import 'dart:developer';

import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart';

import 'plugin.dart';
import 'store.dart';

class PersistentCalendarInstance<T> {

  PCEventBuilder<T> eventBuilder;
  PCIdSelector<T> idSelector;
  Calendar calendar;
  PersistentDeviceCalendar parent;
  DeviceCalendarEventStore store;

  PersistentCalendarInstance(this.parent, this.eventBuilder, this.idSelector, this.calendar, this.store);

  Map<String, Event> _mapItems(List<T> events) => Map<String, Event>.fromEntries(events.map((e) => MapEntry(idSelector(e), eventBuilder(e, calendar.id!, null))));
  Map<String, T> _mapIds(List<T> events) => Map<String, T>.fromEntries(events.map((e) => MapEntry(idSelector(e), e)));

  /// Adds a list of events possibly containing duplicates.
  Future<void> add(Iterable<T> events) async {
    var map = _mapItems(events.toList());
    await parent.addInternal(map, store);
  }

  /// Deletes a list of events.
  Future<void> delete(Iterable<T> events) async {
    var map = _mapItems(events.toList());
    await parent.deleteInternal(map, store);
  }

  /// Adds a list of events, possibly overriding already existing events.
  Future<void> put(Iterable<T> events) async {
    var map = _mapIds(events.toList());
    var storedEvents = await store.getStoredEvents();
    var actualEvents = <ForeignEventId, Event>{};
    actualEvents.addAll(Map.fromEntries(storedEvents.entries.where((element) => map.containsKey(element.key)).map((e) {
      var tInstance = map[e.key] as T;
      return MapEntry(e.key, eventBuilder(tInstance, calendar.id!, e.value));
    })));
    actualEvents.addAll(Map.fromEntries(map.entries.where((element) => !storedEvents.containsKey(element.key)).map((e) {
      var tInstance = map[e.key] as T;
      return MapEntry(e.key, eventBuilder(tInstance, calendar.id!, null));
    })));
    parent.addInternal(actualEvents, store);
  }

  /// Removes event entries from the store, whose respective device calendar
  /// event is not present anymore. [startOverride] and [endOverride] define
  /// the scan range for the native calendar. Events which are outside of the
  /// scan range will be pruned. The default time range is 1900-2100 utc.
  Future<void> prune([TZDateTime? startOverride, TZDateTime? endOverride]) async {
    var start = startOverride ?? TZDateTime.utc(1900);
    var end = endOverride ?? TZDateTime.utc(2100);
    var events = await store.getStoredEvents();
    var existingEvents = (await parent.pluginRetrieveEvents(calendar.id, RetrieveEventsParams(startDate: start, endDate: end))) ?? [];
    for (var e in events.entries.toList()) {
      if (!existingEvents.any((element) => element.eventId == e.value)) events.removeWhere((key, value) => key == e.key);
    }
    await store.storeEvents(events);
  }
}