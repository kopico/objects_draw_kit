import 'dart:math' show Random;

enum EditingMode{
  None, Point, Line, QuadraticBezier, CubicBezier, Arc, Conic, SplineCurve,
  Triangle, Rectangle, Pentagon, Polygon, FreeDraw, Fill, Image, GroupCurve,
  Star, Heart, Arrow, Leaf, DirectedLine, CurveDirectedLine, CompositeCurve,
  CompositeShape, Wave
}

EditingMode getMode(String modeString){
  String mode = modeString.substring(12);
  switch(mode){
    case "None":
      return EditingMode.None;
    case "Point":
      return EditingMode.Point;
    case "Line":
      return EditingMode.Line;
    case "QuadraticBezier":
      return EditingMode.QuadraticBezier;
    case "CubicBezier":
      return EditingMode.CubicBezier;
    case "Arc":
      return EditingMode.Arc;
    case "Conic":
      return EditingMode.Conic;
    case "SplineCurve":
      return EditingMode.SplineCurve;
    case "Triangle":
      return EditingMode.Triangle;
    case "Rectangle":
      return EditingMode.Rectangle;
    case "Pentagon":
      return EditingMode.Pentagon;
    case "Polygon":
      return EditingMode.Polygon;
    case "FreeDraw":
      return EditingMode.FreeDraw;
    case "Fill":
      return EditingMode.Fill;
    case "Image":
      return EditingMode.Image;
    case "GroupCurve":
      return EditingMode.GroupCurve;
    case "Star":
      return EditingMode.Star;
    case "Heart":
      return EditingMode.Heart;
    case "Arrow":
      return EditingMode.Arrow;
    case "Leaf":
      return EditingMode.Leaf;
    case "DirectedLine":
      return EditingMode.DirectedLine;
    case "CurveDirectedLine":
      return EditingMode.CurveDirectedLine;
    case "CompositeCurve":
      return EditingMode.CompositeCurve;
    case "CompositeShape":
      return EditingMode.CompositeShape;
    case "Wave":
      return EditingMode.Wave;
    default:
      return EditingMode.None;
  }
}

String getModeString(EditingMode mode){
  String e = "EditingMode.";
  return mode.toString().substring(e.length);
}

String validNumericChars = "0123456789.";

bool isNumeric(String string){

  if(string == ""){
    return false;
  }
  for(int i = 0; i < string.length; i++){
    if(!validNumericChars.contains(string[i])){
      return false;
    }
  }
  return true;
}

double incrementZoomFactor(double factor){
  if(factor == 1){
    return 1.1;
  } else if (factor == 1.1){
    return 1.25;
  } else if (factor == 1.25){
    return 1.5;
  } else if (factor == 1.5){
    return 2.0;
  } else if (factor == 2.0){
    return 2.5;
  } else if (factor == 2.5){
    return 3.0;
  } else if (factor == 3.0){
    return 4.0;
  } else {
    return factor;
  }
}

double decrementZoomFactor(double factor){
  if (factor == 1.1){
    return 1.0;
  } else if(factor == 1.25){
    return 1.1;
  } else if (factor == 1.5){
    return 1.25;
  } else if (factor == 2.0){
    return 1.5;
  } else if (factor == 2.5){
    return 2.0;
  } else if (factor == 3.0){
    return 2.5;
  } else if (factor == 4.0){
    return 3.0;
  } else {
    return factor;
  }
}

String removeInvalidChars(String string){
  String output = "";
  if (string == ""){
    return output;
  } else {
    for(int i = 0; i < string.length; i++){
      if(validNumericChars.contains(string[i])){
        output = output + string[i];
      }
    }
  }
  return output;
}

bool isPathMode(EditingMode mode){
  return mode != EditingMode.Fill && mode != EditingMode.Image;
}

bool isShapeMode(EditingMode mode){
  return mode == EditingMode.Polygon || mode == EditingMode.Triangle || mode == EditingMode.Rectangle || mode == EditingMode.Pentagon || mode == EditingMode.Star;
}

bool isLineOrCurve(EditingMode mode){
  return mode == EditingMode.Line || mode == EditingMode.Arc || mode == EditingMode.SplineCurve || mode == EditingMode.QuadraticBezier || mode == EditingMode.CubicBezier;
}

bool requireDataPoint(EditingMode mode){
  return mode == EditingMode.Arc || mode == EditingMode.Conic;
}

bool isInteger(String string){
  String digits = "0123456789";
  if(string == "" || string.substring(0,1) == "0"){
    return false;
  }
  for(int i = 0; i < string.length; i++){
    if(!digits.contains(string[i])){
      return false;
    }
  }
  return true;
}

enum DrawAction{
  // General curve editing actions
  changeCurveAttribute, duplicateCurve, deleteCurve,
  // Non-free-draw curve editing actions
  transformControlPoints, addControlPoint, moveControlPoint,
  // Free-draw curve editing actions
  addFreeDraw, transformFreeDraw,
  // General editing actions,
  alterBackgroundImage, changeMode, groupCurves, unGroupCurves,
  // Paint editing actions,
  changePaintColor, changePaintStrokeWidth, changePaintShader, changeFillColor
}

enum TransformCurve{
  Translate, Rotate, FlipHorizontal, FlipVertical, ScaleHorizontal, ScaleVertical, Scale, Skew, None, moveControlPoint, moveRestrictedControlPoint, moveDataControlPoint,
}

int idLength = "voYseacjezd69J9bCFM6jIBJlL63".length;

var rand = Random(int.parse((DateTime.now().millisecondsSinceEpoch % 314159265358979328).toString()));

bool noCapitalOrSmallLetterOrNumber(String pw) {
  String capitalLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  String smallLetters = "abcdefghijklmnopqrstuvwxyz";
  String numbers = "0123456789";
  int length = pw.length;
  for (int index = 0; index < length; index++) {
    if (capitalLetters.contains(pw[index]) ||
        smallLetters.contains(pw[index]) || numbers.contains(pw[index])) {
      return false;
    }
  }
  return true;
}

bool notValidPassword(String pw) {
  if (pw.length < 8 || noCapitalOrSmallLetterOrNumber(pw)) {
    return true;
  }
  return false;
}

String generateAutoID(){
  final baseString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  int baseStringLength = baseString.length;
  String outputString = "";
  for (int i = 0; i < idLength ; i++) {
    outputString += baseString[rand.nextInt(baseStringLength)];
  }
  return outputString;
}

String getDateString(DateTime dateTime){
  return "${dateTime.day}-${dateTime.month}-${dateTime.year}";
}

String getTimeString(DateTime dateTime){
  return "${dateTime.hour}:${dateTime.minute}";
}

enum LoginStatus{LOGGED_IN, LOGGED_OUT, LOGIN_SUCCESS, LOGIN_SUCCESS_AND_CREATING_ACCOUNT, LOGIN_FAILED, LOGOUT_SUCCESS, LOGOUT_FAILED, REAUTHENTICATE_SUCCESS, REAUTHENTICATE_FAILED, EMAIL_UNVERIFIED}

