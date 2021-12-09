
enum PathBuild{
  Line, QuadraticBezier, Cubic, Conic, Arc, Rect, Oval, Polygon, RRect, Path, Close,
}

// The model of a path which is drawn continuously without lifting up the pen.
// The moveTo function is overwritten to disallow lifting and movement of the pen
// after drawing has begun.

// class EditableSegment extends Path {
//   Offset _currentPoint = Offset.zero;
//
//   List<Offset> controlPoints = <Offset>[];
//
//   List<int> editingSequence = <int>[];
//
//   @override
//   void moveTo(double x, double y){
//     assert(controlPoints.isEmpty || (controlPoints.isNotEmpty && controlPoints.last.dx == x && controlPoints.last.dy == y),
//     "Segments cannot have discontinuous subpaths.");
//     super.moveTo(x, y);
//     _currentPoint = Offset(x, y);
//   }
//
//   @override
//   void relativeMoveTo(double dx, double dy){
//     assert(controlPoints.isEmpty || (dx == 0 && dy == 0),
//     "Segments cannot have discontinuous subpaths.");
//     super.relativeMoveTo(dx, dy);
//     _currentPoint += Offset(dx, dy);
//   }
//
//   @override
//   void lineTo(double x, double y){
//     assert(controlPoints.isEmpty || controlPoints.last == _currentPoint,
//     "If drawing has started, current point and the last control point must be identical.");
//     super.lineTo(x, y);
//     if (controlPoints.isEmpty){
//       controlPoints.add(Offset(_currentPoint.dx, _currentPoint.dy));
//     }
//     controlPoints.add(Offset(x, y));
//     _currentPoint = controlPoints.last;
//     editingSequence.add(0);
//   }
//
//   @override
//   void relativeLineTo(double dx, double dy){
//     assert(controlPoints.isEmpty || controlPoints.last == _currentPoint,
//     "If drawing has started, current point and the last control point must be identical.");
//     super.relativeLineTo(dx, dy);
//     if (controlPoints.isEmpty){
//       controlPoints.add(Offset(_currentPoint.dx, _currentPoint.dy));
//     }
//     controlPoints.add(_currentPoint + Offset(dx, dy));
//     _currentPoint = controlPoints.last;
//     editingSequence.add(0);
//   }
//
//   @override
//   void quadraticBezierTo(double x1, double y1, double x2, double y2){
//     assert(controlPoints.isEmpty || controlPoints.last == _currentPoint,
//     "If drawing has started, current point and the last control point must be identical.");
//     super.quadraticBezierTo(x1, y1, x2, y2);
//     if (controlPoints.isEmpty){
//       controlPoints.add(Offset(_currentPoint.dx, _currentPoint.dy));
//     }
//     controlPoints.add(Offset(x1, x2));
//     controlPoints.add(Offset(x2, y2));
//     _currentPoint = controlPoints.last;
//     editingSequence.add(1);
//   }
//
//   @override
//   void relativeQuadraticBezierTo(double x1, double y1, double x2, double y2){
//     assert(controlPoints.isEmpty || controlPoints.last == _currentPoint,
//     "If drawing has started, current point and the last control point must be identical.");
//     super.relativeQuadraticBezierTo(x1, y1, x2, y2);
//     if (controlPoints.isEmpty){
//       controlPoints.add(Offset(_currentPoint.dx, _currentPoint.dy));
//     }
//     controlPoints.add(_currentPoint + Offset(x1, y1));
//     controlPoints.add(_currentPoint + Offset(x2, y2));
//     _currentPoint = controlPoints.last;
//     editingSequence.add(1);
//   }
//
//   @override
//   void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3){
//     assert(controlPoints.isEmpty || controlPoints.last == _currentPoint,
//     "If drawing has started, current point and the last control point must be identical.");
//     super.cubicTo(x1, y1, x2, y2, x3, y3);
//     if (controlPoints.isEmpty){
//       controlPoints.add(Offset(_currentPoint.dx, _currentPoint.dy));
//     }
//     controlPoints.add(Offset(x1, y1));
//     controlPoints.add(Offset(x2, y2));
//     controlPoints.add(Offset(x3, y3));
//     _currentPoint = controlPoints.last;
//     editingSequence.add(2);
//   }
//
//   @override
//   void relativeCubicTo(double x1, double y1, double x2, double y2, double x3, double y3){
//     assert(controlPoints.isEmpty || controlPoints.last == _currentPoint,
//     "If drawing has started, current point and the last control point must be identical.");
//     super.relativeCubicTo(x1, y1, x2, y2, x3, y3);
//     if (controlPoints.isEmpty){
//       controlPoints.add(Offset(_currentPoint.dx, _currentPoint.dy));
//     }
//     controlPoints.add(_currentPoint + Offset(x1, y1));
//     controlPoints.add(_currentPoint + Offset(x2, y2));
//     controlPoints.add(_currentPoint + Offset(x3, y3));
//     _currentPoint = controlPoints.last;
//     editingSequence.add(2);
//   }
//
//   @override
//   void conicTo(double x1, double y1, double x2, double y2, double w){
//     assert(controlPoints.isEmpty || controlPoints.last == _currentPoint,
//     "If drawing has started, current point and the last control point must be identical.");
//     super.conicTo(x1, y1, x2, y2, w);
//     if (controlPoints.isEmpty){
//       controlPoints.add(Offset(_currentPoint.dx, _currentPoint.dy));
//     }
//     controlPoints.add(Offset(w, 0));
//     controlPoints.add(Offset(x1, y1));
//     controlPoints.add(Offset(x2, y2));
//     _currentPoint = controlPoints.last;
//     editingSequence.add(3);
//   }
//
//   @override
//   void relativeConicTo(double x1, double y1, double x2, double y2, double w){
//     assert(controlPoints.isEmpty || controlPoints.last == _currentPoint,
//     "If drawing has started, current point and the last control point must be identical.");
//     super.relativeConicTo(x1, y1, x2, y2, w);
//     if (controlPoints.isEmpty){
//       controlPoints.add(Offset(_currentPoint.dx, _currentPoint.dy));
//     }
//     controlPoints.add(Offset(w, 0));
//     controlPoints.add(_currentPoint + Offset(x1, y1));
//     controlPoints.add(_currentPoint + Offset(x2, y2));
//     _currentPoint = controlPoints.last;
//     editingSequence.add(3);
//   }
//
//   @override
//   void arcTo(Rect rect, double startAngle, double sweepAngle, bool forceMoveTo){
//     assert(controlPoints.isEmpty || controlPoints.last == _currentPoint,
//     "If drawing has started, current point and the last control point must be identical.");
//     throw UnimplementedError("To review how arcs will be drawn in click-and-drag mode.");
//     // super.arcTo(rect, startAngle, sweepAngle, forceMoveTo);
//     // // Assuming that the conic arc is obtained by scaling in the direction
//     // // parallel to the shortest side of rect, with scale factor
//     // // longestSide / shortestSide.
//     // double a = rect.longestSide / 2;
//     // double b = rect.shortestSide / 2;
//     // double totalAngle = startAngle + sweepAngle;
//     // if (rect.width == rect.longestSide){
//     //   double basicAngle = atan(b / a * tan(totalAngle)).abs();
//     //   double angle;
//     //   if( totalAngle < pi / 2){
//     //     angle = basicAngle;
//     //   } else if (totalAngle < pi){
//     //     angle = pi - basicAngle;
//     //   } else if (totalAngle < 3 * pi / 2){
//     //     angle = pi + basicAngle;
//     //   } else {
//     //     angle = 2 * pi - basicAngle;
//     //   }
//     //   _currentPoint = rect.center
//     //       + Offset.fromDirection(angle,
//     //           sqrt(a * a * cos(totalAngle) * cos(totalAngle) + b * b * sin(totalAngle) * sin(totalAngle))
//     //       );
//     // } else {
//     //   double basicAngle = atan(a / b * tan(totalAngle)).abs();
//     //   double angle;
//     //   if( totalAngle < pi / 2){
//     //     angle = basicAngle;
//     //   } else if (totalAngle < pi){
//     //     angle = pi - basicAngle;
//     //   } else if (totalAngle < 3 * pi / 2){
//     //     angle = pi + basicAngle;
//     //   } else {
//     //     angle = 2 * pi - basicAngle;
//     //   }
//     //   _currentPoint = rect.center
//     //       + Offset.fromDirection(angle,
//     //           sqrt(a * a * sin(totalAngle) * sin(totalAngle) + b * b * cos(totalAngle) * cos(totalAngle))
//     //       );
//     // }
//   }
//
//   @override
//   void arcToPoint(Offset arcEnd, {
//     Radius radius = Radius.zero,
//     double rotation = 0.0,
//     bool largeArc = false,
//     bool clockwise = true,}){
//     throw UnimplementedError("To review how arcs will be drawn in click-and-drag mode.");
//     // super.arcToPoint(arcEnd, radius: radius, rotation: rotation, largeArc: largeArc, clockwise: clockwise);
//   }
//
//   // @override
//   // void relativeArcToPoint(Offset arcEndDelta, {
//   //   Radius radius = Radius.zero,
//   //   double rotation = 0.0,
//   //   bool largeArc = false,
//   //   bool clockwise = true,}){
//   //   throw UnimplementedError("To review how arcs will be drawn in click-and-drag mode.");
//   //   // super.relativeArcToPoint(arcEndDelta, radius: radius, rotation: rotation, largeArc: largeArc, clockwise: clockwise);
//   // }
//   //
//   // @override
//   // void addRect(Rect rect){
//   //   super.addRect(rect);
//   //
//   // }
//   //
//   // @override
//   // void addOval(Rect rect){
//   //   super.addOval(rect);
//   //
//   // }
//   //
//   // @override
//   // void addArc(Rect oval, double startAngle, double sweepAngle){
//   //   // super.addArc(oval, startAngle, sweepAngle);
//   //   // double a = oval.longestSide / 2;
//   //   // double b = oval.shortestSide / 2;
//   //   // double totalAngle = startAngle + sweepAngle;
//   //   // if (oval.width == oval.longestSide){
//   //   //   double basicAngle = atan(b / a * tan(totalAngle)).abs();
//   //   //   double angle;
//   //   //   if( totalAngle < pi / 2){
//   //   //     angle = basicAngle;
//   //   //   } else if (totalAngle < pi){
//   //   //     angle = pi - basicAngle;
//   //   //   } else if (totalAngle < 3 * pi / 2){
//   //   //     angle = pi + basicAngle;
//   //   //   } else {
//   //   //     angle = 2 * pi - basicAngle;
//   //   //   }
//   //   //   _currentPoint = oval.center
//   //   //       + Offset.fromDirection(angle,
//   //   //           sqrt(a * a * cos(totalAngle) * cos(totalAngle) + b * b * sin(totalAngle) * sin(totalAngle))
//   //   //       );
//   //   // } else {
//   //   //   double basicAngle = atan(a / b * tan(totalAngle)).abs();
//   //   //   double angle;
//   //   //   if( totalAngle < pi / 2){
//   //   //     angle = basicAngle;
//   //   //   } else if (totalAngle < pi){
//   //   //     angle = pi - basicAngle;
//   //   //   } else if (totalAngle < 3 * pi / 2){
//   //   //     angle = pi + basicAngle;
//   //   //   } else {
//   //   //     angle = 2 * pi - basicAngle;
//   //   //   }
//   //   //   _currentPoint = oval.center
//   //   //       + Offset.fromDirection(angle,
//   //   //           sqrt(a * a * sin(totalAngle) * sin(totalAngle) + b * b * cos(totalAngle) * cos(totalAngle))
//   //   //       );
//   //   // }
//   //   throw UnimplementedError("To review how arcs will be drawn in click-and-drag mode.");
//   // }
//   //
//   // @override
//   // void addPolygon(List<Offset> points, bool close){
//   //   super.addPolygon(points, close);
//   //
//   // }
//   //
//   // @override
//   // void addRRect(RRect rrect){
//   //   super.addRRect(rrect);
//   // }
//   //
//   // void addEPath(EditablePath epath, Offset offset, {Float64List? matrix4}){
//   //   super.addPath(epath, offset, matrix4: matrix4);
//   // }
//   //
//   // @override
//   // void addPath(Path path, Offset offset, {Float64List? matrix4}){
//   //   print("W/ Adding path to an elevatable path does not capture the current point in the instance of the elevated path");
//   //   print("I/ To capture current point in path builds, use 'addEPath' instead.");
//   //   throw UnimplementedError();
//   // }
//   //
//   // @override
//   // void extendWithPath(Path path, Offset offset, {Float64List? matrix4}){
//   //   print("W/ Extending path to an elevatable path does not capture the current point in the instance of the elevated path");
//   //   print("I/ To capture current point in path builds, use 'extendWidthEPath' instead.");
//   //   throw UnimplementedError();
//   // }
//   //
//   // void extendWithEPath(EditablePath epath, Offset offset, {Float64List? matrix4}){
//   //   super.extendWithPath(epath, offset, matrix4: matrix4);
//   // }
//   //
//   // @override
//   // void close(){
//   //   print("W/ Closing an elevatable path does not capture the current point in the instance of the elevated path.");
//   //   throw UnimplementedError();
//   // }
//   //
//   // @override
//   // void reset(){
//   //   super.reset();
//   // }
//   //
//   // void refreshPath(){
//   //   super.reset();
//   //   if(editingSequence.isNotEmpty && controlPoints.isNotEmpty){
//   //     super.moveTo(controlPoints.first.dx, controlPoints.first.dy);
//   //     int index = 1;
//   //     for(int edit in editingSequence){
//   //       switch(edit){
//   //         case 0:
//   //           // Line To
//   //           super.lineTo(controlPoints[index].dx, controlPoints[index].dy);
//   //           index++;
//   //           break;
//   //         case 1:
//   //           // Quadratic Bezier
//   //           super.quadraticBezierTo(
//   //             controlPoints[index].dx,
//   //             controlPoints[index].dy,
//   //             controlPoints[index + 1].dx,
//   //             controlPoints[index + 1].dy,
//   //           );
//   //           index += 2;
//   //           break;
//   //         case 2:
//   //           super.cubicTo(
//   //               controlPoints[index].dx,
//   //               controlPoints[index].dy,
//   //               controlPoints[index + 1].dx,
//   //               controlPoints[index + 1].dy,
//   //               controlPoints[index + 2].dx,
//   //               controlPoints[index + 2].dy
//   //           );
//   //           index += 3;
//   //           break;
//   //         case 3:
//   //           // super.conicTo(controlPoints[index].dx, y1, x2, y2, w)
//   //             break;
//   //         default:
//   //           throw UnimplementedError("Editing code $edit not implemented");
//   //       }
//   //     }
//   //   }
//   //
//   // }
//
// }

// class EditablePath extends Path {
//
//   Offset? _initialPoint;
//
//   Offset _currentPoint = Offset.zero;
//
//   List<Map<PathBuild, dynamic>> segments = [];
//
//   EditablePath() : super();
//
//   Offset get currentPoint => _currentPoint;
//
//   factory EditablePath.from(Path source){
//     throw UnimplementedError("Cannot use base constructor 'from' for elevated paths");
//   }
//
//   @override
//   void moveTo(double x, double y){
//     super.moveTo(x, y);
//     _initialPoint = null;
//     _currentPoint = Offset(x, y);
//   }
//
//   @override
//   void relativeMoveTo(double x, double y){
//     super.relativeMoveTo(x, y);
//     _initialPoint = null;
//     _currentPoint = _currentPoint + Offset(x, y);
//   }
//
//   @override
//   void lineTo(double x, double y){
//     super.lineTo(x, y);
//     segments.add({
//       PathBuild.Line: ["lineTo", x, y]
//     });
//     _initialPoint ??= _currentPoint;
//     _currentPoint = Offset(x, y);
//   }
//
//   @override
//   void relativeLineTo(double dx, double dy){
//     super.relativeLineTo(dx, dy);
//     segments.add({
//       PathBuild.Line: ["relativeLineTo", dx, dy]
//     });
//     _initialPoint ??= _currentPoint;
//     _currentPoint = _currentPoint + Offset(dx, dy);
//   }
//
//   @override
//   void quadraticBezierTo(double x1, double y1, double x2, double y2){
//     super.quadraticBezierTo(x1, y1, x2, y2);
//     segments.add({
//       PathBuild.QuadraticBezier: ["quadraticBezierTo", x1, y1, x2, y2]
//     });
//     _initialPoint ??= _currentPoint;
//     _currentPoint = Offset(x2, y2);
//   }
//
//   @override
//   void relativeQuadraticBezierTo(double x1, double y1, double x2, double y2){
//     super.relativeQuadraticBezierTo(x1, y1, x2, y2);
//     segments.add({
//       PathBuild.QuadraticBezier: ["relativeQuadraticBezierTo", x1, y1, x2, y2]
//     });
//     _initialPoint ??= _currentPoint;
//     _currentPoint = _currentPoint + Offset(x2, y2);
//   }
//
//   @override
//   void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3){
//     super.cubicTo(x1, y1, x2, y2, x3, y3);
//     segments.add({
//       PathBuild.Cubic: ["cubicTo", x1, y1, x2, y2, x3, y3]
//     });
//     _initialPoint ??= _currentPoint;
//     _currentPoint = Offset(x3, y3);
//   }
//
//   @override
//   void relativeCubicTo(double x1, double y1, double x2, double y2, double x3, double y3){
//     super.relativeCubicTo(x1, y1, x2, y2, x3, y3);
//     segments.add({
//       PathBuild.Cubic: ["relativeCubicTo", x1, y1, x2, y2, x3, y3]
//     });
//     _initialPoint ??= _currentPoint;
//     _currentPoint = _currentPoint + Offset(x3, y3);
//   }
//
//   @override
//   void conicTo(double x1, double y1, double x2, double y2, double w){
//     super.conicTo(x1, y1, x2, y2, w);
//     segments.add({
//       PathBuild.Conic: ["conicTo", x1, y1, x2, y2, w]
//     });
//     _initialPoint ??= _currentPoint;
//     _currentPoint = Offset(x2, y2);
//   }
//
//   @override
//   void relativeConicTo(double x1, double y1, double x2, double y2, double w){
//     super.relativeConicTo(x1, y1, x2, y2, w);
//     segments.add({
//       PathBuild.Conic: ["relativeConicTo", x1, y1, x2, y2, w]
//     });
//     _initialPoint ??= _currentPoint;
//     _currentPoint = _currentPoint + Offset(x2, y2);
//   }
//
//   @override
//   void arcTo(Rect rect, double startAngle, double sweepAngle, bool forceMoveTo){
//     super.arcTo(rect, startAngle, sweepAngle, forceMoveTo);
//     if(!forceMoveTo && (_currentPoint != Offset.zero || segments.isNotEmpty)){
//       segments.add({
//         PathBuild.Line: ["forceMoveTo", _currentPoint, rect.center + Offset.fromDirection(startAngle)],
//         PathBuild.Arc: ["arcTo", rect, startAngle, sweepAngle, forceMoveTo],
//       });
//     } else {
//       segments.add({
//         PathBuild.Arc: ["arcTo", rect, startAngle, sweepAngle, forceMoveTo],
//       });
//     }
//     _initialPoint ??= _currentPoint;
//     // Assuming that the conic arc is obtained by scaling in the direction
//     // parallel to the shortest side of rect, with scale factor
//     // longestSide / shortestSide.
//     double a = rect.longestSide / 2;
//     double b = rect.shortestSide / 2;
//     double totalAngle = startAngle + sweepAngle;
//     if (rect.width == rect.longestSide){
//       double basicAngle = atan(b / a * tan(totalAngle)).abs();
//       double angle;
//       if( totalAngle < pi / 2){
//         angle = basicAngle;
//       } else if (totalAngle < pi){
//         angle = pi - basicAngle;
//       } else if (totalAngle < 3 * pi / 2){
//         angle = pi + basicAngle;
//       } else {
//         angle = 2 * pi - basicAngle;
//       }
//       _currentPoint = rect.center
//           + Offset.fromDirection(angle,
//               sqrt(a * a * cos(totalAngle) * cos(totalAngle) + b * b * sin(totalAngle) * sin(totalAngle))
//           );
//     } else {
//       double basicAngle = atan(a / b * tan(totalAngle)).abs();
//       double angle;
//       if( totalAngle < pi / 2){
//         angle = basicAngle;
//       } else if (totalAngle < pi){
//         angle = pi - basicAngle;
//       } else if (totalAngle < 3 * pi / 2){
//         angle = pi + basicAngle;
//       } else {
//         angle = 2 * pi - basicAngle;
//       }
//       _currentPoint = rect.center
//           + Offset.fromDirection(angle,
//               sqrt(a * a * sin(totalAngle) * sin(totalAngle) + b * b * cos(totalAngle) * cos(totalAngle))
//           );
//     }
//   }
//
//   @override
//   void arcToPoint(Offset arcEnd, {
//       Radius radius = Radius.zero,
//       double rotation = 0.0,
//       bool largeArc = false,
//       bool clockwise = true,}){
//     super.arcToPoint(arcEnd, radius: radius, rotation: rotation, largeArc: largeArc, clockwise: clockwise);
//     segments.add({
//       PathBuild.Arc: ["arcToPoint", arcEnd, radius, rotation, largeArc, clockwise]
//     });
//     _initialPoint ??= _currentPoint;
//     _currentPoint = arcEnd;
//   }
//
//   @override
//   void relativeArcToPoint(Offset arcEndDelta, {
//     Radius radius = Radius.zero,
//     double rotation = 0.0,
//     bool largeArc = false,
//     bool clockwise = true,}){
//     super.relativeArcToPoint(arcEndDelta, radius: radius, rotation: rotation, largeArc: largeArc, clockwise: clockwise);
//     segments.add({
//       PathBuild.Arc: ["relativeArcToPoint", arcEndDelta, radius, rotation, largeArc, clockwise]
//     });
//     _initialPoint ??= _currentPoint;
//     _currentPoint = _currentPoint + arcEndDelta;
//   }
//
//   @override
//   void addRect(Rect rect){
//     super.addRect(rect);
//     segments.add({
//       PathBuild.Rect: ["addRect", rect]
//     });
//     _initialPoint = null;
//     _currentPoint = rect.topLeft;
//   }
//
//   @override
//   void addOval(Rect rect){
//     super.addOval(rect);
//     segments.add({
//       PathBuild.Oval: ["addOval", rect]
//     });
//     _initialPoint = null;
//     _currentPoint = rect.centerRight;
//   }
//
//   @override
//   void addArc(Rect oval, double startAngle, double sweepAngle){
//     super.addArc(oval, startAngle, sweepAngle);
//     segments.add({
//       PathBuild.Arc: ["addArc", oval, startAngle, sweepAngle]
//     });
//     _initialPoint ??= _currentPoint;
//     double a = oval.longestSide / 2;
//     double b = oval.shortestSide / 2;
//     double totalAngle = startAngle + sweepAngle;
//     if (oval.width == oval.longestSide){
//       double basicAngle = atan(b / a * tan(totalAngle)).abs();
//       double angle;
//       if( totalAngle < pi / 2){
//         angle = basicAngle;
//       } else if (totalAngle < pi){
//         angle = pi - basicAngle;
//       } else if (totalAngle < 3 * pi / 2){
//         angle = pi + basicAngle;
//       } else {
//         angle = 2 * pi - basicAngle;
//       }
//       _currentPoint = oval.center
//           + Offset.fromDirection(angle,
//               sqrt(a * a * cos(totalAngle) * cos(totalAngle) + b * b * sin(totalAngle) * sin(totalAngle))
//           );
//     } else {
//       double basicAngle = atan(a / b * tan(totalAngle)).abs();
//       double angle;
//       if( totalAngle < pi / 2){
//         angle = basicAngle;
//       } else if (totalAngle < pi){
//         angle = pi - basicAngle;
//       } else if (totalAngle < 3 * pi / 2){
//         angle = pi + basicAngle;
//       } else {
//         angle = 2 * pi - basicAngle;
//       }
//       _currentPoint = oval.center
//           + Offset.fromDirection(angle,
//               sqrt(a * a * sin(totalAngle) * sin(totalAngle) + b * b * cos(totalAngle) * cos(totalAngle))
//           );
//     }
//   }
//
//   @override
//   void addPolygon(List<Offset> points, bool close){
//     super.addPolygon(points, close);
//     segments.add({
//       PathBuild.Polygon: ["addPolygon", points, close]
//     });
//     if(close){
//       _initialPoint = null;
//       _currentPoint = points.first;
//     } else {
//       _initialPoint ??= _currentPoint;
//       _currentPoint = points.last;
//     }
//   }
//
//   @override
//   void addRRect(RRect rrect){
//     super.addRRect(rrect);
//     segments.add({
//       PathBuild.RRect: ["addRRect", rrect]
//     });
//     _initialPoint = null;
//     _currentPoint = Offset(rrect.left, rrect.bottom - rrect.blRadiusY);
//   }
//
//   void addEPath(EditablePath epath, Offset offset, {Float64List? matrix4}){
//     super.addPath(epath, offset, matrix4: matrix4);
//     segments.add({
//       PathBuild.Path: ["addEPath", epath, offset, matrix4]
//     });
//     _initialPoint = epath._initialPoint;
//     _currentPoint = offset + epath._currentPoint;
//   }
//
//   @override
//   void addPath(Path path, Offset offset, {Float64List? matrix4}){
//     print("W/ Adding path to an elevatable path does not capture the current point in the instance of the elevated path");
//     print("I/ To capture current point in path builds, use 'addEPath' instead.");
//     throw UnimplementedError();
//   }
//
//   @override
//   void extendWithPath(Path path, Offset offset, {Float64List? matrix4}){
//     print("W/ Extending path to an elevatable path does not capture the current point in the instance of the elevated path");
//     print("I/ To capture current point in path builds, use 'extendWidthEPath' instead.");
//     throw UnimplementedError();
//   }
//
//   void extendWithEPath(EditablePath epath, Offset offset, {Float64List? matrix4}){
//     super.extendWithPath(epath, offset, matrix4: matrix4);
//     segments.add({
//       PathBuild.Path: ["extendWithEPath", epath, offset, matrix4]
//     });
//     _currentPoint = offset + epath._currentPoint;
//   }
//
//   @override
//   void close(){
//     print("W/ Closing an elevatable path does not capture the current point in the instance of the elevated path.");
//     throw UnimplementedError();
//   }
//
//   @override
//   void reset(){
//     super.reset();
//     _currentPoint = Offset.zero;
//     segments = [];
//   }
// }

