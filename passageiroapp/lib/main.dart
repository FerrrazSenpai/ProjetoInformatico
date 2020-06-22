import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:passageiroapp/map.dart';


Future main() async {
  await DotEnv().load('.env');  //Use - DotEnv().env['IP_ADDRESS'];
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.black,
        accentColor: Colors.white,
      ),
      home: MyHomePage(title: 'Página Inicial'),
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
    _checkInitialLoginStatus();
  }

  _checkInitialLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();
    
    if(sharedPreferences.getBool("checkBox") == null || !sharedPreferences.getBool("checkBox")){
      sharedPreferences.setBool("loginStatus", false);
    }
    else if (sharedPreferences.getString("access_token") == null) {
      sharedPreferences.remove("access_token");
      sharedPreferences.setBool("loginStatus", false);
    }
    else{
      sharedPreferences.setBool("loginStatus", true);
    }

    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => MapPage(title: widget.title)), (Route<dynamic> route) => false);

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
    );
  }

}
