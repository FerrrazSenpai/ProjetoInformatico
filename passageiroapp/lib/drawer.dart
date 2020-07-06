import 'package:flutter/material.dart';
import 'package:passageiroapp/register.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:passageiroapp/dialogs.dart';
import 'package:passageiroapp/login.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:passageiroapp/map.dart';
import 'package:passageiroapp/lines.dart';
import 'package:passageiroapp/favorites.dart';

class DrawerPage extends StatefulWidget {
  DrawerPage({Key key, this.loginStatus}) : super(key: key);

  final bool loginStatus;

  @override
  MyDrawer createState() => MyDrawer();
}

class MyDrawer extends State<DrawerPage> {
  SharedPreferences sharedPreferences;
  var action;
  String nome;

  Color _color;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loginStatus) {
      return Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: _color),
              child: Container(
                child: Column(
                  children: <Widget>[
                    Icon(
                      FontAwesomeIcons.busAlt,
                      color:
                          _color == Colors.black ? Colors.white : Colors.black,
                      size: 85.0,
                    ),
                    SizedBox(height: 15.0),
                    Expanded(
                      child: Text(
                        "$nome",
                        style: TextStyle(
                            fontSize: 25.0,
                            fontWeight: FontWeight.bold,
                            color: _color == Colors.black
                                ? Colors.white
                                : Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                FontAwesomeIcons.home,
                color: Colors.black,
                size: 22.0,
              ),
              title: Text(
                'Página Inicial',
                style: TextStyle(fontSize: 17.0),
              ),
              onTap: () async {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (BuildContext context) => MapPage(
                              title: "Página inicial",
                            )),
                    (Route<dynamic> route) => false);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.linear_scale,
                color: Colors.black,
                size: 22.0,
              ),
              title: Text(
                'Linhas',
                style: TextStyle(fontSize: 17.0),
              ),
              onTap: () async {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (BuildContext context) => LinesPage()),
                    (Route<dynamic> route) => false);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.favorite,
                color: Colors.black,
                size: 22.0,
              ),
              title: Text(
                'Favoritos',
                style: TextStyle(fontSize: 17.0),
              ),
              onTap: () async {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (BuildContext context) => FavoritesPage()),
                    (Route<dynamic> route) => false);
              },
            ),
            ListTile(
              leading: Icon(
                FontAwesomeIcons.signOutAlt,
                color: Colors.black,
                size: 22.0,
              ),
              title: Text(
                'Terminar Sessão',
                style: TextStyle(fontSize: 17.0),
              ),
              onTap: () async {
                action = await Dialogs.yesAbortDialog(
                    context, 'Alerta', 'Pretende realmente terminar sessão?');
                _onPressLogout();
              },
            ),
          ],
        ),
      );
    } else {
      return Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: _color),
              child: Container(
                child: Column(
                  children: <Widget>[
                    Icon(
                      FontAwesomeIcons.busAlt,
                      color:
                          _color == Colors.black ? Colors.white : Colors.black,
                      size: 100.0,
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                FontAwesomeIcons.home,
                color: Colors.black,
                size: 22.0,
              ),
              title: Text(
                'Página Inicial',
                style: TextStyle(fontSize: 17.0),
              ),
              onTap: () async {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (BuildContext context) => MapPage(
                              title: "Página inicial",
                            )),
                    (Route<dynamic> route) => false);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.linear_scale,
                color: Colors.black,
                size: 22.0,
              ),
              title: Text(
                'Linhas',
                style: TextStyle(fontSize: 17.0),
              ),
              onTap: () async {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (BuildContext context) => LinesPage()),
                    (Route<dynamic> route) => false);
              },
            ),
            ListTile(
              leading: Icon(
                FontAwesomeIcons.signInAlt,
                color: Colors.black,
                size: 22.0,
              ),
              title: Text(
                'Iniciar Sessão',
                style: TextStyle(fontSize: 17.0),
              ),
              onTap: () async {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (BuildContext context) => LoginPage()),
                    (Route<dynamic> route) => false);
              },
            ),
            ListTile(
              leading: Icon(
                FontAwesomeIcons.userPlus,
                color: Colors.black,
                size: 22.0,
              ),
              title: Text(
                'Criar Conta',
                style: TextStyle(fontSize: 17.0),
              ),
              onTap: () async {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (BuildContext context) => RegisterPage()),
                    (Route<dynamic> route) => false);
              },
            ),
          ],
        ),
      );
    }
  }

  // void _logout() async {
  //   sharedPreferences = await SharedPreferences.getInstance();

  //   var url = "http://" + DotEnv().env['IP_ADDRESS'] + "/api/logout";
  //   try{
  //     final response = await http.post(url,headers: {
  //       'Authorization' : "Bearer " + sharedPreferences.getString("access_token"),
  //     },).timeout(const Duration(seconds: 3));

  //     print(response.statusCode);
  //     sharedPreferences.setBool("loginStatus", false);
  //     sharedPreferences.clear();
  //   }catch(e){
  //     print("Erro de conexão ao servidor, Access não eliminado");
  //   }
  // }

  _onPressLogout() async {
    sharedPreferences = await SharedPreferences.getInstance();

    if (action == DialogAction.confirm) {
      setState(() {
        sharedPreferences.setBool("loginStatus", false);
        sharedPreferences.remove("access_token");
        sharedPreferences.remove("email");
        sharedPreferences.remove("nome");
        sharedPreferences.remove("idCliente");
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (BuildContext context) => MapPage(
                      title: "Página inicial",
                    )),
            (Route<dynamic> route) => false);
      });
    }
  }

  Future<SharedPreferences> _getData() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      nome = sharedPreferences.getString("nome");
    });
    return sharedPreferences;
  }
}
