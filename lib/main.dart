import 'package:flutter/material.dart';
import 'package:rivertoWearOS/screen/homePage.dart';
import 'package:rivertoWearOS/screens/ambient_screen.dart';
import 'package:rivertoWearOS/screens/start_screen.dart';
import 'package:rivertoWearOS/wear.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Riverto',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: WatchScreen(),
        debugShowCheckedModeBanner: false,
      );
}

class WatchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WatchShape(
        builder: (context, shape) => InheritedShape(
          shape: shape,
          child: AmbientMode(
            builder: (context, mode) => Riverto(),
          ),
        ),
      );
}
