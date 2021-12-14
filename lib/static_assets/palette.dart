import 'package:flutter/material.dart';

import 'dart:ui' as ui;

import 'package:objects_draw_kit/tools/draw_pad.dart';

Paint fillPaint = Paint()
  ..color = Colors.blue
  ..style = PaintingStyle.fill;

Paint strokePaint = Paint()
  ..color = Colors.white
  ..strokeWidth = 1.0
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.stroke;

Color red = Color.fromARGB(255, 255, 64, 64);
Color yellow = Color.fromARGB(255, 255, 255, 64);
Color green = Color.fromARGB(255, 64, 224, 128);
Color blue = Color.fromARGB(255, 64, 96, 255);
Color cyan = Color.fromARGB(255, 64, 255, 255);
Color magenta = Color.fromARGB(255, 255, 64, 224);
Color brown = Color.fromARGB(255, 160, 64, 64);

enum AnchorColor{red, green, blue, alpha}

class CircularColorPalette extends StatelessWidget {
  final double paletteWidth;
  final double paletteHeight;
  final Color initialColor;
  // final AnchorColor anchorColor;
  // final double anchorColorValue;
  const CircularColorPalette(this.paletteWidth, this.paletteHeight, this.initialColor,  {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: paletteWidth,
      height: paletteHeight,
      child: Material(
        shape: const ContinuousRectangleBorder(
          side: BorderSide(width:1, color: Colors.black)
        ),
        child: CustomPaint(
          painter: FastDraw(
            drawer: (Canvas canvas, Size size){
              Offset center = size.center(Offset.zero);
              // switch(anchorColor){
              //   case AnchorColor.red:
              //     break;
              //   case AnchorColor.green:
              //     break;
              //     case AnchorColor.
              // }
              Path colorRing = Path();
              colorRing.addOval(Rect.fromCenter(center: center, width: size.width, height: size.height));
              colorRing.addOval(Rect.fromCenter(center: center, width: size.width * 0.8, height: size.height * 0.8));
              Paint sweepGradientPaint = Paint()
                  ..shader = ui.Gradient.sweep(
                    center,
                    [red, yellow, green, blue, cyan, magenta, red],
                    [0.0, 0.16667, 0.33333, 0.5, 0.66667, 0.83333, 1.0],
                    TileMode.clamp,
                  )
                  ..style = PaintingStyle.fill;
              Paint lineGradientPaint = Paint()
                ..shader = ui.Gradient.linear(
                  Offset(size.width / 2, size.height * 0.7),
                  Offset(size.width / 2, size.height * 0.3),
                  [Colors.black, initialColor, Colors.white],
                  [0.0, 0.5, 1.0],
                  TileMode.clamp,
                )
                ..style = PaintingStyle.fill;
              colorRing.fillType = PathFillType.evenOdd;
              canvas.drawPath(colorRing, sweepGradientPaint);
              canvas.drawRect(Rect.fromCenter(center: center, width: size.width / 4, height: size.height * 0.4), lineGradientPaint);
            },
            shouldRedraw: true,
          )
        ),
      ),
    );
  }
}

Color? getColorFromPalette(double t){
  if( t <= -0.66667 ){
    return Color.lerp(blue, cyan, (t + 1) / 0.33333) ;
  } else if (t <= -0.33333){
    return Color.lerp(cyan, magenta, (t + 0.66667) / 0.33333) ;
  } else if (t <= 0.0){
    return Color.lerp(magenta, red, (t + 0.33333) / 0.33333) ;
  } else if (t <= 0.33333){
    return Color.lerp(red, yellow, (t) / 0.33333) ;
  } else if (t <= 0.66667){
    return Color.lerp(yellow, green, (t - 0.33333) / 0.33333) ;
  } else {
    return Color.lerp(green, blue, (t - 0.66667) / 0.33333) ;
  }
}

Color? getGradientColor(Color initialColor, double t){
  if( t <= 0.5 ){
    return Color.lerp(Colors.black, initialColor, t * 2);
  } else {
    return Color.lerp(initialColor, Colors.white, (t - 0.5) * 2) ;
  }
}

class ThreeDimColorPalette extends StatelessWidget {
  final double paletteWidth;
  final double paletteHeight;
  final AnchorColor anchorColor;
  final int anchorColorValue;
  final int alpha;
  const ThreeDimColorPalette(this.paletteWidth, this.paletteHeight, this.anchorColor, this.anchorColorValue, this.alpha, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: paletteWidth,
      height: paletteHeight,
      child: Material(
        child: CustomPaint(
            painter: FastDraw(
              drawer: (Canvas canvas, Size size){
                switch(anchorColor){
                  case AnchorColor.red:
                    for(int i = 0; i < 256; i++){
                      Paint lineGradientPaint = Paint()
                        ..shader = ui.Gradient.linear(
                          Offset(0, i / 1),
                          Offset(255, i / 1),
                          [Color.fromARGB(alpha, anchorColorValue, i, 0), Color.fromARGB(alpha, anchorColorValue, i, 255)],
                          [0.0, 1.0],
                          TileMode.clamp,
                        )
                        ..style = PaintingStyle.fill;
                      canvas.drawRect(Rect.fromCenter(center: Offset(size.width / 2, i / 1), width: size.width, height: 1), lineGradientPaint);
                    }
                    break;
                  case AnchorColor.green:
                    for(int i = 0; i < 256; i++){
                      Paint lineGradientPaint = Paint()
                        ..shader = ui.Gradient.linear(
                          Offset(20, i / 1),
                          Offset(275, i / 1),
                          [Color.fromARGB(alpha, i, anchorColorValue, 0), Color.fromARGB(alpha, i, anchorColorValue, 255)],
                          [0.0, 1.0],
                          TileMode.clamp,
                        )
                        ..style = PaintingStyle.fill;
                      canvas.drawRect(Rect.fromCenter(center: Offset(size.width / 2, i / 1), width: size.width, height: 1), lineGradientPaint);
                    }
                    break;
                  case AnchorColor.blue:
                    for(int i = 0; i < 256; i++){
                      Paint lineGradientPaint = Paint()
                        ..shader = ui.Gradient.linear(
                          Offset(20, i / 1),
                          Offset(275, i / 1),
                          [Color.fromARGB(alpha, i, 0, anchorColorValue), Color.fromARGB(alpha, i, 255, anchorColorValue)],
                          [0.0, 1.0],
                          TileMode.clamp,
                        )
                        ..style = PaintingStyle.fill;
                      canvas.drawRect(Rect.fromCenter(center: Offset(size.width / 2, i / 1), width: size.width, height: 1), lineGradientPaint);
                    }
                    break;
                  default:
                    break;
                }
              },
              shouldRedraw: true,
            )
        ),
      ),
    );
  }
}

