import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';



Future main() async{
  await DotEnv().load('.env');
  runApp(LoginPage());
}
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState()=> _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var _error = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 50.0,
        backgroundColor: Colors.green[800],
      ),
      body: new Container(
        /*decoration: new BoxDecoration(
          image: DecorationImage(
            image: ExactAssetImage("assets/wallpBUS.jpg"),
            fit: BoxFit.cover,
          ),
        ), */
        color: Colors.black54,
        child: ListView(
          children: <Widget>[
            titleSection(),
            formSection(),
            errorSection(),
            buttonSection(),
          ],
        )
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
        hintStyle: TextStyle(color: Colors.white70),
        icon: Icon(iconName, color: Colors.green[800],),
        filled: true,
      ),
    );
  }

  Container buttonSection(){
    return Container(
      padding: EdgeInsets.only(top: 30.0),
      margin: EdgeInsets.symmetric(horizontal: 30.0),
      child: RaisedButton(
        onPressed: () {
          signIn(emailControler.text, passwordControler.text);
        },
        color: Colors.green[800],
        elevation: 10.0,
        padding: EdgeInsets.all(12.0),
        shape: RoundedRectangleBorder(
          borderRadius: new BorderRadius.circular(20.0),
          side: BorderSide(color: Colors.black54)
        ),
        splashColor: Colors.black54,
        colorBrightness: Brightness.light,
        child: Text("Login",
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
      padding: EdgeInsets.only(left: 70.0, top: 15.0),
      child: Text('$_error', 
        style: TextStyle(
          color: Colors.red[600],
          fontSize: 17.0,
          fontWeight: FontWeight.w600
        ),
      ),
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
        if(jsonResponse.containsKey('access_token')) {
          sharedPreferences.setString("access_token", jsonResponse['access_token']);
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => MyHomePage(title: 'Flutter Demo Home Page')), (Route<dynamic> route) => false);
          print(jsonResponse['access_token']);
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