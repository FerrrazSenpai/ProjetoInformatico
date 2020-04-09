import 'dart:async';
import 'package:app_condutor/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:connectivity/connectivity.dart';
import 'package:date_format/date_format.dart';
import 'package:http/http.dart' as http;

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: new DashboardPage(
        title: 'Página inicial',
      ),
    );
      //home: new LoginPage(),
  }
}

class DashboardPage extends StatefulWidget {
  DashboardPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  SharedPreferences sharedPreferences;

  var location = new Location();

  LocationData userLocation;
  DateTime time;
  double speedkmh;
  bool connected;
  final String url = 'http://'+DotEnv().env['IP_ADDRESS']+'/api/location';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Builder(
        builder: (BuildContext context){
          return OfflineBuilder(
            connectivityBuilder: (
              BuildContext context,
              ConnectivityResult connectivity,
              Widget child
            ){
              connected = connectivity != ConnectivityResult.none;
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
                            ),
                          ),
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
                userLocation == null || !connected
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
      drawer: new DrawerPage(connected: true),
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

}
