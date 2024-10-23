import 'package:flutter/material.dart';
import 'dart:math';
import 'database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper.instance;
    _loadSettings();
    _loadFromSharedPreferences();  
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

  _loadFromSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    fishCount = prefs?.getInt('fishCount') ?? 0;
    selectedSpeed = prefs?.getDouble('fishSpeed') ?? 1.0;
    int colorValue = prefs?.getInt('defaultColor') ?? Colors.blue.value;
    selectedColor = Color(colorValue);

    fishList = []; // Clear the list before loading
    for (int i = 0; i < fishCount; i++) {
      String fishKeyColor = 'fishColor_$i';
      String fishKeySpeed = 'fishSpeed_$i';
      Color fishColor = Color(prefs?.getInt(fishKeyColor) ?? selectedColor.value);
      double fishSpeed = prefs?.getDouble(fishKeySpeed) ?? selectedSpeed;

      fishList.add(Fish(color: fishColor, speed: fishSpeed));
    }

    setState(() {});
  }

  _saveSettings() async {
    Map<String, dynamic> row = {
      DatabaseHelper.columnFishCount: fishCount,
      DatabaseHelper.columnFishSpeed: selectedSpeed,
      DatabaseHelper.columnDefaultColor: selectedColor.value,
    };
    await dbHelper.insert(row);
    await _saveToSharedPreferences(); 
  }

  _saveToSharedPreferences() async {
    if (prefs != null) {
      await prefs!.setInt('fishCount', fishCount);
      await prefs!.setDouble('fishSpeed', selectedSpeed);
      await prefs!.setInt('defaultColor', selectedColor.value);

      // Save each fish's attributes
      for (int i = 0; i < fishList.length; i++) {
        await prefs!.setInt('fishColor_$i', fishList[i].color.value);
        await prefs!.setDouble('fishSpeed_$i', fishList[i].speed);
      }

      // Clear any old data if fish count changes
      for (int i = fishList.length; i < fishCount; i++) {
        await prefs!.remove('fishColor_$i');
        await prefs!.remove('fishSpeed_$i');
      }
    }
  }

  void resetFishes() {
    setState(() {
      fishList.clear(); // Clear the fish list
      fishCount = 0; // Reset the fish count
      _saveSettings(); // Save the changes to the database and shared preferences
    });
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
                    _saveSettings();
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
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: resetFishes, // Call resetFishes on button press
            child: Text('Reset Fishes'),
          ),
        ],
      ),
    );
  }

  void addFish() {
    setState(() {
      fishList.add(Fish(color: selectedColor, speed: selectedSpeed)); // Use selectedSpeed here
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
    currentPosition = _getRandomPosition();
    destination = _getRandomPosition();
    _initializeAnimation();
  }

  Offset _getRandomPosition() {
    return Offset(
      Random().nextDouble() * (widget.containerWidth - 20),
      Random().nextDouble() * (widget.containerHeight - 20),
    );
  }

  void _initializeAnimation() {
    // Use a fixed base duration and modify it by the speed
    // Lower speed = longer duration, Higher speed = shorter duration
    int baseDuration = (2000 / widget.fish.speed).toInt(); // 2 seconds base duration
    
    _controller = AnimationController(
      duration: Duration(milliseconds: baseDuration),
      vsync: this,
    );

    _position = Tween<Offset>(begin: currentPosition, end: destination)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.linear))
      ..addListener(() {
        setState(() {
          currentPosition = _position.value;

          if (currentPosition.dx < 0 || currentPosition.dx > widget.containerWidth - 20 ||
              currentPosition.dy < 0 || currentPosition.dy > widget.containerHeight - 20) {
            _changeDirection();
          }

          if (_controller.isCompleted) {
            _changeDirection();
          }
        });
      });

    _controller.forward();
  }

  void _changeDirection() {
    destination = _getRandomPosition();
    
    // Use the same duration calculation as in _initializeAnimation
    int baseDuration = (2000 / widget.fish.speed).toInt();
    _controller.duration = Duration(milliseconds: baseDuration);
    
    _position = Tween<Offset>(begin: currentPosition, end: destination)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: currentPosition.dx,
      top: currentPosition.dy,
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