import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'driverSetup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:connectivity/connectivity.dart';

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
            Icon(
              Icons.directions_bus,
              color: Theme.of(context).accentColor,
              size: 75.0,
            ),
          ],
        ),
      ),
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
                  titleSection(),
                  formSection(),
                  errorSection(),
                  buttonSection(),
                  checkBoxSection(),
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

  Container  formSection(){
    return Container(
      margin: EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
        child: Column(
          children: <Widget>[
            SizedBox(height: 60.0),
            formInput("Email", Icons.email),
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
            style: TextStyle(color: Colors.white70),
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

    //var jsonResponse = null;
    var url = "http://" + DotEnv().env['IP_ADDRESS'] + "/api/login";
    //final response = null;
    
    try {      
      final response = await http.post(url, body: body).timeout(const Duration(seconds: 5));
      print(response.statusCode);
      if(response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        sharedPreferences.setBool("checkBox", checkBoxValue);
        if(jsonResponse.containsKey('access_token')) {
          sharedPreferences.setString("access_token", jsonResponse['access_token']);
          sharedPreferences.setString("email", email);
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => SetupPage()), (Route<dynamic> route) => false);
          print(jsonResponse['access_token']);
          print(sharedPreferences.getBool("checkBox"));
        }
        else{
          setState(() {
            _error = "Algo correu muito mal!uncaught exception";
          });
          print("Algo correu muito mal!uncaught exception");
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
            _error = "Algo correu muito mal!uncaught exception";
          });
        print("uncaught exception \n" + response.body);
      }
    }
    
    catch(e){
//      if(e.toString().contains("TimeoutException")) {
//        print("demasiado tempo para conectar ao servidor");
//      }
    setState(() {
      _error="Erro de conexão ao servidor";
    });

    print("Erro de conexão ao servidor");
    }
  }

}