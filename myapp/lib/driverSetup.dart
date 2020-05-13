import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:app_condutor/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class SetupPage extends StatefulWidget {
  @override
  _SetupPageState createState()=> _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  SharedPreferences sharedPreferences;
  var array;
  var _error = "";
  int _selectedBus;
  int _selectedLine;
  int _idCondutor;
  var _defaultLine=0;
  var _defaultBus=0;

  final TextEditingController __selectedLineController = new TextEditingController();
  final TextEditingController __selectedBusController = new TextEditingController();

  List bus = List();
  List linhas = List();
  
  @override
  void initState() {
    super.initState();
    getData();
  }

  Future getData() async {
    sharedPreferences = await SharedPreferences.getInstance();
    var url = "http://" + DotEnv().env['IP_ADDRESS'] + "/api/horarioCondutor/" + sharedPreferences.getString("id_condutor");
    //var url = "http://" + DotEnv().env['IP_ADDRESS'] + "/api/info";
    print(url + "Bearer " +sharedPreferences.getString("access_token"));
    try {      
      final response = await http.get(
        url,
        headers: {'Authorization': "Bearer " + sharedPreferences.getString("access_token")},
        ).timeout(const Duration(seconds: 6));
    
      if(response.body[1]=="]"){ //ou seja a resposta é só []
        print("EMPTY RESPONSE");
        setState(() {
          _error="Sem infos no server";
        });
        return; //nao ha nada para fazer nesta funcao entao
      }
      Map<String, dynamic> list = jsonDecode(response.body)[0];
      //array = jsonDecode(response.body)[0];


      //print("linha: " + array["id_linha"]);
      //print("bus: " + array["id_autocarro"]);

      if(list.containsKey('id_linha')){   //se vier linha da api
        setState(() {
          _selectedLine = int.parse(list['id_linha'].toString());
          __selectedLineController.text = _selectedLine.toString();
          _defaultLine=_selectedLine;
        });
      }

      if(list.containsKey('id_autocarro')){ 
        setState(() {
          _selectedBus = int.parse(list['id_autocarro'].toString());
          __selectedBusController.text = _selectedBus.toString();
          _defaultBus=_selectedBus;

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
              //dropDownNrBus(),
              new Container(
                  child: new TextField(
                    decoration: const InputDecoration(hintText: "Numero do autocarro"),
                    autocorrect: false,
                    controller: __selectedBusController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                        WhitelistingTextInputFormatter.digitsOnly
                    ],
                    onChanged: (String value) {
                      _selectedBus = int.parse(value);
                    },
                  ),
                ),
              Padding(padding: EdgeInsets.only(top: 30.0)),
              costumLabel("Numero da linha:"),
              //dropDownLinhas(),
              new Container(
                  child: new TextField(
                    decoration: const InputDecoration(hintText: "Linha"),
                    autocorrect: false,
                    controller: __selectedLineController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                        WhitelistingTextInputFormatter.digitsOnly
                    ],
                    onChanged: (String value) {
                      _selectedLine = int.parse(value);
                    },
                  ),
                ),
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

            if((_selectedLine !=_defaultLine) || (_selectedBus != _defaultBus)) //É preciso corrigir o que esta na bd
            {
              //fazer o post para corrigir 
              //
              //correctInfo();
              //confirmar se o pedido é com id horario ou condutor
            }
            
            sharedPreferences.setString("id_autocarro", _selectedBus.toString());
            sharedPreferences.setString("id_linha", _selectedLine.toString());

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

  correctInfo() async {
    //sharedPreferences = await SharedPreferences.getInstance();
    var url = "http://" + DotEnv().env['IP_ADDRESS'] + "/api/horario/" + sharedPreferences.getString("id_condutor");
//VER SE É ID_CONDUTOR OU ID_HORARIO

    Map body = {
      "id_autocarro" : _selectedBus,
      "id_linha" : _selectedLine,
    };

    try {      
      final response = await http.post(
        url,
        headers: {'Authorization': "Bearer " + sharedPreferences.getString("access_token")},
        body: body).timeout(const Duration(seconds: 6));
      
      print(response.statusCode);
    
    }catch(e){
      print(e);
      setState(() {
        _error=e.toString();
      });
    }
  }

}
