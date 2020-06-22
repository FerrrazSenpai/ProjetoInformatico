import 'package:flutter/material.dart';
import 'package:passageiroapp/drawer.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:passageiroapp/connectivity.dart';
import 'dart:convert';


class MyMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.black,
        accentColor: Colors.white,
      ),
      home: MapPage(title: 'App Passageiro'),
    );
  }
}

class MapPage extends StatefulWidget {
  MapPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  SharedPreferences sharedPreferences;
  
  BitmapDescriptor _sourceIcon;
  double _markerToastPosition = -200;
  bool _loginStatus = false;

  void _setSourceIcon() async {
    _sourceIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5), 'assets/icon_bus.png');
  }
  
  @override
  void initState() {
    super.initState();
    //fillMarkers();
    _setSourceIcon();
    _getMarkers(); //Server testes
  }

  String timeRecord="Clique na linha para obter a previsão";
  GoogleMapController mapController;
  Set<Marker> markers = Set();
  Set<Marker> markersAPI = Set();
  List linhasParagem = List();
  var _selectedParagemID;
  final LatLng _center = const LatLng(39.733222, -8.821096);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    
    _checkLoginStatus();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ConnectivityPage(
        widget: Stack(
          children: <Widget>[
            _mapWidget(),
            AnimatedPositioned(
            bottom: _markerToastPosition,
            right: 0,
            left: 0,
            duration: Duration(milliseconds: 200),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                //margin: EdgeInsets.all(20),
                margin: EdgeInsets.symmetric(vertical: 25, horizontal:10),
                height: 100,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(32)),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        blurRadius: 50,
                        offset: Offset.zero,
                        color: Colors.grey.withOpacity(0.50),
                      )
                    ]),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _buildLocationInfo(),
                    //_buildMarkerType(),
                  ],
                ),
              ),
            ),
          )
          ],
        )
      ),
      drawer: DrawerPage(loginStatus: _loginStatus,),
    );
  }

  _getMarkers() async {
    final String url = 'http://'+ DotEnv().env['IP_ADDRESS']+'/api/linhasParagens';
    try {      
      final response = await http.get(url).timeout(const Duration(seconds: 7));
      print("status code: " + response.statusCode.toString() );
      if(response.statusCode==200){
        var markers =jsonDecode(response.body);
        for (var i=0; i<markers.length; i++){
          var auxlinhas = markers[i]['linhas'];

          setState(() {
            markersAPI.add(
              Marker(
              markerId: MarkerId(markers[i]['id_paragem'].toString()),
              position: LatLng(double.parse(markers[i]['latitude']),double.parse(markers[i]['longitude'])),
              icon: _sourceIcon,
              onTap: (){
                setState(() {
                  timeRecord="Clique na linha para obter a previsão";
                  _selectedParagemID = markers[i]['id_paragem'].toString();
                  linhasParagem= auxlinhas;
                  _markerToastPosition = 0;
                });
              }),
            );
          });
        }
      }
    }catch(e){
      print(e);
    }
  }

  Widget _mapWidget() {
    return GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 17.0,
        ),
        onTap: (LatLng location) {
              setState(() {
              _markerToastPosition = -200;
              timeRecord="Clique na linha para obter a previsão";
          });
        },
        markers: Set.from(markersAPI),
      );
  }


  Widget _buildLocationInfo() {
    List<Widget> widgets = [];
    
    for(var linha in linhasParagem){
      widgets.add(Padding(
        padding: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
        child: Row(
           children: <Widget>[
          ButtonTheme(
              minWidth: 110,
              height: 30.0,
              child: RaisedButton(
              onPressed: ()=> getTime(linha['id_linha'].toString(), _selectedParagemID),
              color: Colors.red,
              padding: EdgeInsets.all(2.0),
              shape: StadiumBorder(),
              
              child: Row(
                children: [ Text("Linha "+linha['id_linha'].toString())],
              )
            )),
           ])
       )
      );
    }
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(left: 20,right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          
          children: <Widget>[
            SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ...widgets
              ]
            )),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget> [
               Text(timeRecord),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerType() { 
    return Padding(
      padding: EdgeInsets.all(15),
      child: Image.asset('assets/icon_bus.png',width: 42,height: 50),
    );
  }

  getTime(String linha, String paragemID) async {
    //final String url = 'http://'+ DotEnv().env['IP_ADDRESS']+'/api/usedid';
    print("paragemID: " + paragemID);
    try {      
     // final response = await http.get(url).timeout(const Duration(seconds: 7));
     // print("status code: " + response.statusCode.toString() );
      setState(() {
        timeRecord = "Tempo até chegar: " + linha + " min.";
      });
    }
    catch(e){
      print(e);
    }
  }

  _checkLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();

    setState(() {
      if(sharedPreferences.getBool("loginStatus") == null || !sharedPreferences.getBool("loginStatus")){
        _loginStatus = false;
      }else{
        _loginStatus = true;
      }
    });
  }
  
}
