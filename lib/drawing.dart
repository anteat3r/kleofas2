import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class DrawingPage extends StatefulWidget {
  const DrawingPage({Key? key}) : super(key: key);
  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class Layer {
  Paint paint;
  List<Offset> points;
  Layer({required this.paint, required this.points});
}

class DrawingPainter extends CustomPainter {
  List<Layer> layers = [];
  DrawingPainter(this.layers);
  @override
  void paint (Canvas canvas, Size size) {
    for (final layer in layers) {
      for (int i = 0; i < layer.points.length - 1; i++) {
        canvas.drawLine(layer.points[i], layer.points[i + 1], layer.paint);
      }
    }
  }
  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return true;
  }
}

class _DrawingPageState extends State<DrawingPage> {
  List<Layer> layers = [];
  List<Layer> removed = [];
  Color curColor = Colors.black;
  @override
  Widget build (BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing'),
      ),
      body: Container(
        color: Colors.white,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: GestureDetector(
          onPanStart: (details) {
            setState(() {
              layers.add(Layer(points: [], paint: Paint()..color = curColor));
            });
          },
          onPanUpdate: (details) {
            setState(() {
              layers.last.points.add(details.localPosition);
            });
          },
          child: CustomPaint(
            painter: DrawingPainter(layers),
          ),
        ),
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 0,
            right: 0,
            child: FloatingActionButton(
              heroTag: 'delete',
              mini: true,
              onPressed: () {
                setState(() {
                  layers.clear();
                });
              },
              backgroundColor: Colors.lightBlue,
              child: const Icon(Icons.delete)
            ),
          ),
          Positioned(
            bottom: 50,
            right: 0,
            child: FloatingActionButton(
              heroTag: 'undo',
              mini: true,
              onPressed: () {
                setState(() {
                  removed.add(layers.removeLast()); 
                });
              },
              backgroundColor: Colors.lightBlue,
              child: const Icon(Icons.undo_rounded)
            ),
          ),
          Positioned(
            bottom: 100,
            right: 0,
            child: FloatingActionButton(
              heroTag: 'redo',
              mini: true,
              onPressed: () {
                setState(() {
                  if (removed.isEmpty) return;
                  layers.add(removed.removeLast()); 
                });
              },
              backgroundColor: Colors.lightBlue,
              child: const Icon(Icons.redo_rounded)
            ),
          ),
          Positioned(
            bottom: 150,
            right: 0,
            child: FloatingActionButton(
              heroTag: 'pick',
              mini: true,
              onPressed: () {
                showDialog(context: context, builder: (context) => AlertDialog(
                  title: const Text('Pick a color'),
                  content: BlockPicker(
                    pickerColor: curColor,
                    onColorChanged: (Color color) {
                      curColor = color;
                      Navigator.pop(context);
                      setState(() {});
                    },
                  ),
                ));
              },
              backgroundColor: curColor,
            ),
          ),
        ],
      ),
    );
  }
}