import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:personal_app/settings.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';

const platform = const MethodChannel("com.flutter.epic/epic");

SharedPreferences prefs;
Telephony telephony = Telephony.instance;
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    new FlutterLocalNotificationsPlugin();

@pragma("vm:entry-point")
widget() async {
  WidgetsFlutterBinding.ensureInitialized();
  await checkSharedPrefs();
  platform.setMethodCallHandler((call) async {
    if (call.method == "kotlin") {
      asyncNotification();
    }
  });
}

intitializeApp() async {
  await checkSharedPrefs();
  if (!prefs.containsKey("good")) {
    Settings settings = new Settings();
    prefs.setBool("whatsapp", true);
    prefs.setBool("sms", true);
    prefs.setBool("randomEmojis", true);
    prefs.setString("numEmoji", "5");
    prefs.setString("number", "919991873735");
    prefs.setStringList("good", settings.getGoodList());
    prefs.setStringList("morning", settings.getMorningList());
    prefs.setStringList("nickname", settings.getNicknamesList());
    prefs.setStringList("emoji", settings.getEmojiList());
  }

  await telephony.requestPhoneAndSmsPermissions;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await checkSharedPrefs();

  final NotificationAppLaunchDetails notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    String text = generateMessage();
    if (prefs.getBool("whatsapp")) {
      await platform
          .invokeMethod("notifyKotlin", {"text": text, "number": prefs.getString("number")});
    }

    if (prefs.getBool("sms")) {
      String text = generateMessage();
      String number = prefs.getString("number").substring(2, 12);
      await platform.invokeMethod("sendSms", {"text": text, "number": number});
    }
  }

  platform.invokeMethod("setAlarm", {"hour": "6", "minutes": "00"});
  await intitializeApp();
  runApp(App());
}

class App extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _App();
}

class _App extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sample App',
      theme: ThemeData(primaryColor: Colors.deepPurple[700], accentColor: Colors.deepPurple[700]),
      home: SetupLists(),
    );
  }
}

class SetupLists extends StatefulWidget {
  @override
  _SetupListsState createState() => _SetupListsState();
}

class _SetupListsState extends State<SetupLists> {
  int navBarIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget lv;
    Text appTitle = Text("Maintainer");

    if (navBarIndex == 0) {
      appTitle = Text("Maintainer");
      lv = ListView(children: [
        makeList("good", context),
        makeList("morning", context),
        makeList("nickname", context),
        makeList("emoji", context),
      ]);
    } else {
      appTitle = Text("Settings");
      lv = SettingsList(
        sections: [
          SettingsSection(
              title: "Message Settings",
              titlePadding: EdgeInsets.fromLTRB(12, 12, 12, 12),
              tiles: [
                SettingsTile(
                  title: "Phone Number",
                  subtitle: prefs.getString("number").substring(2, 12),
                  leading: Icon(Icons.local_phone_rounded),
                  onPressed: (BuildContext context) {
                    var alert = AlertDialog(
                        title: Text("Phone Number"),
                        content: TextField(
                            keyboardType: TextInputType.number,
                            onSubmitted: (value) {
                              prefs.setString("number", "91$value");
                              setState(() {});
                              Navigator.pop(context);
                            }));
                    showDialog(
                        context: context,
                        builder: (context) {
                          return alert;
                        });
                  },
                ),
                SettingsTile(
                  title: "Max emojis",
                  subtitle: prefs.getString("numEmoji"),
                  leading: Icon(Icons.emoji_emotions_outlined),
                  onPressed: (BuildContext context) {
                    var alert = AlertDialog(
                        title: Text("Number of emojis"),
                        content: TextField(
                            keyboardType: TextInputType.number,
                            onSubmitted: (value) {
                              prefs.setString("numEmoji", value);
                              setState(() {});
                              Navigator.pop(context);
                            }));
                    showDialog(
                        context: context,
                        builder: (context) {
                          return alert;
                        });
                  },
                ),
                SettingsTile.switchTile(
                  title: "Random number of emojis",
                  leading: Icon(Icons.shuffle_rounded),
                  subtitle: "Random emojis less than max",
                  switchValue: prefs.getBool("randomEmojis"),
                  onToggle: (bool value) {
                    prefs.setBool("randomEmojis", value);
                    setState(() {});
                  },
                )
              ]),
          SettingsSection(
              title: "Integration",
              titlePadding: EdgeInsets.fromLTRB(12, 12, 12, 12),
              tiles: [
                SettingsTile.switchTile(
                  title: "Whatsapp",
                  subtitle: "Message is automatically typed but not sent",
                  leading: FaIcon(FontAwesomeIcons.whatsapp),
                  switchValue: prefs.getBool("whatsapp"),
                  onToggle: (bool value) {
                    prefs.setBool("whatsapp", value);
                    setState(() {});
                  },
                  subtitleMaxLines: 2,
                ),
                SettingsTile.switchTile(
                  title: "SMS Messages",
                  subtitle: "Will be sent automatically",
                  leading: Icon(Icons.sms_outlined),
                  switchValue: prefs.getBool("sms"),
                  onToggle: (bool value) {
                    prefs.setBool("sms", value);
                    setState(() {});
                  },
                ),
                SettingsTile(
                    title: "Test Whatsapp",
                    leading: Icon(Icons.notifications_none_rounded),
                    onPressed: (BuildContext context) {
                      platform.invokeMethod("notifyKotlin",
                          {"text": generateMessage(), "number": prefs.getString("number")});
                    }),
                SettingsTile(
                    title: "Test SMS",
                    leading: Icon(Icons.notifications_none_rounded),
                    onPressed: (BuildContext context) {
                      String text = generateMessage();
                      String number = prefs.getString("number").substring(2, 12);
                      // Telephony telephony = Telephony.instance;
                      // telephony.sendSms(
                      //     to: prefs.getString("number").substring(2, 12), message: text);
                      platform.invokeMethod("sendSms", {"text": text, "number": number});
                    })
              ])
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: appTitle,
      ),
      body: Builder(builder: (BuildContext context) {
        return lv;
      }),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings')
        ],
        currentIndex: navBarIndex,
        selectedIconTheme: IconThemeData(color: Colors.yellow[600]),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (int index) {
          setState(() {
            navBarIndex = index;
          });
        },
      ),
    );
  }

  makeList(String key, BuildContext context) {
    List<Widget> c = [];
    List<String> list = prefs.getStringList(key);
    String text = "${key[0].toUpperCase()}${key.substring(1)}";
    if (key == "good" || key == "morning") {
      text = "$text Words";
    } else {
      text = "${text}s";
    }

    for (var i in list) {
      c.add(
        GestureDetector(
            onDoubleTap: () {
              removePrefs(key, i);
              setState(() {});
            },
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.grey[300], borderRadius: new BorderRadius.circular(20)),
              padding: EdgeInsets.fromLTRB(12, 6, 12, 6),
              margin: EdgeInsets.fromLTRB(0, 0, 12, 12),
              child: Text(
                i.toString(),
                style: TextStyle(fontSize: 14),
              ),
            )),
      );
    }

    c.add(InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.grey[300],
        onTap: () {
          var alert = AlertDialog(
              title: Text("Add new $text word"),
              content: TextField(
                  decoration: InputDecoration(labelText: "New Word"),
                  onSubmitted: (value) {
                    updatePrefs(key, value);
                    setState(() {});
                    Navigator.pop(context);
                  }));
          showDialog(
              context: context,
              builder: (context) {
                return alert;
              });
        },
        child:
            Padding(padding: EdgeInsets.fromLTRB(6, 2, 6, 2), child: Icon(Icons.add, size: 24))));

    return Container(
        margin: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple[700]),
            ),
            SizedBox(height: 10),
            SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.start,
              direction: Axis.horizontal,
              children: c.toList(),
            ),
            Divider(),
          ],
        ));
  }

  void removePrefs(String key, String i) async {
    await checkSharedPrefs();
    List<String> list = prefs.getStringList(key);
    list.remove(i);
    prefs.setStringList(key, list);
  }

  void updatePrefs(String key, String i) async {
    await checkSharedPrefs();
    List<String> list = prefs.getStringList(key);
    list.add(i);
    prefs.setStringList(key, list);
  }
}

// Prepares the notification to send it
Future<void> asyncNotification() async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'default_notification_channel_id', 'Reminder notifications', 'Reminds to do things',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('spring_board'),
      playSound: true,
      channelShowBadge: true);

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('chat_bubble');

  InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
    String text = generateMessage();
    await platform
        .invokeMethod("notifyKotlin", {"text": text, "number": prefs.getString("number")});
  });

  await flutterLocalNotificationsPlugin.show(
      0, 'Cooper Bot', 'Send Good Morning!', platformChannelSpecifics);
}

//Generates the message
String generateMessage() {
  String message = "${(prefs.getStringList("good")..shuffle()).first} "
      "${(prefs.getStringList("morning")..shuffle()).first} "
      "${(prefs.getStringList("nickname")..shuffle()).first} ";

  int numEmojis = int.parse(prefs.getString("numEmoji"));
  if (prefs.getBool("randomEmojis")) {
    Random r = new Random();
    numEmojis = max(r.nextInt(numEmojis), 1);
  }

  for (int i = 0; i < numEmojis; i++) {
    message += (prefs.getStringList("emoji")..shuffle()).first;
  }

  return message;
}

checkSharedPrefs() async {
  if (prefs == null) prefs = await SharedPreferences.getInstance();
}
