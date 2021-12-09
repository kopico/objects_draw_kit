import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';

import 'dart:ui';
import 'dart:math' show pi;

import 'package:objects_draw_kit/tools/draw_pad.dart';
import 'package:objects_draw_kit/tools/utils.dart';

double _defaultInterpolatingGapWidth = 0.6;

double _toleranceWidth = 0.9;

class SplinePath{

  List<Offset> points;

  final double tension;

  Path splinePath = Path();

  PathMetric? metric;

  bool get isNotEmpty => points.isNotEmpty || cachePoints.isNotEmpty;

  List<Offset> cachePoints = [];

  bool drawEnd = false;

  SplinePath(this.points, {this.tension: 0})
      : assert(tension <= 1.0 && tension >= 0),
      super();

  SplinePath.generate(this.points, {this.tension: 0})
      : assert(tension <= 1.0 && tension >= 0),
        super(){
    if(points.length <= 3){
      splinePath.addPolygon(points, false);
    } else {
      CatmullRomSpline cmrc = CatmullRomSpline.precompute(points, tension: tension,);
      List<Curve2DSample> sampleList = cmrc.generateSamples().toList(growable: false);
      sampleList.sort((a,b) => (a.t).compareTo(b.t));
      splinePath.moveTo(sampleList.first.value.dx, sampleList.first.value.dy);
      for(Curve2DSample p in sampleList){
        splinePath.lineTo(p.value.dx, p.value.dy);
      }
    }
  }

  void generate(List<Offset> pts, {bool firstIteration: false}){
    assert(pts.length > 3);
    List<Curve2DSample> sampleList = CatmullRomSpline(pts, tension: tension).generateSamples().toList(growable: false);
    sampleList.sort((a,b) => (a.t).compareTo(b.t));
    if(firstIteration)
      splinePath.moveTo(sampleList.first.value.dx, sampleList.first.value.dy);
    else
      splinePath.lineTo(sampleList.first.value.dx, sampleList.first.value.dy);
    for(Curve2DSample p in sampleList){
      splinePath.lineTo(p.value.dx, p.value.dy);
    }
  }

  void addSingleStartPoint(Offset p){
    assert(points.isEmpty && cachePoints.isEmpty, "Points or cache points are not empty.");
    cachePoints.add(p);
  }

  void addSinglePoint(Offset p, {double dist: double.infinity}){
    if(dist > _defaultInterpolatingGapWidth){
      cachePoints.add(p);
      if (cachePoints.length == 4){
        generate(cachePoints, firstIteration: points.isEmpty);
        points.addAll(cachePoints);
        cachePoints = [];
      }
    }
  }

  void shiftSplinePath(Offset delta){
    // for quick shift
    splinePath = splinePath.shift(delta);
  }

  void shiftPoints(Offset delta){
    for(int i = 0; i < points.length; i++){
      points[i] += delta;
    }
  }

  void smoothen({double delta = pi / 12, double smallSpacing = 5, double largeSpacing = 20}){
    List<Offset> finalPoints = [points[0]];
    if(points.length + cachePoints.length <= 3){
      return;
    }
    points.addAll(cachePoints);
    cachePoints = [];
    double currentDirection = (points[1] - points[0]).direction;
    print("Smoothening with ${points.length} control points. First point: ${points.first}");
    for(int i = 2; i < points.length; i++){
      if((((points[i] - finalPoints.last).direction - currentDirection).abs() > delta && (points[i] - finalPoints.last).distance > smallSpacing) || ((points[i] - finalPoints.last).distance > largeSpacing)){
        currentDirection = (points[i] - finalPoints.last).direction;
        finalPoints.add(points[i]);
      }
    }
    if(!finalPoints.contains(points.last)){
      finalPoints.add(points.last);
    }
    if(finalPoints.length <= 3){
      print("Smoothening not successful with delta: $delta");
    } else {
      splinePath = getCMRPath(finalPoints);
      points = finalPoints;
      print("Smoothening complete with ${points.length} control points left.");
    }
  }

  void closeSpline(){
    splinePath.close();
  }

  double? sampleNormalAtOffset(Offset offset){
    int index = points.indexOf(offset);
    assert(index != -1, "Offset must be a control point");
    CatmullRomSpline spline = CatmullRomSpline(points);
    Iterable<Curve2DSample> sample = spline.generateSamples();
    List<Offset> nearbyPoints = [];
    for(Curve2DSample s in sample){
      if(Rect.fromCenter(center: s.value, width: _toleranceWidth, height: _toleranceWidth).contains(offset)){
        nearbyPoints.add(s.value);
      }
      if(nearbyPoints.length == 3){
        break;
      }
    }
    if(nearbyPoints.length < 2){
      print("Insufficient sample points near offset $offset");
      return null;
    }
    double d1 = (nearbyPoints[1] - nearbyPoints[0]).direction;
    if(nearbyPoints.length == 3){
      double d2 = (nearbyPoints[2] - nearbyPoints[1]).direction;
      double d3 = (nearbyPoints.last - nearbyPoints.first).direction;
      return (d1 + d2 + d3) / 3 + pi /2 ;
    }
    return d1 + pi / 2;
  }


  void irregThicken({double maxWidth: 5, double tolerance: 0.8}){
    print("Start to thicken with ${points.length} control points.");
    List<Offset> irregMirrorPath1 = <Offset>[];
    List<Offset> irregMirrorPath2 = <Offset>[];
    for(Offset point in points){
      double? normal = sampleNormalAtOffset(point);
      if(normal != null){
        irregMirrorPath1.add(point + Offset.fromDirection(normal, 1.5 + 3.5 * rand.nextDouble()));
        irregMirrorPath2.add(point + Offset.fromDirection(normal + pi, 1.5 + 3.5 * rand.nextDouble()));
      }
    }
    points.clear();
    points = irregMirrorPath1 + irregMirrorPath2.reversed.toList();
    points.add(points.first);
    splinePath = getCMRPath(points);
    splinePath.close();
    print("Thicken completes with ${points.length} control points");
  }

  void taper({double maxWidth: 5, double endWidth : 0}){
    List<Offset> irregMirrorPath1 = <Offset>[];
    List<Offset> irregMirrorPath2 = <Offset>[];
    int length = points.length;
    double width = maxWidth - endWidth;
    for(int i = 0; i < length; i++){
      double? normal = sampleNormalAtOffset(points[i]);
      if(normal != null){
        irregMirrorPath1.add(points[i] + Offset.fromDirection(normal, maxWidth - (i * (width)) / length));
        irregMirrorPath2.add(points[i] + Offset.fromDirection(normal + pi, maxWidth - (i * (width)) / length));
      }
    }
    points.clear();
    points = irregMirrorPath1 + irregMirrorPath2.reversed.toList();
    points.add(points.first);
    splinePath = getCMRPath(points);
    splinePath.close();
  }

  void getMetrics(){
    metric = splinePath.computeMetrics().first;
  }

  void endDraw(){
    drawEnd = true;
  }

  void resetPath(){
    splinePath.reset();
    points.clear();
  }

  SplinePath endHandling(SplinePath splinePath, List<Offset> cache){
    if(cachePoints.isEmpty){
      return splinePath;
    }
    if(splinePath.points.isNotEmpty){
      if(cache.length == 1){
        splinePath.splinePath.lineTo(cache.first.dx, cache.first.dy);
        return splinePath;
      }
      if(cachePoints.length == 2){
        splinePath.splinePath.quadraticBezierTo(cache.first.dx, cache.first.dy, cache.last.dx, cache.last.dy,);
        return splinePath;
      }
      splinePath.generate([splinePath.points.last] + cache);
      return splinePath;
    }
    if(cache.length == 1){
      splinePath.splinePath.addOval(cachePoints.first & Size(2, 2));
      return splinePath;
    }
    splinePath.splinePath.addPolygon(cache, false);
    return splinePath;
  }

  Path drawThis(){
    if(drawEnd){
      endHandling(this, cachePoints);
      return splinePath;
    } else {
      Path cachePath = Path.from(splinePath);
      cachePath.addPolygon(cachePoints, false);
      return cachePath;
    }
  }
}