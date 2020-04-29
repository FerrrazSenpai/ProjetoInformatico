import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UmPage extends StatefulWidget {
      //const UmPage({Key key}) : super(key: key);
    _UmPageState createState()=> _UmPageState();
}

class _UmPageState extends State<UmPage>{
 //Your code here
  String _text="";


  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text("Pagina teste", style: TextStyle(fontSize:25.0)),
            new RaisedButton(
                child: new Text("Press me!", style: new TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 20.0)),
                color: Colors.red,
                onPressed: (){
                  setState(() {
                    _text="Ola!";
                  });
                },
              ),
            new Text(_text, style: TextStyle(fontSize:25.0))
          ],
        ),     
    ));
  }

  
}