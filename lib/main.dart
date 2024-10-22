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

// aquarium_screen.dart
class AquariumScreen extends StatefulWidget {
  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen> {
  List<Fish> fishList = [];
  late SharedPreferences prefs;
  Color selectedColor = Colors.blue; // Default color
  double selectedSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  _loadPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load color and ensure it's one of the predefined colors
      int? colorValue = prefs.getInt('color');
      if (colorValue != null) {
        selectedColor = Color(colorValue);
      }

      // Load speed
      selectedSpeed = prefs.getDouble('speed') ?? 1.0;
    });
  }

  _savePreferences() async {
    await prefs.setInt('color', selectedColor.value);
    await prefs.setDouble('speed', selectedSpeed);
  }

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
              height: 600,
              color: Colors.lightBlueAccent,
              child: Stack(
                children: fishList
                    .map((fish) => AnimatedFish(fish: fish, containerWidth: 300, containerHeight: 600))
                    .toList(),
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
              SizedBox(width: 20),
              Text('Speed:'),
              Slider(
                value: selectedSpeed,
                min: 0.5,
                max: 3.0,
                divisions: 5,
                label: selectedSpeed.toString(),
                onChanged: (value) {
                  setState(() {
                    selectedSpeed = value;
                  });
                },
              ),
              SizedBox(width: 20),
              Text('Color:'),
              DropdownButton<Color>(
                value: selectedColor,
                onChanged: (Color? newColor) {
                  setState(() {
                    if (newColor != null) {
                      selectedColor = newColor;
                    }
                  });
                },
                items: [
                  DropdownMenuItem<Color>(
                    value: Colors.blue,
                    child: Container(
                      width: 24,
                      height: 24,
                      color: Colors.blue,
                    ),
                  ),
                  DropdownMenuItem<Color>(
                    value: Colors.red,
                    child: Container(
                      width: 24,
                      height: 24,
                      color: Colors.red,
                    ),
                  ),
                  DropdownMenuItem<Color>(
                    value: Colors.green,
                    child: Container(
                      width: 24,
                      height: 24,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void addFish() {
    setState(() {
      fishList.add(Fish(color: selectedColor, speed: selectedSpeed));
      _savePreferences();
    });
  }
}

class Fish {
  final Color color;
  final double speed;

  Fish({required this.color, required this.speed});
}

class AnimatedFish extends StatefulWidget {
  final Fish fish;
  final double containerWidth;
  final double containerHeight;

  AnimatedFish({required this.fish, required this.containerWidth, required this.containerHeight});

  @override
  _AnimatedFishState createState() => _AnimatedFishState();
}

class _AnimatedFishState extends State<AnimatedFish> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _position;

  Offset currentPosition = Offset(0, 0);
  Offset destination = Offset(0, 0);

  @override
  void initState() {
    super.initState();

    currentPosition = Offset(
      Random().nextDouble() * widget.containerWidth,
      Random().nextDouble() * widget.containerHeight,
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
      Random().nextDouble() * (widget.containerWidth - 20),
      Random().nextDouble() * (widget.containerHeight - 20),
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
