import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() => runApp(const VirtualAquarium());

class VirtualAquarium extends StatelessWidget {
  const VirtualAquarium({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AquariumScreen(),
    );
  }
}

class AquariumScreen extends StatefulWidget {
  const AquariumScreen({super.key});

  @override
  AquariumScreenState createState() => AquariumScreenState();
}

class AquariumScreenState extends State<AquariumScreen>
    with TickerProviderStateMixin {
  double selectedSpeed = 1.0;
  Color selectedColor = Colors.blue;
  List<Fish> fishList = [];
  AnimationController? _controller;
  Database? _database;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _controller?.addListener(() {
      setState(() {
        _updateFishPositions();
      });
    });
    _loadSettings();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        fishList.add(Fish(color: selectedColor, speed: selectedSpeed));
      });
    }
  }

  void _updateFishPositions() {
    for (var fish in fishList) {
      fish.updatePosition(const Size(300, 300));
    }
  }

  Future<void> _saveSettings() async {
    final fishCount = fishList.length;
    final speed = selectedSpeed;
    final color = selectedColor.value;

    await _database?.insert(
      'Settings',
      {'fishCount': fishCount, 'speed': speed, 'color': color},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _loadSettings() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'aquarium.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE Settings(fishCount INTEGER, speed REAL, color INTEGER)",
        );
      },
      version: 1,
    );

    final List<Map<String, dynamic>> settings =
        await _database?.query('Settings') ?? [];
    if (settings.isNotEmpty) {
      setState(() {
        final data = settings.first;
        selectedSpeed = data['speed'];
        selectedColor = Color(data['color']);

        if (selectedColor != Colors.blue &&
            selectedColor != Colors.red &&
            selectedColor != Colors.green) {
          selectedColor = Colors.blue;
        }

        for (int i = 0; i < data['fishCount']; i++) {
          fishList.add(Fish(color: selectedColor, speed: selectedSpeed));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Virtual Aquarium')),
      body: Column(
        children: [
          Container(
            width: 300,
            height: 300,
            color: Colors.lightBlueAccent,
            child: Stack(
              children: fishList.map((fish) => fish.buildFish()).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Slider(
            value: selectedSpeed,
            min: 0.5,
            max: 5.0,
            divisions: 10,
            label: "Speed: ${selectedSpeed.toStringAsFixed(1)}",
            onChanged: (newSpeed) {
              setState(() {
                selectedSpeed = newSpeed;
              });
            },
          ),
          DropdownButton<Color>(
            value: selectedColor,
            items: const [
              DropdownMenuItem(
                value: Colors.blue,
                child: Text("Blue"),
              ),
              DropdownMenuItem(
                value: Colors.red,
                child: Text("Red"),
              ),
              DropdownMenuItem(
                value: Colors.green,
                child: Text("Green"),
              ),
            ],
            onChanged: (newColor) {
              setState(() {
                selectedColor = newColor!;
              });
            },
          ),
          ElevatedButton(
            onPressed: _addFish,
            child: const Text('Add Fish'),
          ),
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}

class Fish {
  final Color color;
  final double speed;
  double posX;
  double posY;
  double directionX;
  double directionY;

  Fish({
    required this.color,
    required this.speed,
  })  : posX = Random().nextDouble() * 270,
        posY = Random().nextDouble() * 270,
        directionX = (Random().nextBool() ? 1 : -1) * Random().nextDouble(),
        directionY = (Random().nextBool() ? 1 : -1) * Random().nextDouble();

  void updatePosition(Size aquariumSize) {
    posX += directionX * speed;
    posY += directionY * speed;

    if (posX <= 0 || posX >= aquariumSize.width - 30) {
      directionX = -directionX;
    }

    if (posY <= 0 || posY >= aquariumSize.height - 30) {
      directionY = -directionY;
    }
  }

  Widget buildFish() {
    return Positioned(
      left: posX,
      top: posY,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
