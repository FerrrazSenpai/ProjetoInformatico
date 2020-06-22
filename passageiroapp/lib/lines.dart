import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:passageiroapp/drawer.dart';

class LinesPage extends StatefulWidget {

  _LinesPageState createState()=> _LinesPageState();
}

class _LinesPageState extends State<LinesPage>{
  SharedPreferences sharedPreferences;

  List _events = ["1","2","3"];
  Color _color = Colors.teal;
  bool _loginStatus = false;
  bool favorite = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    
    _checkLoginStatus();

    return Scaffold(
      appBar: AppBar(
        title: Text("Linhas"),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        children: <Widget>[
          SizedBox(
            height: 15.0,
          ),
          _listLines(),
        ],
      ),
      drawer: DrawerPage(loginStatus: _loginStatus,),
    );
  }   

  Widget _listLines(){

    return Column(
      children: _events
      .map((event) {
        _functionColor(event.toString().substring(0,1));
        
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black38
            ),
            gradient: LinearGradient(
              stops: [0.35, 0.02],
              colors: [_color, Colors.white]
            ),
            borderRadius: BorderRadius.all(Radius.circular(7.0))
          ),
          margin: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 6.0),
          child: GestureDetector(
            onDoubleTap: (){
              setState(() {
                favorite = true;
              });
            },
            child: ListTile(
              leading: Text(
                " Linha " + event.toString().substring(0,1),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 25
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _loginStatus ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: IconButton(
                      icon: Icon(
                        favorite ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                        color: favorite ? Colors.red[700] : Colors.black,
                      ),
                      onPressed: (){
                        setState(() {
                          favorite = favorite ? false : true;
                        });
                      },
                    ),
                  ) : SizedBox(),
                  Icon(
                    FontAwesomeIcons.chevronDown,
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
          ),
        );
      })
      .toList(),
    );
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
}