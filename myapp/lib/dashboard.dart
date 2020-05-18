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

  static const duration = const Duration(minutes: 1);
  bool isActive = false;

  Timer timer;

  Color _color = Colors.teal;
  Map<DateTime, List> _events;
  List _selectedEvents;

  bool _setup = false;

  void handleTick() {
    if (isActive) {
      _getLocation().then((value) {
        setState(() {
          userLocation = value;
          // 1m/s -> 3.6km/h  speed -> speedkmh
          speedkmh = userLocation.speed.toDouble() * 3.600;
          time = DateTime.fromMillisecondsSinceEpoch(userLocation.time.toInt());
          _postLocation();
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    //_getUserData();
    _getUserData2();

    final _selectedDay = DateTime.now();
    _events = {
      _selectedDay.subtract(Duration(days: 30)): ['Event A0', 'Event B0', 'Event C0'],
      _selectedDay.subtract(Duration(days: 27)): ['Event A1'],
      _selectedDay.subtract(Duration(days: 20)): ['Event A2', 'Event B2', 'Event C2', 'Event D2'],
      _selectedDay.subtract(Duration(days: 16)): ['Event A3', 'Event B3'],
      _selectedDay.subtract(Duration(days: 10)): ['10 9h00-10h10', '7 15h00-16h20'],
      _selectedDay.subtract(Duration(days: 4)): ['3 9h00-10h10'],
      _selectedDay.subtract(Duration(days: 2)): ['6 9h00-10h10', '7 15h00-16h20', '8 uma hora qualquer'],
      _selectedDay: ['7 9h00-10h10', '8 15h00-16h20', '3 uma hora qualquer'],
      _selectedDay.add(Duration(days: 1)): Set.from(['8 9h00-10h10', '9 15h00-16h20', '2 uma hora qualquer','10 uma hora qualquer']).toList(),
      _selectedDay.add(Duration(days: 3)): Set.from(['5 uma hora qualquer']).toList(),
      _selectedDay.add(Duration(days: 7)): ['1 9h00-10h10', '5 15h00-16h20', '3 uma hora qualquer'],
      _selectedDay.add(Duration(days: 11)): ['7 9h00-10h10', '2 15h00-16h20','4 16h20-17h00'],
      _selectedDay.add(Duration(days: 17)): ['Event A12', 'Event B12', 'Event C12', 'Event D12'],
      _selectedDay.add(Duration(days: 22)): ['Event A13', 'Event B13'],
      _selectedDay.add(Duration(days: 26)): ['Event A14', 'Event B14', 'Event C14'],
    };

    _selectedEvents = _events[_selectedDay.add(Duration(days: 2))] ?? null;

    print(_selectedEvents);

    _setupVerification();

    _functionColor(linha);
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
        title: Text(widget.title, style: TextStyle(color: _color == Colors.black ? Colors.white : Colors.black, fontWeight: FontWeight.bold),),
        backgroundColor: _color,
        iconTheme: new IconThemeData(color: _color == Colors.black ? Colors.white : Colors.black),
      ),
      backgroundColor: Theme.of(context).accentColor,
      body: Container(
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
        http.post(
          url,
          headers: {
            'Accept' : 'application/json',
            'Authorization' : "Bearer " + sharedPreferences.getString("access_token"),
          },
          body: body,
        );
    print(response.body);
    //print(body);
    return response.body;
    
  }

  _getUserData() async {
    sharedPreferences = await SharedPreferences.getInstance();
    String dia;
    String ano;
    String mes;
    var url = 'http://'+ DotEnv().env['IP_ADDRESS']+'/api/profile';
    try {      
      final response = 
      await 
      http.get(
        url, 
        headers: {'Authorization': "Bearer " + sharedPreferences.getString("access_token")},
      ).timeout(const Duration(seconds: 15));
      print("status code: " + response.statusCode.toString() );
      if(response.statusCode==200){
        var dados = jsonDecode(response.body);
        print(dados);
        setState(() {
          nome = dados['name'];
          email = dados['email'];
          dataNascimento = dados['data_nascimento'];
          localidade = dados['localidade'];

          if(dataNascimento != null ){
            ano = dataNascimento.substring(0,4);
            dia = dataNascimento.substring(8,10);
            mes = dataNascimento.substring(5,7);
            dataNascimento = dia + '-' + mes + '-' + ano;
            print(dataNascimento);
          }else{
            dataNascimento = 'Desconhecida';
          }

          if (localidade != null ){
            print(localidade);
          }else{
            localidade = 'Desconhecida';
          }
          print(nome);
          print(email);
          print(dataNascimento);
          print(localidade);
          
        });
      }
    }catch(e){
      print(e);
    }
  }

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
        print(dataNascimento);
      }else{
        dataNascimento = 'Desconhecida';
      }

      if (localidade != null ){
        print(localidade);
      }else{
        localidade = 'Desconhecida';
      }
    });
  }

  Widget _getProfile(){
    return Container(
      margin: EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 25.0),
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
                  height:5.0
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
      _onPressed = (){
        setState(() {
          isActive = !isActive;
        });
      };
    }
    return Container(
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
              stops: [0.11, 0.02],
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
                fontSize: 22
              ),
            ),
            title: Text(
              event.toString().substring(2),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19
              ),
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
        _color = Colors.blue[300];
      break;
      case '4':
        _color = Colors.blue[900];
      break;
      case '5':
        _color = Colors.deepPurpleAccent;
      break;
      case '6':
        _color = Colors.pink[300];
      break;
      case '7':
        _color = Colors.yellow[700];
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
}
