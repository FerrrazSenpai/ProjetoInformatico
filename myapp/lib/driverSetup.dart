import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:app_condutor/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:app_condutor/connectivity.dart';

class SetupPage extends StatefulWidget {
  SetupPage({Key key, this.btnText}) : super(key: key);

  final String btnText;
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
  bool checkBoxValue = false;

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
          _error="Sem informação no servidor";
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
        _error= "Houve um problema ao estabelecer conexão";
      });
      print(e.toString());
    }
    
  }


  

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0.0, 
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Icon(
                Icons.directions_bus,
                color: Theme.of(context).accentColor,
                size: 75.0,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      body: new ConnectivityPage(
        widget: Container(
          margin: EdgeInsets.only(top: 20.0),
          decoration: BoxDecoration(
            color: Theme.of(context).accentColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15.0),
              topRight: Radius.circular(15.0),
            ),
          ),
          child: ListView(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 75.0, left:  25.0),
                child: costumLabel("Numero do autocarro:"),
              ),
              //dropDownNrBus(),
              _formInput('Autocarro'),
              Padding(
                padding: EdgeInsets.only(top: 15.0, left:  25.0),
                child: costumLabel("Numero da linha:"),
              ),
              //dropDownLinhas(),
              _formInput('Linha'),
              _checkBoxSection(),
              _errorSection(),
              _buttonSection(),
            ],
          ),
        ),          
      )
    );
  }

  Container _buttonSection(){
    return Container(
      padding: EdgeInsets.only(top: 20.0, bottom: 15.0),
      margin: EdgeInsets.symmetric(horizontal: 30.0),
      child: RaisedButton(
        onPressed: () {

          // print("bus: " + __selectedBusController.text); //debug
          // print("linha: " + __selectedLineController.text); //debug
          // print("btnText = " + widget.btnText);

          // if(_selectedLine!=null && _selectedBus!=null ){
          //   print("bus: " + _selectedBus.toString()); //debug
          //   print("linha: " + _selectedLine.toString()); //debug

          //   if((_selectedLine !=_defaultLine) || (_selectedBus != _defaultBus)) //É preciso corrigir o que esta na bd
          //   {
          //     //fazer o post para corrigir 
          //     //
          //     //correctInfo();
          //     //confirmar se o pedido é com id horario ou condutor
          //   }
            
          // }

          if((__selectedBusController.text == "" || __selectedLineController.text == "") && widget.btnText == 'Avançar'){
            sharedPreferences.setString("id_autocarro", null);
            sharedPreferences.setString("id_linha", null);
            // print("Vem do login e nao preencheu tudo");
          }else if((__selectedBusController.text == "" || __selectedLineController.text == "") && widget.btnText == 'Voltar à página inicial'){
            // print("Nada é alterado");
          }else{
            sharedPreferences.setString("id_autocarro", __selectedBusController.text);
            sharedPreferences.setString("id_linha", __selectedLineController.text);
            // print("Correu tudo bem");
          }

          if(checkBoxValue){
            sharedPreferences.setString("id_autocarro", null);
            sharedPreferences.setString("id_linha", null);   
            // print("Checkbox ativada delete all");         
          }
          // if(sharedPreferences.getString('id_autocarro') != null && sharedPreferences.getString('id_linha') != null){
          //   print("autocarro corrente: " + sharedPreferences.getString('id_autocarro'));
          //   print("linha atual: " + sharedPreferences.getString('id_linha'));
          // }else{
          //   print("ta null");
          // }

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
        child: Text(widget.btnText,
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
      child: Text(
        text, 
        style: TextStyle(
          fontSize: 19.0,
          fontWeight: FontWeight.bold,
          color: Colors.white
        ),
      ),
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

  Container _errorSection(){
    return Container(
      padding: EdgeInsets.only(left: 40.0, top: 12.0),
      child: _error == "" ? Container(margin: EdgeInsets.only(top: 20.0),) :
      Row(
        children: <Widget>[
          Flexible(
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.error_outline,
                  color: Colors.red[700],
                  size: 20.0,
                ),
                SizedBox(width: 5.0),
                Expanded(
                  child: Text('  $_error', 
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
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

  Padding _formInput(String hint){
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      child: TextFormField(
        cursorColor: Colors.white,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        controller: hint == "Autocarro" ? __selectedBusController : __selectedLineController,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white60),
          filled: true,
          fillColor: Colors.grey[800]
        ),
        autocorrect: false,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
            WhitelistingTextInputFormatter.digitsOnly
        ],
        onChanged: (String value) {
          _selectedBus = int.parse(value);
        },
      ),
    );
  }

  Padding _checkBoxSection(){
    return Padding(
      padding: const EdgeInsets.only(left: 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Theme(
            data: Theme.of(context).copyWith(
              unselectedWidgetColor: Theme.of(context).primaryColor,
            ),
            child: Checkbox(
              value: checkBoxValue,
              hoverColor: Colors.red,
              activeColor: Theme.of(context).primaryColor,
              checkColor: Theme.of(context).accentColor,
              onChanged: (bool value){
                setState(() {
                  checkBoxValue = value;
                });
              }
            ),
          ),
          Container(
            padding: EdgeInsets.only(right: 15.0),
            child: Text(
              "Avançar sem autocarro", 
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16 
              ),
              textAlign: TextAlign.start,
            )
          ),
        ],
      ),
    );
  }
}
