import 'dart:async';
import 'package:app_condutor/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:connectivity/connectivity.dart';
import 'package:date_format/date_format.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    //getUserData();
    getUserData2();
    
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
      body: Container(
        color: Theme.of(context).accentColor,
        child: Builder(
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
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                );
              },
              child: Stack(        
                fit: StackFit.expand,
                children: <Widget>[
                  //userLocation == null || !connected
                  //? Text("\n\n\n\n\n\nSem valores óbtidos", textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),)
                  //: Text("\n\n\n\n\n\n   " + userLocation.latitude.toString() + "  latitude \n   " + userLocation.longitude.toString() + "  longitude \n    " +
                  //speedkmh.toStringAsFixed(3)+ "  km/h \n   " + formatDate(time, [yyyy,"-",mm,"-",dd," ",HH,":",nn,":",ss]), textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),),
                  Container(
                    margin: EdgeInsets.fromLTRB(30,50,30,150),
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
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(30.0, 570.0, 30.0, 50.0),
                    child: RaisedButton(
                      padding: EdgeInsets.all(8.0),
                      elevation: 15,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Text(isActive ? 'Parar o envio de localização' : 'Começar o envio de localização', textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontSize: 20),),
                      color: Colors.white,
                      onPressed: (){
                        setState(() {
                          isActive = !isActive;
                        });
                      }
                    ),
                  )
                ],
              ),
            );
          },
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

  getUserData() async {
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

  getUserData2() async {
    sharedPreferences = await SharedPreferences.getInstance();

    setState(() {
      
      nome = sharedPreferences.getString("nome");
      email = sharedPreferences.getString("email");
      localidade = sharedPreferences.getString("localidade");
      dataNascimento = sharedPreferences.getString("data_nascimento");

    });

  }

}
