import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:alarm/alarm.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

var status = "CLOSED";
bool alarmActive = false;
bool active = false; // Flag to track if the alarm is active
DateTime date = DateTime.now();
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// final alarmSettings = AlarmSettings(
//   id: 2,
//   dateTime: date,
//   assetAudioPath: 'assets/alarm.wav',
//   loopAudio: true,
//   vibrate: true,
//   volume: 0.5,
//   fadeDuration: 3.0,
//   notificationTitle: 'DOOR ALERT!!',
//   notificationBody: 'The door has opened.',
//   enableNotificationOnKill: Alarm.android,
// );

// final alarm2 = AlarmSettings(
//   id: 6,
//   dateTime: date,
//   assetAudioPath: 'assets/alarm.wav',
//   loopAudio: true,
//   vibrate: true,
//   volume: 0.5,
//   fadeDuration: 3.0,
//   notificationTitle: 'DOOR ALERT!!',
//   notificationBody: 'The door has opened.',
//   enableNotificationOnKill: Alarm.android,
// );

// void triggerAlarm() async {
//   // await Alarm.init();
//   print('alarmset');
//   showNotification();
//   // await Alarm.set(
//   //   alarmSettings: alarm2,
//   // );
//   print('triggeralarm');
//   var initializationSettingsAndroid = const AndroidInitializationSettings(
//     '@mipmap/ic_launcher',
//   );
//   var initializationSettings = InitializationSettings(
//     android: initializationSettingsAndroid,
//   );
//   await flutterLocalNotificationsPlugin.initialize(
//     initializationSettings,
//     onDidReceiveNotificationResponse:
//         (NotificationResponse notificationResponse) async {
//       if (notificationResponse.payload != null) {
//         if (notificationResponse.payload == 'dismiss_alarm_5') {
//           await dismissAlarmWithId5();
//         }
//         // if (notificationResponse.payload == 'dismiss_alarm') {
//         //   await _MainClassState.dismissAlarm();
//         // }
//       }
//     },
//   );
// }

void showNotification() async {
  print('shownotification');
  var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
    '5',
    'Alarm Channel',
    channelShowBadge: true,
    importance: Importance.max,
    priority: Priority.high,
    autoCancel: false,
    sound: RawResourceAndroidNotificationSound('alarm'),
    enableVibration: true,
    playSound: true,
    actions: <AndroidNotificationAction>[
      AndroidNotificationAction(
        'dismiss_alarm_5',
        'Dismiss Alarm',
        showsUserInterface: true,
        icon: null,
        cancelNotification: false,
      ),
    ],
  );

  var platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    5,
    'Door Alert',
    'The door has opened.',
    platformChannelSpecifics,
    payload: 'dismiss_alarm_5',
  );
}

Future<void> alarmCallback() async {
  print(DateTime.now());
  print('yes');
  final response = await http.get(
    Uri.parse(
        'https://api.thingspeak.com/channels/2472655/feeds/last.json?api_key=SRFFDTGUWK9613V6'),
  );

  if (response.statusCode == 200) {
    final jsonData = jsonDecode(response.body);
    final deviceValue = jsonData['field1'];
    double a = double.parse(deviceValue);
    print(a);

    if (a >= 40.0) {
      status = "OPEN";
      // triggerAlarm();
      showNotification();
      if (!active) {
        active = true;
      }
    } else {
      status = "CLOSED";
    }
  } else {
    status = "CLOSED";
    active = false;
    print('Failed to fetch data');
  }

  var notification =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  if (notification != null && notification.didNotificationLaunchApp) {
    await flutterLocalNotificationsPlugin.cancel(5);
    // Alarm.stop(6);
  }

  scheduleExactAlarm();
}

Future<void> dismissAlarmWithId5() async {
  // await Alarm.stop(6);
  await flutterLocalNotificationsPlugin.cancel(5);
}

void startForegroundService() async {
  FlutterForegroundTask.init(
    androidNotificationOptions:
        AndroidNotificationOptions(channelId: '33', channelName: 'android'),
    iosNotificationOptions: IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(),
  );
  print('start');
  await FlutterForegroundTask.startService(
    notificationTitle: 'Foreground Service Running',
    notificationText: 'Your alarm service is running.',
    callback: alarmCallback,
  );
}

void scheduleExactAlarm() {
  final now = DateTime.now();
  final nextAlarmTime = now.add(const Duration(seconds: 5));

  AndroidAlarmManager.oneShotAt(
    nextAlarmTime,
    2,
    alarmCallback,
    exact: true,
    wakeup: true,
    rescheduleOnReboot: true,
    allowWhileIdle: true,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.scheduleExactAlarm.request();
  await Permission.notification.request();
  await Permission.ignoreBatteryOptimizations.request();
  var initializationSettingsAndroid = const AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );
  var initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) async {
      if (notificationResponse.payload != null) {
        if (notificationResponse.payload == 'dismiss_alarm_5') {
          await dismissAlarmWithId5();
        }
        if (notificationResponse.payload == 'dismiss_alarm') {
          await _MainClassState.dismissAlarm();
        }
      }
    },
  );
  FlutterForegroundTask.init(
    androidNotificationOptions:
        AndroidNotificationOptions(channelId: '33', channelName: 'android'),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: const ForegroundTaskOptions(
      interval: 1000,
      autoRunOnBoot: true,
    ),
  );
  // await Alarm.init();
  await AndroidAlarmManager.initialize();

  runApp(
    const MaterialApp(
      title: "Security App",
      color: Colors.white,
      debugShowCheckedModeBanner: false,
      home: MainClass(),
    ),
  );

  // AndroidAlarmManager.periodic(
  //   const Duration(milliseconds: 2),
  //   2,
  //   alarmCallback,
  //   exact: true,
  //   wakeup: true,
  //   rescheduleOnReboot: true,
  //   allowWhileIdle: true,
  //   startAt: DateTime.now(),
  // );
  scheduleExactAlarm();
  startForegroundService();
}

class MainClass extends StatefulWidget {
  const MainClass({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MainClassState();
  }

  static Future<void> notificationHandler(String? payload) async {
    if (payload == 'dismiss_alarm_5') {
      await dismissAlarmWithId5();
    }
    if (payload == 'dismiss_alarm') {
      await _MainClassState.dismissAlarm();
    }
  }
}

class _MainClassState extends State<MainClass> {
  @override
  void initState() {
    super.initState();
    fetchDeviceData();
    tapFunc();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 30, bottom: 15),
      decoration: BoxDecoration(
        border: Border.all(
          width: 5,
          color: const Color.fromARGB(144, 240, 235, 235),
        ),
        image: const DecorationImage(
          image: AssetImage("Images/background.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Image.asset(
              "Images/logo.jpg",
              alignment: Alignment.topLeft,
            ),
            const SizedBox(
              height: 80,
            ),
            Text(
              "DOOR STATUS :",
              style: GoogleFonts.ptSerif(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 255, 255, 255),
                textBaseline: TextBaseline.ideographic,
                decorationColor: Colors.black,
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            safetyCheck(),
          ],
        ),
      ),
    );
  }

  Widget safetyCheck() {
    fetchDeviceData();
    if (status == "CLOSED") {
      return Column(
        children: [
          Image.asset(
            "Images/Animation4.gif",
            color: Colors.white,
          ),
          Image.asset(
            "Images/Animation.gif",
            color: const Color.fromARGB(255, 210, 207, 207),
          )
        ],
      );
    } else {
      tapFunc();
      return Column(
        children: [
          Image.asset(
            "Images/Animation3.gif",
          ),
          Image.asset(
            "Images/Animation2.gif",
          )
        ],
      );
    }
  }

  Future<void> fetchDeviceData() async {
    final response = await http.get(
      Uri.parse(
          'https://api.thingspeak.com/channels/2472655/feeds/last.json?api_key=SRFFDTGUWK9613V6'),
    );
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final deviceValue = jsonData['field1'];
      double a = double.parse(deviceValue);
      if (a >= 40.0) {
        if (!alarmActive) {
          // checkAlarm();
          // showNotificationWithDismiss();
        }
        setState(() {
          status = "OPEN";
        });
      } else {
        alarmActive = false;
        setState(() {
          status = "CLOSED";
        });
      }
    } else {
      alarmActive = false;
      print('lost');
      setState(() {
        status = "CLOSED";
      });
    }
  }

  // void checkAlarm() async {
  //   showNotificationWithDismiss();
  //   await Alarm.set(
  //     alarmSettings: alarmSettings,
  //   );
  //   alarmActive = true;
  // }

  Future<void> tapFunc() async {
    var notification =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    if (notification != null && notification.didNotificationLaunchApp) {
      await flutterLocalNotificationsPlugin.cancel(42);
      // Alarm.stop(2);
      await flutterLocalNotificationsPlugin.cancel(5);
      // Alarm.stop(6);
    }
  }

  void showNotificationWithDismiss() async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      '42',
      'Alarm Channel',
      channelShowBadge: true,
      importance: Importance.max,
      priority: Priority.high,
      autoCancel: false,
      sound: RawResourceAndroidNotificationSound('alarm'),
      enableVibration: true,
      playSound: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'dismiss_alarm',
          'Dismiss',
          showsUserInterface: true,
          icon: null,
          cancelNotification: false,
        ),
      ],
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      42,
      'Door Alert',
      'The door has opened.',
      platformChannelSpecifics,
      payload: 'dismiss_alarm',
    );
  }

  Future<void> onSelectNotification(String? payload) async {
    if (payload != null &&
        (payload == 'dismiss_alarm' || payload == 'dismiss_alarm_5')) {
      await dismissAlarm();
    }
  }

  static Future<void> dismissAlarm() async {
    // await Alarm.stop(2);
    await flutterLocalNotificationsPlugin.cancel(42);
    // await Alarm.stop(6);
    await flutterLocalNotificationsPlugin.cancel(5);
  }
}
