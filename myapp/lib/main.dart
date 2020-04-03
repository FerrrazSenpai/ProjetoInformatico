import 'dart:async';
import 'dart:io';

import 'package:app_condutor/login.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:connectivity/connectivity.dart';
import 'package:date_format/date_format.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(
        title: 'Flutter Demo Home Page',
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
  final String url = 'http://192.168.1.69:8000/api/location';

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
        actions: <Widget>[
          FlatButton(
            onPressed: () {
              sharedPreferences.clear();
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => LoginPage()), (Route<dynamic> route) => false);
            },
            child: Text("Log Out", style: TextStyle(color: Colors.white)),
          ),
        ],
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
                      color: connected ? null : Color(0xFFFF0000),
                      child: connected ? null :
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text("The device is disconnected", style: TextStyle(color: Colors.white),),
                          SizedBox(width: 8.0,),
                          SizedBox(width: 12.0, height: 12.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                        });
                      });
                      _postLocation();
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
        await http.post(
          url,
          headers: {
            'Accept' : 'application/json',
            'Authorization' : sharedPreferences.getString("access_token"),
          },
          body: body,
        );
    print(response.body);

    return response.body;
  }
}
