import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StopsPage extends StatefulWidget {
  StopsPage({Key key, this.line}) : super(key: key);

  final String line;

  _StopsPageState createState()=> _StopsPageState();
}

class _StopsPageState extends State<StopsPage>{
  SharedPreferences sharedPreferences;

  List _events = [];
  Color _color = Colors.teal;
  bool favorite = true;

  @override
  void initState() {
    super.initState();
    _getStops();
    _functionColor(widget.line);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        leading: BackButton(
          
        ),
        title: Text("Paragens linha " + widget.line.toString()),
        backgroundColor: _color,
      ),
      body: ListView(
        children: <Widget>[
          SizedBox(
            height: 15.0,
          ),
          _listStops(),
        ],
      ),
    );
  }   

  Widget _listStops(){

    return Column(
      children: _events
      .map((event) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black54,
              width: 2.0
            ),
            gradient: LinearGradient(
              stops: MediaQuery.of(context).orientation == Orientation.portrait ? [0.16, 0.02] : [0.07,0.02],
              colors: [Colors.black, Colors.grey[300]],
            ),
            borderRadius: BorderRadius.all(Radius.circular(7.0))
          ),
          margin: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 6.0),
          child: ListTile(
            leading: Icon(
              Icons.directions_bus,
              color: Colors.white,
              size: 30,
            ),
            title: Row(
              children: <Widget>[
                Flexible(
                  child: Text(event.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19.0
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      })
      .toList(),
    );
  }
  
  _functionColor(var expression){

    // if expression tem um numero e depois espaço tira o espaço
    // if expression não tem espaço meter espaço
    if(expression.toString().substring(1) == " "){
      expression = expression.toString().substring(0,1);
    }

    switch (expression) {
      case '1':
        _color = Colors.lightGreen;
      break;
      case '2':
        _color = Colors.red[700];
      break;
      case '3':
        _color = Colors.lightBlue;
      break;
      case '4':
        _color = Colors.black;
      break;
      default:
        _color = Colors.teal;
      break;
    }
  }

  _getStops() async {
    sharedPreferences = await SharedPreferences.getInstance();
    String nomeParagem;

    var url = 'http://'+ DotEnv().env['IP_ADDRESS']+'/api/paragens/' + widget.line.toString();

    try {      
      final response = await http.get(url,headers: {'Authorization': "Bearer " + sharedPreferences.getString("access_token")},).timeout(const Duration(seconds: 15));
      
      if(response.statusCode==200){
        var dados = jsonDecode(response.body);

        _events = new List.generate(dados['paragens'].length, (i) => i + 1);
        for (var i=0; i<dados['paragens'].length; i++) {

          nomeParagem = dados['paragens'][i]['nome'].toString();
        
          setState(() {
            _events[i] = nomeParagem;
          });
        }
      }
    }catch(e){
      print(e);
    }
  }
}