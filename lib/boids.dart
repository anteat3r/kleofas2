import 'package:flutter/material.dart';
import 'dart:math';
import 'package:vector_math/vector_math.dart';

class BoidPage extends StatefulWidget {
  const BoidPage({Key? key}) : super(key: key);
  @override
  State<BoidPage> createState() => _BoidPageState();
}

class _BoidPageState extends State<BoidPage> {
  BoidPainter painter = BoidPainter();
  @override
  Widget build (BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boids'),
      ),
      body: Container(
        color: const Color.fromARGB(255, 31, 31, 31),
        child: GestureDetector(
          child: CustomPaint(
            painter: painter,
          ),
        ),
      ),
    );
  }
}

class Boid {
  Vector2 pos;
  Vector2 vel;
  Vector2 acc;
  double r;
  double maxforce;
  double maxspeed;

  Boid._(this.pos, this.vel, this.acc, this.r, this.maxforce, this.maxspeed);

  factory Boid(double x, double y) {
    double angle = Random().nextDouble() * pi * 2;
    return Boid._(
      Vector2(x, y),
      Vector2(cos(angle), sin(y)),
      Vector2.zero(),
      2, 0.03, 2,
    );
  }

  void run (List<Boid> boids) {

  }

  void applyForce (Vector2 force) {
    acc.add(force);
  }

  void flock (List<Boid> boids) {

  }

  void update () {
    vel.add(acc);
    vel.clamp(Vector2.zero(), Vector2.all(maxspeed));
    pos.add(vel);
    acc.multiply(Vector2.zero());
  }

  Vector2 seek (Vector2 target) {
    Vector2 desired = target..sub(pos);
    desired.normalize();
    desired.multiply(Vector2.all(maxspeed));
    Vector2 steer = desired..sub(vel);
    steer.clamp(Vector2.zero(), Vector2.all(maxforce));
    return steer;
  }

  void render () {}


}

class BoidPainter extends CustomPainter {
  @override
  void paint (Canvas canvas, Size size) {}

  @override
  bool shouldRepaint (BoidPainter oldDelegate) => true;
}