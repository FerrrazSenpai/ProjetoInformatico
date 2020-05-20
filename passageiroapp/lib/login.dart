import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:connectivity/connectivity.dart';
import 'main.dart';


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
  bool connected;
  bool checkBoxValue=false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      
      body: Builder(
        builder: (BuildContext context){
          return OfflineBuilder(
            connectivityBuilder: (
              BuildContext context,
              ConnectivityResult connectivity,
              Widget child
            ){
              connected = connectivity != ConnectivityResult.none;
              return Stack(
                fit: StackFit.expand,
                children: [
                  child,
                  Positioned(
                    left: 0.00,
                    right: 0.00,
                    height: 30.00,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      color: connected ? null : Colors.black,
                      child: connected ? null :
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text("The device is disconnected", style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold),),
                          SizedBox(width: 8.0,),
                          SizedBox(width: 12.0, height: 12.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red[800]),
                          ),),
                        ],
                      ),
                    ),
                  )
                ],
              );
            },
            child: Container(
              padding: EdgeInsets.only(top: 40, left: 30, right: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  topRight: Radius.circular(15.0),
                ),
              ),
              child: ListView(
                children: <Widget>[
                  titleSection(),
                  formSection(),
                  errorSection(),
                  buttonSection(),
                  checkBoxSection(),
                  /*Container(
                    child: RaisedButton(
                    child: Text('Continuar sem autenticação'),
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => MyHomePage(title: 'App Passageiro')), (Route<dynamic> route) => false);
                    },
                  ),
                  )*/
                ],
              )
            ),
          );
        },
      ),
    );
  }


  Container titleSection() {
    return Container(
      margin: EdgeInsets.only(top: 110.0, left: 30.0, right:30.0),
      child: new Image.asset('assets/bus.png', width:100, height:100),
    );
  }

  Container  formSection(){
    return Container(
        child: Column(
          children: <Widget>[
            SizedBox(height: 60.0),
            formInput("Email", Icons.email),
            SizedBox(height: 10.0),
            formInput("Password", Icons.lock),
          ],
        )
    );
  }

  TextEditingController emailControler = new TextEditingController();
  TextEditingController passwordControler = new TextEditingController();


  TextFormField formInput(String hint, IconData iconName){
    return TextFormField(
      cursorColor: Colors.white,
      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
      obscureText: hint == "Password" ? true : false ,
      controller: hint == "Password" ? passwordControler : emailControler,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w400,
          fontSize: 18,
        ),
        icon: Icon(iconName, 
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Container buttonSection(){
    return Container(
      padding: EdgeInsets.only(top: 20.0),
      margin: EdgeInsets.symmetric(horizontal: 30.0),
      child: RaisedButton(
        onPressed: () {
          signIn(emailControler.text, passwordControler.text);
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

  Row checkBoxSection(){
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
            style: TextStyle(color: Colors.black),
            textAlign: TextAlign.start,)
          ),
      ],
    );
  }


  signIn(String email, String password) async {
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
    var url = "http://" + DotEnv().env['IP_ADDRESS'] + "/api/loginCliente";
    try {      
      final response = await http.post(url, body: body).timeout(const Duration(seconds: 5));
      print(response.statusCode);
      if(response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if(jsonResponse['token'].containsKey('access_token')) {
          sharedPreferences.setBool("checkBox", checkBoxValue);
          sharedPreferences.setString("access_token", jsonResponse['token']['access_token'].toString());
          sharedPreferences.setString("email", email);
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => MyHomePage(title: 'App Passageiro')), (Route<dynamic> route) => false);
          //print(jsonResponse['access_token']);
          //print(sharedPreferences.getBool("checkBox"));
        }
        else{
          setState(() {
            _error = "Algo correu muito mal2!uncaught exception";
          });
          print("Algo correu muito mal2!uncaught exception");
        }
      }
      else if(response.statusCode == 400){
        setState(() {
            _error = "Email ou password incorretos";
          });
          print("Email ou password incorretos");
      }
      else{
        setState(() {
            _error = "Algo correu muito mal1!uncaught exception";
          });
        print("uncaught exception1 \n" + response.body);
      }
    }
    catch(e){
      setState(() {
        _error="Erro de conexão ao servidor";
      });
      print("Erro de conexão ao servidor");
    }
  }















}