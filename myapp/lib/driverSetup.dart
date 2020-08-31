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
  // int _idCondutor;
  // var _defaultLine = 0;
  // var _defaultBus = 0;
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
      var listaBus=[];

      for(var elem in array){
        if(elem["estado"]=="livre"){
          bus.add(elem["id_autocarro"]);
        }
      }
      //bus=listaBus; ///rever isto
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
      if (response.body[1] == "]") {
        //ou seja a resposta é só []
        print("EMPTY RESPONSE");
        setState(() {
          _error = "Não tem nenhum serviço está agendado para as próximas horas";
        });
        //return; //nao ha nada para fazer nesta funcao entao
      }else{
        var info = json.decode(response.body);
        print(info);
        //[{id_autocarro: 4, id_linha: 2, data: 2020-08-31, hora_inicio: 09:55:29, hora_fim: 11:10:10}]
        if(info[0].containsKey("id_autocarro") && info[0].containsKey("id_linha") && info[0].containsKey("hora_inicio")){
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

          if(currentTimeMinutes>timeMinutes && currentTimeMinutes<timeFimMinutes){ //se ja tiver começado && ainda nao tiver acabado
            _selectedBus = info[0]["id_autocarro"];
            _selectedLine = info[0]["id_linha"];
          }


          
        }
      }
      /*
      Map<String, dynamic> list = jsonDecode(response.body)[0];
      //array = jsonDecode(response.body)[0];

      //print("linha: " + array["id_linha"]);
      //print("bus: " + array["id_autocarro"]);

      if (list.containsKey('id_linha')) {
        //se vier linha da api
        setState(() {
          _selectedLine = int.parse(list['id_linha'].toString());
          __selectedLineController.text = _selectedLine.toString();
          // _defaultLine=_selectedLine;
        });
      }

      if (list.containsKey('id_autocarro')) {
        setState(() {
          _selectedBus = int.parse(list['id_autocarro'].toString());
          __selectedBusController.text = _selectedBus.toString();
          // _defaultBus=_selectedBus;
        });
      }
      */
    } catch (e) {
      print(e.toString());
      setState(() {
        _error = "Houve um problema ao estabelecer conexão" + e.toString()+ url;
      });
      print(e.toString());
    }
    print("aqui");
    setState(() {
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
                  //_formInput('Autocarro'),
                  _dropdownInput('Autocarro'),
                  Padding(
                    padding: EdgeInsets.only(top: 15.0, left: 25.0),
                    child: costumLabel("Numero da linha:"),
                  ),
                  _dropdownInput('Linha'),
                  //_formInput('Linha'),
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
          //print("id_autocarro:"+ _selectedBus.toString() + ", id_linha:" +  _selectedLine.toString());
          
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
          // if(sharedPreferences.getString('id_autocarro') != null && sharedPreferences.getString('id_linha') != null){
          //   print("autocarro corrente: " + sharedPreferences.getString('id_autocarro'));
          //   print("linha atual: " + sharedPreferences.getString('id_linha'));
          // }else{
          //   print("ta null");
          // }

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
    //sharedPreferences = await SharedPreferences.getInstance();
    var url = "https://" +
        DotEnv().env['IP_ADDRESS'] +
        "/api/horario/" +
        sharedPreferences.getString("id_condutor");
//VER SE É ID_CONDUTOR OU ID_HORARIO

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

  void _openLoadingDialog(BuildContext context) {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: CircularProgressIndicator(),
      );
    },
  );}

   Padding _loading() {
    return Padding(
      padding: const EdgeInsets.only(left: 100.0),
      child: Container(
                child: Center(
                  child: Row(
                    children: <Widget>[
                      Text('A carregar dados ... ', style: TextStyle(color: Colors.white, fontSize: 16.0)),
                      SizedBox(
                        child:CircularProgressIndicator(
                          strokeWidth: 2 , backgroundColor: Colors.blue[400],
                        ),
                      height: 14.0, width: 14.0, 
                      )
                    ],
                  )
                )
              ),

    );
  }

}
