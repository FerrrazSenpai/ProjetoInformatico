import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:passageiroapp/map.dart';
import 'drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:connectivity/connectivity.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:passageiroapp/connectivity.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool connected;
  var _error = "";
  var dataNascimento;
  SharedPreferences sharedPreferences;
  bool _loginStatus = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _absorbing = false;

  @override
  Widget build(BuildContext context) {
    _checkLoginStatus();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Text("Registo"),
        backgroundColor: Colors.black,
      ),
      body: AbsorbPointer(
          absorbing: _absorbing,
          child: Builder(
            builder: (context) {
              return ConnectivityPage(
                widget: Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: ListView(
                      children: <Widget>[
                        formSection(),
                        _errorSection(),
                        buttonSection(),
                      ],
                    )),
              );
            },
          )),
      drawer: DrawerPage(
        loginStatus: _loginStatus,
      ),
    );
  }

  _checkLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();

    setState(() {
      if (sharedPreferences.getBool("loginStatus") == null ||
          !sharedPreferences.getBool("loginStatus")) {
        _loginStatus = false;
      } else {
        _loginStatus = true;
      }
    });
  }

  Container formSection() {
    return Container(
        child: Column(
      children: <Widget>[
        SizedBox(height: 40.0),
        formInputWControler("Nome", FontAwesomeIcons.userAlt, nameControler),
        SizedBox(height: 10.0),
        formInput("Email", FontAwesomeIcons.solidEnvelope),
        SizedBox(height: 18.0),
        formInputBirth("Data Nascimento", FontAwesomeIcons.solidCalendarAlt),
        SizedBox(height: 10.0),
        formInput("Password", FontAwesomeIcons.lock),
        SizedBox(height: 10.0),
        formInputWControler("Confirmar Password", FontAwesomeIcons.lock,
            passwordConfirmationControler),
        SizedBox(height: 10.0),
        formInputWControler(
            "Localidade", FontAwesomeIcons.sign, localidadeControler),
      ],
    ));
  }

  TextEditingController nameControler = new TextEditingController();
  TextEditingController emailControler = new TextEditingController();
  TextEditingController passwordControler = new TextEditingController();
  TextEditingController passwordConfirmationControler =
      new TextEditingController();
  TextEditingController localidadeControler = new TextEditingController();

  TextFormField formInput(String hint, IconData iconName) {
    return TextFormField(
      cursorColor: Colors.black,
      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w400),
      obscureText: hint == "Password" ? true : false,
      controller: hint == "Password" ? passwordControler : emailControler,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        icon: Icon(
          iconName,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  TextFormField formInputWControler(
      String hint, IconData iconName, var controller) {
    return TextFormField(
      cursorColor: Colors.black,
      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w400),
      obscureText: hint == "Confirmar Password" ? true : false,
      controller: controller,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        icon: Icon(
          iconName,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  var dropdownValue;
  int dia;
  int mes;
  int ano;
  Container formInputBirth(String hint, IconData iconName) {
    return Container(
      child: Row(
        children: <Widget>[
          Icon(
            iconName,
            color: Theme.of(context).primaryColor,
          ),
          SizedBox(width: 16.0),
          Text(
            'Data nascimento',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 16.0),
          DropdownButton<int>(
            value: dia,
            icon: Icon(FontAwesomeIcons.arrowDown),
            iconSize: 12,
            elevation: 16,
            style: TextStyle(color: Colors.black),
            underline: Container(
              height: 2,
              color: Colors.black54,
            ),
            onChanged: (int ano) {
              setState(() {
                dia = ano;
              });
            },
            items: [for (var i = 1; i <= 31; i += 1) i]
                .map<DropdownMenuItem<int>>((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text(value.toString()),
              );
            }).toList(),
          ),
          SizedBox(width: 2.0),
          DropdownButton<int>(
            value: mes,
            icon: Icon(FontAwesomeIcons.arrowDown),
            iconSize: 12,
            elevation: 16,
            style: TextStyle(color: Colors.black),
            underline: Container(
              height: 2,
              color: Colors.black54,
            ),
            onChanged: (int newValue) {
              setState(() {
                mes = newValue;
              });
            },
            items: [for (var i = 1; i <= 12; i += 1) i]
                .map<DropdownMenuItem<int>>((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text(value.toString()),
              );
            }).toList(),
          ),
          SizedBox(width: 2.0),
          DropdownButton<int>(
            value: ano,
            icon: Icon(FontAwesomeIcons.arrowDown),
            iconSize: 12,
            elevation: 16,
            style: TextStyle(color: Colors.black),
            underline: Container(
              width: 22.0,
              height: 2,
              color: Colors.black54,
            ),
            onChanged: (int newValue) {
              setState(() {
                ano = newValue;
              });
            },
            items: [for (var i = 2020; i >= 1900; i -= 1) i]
                .map<DropdownMenuItem<int>>((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text(value.toString()),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Container buttonSection() {
    return Container(
      padding: EdgeInsets.only(top: 20.0),
      margin: EdgeInsets.symmetric(horizontal: 20.0),
      child: RaisedButton(
        onPressed: () {
          setState(() {
            _error = ""; //limpar erros
          });
          FocusScope.of(context).unfocus(); //tirar o focus de qualquer caixa de texto -> fechar o teclado caso esteja aberto
          if (nameControler.text.trim() == "" ||
              emailControler.text.trim() == "" ||
              passwordControler.text.trim() == "" ||
              passwordConfirmationControler.text.trim() == "" ||
              localidadeControler.text.trim() == "" ||
              dia == null ||
              mes == null ||
              ano == null) {
            setState(() {
              _error = "É necessario preecher todos os campos!";
            });
            return;
          }

          final regexName =
              new RegExp(r'^[a-zàáâãèéêìíóôõùúçA-ZÀÁÂĖÈÉÊÌÍÒÓÔÕÙÚÛÇ\s]+$');
          if (!regexName.hasMatch(nameControler.text) || nameControler.text.length<3 || nameControler.text.length>30){
            setState(() {
              _error = "Nome invalido!";
            });
            return;
          }

          final regexEmail = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
          if (!regexEmail.hasMatch(emailControler.text)) {
            setState(() {
              _error = "Email invalido!";
            });
            return;
          }

          //confirmar se a data é valida
          dataNascimento = ano.toString() +
              mes.toString().padLeft(2, '0') +
              dia.toString().padLeft(2, '0');
          try {
            var date = DateTime.parse(
                dataNascimento); //se a data nao for valida normalmente dá logo erro aqui e salta para o catch
            if (!date.isBefore(DateTime.now())) {
              setState(() {
                _error = "A data de nascimento é invalida!";
              });
              return;
            }
            var year = date.year.toString().padLeft(4, '0');
            var month = date.month.toString().padLeft(2, '0');
            var day = date.day.toString().padLeft(2, '0');
            if (dataNascimento != "$year$month$day") { //permite ver se o utilizador nao inseriu algum dia não existente, p.e. 31 de setembro
              setState(() {
                _error = "A data de nascimento é invalida!";
              });
              return;
            }
          } catch (e) {
            setState(() {
              _error = "A data de nascimento é invalida!";
            });
            return;
          }
          dataNascimento = ano.toString() +
              "-" +
              mes.toString().padLeft(2, '0') +
              "-" +
              dia.toString().padLeft(2, '0');

          if (passwordControler.text.length < 3) {
            setState(() {
              _error = "A password tem de ter, pelo menos, 3 carateres!";
            });
            return;
          }

          if (passwordControler.text != passwordConfirmationControler.text) {
            setState(() {
              _error = "A password e a confirmação não correspondem!";
            });
            return;
          }

          if (!regexName.hasMatch(localidadeControler.text) || localidadeControler.text.length>30) {
            setState(() {
              _error = "Localidade invalida";
            });
            return;
          }
          register();
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
          "Registar",
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

  Container _errorSection() {
    return Container(
      padding: EdgeInsets.only(left: 40.0, top: 12.0),
      child: _error == ""
          ? Container(
              margin: EdgeInsets.only(top: 20.0),
            )
          : Row(
              children: <Widget>[
                Flexible(
                  child: Row(
                    children: <Widget>[
                      Icon(
                        FontAwesomeIcons.exclamationCircle,
                        color: Colors.red[700],
                        size: 18.5,
                      ),
                      SizedBox(width: 7.0),
                      Expanded(
                        child: Text(
                          '$_error',
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

  register() async {
    Map body = {
      "nome": nameControler.text.trim(),
      "email": emailControler.text.trim(),
      "password": passwordControler.text.trim(),
      "data": dataNascimento.trim(),
      "localidade": localidadeControler.text.trim(),
    };

    var url = "https://" +
        DotEnv().env['IP_ADDRESS'] +
        "/api/utilizadores/registerClient";
    try {
      var response =
          await http.post(url, body: body).timeout(const Duration(seconds: 7));
      print(response.statusCode);
      
      
      if(response.statusCode == 302){
        print(response.body);
        setState(() {
          _error = "Erro: Email já registado!";
        });
        return;
      }

      if (response.statusCode == 201) {
        var jsonResponse = json.decode(response.body);
        print(jsonResponse);

        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text("Conta criada com sucesso"),
        ));
        setState(() {
          _absorbing = true; //nao permitir ao user fazer alterações
        });
        Timer(
            Duration(seconds: 2),
            () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MapPage(title: "Página inicial")),
                ));
      } else {
        setState(() {
          _error = "Erro! Tente novamente";
        });
        print("Error: status != 201\n" + response.body);
      }
    } catch (e) {
      setState(() {
        _error = "Erro de conexão ao servidor, tente novamente!";
      });
      print("Erro de conexão ao servidor: " + e.toString());
    }
  }
}
