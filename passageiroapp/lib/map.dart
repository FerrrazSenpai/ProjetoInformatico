import 'package:flutter/material.dart';
import 'login.dart';
import 'marker.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';


class MapPage extends StatefulWidget {
  MapPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  SharedPreferences sharedPreferences;
  
  BitmapDescriptor _sourceIcon;
  CustomMarker _markerInfo;
  double _markerToastPosition = -200;
  CustomMarker _currentPinData = CustomMarker(
      pinPath: 'assets/icon_bus.png',
      location: LatLng(0, 0),
      locationName: '',
      labelColor: Colors.grey,
      linhas: List());


  void _setSourceIcon() async {
    _sourceIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5), 'assets/icon_bus.png');
  }
  @override
  void initState() {
    super.initState();
    //fillMarkers();
    _setSourceIcon();
    getMarkers(); //Server testes
 }

  GoogleMapController mapController;
  Set<Marker> markers = Set();
  Set<Marker> markersAPI = Set();

  final LatLng _center = const LatLng(39.733222, -8.821096);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
              margin: EdgeInsets.all(20),
              height: 100,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      blurRadius: 20,
                      offset: Offset.zero,
                      color: Colors.grey.withOpacity(0.5),
                    )
                  ]),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _buildLocationInfo(),
                  _buildMarkerType(),
                ],
              ),
            ),
          ),
        )
        ],
      )
    );
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

  getMarkers() async {
    final String url = 'http://'+ DotEnv().env['IP_ADDRESS']+'/api/markers';
    try {      
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      print("status code: " + response.statusCode.toString() );
      if(response.statusCode==200){
        var markers =jsonDecode(response.body);
        print(markers[1]);
        print(markers);
        for (var i=0; i<markers.length; i++){
          var auxlinhas = markers[i]['linhas'];
          String linhas= "";

          /*for(final linha in auxlinhas){
            print(linha['id_linha']);
            linhas+="Linha " + linha['id_linha'].toString() + "\n";
            //print(guardaLinhas);
          }
          print(linhas);*/

          setState(() {
            markersAPI.add(
              Marker(
              markerId: MarkerId(markers[i]['id_paragem'].toString()),
              position: LatLng(double.parse(markers[i]['latitude']),double.parse(markers[i]['longitude'])),
              icon: _sourceIcon,
              onTap: (){
                setState(() {
                 // _currentPinData = _markerInfo;
                  _currentPinData.pinPath= 'assets/icon_bus.png';
                  _currentPinData.locationName= "My Location";
                  _currentPinData.location= LatLng(39.733222, -8.821096);
                  _currentPinData.linhas= auxlinhas;

                  _markerToastPosition = 0;
                });
                
              }),
            );
           /* _markerInfo = CustomMarker(
              pinPath: 'assets/icon_bus.png',
              locationName: "My Location",
              location: LatLng(39.733222, -8.821096),
              labelColor: Colors.blue,
              linhas: auxlinhas);*/
          }
          );
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
          });
        },
        markers: Set.from(markersAPI),
      );
  }


  Widget _buildLocationInfo() {
    List<Widget> widgets = [];
    for(var linha in _currentPinData.linhas){
      widgets.add(Padding(
        padding: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
        child: Row(
           children: <Widget>[
          ButtonTheme(
              minWidth: 110,
              height: 30.0,
              child: RaisedButton(
              onPressed: () => {},
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
        margin: EdgeInsets.only(left: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                ...widgets
              ]
            //Text(
            //  _currentPinData.locationName,
            //),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget> [
               Text("clique para obter a previsão de tempo",),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerType() {
    return Padding(
      padding: EdgeInsets.all(15),
      child: Image.asset(_currentPinData.pinPath,width: 42,height: 50),
    );
  }
}
