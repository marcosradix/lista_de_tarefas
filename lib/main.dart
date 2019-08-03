import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final myTodoController = TextEditingController();

  void _addTodo() {
    Map<String, dynamic> newTodo = Map();
    if (myTodoController.text.isNotEmpty) {
      setState(() {
        newTodo["title"] = myTodoController.text;
        myTodoController.text = "";
        newTodo["ok"] = false;
        _todoList.add(newTodo);
      });
      _saveData();
    }
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _todoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
    return null;
  }

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      if (data.isNotEmpty) {
        setState(() {
          _todoList = json.decode(data);
        });
      }
    });
  }

  List _todoList = [];
  Map<String, dynamic> _lastRemoved;
  int lastRemovedPos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de tarefas'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: myTodoController,
                    decoration: InputDecoration(
                        labelText: 'Nova tarefa',
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                RaisedButton.icon(
                  icon: const Icon(Icons.add, size: 18.0),
                  color: Colors.blueAccent,
                  label: Text('ADD'),
                  textColor: Colors.white,
                  onPressed: () {
                    _addTodo();
                  },
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _todoList.length,
                  itemBuilder: buildItemList),
            ),
          )
        ],
      ),
    );
  }

  Widget buildItemList(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
          alignment: Alignment(-0.9, -0.0),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: checkboxListTile(index),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_todoList[index]);
          lastRemovedPos = index;
          _todoList.removeAt(index);
          _saveData();
          final showLastRemoved = _lastRemoved['title'];
          final snack = SnackBar(
            content: Text("Tarefa \"$showLastRemoved\" removida!"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _todoList.insert(lastRemovedPos, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 3),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Widget checkboxListTile(index) {
    return CheckboxListTile(
      title: Text(_todoList[index]["title"]),
      value: _todoList[index]["ok"],
      secondary: CircleAvatar(
        child: Icon(_todoList[index]["ok"] ? Icons.check : Icons.error),
      ),
      onChanged: (bool value) {
        setState(() {
          _todoList[index]["ok"] = value;
          _saveData();
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    directory.create();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsStringSync();
    } catch (e) {
      debugPrint(e);
      return null;
    }
  }
}
