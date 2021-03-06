import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:app_condutor/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:app_condutor/connectivity.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:date_format/date_format.dart';


class SetupPage extends StatefulWidget {
  SetupPage({Key key, this.btnText}) : super(key: key);

  final String btnText;
  @override
  _SetupPageState createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  SharedPreferences sharedPreferences;
  var array;
  var _error = "";
  int _selectedBus;
  int _selectedLine;
  bool checkBoxValue = false;
  bool _absorbing = true;

  final TextEditingController __selectedLineController =
      new TextEditingController();
  final TextEditingController __selectedBusController =
      new TextEditingController();

  List bus = List();
  List linhas = List();

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future getData() async {
    sharedPreferences = await SharedPreferences.getInstance();

    //ir buscar os autocarros livres
    var url = "https://" + DotEnv().env['IP_ADDRESS'] + "/api/autocarrosDisponiveis/" ;
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization':
              "Bearer " + sharedPreferences.getString("access_token")
        },
      ).timeout(const Duration(seconds: 15));

      array = jsonDecode(response.body)["data"];

      for(var elem in array){
        if(elem["estado"]=="livre"){
          bus.add(elem["id_autocarro"]);
        }
      }
    }catch(e){
      print(e.toString());
    }

    //ir buscar linhas
    url = "https://" + DotEnv().env['IP_ADDRESS'] + "/api/linhas/" ;
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization':
              "Bearer " + sharedPreferences.getString("access_token")
        },
      ).timeout(const Duration(seconds: 15));

      array = jsonDecode(response.body)["data"];

      for(var elem in array){   
          linhas.add(elem["id_linha"]);
      }

    }catch(e){
      print(e.toString());
    }

    url = "https://" +
        DotEnv().env['IP_ADDRESS'] +
        "/api/getHorarios/" +
        sharedPreferences.getString("id_condutor");
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization':
              "Bearer " + sharedPreferences.getString("access_token")
        },
      ).timeout(const Duration(seconds: 15));
      print(response.body);
      if (response.body == "[]") { //ou seja, o server responde só [], não há horario na base de dados para este condutor
        setState(() {
          _error = "Não tem nenhum serviço está agendado para as próximas horas";
        });
      }else{
        var info = json.decode(response.body);

        if(info[0].containsKey("id_autocarro") && info[0].containsKey("id_linha") && info[0].containsKey("hora_inicio") && info[0].containsKey("hora_fim")){
          var hInicio = info[0]["hora_inicio"];
          var aux= hInicio.toString().split(":");

          var hFim= info[0]["hora_fim"];
          var auxFim= hFim.toString().split(":");

          var timeInicio = TimeOfDay(hour: int.parse(aux[0]), minute: int.parse(aux[1]));
          print(timeInicio);
          var timeFim = TimeOfDay(hour: int.parse(auxFim[0]), minute: int.parse(auxFim[1]));
          print(timeFim);
          var currentTime = TimeOfDay.now();
          print(currentTime);

          var timeMinutes = (timeInicio.hour*60) + timeInicio.minute;
          var timeFimMinutes = (timeFim.hour*60) + timeFim.minute;
          var currentTimeMinutes = (currentTime.hour*60) + currentTime.minute;

          if(currentTimeMinutes>timeMinutes && currentTimeMinutes<timeFimMinutes){ //se ja tiver começado && ainda nao tiver acabado(ou seja está na hora do serviço), vai preencher os campos automaticamente
            if(bus.contains(info[0]["id_autocarro"])){
              _selectedBus = info[0]["id_autocarro"];
            }else{
              _error="Autocarro ocupado";
            }
            if(linhas.contains(info[0]["id_linha"])){
              _selectedLine = info[0]["id_linha"];
            }          
          }         
        }else{
          setState(() {
            _error="Horario mal formatado, contactar superior";
          });
        }
      }
    } catch (e) {
      print(e.toString());
      setState(() {
        _error = "Houve um problema ao estabelecer conexão com o servidor";
      });
      print(e.toString());
    }
    
    setState(() {
      //antes o absorving estava == true para impedir o user de mexer enquanto a app fazia os pedidos ao servidor.Como os pedidos já estão todos concluidos, passa a false para o user poder mexer
      _absorbing=false;
    }); 
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
              Icon(
                FontAwesomeIcons.busAlt,
                color: Theme.of(context).accentColor,
                size: 60.0,
              ),
            ],
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        body: AbsorbPointer(
          absorbing: _absorbing,
          child: ConnectivityPage(
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
                    padding: EdgeInsets.only(top: 75.0, left: 25.0),
                    child: costumLabel("Numero do autocarro:"),
                  ),
                  _dropdownInput('Autocarro'),
                  Padding(
                    padding: EdgeInsets.only(top: 15.0, left: 25.0),
                    child: costumLabel("Numero da linha:"),
                  ),
                  _dropdownInput('Linha'),
                  _checkBoxSection(),
                  _errorSection(),
                  _absorbing==false ?_buttonSection() : _loading()
                ],
              )  
            ),
          )
        )
      );
  }

  Container _buttonSection() {
    return Container(
      padding: EdgeInsets.only(top: 20.0, bottom: 15.0),
      margin: EdgeInsets.symmetric(horizontal: 30.0),
      child: RaisedButton(
        onPressed: () {         
          if ((_selectedBus.toString() == "" ||
                _selectedLine.toString() == "" ||
                  _selectedBus == null || 
                    _selectedLine == null) &&
              widget.btnText == 'Avançar') {
            sharedPreferences.setString("id_autocarro", null);
            sharedPreferences.setString("id_linha", null);
            //print("Vem do login e nao preencheu tudo");
          } else if ((_selectedBus.toString() == "" ||
                  _selectedLine.toString() == "" ||
                  _selectedBus == null || 
                  _selectedLine == null) &&
              widget.btnText == 'Voltar à página inicial') {
              //print("Nada é alterado");
          } else {
            sharedPreferences.setString(
                "id_autocarro", _selectedBus.toString());
            sharedPreferences.setString(
                "id_linha", _selectedLine.toString());
             //print("Correu tudo bem");
          }

          if (checkBoxValue) {
            sharedPreferences.setString("id_autocarro", null);
            sharedPreferences.setString("id_linha", null);
            // print("Checkbox ativada delete all");
          }

          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (BuildContext context) =>
                      DashboardPage(title: 'Página inicial')),
              (Route<dynamic> route) => false);
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
          widget.btnText,
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

  Container costumLabel(String text) {
    return Container(
      child: Text(
        text,
        style: TextStyle(
            fontSize: 19.0, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Container _errorSection() {
    return Container(
      padding: EdgeInsets.only(left: 40.0, top: 12.0, right: 40.0),
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
                        size: 20.0,
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

  correctInfo() async {
    sharedPreferences = await SharedPreferences.getInstance();
    var url = "https://" +
        DotEnv().env['IP_ADDRESS'] +
        "/api/horario/" +
        sharedPreferences.getString("id_condutor");

    Map body = {
      "id_autocarro": _selectedBus,
      "id_linha": _selectedLine,
    };

    try {
      final response = await http
          .post(url,
              headers: {
                'Authorization':
                    "Bearer " + sharedPreferences.getString("access_token")
              },
              body: body)
          .timeout(const Duration(seconds: 15));

      print(response.statusCode);
    } catch (e) {
      print(e);
      setState(() {
        _error = e.toString();
      });
    }
  }

  //substituido pelos dropdown
  Padding _formInput(String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      child: TextFormField(
        cursorColor: Colors.white,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        controller: hint == "Autocarro"
            ? __selectedBusController
            : __selectedLineController,
        decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white60),
            filled: true,
            fillColor: Colors.grey[800]),
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

  Padding _dropdownInput(String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      child: Theme(
        data: Theme.of(context).copyWith(
            canvasColor: Colors.grey[800],
          ),
        child: DropdownButtonFormField(
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          items: 
            hint == "Autocarro"
              ?bus.map((id) {
                return DropdownMenuItem(
                  value: id,
                  child: Text(id.toString()),
                );
              }
            ).toList()
            :linhas.map((id) {
            return DropdownMenuItem(
              value: id,
              child: Text(id.toString()),
            );
          }
        ).toList(),
        onChanged: (value) {
          hint == "Autocarro"
            ? setState(() {
            _selectedBus = value;
            })
          : setState(() {
            _selectedLine = value;
          });
        },
        value: hint == "Autocarro" ? _selectedBus : _selectedLine,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white60,fontWeight: FontWeight.w900),
          filled: true,
          fillColor: Colors.grey[800],
          ),
        ),
      )
    );
  }

  Padding _checkBoxSection() {
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
                onChanged: (bool value) {
                  setState(() {
                    checkBoxValue = value;
                  });
                }),
          ),
          Container(
              padding: EdgeInsets.only(right: 15.0),
              child: Text(
                "Avançar sem autocarro",
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.start,
              )),
        ],
      ),
    );
  }

   Container _loading() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('A carregar dados ... ', style: TextStyle(
            color: Colors.white,
            letterSpacing: 2.0,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            child:CircularProgressIndicator(
              strokeWidth: 2 , backgroundColor: Colors.blue[400],
            ),
          height: 18.0, width: 18.0, 
          )
        ],
      )
    );
  }

}
