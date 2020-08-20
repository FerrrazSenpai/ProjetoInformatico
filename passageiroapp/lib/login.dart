import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:passageiroapp/map.dart';
import 'package:passageiroapp/drawer.dart';
import 'package:passageiroapp/connectivity.dart';

Future main() async {
  await DotEnv().load('.env'); //Use - DotEnv().env['IP_ADDRESS'];
  runApp(LoginPage());
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var _error = "";
  bool connected;
  bool checkBoxValue = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0.0,
      ),
      backgroundColor: Theme.of(context).primaryColor,
      body: ConnectivityPage(
        widget: Container(
            padding: EdgeInsets.only(left: 30, right: 30),
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
            )),
      ),
      drawer: DrawerPage(
        loginStatus: false,
      ),
    );
  }

  Container titleSection() {
    return Container(
      margin: EdgeInsets.only(top: 110.0, left: 30.0, right: 30.0),
      child: new Image.asset('assets/bus.png', width: 100, height: 100),
    );
  }

  Container formSection() {
    return Container(
        child: Column(
      children: <Widget>[
        SizedBox(height: 60.0),
        formInput("Email", Icons.email),
        SizedBox(height: 10.0),
        formInput("Password", Icons.lock),
        SizedBox(height: 20.0),
      ],
    ));
  }

  TextEditingController emailControler = new TextEditingController();
  TextEditingController passwordControler = new TextEditingController();

  TextFormField formInput(String hint, IconData iconName) {
    return TextFormField(
      cursorColor: Colors.white,
      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
      obscureText: hint == "Password" ? true : false,
      controller: hint == "Password" ? passwordControler : emailControler,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w400,
          fontSize: 18,
        ),
        icon: Icon(
          iconName,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Container buttonSection() {
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
            side: BorderSide(color: Colors.black54)),
        splashColor: Colors.black54,
        colorBrightness: Brightness.light,
        child: Text(
          "Iniciar Sessão",
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

  Container errorSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.0),
      child: _error == ""
          ? Container(
              margin: EdgeInsets.only(top: 20.0),
            )
          : Row(
              children: <Widget>[
                Icon(
                  Icons.error_outline,
                  color: Colors.red[700],
                  size: 20.0,
                ),
                SizedBox(width: 5.0),
                Expanded(
                    child: Text(
                  '$_error',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                  ),
                )),
              ],
            ),
    );
  }

  Row checkBoxSection() {
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
              onChanged: (bool value) {
                setState(() {
                  checkBoxValue = value;
                });
              }),
        ),
        Container(
            padding: EdgeInsets.only(right: 20.0),
            child: Text(
              "Manter sessão iniciada",
              style: TextStyle(color: Colors.black),
              textAlign: TextAlign.start,
            )),
      ],
    );
  }

  signIn(String email, String password) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    setState(() {
      _error = ""; //clear errors
    });


    if (email.trim()=="" || password.trim() == "") {
      setState(() {
        _error = "Preencha ambos os campos!"; 
      });
      return;
    }


    //Informar o user se o email não tiver as caracteristicas de um email, não o vai impedir de continuar 
    final regexEmail = RegExp(r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
    if (!regexEmail.hasMatch(email.trim())) {
      setState(() {
        _error = "Tem a certeza que o email está correto?";
      });
    }

    Map body = {
      "email": email.trim(),
      "password": password.trim(),
    };
    var url = "http://" + DotEnv().env['IP_ADDRESS'] + "/api/loginCliente";
    try {
      final response =
          await http.post(url, body: body).timeout(const Duration(seconds: 5));
      print(response.statusCode);
      if (response.statusCode == 200) { 
        if (response.body.trim() == "{\"msg\":\"Not authorized\"}") { //se a resposta for 200, mas no conteudo estiver Not autorized
          setState(() {
            _error = "Email ou password incorretos";
          });
          print("Email ou password incorretos");
          return;
        }

        var jsonResponse = json.decode(response.body);

        if (jsonResponse.containsKey('user') && jsonResponse['user']['tipo'] != "c") { // condição especial
          // tipo c é utilizadores da app de passageiros - quero garantir que nao permitimos login com credencias da app condutor, ou seja se o tipo for != de c não vai poder entrar
          setState(() {
            _error = "Email ou password incorretos";
          });
          print("Email ou password incorretos");
          return;
        }

        if (jsonResponse['token'].containsKey('access_token')) { //garantir que a respostra trás o access token
          sharedPreferences.setInt("id", jsonResponse['user']['id']);
          sharedPreferences.setBool("checkBox", checkBoxValue);
          sharedPreferences.setBool("update_notifications", true);
          sharedPreferences.setString(
              "access_token", jsonResponse['token']['access_token'].toString());
          sharedPreferences.setString("email", email);
          sharedPreferences.setString("nome", jsonResponse['user']['nome']);
          sharedPreferences.setInt("idCliente", jsonResponse['user']['id']);
          sharedPreferences.setBool("loginStatus", true);
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (BuildContext context) => MapPage(
                        title: "Página inicial",
                      )),
              (Route<dynamic> route) => false);
        } else { //se a resposta não tiver o access token
          setState(() {
            _error = "Erro a receber a informação do servidor. Tente novamente!";
          });
          print("A resposta não tem a estrutura certa");
        }
      } else if (response.statusCode == 400 || response.statusCode == 401) {  //se retornar 401, classico password errada
        setState(() {
          _error = "Email ou password incorretos";
        });
        print("Email ou password incorretos");
      } else { // se nao for nem 200 nem 400 //algo de estranho se passou com o servidor - tentar outra vez
        setState(() {
          _error = "Erro de conexão ao servidor, tente novamente!";
        });
        print("Erro, a resposta não é 200 nem 400 ... \n" + response.body);
      }
    } catch (e) { //ocorreu algum erro durante o pedido, tentar outra vez
      setState(() { 
        _error = "Erro de conexão ao servidor, tente novamente!";
      });
      print("Erro de conexão ao servidor" + e.toString());
    }
  }
}
