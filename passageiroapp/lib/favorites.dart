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

  List _events = null;
  Color _color = Colors.teal;
  List _favorites;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _getFavorites();
    // _getLines();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
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
    );
  }   

  Widget _listLines(){

    if(_events == null){
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircularProgressIndicator(
            strokeWidth: 5.0,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ),
        ),
      );
    }else if(_events.length != 0){
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
                        FontAwesomeIcons.solidHeart,
                        color: Colors.red[700]
                      ),
                      tooltip: "Remover favorito",
                      onPressed: (){
                        _showSnackBar();
                        _removeFavorite(event.toString().substring(0,1));
                        setState(() {
                          _events.remove(event.toString());
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

  // _getLines() async {


  //   var url = 'http://'+ DotEnv().env['IP_ADDRESS']+'/api/linhas';

  //   try {
  //     final response = await http.get(url).timeout(const Duration(seconds: 15));
      
  //     if(response.statusCode==200){
  //       var dados = jsonDecode(response.body);
        
  //       print(_favorites);
  //       _events = new List.generate(_favorites.length, (i) => i + 1);

  //       for(var i = 0; i < _favorites.length; i++){
  //         id = _favorites[i].toString();
  //         print(id);
  //         for(var j = 0; j < dados['data'].length; j++){
  //           if(dados['data'][j]['id_linha'].toString() == id){
  //             nomeLinha = dados['data'][j]['nome'].toString();
  //             _events[i] = id + nomeLinha;
  //           }
  //         }
  //       }

  //       setState(() {
  //         print(_events);
  //       });

  //     }
  //   }catch(e){
  //     print(e);
  //   }
  // }

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

  _getFavorites() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    String _idLinha;
    String _idFavorito;
    String _idCliente;
    int _count = 0;
    int _count2 = 0;
    
    String id;
    String nomeLinha;

    var urlFavoritos = 'http://'+ DotEnv().env['IP_ADDRESS']+'/api/favoritos';
    var urlLinhas = 'http://'+ DotEnv().env['IP_ADDRESS']+'/api/linhas';

    try {
      final responseFav = await http.get(urlFavoritos).timeout(const Duration(seconds: 15));
      
      if(responseFav.statusCode==200){
        var dados = jsonDecode(responseFav.body);

        if(dados['data'] != []){
          for(var i = 0; i < dados['data'].length; i++){
            if(dados['data'][i]['id_cliente'] == sharedPreferences.getInt("idCliente")){
              _count ++;
            } 
          }

          if(_count == 0 ){
            setState(() {
              _events = [];
            });
            return;
          }

          _favorites = new List.generate(_count, (i) => i + 1);


          for(var i = 0; i < dados['data'].length; i++){
            if(dados['data'][i]['id_cliente'] == sharedPreferences.getInt("idCliente")){
              _idLinha = dados['data'][i]['id_linha'].toString();
              _idFavorito = dados['data'][i]['id_favorito'].toString();
              _idCliente = dados['data'][i]['id_cliente'].toString();

              _favorites[_count2] = _idLinha;
              _count2++;
            }
          }

          _favorites.sort();

          final responseLin = await http.get(urlLinhas).timeout(const Duration(seconds: 15));
        
          if(responseLin.statusCode==200){
            var dadosLin = jsonDecode(responseLin.body);
            
            _events = new List.generate(_favorites.length, (i) => i + 1);

            for(var i = 0; i < _favorites.length; i++){
              id = _favorites[i].toString();
              for(var j = 0; j < dadosLin['data'].length; j++){
                if(dadosLin['data'][j]['id_linha'].toString() == id){
                  nomeLinha = dadosLin['data'][j]['nome'].toString();
                  _events[i] = id + nomeLinha;
                }
              }
            }

            setState(() {
            });

          }

        }
      }

    }catch(e){
      print(e);
    }
  }

  void _removeFavorite(String id) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    String idCliente = sharedPreferences.getInt("idCliente").toString();
    int idFavorito;
    
    var urlFavoritos = 'http://'+ DotEnv().env['IP_ADDRESS']+'/api/favoritos';

    try {
      final responseFav = await http.get(urlFavoritos).timeout(const Duration(seconds: 15));
      
      if(responseFav.statusCode==200){
        var dados = jsonDecode(responseFav.body);

        for(var i = 0; i < dados['data'].length; i++){
          if(dados['data'][i]['id_cliente'].toString() == idCliente && dados['data'][i]['id_linha'].toString() == id) {
            idFavorito = dados['data'][i]['id_favorito'];
          }
        }

        var urlRemoverFavorito = 'http://'+ DotEnv().env['IP_ADDRESS']+'/api/favoritos/' + idFavorito.toString();

        final responseRemoveFav = await http.delete(urlRemoverFavorito).timeout(const Duration(seconds: 15));

        if(responseRemoveFav.statusCode == 200){
          var dados = jsonDecode(responseRemoveFav.body);

          print(dados);
        }

      }

    }catch(e){
      print(e);
    }

  }
}