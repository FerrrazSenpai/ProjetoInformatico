import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:passageiroapp/drawer.dart';
import 'package:passageiroapp/stops.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:passageiroapp/connectivity.dart';

class LinesPage extends StatefulWidget {
  _LinesPageState createState() => _LinesPageState();
}

class _LinesPageState extends State<LinesPage> {
  SharedPreferences sharedPreferences;

  List _events = null;
  Color _color = Colors.teal;
  bool _loginStatus = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _getLines();
  }

  @override
  Widget build(BuildContext context) {
    _checkLoginStatus();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 0.0,
        title: Text("Linhas"),
        backgroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        child: Container(
          child: ConnectivityPage(
            widget: Scrollbar(
              child: ListView(
                children: <Widget>[
                  SizedBox(
                    height: 25.0,
                  ),
                  _listLines(),
                ],
              ),
            ),
          ),
        ),
        onRefresh: _handleRefresh,
        color: Colors.grey[900],
      ),
      drawer: DrawerPage(
        loginStatus: _loginStatus,
      ),
    );
  }

  Widget _listLines() {
    if (_events == null) {
      return Column(
        children: <Widget>[
          SizedBox(
            height: 15.0,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(
                strokeWidth: 5.0,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            ),
          ),
        ],
      );
    } else if (_events.length != 0) {
      return Column(
        children: _events.map((event) {
          int tamanho = event.toString().length;
          _functionColor(event.toString().substring(0, 1));
          return AnimatedContainer(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.black54, width: 2.0),
                gradient: LinearGradient(
                    stops: MediaQuery.of(context).orientation ==
                            Orientation.portrait
                        ? [0.14, 0.02]
                        : [0.06, 0.02],
                    colors: [_color, Colors.grey[200]]),
                borderRadius: BorderRadius.all(Radius.circular(7.0))),
            margin: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 6.0),
            child: GestureDetector(
              onDoubleTap: () {
                _addFavorite(event.toString().substring(0, 1));
                _events.replaceRange(
                    _events.indexOf(event.toString()),
                    _events.indexOf(event.toString()) + 1,
                    [event.substring(0, tamanho - 1) + "1"]);
                setState(() {
                  _showSnackBar(false);
                });
              },
              child: ListTile(
                leading: Text(
                  event.toString().substring(0, 1),
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
                title: Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        event.toString().substring(1, tamanho - 1),
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 19.0),
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _loginStatus
                        ? IconButton(
                            icon: Icon(
                              event.toString().substring(tamanho - 1) == "1"
                                  ? FontAwesomeIcons.solidHeart
                                  : FontAwesomeIcons.heart,
                              color:
                                  event.toString().substring(tamanho - 1) == "1"
                                      ? Colors.red[700]
                                      : Colors.black,
                            ),
                            tooltip:
                                event.toString().substring(tamanho - 1) == "1"
                                    ? "Remover favorito"
                                    : "Adicionar favorito",
                            onPressed: () {
                              setState(() {
                                if (event
                                        .toString()
                                        .substring(event.length - 1) ==
                                    "1") {
                                  _removeFavorite(
                                      event.toString().substring(0, 1));
                                  _events.replaceRange(
                                      _events.indexOf(event.toString()),
                                      _events.indexOf(event.toString()) + 1,
                                      [event.substring(0, tamanho - 1) + "0"]);
                                  setState(() {
                                    _showSnackBar(true);
                                  });
                                } else {
                                  _addFavorite(
                                      event.toString().substring(0, 1));
                                  _events.replaceRange(
                                      _events.indexOf(event.toString()),
                                      _events.indexOf(event.toString()) + 1,
                                      [event.substring(0, tamanho - 1) + "1"]);
                                  setState(() {
                                    _showSnackBar(false);
                                  });
                                }
                              });
                            },
                          )
                        : SizedBox(),
                    IconButton(
                      icon: Icon(
                        FontAwesomeIcons.chevronRight,
                        color: Colors.black87,
                      ),
                      tooltip: "Ver paragens",
                      onPressed: () {
                        setState(() {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (BuildContext context) => StopsPage(
                                    line: event.toString().substring(0, 1),
                                  )));
                        });
                      },
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => StopsPage(
                            line: event.toString().substring(0, 1),
                          )));
                },
              ),
            ),
            duration: Duration(seconds: 3),
          );
        }).toList(),
      );
    }
  }

  _functionColor(var expression) {
    // if expression tem um numero e depois espaço tira o espaço
    // if expression não tem espaço meter espaço
    if (expression.toString().substring(1) == " ") {
      expression = expression.toString().substring(0, 1);
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

  _checkLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();

    setState(() {
      if (sharedPreferences.getBool("loginStatus") == null ||
          !sharedPreferences.getBool("loginStatus")) {
        _loginStatus = false;
      } else {
        _loginStatus = true;
      }
    });
  }

  _getLines() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String idCliente = sharedPreferences.getInt("idCliente").toString();

    String id;
    String nomeLinha;
    int _count = 0;

    List _favorites;

    var urlLinhas = 'http://' + DotEnv().env['IP_ADDRESS'] + '/api/linhas';
    var urlFavoritos =
        'http://' + DotEnv().env['IP_ADDRESS'] + '/api/favoritos';

    try {
      final responseLin = await http.get(
        urlLinhas,
        headers: {
          'Authorization':
              "Bearer " + sharedPreferences.getString("access_token")
        },
      ).timeout(const Duration(seconds: 5));

      if (responseLin.statusCode == 200) {
        var dadosLin = jsonDecode(responseLin.body);

        _events = new List.generate(
            dadosLin['data'].length, (i) => (i + 1).toString() + " ");

        if (_loginStatus) {
          final responseFav = await http.get(
            urlFavoritos,
            headers: {
              'Authorization':
                  "Bearer " + sharedPreferences.getString("access_token")
            },
          ).timeout(const Duration(seconds: 5));

          if (responseFav.statusCode == 200) {
            var dadosFav = jsonDecode(responseFav.body);

            if (dadosFav['data'] != []) {
              for (var i = 0; i < dadosFav['data'].length; i++) {
                if (dadosFav['data'][i]['id_cliente'] ==
                    sharedPreferences.getInt("idCliente")) {
                  _count++;
                }
              }

              if (_count == 0) {
                for (var i = 0; i < dadosLin['data'].length; i++) {
                  id = dadosLin['data'][i]['id_linha'].toString();
                  nomeLinha = dadosLin['data'][i]['nome'].toString();

                  _events[i] = id + nomeLinha + "0";
                }
                return;
              }

              _favorites = new List.generate(_count, (i) => i + 1);

              _count = 0;

              for (var i = 0; i < dadosFav['data'].length; i++) {
                if (dadosFav['data'][i]['id_cliente'] ==
                    sharedPreferences.getInt("idCliente")) {
                  _favorites[_count] = dadosFav['data'][i]['id_linha'];
                  _count++;
                }
              }

              _favorites.sort();

              int _count2 = 0;

              for (var i = 0; i < dadosLin['data'].length; i++) {
                id = dadosLin['data'][i]['id_linha'].toString();
                nomeLinha = dadosLin['data'][i]['nome'].toString();

                if (id == _favorites[_count2].toString()) {
                  _events[i] = id + nomeLinha + "1";
                  if (_count2 != _count - 1) {
                    _count2++;
                  }
                } else {
                  _events[i] = id + nomeLinha + "0";
                }
              }
            }
          }
        } else {
          for (var i = 0; i < dadosLin['data'].length; i++) {
            id = dadosLin['data'][i]['id_linha'].toString();
            nomeLinha = dadosLin['data'][i]['nome'].toString();

            _events[i] = id + nomeLinha + "0";
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  _showSnackBar(bool remfavorite) {
    final snackBar = new SnackBar(
      content: Container(
        margin: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Icon(
                remfavorite ? Icons.delete_outline : Icons.check_circle_outline,
                color: remfavorite ? Colors.red[700] : Colors.lightGreen[700],
                size: 30.0,
              ),
            ),
            Text(
              remfavorite ? 'Favorito removido' : 'Favorito adicionado',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: remfavorite ? Colors.red[700] : Colors.lightGreen[700],
              ),
            )
          ],
        ),
      ),
      duration: Duration(seconds: 1),
      backgroundColor: Colors.grey[300],
    );
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  void _removeFavorite(String id) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    String idCliente = sharedPreferences.getInt("idCliente").toString();
    String idFavorito;

    var urlFavoritos =
        'http://' + DotEnv().env['IP_ADDRESS'] + '/api/favoritos';

    try {
      final responseFav = await http.get(
        urlFavoritos,
        headers: {
          'Authorization':
              "Bearer " + sharedPreferences.getString("access_token")
        },
      ).timeout(const Duration(seconds: 15));

      if (responseFav.statusCode == 200) {
        var dados = jsonDecode(responseFav.body);

        for (var i = 0; i < dados['data'].length; i++) {
          if (dados['data'][i]['id_cliente'].toString() == idCliente &&
              dados['data'][i]['id_linha'].toString() == id) {
            idFavorito = dados['data'][i]['id_favorito'].toString();
          }
        }

        var urlRemoverFavorito = 'http://' +
            DotEnv().env['IP_ADDRESS'] +
            '/api/favoritos/' +
            idFavorito;

        final responseRemoveFav = await http.delete(
          urlRemoverFavorito,
          headers: {
            'Authorization':
                "Bearer " + sharedPreferences.getString("access_token")
          },
        ).timeout(const Duration(seconds: 15));
        print(responseRemoveFav.body);
        if (responseRemoveFav.statusCode == 200) {
          var dados = jsonDecode(responseRemoveFav.body);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  _addFavorite(String id) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    String idCliente = sharedPreferences.getInt("idCliente").toString();

    var url = "http://" + DotEnv().env['IP_ADDRESS'] + "/api/favoritos";

    Map body = {
      "id_cliente": idCliente,
      "id_linha": id,
    };

    try {
      final response = await http.post(
        url,
        body: body,
        headers: {
          'Authorization':
              "Bearer " + sharedPreferences.getString("access_token")
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        var dados = jsonDecode(response.body);

        print(dados);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<Null> _handleRefresh() async {
    await new Future.delayed(new Duration(seconds: 2));

    setState(() {
      _getLines();
    });

    return null;
  }
}
