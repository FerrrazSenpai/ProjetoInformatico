import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:connectivity/connectivity.dart';

class ConnectivityPage extends StatefulWidget {
  ConnectivityPage({Key key, this.widget}) : super(key: key);

  final Widget widget;
  @override
  Connectivity createState() => Connectivity();
}

class Connectivity extends State<ConnectivityPage> {
  bool connected;
  
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
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
          child: widget.widget,
        );
      }
    );
  }
}