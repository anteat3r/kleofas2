import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kleofas2/storage.dart';

class DrawingPage extends StatefulWidget {
  const DrawingPage({Key? key}) : super(key: key);
  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

enum LayerType {pencil, line, circle, vertices}

Offset offset = const Offset(0, 0);
double scale = 1;

class Layer {
  Paint paint;
  List<Offset> points;
  LayerType layerType;
  Layer({required this.paint, required this.points, required this.layerType});
}

class DrawingPainter extends CustomPainter {
  Offset halfScreen;
  List<Layer> layers = [];
  DrawingPainter(this.halfScreen, this.layers);
  @override
  void paint (Canvas canvas, Size size) {
    canvas.translate(halfScreen.dx, halfScreen.dy);
    canvas.scale(scale);
    canvas.translate(offset.dx, offset.dy);
    for (final layer in layers) {
      if (layer.layerType == LayerType.pencil) {
        for (int i = 0; i < layer.points.length - 1; i++) {
          canvas.drawLine(layer.points[i], layer.points[i + 1], layer.paint);
        }
      }
      if (layer.layerType == LayerType.line) {
        if (layer.points.length == 1) {
          canvas.drawCircle(layer.points.first, 5, layer.paint);
        } else {
          canvas.drawLine(layer.points.first, layer.points.last, layer.paint);
        }
      }
      if (layer.layerType == LayerType.vertices) {
        canvas.drawVertices(Vertices(VertexMode.triangleStrip, layer.points), BlendMode.multiply, layer.paint);
      }
      if (layer.layerType == LayerType.circle) {
        if (layer.points.length == 1) {
          canvas.drawCircle(layer.points.first, 5, layer.paint);
        } else {
          canvas.drawCircle(layer.points.first, (layer.points.last - layer.points.first).distance, layer.paint);
        }
      }
    }
  }
  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}

class _DrawingPageState extends State<DrawingPage> {
  List<Layer> layers = [];
  List<Layer> removed = [];
  List<Offset> moveBuffer = [];
  Paint curPaint = Paint()..color = Colors.black;
  bool drag = false;
  LayerType selectedLayerType = LayerType.line;
  late Offset halfScreen;

  Offset processOffset (Offset input) => (input - halfScreen - offset*scale)/scale;

  void pushNewLayer (Offset initPoint) => layers.add(Layer(points: [processOffset(initPoint)], paint: curPaint, layerType: selectedLayerType));

  @override
  Widget build (BuildContext context) {
    final appBar = AppBar(
      title: const Text('Drawing'),
    );
    final currentSize = MediaQuery.sizeOf(context);
    final maxHeight = currentSize.height - appBar.preferredSize.height - MediaQuery.of(context).padding.top - 19;
    final maxWidth = currentSize.width;
    halfScreen = Offset(maxWidth/2, maxHeight/2);
    return Scaffold(
      appBar: appBar,
      body: Container(
        color: Colors.white,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: GestureDetector(
          onPanStart: (details) {
            if (drag) return;
            setState(() {
              pushNewLayer(details.localPosition);
            });
          },
          onPanUpdate: (details) {
            if (!drag) {
              setState(() {
                if (layers.last.layerType == LayerType.pencil) {
                  layers.last.points.add(processOffset(details.localPosition));
                }
                if (layers.last.layerType == LayerType.line || layers.last.layerType == LayerType.circle) {
                  if (layers.last.points.length < 2) {
                    layers.last.points.add(details.localPosition);
                  }
                  layers.last.points.last = processOffset(details.localPosition);
                }
              });
            } else {
              setState(() {
                moveBuffer.add(details.localPosition);
                if (moveBuffer.length > 4) {
                  moveBuffer.removeAt(0);
                }
                if (moveBuffer.length == 4) {
                  final rowDiffMax = [
                    moveBuffer[0].dx - moveBuffer[1].dx,
                    moveBuffer[0].dy - moveBuffer[1].dy,
                    moveBuffer[2].dx - moveBuffer[3].dx,
                    moveBuffer[2].dy - moveBuffer[3].dy,
                  ].reduce((a, b) => math.max(a.abs(), b.abs()));
                  final columnDiffMax = [
                    moveBuffer[0].dx - moveBuffer[2].dx,
                    moveBuffer[0].dy - moveBuffer[2].dy,
                    moveBuffer[1].dx - moveBuffer[3].dx,
                    moveBuffer[1].dy - moveBuffer[3].dy,
                  ].reduce((a, b) => math.max(a.abs(), b.abs()));
                  if (rowDiffMax > columnDiffMax * 50) {
                    final firstDiff = moveBuffer[0] - moveBuffer[1];
                    final secondDiff = moveBuffer[2] - moveBuffer[3];
                    final firstDist = firstDiff.distance;
                    final secondDist = secondDiff.distance;
                    final zoom = secondDist - firstDist;
                    final newScale = ((scale < 1 ? 5*(scale-1) : scale - 1) + zoom / 100).clamp(-5, 10);
                    scale = newScale < 0 ? newScale/5 + 1 : newScale + 1;
                    return;
                  }
                }
                offset = offset.translate(details.delta.dx / scale, details.delta.dy / scale);
              });
            }
          },
          onTapUp: (details) {
            if (drag) return;
            setState(() {
              if (layers.isEmpty || (layers.last.layerType != selectedLayerType)) {
                pushNewLayer(details.localPosition);
              }
              if (layers.last.layerType == LayerType.line || layers.last.layerType == LayerType.circle) {
                if (layers.last.points.length < 2) {
                  layers.last.points.add(processOffset(details.localPosition));
                } else {
                  pushNewLayer(details.localPosition);
                }
              }
              if (layers.last.layerType == LayerType.vertices) {
                layers.last.points.add(processOffset(details.localPosition));
              }
            });
          },
          child: CustomPaint(
            painter: DrawingPainter(halfScreen, layers),
          ),
        ),
      ),
      floatingActionButton: Stack(
        children: [
          FloatingActionButton(
            heroTag: 'clear',
            mini: true,
            onPressed: () {
              setState(() {
                layers.clear();
              });
            },
            backgroundColor: Colors.lightBlue,
            child: const Icon(Icons.delete_rounded)
          ),
          FloatingActionButton(
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
          FloatingActionButton(
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
          FloatingActionButton(
            heroTag: 'pick',
            mini: true,
            onPressed: () {
              showDialog(context: context, builder: (context) {
                return StatefulBuilder(
                  builder: (context, dialogSetState) {
                    return AlertDialog(
                      title: const Text('Pick a color'),
                      content: Column(
                        children: [
                          BlockPicker(
                            pickerColor: curPaint.color,
                            onColorChanged: (Color color) {
                              curPaint.color = color;
                              Navigator.pop(context);
                              setState(() {});
                            },
                          ),
                          Switch(
                            value: curPaint.style == PaintingStyle.fill,
                            onChanged: (value) {
                              dialogSetState(() {
                                curPaint.style = value ? PaintingStyle.fill : PaintingStyle.stroke;
                              });
                            },
                          )
                        ],
                      ),
                    );
                  },
                );
              });
            },
            backgroundColor: curPaint.color,
          ),
          FloatingActionButton(
            heroTag: 'drag',
            mini: true,
            onPressed: () {
              setState(() {
                drag = !drag;
              });
            },
            backgroundColor: Colors.lightBlue,
            child: drag ? const Icon(Icons.mouse_rounded) : const Icon(Icons.draw_rounded),
          ),
          FloatingActionButton(
            heroTag: 'tool',
            mini: true,
            onPressed: () {
              setState(() {
                /// cycles selectedLayerType in LayerType.values
                selectedLayerType = LayerType.values[(LayerType.values.indexOf(selectedLayerType)+1)%LayerType.values.length];
              });
            },
            backgroundColor: Colors.lightBlue,
            child: switch (selectedLayerType) {
              LayerType.pencil => const Icon(Icons.edit_rounded),
              LayerType.line => const Icon(Icons.straighten_rounded),
              LayerType.circle => const Icon(Icons.circle_outlined),
              LayerType.vertices => const Icon(Icons.hub_sharp),
            },
          ),
          // Positioned(
          //   bottom: 250,
          //   right: 0,
          //   child: RotatedBox(
          //     quarterTurns: 3,
          //     child: Slider(
          //       min: -5 ,
          //       max: 10,
          //       value: (scale < 1 ? 5*(scale-1) : scale - 1).clamp(-5, 10),
          //       onChanged: (value) {
          //         setState(() {
          //           scale = value < 0 ? value/5 + 1 : value + 1;
          //         });
          //       }
          //     ),
          //   ),
          // ),
        ].enumerate().map((e) => Positioned(
          bottom: e.$1 * 50,
          right: 0,
          child: e.$2
        )).toList(),
      ),
    );
  }
}