import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

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

class AnimatedFish extends StatefulWidget {
  final Fish fish;

  AnimatedFish({required this.fish});

  @override
  _AnimatedFishState createState() => _AnimatedFishState();
}

class _AnimatedFishState extends State<AnimatedFish> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _position;

  final double aquariumWidth = 300; 
  final double aquariumHeight = 300;

  Offset currentPosition = Offset(0, 0);
  Offset destination = Offset(0, 0);

  @override
  void initState() {
    super.initState();

    currentPosition = Offset(
      Random().nextDouble() * aquariumWidth,
      Random().nextDouble() * aquariumHeight,
    );

    destination = _getRandomPosition();

    _controller = AnimationController(
      duration: Duration(seconds: (5 / widget.fish.speed).round()), 
      vsync: this,
    )..forward();

    _position = Tween<Offset>(begin: currentPosition, end: destination)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.linear))
      ..addListener(() {
        setState(() {});  
      });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _setNewDestination();
      }
    });
  }

  
  Offset _getRandomPosition() {
    return Offset(
      Random().nextDouble() * (aquariumWidth - 20),
      Random().nextDouble() * (aquariumHeight - 20), 
    );
  }

  
  void _setNewDestination() {
    setState(() {
      currentPosition = destination;
      destination = _getRandomPosition();  

      _position = Tween<Offset>(begin: currentPosition, end: destination)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

      _controller.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.value.dx,
      top: _position.value.dy,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: widget.fish.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}