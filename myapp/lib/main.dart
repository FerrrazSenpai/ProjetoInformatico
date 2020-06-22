import 'dart:async';
import 'dart:io';

import 'package:app_condutor/login.dart';
import 'package:app_condutor/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

Future main() async {
  await DotEnv().load('.env');  //Use - DotEnv().env['IP_ADDRESS'];
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    if (kReleaseMode)
      exit(1);
  };
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
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
  // Timer timer;
  // static const duration = const Duration(seconds: 1);
  // bool counter = false;

  // void handleTick() {
  //   if(!counter)
  //   setState(() {
  //     counter = true;
  //   });
  // }

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

   checkLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setBool("ativo", null);
    if(sharedPreferences.getBool("checkBox")==null || !sharedPreferences.getBool("checkBox")){
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => LoginPage()), (Route<dynamic> route) => false);
    }else if (sharedPreferences.getString("access_token") == null) {
      sharedPreferences.remove("access_token");
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => LoginPage()), (Route<dynamic> route) => false);
    }
    else{
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => DashboardPage(title: widget.title)), (Route<dynamic> route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {

    // if (timer == null) {
    //   timer = Timer.periodic(duration, (Timer t) {
    //     handleTick();
    //   });
    // }

    return Scaffold(
      backgroundColor: Colors.black,
      // body: Padding(
      //   padding: const EdgeInsets.only(top: 275),
      //   child: Center(
      //     child: Container(
      //       child: Column(
      //         children: <Widget>[
      //           Container(
      //             width: 40,
      //             height: 40,
      //             child: CircularProgressIndicator(
      //               strokeWidth: 5.0,
      //               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      //             ),
      //           ),
      //           SizedBox(
      //             height: 20
      //           ),
      //           Text("A carregar ...", 
      //           style: TextStyle(
      //             color: Colors.white,
      //             fontSize: 20,
      //             fontWeight: FontWeight.w700
      //           )
      //           ),
      //         ]
      //       )
      //     ),
      //   ),
      // ),
    );
  }
}
