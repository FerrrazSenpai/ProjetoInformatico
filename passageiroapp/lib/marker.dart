import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomMarker{
  String pinPath;
  LatLng location;
  String locationName;
  Color labelColor;
  List<dynamic> linhas;

  CustomMarker({this.pinPath, this.location, this.locationName, this.labelColor, this.linhas});


}
