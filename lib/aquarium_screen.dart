import 'package:flutter/material.dart';
import 'dart:math';
import 'database_helper.dart';

class AquariumScreen extends StatefulWidget {
  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen> {
  List<Fish> fishList = [];
  late DatabaseHelper dbHelper;
  Color selectedColor = Colors.blue; 
  double selectedSpeed = 1.0;
  int fishCount = 0;

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper.instance;
    _loadSettings();
  }

  _loadSettings() async {
    List<Map<String, dynamic>> rows = await dbHelper.queryAllRows();
    if (rows.isNotEmpty) {
      Map<String, dynamic> row = rows[0];
      setState(() {
        fishCount = row[DatabaseHelper.columnFishCount];
        selectedSpeed = row[DatabaseHelper.columnFishSpeed];

        Color loadedColor = Color(row[DatabaseHelper.columnDefaultColor]);
        if (loadedColor == Colors.blue || loadedColor == Colors.red || loadedColor == Colors.green) {
          selectedColor = loadedColor;
        } else {
          selectedColor = Colors.blue; 
        }
      });
    }
  }

  _saveSettings() async {
    Map<String, dynamic> row = {
      DatabaseHelper.columnFishCount: fishCount,
      DatabaseHelper.columnFishSpeed: selectedSpeed,
      DatabaseHelper.columnDefaultColor: selectedColor.value,
    };
    await dbHelper.insert(row);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Aquarium'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center, 
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blueAccent, width: 2), 
            ),
            child: Stack(
              children: fishList
                  .map((fish) => AnimatedFish(fish: fish, containerWidth: 300, containerHeight: 300))
                  .toList(),
            ),
          ),
          SizedBox(height: 20), 
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: addFish,
                child: Text('Add Fish'),
              ),
              SizedBox(width: 20),
              Text(' Speed:'),
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
            ],
          ),
          SizedBox(height: 20),
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
    );
  }

  void addFish() {
    setState(() {
      fishList.add(Fish(color: selectedColor, speed: selectedSpeed));
      fishCount++;
      _saveSettings();
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
