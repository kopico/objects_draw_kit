import 'package:flutter/material.dart';

import 'dart:ui';

import 'package:objects_draw_kit/tools/spline_path.dart';
import 'package:objects_draw_kit/tools/utils.dart';

// class EditingMode{
//   final String mode;
//
//   static EditingMode None = EditingMode("none");
//   static EditingMode Line = EditingMode("line");
//   static EditingMode Arc = EditingMode("arc");
//   static EditingMode SplineCurve = EditingMode("spline_curve");
//   static EditingMode QuadraticBezier = EditingMode("quadratic_bezier");
//   static EditingMode CubicBezier = EditingMode("cubic_bezier");
//   static EditingMode Polygon = EditingMode("polygon");
//   static EditingMode Conic = EditingMode("conic");
//   static EditingMode Arrow = EditingMode("arrow");
//   static EditingMode Heart = EditingMode("heart");
//   static EditingMode Star = EditingMode("star");
//   static EditingMode Leaf = EditingMode("leaf");
//   static EditingMode DirectedLine = EditingMode("directed_line");
//   static EditingMode CurvedDirectedLine = EditingMode("curved_directed_line");
//   static EditingMode FreeDraw = EditingMode("free_draw");
//   static EditingMode GroupCurve = EditingMode("group_curve");
//   static EditingMode CompositeCurve = EditingMode("composite_curve");
//   static EditingMode CompositeShape = EditingMode("composite_shape");
//
//   EditingMode(this.mode);
//
//   @override
//   String toString(){
//     return mode;
//   }
//
//   @override
//   bool operator ==(Object other){
//     return mode == other.toString();
//   }
//
//   @override
//   int get hashCode => mode.hashCode;
// }

abstract class ODKPath{

  // Also known as control points of the currently editing curve.
  // Active path points are free to move around any where in the canvas.
  List<Offset> points = <Offset>[];

  // Also known as restricted control points of the currently editing curve.
  // Active restricted path points movements are restricted by the type of curve
  // it is and the control points of the curve. Both restricted and unrestricted
  // control points are points which falls on the path of the curve, and
  // therefore can be transformed globally.
  List<Offset> rPoints = <Offset>[];

  // Data control points are free to be placed any where, but cannot be
  // transformed like control points because of distortion. Data points are
  // in place to enable quick determination of parameters like size of the objects.
  // During transformation, the parameters of the curve will determine the location of data
  // points, unlike control points and restricted control points.
  List<Offset> dPoints = <Offset>[];

  // Paint for outline of the shape using stroke painting style.
  Paint sPaint = Paint()
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  // Records whether to draw the outline of the object
  bool outlined = true;

  // Paint for the interior of the object using fill painting style.
  // Any shader values are also encoded within this property
  Paint fPaint = Paint()
    ..style = PaintingStyle.fill;

  // Records whether to fill the object's interior
  bool filled = false;

  // The bounding rectangle of this path
  Rect bound = Rect.zero;

  // The method called before passing the object to the web cloud storage
  Map<String, dynamic> odkToJson(){
    List<Map<String, double>> pts = [for(Offset p in points) {"x": p.dx, "y": p.dy}];
    List<Map<String, double>> rpts = [for(Offset p in rPoints) {"x": p.dx, "y": p.dy}];
    List<Map<String, double>> dpts = [for(Offset p in dPoints) {"x": p.dx, "y": p.dy}];
    return {
      "filled": filled,
      "fill_paint_color": fPaint.color,
      "fill_paint_shader_data": [],
      "outlined": outlined,
      "stroke_paint_color": sPaint.color,
      "stroke_paint_width": sPaint.strokeWidth,
      "points": pts,
      "restricted_points": rpts,
      "data_points": dpts,
    };
  }

  // The method called before passing the object to the web cloud storage. For
  // individual objects to override with specific implementations of different
  // paths.
  Map<String, dynamic> toJson();

  // The method called to restore the object format of this path when received
  // from the cloud.
  void toODK(Map<String, dynamic> data, {bool parsePoints = true}){
    if(parsePoints){
      List<Map<String, double>> cpData = [for(Map o in data['points']) Map.from(o)];
      List<Map<String, double>> rcpData = [for(Map o in data['restricted_points']) Map.from(o)];
      List<Map<String, double>> dcpData = [for(Map o in data['data_points']) Map.from(o)];
      for(int i = 0; i < cpData.length; i++){
        points += [Offset(cpData[i]['x']!, cpData[i]['y']!)];
      }
      for(int i = 0; i < rcpData.length; i++){
        rPoints += [Offset(rcpData[i]['x']!, rcpData[i]['y']!)];
      }
      for(int i = 0; i < dcpData.length; i++){
        dPoints += [Offset(dcpData[i]['x']!, dcpData[i]['y']!)];
      }
    }
    sPaint.strokeWidth = data["stroke_paint_width"];
    var scol = data["stroke_paint_color"];
    sPaint.color = Color.fromARGB(scol[0], scol[1], scol[2], scol[3]);
    var fcol = data["fill_paint_color"];
    fPaint.color = Color.fromARGB(fcol[0], fcol[1], fcol[2], fcol[3]);
    var fShader = data["fill_paint_shader_data"];
    // To parse shader data into shader
    // fPaint.shader =
    filled = data["filled"];
    outlined = data["outlined"];
  }

  ODKPath toObject(Map<String, dynamic> data);

  void updateStrokePaint({double? strokeWidth, Color? color}){
    if(strokeWidth != null){
      sPaint.strokeWidth = strokeWidth;
    }
    if(color != null){
      sPaint.color = color;
    }
  }

  void updateFillPaint({Shader? shader, Color? color}){
    if(shader != null){
      fPaint.shader = shader;
    }
    if(color != null){
      fPaint.color = color;
    }
  }
}

class FreeDraw extends ODKPath{

  EditingMode mode = EditingMode.FreeDraw;

  SplinePath splinePath = SplinePath([]);

  FreeDraw(this.splinePath);

  // Records whether this path is a closed path
  bool close = false;

  @override
  Map<String, dynamic> toJson(){
    Map<String, dynamic> data = odkToJson();
    data.addAll({
      "mode": mode.toString(),
      "close": close,
      "tension": splinePath.tension,
      "has_metrics": splinePath.metric != null,
    });
    return data;
  }

  @override
  FreeDraw toObject(Map<String, dynamic> data){
    List<Map<String, double>> cpData = [for(Map o in data['points']) Map.from(o)];
    List<Offset> pts = <Offset>[];
    for(int i = 0; i < cpData.length; i++){
      pts += [Offset(cpData[i]['x']!, cpData[i]['y']!)];
    }
    SplinePath splinePath = SplinePath.generate(pts, tension: data["tension"]);
    splinePath.endDraw();
    if(data["has_metrics"]){
      splinePath.getMetrics();
    }
    FreeDraw fd = FreeDraw(splinePath);
    fd.toODK(data, parsePoints: false);
    fd.close = data["close"];
    return fd;
  }
}

// Composite objects draw kit curve. This is a composite curve which can comprise
// straight-edged lines, arcs, CatmullRom splines, quadratic bezier and cubic
// bezier curves
class ODKCompositeCurve extends ODKPath{

  EditingMode mode = EditingMode.CompositeCurve;

  // Records whether this path is a closed path
  bool close = false;

  List<EditingMode> composites = [];

  @override
  Map<String, dynamic> toJson(){
    Map<String, dynamic> data = odkToJson();
    data.addAll({
      "mode": mode.toString(),
      "close": close,
      "composites": composites.map((e) => e.toString()),
    });
    return data;
  }

  @override
  ODKCompositeCurve toObject(Map<String, dynamic> data){
    ODKCompositeCurve compositeCurve = ODKCompositeCurve();
    compositeCurve.toODK(data);
    compositeCurve.close = data["close"];
    compositeCurve.composites = List<EditingMode>.from(data["composites"].map((e) => getModeString(e)));
    return compositeCurve;
  }
}

class ODKCompositeShape extends ODKPath{

  EditingMode mode = EditingMode.CompositeShape;

  bool isRegular = false;

  List<EditingMode> composites = [];

  @override
  Map<String, dynamic> toJson(){
    Map<String, dynamic> data = odkToJson();
    data.addAll({
      "mode": mode.toString(),
      "is_regular": isRegular,
      "composites": composites.map((e) => e.toString()),
    });
    return data;
  }

  @override
  ODKCompositeShape toObject(Map<String, dynamic> data){
    ODKCompositeShape compositeShape = ODKCompositeShape();
    compositeShape.toODK(data);
    compositeShape.isRegular = data["is_regular"];
    compositeShape.composites = List<EditingMode>.from(data["composites"].map((e) => getModeString(e)));
    return compositeShape;
  }
}

class ODKLine extends ODKPath{

  EditingMode mode = EditingMode.Line;

  bool chained = false;

  @override
  Map<String, dynamic> toJson(){
    Map<String, dynamic> data = odkToJson();
    data.addAll({
      "mode": mode.toString(),
      "is_chained": chained,
    });
    return data;
  }

  @override
  ODKLine toObject(Map<String, dynamic> data){
    ODKLine odkLine = ODKLine();
    odkLine.toODK(data);
    odkLine.chained = data["is_chained"];
    return odkLine;
  }
}

class ODKArc extends ODKPath{

  EditingMode mode = EditingMode.Arc;

  bool chained = false;

  @override
  Map<String, dynamic> toJson(){
    Map<String, dynamic> data = odkToJson();
    data.addAll({
      "mode": mode.toString(),
      "is_chained": chained,
    });
    return data;
  }

  @override
  ODKArc toObject(Map<String, dynamic> data){
    ODKArc odkArc = ODKArc();
    odkArc.toODK(data);
    odkArc.chained = data["is_chained"];
    return odkArc;
  }
}

class ODKSplineCurve extends ODKPath{

  EditingMode mode = EditingMode.SplineCurve;

  bool chained = false;

  @override
  Map<String, dynamic> toJson(){
    Map<String, dynamic> data = odkToJson();
    data.addAll({
      "mode": mode.toString(),
      "is_chained": chained,
    });
    return data;
  }

  @override
  ODKSplineCurve toObject(Map<String, dynamic> data){
    ODKSplineCurve odkSplineCurve = ODKSplineCurve();
    odkSplineCurve.toODK(data);
    odkSplineCurve.chained = data["is_chained"];
    return odkSplineCurve;
  }
}

class ODKQuadraticBezier extends ODKPath{

  EditingMode mode = EditingMode.QuadraticBezier;

  bool chained = false;

  @override
  Map<String, dynamic> toJson(){
    Map<String, dynamic> data = odkToJson();
    data.addAll({
      "mode": mode.toString(),
      "is_chained": chained,
    });
    return data;
  }

  @override
  ODKQuadraticBezier toObject(Map<String, dynamic> data){
    ODKQuadraticBezier odkQuadraticBezier = ODKQuadraticBezier();
    odkQuadraticBezier.toODK(data);
    odkQuadraticBezier.chained = data["is_chained"];
    return odkQuadraticBezier;
  }
}

class ODKCubicBezier extends ODKPath{

  EditingMode mode = EditingMode.CubicBezier;

  bool chained = false;

  @override
  Map<String, dynamic> toJson(){
    Map<String, dynamic> data = odkToJson();
    data.addAll({
      "mode": mode.toString(),
      "is_chained": chained,
    });
    return data;
  }

  @override
  ODKCubicBezier toObject(Map<String, dynamic> data){
    ODKCubicBezier odkCubicBezier = ODKCubicBezier();
    odkCubicBezier.toODK(data);
    odkCubicBezier.chained = data["is_chained"];
    return odkCubicBezier;
  }
}

class ODKPolygon extends ODKPath{

  EditingMode mode = EditingMode.Polygon;

  int? nodeLimit;

  ODKPolygon({this.nodeLimit});

  @override
  Map<String, dynamic> toJson(){
    Map<String, dynamic> data = odkToJson();
    data.addAll({
      "mode": mode.toString(),
      "node_limit": nodeLimit ?? -1,
    });
    return data;
  }

  @override
  ODKPolygon toObject(Map<String, dynamic> data){
    int? limit = data["node_limit"] != -1 ? data["node_limit"] : null;
    ODKPolygon odkPolygon = ODKPolygon(nodeLimit: limit);
    odkPolygon.toODK(data);
    return odkPolygon;
  }
}

class ODKConic extends ODKPath{

  EditingMode mode = EditingMode.Conic;

  ODKConic();

  @override
  Map<String, dynamic> toJson(){
    Map<String, dynamic> data = odkToJson();
    data.addAll({
      "mode": mode.toString(),

    });
    return data;
  }

  @override
  ODKConic toObject(Map<String, dynamic> data){
    ODKConic odkConic = ODKConic();
    odkConic.toODK(data);
    return odkConic;
  }
}

class ODKHeart extends ODKPath{

  EditingMode mode = EditingMode.Heart;

  ODKHeart();

  @override
  Map<String, dynamic> toJson(){
    Map<String, dynamic> data = odkToJson();
    data.addAll({
      "mode": mode.toString(),

    });
    return data;
  }

  @override
  ODKHeart toObject(Map<String, dynamic> data){
    ODKHeart odkHeart = ODKHeart();
    odkHeart.toODK(data);
    return odkHeart;
  }
}

class ODKStar extends ODKPath{

  EditingMode mode = EditingMode.Leaf;

  ODKStar();

  @override
  Map<String, dynamic> toJson(){
    Map<String, dynamic> data = odkToJson();
    data.addAll({
      "mode": mode.toString(),
    });
    return data;
  }

  @override
  ODKStar toObject(Map<String, dynamic> data){
    ODKStar odkStar = ODKStar();
    odkStar.toODK(data);
    return odkStar;
  }
}

class ODKArrow extends ODKPath{

  EditingMode mode = EditingMode.Arrow;

  ODKArrow();

  @override
  Map<String, dynamic> toJson(){
    Map<String, dynamic> data = odkToJson();
    data.addAll({
      "mode": mode.toString(),
    });
    return data;
  }

  @override
  ODKArrow toObject(Map<String, dynamic> data){
    ODKArrow odkArrow = ODKArrow();
    odkArrow.toODK(data);
    return odkArrow;
  }
}

class ODKLeaf extends ODKPath{

  EditingMode mode = EditingMode.Leaf;

  ODKLeaf();

  @override
  Map<String, dynamic> toJson(){
    Map<String, dynamic> data = odkToJson();
    data.addAll({
      "mode": mode.toString(),
    });
    return data;
  }

  @override
  ODKLeaf toObject(Map<String, dynamic> data){
    ODKLeaf odkLeaf = ODKLeaf();
    odkLeaf.toODK(data);
    return odkLeaf;
  }
}

class ODKDirectedLine extends ODKPath{

  EditingMode mode = EditingMode.DirectedLine;

  ODKDirectedLine();

  @override
  Map<String, dynamic> toJson(){
    Map<String, dynamic> data = odkToJson();
    data.addAll({
      "mode": mode.toString(),
    });
    return data;
  }

  @override
  ODKDirectedLine toObject(Map<String, dynamic> data){
    ODKDirectedLine odkDirectedLine = ODKDirectedLine();
    odkDirectedLine.toODK(data);
    return odkDirectedLine;
  }
}

class ODKCurvedDirectedLine extends ODKPath{

  EditingMode mode = EditingMode.CurveDirectedLine;

  ODKCurvedDirectedLine();

  @override
  Map<String, dynamic> toJson(){
    Map<String, dynamic> data = odkToJson();
    data.addAll({
      "mode": mode.toString(),
    });
    return data;
  }

  @override
  ODKCurvedDirectedLine toObject(Map<String, dynamic> data){
    ODKCurvedDirectedLine odkCurvedDirectedLine = ODKCurvedDirectedLine();
    odkCurvedDirectedLine.toODK(data);
    return odkCurvedDirectedLine;
  }
}

class ODKGroupCurve extends ODKPath{

  EditingMode mode = EditingMode.GroupCurve;

  List<EditingMode> modeMap = [];

  ODKGroupCurve();

  @override
  Map<String, dynamic> toJson(){
    Map<String, dynamic> data = odkToJson();
    data.addAll({
      "mode": mode.toString(),
    });
    return data;
  }

  @override
  ODKGroupCurve toObject(Map<String, dynamic> data){
    ODKGroupCurve odkGroupCurve = ODKGroupCurve();
    odkGroupCurve.toODK(data);
    return odkGroupCurve;
  }

  List<EditingMode> recoverModeMap(String modeMapString){
    return [];
  }
}