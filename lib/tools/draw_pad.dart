import 'package:flutter/material.dart';
import 'package:objects_draw_kit/tools/matrices.dart';

import 'dart:math';

import 'package:objects_draw_kit/tools/utils.dart';

class FastDraw extends CustomPainter{
  final bool shouldRedraw;
  final void Function(Canvas, Size) drawer;
  final Map<String, dynamic>? args;
  const FastDraw({required this.drawer, required this.shouldRedraw, this.args});

  @override
  void paint(Canvas canvas, Size size){
    drawer(canvas, size);
  }

  @override
  bool shouldRepaint(old) => shouldRedraw;
}

Path getCMRPath(List<Offset> generatingPoints, {bool close : false}){
  Path cmrPath = Path();
  CatmullRomSpline cmrSpline = CatmullRomSpline(generatingPoints);
  Iterable<Curve2DSample> samples = cmrSpline.generateSamples();
  cmrPath.moveTo(samples.first.value.dx, samples.first.value.dy);
  for(Curve2DSample pt in samples){
    cmrPath.lineTo(pt.value.dx, pt.value.dy);
  }
  if(close){
    cmrPath.close();
  }
  return cmrPath;
}

Path getQuadraticBezierPath(List<Offset> generatingPoints, {bool close : false}){
  assert(generatingPoints.length >= 3, "Requires at least 3 points for quadratic bezier curve");
  Path quadraticBezier = Path();
  quadraticBezier.moveTo(generatingPoints.first.dx, generatingPoints.first.dy);
  for(int i = 1; i + 1 < generatingPoints.length; i += 2){
    quadraticBezier.quadraticBezierTo(generatingPoints[i].dx, generatingPoints[i].dy, generatingPoints[i + 1].dx, generatingPoints[i + 1].dy);
  }
  if(close){
    quadraticBezier.close();
  }
  return quadraticBezier;
}

Path getCubicBezierPath(List<Offset> generatingPoints, {bool close : false}){
  assert(generatingPoints.length >= 4, "Requires at least 4 points for cubic bezier curve");
  Path cubicBezier = Path();
  cubicBezier.moveTo(generatingPoints.first.dx, generatingPoints.first.dy);
  for(int i = 1; i + 2 < generatingPoints.length; i += 3){
    cubicBezier.cubicTo(generatingPoints[i].dx, generatingPoints[i].dy, generatingPoints[i + 1].dx, generatingPoints[i + 1].dy, generatingPoints[i + 2].dx, generatingPoints[i + 2].dy,);
  }
  if(close){
    cubicBezier.close();
  }
  return cubicBezier;
}


Path getLinePath(List<Offset> generatingPoints, {bool close: false}){
  assert(generatingPoints.length >= 2, "Requires at least 2 points for line path.");
  Path line = Path();
  line.addPolygon(generatingPoints, close);
  return line;
}

Path getArcPath(List<Offset> arcPoints, List<Offset> directionalPoints, double width, double height, {bool close : false}){
  assert(arcPoints.length == 1 && directionalPoints.length == 3, "Requires exactly 1 arc points and 3 directional points for an arc path.");
  Path arc = Path();
  Rect rect = Rect.fromCenter(center: arcPoints[0], width: width, height: height);
  double direction = (directionalPoints[2] - arcPoints[0]).direction;
  double start = getConicDirection(rect, (directionalPoints[0] - arcPoints[0]).direction - direction);
  double sweep = getConicDirection(rect, (directionalPoints[1] - arcPoints[0]).direction - direction) - start;
  if(sweep < 0){
    sweep += 2 * pi;
  } else if (sweep > 2 * pi){
    sweep -= 2 * pi;
  }
  arc.addArc(rect, start, sweep);
  if(close){
    arc.close();
  }
  return arc.transform(rotateZAbout(direction, arcPoints[0]).storage);
}

double getConicDirection(Rect rect, double coordinateDirection){
  double basic = atan(rect.width / rect.height * tan(coordinateDirection)).abs();
  if(coordinateDirection < -3 * pi / 2){
    return basic;
  } else if(coordinateDirection < -pi){
    return pi - basic;
  } else if(coordinateDirection < -pi / 2){
    return pi + basic;
  } else if(coordinateDirection < 0){
    return 2 * pi - basic;
  } else if(coordinateDirection < pi / 2){
    return basic;
  } else if(coordinateDirection < pi){
    return pi - basic;
  } else if(coordinateDirection < 3 * pi / 2){
    return pi + basic;
  } else {
    return 2 * pi - basic;
  }
}

Offset getConicOffset(Rect rect, double conicDirection){
  return rect.center + Offset(rect.width / 2 * cos(conicDirection), rect.height / 2 * sin(conicDirection));
}

Path getPolygonPath(List<Offset> generatingPoints, {bool close: true}){
  assert(generatingPoints.length >= 3, "Requires at least 3 points for polygonal paths.");
  Path polygon = Path();
  polygon.addPolygon(generatingPoints, close);
  return polygon;
}

Path getConicPath(List<Offset> generatingPoints, double width, double height, Offset directionPoint){
  assert(generatingPoints.length == 1, "Requires exactly 2 points for conic paths.");
  Path conic = Path();
  conic.addOval(Rect.fromCenter(center: generatingPoints[0], width: width, height: height));
  return conic.transform(rotateZAbout((directionPoint - generatingPoints[0]).direction, generatingPoints[0]).storage);
}

Path getLeafPath(List<Offset> generatingPoints, {bool symmetric = true, bool orthSymmetric = true}) {
  assert((generatingPoints.length == 3 && symmetric && orthSymmetric) || (generatingPoints.length == 4 && symmetric) || generatingPoints.length == 6, "Requires at least 3 points for leaf paths.");
  Path leaf = Path();
  Offset cubicCP1 = generatingPoints[2];
  Offset cubicCP2, cubicCP3, cubicCP4;
  if(symmetric && orthSymmetric){
    Offset center = Rect.fromPoints(generatingPoints[0], generatingPoints[1]).center;
    double cp1Direction = (cubicCP1 - center).direction;
    double cp1Distance = (cubicCP1 - center).distance;
    cubicCP2 = center + Offset.fromDirection(cp1Direction + pi / 2, cp1Distance);
    cubicCP3 = center + Offset.fromDirection(cp1Direction + pi, cp1Distance);
    cubicCP4 = center + Offset.fromDirection(cp1Direction + 3 * pi / 2, cp1Distance);
  } else if (symmetric){
    cubicCP2 = generatingPoints[3];
    double cp3Direction = 2 * (generatingPoints[0] - generatingPoints[1]).direction - (cubicCP2 - generatingPoints[1]).direction;
    double cp1Distance = (cubicCP1 - generatingPoints[0]).distance;
    double cp4Direction = 2 * (generatingPoints[1] - generatingPoints[0]).direction - (cubicCP1 - generatingPoints[0]).direction;
    double cp2Distance = (cubicCP2 - generatingPoints[1]).distance;
    cubicCP3 = generatingPoints[1] + Offset.fromDirection(cp3Direction, cp2Distance);
    cubicCP4 = generatingPoints[0] + Offset.fromDirection(cp4Direction, cp1Distance);
  } else {
    cubicCP2 = generatingPoints[3];
    cubicCP3 = generatingPoints[4];
    cubicCP4 = generatingPoints[5];
  }
  leaf.moveTo(generatingPoints[0].dx, generatingPoints[0].dy);
  leaf.cubicTo(cubicCP1.dx, cubicCP1.dy, cubicCP2.dx, cubicCP2.dy, generatingPoints[1].dx, generatingPoints[1].dy);
  leaf.cubicTo(cubicCP3.dx, cubicCP3.dy, cubicCP4.dx, cubicCP4.dy, generatingPoints[0].dx, generatingPoints[0].dy);
  leaf.close();
  return leaf;
}

Path getHeartShapePath(List<Offset> controlPoints){
  assert(controlPoints.length == 3, "Require 3 points for heart shape paths.");
  Path heartShapePath = Path();
  Rect rect = Rect.fromPoints(controlPoints[0], controlPoints[1]);
  Rect upperRect = rect.topLeft & Size(rect.width, rect.height * 0.6);
  Rect lowerRect = (rect.centerLeft + Offset(0, - rect.height * 0.2)) & Size(rect.width, rect.height * 0.7);
  Offset blControlPoint = controlPoints[2];
  Offset brControlPoint = blControlPoint + Offset(2 * (rect.center.dx - blControlPoint.dx), 0);
  heartShapePath.addArc(Rect.fromPoints(upperRect.topLeft, upperRect.bottomCenter), pi, pi);
  heartShapePath.addArc(Rect.fromPoints(upperRect.topRight, upperRect.bottomCenter), pi, pi);
  heartShapePath.quadraticBezierTo(brControlPoint.dx, brControlPoint.dy, lowerRect.bottomCenter.dx, lowerRect.bottomCenter.dy);
  heartShapePath.quadraticBezierTo(blControlPoint.dx, blControlPoint.dy, lowerRect.topLeft.dx, lowerRect.topLeft.dy);
  return heartShapePath;
}

Path getStarPath(List<Offset> controlPoints, {double? radius}){
  assert(controlPoints.length == 2, "Require 2 points for star paths.");
  Path star = Path();
  Offset center = controlPoints[0];
  Offset initialPoint = controlPoints[1];
  List<Offset> vertices = [];
  double outerRadius = (initialPoint - center).distance;
  double innerRadius = radius ?? outerRadius * sin(pi / 10) / sin(7 * pi / 10);
  double startAngleOuter = (initialPoint - center).direction;
  double startAngleInner = startAngleOuter + pi / 5;
  for(int i = 0; i < 5; i++){
    vertices.add(center + Offset.fromDirection(startAngleOuter + i * (2 * pi / 5), outerRadius));
    vertices.add(center + Offset.fromDirection(startAngleInner + i * (2 * pi / 5), innerRadius));
  }
  star.addPolygon(vertices, true);
  return star;
}

Path getArrowShapePath(List<Offset> controlPoints, List<Offset> restrictedPoints, double directionalGap, double orthogonalGap){
  assert(controlPoints.length == 2, "Require 2 points for arrow shape paths.");
  Path arrow = Path();
  Offset displacement = restrictedPoints[0] - restrictedPoints[1];
  Offset lerpPoint = controlPoints[0] + Offset.fromDirection((controlPoints[1] - controlPoints[0]).direction, directionalGap);
  double normal = displacement.direction;
  double dist = displacement.distance;
  arrow.addPolygon(
      [
        controlPoints[0] + Offset.fromDirection(normal, orthogonalGap - dist),
        restrictedPoints[1],
        restrictedPoints[0],
        controlPoints[1],
        lerpPoint + Offset.fromDirection(normal + pi, orthogonalGap),
        lerpPoint + Offset.fromDirection(normal + pi, orthogonalGap - dist),
        controlPoints[0] + Offset.fromDirection(normal + pi, orthogonalGap - dist)
      ], true);
  return arrow;
}


List<Offset>? getRegularisedPoints(List<Offset> points, EditingMode mode){
  if(points.length >= 3){
    Path originalPath = Path();
    originalPath.addPolygon(points, true);
    Offset center = originalPath.getBounds().center;
    double initialDirection = (points.first - center).direction;
    double dist = (points.first - center).distance;
    double sweepingAngle = 2 * pi / points.length;
    List<Offset> regularisedPoints = [points[0]];
    for(int i = 1; i < points.length; i++){
      regularisedPoints.add(center + Offset.fromDirection(initialDirection + i * sweepingAngle, dist));
    }
    return regularisedPoints;
  } else if (points.length == 2 && mode == EditingMode.Rectangle){
    Offset center = Rect.fromPoints(points[0], points[1]).center;
    double firstDirection = (points[0] - center).direction;
    double dist = (points[0] - center).distance;
    if(firstDirection < -3 * pi / 4){
      return [center + Offset.fromDirection(-3 * pi / 4, dist), center + Offset.fromDirection(pi / 4, dist)];
    } else if (firstDirection < - pi / 4){
      return [center + Offset.fromDirection(- pi / 4, dist), center + Offset.fromDirection(3 * pi / 4, dist)];
    } else if (firstDirection < pi / 4){
      return [center + Offset.fromDirection(pi / 4, dist), center + Offset.fromDirection(-3 * pi / 4, dist)];
    } else {
      return [center + Offset.fromDirection(3 * pi / 4, dist), center + Offset.fromDirection(- pi / 4, dist)];
    }
  }
}

Offset rotate(Offset p, Offset center, double angle){
  return center + Offset.fromDirection((p - center).direction + angle, (p - center).distance);
}

List<Offset> getFlipHorizontal(List<Offset> points, Offset center){
  List<Offset> flippedPoints = [];
  for(Offset point in points){
    flippedPoints.add(
        Offset(center.dx + (center.dx - point.dx), point.dy)
    );
  }
  return flippedPoints;
}

List<Offset> getFlipVertical(List<Offset> points, Offset center){
  List<Offset> flippedPoints = [];
  for(Offset point in points){
    flippedPoints.add(
        Offset(point.dx, center.dy + (center.dy - point.dy))
    );
  }
  return flippedPoints;
}

List<Offset> getRotatedPoints(List<Offset> points, Offset center, double angle){
  List<Offset> rotatedPoints = [];
  for(Offset point in points){
    rotatedPoints.add(rotate(point, center, angle));
  }
  return rotatedPoints;
}

Map<String, dynamic> getDataPointsByRotation(EditingMode mode, Map<String, dynamic> curve, double rotation){
  switch(mode){
    case EditingMode.Arc:
      curve["data_control_points"][0] = curve["control_points"][0] + Offset(curve["width"] / 2, curve["height"] / 2);
      return curve;
    case EditingMode.Conic:
      curve["data_control_points"][0] = curve["control_points"][0] + Offset(curve["width"] / 2, curve["height"] / 2);
      return curve;
    default:
      return curve;
  }
}

Map<String, dynamic> getRestrictedPointsByRotation(EditingMode mode, Map<String, dynamic> curve, Offset center, double rotation){
  switch(mode){
    case EditingMode.Arc:
      curve["restricted_control_points"] = getRotatedPoints(curve["restricted_control_points"], center, rotation);
      return curve;
    case EditingMode.Conic:
      curve["restricted_control_points"] = getRotatedPoints(curve["restricted_control_points"], center, rotation);
      return curve;
    case EditingMode.Arrow:
      curve["restricted_control_points"] = getRotatedPoints(curve["restricted_control_points"], center, rotation);
      return curve;
    default:
      return curve;
  }
}

List<Offset> getTranslatedPoints(List<Offset> points, double dx, double dy){
  List<Offset> translatedPoints = [];
  for(Offset point in points){
    translatedPoints.add(point + Offset(dx, dy));
  }
  return translatedPoints;
}

Map<String, dynamic> getDataPointsByTranslation(EditingMode mode, Map<String, dynamic> curve, double dx, double dy){
  switch(mode){
    case EditingMode.Arc:
      curve["data_control_points"][0] = curve["data_control_points"][0] + Offset(dx, dy);
      return curve;
    case EditingMode.Conic:
      curve["data_control_points"][0] = curve["data_control_points"][0] + Offset(dx, dy);
      return curve;
    default:
      return curve;
  }
}

Map<String, dynamic> getRestrictedPointsByTranslation(EditingMode mode, Map<String, dynamic> curve, double dx, double dy){
  switch(mode){
    case EditingMode.Arc:
      curve["restricted_control_points"] = getTranslatedPoints(curve["restricted_control_points"], dx, dy);
      return curve;
    case EditingMode.Conic:
      curve["restricted_control_points"] = getTranslatedPoints(curve["restricted_control_points"], dx, dy);
      return curve;
    case EditingMode.Arrow:
      curve["restricted_control_points"] = getTranslatedPoints(curve["restricted_control_points"], dx, dy);
      return curve;
    default:
      return curve;
  }
}

Map<String, dynamic> getRestrictedPointsByHorizontalScale(EditingMode mode, Map<String, dynamic> curve, Offset stationary, double scaleFactor){
  switch(mode){
    case EditingMode.Arc:
      Rect rect = Rect.fromCenter(center: curve["control_points"][0], width: curve["width"], height: curve["height"]);
      curve["restricted_control_points"][2] = curve["control_points"][0] + Offset.fromDirection((Offset(stationary.dx + (curve["restricted_control_points"][2].dx - stationary.dx) * scaleFactor, curve["restricted_control_points"][2].dy) - curve["control_points"][0]).direction, (rect.center - rect.bottomRight).distance);
      double rotationAdjustedAngle = (curve["restricted_control_points"][2] - rect.center).direction;
      Matrix4 rotationMatrix = rotateZAbout(rotationAdjustedAngle, rect.center);
      curve["restricted_control_points"][0] = matrixApply(rotationMatrix, getConicOffset(rect, getConicDirection(rect, (curve["restricted_control_points"][0] - rect.center).direction - rotationAdjustedAngle)));
      curve["restricted_control_points"][1] = matrixApply(rotationMatrix, getConicOffset(rect, getConicDirection(rect, (curve["restricted_control_points"][1] - rect.center).direction - rotationAdjustedAngle)));
      return curve;
    case EditingMode.Conic:
      Rect rect = Rect.fromCenter(center: curve["control_points"][0], width: curve["width"], height: curve["height"]);
      curve["restricted_control_points"][0] = curve["control_points"][0] + Offset.fromDirection((Offset(stationary.dx + (curve["restricted_control_points"][0].dx - stationary.dx) * scaleFactor, curve["restricted_control_points"][0].dy) - curve["control_points"][0]).direction, (rect.center - rect.bottomRight).distance);
      // curve["restricted_control_points"] = getRotatedPoints(curve["restricted_control_points"], center, rotation);
      return curve;
    case EditingMode.Arrow:
      double direction = (curve["control_points"][1] - curve["control_points"][0]).direction;
      double dist = (curve["restricted_control_points"][0] - curve["restricted_control_points"][1]).distance;
      // curve["directional_gap"] = curve["directional_gap"] * scaleFactor;
      curve["restricted_control_points"][0] = curve["control_points"][0] + Offset.fromDirection(direction, curve["directional_gap"]) + Offset.fromDirection(direction + pi / 2, curve["orthogonal_gap"]);
      curve["restricted_control_points"][1] = curve["control_points"][0] + Offset.fromDirection(direction, curve["directional_gap"]) + Offset.fromDirection(direction + pi / 2, curve["orthogonal_gap"] - dist);
      return curve;
    default:
      return curve;
  }
}

List<Offset> scaleHorizontal(List<Offset> points, Offset stationary, double scaleFactor){
  List<Offset> scaled = [];
  for(Offset point in points){
    scaled.add(
        Offset(stationary.dx + (point.dx - stationary.dx) * scaleFactor, point.dy)
    );
  }
  return scaled;
}

Map<String, dynamic> getDataPointsByHorizontalScale(EditingMode mode, Map<String, dynamic> curve, Offset stationary, double scaleFactor){
  switch(mode){
    case EditingMode.Arc:
      curve["width"] = curve["width"] * scaleFactor;
      curve["data_control_points"][0] = Rect.fromCenter(center: curve["control_points"][0], width: curve["width"], height: curve["height"]).bottomRight;
      return curve;
    case EditingMode.Conic:
      curve["width"] = curve["width"] * scaleFactor;
      curve["data_control_points"][0] = Rect.fromCenter(center: curve["control_points"][0], width: curve["width"], height: curve["height"]).bottomRight;
      return curve;
    case EditingMode.Arrow:
      double direction = (curve["control_points"][1] - curve["control_points"][0]).direction;
      double dist = (curve["restricted_control_points"][0] - curve["restricted_control_points"][1]).distance;
      curve["restricted_control_points"][0] = curve["control_points"][0] + Offset.fromDirection(direction, curve["directional_gap"]) + Offset.fromDirection(direction + pi / 2, curve["orthogonal_gap"]);
      curve["restricted_control_points"][1] = curve["control_points"][0] + Offset.fromDirection(direction, curve["directional_gap"]) + Offset.fromDirection(direction + pi / 2, curve["orthogonal_gap"] - dist);
      return curve;
    default:
      return curve;
  }
}

List<Offset> scaleVertical(List<Offset> points, Offset stationary, double scaleFactor){
  List<Offset> scaled = [];
  for(Offset point in points){
    scaled.add(
        Offset(point.dx, stationary.dy + (point.dy - stationary.dy) * scaleFactor)
    );
  }
  return scaled;
}

Map<String, dynamic> getRestrictedPointsByVerticalScale(EditingMode mode, Map<String, dynamic> curve, Offset stationary, double scaleFactor){
  switch(mode){
    case EditingMode.Arc:
      Rect rect = Rect.fromCenter(center: curve["control_points"][0], width: curve["width"], height: curve["height"]);
      curve["restricted_control_points"][2] = curve["control_points"][0] + Offset.fromDirection((Offset(curve["restricted_control_points"][2].dx, stationary.dy + (curve["restricted_control_points"][2].dy - stationary.dy) * scaleFactor) - curve["control_points"][0]).direction, (rect.center - rect.bottomRight).distance);
      double rotationAdjustedAngle = (curve["restricted_control_points"][2] - rect.center).direction;
      Matrix4 rotationMatrix = rotateZAbout(rotationAdjustedAngle, rect.center);
      curve["restricted_control_points"][0] = matrixApply(rotationMatrix, getConicOffset(rect, getConicDirection(rect, (curve["restricted_control_points"][0] - rect.center).direction - rotationAdjustedAngle)));
      curve["restricted_control_points"][1] = matrixApply(rotationMatrix, getConicOffset(rect, getConicDirection(rect, (curve["restricted_control_points"][1] - rect.center).direction - rotationAdjustedAngle)));
      return curve;
    case EditingMode.Conic:
      Rect rect = Rect.fromCenter(center: curve["control_points"][0], width: curve["width"], height: curve["height"]);
      curve["restricted_control_points"][0] = curve["control_points"][0] + Offset.fromDirection((Offset(curve["restricted_control_points"][0].dx, stationary.dy + (curve["restricted_control_points"][0].dy - stationary.dy) * scaleFactor) - curve["control_points"][0]).direction, (rect.center - rect.bottomRight).distance);
      return curve;
    default:
      return curve;
  }
}

Map<String, dynamic> getDataPointsByVerticalScale(EditingMode mode, Map<String, dynamic> curve, Offset stationary, double scaleFactor){
  switch(mode){
    case EditingMode.Arc:
      curve["height"] = curve["height"] * scaleFactor;
      curve["data_control_points"][0] = Rect.fromCenter(center: curve["control_points"][0], width: curve["width"], height: curve["height"]).bottomRight;
      return curve;
    case EditingMode.Conic:
      curve["height"] = curve["height"] * scaleFactor;
      curve["data_control_points"][0] = curve["control_points"][0] + Offset(curve["width"] / 2, curve["height"] / 2);
      return curve;
    default:
      return curve;
  }
}

List<Offset> scale(List<Offset> points, Offset stationary, Offset scaleFactor){
  List<Offset> scaled = [];
  for(Offset point in points){
    scaled.add(
        Offset(stationary.dx + (point.dx - stationary.dx) * scaleFactor.dx, stationary.dy + (point.dy - stationary.dy) * scaleFactor.dy)
    );
  }
  return scaled;
}

Map<String, dynamic> getRestrictedPointsByScale(EditingMode mode, Map<String, dynamic> curve, Offset stationary, Offset scaleFactor){
  switch(mode){
    case EditingMode.Arc:
      Rect rect = Rect.fromCenter(center: curve["control_points"][0], width: curve["width"], height: curve["height"]);
      curve["restricted_control_points"][2] = curve["control_points"][0] + Offset.fromDirection((Offset(stationary.dx + (curve["restricted_control_points"][2].dx - stationary.dx) * scaleFactor.dx, stationary.dy + (curve["restricted_control_points"][2].dy - stationary.dy) * scaleFactor.dy) - curve["control_points"][0]).direction, (rect.center - rect.bottomRight).distance);
      double rotationAdjustedAngle = (curve["restricted_control_points"][2] - rect.center).direction;
      Matrix4 rotationMatrix = rotateZAbout(rotationAdjustedAngle, rect.center);
      curve["restricted_control_points"][0] = matrixApply(rotationMatrix, getConicOffset(rect, getConicDirection(rect, (curve["restricted_control_points"][0] - rect.center).direction - rotationAdjustedAngle)));
      curve["restricted_control_points"][1] = matrixApply(rotationMatrix, getConicOffset(rect, getConicDirection(rect, (curve["restricted_control_points"][1] - rect.center).direction - rotationAdjustedAngle)));
      return curve;
    case EditingMode.Conic:
      Rect rect = Rect.fromCenter(center: curve["control_points"][0], width: curve["width"], height: curve["height"]);
      curve["restricted_control_points"][0] = curve["control_points"][0] + Offset.fromDirection((Offset(stationary.dx + (curve["restricted_control_points"][0].dx - stationary.dx) * scaleFactor.dx, stationary.dy + (curve["restricted_control_points"][0].dy - stationary.dy) * scaleFactor.dy) - curve["control_points"][0]).direction, (rect.center - rect.bottomRight).distance);
      return curve;
    default:
      return curve;
  }
}

Map<String, dynamic> getDataPointsByScale(EditingMode mode, Map<String, dynamic> curve, Offset stationary, Offset scaleFactor){
  switch(mode){
    case EditingMode.Arc:
      curve["height"] = curve["height"] * scaleFactor.dy;
      curve["width"] = curve["width"] * scaleFactor.dx;
      curve["data_control_points"][0] = Rect.fromCenter(center: curve["control_points"][0], width: curve["width"], height: curve["height"]).bottomRight;
      return curve;
    case EditingMode.Conic:
      curve["height"] = curve["height"] * scaleFactor.dy;
      curve["width"] = curve["width"] * scaleFactor.dx;
      curve["data_control_points"][0] = Rect.fromCenter(center: curve["control_points"][0], width: curve["width"], height: curve["height"]).bottomRight;
      return curve;
    default:
      return curve;
  }
}

Path getDirectedLinePath(List<Offset> endPoints){
  assert(endPoints.length == 2, "Require exactly 2 points for a directed line");
  Path directedLine = Path();
  Offset start = endPoints[0];
  Offset pointer = endPoints[1];
  directedLine.moveTo(start.dx, start.dy);
  directedLine.lineTo(pointer.dx, pointer.dy);
  double direction = (pointer - start).direction;
  directedLine.addPolygon(
      [
        pointer + Offset.fromDirection(direction, 6),
        pointer + Offset.fromDirection(direction + (2 * pi / 3), 6),
        pointer + Offset.fromDirection(direction + (4 * pi / 3), 6),
      ], true);
  return directedLine;
}

Path getCurveDirectedLinePath(List<Offset> controlPoints){
  assert(controlPoints.length == 2, "Require exactly 2 points for a curve directed line");
  Path curveDirectedLine = Path();
  Offset start = controlPoints[0];
  Offset pointer = controlPoints[1];
  double direction = (pointer - start).direction;
  double gap = (pointer - start).distance * 0.2;
  Offset controlPoint1 = start + ((pointer - start) / 3) + Offset.fromDirection(direction + pi / 2, gap);
  Offset controlPoint2 = start + ((pointer - start) * 2 / 3) + Offset.fromDirection(direction - pi / 2, gap);
  curveDirectedLine.moveTo(start.dx, start.dy);
  curveDirectedLine.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, pointer.dx, pointer.dy);
  curveDirectedLine.addPolygon(
      [
        pointer + Offset.fromDirection(direction, 6),
        pointer + Offset.fromDirection(direction + (2 * pi / 3), 6),
        pointer + Offset.fromDirection(direction + (4 * pi / 3), 6),
      ], true);
  return curveDirectedLine;
}

Path getEndArrow(List<Offset> controlPoints){
  assert(controlPoints.length == 2, "Require exactly 2 points for end arrow");
  Path curveDirectedLinePointer = Path();
  Offset start = controlPoints[0];
  Offset pointer = controlPoints[1];
  double direction = (pointer - start).direction;
  curveDirectedLinePointer.addPolygon(
      [
        pointer + Offset.fromDirection(direction, 6),
        pointer + Offset.fromDirection(direction + (2 * pi / 3), 6),
        pointer + Offset.fromDirection(direction + (4 * pi / 3), 6),
      ], true);
  return curveDirectedLinePointer;
}