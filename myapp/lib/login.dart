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
      body: new Container(
        /*decoration: new BoxDecoration(
          image: DecorationImage(
            image: ExactAssetImage("assets/wallpBUS.jpg"),
            fit: BoxFit.cover,
          ),
        ), */
        color: Colors.white,
        child: ListView(
          children: <Widget>[
            titleSection(),
            formSection(),
            buttonSection(),
            errorSection()
          ],
        )
      ),
    );
  }

  Container titleSection() {
    return Container(
      margin: EdgeInsets.only(top: 110.0),
      child: Text("Olá, motorista", 
        style: TextStyle(
          color: Colors.black45,
          fontSize: 35.0,
          fontWeight: FontWeight.bold)),
    );
  }

  Container  formSection(){
    return Container(
      margin: EdgeInsets.only(top: 40.0),
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
      obscureText: hint == "Password" ? true : false ,
      controller: hint == "Password" ? passwordControler : emailControler,
      decoration: InputDecoration(
        hintText: hint,
        icon: Icon(iconName),
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
        color: Colors.yellow,
        child: Text("Login",
          style: new TextStyle(
          color: Colors.black,
        ),
      ),
     ),
    );
  }

  Container errorSection(){
    return Container(
      child: Text('$_error', 
        style: TextStyle(
          color: Colors.red,
          fontSize: 15.0,
          fontWeight: FontWeight.bold)),
    );
  }

  signIn(String email, String password) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    setState(() {
      _error = ""; //clear errors 
    });

    
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
          print("olaolaola\n\n\n");
          sharedPreferences.setString("access_token", jsonResponse['access_token']);
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => MyHomePage(title: 'Flutter Demo Home Page')), (Route<dynamic> route) => false);
          print(jsonResponse['access_token']);
        }
        else{
          setState(() {
            _error = "Wrong email/password";
          });
          print("wrong email/password");
        }
      }
      else if(response.statusCode == 302){
        setState(() {
            _error = "Fields not valid";
          });
          print("Fields not valid");
      }
      else{
        print(response.body);
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