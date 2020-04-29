import 'package:flutter/material.dart';
import 'login.dart';
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
  
  @override
  void initState() {
    super.initState();
    //fillMarkers();
    getMarkers(); //Server Azure
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
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 17.0,
        ),
        markers: Set.from(markersAPI),
      ),
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
        for (var i=0; i<markers.length; i++){
          setState(() {
            markersAPI.add(
              Marker(
              markerId: MarkerId(markers[i]['nome']),
              position: LatLng(double.parse(markers[i]['latitude']),double.parse(markers[i]['longitude'])),
              infoWindow: InfoWindow(title: markers[i]['nome'])),
            );
          });
        }
        
      }
    }catch(e){
      print(e);
    }
  }
}
