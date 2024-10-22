import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Aquarium',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AquariumScreen(),
    );
  }
}

class AquariumScreen extends StatefulWidget {
  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen> {
  List<Fish> fishList = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Aquarium'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: 300,
              height: 300,
              color: Colors.lightBlueAccent,
              child: Stack(
                children: fishList.map((fish) => AnimatedFish(fish: fish)).toList(),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: addFish, 
                child: Text('Add Fish'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void addFish(){
    if(fishList.length <10){
      setState(() {
        fishList.add(Fish(color: Colors.blue, speed: 1.0));
      });
    }
  }
}


class Fish{
  final Color color;
  final double speed;
  Fish({required this.color, required this.speed});
}

class AnimatedFish extends StatelessWidget{
  final Fish fish;

  AnimatedFish({required this.fish});
  Widget build(BuildContext context) {
    return Positioned(
      left: 50,
      top: 50,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: fish.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}