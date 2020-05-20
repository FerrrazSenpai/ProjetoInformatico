import 'dart:async';
import 'package:app_condutor/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:date_format/date_format.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app_condutor/connectivity.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: new DashboardPage(
        title: 'Página inicial',
      ),
    );
      //home: new LoginPage(),
  }
}

class DashboardPage extends StatefulWidget {
  DashboardPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  SharedPreferences sharedPreferences;

  var location = new Location();

  LocationData userLocation;
  DateTime time;
  double speedkmh;
  bool connected;
  String nome;
  String email;
  String localidade;
  String dataNascimento;
  String linha;
  String bus;
  bool isActive = false;

  static const duration = const Duration(minutes: 1);
  
  _functionActive() async{
    sharedPreferences = await SharedPreferences.getInstance();
    if(sharedPreferences.getBool("ativo") != null){
      isActive = sharedPreferences.getBool("ativo");
      print('SHARED PREFERENCES = ' + sharedPreferences.getBool("ativo").toString());
    }else{
      sharedPreferences.setBool("ativo", false);
      isActive = false;
      print('SHARED PREFERENCES = ' + sharedPreferences.getBool("ativo").toString());
    }
  }

  Timer timer;

  Color _color = Colors.teal;
  List _events;
  List _selectedEvents;

  bool _setup = false;

  String _selectedDay;

  void handleTick() async{
    sharedPreferences = await SharedPreferences.getInstance();
    if (isActive) {
      _getLocation().then((value) {
        userLocation = value;
        // 1m/s -> 3.6km/h  speed -> speedkmh
        speedkmh = userLocation.speed.toDouble() * 3.600;
        time = DateTime.fromMillisecondsSinceEpoch(userLocation.time.toInt());
        _postLocation();  
      });
    }
  }

  @override
  void initState() {
    super.initState();
    //_getUserData();
    _getUserData2();
    _setupVerification();
    _functionColor(linha);
    _getSchedule();
    _functionActive();
  }

  @override
  Widget build(BuildContext context) {
    
    _functionColor(linha);

    if (timer == null) {
      timer = Timer.periodic(duration, (Timer t) {
        handleTick();
      });
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(widget.title, 
          style: TextStyle(
            color: _color == Colors.black ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22
          ),
        ),
        backgroundColor: _color,
        iconTheme: new IconThemeData(color: _color == Colors.black ? Colors.white : Colors.black),
      ),
      backgroundColor: Theme.of(context).accentColor,
      body: RefreshIndicator(
        child: Container(
          child: new ConnectivityPage(
            widget: ListView(        
              children: <Widget>[
                _getProfile(),
                //_buildEventList(),
                Text("Meus serviços para o dia de hoje",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.white,
                    fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(
                  height: 6.0,
                ),
                _buildEventList(),
                _getLocationButton(),
              ],
            ),
          ),
        ),
        onRefresh: _handleRefresh,
      ),
      drawer: new DrawerPage(),
    );
  }

  Future<LocationData> _getLocation() async {
    LocationData currentLocation;
    try {
      currentLocation = await location.getLocation();
    } catch (e) {
      currentLocation = null;
    }
    return currentLocation;
  }

  
  Future<String> _postLocation() async {
    sharedPreferences = await SharedPreferences.getInstance();
    
    var url = 'http://'+DotEnv().env['IP_ADDRESS']+'/api/tempos';
    Map body = {
      "latitude" : userLocation.latitude.toString(),
      "longitude" : userLocation.longitude.toString(),
      "velocidade" : speedkmh.toStringAsFixed(3),
      "hora" : formatDate(time, [HH,":",nn]),
      "id_linha" : sharedPreferences.getString("id_linha"),
      "id_autocarro" : sharedPreferences.getString("id_autocarro"),
      "id_condutor" : sharedPreferences.getString("id_condutor"),
    };

    var response = 
      await 
      http.post(url,
        headers: {
          'Accept' : 'application/json',
          'Authorization' : "Bearer " + sharedPreferences.getString("access_token"),
        },
        body: body,
      );
    print(response.body);
    return response.body;
    
  }

  // _getUserData() async {
  //   sharedPreferences = await SharedPreferences.getInstance();
  //   String dia;
  //   String ano;
  //   String mes;
  //   var url = 'http://'+ DotEnv().env['IP_ADDRESS']+'/api/profile';
  //   try {      
  //     final response = 
  //     await 
  //     http.get(
  //       url, 
  //       headers: {'Authorization': "Bearer " + sharedPreferences.getString("access_token")},
  //     ).timeout(const Duration(seconds: 15));
  //     print("status code: " + response.statusCode.toString() );
  //     if(response.statusCode==200){
  //       var dados = jsonDecode(response.body);
  //       print(dados);
  //       setState(() {
  //         nome = dados['name'];
  //         email = dados['email'];
  //         dataNascimento = dados['data_nascimento'];
  //         localidade = dados['localidade'];

  //         if(dataNascimento != null ){
  //           ano = dataNascimento.substring(0,4);
  //           dia = dataNascimento.substring(8,10);
  //           mes = dataNascimento.substring(5,7);
  //           dataNascimento = dia + '-' + mes + '-' + ano;
  //         }else{
  //           dataNascimento = 'Desconhecida';
  //         }

  //         if (localidade == null ){
  //           localidade = 'Desconhecida';
  //         }
          
  //       });
  //     }
  //   }catch(e){
  //     print(e);
  //   }
  // }

  _getUserData2() async {
    sharedPreferences = await SharedPreferences.getInstance();
    String dia;
    String ano;
    String mes;

    setState(() {
      
      nome = sharedPreferences.getString("nome");
      email = sharedPreferences.getString("email");
      localidade = sharedPreferences.getString("localidade");
      dataNascimento = sharedPreferences.getString("data_nascimento");
      linha = sharedPreferences.getString("id_linha");
      bus = sharedPreferences.getString("id_autocarro");

      if(dataNascimento != null ){
        ano = dataNascimento.substring(0,4);
        dia = dataNascimento.substring(8,10);
        mes = dataNascimento.substring(5,7);
        dataNascimento = dia + '-' + mes + '-' + ano;
      }else{
        dataNascimento = 'Desconhecida';
      }

      if (localidade == null ){
        localidade = 'Desconhecida';
      }
    });
  }

  Widget _getProfile(){
    return Container(
      margin: EdgeInsets.fromLTRB(30.0, 15.0, 30.0, 25.0),
      child: Row(
        children: <Widget>[
          Flexible(
            child: Column(
              children: <Widget>[
                Icon(
                  FontAwesomeIcons.solidUserCircle,
                  color: _color,
                  size: 65.0,
                ),
                SizedBox(
                  height:9.0
                ),
                Text("$nome",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23.0,
                    color: Colors.white,
                    fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(
                  height: 23.0,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('\Email', 
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(" $email",
                  textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.white
                    ),  
                  ),
                ),
                SizedBox(
                  height: 10.0,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Localidade', 
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(" $localidade",
                  textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.white
                    ),  
                  ),
                ),
                SizedBox(
                  height: 10.0,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Data de nascimento', 
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(" $dataNascimento",
                  textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.white
                    ),  
                  ),
                ),
                _verifyBusLinha(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getLocationButton(){
    var _onPressed;

    _functionColor(linha);

    if(_setup){
      _onPressed = () async {
        sharedPreferences = await SharedPreferences.getInstance();

        setState(() {
          isActive = !isActive;
          sharedPreferences.setBool("ativo", isActive);
          if(isActive){
            _getLocation().then((value) {
              setState(() {
                userLocation = value;
                // 1m/s -> 3.6km/h  speed -> speedkmh
                speedkmh = userLocation.speed.toDouble() * 3.600;
                time = DateTime.fromMillisecondsSinceEpoch(userLocation.time.toInt());
                _postLocation();
              });
            });
          }else{
            print("Parou o envio");
          }
        });
      };
    }
    return Container (
      padding: EdgeInsets.symmetric(horizontal: 30.0,vertical: 20.0),
      child: RaisedButton(
        focusElevation: 30,
        padding: EdgeInsets.all(15.0),
        elevation: 15,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Text(isActive ? 'Parar o envio de localização' : 'Começar o envio de localização',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 19,
            color: _color == Colors.black ? Colors.white : Colors.black
          ),
        ),
        color: _color,
        onPressed: _onPressed,
        disabledColor: Colors.grey[600],
      ),
    );
  }

  Widget _buildEventList() {
    if(_selectedEvents == null){
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(7.0))
        ),
        margin: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
        child: ListTile(
          leading: Icon(
            FontAwesomeIcons.solidCalendarTimes,
            color: Colors.red[900],
          ),
          title: Text('Não tem nenhum serviço agendado',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 19
            ),
          ),
        ),
      );
    }
    return Column(
      children: _selectedEvents
      .map((event) {
        _functionColor(event.toString().substring(0,2));
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              stops: MediaQuery.of(context).orientation == Orientation.portrait ? [0.12, 0.02] : [0.07,0.02],
              colors: [_color, Colors.white]
            ),
            borderRadius: BorderRadius.all(Radius.circular(7.0))
          ),
          margin: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 6.0),
          child: ListTile(
            leading: Text(
              event.toString().substring(0,2),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 25
              ),
            ),
            title: Row(
              children: <Widget>[
                Icon(
                  FontAwesomeIcons.busAlt
                ),
                Text(event.toString().substring(2),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20
                  ),
                ),
              ],
            ),
          ),
        );
      })
      .toList(),
    );
  }

  _setupVerification() async{
    sharedPreferences = await SharedPreferences.getInstance();

    if(sharedPreferences.getString("id_condutor")!=null && sharedPreferences.getString("id_linha")!=null && sharedPreferences.getString("id_autocarro")!=null){
      _setup = true;
    }else{
      _setup = false;
    }
  }

  Widget _verifyBusLinha(){

    if(linha != null && bus != null){
      return Container(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 10.0,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Autocarro                    Linha', 
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("  $bus                      $linha",
              textAlign: TextAlign.left,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.white
                ),  
              ),
            ),
          ],
        ),
      );
    }
    else{
      return Container();
    }
  }

  _functionColor(var expression){

    // if expression tem um numero e depois espaço tira o espaço
    // if expression não tem espaço meter espaço
    if(expression.toString().substring(1) == " "){
      expression = expression.toString().substring(0,1);
    }

    switch (expression) {
      case '1':
        _color = Colors.red[700];
      break;
      case '2':
        _color = Colors.lightGreen;
      break;
      case '3':
        _color = Colors.lightBlue;
      break;
      case '4':
        _color = Colors.blue[800];
      break;
      case '5':
        _color = Colors.green[800];
      break;
      case '6':
        _color = Colors.pink[300];
      break;
      case '7':
        _color = Colors.yellow[600];
      break;
      case '8':
        _color = Colors.orange[700];
      break;
      case '9':
        _color = Colors.black;
      break;
      default:
        _color = Colors.teal;
      break;
    }
  }

  Future<Null> _handleRefresh() async {

    await new Future.delayed(new Duration(seconds: 2));

    setState(() {
      _getSchedule();
    });

    return null;
  }

  _getSchedule() async {
    sharedPreferences = await SharedPreferences.getInstance();
    
    var url = 'http://'+ DotEnv().env['IP_ADDRESS']+'/api/getHorarios/' + sharedPreferences.getString("id_condutor");
    String linha;
    String autocarro;
    String horaInicio;
    String horaFim;

    try {      
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      
      if(response.statusCode==200){
        var dados = jsonDecode(response.body);

        if(response.body[1]=="]"){ //ou seja a resposta é só []
          print("Não há nada agendado para hoje");
          setState(() {
            _selectedEvents = null;
          });
          return; //nao ha nada para fazer nesta funcao entao
        }else{
          _events = new List.generate(dados.length, (i) => i + 1);
          for (var i=0; i<dados.length; i++) {
            autocarro = (dados[i]['id_autocarro']).toString();
            linha = (dados[i]['id_linha']).toString();
            horaInicio = dados[i]['hora_inicio'].toString().substring(0,2) + 'h' + dados[i]['hora_inicio'].toString().substring(3,5);
            horaFim = dados[i]['hora_fim'].toString().substring(0,2) + 'h' + dados[i]['hora_fim'].toString().substring(3,5);

            if(autocarro.length > 2){
              _events[i] = linha + '  ' + autocarro + '     ' + horaInicio + " - " + horaFim;
            }else if(autocarro.length == 2){
              _events[i] = linha + '  ' + autocarro + '       ' + horaInicio + " - " + horaFim;
            }else{
              _events[i] = linha + '  ' + autocarro + '         ' + horaInicio + " - " + horaFim;
            }
            
            setState(() {
              _selectedEvents = _events;
            });
          }
        }
      }
    }catch(e){
      print(e);
    }

  }

}
