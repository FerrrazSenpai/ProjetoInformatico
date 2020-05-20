import 'package:flutter/material.dart';
import 'package:passageiroapp/um.dart';
import 'package:passageiroapp/map.dart';
import 'login.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future main() async {
  await DotEnv().load('.env');  //Use - DotEnv().env['IP_ADDRESS'];
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.black,
        accentColor: Colors.white,
      ),
      home: MyHomePage(title: 'App Passageiro'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  SharedPreferences sharedPreferences;
  int _selectedTab = 2;

  @override
  void initState() {
    super.initState();
    Future(() {
      checkLoginStatus();
    });
 }

  checkLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();

    if(sharedPreferences.getBool("checkBox")==null || !sharedPreferences.getBool("checkBox")){
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => LoginPage()), (Route<dynamic> route) => false);
    }else if (sharedPreferences.getString("access_token") == null) {
      sharedPreferences.remove("access_token");
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => LoginPage()), (Route<dynamic> route) => false);
    }
    else{
      //
    }
  }

  GoogleMapController mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.exit_to_app),
              onPressed: 
                onPressLogout,
          ),
        ],
      ),*/
      //body: _pageOptions[_selectedTab],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,

        currentIndex: _selectedTab,
        onTap: (int index) {
            setState(() {
            _selectedTab = index;
          });
        },

        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            title: Text('Menu'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            title: Text('Home'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            title: Text('Map'),
          ),
          //SizedBox(width: 48),
          BottomNavigationBarItem(
            icon: Icon(Icons.hd),
            title: Text('Home'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pages),
            title: Text('Home'),
          ),
        ]
      ),
      body: 
      IndexedStack(
        children: <Widget>[
          UmPage(),
          UmPage(),
          MapPage(),
          UmPage(),
          UmPage(),
        ],
      index: _selectedTab,
     ),
    );
  }

  onPressLogout() async {
    sharedPreferences = await SharedPreferences.getInstance();
    
      sharedPreferences.clear();
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => LoginPage()), (Route<dynamic> route) => false);
  }
}
