# Persistent Device Calendar
## Features
This package contains a wrapper for the device_calendar plugin which adds persistence and 
quality-of-life improvements, reducing boilerplate code in common use-cases, as well as
improving code readability and simplicity.

NOTE: This package currently only aims to provide basic calendar functionality, recurrence
for events has not been tested with this package and is considered not supported.

## Example
```dart
void usage() async {
  var calPlugin = PersistentDeviceCalendar();
  if (!await calPlugin.setup()) return; // Setup permissions or return if not granted
  
  var start = TZDateTime.now(getLocation("America/Detroit")); // Constant debug times
  var end = start.add(const Duration(hours: 2));
  
  var calendar = await calPlugin.getCalendar<CustomEvent>(name: "Custom Events",
      builder: (event, calendarId, eventId) => Event(calendarId, eventId: eventId, title: event.name, start: start, end: end),
      idSelector: (event) => event.id
  );
  await calendar.prune(); // Optionally remove registered events which have been deleted on the device

  var events = [
    CustomEvent(id: "a", name: "Event A"),
    CustomEvent(id: "b", name: "Event B"), 
    CustomEvent(id: "c", name: "Event C")
  ];
  await calendar.put(events); // Put events, possibly replacing old version
}

class CustomEvent {

  String id;
  String name;

  CustomEvent({
    required this.id,
    required this.name,
  });
}
```

## Timezones with TZDateTime (from device_calendar)
Due to feedback we received, starting from `4.0.0` we will be using the `timezone` package to
better handle all timezone data.

This is already included in this package. However, you need to add this line
whenever the package is needed.

```dart
import 'package:timezone/timezone.dart';
```

If you don't need any timezone specific features in your app, you may use `flutter_native_timezone`
to get your devices' current timezone, then convert your previous `DateTime` with it.

```dart
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

// As an example, our default timezone is UTC.
Location _currentLocation = getLocation('Etc/UTC');

Future setCurentLocation() async {
  String timezone = 'Etc/UTC';
  try {
    timezone = await FlutterNativeTimezone.getLocalTimezone();
  } catch (e) {
    print('Could not get the local timezone');
  }
  _currentLocation = getLocation(timezone);
  setLocalLocation(_currentLocation);
}

...

event.start = TZDateTime.from(oldDateTime, _currentLocation);
```

For other use cases, feedback or future developments on the feature, feel free to
open a discussion on GitHub.

## Platform Setup (from device_calendar)
### Android Integration

The following will need to be added to the `AndroidManifest.xml` file for your application to
indicate permissions to modify calendars are needed

```xml
<uses-permission android:name="android.permission.READ_CALENDAR" />
<uses-permission android:name="android.permission.WRITE_CALENDAR" />
```

#### Proguard / R8 exceptions

By default, all android apps go through R8 for file shrinking when building a release version.
Currently, it interferes with some functions such as `retrieveCalendars()`.

You may add the following setting to the ProGuard rules file `proguard-rules.pro`
(thanks to [Britannio Jarrett](https://github.com/britannio)). Read more about the issue
[here](https://github.com/builttoroam/device_calendar/issues/99)

```
-keep class com.builttoroam.devicecalendar.** { *; }
```

See [here](https://github.com/builttoroam/device_calendar/issues/99#issuecomment-612449677)
for an example setup.

For more information, refer to the guide at
[Android Developer](https://developer.android.com/studio/build/shrink-code#keep-code)

#### AndroidX migration

Since `v.1.0`, this version has migrated to use AndroidX instead of the deprecated
Android support libraries. When using `0.10.0` and onwards for this plugin, please ensure your
application has been migrated following the guide
[here](https://developer.android.com/jetpack/androidx/migrate)

### iOS Integration

For iOS 10+ support, you'll need to modify the `Info.plist` to add the following key/value pair

```xml
<key>NSCalendarsUsageDescription</key>
<string>Access most functions for calendar viewing and editing.</string>

<key>NSContactsUsageDescription</key>
<string>Access contacts for event attendee editing.</string>
```

Note that on iOS, this is a Swift plugin. There is a known issue being tracked
[here](https://github.com/flutter/flutter/issues/16049) by the Flutter team, where adding a plugin
developed in Swift to an Objective-C project causes problems. If you run into such issues, please
look at the suggested workarounds there.