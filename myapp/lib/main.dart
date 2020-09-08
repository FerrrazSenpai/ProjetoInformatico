import 'dart:async';
import 'dart:io';

import 'package:app_condutor/login.dart';
import 'package:app_condutor/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

Future main() async {
  await DotEnv().load('.env'); //Use - DotEnv().env['IP_ADDRESS'];
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    if (kReleaseMode) exit(1);
  };
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.teal,
        accentColor: Colors.grey[900],
      ),
      home: new MyHomePage(
        title: 'Página inicial',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  SharedPreferences sharedPreferences;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  checkLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getBool("checkBox") == null ||
        !sharedPreferences.getBool("checkBox")) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (BuildContext context) => LoginPage()),
          (Route<dynamic> route) => false);
    } else if (sharedPreferences.getString("access_token") == null) {
      sharedPreferences.remove("access_token");
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (BuildContext context) => LoginPage()),
          (Route<dynamic> route) => false);
    } else {
      // checkLocationHistory();
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (BuildContext context) =>
                  DashboardPage(title: widget.title)),
          (Route<dynamic> route) => false);
    }
  }

  checkLocationHistory() async {
    sharedPreferences = await SharedPreferences.getInstance();

    if (sharedPreferences.getBool("ativo") == true) {
      sharedPreferences.setBool("ativo", false);
      var url = 'https://' + DotEnv().env['IP_ADDRESS'] + '/api/historicos';

      Map body = {
        "id_linha": sharedPreferences.getString("id_linha"),
        "hora_inicio": sharedPreferences.getString("horaInicio"),
        "hora_fim": sharedPreferences.getString("horaFim"),
        "data": sharedPreferences.getString("dataRota")
      };

      var response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization':
              "Bearer " + sharedPreferences.getString("access_token"),
        },
        body: body,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
    );
  }
}
