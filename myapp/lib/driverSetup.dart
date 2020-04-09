import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:app_condutor/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SetupPage extends StatefulWidget {
  @override
  _SetupPageState createState()=> _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  SharedPreferences sharedPreferences;
  var _error = "";
  var _selectedBus;
  int _selectedLine;
  int _idCondutor;

  List bus = List();
  List linhas = List();
  
  @override
  void initState() {
    super.initState();
    getData();
  }

  Future getData() async {
    sharedPreferences = await SharedPreferences.getInstance();
    var now = new DateTime.now().toString();
    Map body = {"email":sharedPreferences.getString("email"), "data":now};
    var url = "http://" + DotEnv().env['IP_ADDRESS'] + "/api/info";
    
    try {      
      final response = await http.post(url,headers: {
        'Authorization' : "Bearer " + sharedPreferences.getString("access_token"),
      },body: body).timeout(const Duration(seconds: 6));

      print("driverSetup.dart: " + response.body); ///JUST DEBUG
      Map<String, dynamic> list = jsonDecode(response.body);

      if(list['id_linha'].length !=0){ //se o motorista tiver no seu horario
        setState(() {
          _selectedLine = int.parse(list['id_linha'][0].toString());
        });
      }

      if(list['autocarros_livres'].length !=0 && list['linhas'].length !=0){
        setState(() {
          bus = list['autocarros_livres'];
          linhas = list['linhas'];
          _idCondutor = int.parse(list['id_condutor'][0].toString());
        });
      }else{
        setState(() {
          _error = "Erro ao ir buscar os autocarros/linhas";
        });
      }

    }catch(e){
      setState(() {
        _error= e.toString();
      });
      print(e.toString());
    }
  }


  

  Widget build(BuildContext context) {
      return Scaffold(
        body: new Container(
          child: ListView(
            children: <Widget>[
              Padding(padding: EdgeInsets.only(top: 75.0)),
              costumLabel("Numero do autocarro:"),
              dropDownNrBus(),
              Padding(padding: EdgeInsets.only(top: 30.0)),
              costumLabel("Numero da linha:"),
              dropDownLinhas(),
              errorSection(),
              buttonSection(),
            ],
        )
      )
    );
  }

  Container buttonSection(){
    return Container(
      padding: EdgeInsets.only(top: 20.0),
      margin: EdgeInsets.symmetric(horizontal: 30.0),
      child: RaisedButton(
        onPressed: () {
          if(_selectedLine!=null && _selectedBus!=null ){
            print("bus: " + _selectedBus.toString()); //debug
            print("linha: " + _selectedLine.toString()); //debug
            print("condutor: " + _idCondutor.toString()); //debug

            fillHistory();

          }else{
            setState(() {
              _error="Por favor preencha ambos os campos.";
           });
          }       
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => DashboardPage(title: 'Página inicial')), (Route<dynamic> route) => false);
        },

        color: Theme.of(context).primaryColor,
        elevation: 20.0,
        padding: EdgeInsets.all(15.0),
        shape: RoundedRectangleBorder(
          borderRadius: new BorderRadius.circular(20.0),
          side: BorderSide(color: Colors.black54)
        ),
        splashColor: Colors.black54,
        colorBrightness: Brightness.light,
        child: Text("Iniciar Sessão",
          style: new TextStyle(
            color: Colors.white,
            letterSpacing: 2.0,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  DropdownButton dropDownNrBus(){
    return DropdownButton(
      items: bus.map((id) {
        return 
           DropdownMenuItem(
            value: id,
            child: Text(id.toString()),
          );
        }
      ).toList(),
             
      onChanged: (value) {
        setState(() {
          _selectedBus = value;
        });
      },
          
      hint: Text('Select Item'),
      value: _selectedBus,
    );
  }

  Container costumLabel(String text){
    return Container(
      child: Text(text, 
        style: TextStyle(
          fontSize: 19.0,
          fontWeight: FontWeight.bold)),
    );

  }

  DropdownButton dropDownLinhas(){
    return DropdownButton<int>(
      items: linhas.map((id) {
        return 
           DropdownMenuItem<int>(
            value: id,
            child: Text(id.toString()),
          );
        }
      ).toList(),
             
      onChanged: (value) {
        setState(() {
          _selectedLine = value;
        });
      },
          
      hint: Text('Select Item'),
      value: _selectedLine,
    );
  }

  Container errorSection(){
    return Container(
      padding: EdgeInsets.only(left: 70.0, top: 12.0),
      child: _error == "" ? Container(margin: EdgeInsets.only(top: 20.0),) :
      Row(
        children: <Widget>[
          Icon(
            Icons.error_outline,
            color: Colors.red[700],
            size: 20.0,
          ),
          Text('  $_error', 
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 15.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  fillHistory() async {
    var data = new DateTime.now().toString();
    Map body = {
      "id_condutor": _idCondutor.toString(),
      "id_autocarro":_selectedBus.toString(),
      "id_linha": _selectedLine.toString(),
      "time": data
    };

    var url = "http://" + DotEnv().env['IP_ADDRESS'] + "/api/updateinfo";
    
    try {      
      final response = await http.post(url,headers: {
        'Authorization' : "Bearer " + sharedPreferences.getString("access_token"),
      },body: body).timeout(const Duration(seconds: 6));

      if(response.statusCode == 200) {

        sharedPreferences = await SharedPreferences.getInstance();
        sharedPreferences.setInt('id_condutor', _idCondutor);
        sharedPreferences.setInt('id_linha', _selectedLine);
        sharedPreferences.setInt('id_autocarro', _selectedBus);

      }else{
        setState(() {
          print(response.body);
          _error = response.body;
        });
      }

    }catch(e){
      print(e.toString());
      setState(() {
        _error=e.toString();
      });
    }
  }

}
