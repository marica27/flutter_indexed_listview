import 'package:flutter/material.dart';
import 'indexed.listview.dart';
import 'dart:math';
import 'dart:async';

void main() => runApp(new MyApp());

  List<double> _kHeights = new List<double>.generate(100, (int index){
    var random = new Random();
    return random.nextInt(10) * 10.0 + 20.0;
  });


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
    _selectedIndex = null;
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
      body: new IndexedListView(
        initalIndex: _selectedIndex,
        controller: controller,
        itemBuilder: _itemBuilder,
      ),
    );
  }

  _showDialog(BuildContext context) {
    final controller = TextEditingController();
    FocusNode focusNode = new FocusNode();

    showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          new Future.delayed(new Duration(milliseconds: 300), () {
            FocusScope.of(context).requestFocus(focusNode);
          } );

          return new AlertDialog(
            title: new Text("Jump to index"),
            content: new TextField(
              focusNode: focusNode,
              controller: controller,
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
                    Navigator.pop(context, int.parse(controller.text));
                  })
            ],
          );
        }).then((int index) {
      setState(() {
        _selectedIndex = index;
      });
    });
  }

  Widget _itemBuilder(BuildContext context, int index) {
    print("_itemBuilder index=$index offset=${controller.position.pixels}" );
    double height = _kHeights[index % _kHeights.length];
    return new Padding(
        padding: EdgeInsets.all(4.0),
        child: new Material(
            color: index % 2 == 0 ? Colors.lightGreen[100] : Colors.yellow[100],
            elevation: 4.0,
            child: new Container(
                //margin: EdgeInsets.all(14.0),
                height: height,
                child: new Align(
                    alignment: Alignment.centerLeft,
                    child: new Text("$index: ${height.floor()}")))));
  }
}