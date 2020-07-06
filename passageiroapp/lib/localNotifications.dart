import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class LocalNotifications {
  FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  SharedPreferences sharedPreferences;

  LocalNotifications() {
    _initializeNotifications();
  }

  void _initializeNotifications() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final initializationSettingsAndroid =
        AndroidInitializationSettings('red_bus');
    final initializationSettingsIOS = IOSInitializationSettings();
    final initializationSettings = InitializationSettings(
      initializationSettingsAndroid,
      initializationSettingsIOS,
    );
    _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onSelectNotification: onSelectNotification,
    );
  }

  Future onSelectNotification(String payload) async {
    if (payload != null) {
      print('notification payload: ' + payload);
    }
  }

  Future<void> showDailyAtTime(
      Time time, int id, String title, String description) async {
    //notificação todos os dias a X hora
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'Favoritos channel id', 'Favoritos', 'Notificações sobre Favoritos',
        importance: Importance.Max,
        priority: Priority.High,
        ticker: "notification ticker");
    final iOSPlatformChannelSpecifics = IOSNotificationDetails();
    final platformChannelSpecifics = NotificationDetails(
      androidPlatformChannelSpecifics,
      iOSPlatformChannelSpecifics,
    );
    await _flutterLocalNotificationsPlugin.showDailyAtTime(
      id,
      title,
      description,
      time,
      platformChannelSpecifics,
    );
  }

  Future<void> show(int id, String title, String description) async {
    // notificação imediata
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'Favoritos channel id', 'Favoritos', 'Notificações sobre Favoritos',
        importance: Importance.Max,
        priority: Priority.High,
        ticker: "notification ticker");
    final iOSPlatformChannelSpecifics = IOSNotificationDetails();
    final platformChannelSpecifics = NotificationDetails(
      androidPlatformChannelSpecifics,
      iOSPlatformChannelSpecifics,
    );
    await _flutterLocalNotificationsPlugin.show(
        id, title, description, platformChannelSpecifics,
        payload: "notification payload");
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getListPendingNotifications() async {
    final listNotifications =
        await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    print("Pending notifications: \n");
    for (var notification in listNotifications) {
      print(notification.id.toString() + " : " + notification.body);
    }
    return listNotifications;
  }

  void setNotifications() async {
    this.cancelAllNotifications();
    sharedPreferences = await SharedPreferences.getInstance();

    var startId = 1;
    var url = 'http://' + DotEnv().env['IP_ADDRESS'] + '/api/favoritos';
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization':
              "Bearer " + sharedPreferences.getString("access_token")
        },
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        var dados = jsonDecode(response.body);

        for (var fav in dados) {
          url = 'http://' +
              DotEnv().env['IP_ADDRESS'] +
              '/api/horariosLinha/' +
              fav['id_linha'].toString();

          try {
            final response = await http.get(
              url,
              headers: {
                'Authorization':
                    "Bearer " + sharedPreferences.getString("access_token")
              },
            ).timeout(const Duration(seconds: 8));
            if (response.statusCode == 200) {
              var dados = jsonDecode(response.body);
              for (var hora in dados) {
                var horaInicio = hora['hora_inicio'];
                var time = Time(
                    int.parse(horaInicio.split(":")[0]),
                    int.parse(horaInicio.split(":")[1]),
                    int.parse(horaInicio.split(":")[2]));
                this.showDailyAtTime(
                    time,
                    ++startId,
                    fav['nome'],
                    "A linha " +
                        fav['id_linha'].toString() +
                        " está a começar a viagem");
              }
            }
          } catch (e) {
            print(e);
          }
        }
      } else {
        print("Status != 200");
      }
    } catch (e) {
      print(e);
    }
    print("confirmar lista de notificações: ");
    this.getListPendingNotifications();
  }
}
