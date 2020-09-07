import 'dart:io';
import 'package:flutter/material.dart';
import 'package:passageiroapp/drawer.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:passageiroapp/localNotifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:passageiroapp/connectivity.dart';
import 'dart:convert';
import 'dart:async';
import 'package:geolocator/geolocator.dart';



class MyMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.black,
        accentColor: Colors.white,
      ),
      home: MapPage(title: 'App Passageiro'),
    );
  }
}

class MapPage extends StatefulWidget {
  MapPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin{
  SharedPreferences sharedPreferences;
  
  BitmapDescriptor _sourceIcon;
  double _markerToastPosition = -200;
  bool _loginStatus = false;
  var _userPosition;
  AnimationController _controller;
  Animation _myAnimation;
  String timeRecord="Clique na linha para obter a previsão";
  GoogleMapController mapController;
  Set<Marker> markers = Set();
  Set<Marker> markersAPI = Set();
  List linhasParagem = List();
  var _selectedParagemID;
  var _selectedParagemName="";
  bool _loadingPrediction = false;
  final LatLng _estg = const LatLng(39.733222, -8.821096); //coordenadas estg
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Color _color = Colors.teal;

  void _setSourceIcon() async {
    //preparar o icon das paragens
    _sourceIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5), 'assets/paragem.png');
  }

  void _initForAnimation(){
    //preparar as coisas para a animação inicial do mapa
    _controller = AnimationController(vsync: this,duration: Duration(milliseconds: 2000),);
    _myAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();    
  }
  
  @override
  void initState() {
    super.initState();
    _initForAnimation();
    _userLocation();
    _setSourceIcon();
    _getMarkers();
    _updateNotifications();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    
    _checkLoginStatus();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 0.0,
        title: Text(widget.title),
        backgroundColor: Colors.black
      ),
      body: _userPosition == null ? Container(
        child: Center(
          child: FadeTransition(
            opacity: _myAnimation,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                  image: new DecorationImage(
                      image: new AssetImage(
                        'assets/maps_logo.png',
                      )
                  )
              ),
            ),
          )
        )
      )
      : Container(
       child: ConnectivityPage(
        widget: Stack(
          children: <Widget>[
            GoogleMap(
              onMapCreated: _onMapCreated,
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              initialCameraPosition: CameraPosition(
                target:  _userPosition,
                zoom: 17.0,
              ),

              onTap: (LatLng location) {
                setState(() {
                  _markerToastPosition = -200;
                  timeRecord="Clique na linha para obter a previsão";
                  _loadingPrediction=false;
                });
              },
              markers: Set.from(markersAPI),
            ),
            AnimatedPositioned(
              bottom: _markerToastPosition,
              right: 0,
              left: 0,
              duration: Duration(milliseconds: 200),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  //margin: EdgeInsets.all(20),
                  margin: EdgeInsets.symmetric(vertical: 25, horizontal:10),
                  height: 125,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black45,
                      width: 2.0
                    ),
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        blurRadius: 30,
                        offset: Offset.zero,
                        color: Colors.grey.withOpacity(0.50),
                      )
                    ]
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _buildLocationInfo(),
                    ],
                  ),
                ),
              ),
            )
          ],
        )
      )),
      drawer: DrawerPage(loginStatus: _loginStatus,),
    );
  }

  _getMarkers() async {
    sharedPreferences = await SharedPreferences.getInstance();
    
    final String url = 'https://'+ DotEnv().env['IP_ADDRESS']+'/api/linhasParagens';
    try {      
      final response = await http.get(url,).timeout(const Duration(seconds: 7));
      if(response.statusCode==200){
        var markers =jsonDecode(response.body);
        for (var i=0; i<markers.length; i++){
          var auxlinhas = markers[i]['linhas'];

          setState(() {
            markersAPI.add(
              Marker(
              markerId: MarkerId(markers[i]['id_paragem'].toString()),
              position: LatLng(double.parse(markers[i]['latitude']),double.parse(markers[i]['longitude'])),
              icon: _sourceIcon,
              onTap: (){
                setState(() {
                  timeRecord="Clique na linha para obter a previsão";
                  _selectedParagemID = markers[i]['id_paragem'].toString();
                  _selectedParagemName = markers[i]['nome'].toString();
                  linhasParagem= auxlinhas;
                  _markerToastPosition = 0;
                  _loadingPrediction=false;
                });
              }),
            );
          });
        }
      }else{
        print(response.statusCode);
        setState(() {
          _scaffoldKey.currentState.showSnackBar(SnackBar( content: Text("O servidor não enviou as paragens!"),));
        });
      }
    }catch(e){
      print(e);
      setState(() {
        _scaffoldKey.currentState.showSnackBar(SnackBar( content: Text("O servidor não enviou as paragens!"),));
      });
    }
  }

  Widget _buildLocationInfo() {
    List<Widget> widgets = [];
    
    for(var linha in linhasParagem){
      _functionColor(linha['id_linha']);
      widgets.add(
        Padding(
          padding: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
          child: Row(
            children: <Widget>[
              ButtonTheme(
                minWidth: 110,
                height: 30.0,
                child: RaisedButton(
                  onPressed: (){
                    getTime(linha['id_linha'].toString(), _selectedParagemID);
                    
                    if(timeRecord!="A carregar ..."){ 
                        setState(() {
                          timeRecord="A carregar ...";
                          _loadingPrediction=true;
                        });
                    }else{//caso já estivesse a carregar, limpar o texto, usar um delay de 50 milisegundos para o utilizador conseguir ver o texto a alterar, voltar a escrever o texto
                      setState(() {
                        _loadingPrediction=false;
                        timeRecord=" ";
                      });
                      Timer(Duration(milliseconds: 50), () {
                        setState(() {
                          timeRecord="A carregar ...";
                          _loadingPrediction=true;
                        });
                      });
                    }
                  },
                  color: _color,
                  padding: EdgeInsets.all(2.0),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: Colors.black45,
                      width: 1.5
                    )
                  ),
                  child: Row(
                    children: [ 
                      Text("Linha "+linha['id_linha'].toString(), 
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5
                        )
                      )
                    ],
                  )
                )
              ),
            ],
          ),
        ),
      );
    }
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(left: 20,right: 20,top:10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          
          children: <Widget>[
            Center(
              child: Text(
                _selectedParagemName,  
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0
                ),
              )
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ...widgets  //lista dos botões de cada linha existente na paragem
                ]
              )
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget> [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(timeRecord, textAlign:TextAlign.center,),
                      padding: EdgeInsetsDirectional.only(bottom:7),
                    ),
                  ),
                  _loadingPrediction == true ? Flexible(
                    child: SizedBox(
                      child: CircularProgressIndicator(
                        strokeWidth: 2, backgroundColor: Colors.blue[400],
                      ),
                      height: 12.0, width: 12.0, 
                    )
                  ) : Container(),
                ],
              )
            ),
          ],
        ),
      ),
    );
  }

  void _userLocation() async {
    //obter as coordenadas atuais do utilizador para focar na sua localização
    //como estamos em casa o foco está na estg em vez de na localização do utilizador, por isso o codigo de focar no utilizador está comentado
    try{      
      //Position usrCurrentPosition = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        //_userPosition = LatLng(usrCurrentPosition.latitude, usrCurrentPosition.longitude);
        _userPosition = _estg; //centrar na estg porque com a quarentena a nossa localização atual é em casa; com isto a app vai abrir logo em Leiria e evitamos andar a dar scroll para lá chegar
      });
    }catch(e){
      _scaffoldKey.currentState.showSnackBar(SnackBar( content: Text("Ao não ativar a localização vai perder algumas funcionalidades!"),));
      setState(() {
        _userPosition = _estg; //ao nao ter permissoes de localização vai centar na estg
      });
    }
  }
  
  getTime(String linha, String paragemID) async {
    //obter a previsao que falta ate chegar um autocarro de X linha a Y paragem
    sharedPreferences = await SharedPreferences.getInstance();
    String url = 'https://'+ DotEnv().env['IP_ADDRESS']+'/api/tempo/'+paragemID+'/'+linha;

    try {      
      final response = await http.get(url,).timeout(const Duration(seconds: 80)); //mais tempo que o normal porque este pedido é bastante mais lento que os outros

      if(response.statusCode==200){
        setState(() {
          timeRecord = response.body;
        });
      }else if(response.statusCode==500){ //quando a linha nao tem autocarros a circular o servidor envia um 500
        setState(() {
          timeRecord = "Sem autocarros a circular";
        });
      }
      else{ //se o statuscode nao for 200 nem 500 o servidor enviou uma resposta inadequada
        setState(() {
          timeRecord = "Problemas no servidor: Tente Novamente";
        }); 
      }
    }
    catch(e){ //se der erro durante o pedido dizemos ao user para tentar novamente; p.e. se o servidor nao responder em tempo util
      print(e);
      setState(() {
          timeRecord = "Tente novamente!";
      }); 
    }

    setState(() {
        _loadingPrediction=false;
    });
  }

  _functionColor(var expression){

    switch (expression.toString()) {
      case '1':
        _color = Colors.lightGreen;
      break;
      case '2':
        _color = Colors.red[700];
      break;
      case '3':
        _color = Colors.lightBlue;
      break;
      case '4':
        _color = Colors.black;
      break;
      default:
        _color = Colors.teal;
      break;
    }
  }

  _checkLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      if(sharedPreferences.getBool("loginStatus") == null || !sharedPreferences.getBool("loginStatus")){
        _loginStatus = false;
      }else{
        _loginStatus = true;
      }
    });
  }
  
  void _updateNotifications() async {
    //depois de um utilizador se logar vamos correr a função para configurar as notificações adequadas aos favoritos dele
    await _checkLoginStatus();
    if(_loginStatus==true){ 
      sharedPreferences = await SharedPreferences.getInstance();
      
      var updateNotifications = sharedPreferences.getBool("update_notifications");
      if(updateNotifications){
        final LocalNotifications notifications = LocalNotifications();
        var notificationsUpdated = await notifications.setNotifications();
        if(!notificationsUpdated){
          _scaffoldKey.currentState.showSnackBar(SnackBar( content: Text("Erro ao atualizar as notifições!"),));
        }else{
          _scaffoldKey.currentState.showSnackBar(SnackBar( content: Text("Notificações atualizadas com sucesso!"),));
          sharedPreferences.setBool("update_notifications",false);
        }
      }
    }
  }

}
