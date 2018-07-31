import 'package:flutter/material.dart';
import 'indexed.listview.dart';
import 'dart:math';
import 'dart:async';

import 'dividedlistview.dart';

void main() => runApp(new MyApp());

void main1() {
  runApp(new MaterialApp(
    home: new HomePage(),
  ));
}

List<double> _kHeights = [
  60.0,
  100.0,
  110.0,
  100.0,
  70.0,
  40.0,
  50.0,
  20.0,
  110.0,
  80.0,
  70.0,
  60.0,
  110.0,
  50.0,
  40.0,
  20.0,
  50.0,
  50.0,
  40.0,
  30.0,
  40.0,
  30.0,
  80.0,
  40.0,
  40.0,
  60.0,
  60.0,
  50.0,
  90.0,
  20.0,
  100.0,
  40.0,
  100.0,
  50.0,
  20.0,
  80.0,
  90.0,
  40.0,
  60.0,
  110.0,
  70.0,
  100.0,
  80.0,
  80.0,
  70.0,
  90.0,
  30.0,
  90.0,
  80.0,
  100.0,
  90.0,
  110.0,
  80.0,
  100.0,
  70.0,
  110.0,
  70.0,
  40.0,
  20.0,
  80.0,
  80.0,
  50.0,
  50.0,
  90.0,
  50.0,
  90.0,
  70.0,
  50.0,
  30.0,
  20.0,
  110.0,
  70.0,
  60.0,
  110.0,
  50.0,
  80.0,
  50.0,
  110.0,
  20.0,
  50.0,
  30.0,
  40.0,
  40.0,
  30.0,
  70.0,
  70.0,
  100.0,
  100.0,
  90.0,
  50.0,
  30.0,
  40.0,
  80.0,
  90.0,
  50.0,
  20.0,
  50.0,
  90.0,
  20.0,
  80.0
];
//new List<double>.generate(100, (int index) {
//  var random = new Random();
//  return random.nextInt(10) * 10.0 + 20.0;
//});

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    print("_kHeights $_kHeights");
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.lightGreen,
      ),
      home: new MyHomePage(title: 'Indexed List View'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  String title;


  MyHomePage({this.title});

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex;
  ScrollController controller;

  @override
  void initState() {
    _selectedIndex = 0;
    controller = new ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    print("_selectedIndex=${_selectedIndex}");
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: new Icon(Icons.forward),
            onPressed: () => _showDialog(context),
          )
        ],
      ),
      body: new DividedListView.builder(
        key: new GlobalObjectKey("DividedListView${_selectedIndex}"),
        startIndex: _selectedIndex,
        itemBuilder: _itemBuilder,
      ),
    );
  }

  _showDialog(BuildContext context) {
    final textController = TextEditingController();
    FocusNode focusNode = new FocusNode();

    showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          new Future.delayed(new Duration(milliseconds: 300), () {
            FocusScope.of(context).requestFocus(focusNode);
          });

          return new AlertDialog(
            title: new Text("Jump to index"),
            content: new TextField(
              focusNode: focusNode,
              controller: textController,
              keyboardType: TextInputType.numberWithOptions(),
            ),
            actions: <Widget>[
              new FlatButton(
                  child: const Text('cansel'),
                  onPressed: () {
                    Navigator.pop(context, null);
                  }),
              new FlatButton(
                  child: const Text('ok'),
                  onPressed: () {
                    Navigator.pop(context, int.parse(textController.text));
                  })
            ],
          );
        }).then((int index) {
      if (index != null) {
        setState(() {
          _selectedIndex = index;
          //controller.jumpTo(index * 10.0);
        });
      }
    });
  }

  Widget _itemBuilder(BuildContext context, int index) {
    print("_itemBuilder index=$index ");
    double height = _kHeights[index % _kHeights.length];
    return new Padding(
        padding: EdgeInsets.all(4.0),
        child: new Material(
            color: index % 2 == 0 ? Colors.lightGreen[100] : Colors.yellow[100],
            elevation: 4.0,
            child: new Container(
                //margin: EdgeInsets.all(14.0),
                height: height,
                child: new Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: new Align(
                        alignment: Alignment.centerLeft,
                        child: new Text("$index: h${height.floor()}.0"))))));
  }
}
