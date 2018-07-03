import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(new MaterialApp(
    home: new HomePage(),
  ));
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Wrapping List View'),
      ),
      body: new WrappingListView.builder(
        itemCount: 10,
        itemBuilder: (BuildContext context, Color color, int index) {
          return new Card(
            child: new Container(
              decoration: new BoxDecoration(
                  border: Border.all(color: Colors.black),
                  color: color.withOpacity(index / 10)),
              height: 50.0,
              child: new Center(child: new Text('Card $index')),
            ),
          );
        },
      ),
    );
  }
}

class UnboundedScrollPosition extends ScrollPositionWithSingleContext {
  UnboundedScrollPosition({
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition oldPosition,
    double initialPixels,
  }) : super(
            physics: physics,
            context: context,
            initialPixels: initialPixels,
            oldPosition: oldPosition);

  @override
  double get minScrollExtent => double.negativeInfinity;
}

class UnboundedScrollController extends ScrollController {
  UnboundedScrollController({
    double initialScrollOffset: 0.0,
    keepScrollOffset: true,
    debugLabel,
  }) : super(
            initialScrollOffset: initialScrollOffset,
            keepScrollOffset: keepScrollOffset,
            debugLabel: debugLabel);

  @override
  UnboundedScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition oldPosition,
  ) {
    return new UnboundedScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      initialPixels: initialScrollOffset,
    );
  }
}

//this Wrapping ListView is from original example
//https://stackoverflow.com/questions/44468337/how-can-i-make-a-scrollable-wrapping-view-with-flutter
class WrappingListView extends StatefulWidget {
  factory WrappingListView({Key key, List<Widget> children}) {
    return new WrappingListView.builder(
      itemCount: children.length,
      itemBuilder: (BuildContext context, Color color, int index) {
        return children[index % children.length];
      },
    );
  }

  WrappingListView.builder({Key key, this.itemBuilder, this.itemCount})
      : super(key: key);

  final int itemCount;
  final IndexedColorWidgetBuilder itemBuilder;

  WrappingListViewState createState() => new WrappingListViewState();
}

typedef Widget IndexedColorWidgetBuilder(
    BuildContext context, Color color, int index);

class WrappingListViewState extends State<WrappingListView> {
  UnboundedScrollController _controller =
      new UnboundedScrollController(initialScrollOffset: -100.0);
  UnboundedScrollController _negativeController =
      new UnboundedScrollController(initialScrollOffset: -460.0);

  @override
  void initState() {
    _controller.addListener(() {
      print(
          "listener: ${-_negativeController.position.extentInside} - ${_controller.position.pixels} = ${
          -_negativeController.position.extentInside - _controller.position.pixels}");
      _negativeController.jumpTo(-_negativeController.position.extentInside -
          _controller.position.pixels);
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Stack(
      children: <Widget>[
        new CustomScrollView(
          physics: new AlwaysScrollableScrollPhysics(),
          controller: _negativeController,
          reverse: true,
          slivers: <Widget>[
            new SliverList(
              delegate: new SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                print(
                    "CustomScrollView $index ${_negativeController.position.pixels}");
                return widget.itemBuilder(
                  context,
                  Colors.red,
                  (widget.itemCount - 1 - index) % widget.itemCount,
                );
              }),
            ),
          ],
        ),
        new ListView.builder(
          //reverse: true,
          controller: _controller,
          itemBuilder: (BuildContext context, int index) {
            print("ListView.builder $index ${_controller.position.pixels}");
            return widget.itemBuilder(
                context, Colors.blue, index % widget.itemCount);
          },
        ),
      ],
    );
  }
}

class DividedListView extends StatefulWidget {
  factory DividedListView({
    Key key,
    List<Widget> children,
    int startIndex,
  }) {
    return new DividedListView.builder(
      startIndex: startIndex,
      itemCount: children.length,
      itemBuilder: (BuildContext context, int index) {
        return children[index % children.length];
      },
    );
  }

  DividedListView.builder(
      {Key key, this.itemBuilder, this.itemCount, this.startIndex = 0})
      : assert(startIndex != null),
        super(key: key);

  final int itemCount;
  final int startIndex;
  final IndexedWidgetBuilder itemBuilder;

  DividedListViewState createState() => new DividedListViewState();
}

class DividedListViewState extends State<DividedListView> {
  UnboundedScrollController _controller = new UnboundedScrollController();
  UnboundedScrollController _negativeController =
      new UnboundedScrollController();

  @override
  void initState() {
    _controller.addListener(() {
      _negativeController.jumpTo(-_negativeController.position.extentInside -
          _controller.position.pixels);
    });
  }

  @override
  Widget build(BuildContext context) {
    print("DividedListViewState index=${widget.startIndex}");
    return new Stack(
      children: <Widget>[
        new CustomScrollView(
          physics: new AlwaysScrollableScrollPhysics(),
          controller: _negativeController,
          reverse: true,
          slivers: <Widget>[
            new SliverList(
              delegate: new SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                print(
                    "CustomScrollView $index ${_negativeController.position.pixels}");
                return widget.itemBuilder(
                  context,
                  widget.startIndex - index - 1,
                );
              }),
            ),
          ],
        ),
        new ListView.builder(
          controller: _controller,
          itemBuilder: (BuildContext context, int index) {
            print("ListView.builder $index ${_controller.position.pixels}");
            return widget.itemBuilder(context, widget.startIndex + index);
          },
        ),
      ],
    );
  }
}
