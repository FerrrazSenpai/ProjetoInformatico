import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:passageiroapp/drawer.dart';
import 'package:passageiroapp/stops.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FavoritesPage extends StatefulWidget {
      //const UmPage({Key key}) : super(key: key);
    _FavoritesPageState createState()=> _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>{
  SharedPreferences sharedPreferences;

  List _events = [];
  Color _color = Colors.teal;
  bool favorite = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _getLines();
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          elevation: 0.0,
          title: Text("Favoritos"),
          backgroundColor: Colors.black,
        ),
        body: ListView(
          children: <Widget>[
            SizedBox(
              height: 15.0,
            ),
            _listLines(),
          ],
        ),
        drawer: DrawerPage(loginStatus: true,),
      ),
    );
  }   

  Widget _listLines(){

    if(favorite){
      return Column(
        children: _events
        .map((event) {
          _functionColor(event.toString().substring(0,1));
          
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black54,
                width: 2.0
              ),
              gradient: LinearGradient(
                stops: MediaQuery.of(context).orientation == Orientation.portrait ? [0.14, 0.02] : [0.06,0.02],
                colors: [_color, Colors.grey[200]]
              ),
              borderRadius: BorderRadius.all(Radius.circular(7.0))
            ),
            margin: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 6.0),
            child: GestureDetector(
              child: ListTile(
                leading: Text(
                  event.toString().substring(0,1),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20
                  ),
                ),
                title: Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(event.toString().substring(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 19.0
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: Icon(
                        favorite ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                        color: favorite ? Colors.red[700] : Colors.black,
                      ),
                      tooltip: "Remover favorito",
                      onPressed: (){
                        _showSnackBar();
                        setState(() {
                          favorite = false;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        FontAwesomeIcons.chevronRight,
                        color: Colors.black87,
                      ),
                      tooltip: "Ver paragens",
                      onPressed: (){
                        setState(() {
                          Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => StopsPage(line: event.toString().substring(0,1),)));
                        });
                      },
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => StopsPage(line: event.toString().substring(0,1),)));
                },
              ),
            ),
          );
        })
        .toList(),
      );
    }else{
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black38
          ),
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(7.0))
        ),
        margin: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
        child: ListTile(
          leading: Icon(
            FontAwesomeIcons.heartBroken,
            color: Colors.red[900],
          ),
          title: Text('Não tem nenhuma linha favorita',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 19
            ),
          ),
        ),
      );
    }
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

  _getLines() async {

    String id;
    String nomeLinha;

    var url = 'http://'+ DotEnv().env['IP_ADDRESS']+'/api/linhas';

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      
      if(response.statusCode==200){
        var dados = jsonDecode(response.body);
        
        _events = new List.generate(1, (i) => i + 1);

        id = dados['data'][2]['id_linha'].toString();
        nomeLinha = dados['data'][2]['nome'].toString();

        setState(() {
          _events[0] = id + nomeLinha;
        });
      }
    }catch(e){
      print(e);
    }
  }

  _showSnackBar() {
    final snackBar = new SnackBar(
      content: Container(
        margin: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red[700],
                size: 30.0
              ),
            ),
            Text('Favorito removido',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: Colors.red[700]
              ),
            ),
          ],
        ),
      ),
      duration: Duration(seconds: 3),
      backgroundColor: Colors.grey[300],

    );
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }
}