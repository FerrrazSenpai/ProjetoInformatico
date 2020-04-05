import 'dart:async';
import 'dart:io';
import 'dart:convert';


import 'package:app_condutor/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:connectivity/connectivity.dart';
import 'package:date_format/date_format.dart';
import 'package:http/http.dart' as http;
import 'package:app_condutor/dialogs.dart';

Future main() async {
  await DotEnv().load('.env');  //Use - DotEnv().env['IP_ADDRESS'];
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
        primaryColor: Colors.teal[500],
        accentColor: Colors.grey[900],
      ),
      home: new MyHomePage(
        title: 'Página inicial',
      ),
    );
      //home: new LoginPage(),
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

  var location = new Location();

  LocationData userLocation;
  DateTime time;
  double speedkmh;
  final String url = 'http://'+DotEnv().env['IP_ADDRESS']+'/api/location';

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  checkLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();
    if(sharedPreferences.getString("access_token") == null) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => LoginPage()), (Route<dynamic> route) => false);
    }
    print(sharedPreferences.getString("access_token"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.teal[900],
                    Colors.teal[400],
                  ]
                ),
              ),
              child: Column(
                children: <Widget>[
                  Icon(
                    Icons.directions_bus,
                    color: Theme.of(context).accentColor,
                    size: 100.0,
                  ),
                  Text("Que ganda autoBUS",
                    style: TextStyle(
                      fontSize: 25.0
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: <Widget>[
                FlatButton(
                  padding: EdgeInsets.only(right: 10.0),
                  child: ListTile(
                        leading: Icon(Icons.exit_to_app, color: Colors.black,),
                        title: Text('Terminar Sessão', 
                        style: TextStyle(fontSize: 17.0),),
                  ),
                  onPressed: () async{
                    final action =
                    await Dialogs.yesAbortDialog(context, 'Alerta', 'Pretende realmente sair?');
                    if (action == DialogAction.yes) {
                      _logout();
                      sharedPreferences.clear();
                      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => LoginPage()), (Route<dynamic> route) => false);
                    } else {
                      setState((){});
                    }
                  },
                ),
                Divider(),
              ],
            )
          ],
        ),
      ),
      body: Builder(
        builder: (BuildContext context){
          return OfflineBuilder(
            connectivityBuilder: (
              BuildContext context,
              ConnectivityResult connectivity,
              Widget child
            ){
              final bool connected = connectivity != ConnectivityResult.none;
              return Stack(
                fit: StackFit.expand,
                children: [
                  child,
                  Positioned(
                    left: 0.00,
                    right: 0.00,
                    height: 30.00,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      color: connected ? null : Colors.black,
                      child: connected ? null :
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text("The device is disconnected", style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold),),
                          SizedBox(width: 8.0,),
                          SizedBox(width: 12.0, height: 12.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red[800]),
                          ),),
                        ],
                      ),
                    ),
                  )
                ],
              );
            },
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                new Image(
                  image: new AssetImage("assets/wallpBUS.jpg"),
                  fit: BoxFit.cover,
                ),
                userLocation == null 
                ? Text("\n\n\n\n\n\nSem valores óbtidos", textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),)
                : Text("\n\n\n\n\n\n   " + userLocation.latitude.toString() + "  latitude \n   " + userLocation.longitude.toString() + "  longitude \n    " +
                speedkmh.toStringAsFixed(3)+ "  km/h \n   " + formatDate(time, [yyyy,"-",mm,"-",dd," ",HH,":",nn,":",ss]), textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),),
                Container(
                  width: 200.0,
                  padding: EdgeInsets.fromLTRB(50.0, 315.0, 50.0, 315.0),
                  child: new FlatButton(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Get Coordinates, speed and time', textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontSize: 20),),
                    color: Colors.white,
                    onPressed: (){
                      _getLocation().then((value) {
                        setState(() {
                          userLocation = value;
                          // 1m/s -> 3.6km/h  speed -> speedkmh
                          speedkmh = userLocation.speed.toDouble() * 3.600;
                          time = DateTime.fromMillisecondsSinceEpoch(userLocation.time.toInt());
                          _postLocation();
                        });
                      });
                    }
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Future<LocationData> _getLocation() async {
    LocationData currentLocation;
    try {
      currentLocation = await location.getLocation();
    } catch (e) {
      currentLocation = null;
    }
    return currentLocation;
  }

  
  Future<String> _postLocation() async {

    sharedPreferences = await SharedPreferences.getInstance();

    Map body = {
      "latitude" : userLocation.latitude.toString(),
      "longitude" : userLocation.longitude.toString(),
      "speed" : speedkmh.toStringAsFixed(3),
      "time" : formatDate(time, [yyyy,"-",mm,"-",dd," ",HH,":",nn,":",ss]),
    };

    var response = 
        await 
        http.post(
          url,
          headers: {
            'Accept' : 'application/json',
            'Authorization' : "Bearer " + sharedPreferences.getString("access_token"),
          },
          body: body,
        );
    print(response.body);
    //print(body);
    return response.body;
  }

  void _logout() async {
    var url = "http://" + DotEnv().env['IP_ADDRESS'] + "/api/logout";
    try{
      final response = await http.post(url,headers: {
        'Authorization' : "Bearer " + sharedPreferences.getString("access_token"),
      },).timeout(const Duration(seconds: 3));

      print(response.statusCode);  
    }catch(e){
      print("Erro de conexão ao servidor, Access não eliminado");
    }
  }


}
