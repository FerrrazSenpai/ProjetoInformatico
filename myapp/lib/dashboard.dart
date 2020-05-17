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

  static const duration = const Duration(minutes: 1);
  bool isActive = false;

  Timer timer;

  List _event;
  List _eventVoid;
  Color _color = Colors.white;
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
      _selectedDay: ['1 9h00-10h10', '4 15h00-16h20', '3 uma hora qualquer'],
      _selectedDay.add(Duration(days: 1)): Set.from(['1 9h00-10h10', '9 15h00-16h20', '2 uma hora qualquer','5 uma hora qualquer','10 uma hora qualquer']).toList(),
      _selectedDay.add(Duration(days: 3)): Set.from(['Event A9', 'Event A9', 'Event B9']).toList(),
      _selectedDay.add(Duration(days: 7)): ['1 9h00-10h10', '5 15h00-16h20', '3 uma hora qualquer'],
      _selectedDay.add(Duration(days: 11)): ['7 9h00-10h10', '2 15h00-16h20','4 CHUPAMOS'],
      _selectedDay.add(Duration(days: 17)): ['Event A12', 'Event B12', 'Event C12', 'Event D12'],
      _selectedDay.add(Duration(days: 22)): ['Event A13', 'Event B13'],
      _selectedDay.add(Duration(days: 26)): ['Event A14', 'Event B14', 'Event C14'],
    };

    _selectedEvents = _events[_selectedDay] ?? [];

    _setupVerification();

  }

  @override
  Widget build(BuildContext context) {
    
    if (timer == null) {
      timer = Timer.periodic(duration, (Timer t) {
        handleTick();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      backgroundColor: Theme.of(context).accentColor,
      body: Container(
        
        child: new ConnectivityPage(
          widget: ListView(        
            children: <Widget>[
              _getProfile(),
              //_buildEventList(),
              _getLocationButton(),
            ],
          ),
        )
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
      margin: EdgeInsets.fromLTRB(30,50,30,10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16.0, // has the effect of softening the shadow
            spreadRadius: 3.0, // has the effect of extending the shadow
            offset: Offset(
              10.0, // horizontal, move right 10
              10.0, // vertical, move down 10
            ),
          )
        ],
        borderRadius: BorderRadius.all(Radius.circular(15.0)),
      ),
      child: Row(
        children: <Widget>[
          Flexible(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text('\nNome: ' + '$nome' + '\n', textAlign: TextAlign.start, style: TextStyle(fontSize: 20)),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text('Email: ' + '$email' + '\n', textAlign: TextAlign.start, style: TextStyle(fontSize: 20),),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text('Data de nascimento: ' + '$dataNascimento' + '\n', textAlign: TextAlign.start, style: TextStyle(fontSize: 20),),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text('Localidade: ' + '$localidade' + '\n', textAlign: TextAlign.start, style: TextStyle(fontSize: 20),),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getLocationButton(){
    var _onPressed;

    if(_setup){
      _onPressed = (){
        setState(() {
          isActive = !isActive;
        });
      };
    }
    return Container(
      padding: EdgeInsets.only(right: 30.0,left: 30.0,top: 20.0),
      child: RaisedButton(
        padding: EdgeInsets.all(15.0),
        elevation: 15,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Text(isActive ? 'Parar o envio de localização' : 'Começar o envio de localização', textAlign: TextAlign.center, style: TextStyle(fontSize: 20),),
        color: Colors.white,
        onPressed: _onPressed,
        disabledColor: Colors.white70,
        disabledTextColor: Colors.red[900],
      ),
    );
  }

  Widget _buildEventList() {
    return Column(
      children: _selectedEvents
      .map((event) {
        switch (event.toString().substring(0,2)) {
          case '1 ':
            _color = Colors.red;
          break;
          case '2 ':
            _color = Colors.lightGreen;
          break;
          case '3 ':
            _color = Colors.blue[300];
          break;
          case '4 ':
            _color = Colors.blue[900];
          break;
          case '5 ':
            _color = Colors.deepPurpleAccent;
          break;
          case '6 ':
            _color = Colors.pink;
          break;
          case '7 ':
            _color = Colors.yellow[600];
          break;
          case '8 ':
            _color = Colors.orange;
          break;
          case '9 ':
            _color = Colors.black;
          break;
          case '10':
            _color = Colors.teal;
          break;
          default:
            _color = Colors.white;
          break;
        }
        var container = Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              stops: [0.11, 0.02],
              colors: [_color, Colors.white]
            ),
            borderRadius: BorderRadius.all(Radius.circular(10.0))
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
            title: Text(
              event.toString().substring(2),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20
              ),
            ),
            onTap: () => print('$event tapped!'),
          ),
        );return container;
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
}
