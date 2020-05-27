import 'package:flutter/material.dart';
import 'package:app_condutor/dialogs.dart';
import 'package:app_condutor/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_condutor/schedule.dart';
import 'package:app_condutor/dashboard.dart';
import 'package:app_condutor/driverSetup.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DrawerPage extends StatefulWidget {
  DrawerPage({Key key, this.page}) : super(key: key);

  final String page;
  
  @override
  MyDrawer createState() => MyDrawer();
}

class MyDrawer extends State<DrawerPage> {
  SharedPreferences sharedPreferences;
  var action;
  int code;
  String nome;
  
  String linha;
  Color _color;
  
  @override
  void initState() {
    super.initState();
    _getData();
    _functionColor(linha);
  }

  @override
  Widget build(BuildContext context) {
    _functionColor(linha);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: _color
            ),
            child: Container(
              child: Column(
                children: <Widget>[
                  Icon(
                    FontAwesomeIcons.busAlt,
                    color: _color == Colors.black ? Colors.white : Colors.black,
                    size: 80.0,
                  ),
                  SizedBox(
                    height: 10.0
                  ),
                  Expanded(
                    child: Text("$nome",
                      style: TextStyle(
                        fontSize: 25.0,
                        fontWeight: FontWeight.bold,
                        color: _color == Colors.black ? Colors.white : Colors.black
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Icon(FontAwesomeIcons.home, color: Colors.black,size: 22.0,),
            title: Text('Página Inicial', style: TextStyle(fontSize: 17.0),),
            onTap: () async {
              if(widget.page == "dashboard"){
                Navigator.of(context).pop();
              }
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => DashboardPage(title: 'Página inicial')), (Route<dynamic> route) => false);
            },
          ),
          ListTile(
            leading: Icon(FontAwesomeIcons.solidClock, color: Colors.black,size: 22.0,),
            title: Text('Horário', style: TextStyle(fontSize: 17.0),),
            onTap: () async {
              if(widget.page == "schedule"){
                Navigator.of(context).pop();
              }
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => SchedulePage(color: _color,)), (Route<dynamic> route) => false);
            },
          ),
          ListTile(
            leading: Icon(FontAwesomeIcons.cog, color: Colors.black,size: 22.0,),
            title: Text('Configurar autocarro e linha', style: TextStyle(fontSize: 17.0),),
            onTap: () async {
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => SetupPage(btnText: 'Voltar à página inicial',)), (Route<dynamic> route) => false);
            },
          ),
          ListTile(
            leading: Icon(FontAwesomeIcons.signOutAlt, color: Colors.black,size: 22.0,),
            title: Text('Terminar Sessão', style: TextStyle(fontSize: 17.0),),
            onTap: () async {
              action =
              await Dialogs.yesAbortDialog(context, 'Alerta', 'Pretende realmente sair?');
              _onPressLogout();
            },
          ),
        ],
      ),
    );
  }

  void _logout() async {
    var url = "http://" + DotEnv().env['IP_ADDRESS'] + "/api/logout";
    try{
      final response = await http.post(url,headers: {
        'Authorization' : "Bearer " + sharedPreferences.getString("access_token"),
      },).timeout(const Duration(seconds: 3));

      print(response.statusCode);  
    }catch(e){
      print("Erro de conexão ao servidor, Access não eliminado");
    }
  }

  Future<SharedPreferences> _getData() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      nome = sharedPreferences.getString("nome");
      linha = sharedPreferences.getString("id_linha");
    });
    return sharedPreferences;
  }

  _onPressLogout() async {
    sharedPreferences = await SharedPreferences.getInstance();

    var url = "http://" + DotEnv().env['IP_ADDRESS'] + "/api/userid";
    /* final response =  */await http.get(url,headers: {
        'Authorization' : "Bearer " + sharedPreferences.getString("access_token"),
    },).timeout(const Duration(seconds: 6));

    /* if (action == DialogAction.cancel) {
      Navigator.of(context).pop();
    } else if(action == DialogAction.confirm && response.statusCode == 200){
      _logout();
      sharedPreferences.clear();
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => LoginPage()), (Route<dynamic> route) => false);
    }else{
      Navigator.of(context).pop();
    } */

    if (action == DialogAction.confirm) {
      _logout();
      sharedPreferences.clear();
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => LoginPage()), (Route<dynamic> route) => false);
    }
  }

  _functionColor(var expression){

    if(expression.toString().substring(1) == " "){
      expression = expression.toString().substring(0,1);
    }

    switch (expression) {
      case '1':
        _color = Colors.red[700];
      break;
      case '2':
        _color = Colors.lightGreen;
      break;
      case '3':
        _color = Colors.lightBlue;
      break;
      case '4':
        _color = Colors.blue[800];
      break;
      case '5':
        _color = Colors.green[800];
      break;
      case '6':
        _color = Colors.pink[300];
      break;
      case '7':
        _color = Colors.yellow[600];
      break;
      case '8':
        _color = Colors.orange[700];
      break;
      case '9':
        _color = Colors.black;
      break;
      default:
        _color = Colors.teal;
      break;
    }
  }
}