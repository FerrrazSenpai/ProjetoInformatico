import 'package:app_condutor/drawer.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:app_condutor/connectivity.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:date_format/date_format.dart';

class SchedulePage extends StatefulWidget {
  SchedulePage({Key key, this.color}) : super(key: key);

  final Color color;
  @override
  SchedulePageStateState createState() => SchedulePageStateState();
}

class SchedulePageStateState extends State<SchedulePage>
    with TickerProviderStateMixin {
  CalendarController _calendarController;
  Map<DateTime, List> _events;
  List _selectedEvents;
  Color _color = Colors.teal;
  bool connected;

  String linha;
  SharedPreferences sharedPreferences;
  DateTime _selectedDay;
  List _eventsDaily;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    _calendarController = CalendarController();

    _events = {};

    _getSchedule();

    _selectedEvents = _events[_selectedDay] ?? [];
  }

  void _onDaySelected(DateTime day, List events) {
    setState(() {
      _selectedEvents = events;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Horário',
          style: TextStyle(
              color: widget.color == Colors.black ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22),
        ),
        backgroundColor: widget.color,
        iconTheme: new IconThemeData(
            color: widget.color == Colors.black ? Colors.white : Colors.black),
      ),
      backgroundColor: Theme.of(context).accentColor,
      body: RefreshIndicator(
        child: Container(
            child: new ConnectivityPage(
          widget: ListView(
            children: <Widget>[
              _buildTableCalendar(),
              Divider(
                color: Colors.transparent,
                height: 20,
              ),
              _buildEventList(),
            ],
          ),
        )),
        onRefresh: _handleRefresh,
      ),
      drawer: new DrawerPage(page: "schedule"),
    );
  }

  // More advanced TableCalendar configuration (using Builders & Styles)
  Widget _buildTableCalendar() {
    return TableCalendar(
      locale: 'pt_PT',
      calendarController: _calendarController,
      formatAnimation: FormatAnimation.scale,
      events: _events,
      availableGestures: AvailableGestures.horizontalSwipe,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Mês',
        CalendarFormat.week: 'Semana',
      },
      calendarStyle: CalendarStyle(
        outsideStyle: TextStyle(color: Colors.grey),
        unavailableStyle: TextStyle(color: Colors.grey),
        outsideWeekendStyle: TextStyle(color: Colors.grey),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        dowTextBuilder: (date, locale) {
          return DateFormat.E(locale)
              .format(date)
              .substring(0, 3)
              .toUpperCase();
        },
        weekdayStyle: TextStyle(color: Colors.grey),
        weekendStyle: TextStyle(color: Colors.grey),
      ),
      headerStyle: HeaderStyle(
          centerHeaderTitle: false,
          headerMargin: EdgeInsets.all(5.0),
          formatButtonDecoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(8.0),
          ),
          formatButtonPadding:
              EdgeInsets.only(right: 15.0, left: 15.0, top: 5, bottom: 5),
          formatButtonShowsNext: false,
          formatButtonTextStyle: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
          leftChevronIcon: Icon(Icons.arrow_back_ios, color: Colors.white70),
          rightChevronIcon:
              Icon(Icons.arrow_forward_ios, color: Colors.white70),
          titleTextStyle: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.white)),
      onDaySelected: _onDaySelected,
      startingDayOfWeek: StartingDayOfWeek.monday,
      builders: CalendarBuilders(
        selectedDayBuilder: (context, date, events) => Container(
          margin: const EdgeInsets.all(3.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(6.0)),
          child: Text(date.day.toString(),
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17.5)),
        ),
        todayDayBuilder: (context, date, events) => Container(
          margin: const EdgeInsets.all(5.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Colors.grey[700],
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(6.0)),
          child: Text(date.day.toString(),
              style: TextStyle(
                color: Colors.white,
              )),
        ),
        dayBuilder: (context, date, events) => Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(6.0)),
          child: Text(date.day.toString(),
              style: TextStyle(
                color: Colors.white,
              )),
        ),
        outsideDayBuilder: (context, date, events) => Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(6.0)),
          child: Text(date.day.toString(),
              style: TextStyle(
                color: Colors.grey,
              )),
        ),
        outsideWeekendDayBuilder: (context, date, events) => Container(
          margin: const EdgeInsets.all(5.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(6.0)),
          child: Text(date.day.toString(),
              style: TextStyle(
                color: Colors.white38,
              )),
        ),
        markersBuilder: (context, date, events, holidays) {
          final children = <Widget>[];
          if (events.isNotEmpty) {
            children.add(
              Positioned(
                right: 1,
                bottom: 1,
                child: _buildEventsMarker(date, events),
              ),
            );
          }
          return children;
        },
      ),
    );
  }

  Widget _buildEventsMarker(DateTime date, List events) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(6.0),
        color: _calendarController.isSelected(date)
            ? Colors.grey[700]
            : _calendarController.isToday(date)
                ? (widget.color == Colors.red[700]
                    ? Colors.teal[400]
                    : Colors.red[400])
                : widget.color,
      ),
      width: 18.0,
      height: 18.0,
      child: Center(
        child: Text(
          '${events.length}',
          style: TextStyle().copyWith(
            color: _calendarController.isSelected(date)
                ? Colors.white
                : _calendarController.isToday(date)
                    ? Colors.white
                    : (widget.color == Colors.black
                        ? Colors.white
                        : Colors.black),
            fontWeight: FontWeight.bold,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }

  Widget _buildEventList() {
    return Column(
      children: _selectedEvents.map((event) {
        _functionColor(event.toString().substring(0, 2));

        var container = Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  stops:
                      MediaQuery.of(context).orientation == Orientation.portrait
                          ? [0.12, 0.02]
                          : [0.07, 0.02],
                  colors: [_color, Colors.white]),
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          margin: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 6.0),
          child: ListTile(
            leading: Text(
              event.toString().substring(0, 2),
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 25),
            ),
            title: Row(
              children: <Widget>[
                Icon(FontAwesomeIcons.busAlt),
                Text(
                  event.toString().substring(2),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
          ),
        );
        return container;
      }).toList(),
    );
  }

  _functionColor(var expression) {
    if (expression.toString().substring(1) == " ") {
      expression = expression.toString().substring(0, 1);
    }

    switch (expression) {
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
      // case '5':
      //   _color = Colors.green[800];
      // break;
      // case '6':
      //   _color = Colors.pink[300];
      // break;
      // case '7':
      //   _color = Colors.yellow[600];
      // break;
      // case '8':
      //   _color = Colors.orange[700];
      // break;
      // case '9':
      //   _color = Colors.black;
      // break;
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

    var url = 'http://' +
        DotEnv().env['IP_ADDRESS'] +
        '/api/getHorariosTodos/' +
        sharedPreferences.getString('id_condutor');

    String linha;
    String autocarro;
    String horaInicio;
    String horaFim;
    var count = 0;
    var count2;

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _events = {};
        var dados = jsonDecode(response.body);

        if (response.body[1] == "]") {
          //ou seja a resposta é só []
          print("Não há nada agendado");
          setState(() {
            _selectedEvents = [];
          });
          return; //nao ha nada para fazer nesta funcao entao
        } else {
          for (var i = 0; i < dados.length; i++) {
            _selectedDay = DateTime.parse(dados[i]['data']);
            count2 = 0;
            count = 0;

            if (!_events.containsKey(_selectedDay)) {
              for (var j = 0; j < dados.length; j++) {
                // linha = (dados[j]['id_linha']).toString();
                // horaInicio = dados[j]['hora_inicio'].toString().substring(0,2) + 'h' + dados[j]['hora_inicio'].toString().substring(3,5);
                // horaFim = dados[j]['hora_fim'].toString().substring(0,2) + 'h' + dados[j]['hora_fim'].toString().substring(3,5);
                if (dados[i]['data'] == dados[j]['data']) {
                  count++;
                }
              }
              _eventsDaily = new List.generate(count, (i) => i + 1);
              while (count2 != count) {
                for (var k = 0; k < dados.length; k++) {
                  if (dados[i]['data'] == dados[k]['data']) {
                    autocarro = (dados[k]['id_autocarro']).toString();
                    linha = (dados[k]['id_linha']).toString();
                    horaInicio =
                        dados[k]['hora_inicio'].toString().substring(0, 2) +
                            'h' +
                            dados[k]['hora_inicio'].toString().substring(3, 5);
                    horaFim = dados[k]['hora_fim'].toString().substring(0, 2) +
                        'h' +
                        dados[k]['hora_fim'].toString().substring(3, 5);

                    if (autocarro.length > 2) {
                      _eventsDaily[count2] = linha +
                          '  ' +
                          autocarro +
                          '     ' +
                          horaInicio +
                          " - " +
                          horaFim;
                    } else if (autocarro.length == 2) {
                      _eventsDaily[count2] = linha +
                          '  ' +
                          autocarro +
                          '       ' +
                          horaInicio +
                          " - " +
                          horaFim;
                    } else {
                      _eventsDaily[count2] = linha +
                          '  ' +
                          autocarro +
                          '         ' +
                          horaInicio +
                          " - " +
                          horaFim;
                    }

                    count2++;
                  }
                }
              }
              _events[_selectedDay] = _eventsDaily;
              _eventsDaily = [];
            }
          }

          setState(() {
            DateTime now = DateTime.parse(
                formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd]));
            _selectedEvents = _events[now] ?? [];
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }
}
