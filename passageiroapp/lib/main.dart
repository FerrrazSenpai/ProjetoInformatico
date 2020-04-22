import 'package:flutter/material.dart';
import 'login.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future main() async {
  await DotEnv().load('.env');  //Use - DotEnv().env['IP_ADDRESS'];
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primaryColor: Colors.black,
        accentColor: Colors.white,
      ),
      home: MyHomePage(title: 'App Passageiro'),
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
    Future(() {
      checkLoginStatus();
    });
    fillMarkers();
 }

  checkLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();

    if(sharedPreferences.getBool("checkBox")==null || !sharedPreferences.getBool("checkBox")){
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => LoginPage()), (Route<dynamic> route) => false);
    }else if (sharedPreferences.getString("access_token") == null) {
      sharedPreferences.remove("access_token");
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => LoginPage()), (Route<dynamic> route) => false);
    }
    else{
      //
    }
  }

  GoogleMapController mapController;
  Set<Marker> markers = Set();
  final LatLng _center = const LatLng(39.733222, -8.821096);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.exit_to_app),
              onPressed: 
                onPressLogout,
          ),
        ],
      ),*/
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          onPressed: () { },
          tooltip: 'Increment',
          child: Icon(Icons.map, color: Theme.of(context).accentColor),
          elevation: 2.0,
          backgroundColor: Theme.of(context).primaryColor,
        ),

      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(icon: Icon(Icons.menu), onPressed: onPressLogout,),
            IconButton(icon: Icon(Icons.card_giftcard), onPressed: onPressLogout,),
            SizedBox(width: 48),
            IconButton(icon: Icon(Icons.hd), onPressed: onPressLogout,),
            IconButton(icon: Icon(Icons.pages), onPressed: onPressLogout,),
          ],
        ),
        shape: CircularNotchedRectangle(), 
        color: Colors.white,
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 17.0,
        ),
        markers: Set.from(markers),
      ),
    );
  }

  onPressLogout() async {
    sharedPreferences = await SharedPreferences.getInstance();
    
      sharedPreferences.clear();
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => LoginPage()), (Route<dynamic> route) => false);
  }

  fillMarkers(){
    markers.addAll([ 
    Marker(
        markerId: MarkerId('value'),
        position: LatLng(39.733222, -8.821096),
        infoWindow: InfoWindow(title: "Paragem Biblioteca")),
    Marker(
        markerId: MarkerId('value2'),
        position: LatLng(39.735196, -8.823338),
        infoWindow: InfoWindow(title: "Paragem Rotunda")),
    ]);
  }
}
