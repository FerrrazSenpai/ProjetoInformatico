import 'package:app_condutor/drawer.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:app_condutor/connectivity.dart';


class SchedulePage extends StatefulWidget {
  SchedulePage({Key key, this.color}) : super(key: key);

  final Color color;
  @override
  schedulePageStateState createState() => schedulePageStateState();
}

class schedulePageStateState extends State<SchedulePage> with TickerProviderStateMixin{
  CalendarController _calendarController;
  Map<DateTime, List> _events;
  List _selectedEvents;
  Color _color = Colors.teal;
  bool connected;

  String linha;
  SharedPreferences sharedPreferences;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    _calendarController = CalendarController();
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
      _selectedDay.add(Duration(days: 1)): Set.from(['8 9h00-10h10', '9 15h00-16h20', '2 uma hora qualquer','5 uma hora qualquer','10 uma hora qualquer']).toList(),
      _selectedDay.add(Duration(days: 3)): Set.from(['Event A9', 'Event A9', 'Event B9']).toList(),
      _selectedDay.add(Duration(days: 7)): ['1 9h00-10h10', '5 15h00-16h20', '3 uma hora qualquer'],
      _selectedDay.add(Duration(days: 11)): ['7 9h00-10h10', '2 15h00-16h20','4 16h20-17h00'],
      _selectedDay.add(Duration(days: 17)): ['Event A12', 'Event B12', 'Event C12', 'Event D12'],
      _selectedDay.add(Duration(days: 22)): ['Event A13', 'Event B13'],
      _selectedDay.add(Duration(days: 26)): ['Event A14', 'Event B14', 'Event C14'],
    };

    _selectedEvents = _events[_selectedDay] ?? [];

    _getLinha();
    _functionColor(linha);
  }

  void _onDaySelected(DateTime day, List events) {
    setState(() {
      _selectedEvents = events;
    });
  }

  @override
  Widget build(BuildContext context) {
    _functionColor(linha);

    return Scaffold(
      appBar: AppBar(
        title: Text('Horário', style: TextStyle(color: widget.color == Colors.black ? Colors.white : Colors.black, fontWeight: FontWeight.bold),),
        backgroundColor: widget.color,
        iconTheme: new IconThemeData(color: widget.color == Colors.black ? Colors.white : Colors.black),
      ),
      backgroundColor: Theme.of(context).accentColor,
      body: Container(
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
        )
      ),
      drawer: new DrawerPage(),
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
        formatButtonPadding: EdgeInsets.only(right: 15.0, left: 15.0, top: 5, bottom: 5),
        formatButtonShowsNext: false,
        formatButtonTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 16
        ),
        leftChevronIcon: Icon(Icons.arrow_back_ios, color: Colors.white70),
        rightChevronIcon: Icon(Icons.arrow_forward_ios, color: Colors.white70),
        titleTextStyle: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: Colors.white
        )
      ),
      onDaySelected: _onDaySelected,
      startingDayOfWeek: StartingDayOfWeek.monday,
      builders: CalendarBuilders(
        selectedDayBuilder: (context, date, events) =>
        Container(
          margin: const EdgeInsets.all(3.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(6.0)
          ),
          child: Text(
            date.day.toString(), 
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17.5
            )
          ),
        ),
        todayDayBuilder: (context, date, events) =>
        Container(
          margin: const EdgeInsets.all(5.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(6.0)
          ),
          child: Text(
            date.day.toString(), 
            style: TextStyle(
              color: Colors.white,
            )
          ),
        ),
        dayBuilder: (context, date, events) =>
        Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(6.0)
          ),
          child: Text(
            date.day.toString(), 
            style: TextStyle(
              color: Colors.white,
            )
          ),
        ),
        outsideDayBuilder: (context, date, events) =>
        Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(6.0)
          ),
          child: Text(
            date.day.toString(), 
            style: TextStyle(
              color: Colors.grey,
            )
          ),
        ),
        outsideWeekendDayBuilder: (context, date, events) =>
        Container(
          margin: const EdgeInsets.all(5.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(6.0)
          ),
          child: Text(
            date.day.toString(), 
            style: TextStyle(
              color: Colors.white38,
            )
          ),
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
          : _calendarController.isToday(date) ? widget.color == Colors.red[700] ? Colors.teal[400] : Colors. red[400]: widget.color,
      ),
      width: 18.0,
      height: 18.0,
      child: Center(
        child: Text(
          '${events.length}',
          style: TextStyle().copyWith(
            color: _calendarController.isSelected(date)
              ? Colors.white
              : _calendarController.isToday(date) ? Colors.white : _color == Colors.black ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }

  Widget _buildEventList() {
    return Column(
      children: _selectedEvents
      .map((event) {
        _functionColor(event.toString().substring(0,2));

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

  _functionColor(var expression){

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

  _getLinha() async {
    sharedPreferences = await SharedPreferences.getInstance();

    setState(() {
      linha = sharedPreferences.getString("id_linha");
      print(linha);
    });
  }
}