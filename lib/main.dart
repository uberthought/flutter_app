// Copyright 2017, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';

Future<void> main() async {
  final FirebaseApp app = await FirebaseApp.configure(
    name: 'db2',
    options: const FirebaseOptions(
      googleAppID: '1:724911092758:android:7bd71543f89d056a',
      apiKey: 'AIzaSyBynGgM64_JaAnM2O5yNFbf85VX_Fkj4dM',
      databaseURL: 'https://flutterapp-8a4af.firebaseio.com',
    ),
  );
  runApp(new MaterialApp(
    title: 'Flutter Database Example',
    home: new MyHomePage(app: app),
  ));
}

class MyHomePage extends StatefulWidget {
  MyHomePage({this.app});

  final FirebaseApp app;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter;
  DatabaseReference _messagesRef;
  StreamSubscription<Event> _messagesSubscription;
  bool _anchorToBottom = false;

  DatabaseError _error;

  @override
  void initState() {
    super.initState();
    final FirebaseDatabase database = new FirebaseDatabase(app: widget.app);
    _messagesRef = database.reference().child('trip');
    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);
    _messagesSubscription =
        _messagesRef.limitToLast(10).onChildAdded.listen((Event event) {
      print('Child added: ${event.snapshot.value}');
    }, onError: (Object o) {
      final DatabaseError error = o;
      print('Error: ${error.code} ${error.message}');
    });
  }

  @override
  void dispose() {
    super.dispose();
    _messagesSubscription.cancel();
  }

  Future<Null> _increment() async {
    _messagesRef.once().then((value){
      var map = value.value as Map;
      var nextNumber = map.length + 1;
      var tripNumber = 'T' + nextNumber.toString().padLeft(3, '0');
      var startTime = DateTime.now().toUtc().millisecondsSinceEpoch;
      _messagesRef.push().set({
        'tripNumber': tripNumber,
        'startTime': startTime,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Flutter Database Example'),
      ),
      body: new FirebaseAnimatedList(
        key: new ValueKey<bool>(_anchorToBottom),
        query: _messagesRef,
        itemBuilder: (BuildContext context, DataSnapshot snapshot,
            Animation<double> animation, int index) {
          var tripNumber = snapshot.value['tripNumber'];
          var startTime = snapshot.value['startTime'];
          if (startTime.runtimeType == int)
            startTime = DateTime.fromMillisecondsSinceEpoch(startTime, isUtc: true).toString();
          return new ListTile(
            title: Text(tripNumber),
            subtitle: Text(startTime),
          );
        },
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _increment,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
