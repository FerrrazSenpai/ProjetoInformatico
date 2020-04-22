import 'package:flutter/material.dart';
import 'package:app_condutor/dialogs.dart';
import 'package:app_condutor/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class DrawerPage extends StatefulWidget {
  DrawerPage({Key key, this.connected}) : super(key: key);

  final bool connected;
  @override
  MyDrawer createState() => MyDrawer();
}

class MyDrawer extends State<DrawerPage> {
  SharedPreferences sharedPreferences;
  var action;
  int code;
  
  @override
  void initState() {
    super.initState();
    getStuff();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Colors.black87,
                  Colors.grey[700],
                ]
              ),
            ),
            child: Column(
              children: <Widget>[
                Icon(
                  Icons.directions_bus,
                  color: Theme.of(context).primaryColor,
                  size: 100.0,
                ),
                Text("Aplicação Condutor",
                  style: TextStyle(
                    fontSize: 25.0,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.black,),
            title: Text('Terminar Sessão', style: TextStyle(fontSize: 17.0),),
            onTap: () async {
              action =
              await Dialogs.yesAbortDialog(context, 'Alerta', 'Pretende realmente sair?');
              onPressLogout();
            },
          ),
          Divider(),
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

  Future<SharedPreferences> getStuff() async {
    sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences;
  }

  onPressLogout() async {
    sharedPreferences = await SharedPreferences.getInstance();

    var url = "http://" + DotEnv().env['IP_ADDRESS'] + "/api/userid";
    final response = await http.get(url,headers: {
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
}