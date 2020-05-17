import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:app_condutor/driverSetup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_condutor/connectivity.dart';

Future main() async {
  await DotEnv().load('.env');  //Use - DotEnv().env['IP_ADDRESS'];
  runApp(LoginPage());
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState()=> _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var _error = "";
  bool checkBoxValue = false;
  bool connected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
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
              _titleSection(),
              _formSection(),
              _errorSection(),
              _buttonSection(),
              _checkBoxSection(),
            ],
          )
        ),
      ),
    );
  }

  Container _titleSection() {
    return Container(
      margin: EdgeInsets.only(top: 110.0, left: 30.0),
      child: Text("Bem vindo, Sr. Condutor",
        style: TextStyle(
          color: Colors.white,
          fontSize: 32.0,
          fontWeight: FontWeight.bold
        )
      ),
    );
  }

  Container  _formSection(){
    return Container(
      margin: EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
        child: Column(
          children: <Widget>[
            SizedBox(height: 60.0),
            _formInput("Email", Icons.email),
            _formInput("Password", Icons.lock),
          ],
        )
    );
  }

  TextEditingController emailControler = new TextEditingController();
  TextEditingController passwordControler = new TextEditingController();


  TextFormField _formInput(String hint, IconData iconName){
    return TextFormField(
      cursorColor: Colors.white,
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      obscureText: hint == "Password" ? true : false ,
      controller: hint == "Password" ? passwordControler : emailControler,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white60),
        icon: Icon(iconName, 
          color: Theme.of(context).primaryColor,
        ),
        filled: true,
        fillColor: Colors.grey[800]
      ),
    );
  }

  Container _buttonSection(){
    return Container(
      padding: EdgeInsets.only(top: 20.0, bottom: 15.0),
      margin: EdgeInsets.symmetric(horizontal: 30.0),
      child: RaisedButton(
        onPressed: () {
          _signIn(emailControler.text, passwordControler.text);
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

  Container _errorSection(){
    return Container(
      padding: EdgeInsets.only(left: 70.0, top: 12.0),
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
                  child: Text('$_error', 
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

  Row _checkBoxSection(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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
          padding: EdgeInsets.only(right: 20.0),
          child: Text("Manter sessão iniciada", 
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.start,)
          ),
      ],
    );
  }
  
  _signIn(String email, String password) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    setState(() {
      _error = ""; //clear errors 
    });

    final regexEmail = RegExp(r"^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$");

    if (!regexEmail.hasMatch(email) || password.trim()==""){
      setState(() {
        _error = "Preencha os dois campos"; //clear errors 
      });
      return;
    }

    Map body = {
      "email" : email,
      "password" : password,
    };

    //var jsonResponse = null;
    var url = "http://" + DotEnv().env['IP_ADDRESS'] + "/api/loginAPI";
    //final response = null;
    
    try {      
      final response = await http.post(url, body: body).timeout(const Duration(seconds: 6));
      print(response.statusCode);
      if(response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if(jsonResponse['user']['tipo']=='d'){
          if(jsonResponse['token'].containsKey('access_token')) {
            sharedPreferences.setBool("checkBox", checkBoxValue);
            //print(jsonResponse['token'].containsKey('access_token'));
            //print("id: " + jsonResponse['user']['id'].toString());
            sharedPreferences.setString("access_token", jsonResponse['token']['access_token'].toString());
            sharedPreferences.setString("email", email);
            sharedPreferences.setString("nome", jsonResponse['user']['nome']);
            sharedPreferences.setString("localidade", jsonResponse['user']['localidade']);
            sharedPreferences.setString("data_nascimento", jsonResponse['user']['data_nascimento']);
            sharedPreferences.setString("id_condutor", jsonResponse['user']['id'].toString());



            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => SetupPage(btnText: 'Avançar',)), (Route<dynamic> route) => false);
            //print(jsonResponse['access_token']);
            //print(sharedPreferences.getBool("checkBox"));
          }
          else{
            sharedPreferences.clear();
            setState(() {
              _error = "Algo correu muito mal 1!uncaught exception";
            });
            print("Algo correu muito mal 1!uncaught exception");
          }
        }else{
          sharedPreferences.clear();
          setState(() {
              _error = "Tem de utilizar uma conta de condutor!";
            });
        }
      }
      else if(response.statusCode == 400){
        sharedPreferences.clear();
        setState(() {
            _error = "Email ou password incorretos";
          });
          print("Email ou password incorretos");
      }
      else{
        sharedPreferences.clear();
        setState(() {
            _error = "Algo correu muito mal 2!uncaught exception";
          });
        print("uncaught exception \n" + response.body);
      }
    }
    
    catch(e){
      if(e.toString().contains("TimeoutException")) {
        setState(() {
          _error="Demasiado tempo para conectar ao servidor";
        });
        print("demasiado tempo para conectar ao servidor");
      }
    sharedPreferences.clear();
    print(e);
    setState(() {
      _error="Erro de conexão ao servidor";
    });

    print("Erro de conexão ao servidor");
    }
  }

}