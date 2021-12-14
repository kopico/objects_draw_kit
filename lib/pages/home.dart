
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, User, UserCredential;
import 'package:image_picker/image_picker.dart';
import 'package:objects_draw_kit/static_assets/dialogs.dart';

import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:async';
import 'dart:math' show pi, sqrt2, min, max;

import 'package:objects_draw_kit/tools/draw_pad.dart';
import 'package:objects_draw_kit/tools/matrices.dart';
import 'package:objects_draw_kit/tools/utils.dart';
import 'package:objects_draw_kit/tools/spline_path.dart';
import 'package:objects_draw_kit/pages/preferences.dart';
import 'package:objects_draw_kit/pages/help_page.dart';
import 'package:objects_draw_kit/pages/login.dart';
import 'package:objects_draw_kit/static_assets/icon_sketch.dart';
import 'package:objects_draw_kit/static_assets/palette.dart';
import 'package:objects_draw_kit/io/web_io.dart';
import 'package:objects_draw_kit/static_assets/rulers.dart';
import 'package:objects_draw_kit/io/authentication.dart';


class Home extends StatefulWidget {
  const Home({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<Home> createState() => _HomeState();
}

double _standardCanvasWidth = 800.0;
double _standardCanvasHeight = 500.0;

Paint fillPaint = Paint()
  ..color = Colors.black
  ..style = PaintingStyle.fill;

Paint dataPaint = Paint()
  ..color = Colors.green
  ..style = PaintingStyle.fill;

Paint boundingPaint = Paint()
  ..color = Colors.grey[350]!
  ..strokeWidth = 1.0
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.stroke;

Paint boundingFill = Paint()
  ..color = Colors.grey[350]!
  ..style = PaintingStyle.fill;

Paint strokePaint = Paint()
  ..color = Colors.black
  ..strokeWidth = 1.0
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.stroke;

Paint actionPointPaint = Paint()
  ..color = Colors.black38
  ..strokeWidth = 5.0
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.stroke;

Paint shadowPaint = Paint()
  ..color = Colors.black
  ..shader = ui.Gradient
      .radial(
      const Offset(50, 300),
      5,
      [Colors.black, Colors.white],
  )
  ..strokeWidth = 3.0
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.fill;

double _tapSensitivityDistance = 10.0;
double _controlPointSize = 4.0;
const String _defaultDrawingName = "default_drawing_name";

class _HomeState extends State<Home> {

  EditingMode currentMode = EditingMode.None;

  bool showAddCurveMenu = false;

  // Sign in status
  String? userIdentifier;
  User? currentUser;
  String? currentDocId;
  String currentDrawingName = _defaultDrawingName;
  late WebIO webIO;

  // Action handling
  List<Map<DrawAction, dynamic>> actionStack = <Map<DrawAction, dynamic>>[];
  String? currentFilename;
  Reference? currentFileReference;

  // Path caching handling
  bool pathsCollectionChanged = false;
  List<Map<String, dynamic>> pathsCollection = <Map<String, dynamic>>[];
  int? currentEditingCurveIndex;

  // Scale and zoom handling
  double zoomFactor = 1.0;
  Float64List scaleThenTranslateMatrix = Matrix4.identity().storage;
  Offset panOffset = Offset.zero;

  // Active path handling
  int? indexOfSelectedRestrictedControlPoint;
  int? indexOfSelectedDataControlPoint;
  int? indexOfSelectedControlPoint;
  int? indexOfGroupedControlPointFrom;
  int? indexOfGroupedControlPointTo;
  int? indexOfGroupedRestrictedControlPointFrom;
  int? indexOfGroupedRestrictedControlPointTo;
  int? indexOfGroupedDataControlPointFrom;
  int? indexOfGroupedDataControlPointTo;
  Map<String, dynamic>? selectedGroupedCurve;
  Offset? pendingOffset;
  Offset? selectionOffset; // For group selection
  List<int> groupSelection = [];
  bool snapToGridNode = true;
  Offset? pointerHoveringPoint;

  // Curve transformation handling
  Rect? boundingRect;
  Offset? rotationControlPoint;
  Offset? horizontalScaleControlPoint;
  Offset? verticalScaleControlPoint;
  Offset? scaleControlPoint;
  double? panReference;
  double? panSecondReference;
  Offset? transformationReferenceOffset;
  List<Offset>? transformationReferenceOffsetList;
  bool readyToTransform = false;
  TransformCurve transformation = TransformCurve.None;

  // Paint and color handling
  bool showColorSelector = false;
  AnchorColor strokeAnchorColor = AnchorColor.red;
  AnchorColor fillAnchorColor = AnchorColor.red;
  int strokeAnchorColorValue = 64;
  int fillAnchorColorValue = 0;
  late Timer colorChangeTimer;
  int strokeRedInt = 64;
  int strokeGreenInt = 96;
  int strokeBlueInt = 255;
  int strokeAlphaInt = 255;
  int fillRedInt = 64;
  int fillGreenInt = 96;
  int fillBlueInt = 255;
  int fillAlphaInt = 255;
  Offset strokeColorPickerCursor = const Offset(255, 96);
  Offset fillColorPickerCursor = const Offset(255, 96);
  Offset? gradientPointer;
  Color gradientColor = const Color.fromARGB(255, 64, 96, 255);
  Color strokePendingColor = const Color.fromARGB(255, 64, 96, 255);
  Color fillPendingColor = const Color.fromARGB(255, 64, 96, 255);
  double strokeColorTabTopPosition = 50;
  double strokeColorTabRightPosition = 330;
  double fillColorTabTopPosition = 463;
  double fillColorTabRightPosition = 330;
  Paint currentStrokeColor = Paint()
    ..color = const Color.fromARGB(255, 64, 96, 255)
    ..strokeWidth = 2.0
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  Paint currentFillColor = Paint()
    ..color = const Color.fromARGB(255, 64, 96, 255)
  // Colors.transparent
    ..style = PaintingStyle.fill;

  // Stroke width handling
  bool showStrokeWidthSelector = false;

  // Image handling
  ImagePicker imagePicker = ImagePicker();
  XFile? backgroundImageFile;
  bool hasBackgroundImage = false;
  ui.Image? currentImage;
  bool backgroundImageChanged = false;

  // Keyboard controls
  FocusNode rawKeyboardFocusNode = FocusNode();
  bool ctrlKeyPressed = false;
  bool shiftKeyPressed = false;
  bool altKeyPressed = false;

  // Canvas preferences
  bool gridEnabled = false;
  bool gridChanged = false;
  bool enableRuler = true;
  double gridHorizontalGap = 40;
  double gridVerticalGap = 40;

  bool showPathsPanel = true;

  // Option Box
  double optionBoxTopPosition = 20;
  double optionBoxLeftPosition = 20;

  void reset(){
    currentMode = EditingMode.None;
    pathsCollection = <Map<String, dynamic>>[];
    currentEditingCurveIndex = null;
    boundingRect = null;
    actionStack.clear();
    rotationControlPoint = null;
    panReference = null;
    panSecondReference = null;
    scaleControlPoint = null;
    horizontalScaleControlPoint = null;
    verticalScaleControlPoint = null;
    pendingOffset = null;
    selectionOffset = null;
    zoomFactor = 1;
    panOffset = Offset.zero;
    scaleThenTranslateMatrix = Matrix4.identity().storage;
    readyToTransform = false;
    indexOfSelectedControlPoint = null;
    indexOfSelectedRestrictedControlPoint = null;
    indexOfSelectedDataControlPoint = null;
    backgroundImageFile = null;
    hasBackgroundImage = false;
    currentImage = null;
  }

  Future<void> createNewDoc() async {
    currentDocId = await webIO.createNewDrawing(currentDrawingName, pathsCollection);
  }

  PopupMenuItem<String> menuItem(String itemName, String val, {IconData? iconData, Map<String, dynamic>? arguments, bool enabled = true}){
    return PopupMenuItem(
        value: val,
        enabled: enabled,
        child: SizedBox(
            width: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (iconData != null)
                  SizedBox(
                      height: 30,
                      width: 30,
                      child: Icon(iconData, size: 24, color: Colors.white)
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Text(itemName, style: const TextStyle(fontSize: 16, color: Colors.white)
                    ),
                  ),
                ),
              ],
            )
        )
    );
  }

  Widget getSideBarButton(void Function()? buttonAction, IconData iconData, {String toolTipMessage = "", Widget? iconWidget}){
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SizedBox(
        width:24,
        height: 24,
        child: Tooltip(
          message: toolTipMessage,
          child: MaterialButton(
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
            color: Colors.black,
            child: iconWidget ?? Icon(iconData, size: 16, color: Colors.white),
            onPressed: buttonAction,
            disabledColor: Colors.black26,
          ),
        ),
      ),
    );
  }

  Widget getActionButton(
      BuildContext context, EditingMode mode, bool stateController,
      {IconData? iconData, Widget? widget, Semantics? semantics, void Function()? customOnPressed, void Function()? pressAndHoldCall, String toolTipMessage = ""}
      ){
    Widget iconWidget;
    if(widget != null){
      iconWidget = widget;
    } else if (iconData != null){
      iconWidget = Icon(iconData, size:24, color: Colors.white);
    } else {
      iconWidget = Container();
    }
    return Container(
      width: 32,
      height: 32,
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 4,
      ),
      child: Tooltip(
        message: toolTipMessage,
        child: MaterialButton(
          onPressed: customOnPressed ?? (){
            if(currentMode != mode){
              if(mode != EditingMode.FreeDraw){
                actionStack.add(
                    {DrawAction.changeMode: {
                      "original_mode": currentMode,
                      "original_editing_index": currentEditingCurveIndex
                    }});
                deactivateCurrentActivePath();

                setState(() {
                  showAddCurveMenu = false;
                  currentMode = mode;
                  pathsCollection.add({
                    "mode": mode,
                    // Also known as control points of the currently editing curve.
                    // Active path points are free to move around any where in the canvas.
                    "control_points": <Offset>[],
                    // Also known as restricted control points of the currently editing curve.
                    // Active restricted path points movements are restricted by the type of curve
                    // it is and the control points of the curve. Both restricted and unrestricted
                    // control points are points which falls on the path of the curve, and
                    // therefore can be transformed globally.
                    "restricted_control_points": <Offset>[],
                    // Data control points are free to be placed any where, but cannot be
                    // transformed like control points because of distortion. Data points are
                    // in place to enable quick determination of parameters like size of the objects.
                    // During transformation, the parameters of the curve will determine the location of data
                    // points, unlike control points and restricted control points.
                    "data_control_points": <Offset>[],
                    "stroke": copyPaint(currentStrokeColor),
                    "outlined": true,
                    "fill": copyPaint(currentFillColor),
                    "filled": false,
                    "bounding_rect": Rect.zero,
                  });
                  if(isLineOrCurve(mode)){
                    pathsCollection.last["close"] = false;
                    if(mode == EditingMode.Line){
                      pathsCollection.last["polygonal"] = false;
                    }
                    if(mode == EditingMode.QuadraticBezier || mode == EditingMode.CubicBezier){
                      pathsCollection.last["chained"] = false;
                    }
                  }
                  currentEditingCurveIndex = pathsCollection.length - 1;
                  if(isShapeMode(mode)){
                    pathsCollection[currentEditingCurveIndex!]["is_regular"] = false;
                  }
                  if(mode == EditingMode.Leaf){
                    pathsCollection[currentEditingCurveIndex!]["symmetric"] = true;
                    pathsCollection[currentEditingCurveIndex!]["orthogonal_symmetric"] = true;
                  }
                  if(mode == EditingMode.Conic){
                    pathsCollection[currentEditingCurveIndex!]["axial_lock"] = false;
                  }
                });
              } else {
                setState(() {
                  showAddCurveMenu = false;
                  currentMode = mode;
                  pathsCollection.add({
                    "mode": mode,
                    "free_draw_spline": SplinePath([]),
                    "control_points": <Offset>[],
                    "restricted_control_points": <Offset>[],
                    "data_control_points": <Offset>[],
                    "stroke": copyPaint(currentStrokeColor),
                    "outlined": true,
                    "fill": copyPaint(currentFillColor),
                    "filled": false,
                    "draw_end": false,
                    "close": false,
                    "bounding_rect": Rect.zero,
                  });
                  currentEditingCurveIndex = pathsCollection.length - 1;
                });
                actionStack.add(
                    {DrawAction.addFreeDraw: {
                      "editing_curve_index": currentEditingCurveIndex
                    }});
              }
            }
          },
          onLongPress: pressAndHoldCall,
          shape: const CircleBorder(),
          color: stateController ? Colors.cyanAccent : Colors.black,
          clipBehavior: Clip.hardEdge,
          hoverColor: Colors.cyanAccent,
          elevation: 4.0,
          padding: EdgeInsets.zero,
          child: iconWidget,
        ),
      ),
    );
  }

  List<Widget> subPathListWidget(List<Map<String, dynamic>> collection,){
    List<Widget> widgetList = [];
    for(int index = 0; index < collection.length; index++){
      Map<String, dynamic> subPath = collection[index];
      widgetList.add(
          Stack(
            key: ValueKey("${collection[index]["mode"]}$index"),
            children: [
              Container(
                padding: const EdgeInsets.all(4.0),
                child: MaterialButton(
                  onPressed:(){
                    if (currentEditingCurveIndex != index){
                      activatePath(index, subPath["mode"]);
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9.0),
                  ),
                  color: currentEditingCurveIndex == index || groupSelection.contains(index) ? Colors.grey : Colors.grey[300],
                  elevation: 10.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Row(
                        children: [
                          ReorderableDelayedDragStartListener(
                              index: index,
                              child: Card(
                                color: currentEditingCurveIndex == index || groupSelection.contains(index) ? Colors.grey : Colors.grey[300],
                                  margin: EdgeInsets.zero,
                                  child: const Icon(Icons.drag_handle, size:16, color: Colors.black))
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                            alignment: Alignment.centerLeft,
                            child: Text(getModeString(subPath["mode"]), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                          ),
                        ],
                      ),
                      if(subPath["mode"] != EditingMode.FreeDraw)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          alignment: Alignment.centerLeft,
                          child: Text("Control points: " + subPath["control_points"].toString(), textAlign: TextAlign.left),
                        ),
                      if(subPath["mode"] != EditingMode.FreeDraw)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          alignment: Alignment.centerLeft,
                          child: Text("Restricted control points: " + subPath["restricted_control_points"].toString(), textAlign: TextAlign.left),
                        ),
                    ]
                  )
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                  child: Row(
                    children:[
                      Container(
                        width: 32,
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical:4),
                        child: MaterialButton(
                          onPressed: (){
                            deactivateCurrentActivePath();
                            setState(() {
                              actionStack.add(
                                  {DrawAction.deleteCurve: {
                                    "deleted_curve": Map<String, dynamic>.from(pathsCollection[index]),
                                    "editing_curve_index": index,
                                  }
                                  });
                              pathsCollection.removeAt(index);
                            });
                          },
                          padding:EdgeInsets.zero,
                          shape: const CircleBorder(),
                          color: Colors.black,
                          child: const Icon(Icons.delete, size:16, color: Colors.white),
                        ),
                      ),
                    ]
                  ),
                ),
              ),
            ],
          )
      );
    }
    return widgetList;
  }

  Future<void> getSelectedImage(XFile imageFile) async {
    Uint8List data = await imageFile.readAsBytes();
    ui.instantiateImageCodec(Uint8List.view(data.buffer));
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(Uint8List.view(data.buffer), (ui.Image img) {
      return completer.complete(img);
    });
    ui.Image image = await completer.future;
    setState((){
      currentImage = image;
    });
  }

  void pickImage() async {
    XFile? imageFile = await imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if(imageFile != null){
      actionStack.add({
        DrawAction.alterBackgroundImage: {
          "original_background_file_path": backgroundImageFile?.path,
          "original_has_background_image": hasBackgroundImage,
        }
      });
      setState(() {
        backgroundImageFile = imageFile;
        hasBackgroundImage = true;
      });
      getSelectedImage(imageFile);
    }
  }

  void removeImage() async {
    if(backgroundImageFile != null){
      actionStack.add({
        DrawAction.alterBackgroundImage: {
          "original_background_file_path": backgroundImageFile!.path,
          "original_has_background_image": true,
        }
      });
      setState(() {
        backgroundImageChanged = true;
        backgroundImageFile = null;
        currentImage = null;
        hasBackgroundImage = false;
      });
    }
    if(currentImage != null){
      actionStack.add({
        DrawAction.alterBackgroundImage: {
          "original_image": currentImage,
          "original_has_background_image": true,
        }
      });
      setState(() {
        backgroundImageChanged = true;
        backgroundImageFile = null;
        currentImage = null;
        hasBackgroundImage = false;
      });
    }
  }

  void pickCurve(){
    setState((){
      showAddCurveMenu = !showAddCurveMenu;
    });
  }

  void pickStrokeWidth(){
    setState((){
      showStrokeWidthSelector = !showStrokeWidthSelector;
    });
  }

  void pickColor(){
    setState((){
      showColorSelector = !showColorSelector;
      if(showColorSelector){
        gradientPointer = const Offset(107.5, 150);
        gradientColor = currentStrokeColor.color;
        strokePendingColor = currentStrokeColor.color;
      }
    });
  }

  void pickFillColor(){
    setState((){
      showColorSelector = !showColorSelector;
      if(showColorSelector){
        gradientPointer = const Offset(107.5, 150);
        gradientColor = currentFillColor.color;
        strokePendingColor = currentFillColor.color;
      }
    });
  }

  void pickShader(){
    setState(() {
      throw UnimplementedError("To implement change of shader");
    });
  }

  void closeMenus(){
    if(showStrokeWidthSelector || showColorSelector || showAddCurveMenu){
      setState(() {
        showStrokeWidthSelector = false;
        showColorSelector = false;
        showAddCurveMenu = false;
      });
    }
  }

  void undoLastAction(){
    closeMenus();
    switch(actionStack.last.keys.first){
      case DrawAction.moveControlPoint:
        List<Offset> controlPoints = List<Offset>.from(actionStack.last[DrawAction.moveControlPoint]["control_points"]);
        List<Offset> restrictedControlPoints = List<Offset>.from(actionStack.last[DrawAction.moveControlPoint]["restricted_control_points"]);
        var editingCurveIndex = actionStack.last[DrawAction.moveControlPoint]["editing_curve_index"];
        var selectedPointIndex = actionStack.last[DrawAction.moveControlPoint]["selected_point_index"];
        bool restricted = actionStack.last[DrawAction.moveControlPoint]["restricted"];
        setState(() {
          pathsCollection[editingCurveIndex]["control_points"] = controlPoints;
          if(pathsCollection[editingCurveIndex]["mode"] == EditingMode.GroupCurve){
            int curveIndex = actionStack.last[DrawAction.moveControlPoint]["index_of_grouped_path"];
            int from = actionStack.last[DrawAction.moveControlPoint]["grouped_path_control_point_from"];
            int to = actionStack.last[DrawAction.moveControlPoint]["grouped_path_control_point_to"];
            int restrictedFrom = actionStack.last[DrawAction.moveControlPoint]["grouped_restricted_path_control_point_from"];
            int restrictedTo = actionStack.last[DrawAction.moveControlPoint]["grouped_restricted_path_control_point_to"];
            if(from < to){
              pathsCollection[editingCurveIndex]["curves"][curveIndex]["control_points"] = controlPoints.sublist(from, to);
            }
            if(restrictedFrom < restrictedTo){
              pathsCollection[editingCurveIndex]["curves"][curveIndex]["restricted_control_points"] = restrictedControlPoints.sublist(restrictedFrom, restrictedTo);
            }
          }
          currentEditingCurveIndex = editingCurveIndex;
          if(restricted){
            indexOfSelectedControlPoint = null;
            indexOfSelectedRestrictedControlPoint = selectedPointIndex;
            indexOfSelectedDataControlPoint = null;
          } else {
            indexOfSelectedControlPoint = selectedPointIndex;
            indexOfSelectedRestrictedControlPoint = null;
            indexOfSelectedDataControlPoint = null;
          }
          actionStack.removeLast();
        });
        break;
      case DrawAction.addControlPoint:
        List<Offset> controlPoints = List<Offset>.from(actionStack.last[DrawAction.addControlPoint]["control_points"]);
        List<Offset> restrictedControlPoints = List<Offset>.from(actionStack.last[DrawAction.addControlPoint]["restricted_control_points"]);
        var editingCurveIndex = actionStack.last[DrawAction.addControlPoint]["editing_curve_index"];
        setState(() {
          pathsCollection[editingCurveIndex]["control_points"] = controlPoints;
          pathsCollection[editingCurveIndex]["restricted_control_points"] = restrictedControlPoints;
          currentEditingCurveIndex = editingCurveIndex;
          indexOfSelectedControlPoint = null;
          indexOfSelectedRestrictedControlPoint = null;
          indexOfSelectedDataControlPoint = null;
          actionStack.removeLast();
        });
        break;
      case DrawAction.transformControlPoints:
        // This action is applicable only to non-free-draw mode actions.
        // Free-Draw mode actions does not work solely on control points but
        // directly on the spline path created by the added control points
        List<Offset> controlPoints = List<Offset>.from(actionStack.last[DrawAction.transformControlPoints]["control_points"]);
        List<Offset> restrictedControlPoints = List<Offset>.from(actionStack.last[DrawAction.transformControlPoints]["restricted_control_points"]);
        var editingCurveIndex = actionStack.last[DrawAction.transformControlPoints]["editing_curve_index"];
        setState(() {
          pathsCollection[editingCurveIndex]["control_points"] = controlPoints;
          pathsCollection[editingCurveIndex]["restricted_control_points"] = restrictedControlPoints;
          currentEditingCurveIndex = editingCurveIndex;
          indexOfSelectedControlPoint = null;
          indexOfSelectedRestrictedControlPoint = null;
          indexOfSelectedDataControlPoint = null;
        });
        actionStack.removeLast();
        break;
      case DrawAction.changeCurveAttribute:
        var editingCurveIndex = actionStack.last[DrawAction.changeCurveAttribute]["editing_curve_index"];
        setState(() {
          for(MapEntry<String, dynamic> attribute in actionStack.last[DrawAction.changeCurveAttribute].entries){
            if(attribute.key != "editing_curve_index"){
              pathsCollection[editingCurveIndex][attribute.key] = attribute.value;
            }
          }
          actionStack.removeLast();
        });
        break;
      case DrawAction.changePaintShader:
        // Unimplemented case;
        break;
      case DrawAction.changeFillColor:
        Color color = actionStack.last[DrawAction.changeFillColor]["original_fill_color"];
        var editingCurveIndex = actionStack.last[DrawAction.changeFillColor]["editing_curve_index"];
        setState(() {
          currentFillColor.color = color;
          if(editingCurveIndex != null){
            pathsCollection[editingCurveIndex]["fill"].color = actionStack.last[DrawAction.changeFillColor]["original_curve_fill_color"];
            pathsCollection[editingCurveIndex]["filled"] = actionStack.last[DrawAction.changeFillColor]["original_filled_attribute"];
          }
          actionStack.removeLast();
        });
        break;
      case DrawAction.changePaintColor:
        var editingCurveIndex = actionStack.last[DrawAction.changePaintColor]["editing_curve_index"];
        setState(() {
          currentStrokeColor.color = actionStack.last[DrawAction.changePaintColor]["original_paint_color"];
          if(editingCurveIndex != null){
            pathsCollection[editingCurveIndex]["stroke"].color = actionStack.last[DrawAction.changePaintColor]["original_curve_paint_color"];
          }
          actionStack.removeLast();
        });
        break;
      case DrawAction.changePaintStrokeWidth:
        var editingCurveIndex = actionStack.last[DrawAction.changePaintStrokeWidth]["editing_curve_index"];
        setState(() {
          currentStrokeColor.strokeWidth = actionStack.last[DrawAction.changePaintStrokeWidth]["original_stroke_width"];
          if(editingCurveIndex != null){
            pathsCollection[editingCurveIndex]["stroke"].strokeWidth = actionStack.last[DrawAction.changePaintStrokeWidth]["original_curve_paint_stroke_width"];
          }
          actionStack.removeLast();
        });
        break;
      case DrawAction.changeMode:
        var editingCurveIndex = actionStack.last[DrawAction.changeMode]["original_editing_index"];
        var mode = actionStack.last[DrawAction.changeMode]["original_mode"];
        setState(() {
          pathsCollection.removeLast();
          currentMode = mode;
          currentEditingCurveIndex = editingCurveIndex;
          if(currentEditingCurveIndex != null){
            indexOfSelectedControlPoint = null;
            indexOfSelectedRestrictedControlPoint = null;
            indexOfSelectedDataControlPoint = null;
          }
          actionStack.removeLast();
        });
        break;
      case DrawAction.duplicateCurve:
        var editingCurveIndex = actionStack.last[DrawAction.duplicateCurve]["editing_curve_index"];
        setState(() {
          pathsCollection.removeAt(editingCurveIndex);
          if(currentEditingCurveIndex != null && editingCurveIndex < currentEditingCurveIndex){
            currentEditingCurveIndex = currentEditingCurveIndex! - 1;
          }
          actionStack.removeLast();
        });
        break;
      case DrawAction.deleteCurve:
        var editingCurveIndex = actionStack.last[DrawAction.deleteCurve]["editing_curve_index"];
        var path = actionStack.last[DrawAction.deleteCurve]["deleted_curve"];
        setState(() {
          pathsCollection.insert(editingCurveIndex, path);
          if(currentEditingCurveIndex != null && editingCurveIndex <= currentEditingCurveIndex){
            currentEditingCurveIndex = currentEditingCurveIndex! + 1;
          }
          actionStack.removeLast();
        });
        break;
      case DrawAction.groupCurves:
        int index = actionStack.last[DrawAction.groupCurves]["editing_curve_index"];
        unGroupCurves(groupedCurves: pathsCollection[index], index: index, addToAction: false);
        break;
      case DrawAction.unGroupCurves:
        groupSelection = actionStack.last[DrawAction.unGroupCurves]["group_selection"];
        groupSelectedCurves(addToAction: false);
        break;
      case DrawAction.addFreeDraw:
        var editingCurveIndex = actionStack.last[DrawAction.addFreeDraw]["editing_curve_index"];
        setState(() {
          pathsCollection.removeAt(editingCurveIndex);
          actionStack.removeLast();
        });
        if(currentEditingCurveIndex == editingCurveIndex){
          deactivateCurrentActivePath();
        }
        break;
      case DrawAction.transformFreeDraw:
        var editingCurveIndex = actionStack.last[DrawAction.transformFreeDraw]["editing_curve_index"];
        List<Offset> controlPoints = List<Offset>.from(actionStack.last[DrawAction.transformFreeDraw]["control_points"]);
        Path originalPath = Path();
        originalPath.addPath(actionStack.last[DrawAction.transformFreeDraw]["free_draw_spline"], Offset.zero);
        setState(() {
          pathsCollection[editingCurveIndex]["free_draw_spline"].splinePath = originalPath;
          pathsCollection[editingCurveIndex]["free_draw_spline"].points = controlPoints;
          indexOfSelectedControlPoint = null;
          indexOfSelectedRestrictedControlPoint = null;
          indexOfSelectedDataControlPoint = null;
          currentEditingCurveIndex = editingCurveIndex;
          actionStack.removeLast();
        });
        break;
      case DrawAction.alterBackgroundImage:
        print("Unimplemented change background image draw action to undo.");
        break;
      default:
        print("Unimplemented draw action ${actionStack.last.keys.first} to undo.");
        break;
    }
  }

  void groupSelectedCurves({bool addToAction = true}){
    if(groupSelection.isNotEmpty){
      groupSelection.sort();
      if(addToAction){
        actionStack.add({
          DrawAction.groupCurves: <String, dynamic>{
            "group_selection": List<int>.from(groupSelection),
          }
        });
      }
      setState(() {
        pathsCollection.add({
          "mode": EditingMode.GroupCurve,
          "curves" : <Map<String, dynamic>>[],
          "outlined": false,
          "filled": false,
          "stroke": copyPaint(currentStrokeColor),
          "fill": copyPaint(currentFillColor),
          "control_points": <Offset>[],
          "restricted_control_points": <Offset>[],
          "data_control_points": <Offset>[],
          "bounding_rect": Rect.zero,
        });
        Path boundingRect = Path();
        for(int i in groupSelection){
          pathsCollection.last["curves"].add(Map<String, dynamic>.from(pathsCollection[i]));
          pathsCollection.last["control_points"].addAll(List<Offset>.from(pathsCollection[i]["control_points"]));
          pathsCollection.last["restricted_control_points"].addAll(List<Offset>.from(pathsCollection[i]["restricted_control_points"]));
          pathsCollection.last["data_control_points"].addAll(List<Offset>.from(pathsCollection[i]["data_control_points"]));
          boundingRect.addRect(pathsCollection[i]["bounding_rect"]);
        }
        for(int i in groupSelection.reversed){
          pathsCollection.removeAt(i);
        }
        groupSelection = [];
        currentMode = EditingMode.GroupCurve;
        pathsCollection.last["bounding_rect"] = boundingRect.getBounds();
        currentEditingCurveIndex = pathsCollection.length - 1;
      });
      if(addToAction){
        actionStack.last[DrawAction.groupCurves]["editing_curve_index"] = currentEditingCurveIndex;
      }
      pathsCollection.last["curve_finder_function"] = curveFinderGetter(pathsCollection.last["curves"]);
    }
  }

  void unGroupCurves({Map<String, dynamic>? groupedCurves, int? index, bool addToAction = true}){
    if(currentMode == EditingMode.GroupCurve){
      Map<String, dynamic> groupCurve = Map<String, dynamic>.from(pathsCollection[currentEditingCurveIndex!]);
      if(addToAction){
        actionStack.add({
          DrawAction.unGroupCurves: {
            "editing_curve_index": currentEditingCurveIndex,
            "group_selection": List<int>.generate(groupCurve["curves"].length, (i) => currentEditingCurveIndex! + i),
          }
        });
      }
      pathsCollection[currentEditingCurveIndex!]["mark_for_removal"] = true;
      setState(() {
        for(Map<String, dynamic> c in groupCurve["curves"]){
          pathsCollection.insert(currentEditingCurveIndex!, c);
        }
      });
      pathsCollection.removeWhere((e) => e.containsKey("mark_for_removal"));
      boundingRect = null;
    } else if (groupedCurves != null && index != null){
      if(addToAction){
        actionStack.add({
          DrawAction.unGroupCurves: {
            "editing_curve_index": index,
            "group_selection": List<int>.generate(groupedCurves["curves"].length, (i) => index + i),
          }
        });
      }
      pathsCollection[index]["mark_for_removal"] = true;
      setState(() {
        for(Map<String, dynamic> c in groupedCurves["curves"]){
          pathsCollection.insert(index, c);
        }
      });
      pathsCollection.removeWhere((e) => e.containsKey("mark_for_removal"));
      boundingRect = null;
    }
  }

  Future<void> signInIfInDebugMode() async {
    const isReleaseMode = bool.fromEnvironment("dart.vm.product");
    UserCredential? userCredential;
    if(!isReleaseMode){
      Authentication authInstance = Authentication(user: null);
      userCredential = await authInstance.auth.signInWithEmailAndPassword(email: "appdeveloper@initkopico.com", password: "Password123");
      if(userCredential.user != null){
        setState(() {
          userIdentifier = userCredential!.user!.email;
          currentUser = userCredential.user;
        });
      }
    }
    webIO = WebIO(currentUser);
    webIO.updateUserCredential(userCredential);
  }

  void changeRed(bool increment, String colorReceiver){
    if(increment){
      if(colorReceiver == "Stroke" && strokeRedInt <= 252){
        setState((){
          strokeRedInt += 3;
          if(strokeAnchorColor == AnchorColor.red){
            strokeAnchorColorValue = strokeRedInt;
          }
          strokePendingColor = Color.fromARGB(strokeAlphaInt, strokeRedInt, strokeGreenInt, strokeBlueInt);
        });
      } else if (colorReceiver == "Stroke" && strokeRedInt < 255){
        setState((){
          strokeRedInt = 255;
          if(strokeAnchorColor == AnchorColor.red){
            strokeAnchorColorValue = strokeRedInt;
          }
          strokePendingColor = Color.fromARGB(strokeAlphaInt, strokeRedInt, strokeGreenInt, strokeBlueInt);
        });
      } else if(colorReceiver == "Fill" && fillRedInt <= 252){
        setState((){
          fillRedInt += 3;
          if(fillAnchorColor == AnchorColor.red){
            fillAnchorColorValue = fillRedInt;
          }
          fillPendingColor = Color.fromARGB(fillAlphaInt, fillRedInt, fillGreenInt, fillBlueInt);
        });
      } else if (colorReceiver == "Fill" && fillRedInt < 255){
        setState((){
          fillRedInt = 255;
          if(fillAnchorColor == AnchorColor.red){
            fillAnchorColorValue = fillRedInt;
          }
          fillPendingColor = Color.fromARGB(fillAlphaInt, fillRedInt, fillGreenInt, fillBlueInt);
        });
      }
    } else {
      if(colorReceiver == "Stroke" && strokeRedInt >= 3){
        setState((){
          strokeRedInt -= 3;
          if(strokeAnchorColor == AnchorColor.red){
            strokeAnchorColorValue = strokeRedInt;
          }
          strokePendingColor = Color.fromARGB(strokeAlphaInt, strokeRedInt, strokeGreenInt, strokeBlueInt);
        });
      } else if (colorReceiver == "Stroke" && strokeRedInt > 0){
        setState((){
          strokeRedInt = 0;
          if(strokeAnchorColor == AnchorColor.red){
            strokeAnchorColorValue = strokeRedInt;
          }
          strokePendingColor = Color.fromARGB(strokeAlphaInt, strokeRedInt, strokeGreenInt, strokeBlueInt);
        });
      } else if(colorReceiver == "Fill" && fillRedInt >= 3){
        setState((){
          fillRedInt -= 3;
          if(fillAnchorColor == AnchorColor.red){
            fillAnchorColorValue = fillRedInt;
          }
          fillPendingColor = Color.fromARGB(fillAlphaInt, fillRedInt, fillGreenInt, fillBlueInt);
        });
      } else if (colorReceiver == "Fill" && fillRedInt > 0){
        setState((){
          fillRedInt = 0;
          if(fillAnchorColor == AnchorColor.red){
            fillAnchorColorValue = fillRedInt;
          }
          fillPendingColor = Color.fromARGB(fillAlphaInt, fillRedInt, fillGreenInt, fillBlueInt);
        });
      }
    }
    moveColorPickerCursor(colorReceiver);
  }

  void changeGreen(bool increment, String colorReceiver){
    if(increment){
      if(colorReceiver == "Stroke" && strokeGreenInt <= 252){
        setState((){
          strokeGreenInt += 3;
          if(strokeAnchorColor == AnchorColor.green){
            strokeAnchorColorValue = strokeGreenInt;
          }
          strokePendingColor = Color.fromARGB(strokeAlphaInt, strokeRedInt, strokeGreenInt, strokeBlueInt);
        });
      } else if (colorReceiver == "Stroke" && strokeGreenInt < 255){
        setState((){
          strokeGreenInt = 255;
          if(strokeAnchorColor == AnchorColor.green){
            strokeAnchorColorValue = strokeGreenInt;
          }
          strokePendingColor = Color.fromARGB(strokeAlphaInt, strokeRedInt, strokeGreenInt, strokeBlueInt);
        });
      } else if(colorReceiver == "Fill" && fillGreenInt <= 252){
        setState((){
          fillGreenInt += 3;
          if(fillAnchorColor == AnchorColor.green){
            fillAnchorColorValue = fillGreenInt;
          }
          fillPendingColor = Color.fromARGB(fillAlphaInt, fillRedInt, fillGreenInt, fillBlueInt);
        });
      } else if (colorReceiver == "Fill" && fillGreenInt < 255){
        setState((){
          fillGreenInt = 255;
          if(fillAnchorColor == AnchorColor.green){
            fillAnchorColorValue = fillGreenInt;
          }
          fillPendingColor = Color.fromARGB(fillAlphaInt, fillRedInt, fillGreenInt, fillBlueInt);
        });
      }
    } else {
      if(colorReceiver == "Stroke" && strokeGreenInt >= 3){
        setState((){
          strokeGreenInt -= 3;
          if(strokeAnchorColor == AnchorColor.green){
            strokeAnchorColorValue = strokeGreenInt;
          }
          strokePendingColor = Color.fromARGB(strokeAlphaInt, strokeRedInt, strokeGreenInt, strokeBlueInt);
        });
      } else if (colorReceiver == "Stroke" && strokeGreenInt > 0){
        setState((){
          strokeGreenInt = 0;
          if(strokeAnchorColor == AnchorColor.green){
            strokeAnchorColorValue = strokeGreenInt;
          }
          strokePendingColor = Color.fromARGB(strokeAlphaInt, strokeRedInt, strokeGreenInt, strokeBlueInt);
        });
      } else if(colorReceiver == "Fill" && fillGreenInt >= 3){
        setState((){
          fillGreenInt -= 3;
          if(fillAnchorColor == AnchorColor.green){
            fillAnchorColorValue = fillGreenInt;
          }
          fillPendingColor = Color.fromARGB(fillAlphaInt, fillRedInt, fillGreenInt, fillBlueInt);
        });
      } else if (colorReceiver == "Fill" && fillGreenInt > 0){
        setState((){
          fillGreenInt = 0;
          if(fillAnchorColor == AnchorColor.green){
            fillAnchorColorValue = fillGreenInt;
          }
          fillPendingColor = Color.fromARGB(fillAlphaInt, fillRedInt, fillGreenInt, fillBlueInt);
        });
      }
    }
    moveColorPickerCursor(colorReceiver);
  }

  void changeBlue(bool increment, String colorReceiver){
    if(increment){
      if(colorReceiver == "Stroke" && strokeBlueInt <= 252){
        setState((){
          strokeBlueInt += 3;
          if(strokeAnchorColor == AnchorColor.blue){
            strokeAnchorColorValue = strokeBlueInt;
          }
          strokePendingColor = Color.fromARGB(strokeAlphaInt, strokeRedInt, strokeGreenInt, strokeBlueInt);
        });
      } else if (colorReceiver == "Stroke" && strokeBlueInt < 255){
        setState((){
          strokeBlueInt = 255;
          if(strokeAnchorColor == AnchorColor.blue){
            strokeAnchorColorValue = strokeBlueInt;
          }
          strokePendingColor = Color.fromARGB(strokeAlphaInt, strokeRedInt, strokeGreenInt, strokeBlueInt);
        });
      } else if(colorReceiver == "Fill" && fillBlueInt <= 252){
        setState((){
          fillBlueInt += 3;
          if(fillAnchorColor == AnchorColor.blue){
            fillAnchorColorValue = fillBlueInt;
          }
          fillPendingColor = Color.fromARGB(fillAlphaInt, fillRedInt, fillGreenInt, fillBlueInt);
        });
      } else if (colorReceiver == "Fill" && fillBlueInt < 255){
        setState((){
          fillBlueInt = 255;
          if(fillAnchorColor == AnchorColor.blue){
            fillAnchorColorValue = fillBlueInt;
          }
          fillPendingColor = Color.fromARGB(fillAlphaInt, fillRedInt, fillGreenInt, fillBlueInt);
        });
      }
    } else {
      if(colorReceiver == "Stroke" && strokeBlueInt >= 3){
        setState((){
          strokeBlueInt -= 3;
          if(strokeAnchorColor == AnchorColor.blue){
            strokeAnchorColorValue = strokeBlueInt;
          }
          strokePendingColor = Color.fromARGB(strokeAlphaInt, strokeRedInt, strokeGreenInt, strokeBlueInt);
        });
      } else if (colorReceiver == "Stroke" && strokeBlueInt > 0){
        setState((){
          strokeBlueInt = 0;
          if(strokeAnchorColor == AnchorColor.blue){
            strokeAnchorColorValue = strokeBlueInt;
          }
          strokePendingColor = Color.fromARGB(strokeAlphaInt, strokeRedInt, strokeGreenInt, strokeBlueInt);
        });
      } else if(colorReceiver == "Fill" && fillBlueInt >= 3){
        setState((){
          fillBlueInt -= 3;
          if(fillAnchorColor == AnchorColor.blue){
            fillAnchorColorValue = fillBlueInt;
          }
          fillPendingColor = Color.fromARGB(fillAlphaInt, fillRedInt, fillGreenInt, fillBlueInt);
        });
      } else if (colorReceiver == "Fill" && fillBlueInt > 0){
        setState((){
          fillBlueInt = 0;
          if(fillAnchorColor == AnchorColor.blue){
            fillAnchorColorValue = fillBlueInt;
          }
          fillPendingColor = Color.fromARGB(fillAlphaInt, fillRedInt, fillGreenInt, fillBlueInt);
        });
      }
    }
    moveColorPickerCursor(colorReceiver);
  }

  void changeAlpha(bool increment, String colorReceiver){
    if(increment){
      if(colorReceiver == "Stroke" && strokeAlphaInt <= 252){
        setState((){
          strokeAlphaInt += 3;
          strokePendingColor = Color.fromARGB(strokeAlphaInt, strokeRedInt, strokeGreenInt, strokeBlueInt);
        });
      } else if (colorReceiver == "Stroke" && strokeAlphaInt < 255){
        setState((){
          strokeAlphaInt = 255;
          strokePendingColor = Color.fromARGB(strokeAlphaInt, strokeRedInt, strokeGreenInt, strokeBlueInt);
        });
      } else if(colorReceiver == "Fill" && fillAlphaInt <= 252){
        setState((){
          fillAlphaInt += 3;
          fillPendingColor = Color.fromARGB(fillAlphaInt, fillRedInt, fillGreenInt, fillBlueInt);
        });
      } else if (colorReceiver == "Fill" && fillAlphaInt < 255){
        setState((){
          fillAlphaInt = 255;
          fillPendingColor = Color.fromARGB(fillAlphaInt, fillRedInt, fillGreenInt, fillBlueInt);
        });
      }
    } else {
      if(colorReceiver == "Stroke" && strokeAlphaInt >= 3){
        setState((){
          strokeAlphaInt -= 3;
          strokePendingColor = Color.fromARGB(strokeAlphaInt, strokeRedInt, strokeGreenInt, strokeBlueInt);
        });
      } else if (colorReceiver == "Stroke" && strokeAlphaInt > 0){
        setState((){
          strokeAlphaInt = 0;
          strokePendingColor = Color.fromARGB(strokeAlphaInt, strokeRedInt, strokeGreenInt, strokeBlueInt);
        });
      } else if(colorReceiver == "Fill" && fillAlphaInt >= 3){
        setState((){
          fillAlphaInt -= 3;
          fillPendingColor = Color.fromARGB(fillAlphaInt, fillRedInt, fillGreenInt, fillBlueInt);
        });
      } else if (colorReceiver == "Fill" && fillAlphaInt > 0){
        setState((){
          fillAlphaInt = 0;
          fillPendingColor = Color.fromARGB(fillAlphaInt, fillRedInt, fillGreenInt, fillBlueInt);
        });
      }
    }
  }

  Future<void> startChangeColorValues(AnchorColor anchorColor, bool increment, String colorReceiver) async {
    switch(anchorColor){
      case AnchorColor.red:
        colorChangeTimer = Timer.periodic(
            const Duration(milliseconds: 30),
                (_timer){
                  changeRed(increment, colorReceiver);
                });
        break;
      case AnchorColor.green:
        colorChangeTimer = Timer.periodic(
            const Duration(milliseconds: 30),
                (_timer){
                changeGreen(increment, colorReceiver);
            });
        break;
      case AnchorColor.blue:
        colorChangeTimer = Timer.periodic(
            const Duration(milliseconds: 30),
                (_timer){
                changeBlue(increment, colorReceiver);
            });
        break;
      case AnchorColor.alpha:
        colorChangeTimer = Timer.periodic(
            const Duration(milliseconds: 30),
                (_timer){
              changeAlpha(increment, colorReceiver);
            });
        break;
      default:
        break;
    }
  }

  void moveColorPickerCursor(String colorReceiver, {TapDownDetails? tapDownDetails, DragUpdateDetails? dragDetails}){
    if(colorReceiver == "Stroke" && tapDownDetails != null){
      setState((){
        strokeColorPickerCursor = tapDownDetails.localPosition;
      });
    } else if (colorReceiver == "Stroke" && dragDetails != null ){
      setState((){
        strokeColorPickerCursor = dragDetails.localPosition;
      });
    } else if(colorReceiver == "Fill" && tapDownDetails != null){
      setState((){
        fillColorPickerCursor = tapDownDetails.localPosition;
      });
    } else if (colorReceiver == "Fill" && dragDetails != null ){
      setState((){
        fillColorPickerCursor = dragDetails.localPosition;
      });
    } else {
      switch(colorReceiver == "Stroke" ? strokeAnchorColor : fillAnchorColor){
        case AnchorColor.red:
          if(colorReceiver == "Stroke"){
            setState((){
              strokeColorPickerCursor = Offset(strokeBlueInt / 1, strokeGreenInt / 1);
            });
          } else if (colorReceiver == "Fill"){
            setState((){
              fillColorPickerCursor = Offset(strokeBlueInt / 1, strokeGreenInt / 1);
            });
          }
          break;
        case AnchorColor.green:
          if(colorReceiver == "Stroke"){
            setState((){
              strokeColorPickerCursor = Offset(strokeBlueInt / 1, strokeRedInt / 1);
            });
          } else if (colorReceiver == "Fill"){
            setState((){
              fillColorPickerCursor = Offset(strokeBlueInt / 1, strokeRedInt / 1);
            });
          }
          break;
        case AnchorColor.blue:
          if(colorReceiver == "Stroke"){
            setState((){
              strokeColorPickerCursor = Offset(strokeGreenInt / 1, strokeRedInt / 1);
            });
          } else if (colorReceiver == "Fill"){
            setState((){
              fillColorPickerCursor = Offset(strokeGreenInt / 1, strokeRedInt / 1);
            });
          }
          break;
        default:
          break;
      }
    }
  }

  @override
  void initState(){
    super.initState();
    signInIfInDebugMode();
  }

  Map<String, dynamic> Function({num? cpIndex, num? rcpIndex}) curveFinderGetter(List<Map<String, dynamic>> curves){
    Map<String, dynamic> curveFinderFunction ({num? cpIndex, num? rcpIndex, num? dcpIndex}){
      assert(cpIndex != null || rcpIndex != null && !(cpIndex != null && rcpIndex != null), "Either control point index or restricted control point index must be given, but not both");
      num sumcp = -1;
      num sumrcp = -1;
      num sumdcp = -1;
      if(cpIndex != null){
        for(int k = 0; k < curves.length; k++){
          Map<String, dynamic> c = curves[k];
          if(sumcp + c["control_points"].length >= cpIndex){
            if(curves[k]["mode"] != EditingMode.GroupCurve) {
              return {
                "from": sumcp + 1,
                "to": sumcp + c["control_points"].length + 1,
                "restricted_from": sumrcp + 1,
                "restricted_to": sumrcp + c["restricted_control_points"].length + 1,
                "data_from": sumdcp + 1,
                "data_to": sumdcp + c["data_control_points"].length + 1,
                "path": k.toString(),
                "curve": c,
              };
            } else {
              Map<String, dynamic> result = curves[k]["curve_finder_function"](cpIndex:cpIndex - sumcp - 1);
              result["path"] = "$k/" + result["path"];
              result["from"] += (sumcp + 1);
              result["to"] += (sumcp + 1);
              result["data_from"] += (sumdcp + 1);
              result["data_to"] += (sumdcp + 1);
              result["restricted_from"] += (sumrcp + 1);
              result["restricted_to"] += (sumrcp + 1);
              return result;
            }
          }
          sumcp = sumcp + c["control_points"].length;
          sumrcp = sumrcp + c["restricted_control_points"].length;
          sumdcp = sumdcp + c["data_control_points"].length;
        }
        throw Exception("Path not found from curve finder function");
      } else if (rcpIndex != null){
        for(int k = 0; k < curves.length; k++){
          Map<String, dynamic> c = curves[k];
          if(sumrcp + c["restricted_control_points"].length >= rcpIndex){
            if(curves[k]["mode"] != EditingMode.GroupCurve) {
              return {
                "from": sumcp + 1,
                "to": sumcp + c["control_points"].length + 1,
                "restricted_from": sumrcp + 1,
                "restricted_to": sumrcp + c["restricted_control_points"].length + 1,
                "data_from": sumdcp + 1,
                "data_to": sumdcp + c["data_control_points"].length + 1,
                "path": k.toString(),
                "curve": c,
              };
            } else {
              Map<String, dynamic> result = curves[k]["curve_finder_function"](rcpIndex:rcpIndex - sumrcp - 1);
              result["path"] = "$k/" + result["path"];
              result["from"] += (sumcp + 1);
              result["to"] += (sumcp + 1);
              result["restricted_from"] += (sumrcp + 1);
              result["restricted_to"] += (sumrcp + 1);
              result["data_from"] += (sumdcp + 1);
              result["data_to"] += (sumdcp + 1);
              return result;
            }
          }
          sumcp = sumcp + c["control_points"].length;
          sumrcp = sumrcp + c["restricted_control_points"].length;
          sumdcp = sumdcp + c["data_control_points"].length;
        }
        throw Exception("Path not found from curve finder function");
      } else if (dcpIndex != null){
        for(int k = 0; k < curves.length; k++){
          Map<String, dynamic> c = curves[k];
          if(sumrcp + c["data_control_points"].length >= dcpIndex){
            if(curves[k]["mode"] != EditingMode.GroupCurve) {
              return {
                "from": sumcp + 1,
                "to": sumcp + c["control_points"].length + 1,
                "restricted_from": sumrcp + 1,
                "restricted_to": sumrcp + c["restricted_control_points"].length + 1,
                "data_from": sumdcp + 1,
                "data_to": sumdcp + c["data_control_points"].length + 1,
                "path": k.toString(),
                "curve": c,
              };
            } else {
              Map<String, dynamic> result = curves[k]["curve_finder_function"](dcpIndex:dcpIndex - sumdcp - 1);
              result["path"] = "$k/" + result["path"];
              result["from"] += (sumcp + 1);
              result["to"] += (sumcp + 1);
              result["restricted_from"] += (sumrcp + 1);
              result["restricted_to"] += (sumrcp + 1);
              result["data_from"] += (sumdcp + 1);
              result["data_to"] += (sumdcp + 1);
              return result;
            }
          }
          sumcp = sumcp + c["control_points"].length;
          sumrcp = sumrcp + c["restricted_control_points"].length;
          sumdcp = sumdcp + c["data_control_points"].length;
        }
        throw Exception("Path not found from curve finder function");
      } else {
        throw Exception("Path not found from curve finder function");
      }
    }
    return curveFinderFunction;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double appBarHeight = 50;
    double sideBarWidth = 40;
    double canvasHeight = 500;
    double canvasWidth = 800;
    double sidePanelWidth = 300;
    double canvasTopPosition = (screenHeight - appBarHeight - canvasHeight) / 2; // 200
    double canvasLeftPosition = (screenWidth - sideBarWidth - sidePanelWidth - canvasWidth) / 2;// 500
    double horizontalRulerTopPosition = canvasTopPosition - 30;
    double horizontalRulerLeftPosition = canvasLeftPosition - 15;
    double verticalRulerTopPosition = canvasTopPosition - 10;
    double verticalRulerLeftPosition = canvasLeftPosition - 50;
    double sliderWidth = 264;
    Rect paletteRect = Offset(1,1) & Size(256, 256);
    Size canvasSize = Size(_standardCanvasWidth, _standardCanvasHeight);
    rawKeyboardFocusNode.requestFocus();
    return RawKeyboardListener(
      onKey: _keyboardCallBack,
      focusNode: rawKeyboardFocusNode,
      child: Material(
        type: MaterialType.canvas,
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: screenWidth,
                height: appBarHeight,
                child: AppBar(
                  title: Text(widget.title + ": $currentDrawingName"),
                  actions: [
                    Container(
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: MaterialButton(
                        color: Colors.orange,
                        elevation: 0.0,
                        hoverColor: Colors.orange,
                        padding: EdgeInsets.zero,
                        onPressed: (){

                        },
                        child: currentUser != null ? Text("$userIdentifier", style: const TextStyle(fontSize: 16, color: Colors.black)) : Container(),
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: MaterialButton(
                        shape: const CircleBorder(),
                        color: Colors.white,
                        onPressed: (){
                          setState(() {
                            showPathsPanel = !showPathsPanel;
                          });
                        },
                        padding: EdgeInsets.zero,
                        child: const Icon(Icons.format_list_bulleted_outlined, size: 24, color: Colors.orange),
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: MaterialButton(
                        shape: const CircleBorder(),
                        color: Colors.white,
                        onPressed: (){
                          MaterialPageRoute helpPageRoute = MaterialPageRoute(
                            builder: (context){
                              return const HelpPage();
                            }
                          );
                          Navigator.push(context, helpPageRoute);
                        },
                        padding: EdgeInsets.zero,
                        child: const Text("?", style: TextStyle(fontSize:16, color: Colors.orange)),
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: PopupMenuButton<String>(
                        itemBuilder: (context){
                          return [
                            if(currentUser == null)
                              menuItem("Sign in", "login", iconData: Icons.lock_open),
                            if(currentUser != null)
                              menuItem("Sign out", "logout", iconData: Icons.lock_rounded),
                            menuItem("New", "new", iconData: Icons.insert_drive_file),
                            if(!hasBackgroundImage)
                              menuItem("Import Image", "import_image", iconData: Icons.image),
                            if(hasBackgroundImage)
                              menuItem("Remove Background Image", "remove_image", iconData: Icons.remove),
                            if(currentDrawingName == _defaultDrawingName)
                              menuItem("Save As", "get_drawing_name_and_save", iconData: Icons.save, enabled: currentUser != null),
                            if(currentDrawingName != _defaultDrawingName)
                              menuItem("Save", "save", iconData: Icons.save, enabled: currentUser != null),
                            // menuItem("Download from Cloud", "download_png", iconData: Icons.folder, enabled: currentUser != null),
                            menuItem("Load Drawing", "load_drawing", iconData: Icons.picture_in_picture_alt, enabled: currentUser != null),
                            if(currentUser != null)
                              menuItem("Export", "export_to_cloud", iconData: Icons.import_export),
                            menuItem("Preferences", "preferences", iconData: Icons.settings),
                          ];
                        },
                        onSelected: (String val) async {
                          switch (val){
                            case "logout":
                              showConfirmDialog(
                                  context,
                                  "Sign out?",
                                      (){
                                    setState(() {
                                      currentUser = null;
                                      userIdentifier = null;
                                    });
                                    FirebaseAuth.instance.signOut();
                                    Navigator.pop(context);
                                  },
                                      (){
                                    Navigator.pop(context);
                                  }
                              );
                              break;
                            case "login":
                              MaterialPageRoute loginRoute = MaterialPageRoute(
                                builder: (context){
                                  return LoginPage(webIO.authInstance!);
                                },
                                settings: RouteSettings(
                                  name: "login_page",
                                  arguments: {
                                    "user_identifier": userIdentifier ?? "",
                                  }
                                )
                              );
                              var loginResponse = await Navigator.push(context, loginRoute);
                              if(loginResponse != null){
                                if(loginResponse["login_status"] == LoginStatus.LOGIN_SUCCESS){
                                  String? email = loginResponse["user"].email;
                                  if(email != null){
                                    setState(() {
                                      userIdentifier = email;
                                      currentUser = loginResponse["user"];
                                      webIO.user = currentUser;
                                    });
                                  } else {
                                    setState((){
                                      userIdentifier = "Signed In";
                                      currentUser = loginResponse["user"];
                                      webIO.user = currentUser;
                                    });
                                  }
                                }
                              }
                              break;
                            // case "account":
                            //   MaterialPageRoute accountRoute = MaterialPageRoute(
                            //       builder: (context){
                            //         return AccountPage(currentUser!);
                            //       }
                            //   );
                            //   Navigator.push(context, accountRoute);
                            //   break;
                            case "import_image":
                              pickImage();
                              break;
                            case "remove_image":
                              removeImage();
                              break;
                            case "get_drawing_name_and_save":
                              String? drawingName = await showGetDrawingNameDialog(context);
                              if(drawingName != null){
                                autosave(drawingName: drawingName);
                                setState((){
                                  currentDrawingName = drawingName;
                                });
                              }
                              break;
                            case "save":
                              autosave();
                              break;
                            case "export_to_cloud":
                              ui.Picture currentPicture = getCurrentPicture(pathsCollection);
                              ui.Image currentImage = await currentPicture.toImage(_standardCanvasWidth ~/ 1, _standardCanvasHeight ~/ 1);
                              Map<String, dynamic>? outcome = await webIO.uploadDrawing(
                                  context,
                                  currentImage,
                                  {
                                    "width": (_standardCanvasWidth ~/ 1).toString(),
                                    "height": (_standardCanvasHeight ~/ 1).toString()
                                  });
                              if(outcome != null && outcome.containsKey("status") && outcome["status"] == "Success"){
                                currentFilename = outcome["filename"];
                                currentFileReference = outcome["reference"];
                              }
                              break;
                            case "download_png":
                              if(pathsCollection.isNotEmpty || backgroundImageFile != null){
                                // restricted control points always accompanies some control points (unrestricted)
                                bool? confirmation = await showConfirmDialog(
                                    context,
                                    "Save to cloud?",
                                        () async {
                                      Navigator.pop(context, true);
                                    },
                                        (){
                                      Navigator.pop(context, false);
                                    }
                                );
                                print("Confirmation: $confirmation");
                                if(confirmation != null){
                                  if(confirmation){
                                    ui.Picture currentPicture = getCurrentPicture(pathsCollection);
                                    ui.Image currentImage = await currentPicture.toImage(_standardCanvasWidth ~/ 1, _standardCanvasHeight ~/ 1);
                                    await webIO.uploadDrawing(
                                      context,
                                      currentImage,
                                      {
                                        "width": (_standardCanvasWidth ~/ 1).toString(),
                                        "height": (_standardCanvasHeight ~/ 1).toString()
                                      },
                                      currentFilename: currentFilename,
                                      currentFileRef: currentFileReference,
                                    );
                                  }
                                  reset();
                                  ui.Image? image = await webIO.loadDrawingPNG(context, "${currentUser!.uid}");
                                  if(image != null){
                                    print("image is not null.");
                                    setState(() {
                                      hasBackgroundImage = true;
                                      currentImage = image;
                                    });
                                  } else {
                                    print("Load image unsuccessful.");
                                  }
                                }
                              } else {
                                ui.Image? image = await webIO.loadDrawingPNG(context, "${currentUser!.uid}");
                                if(image != null){
                                  print("image is not null.");
                                  setState(() {
                                    hasBackgroundImage = true;
                                    currentImage = image;
                                  });
                                } else {
                                  print("Load image unsuccessful.");
                                }
                              }
                              break;
                            case "load_drawing":
                              if(pathsCollection.isNotEmpty || backgroundImageFile != null){
                                // restricted control points always accompanies some control points (unrestricted)
                                bool? confirmation = await showConfirmDialog(
                                    context,
                                    "Save to cloud?",
                                        () async {
                                      Navigator.pop(context, true);
                                      ui.Picture currentPicture = getCurrentPicture(pathsCollection);
                                      ui.Image currentImage = await currentPicture.toImage(_standardCanvasWidth ~/ 1, _standardCanvasHeight ~/ 1);
                                      await webIO.uploadDrawing(
                                        context,
                                        currentImage,
                                        {
                                          "width": (_standardCanvasWidth ~/ 1).toString(),
                                          "height": (_standardCanvasHeight ~/ 1).toString()
                                        },
                                        currentFilename: currentFilename,
                                        currentFileRef: currentFileReference,
                                      );
                                      reset();
                                    },
                                        (){
                                      Navigator.pop(context, false);
                                    }
                                );
                                if(confirmation != null){
                                  Map<String, dynamic>? odkObject = await webIO.loadODKDrawing(context, "${currentUser!.uid}");
                                  if(odkObject != null){
                                    setState(() {
                                      pathsCollection = odkObject["paths_collection"];
                                      currentDrawingName = odkObject["drawing_name"];
                                      currentDocId = odkObject["doc_id"];
                                      currentEditingCurveIndex = null;
                                      currentMode = EditingMode.None;
                                    });
                                  } else {
                                    print("Load drawing unsuccessful.");
                                  }
                                }
                              } else {
                                Map<String, dynamic>? odkObject = await webIO.loadODKDrawing(context, "${currentUser!.uid}");
                                if(odkObject != null){
                                  setState(() {
                                    pathsCollection = odkObject["paths_collection"];
                                    currentDrawingName = odkObject["drawing_name"];
                                    currentDocId = odkObject["doc_id"];
                                    currentEditingCurveIndex = null;
                                    currentMode = EditingMode.None;
                                  });
                                } else {
                                  print("Load drawing unsuccessful.");
                                }
                              }
                              break;
                            case "new":
                              if(pathsCollection.isNotEmpty || hasBackgroundImage ){
                                showConfirmDialog(
                                  context,
                                  "Existing drawings will be erased. Confirm?",
                                  () async {
                                      reset();
                                      createNewDoc();
                                      Navigator.pop(context, true);
                                    },
                                  (){
                                      Navigator.pop(context, false);
                                  }
                                );
                              }
                              break;
                            case "preferences":
                              MaterialPageRoute<Map<String, dynamic>> preferencesRoute = MaterialPageRoute<Map<String, dynamic>>(
                                builder: (context){
                                  return PreferencesPage(
                                    gridEnabled,
                                    enableRuler,
                                    snapToGridNode,
                                    gridHorizontalGap.toString(),
                                    gridVerticalGap.toString(),
                                  );
                                },
                              );
                              Map<String, dynamic>? changes = await Navigator.push<Map<String, dynamic>>(context, preferencesRoute);
                              if(changes != null){
                                for(MapEntry<String, dynamic> entry in changes.entries){
                                  switch(entry.key){
                                    case "grid_lines":
                                      setState(() {
                                        gridEnabled = entry.value;
                                      });
                                      break;
                                    case "snap_to_grid_node":
                                      setState(() {
                                        snapToGridNode = entry.value;
                                      });
                                      break;
                                    case "ruler":
                                      setState(() {
                                        enableRuler = entry.value;
                                      });
                                      break;
                                    case "horizontal_grid_gap":
                                      setState(() {
                                        gridHorizontalGap = entry.value;
                                      });
                                      break;
                                    case "vertical_grid_gap":
                                      setState(() {
                                        gridVerticalGap = entry.value;
                                      });
                                      break;
                                    default:
                                      break;
                                  }
                                }
                              }
                              break;
                            default:
                              break;
                          }
                        },
                        child: const Material(
                          shape: CircleBorder(),
                          color: Colors.white,
                          child: Icon(Icons.more_vert, size: 24, color: Colors.orange)
                        ),
                        color: Colors.black,
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9.0),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                width: screenWidth,
                height: screenHeight - appBarHeight,
                child: Row(
                  children: [
                    Container(
                        width: sideBarWidth,
                        height: screenHeight - appBarHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Material(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)
                          ),
                          elevation: 10.0,
                          color: Colors.grey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              getSideBarButton(pickCurve, Icons.add, toolTipMessage: "Add Curves"),
                              getActionButton(context,
                                  EditingMode.FreeDraw,
                                  currentMode == EditingMode.FreeDraw,
                                  widget: const FreeDrawIcon(widthSize: 28),
                                  toolTipMessage: "Free Draw"
                              ),
                              getSideBarButton(pickStrokeWidth, Icons.line_weight, toolTipMessage: "Set Stroke Width"),
                              getSideBarButton(actionStack.isNotEmpty ? undoLastAction : null, Icons.undo, toolTipMessage: "Undo Last Action"),
                              getSideBarButton(
                                  groupSelection.isNotEmpty ? groupSelectedCurves : null,
                                  Icons.undo,
                                  toolTipMessage: "Group curves",
                                  iconWidget: const GroupIcon(widthSize: 28)
                              ),
                              getSideBarButton(
                                  currentMode == EditingMode.GroupCurve ? unGroupCurves : null,
                                  Icons.undo,
                                  toolTipMessage: "Ungroup curves",
                                  iconWidget: const UngroupIcon(widthSize: 28)
                              ),
                            ],
                          ),
                        )
                    ),
                    LimitedBox(
                      maxHeight: screenHeight - appBarHeight,
                      maxWidth: screenWidth - sideBarWidth,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Stack(
                            children: [
                              SizedBox(
                                width: screenWidth - sideBarWidth,
                                height: screenHeight - appBarHeight,
                                child: GestureDetector(
                                  onTapUp: (dt){
                                    closeMenus();
                                    deactivateCurrentActivePath();
                                  },
                                )
                              ),
                              Positioned(
                                top: 4,
                                right: showPathsPanel ? 304 : 4,
                                child: SizedBox(
                                  height: 60,
                                  width: 150,
                                  child: Column(
                                    children: [
                                      Material(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        color: Colors.grey,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal:8),
                                              child: Text("Zoom: ${zoomFactor.toStringAsPrecision(3)}x", style: const TextStyle(fontSize:12, color: Colors.white)),
                                            ),
                                            SizedBox(
                                              width: 32,
                                              child: MaterialButton(
                                                shape: const CircleBorder(),
                                                padding: EdgeInsets.zero,
                                                child: const Icon(Icons.zoom_in, size: 24, color: Colors.white),
                                                onPressed: (){
                                                  setState(() {
                                                    zoomFactor = incrementZoomFactor(zoomFactor);
                                                    panOffset = Offset(
                                                        min(max(panOffset.dx, -(_standardCanvasWidth * (zoomFactor - 1))), 0),
                                                        min(max(panOffset.dy, -(_standardCanvasHeight * (zoomFactor - 1))), 0)
                                                    );
                                                    scaleThenTranslateMatrix = scaleThenTranslate(zoomFactor, panOffset).storage;
                                                  });
                                                },
                                              ),
                                            ),
                                            SizedBox(
                                              width:32,
                                              child: MaterialButton(
                                                shape: const CircleBorder(),
                                                padding: EdgeInsets.zero,
                                                child: const Icon(Icons.zoom_out, size: 24, color: Colors.white),
                                                onPressed: (){
                                                  setState(() {
                                                    zoomFactor = decrementZoomFactor(zoomFactor);
                                                    panOffset = Offset(
                                                        min(max(panOffset.dx, -(_standardCanvasWidth * (zoomFactor - 1))), 0),
                                                        min(max(panOffset.dy, -(_standardCanvasHeight * (zoomFactor - 1))), 0)
                                                    );
                                                    scaleThenTranslateMatrix = scaleThenTranslate(zoomFactor, panOffset).storage;
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                        child: Text("Hold 'Shift' key to pan", style: TextStyle(fontSize:12, color:Colors.grey), textAlign: TextAlign.left,),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              if(enableRuler)
                                Positioned(
                                  top: horizontalRulerTopPosition,
                                  left: horizontalRulerLeftPosition,
                                  child: HorizontalRuler(zoomFactor, panOffset),
                                ),
                              if(enableRuler)
                                Positioned(
                                  top: verticalRulerTopPosition,
                                  left: verticalRulerLeftPosition,
                                  child: VerticalRuler(zoomFactor, panOffset),
                                ),
                              Positioned(
                                top: canvasTopPosition,
                                left: canvasLeftPosition,
                                child: Container(
                                  width: _standardCanvasWidth + 12,
                                  height: _standardCanvasHeight,
                                  padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                  child: GestureDetector(
                                    onPanDown: (dt){
                                      closeMenus();
                                      if(shiftKeyPressed){
                                        return;
                                      } else {
                                        curvePanDown(canvasSize, dt);
                                      }
                                    },
                                    onPanUpdate: (dt){
                                      if(shiftKeyPressed){
                                        Offset offset = panOffset + dt.delta;
                                        setState(() {
                                          panOffset = Offset(
                                              min(max(offset.dx, -(_standardCanvasWidth * (zoomFactor - 1))), 0),
                                              min(max(offset.dy, -(_standardCanvasHeight * (zoomFactor - 1))), 0)
                                          );
                                          scaleThenTranslateMatrix = scaleThenTranslate(zoomFactor, panOffset).storage;
                                        });
                                        return;
                                      } else {
                                        curvePanUpdate(canvasSize, dt);
                                      }
                                    },
                                    onPanEnd: (dt){
                                      curvePanEnd(canvasSize, dt);
                                    },
                                    child: Material(
                                      type: MaterialType.canvas,
                                      child: MouseRegion(
                                        onHover: _mouseHoverCallBack,
                                        child: CustomPaint(
                                            painter: FastDraw(
                                                drawer: (Canvas canvas, Size size){
                                                  canvas.clipRect(Offset.zero & size);
                                                  if(hasBackgroundImage && currentImage != null){
                                                    canvas.drawImage(currentImage!, panOffset, Paint(),);
                                                    backgroundImageChanged = false;
                                                  }
                                                  if(gridEnabled){
                                                    drawGrid(canvas, size, zoomFactor, panOffset);
                                                  }
                                                  if(pathsCollection.isNotEmpty){
                                                    drawInactivePaths(canvas, size, pathsCollection, currentEditingCurveIndex);
                                                  }
                                                },
                                                shouldRedraw: backgroundImageChanged || gridChanged || pathsCollectionChanged,
                                            ),
                                          foregroundPainter: FastDraw(
                                            drawer: (Canvas canvas, Size size){
                                              canvas.clipRect(Offset.zero & size);
                                              Path? selectedPoint, selectedRestrictedPoint, selectedDataPoint;
                                              if(pointerHoveringPoint != null && pendingOffset == null){
                                                canvas.drawOval(Rect.fromCenter(center: pointerHoveringPoint!, width: 3, height: 3), fillPaint);
                                              }
                                              if(indexOfSelectedControlPoint != null){
                                                selectedPoint = Path();
                                                selectedPoint.addOval(Rect.fromCenter(center: pathsCollection[currentEditingCurveIndex!]["control_points"][indexOfSelectedControlPoint!], width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
                                                canvas.drawPath(selectedPoint.transform(scaleThenTranslateMatrix), strokePaint);
                                              }
                                              if(indexOfSelectedRestrictedControlPoint != null){
                                                selectedRestrictedPoint = Path();
                                                selectedRestrictedPoint.addRect(Rect.fromCenter(center: pathsCollection[currentEditingCurveIndex!]["restricted_control_points"][indexOfSelectedRestrictedControlPoint!], width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
                                                canvas.drawPath(selectedRestrictedPoint.transform(scaleThenTranslateMatrix), strokePaint);
                                              }
                                              if(indexOfSelectedDataControlPoint != null){
                                                selectedDataPoint = Path();
                                                selectedDataPoint.addOval(Rect.fromCenter(center: pathsCollection[currentEditingCurveIndex!]["data_control_points"][indexOfSelectedDataControlPoint!], width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
                                                canvas.drawPath(selectedDataPoint.transform(scaleThenTranslateMatrix), strokePaint);
                                              }
                                              if(pendingOffset != null && !readyToTransform){
                                                canvas.drawOval(Rect.fromCenter(center: pendingOffset!, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor), fillPaint);
                                                if(selectionOffset != null){
                                                  canvas.drawOval(Rect.fromCenter(center: selectionOffset!, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor), fillPaint);
                                                  canvas.drawRect(Rect.fromPoints(pendingOffset!, selectionOffset!), boundingPaint);
                                                }
                                              }
                                              if(groupSelection.isNotEmpty){
                                                for(int i in groupSelection){
                                                  Path indexIPath = drawActivePath(canvas, pathsCollection[i]);
                                                  drawBoundingRect(canvas, indexIPath);
                                                }
                                              } else if (currentEditingCurveIndex != null){
                                                Path currentPath = drawActivePath(canvas, pathsCollection[currentEditingCurveIndex!]);
                                                drawBoundingRect(canvas, currentPath);
                                                pathsCollection[currentEditingCurveIndex!]["bounding_rect"] = boundingRect ?? Rect.zero;
                                                // , rect: currentMode == EditingMode.Arc ? pathsCollection[currentEditingCurveIndex!]["bounding_rect"] : null);
                                              }
                                              // canvas.drawPath(activePath.transform(scaleThenTranslateMatrix), fillPaint);
                                            },
                                            shouldRedraw: true,
                                          ),
                                        ),
                                      ),
                                      shape: const ContinuousRectangleBorder(
                                        side: BorderSide(width: 1.0, color: Colors.black),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: strokeColorTabTopPosition,
                                right: strokeColorTabRightPosition,
                                child: colorTab(paletteRect, "Stroke"),
                              ),
                              Positioned(
                                top: fillColorTabTopPosition,
                                right: fillColorTabRightPosition,
                                child: colorTab(paletteRect, "Fill"),
                              ),
                              if(showPathsPanel)
                                Positioned(
                                  top:0,
                                  right: 0,
                                  child: Material(
                                    elevation: 10.0,
                                    color: Colors.white,
                                    shape: const ContinuousRectangleBorder(),
                                    child: SizedBox(
                                        width: 300,
                                        height: screenHeight - appBarHeight,
                                        child: ReorderableListView(
                                          scrollDirection: Axis.vertical,
                                          buildDefaultDragHandles: false,
                                          onReorder: (oldId, newId){
                                            setState(() {
                                              if (oldId < newId){
                                                pathsCollection.insert(newId, pathsCollection[oldId]);
                                                pathsCollection.removeAt(oldId);
                                              } else if ( oldId > newId){
                                                pathsCollection.insert(newId, pathsCollection[oldId]);
                                                pathsCollection.removeAt(oldId + 1);
                                              }
                                            });
                                          },
                                          padding: EdgeInsets.zero,
                                          children: subPathListWidget(pathsCollection),
                                        )
                                    ),
                                  ),
                                ),
                              if(currentMode != EditingMode.None)
                                Positioned(
                                  top: optionBoxTopPosition,
                                  left: optionBoxLeftPosition,
                                  child: optionBox(currentMode),
                                ),
                              if(showStrokeWidthSelector)
                                Positioned(
                                  top: 100,
                                  left: 10,
                                  child: Material(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9.0),
                                    ),
                                    elevation: 10.0,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                            child: const Text("1.0",style: TextStyle(fontSize:16, ), textAlign: TextAlign.center,)),
                                          SizedBox(
                                            height: 35,
                                            child: Slider(
                                              value: currentStrokeColor.strokeWidth,
                                              onChanged: (double val) {
                                                if(actionStack.isEmpty || !(actionStack.last).containsKey(DrawAction.changePaintStrokeWidth)){
                                                  actionStack.add({
                                                    DrawAction.changePaintStrokeWidth: {
                                                      "original_stroke_width": currentStrokeColor.strokeWidth,
                                                      "editing_curve_index": currentEditingCurveIndex,
                                                    }
                                                  });
                                                }
                                                setState(() {
                                                  currentStrokeColor.strokeWidth = val;
                                                  if(currentEditingCurveIndex != null){
                                                    actionStack.last[DrawAction.changePaintStrokeWidth]["original_curve_paint_stroke_width"] = pathsCollection[currentEditingCurveIndex!]["stroke"].strokeWidth;
                                                    pathsCollection[currentEditingCurveIndex!]["stroke"].strokeWidth = val;
                                                  }
                                                });
                                              },
                                              min: 1.0,
                                              max: 20.0,
                                              divisions: 190,
                                              label: currentStrokeColor.strokeWidth.toStringAsPrecision(3),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                            child: const Text("20.0", style: TextStyle(fontSize:16), textAlign: TextAlign.center,)
                                          ),
                                          getSideBarButton(() {
                                            setState(() {
                                              showStrokeWidthSelector = false;
                                            });
                                          }, Icons.check)
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                              if(showAddCurveMenu)
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: Container(
                                    width: 200,
                                    height: 400,
                                    padding: const EdgeInsets.symmetric(horizontal:6, vertical:6),
                                    child: Material(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(9.0),
                                      ),
                                      elevation: 10.0,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children:[
                                          Container(
                                            padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
                                            child: const Text("Lines and Curves", style: TextStyle(fontSize: 14, color: Colors.black),),
                                          ),
                                          const Divider(
                                            height: 10,
                                            thickness: 2.0,
                                            indent: 2.0,
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              getActionButton(
                                                context, EditingMode.Line,
                                                currentMode == EditingMode.Line,
                                                semantics: Semantics(label: "Add a straight line control point"),
                                                widget: const LineIcon(widthSize: 28),
                                                toolTipMessage: "Add a straight line"
                                              ),
                                              getActionButton(
                                                context, EditingMode.Arc,
                                                currentMode == EditingMode.Arc,
                                                semantics: Semantics(label: "Add an arc control point"),
                                                widget: const ArcIcon(widthSize: 28),
                                                toolTipMessage: "Add an arc"
                                              ),
                                              getActionButton(
                                                context, EditingMode.SplineCurve,
                                                currentMode == EditingMode.SplineCurve,
                                                semantics: Semantics(label: "Add a Catmull Rom spline control point"),
                                                widget: const CatmullRomCurveIcon(widthSize: 28),
                                                toolTipMessage: "Add a spline curve"
                                              ),
                                              getActionButton(
                                                context, EditingMode.QuadraticBezier,
                                                currentMode == EditingMode.QuadraticBezier,
                                                semantics: Semantics(label: "Edit quadratic bezier curve control point"),
                                                widget: const QuadraticBezierCurveIcon(widthSize: 28),
                                                toolTipMessage: "Add a quadratic bezier curve"
                                              ),
                                              getActionButton(
                                                context, EditingMode.CubicBezier,
                                                currentMode == EditingMode.CubicBezier,
                                                semantics: Semantics(label: "Edit cubic bezier curve control point"),
                                                widget: const CubicBezierCurveIcon(widthSize: 28),
                                                toolTipMessage: "Add a cubic bezier curve",
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
                                            child: const Text("Shapes", style: TextStyle(fontSize: 14, color: Colors.black),),
                                          ),
                                          const Divider(
                                            height: 10,
                                            thickness: 2.0,
                                            indent: 2.0,
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              getActionButton(
                                                context, EditingMode.Triangle,
                                                currentMode == EditingMode.Triangle,
                                                semantics: Semantics(label: "triangle"),
                                                widget: const TriangleIcon(widthSize: 28),
                                                toolTipMessage: "Add a triangle",
                                              ),
                                              getActionButton(
                                                context, EditingMode.Rectangle,
                                                currentMode == EditingMode.Rectangle,
                                                semantics: Semantics(label: "rectangle"),
                                                widget: const RectangleIcon(widthSize: 28),
                                                toolTipMessage: "Add a rectangle",
                                              ),
                                              getActionButton(
                                                context, EditingMode.Pentagon,
                                                currentMode == EditingMode.Pentagon,
                                                semantics: Semantics(label: "pentagon"),
                                                widget: const PentagonIcon(widthSize: 28),
                                                toolTipMessage: "Add a pentagon",
                                              ),
                                              getActionButton(
                                                context, EditingMode.Polygon,
                                                currentMode == EditingMode.Polygon,
                                                semantics: Semantics(label: "polygon"),
                                                widget: const PolygonIcon(widthSize: 28),
                                                toolTipMessage: "Add a polygon",
                                              ),
                                              getActionButton(
                                                context, EditingMode.Conic,
                                                currentMode == EditingMode.Conic,
                                                semantics: Semantics(label: "conic"),
                                                widget: const ConicIcon(widthSize: 28),
                                                toolTipMessage: "Add a conic",
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              getActionButton(
                                                context, EditingMode.Star,
                                                currentMode == EditingMode.Star,
                                                semantics: Semantics(label: "star"),
                                                widget: const StarIcon(widthSize: 28),
                                                toolTipMessage: "Add a star",
                                              ),
                                              getActionButton(
                                                context, EditingMode.Heart,
                                                currentMode == EditingMode.Heart,
                                                semantics: Semantics(label: "heart"),
                                                widget: const HeartIcon(widthSize: 28),
                                                toolTipMessage: "Add a heart shape",
                                              ),
                                              getActionButton(
                                                context, EditingMode.Arrow,
                                                currentMode == EditingMode.Arrow,
                                                semantics: Semantics(label: "arrow"),
                                                widget: const ArrowIcon(widthSize: 28),
                                                toolTipMessage: "Add an arrow shape",
                                              ),
                                              getActionButton(
                                                context, EditingMode.Leaf,
                                                currentMode == EditingMode.Leaf,
                                                semantics: Semantics(label: "leaf"),
                                                widget: const LeafIcon(widthSize: 28),
                                                toolTipMessage: "Add a leaf shape",
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
                                            child: const Text("Directed Lines", style: TextStyle(fontSize: 14, color: Colors.black),),
                                          ),
                                          const Divider(
                                            height: 10,
                                            thickness: 2.0,
                                            indent: 2.0,
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              getActionButton(
                                                context, EditingMode.DirectedLine,
                                                currentMode == EditingMode.DirectedLine,
                                                semantics: Semantics(label: "directed_line"),
                                                widget: const DirectedLineIcon(widthSize: 28),
                                                toolTipMessage: "Add a directed line",
                                              ),
                                              getActionButton(
                                                context, EditingMode.CurveDirectedLine,
                                                currentMode == EditingMode.CurveDirectedLine,
                                                semantics: Semantics(label: "curve_directed_line"),
                                                widget: const CurveDirectedLineIcon(widthSize: 28),
                                                toolTipMessage: "Add a curved directed line",
                                              ),

                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
                                            child: const Text("Complex Curves", style: TextStyle(fontSize: 14, color: Colors.black),),
                                          ),
                                          const Divider(
                                            height: 10,
                                            thickness: 2.0,
                                            indent: 2.0,
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              getActionButton(
                                                context, EditingMode.CompositeCurve,
                                                currentMode == EditingMode.CompositeCurve,
                                                semantics: Semantics(label: "composite_curve"),
                                                widget: const OpenCurveIcon(widthSize: 28),
                                                toolTipMessage: "Add a composite curve",
                                              ),
                                              getActionButton(
                                                context, EditingMode.Wave,
                                                currentMode == EditingMode.Wave,
                                                semantics: Semantics(label: "wave"),
                                                widget: const WaveIcon(widthSize: 28),
                                                toolTipMessage: "Add a wave-like curve",
                                              ),
                                            ],
                                          ),
                                        ]
                                      )
                                    )
                                  )
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void deactivateCurrentActivePath(){
    setState(() {
      currentEditingCurveIndex = null;
      groupSelection = [];
      indexOfSelectedControlPoint = null;
      indexOfSelectedRestrictedControlPoint = null;
      currentMode = EditingMode.None;
      boundingRect = null;
      readyToTransform = false;
    });
  }

  void activatePath(int index, EditingMode mode, {bool deactivateCurrentPathFirst = true}){
    if(deactivateCurrentPathFirst){
      deactivateCurrentActivePath();
    }
    setState(() {
      currentMode = mode;
      currentEditingCurveIndex = index;
      currentStrokeColor = pathsCollection[index]["stroke"];
      currentFillColor = pathsCollection[index]["fill"];
    });
  }

  void autosave({String drawingName = _defaultDrawingName}){
    webIO.autosave(pathsCollection, currentDocId, drawingName);
  }

  Map<String, dynamic> updateTransformationReferences(Offset localPosition, Offset delta){
    switch(transformation){
      case TransformCurve.Translate:
        return {"translate_x": delta.dx / zoomFactor, "translate_y": delta.dy / zoomFactor};
      case TransformCurve.Rotate:
        double rotation = (localPosition - transformationReferenceOffset!).direction - panReference!;
        panReference = (localPosition - transformationReferenceOffset!).direction;
        return {"rotation": rotation};
      case TransformCurve.ScaleHorizontal:
        double horizontalScaleFactor = (localPosition.dx - transformationReferenceOffset!.dx) / panReference!;
        panReference = localPosition.dx - transformationReferenceOffset!.dx;
        return {"factor": horizontalScaleFactor};
      case TransformCurve.ScaleVertical:
        double verticalScaleFactor = (localPosition.dy - transformationReferenceOffset!.dy) / panReference!;
        panReference = localPosition.dy - transformationReferenceOffset!.dy;
        return {"factor": verticalScaleFactor};
      case TransformCurve.Scale:
        Offset scaleFactor = Offset((localPosition.dx - transformationReferenceOffset!.dx) / panReference!, (localPosition.dy - transformationReferenceOffset!.dy) / panSecondReference!);
        panReference = localPosition.dx - transformationReferenceOffset!.dx;
        panSecondReference = localPosition.dy - transformationReferenceOffset!.dy;
        return {"factor": scaleFactor};
      case TransformCurve.moveControlPoint:
        if(indexOfGroupedRestrictedControlPointFrom != null){
          return {
            "new_location": localPosition,
            "restriction_index": -1,
          };
        } else {
          return {
            "new_location": localPosition,
            "restriction_index": -1,
          };
        }
      case TransformCurve.moveRestrictedControlPoint:
        if(indexOfGroupedRestrictedControlPointFrom != null){
          return {
            "new_location": localPosition,
            "restriction_index": indexOfSelectedRestrictedControlPoint! - indexOfGroupedRestrictedControlPointFrom!,
          };
        } else {
          return {
            "new_location": localPosition,
            "restriction_index": indexOfSelectedRestrictedControlPoint,
          };
        }
      case TransformCurve.moveDataControlPoint:
        if(indexOfGroupedRestrictedControlPointFrom != null){
          return {
            "new_location": localPosition,
            "restriction_index": indexOfSelectedDataControlPoint! - indexOfGroupedDataControlPointFrom!,
          };
        } else {
          return {
            "new_location": localPosition,
            "restriction_index": indexOfSelectedDataControlPoint,
          };
        }
      default:
        print("Returning default values when updating transform references");
        return {"default": null};
    }
  }

  List<Offset> getTransformControlPoints(List<Offset> originalControlPoints, Map<String, dynamic> args){
    switch(transformation){
      case TransformCurve.Translate:
        return getTranslatedPoints(originalControlPoints, args["translate_x"], args["translate_y"]);
      case TransformCurve.Rotate:
        return getRotatedPoints(originalControlPoints, (transformationReferenceOffset! - panOffset)/ zoomFactor, args["rotation"]);
      case TransformCurve.ScaleHorizontal:
        return scaleHorizontal(originalControlPoints, (transformationReferenceOffset! - panOffset) / zoomFactor, args["factor"]);
      case TransformCurve.ScaleVertical:
        return scaleVertical(originalControlPoints, (transformationReferenceOffset! - panOffset) / zoomFactor, args["factor"]);
      case TransformCurve.Scale:
        return scale(originalControlPoints, (transformationReferenceOffset! - panOffset) / zoomFactor, args["factor"]);
      default:
        return originalControlPoints;
    }
  }

  Map<String, dynamic> getTransformDataControlPoints(Map<String, dynamic> curve, Map<String, dynamic> args){
    // Affects only transformation that changes the sizes of the curve
    switch(transformation){
      case TransformCurve.Translate:
        return getDataPointsByTranslation(curve["mode"], curve, args["translate_x"], args["translate_y"]);
      case TransformCurve.Rotate:
        return getDataPointsByRotation(curve["mode"], curve, args["rotation"]);
      case TransformCurve.ScaleHorizontal:
        return getDataPointsByHorizontalScale(curve["mode"], curve, (transformationReferenceOffset! - panOffset)/ zoomFactor, args["factor"]);
      case TransformCurve.ScaleVertical:
        return getDataPointsByVerticalScale(curve["mode"], curve, (transformationReferenceOffset! - panOffset)/ zoomFactor, args["factor"]);
      case TransformCurve.Scale:
        return getDataPointsByScale(curve["mode"], curve, (transformationReferenceOffset! - panOffset)/ zoomFactor, args["factor"]);
      default:
        return curve;
    }
  }

  Map<String, dynamic> getTransformRestrictedControlPoints(Map<String, dynamic> curve, Map<String, dynamic> args){
    // Affects only transformation that changes the sizes of the curve
    switch(transformation){
      case TransformCurve.Translate:
        return getRestrictedPointsByTranslation(curve["mode"], curve, args["translate_x"], args["translate_y"]);
      case TransformCurve.Rotate:
        return getRestrictedPointsByRotation(curve["mode"], curve, (transformationReferenceOffset! - panOffset)/ zoomFactor, args["rotation"]);
      case TransformCurve.ScaleHorizontal:
        return getRestrictedPointsByHorizontalScale(curve["mode"], curve, (transformationReferenceOffset! - panOffset)/ zoomFactor, args["factor"]);
      case TransformCurve.ScaleVertical:
        return getRestrictedPointsByVerticalScale(curve["mode"], curve, (transformationReferenceOffset! - panOffset)/ zoomFactor, args["factor"]);
      case TransformCurve.Scale:
        return getRestrictedPointsByScale(curve["mode"], curve, (transformationReferenceOffset! - panOffset)/ zoomFactor, args["factor"]);
      default:
        return curve;
    }
  }


  Matrix4 getTransformMatrix(Map<String, dynamic> args){
    switch(transformation){
      case TransformCurve.Translate:
        return translateXY(args["translate_x"] / zoomFactor, args["translate_y"] / zoomFactor);
      case TransformCurve.Rotate:
        return rotateZAbout(args["rotation"], (transformationReferenceOffset! - panOffset) / zoomFactor);
      case TransformCurve.ScaleHorizontal:
        return scalingX(args["factor"], (transformationReferenceOffset! - panOffset) / zoomFactor);
      case TransformCurve.ScaleVertical:
        return scalingY(args["factor"], (transformationReferenceOffset! - panOffset) / zoomFactor);
      case TransformCurve.Scale:
        return scalingXY(args["factor"], (transformationReferenceOffset! - panOffset) / zoomFactor);
      default:
        return Matrix4.identity();
    }
  }

  Map<String, dynamic> transformPath(Map<String, dynamic> path, Map<String, dynamic> args, {bool isCurrent = true}){
    if(path["mode"] == EditingMode.FreeDraw){
      return updateFreeDrawPath(path, getTransformMatrix(args));
    } else if (path["mode"] == EditingMode.GroupCurve){
      return updateGroupPath(path, args, getTransformMatrix(args));
    } else {
      assert(path["mode"] != EditingMode.None, "Cannot transform a none-mode path");
      return updateBasePath(path, args);
    }
  }

  Map<String, dynamic> updateFreeDrawPath(Map<String, dynamic> curve, Matrix4 transform, {int? cpFrom, int? cpTo, int? rcpFrom, int? rcpTo}){
    assert(curve["mode"] == EditingMode.FreeDraw, "This call applies for free draw curves only.");
    curve["free_draw_spline"].points = List<Offset>.from(curve["free_draw_spline"].points.map((e) => matrixApply(transform, e)).toList());
    curve["free_draw_spline"].splinePath = curve["free_draw_spline"].splinePath.transform(transform.storage);
    return curve;
  }

  Map<String, dynamic> updateAllControlPoints(List<Offset> pointsToUpdate, List<Offset> restrictedPointsToUpdate, Map<String, dynamic> originalCurve, {bool addActionToStack = true, bool unZoomed = false}){
    if(addActionToStack){
      actionStack.add({
        DrawAction.transformControlPoints: {
          "control_points": List<Offset>.from(pathsCollection[currentEditingCurveIndex!]["control_points"]),
          "restricted_control_points": List<Offset>.from(pathsCollection[currentEditingCurveIndex!]["restricted_control_points"]),
          "editing_curve_index": currentEditingCurveIndex,
        }
      });
    }
    if(!unZoomed){
      pointsToUpdate = descalePointsList(pointsToUpdate);
    }
    originalCurve["control_points"] = pointsToUpdate;
    originalCurve["restricted_control_points"] = restrictedPointsToUpdate;
    return originalCurve;
  }

  Map<String, dynamic> updateGroupPath(Map<String, dynamic> groupedCurve, Map<String, dynamic> args, Matrix4 transformMatrix, {List<Offset>? groupControlPoints}){
    groupedCurve["control_points"] = groupControlPoints ?? getTransformControlPoints(groupedCurve["control_points"], args);
    int cpFrom = 0;
    int rcpFrom = 0;
    int dcpFrom = 0;
    int cpTo, rcpTo, dcpTo;
    for(int i = 0; i < groupedCurve["curves"].length; i++){
      Map<String, dynamic> c = groupedCurve["curves"][i];
      cpTo = cpFrom + int.parse(c["control_points"].length.toString());
      rcpTo = rcpFrom + int.parse(c["restricted_control_points"].length.toString());
      dcpTo = dcpFrom + int.parse(c["data_control_points"].length.toString());
      if(c["mode"] == EditingMode.FreeDraw){
        groupedCurve["curves"][i] = updateFreeDrawPath(c, transformMatrix);
      } else if (c["mode"] == EditingMode.GroupCurve){
        groupedCurve["curves"][i] = updateGroupPath(c, args, transformMatrix,
          groupControlPoints: groupedCurve["control_points"].sublist(cpFrom, cpTo),
        );
      } else {
        assert(c["mode"] != EditingMode.None, "Cannot update path with none editing mode.");
        groupedCurve["curves"][i] = updateBasePath(c, args,
          groupControlPoints: groupedCurve["control_points"].sublist(cpFrom, cpTo),
        );
      }
      for(int j = rcpFrom; j < rcpTo; j++){
        groupedCurve["restricted_control_points"][j] = groupedCurve["curves"][i]["restricted_control_points"][j - rcpFrom];
      }
      for(int k = dcpFrom; k < dcpTo; k++){
        groupedCurve["data_control_points"][k] = groupedCurve["curves"][i]["data_control_points"][k - dcpFrom];
      }
      cpFrom = cpTo;
      rcpFrom = rcpTo;
      dcpFrom = dcpTo;
    }
    return groupedCurve;
  }

  Map<String, dynamic> updateBasePath(Map<String, dynamic> path, Map<String, dynamic> args, {List<Offset>? groupControlPoints}){
    assert(path["mode"] != EditingMode.GroupCurve, "Updating base path cannot update group curve");
    path["control_points"] = groupControlPoints ?? getTransformControlPoints(path["control_points"], args);
    return getTransformRestrictedControlPoints(getTransformDataControlPoints(path, args), args);
  }

  Map<String, dynamic> moveControlPoint(Offset localPosition, Offset delta, Map<String, dynamic> path, Map<String, dynamic> args, {int? adjustedIndex}){
    int index = adjustedIndex ?? indexOfSelectedControlPoint!;
    path["control_points"][index] = (localPosition - panOffset) / zoomFactor;
    if(path["mode"] != EditingMode.GroupCurve){
      path = updateRCPWhenCPMoved(path["mode"], path, localPosition, delta, args: args,);
    } else {
      int cpFrom = 0;
      int rcpFrom = 0;
      int dcpFrom = 0;
      int cpLen, rcpLen, dcpLen;
      for(int i = 0; i < path["curves"].length; i++){
        cpLen = path["curves"][i]["control_points"].length;
        rcpLen = path["curves"][i]["restricted_control_points"].length;
        dcpLen = path["curves"][i]["data_control_points"].length;
        if(index < cpFrom + cpLen ){
          path["curves"][i] = moveControlPoint(localPosition, delta, path["curves"][i], args, adjustedIndex: index - cpFrom);
          for(int j = rcpFrom; j < rcpFrom + rcpLen; j++){
            path["restricted_control_points"][j] = path["curves"][i]["restricted_control_points"][j - rcpFrom];
          }
          for(int k = dcpFrom; k < dcpFrom + dcpLen; k++){
            path["data_control_points"][k] = path["curves"][i]["data_control_points"][k - dcpFrom];
          }
          break;
        }
        cpFrom += cpLen;
        rcpFrom += rcpLen;
      }
    }
    return path;
  }

  Map<String, dynamic> moveDataControlPoint(Offset localPosition, Offset delta, Map<String, dynamic> path, {int? adjustedIndex, Map<String, dynamic>? args}){
    int index = adjustedIndex ?? indexOfSelectedDataControlPoint!;
    path["data_control_points"][index] = localPosition;
    switch(path["mode"]){
      case EditingMode.Arc:
        path["width"] = 2 * (localPosition - path["control_points"][0]).dx.abs();
        path["height"] = 2 * (localPosition - path["control_points"][0]).dy.abs();
        Rect rect = Rect.fromCenter(center: path["control_points"][0], width: path["width"], height: path["height"]);
        double rotationAdjustedAngle = (path["restricted_control_points"][2] - rect.center).direction;
        Matrix4 rotationMatrix = rotateZAbout(rotationAdjustedAngle, rect.center);
        path["restricted_control_points"][0] = matrixApply(rotationMatrix, getConicOffset(rect, getConicDirection(rect, (path["restricted_control_points"][0] - rect.center).direction - rotationAdjustedAngle)));
        path["restricted_control_points"][1] = matrixApply(rotationMatrix, getConicOffset(rect, getConicDirection(rect, (path["restricted_control_points"][1] - rect.center).direction - rotationAdjustedAngle)));
        path["restricted_control_points"][2] = matrixApply(rotationMatrix, path["control_points"][0] + Offset.fromDirection(0, (rect.bottomRight - rect.center).distance));
        return path;
      case EditingMode.Conic:
        path["width"] = 2 * (localPosition - path["control_points"][0]).dx.abs();
        path["height"] = 2 * (localPosition - path["control_points"][0]).dy.abs();
        Rect rect = Rect.fromCenter(center: path["control_points"][0], width: path["width"], height: path["height"]);
        double rotationAdjustedAngle = (path["restricted_control_points"][0] - rect.center).direction;
        Matrix4 rotationMatrix = rotateZAbout(rotationAdjustedAngle, rect.center);
        path["restricted_control_points"][0] = matrixApply(rotationMatrix, path["control_points"][0] + Offset.fromDirection(0, (rect.bottomRight - rect.center).distance));
        return path;
      case EditingMode.GroupCurve:
        int from = 0;
        int rcpFrom = 0;
        int len, rcpLen;
        for(int i = 0; i < path["curves"].length; i++){
          len = path["curves"][i]["data_control_points"].length;
          rcpLen = path["curves"][i]["restricted_control_points"].length;
          if(index < from + len){
            path["curves"][i] = moveDataControlPoint(localPosition, delta, path["curves"][i], adjustedIndex: index - from, args: args);
            for(int j = rcpFrom; j < rcpFrom + rcpLen; j++){
              path["restricted_control_points"][j] = path["curves"][i]["restricted_control_points"][j - rcpFrom];
            }
            for(int k = from; k < from + len; k++){
              path["data_control_points"][k] = path["curves"][i]["data_control_points"][k - from];
            }
            break;
          }
          from += len;
          rcpFrom += rcpLen;
        }
        return path;
      default:
        return path;
    }
  }

  Map<String, dynamic> moveRestrictedControlPoint(Offset localPosition, Offset delta, Map<String, dynamic> path, {int? adjustedIndex, Map<String, dynamic>? args}){
    int index = adjustedIndex ?? indexOfSelectedRestrictedControlPoint!;
    if(path["mode"] != EditingMode.GroupCurve){
      path["restricted_control_points"][index] = updateRestrictedControlPoint(
        path["mode"],
        path,
        localPosition,
        delta,
        path["restricted_control_points"][index],
        args: args
      );
    } else {
      int from = 0;
      int len;
      for(int i = 0; i < path["curves"].length; i++){
        len = path["curves"][i]["restricted_control_points"].length;
        if(index < from + len){
          path["curves"][i] = moveRestrictedControlPoint(localPosition, delta, path["curves"][i], adjustedIndex: index - from, args: args);
          for(int j = from; j < from + len; j++){
            path["restricted_control_points"][j] = path["curves"][i]["restricted_control_points"][j - from];
          }
          break;
        }
        from += len;
      }
    }
    return path;
  }

  List<Widget> generalTools(){
    return <Widget>[
      getActionButton(context, EditingMode.None, false, toolTipMessage: "Duplicate", widget: const Icon(Icons.copy, size:18, color:Colors.white),
        customOnPressed:(){
          List<Offset> dupControlPoints = List<Offset>.from(pathsCollection[currentEditingCurveIndex!]["control_points"]);
          Map<String, dynamic> duplication = Map<String, dynamic>.from(pathsCollection[currentEditingCurveIndex!]);
          if(currentMode == EditingMode.FreeDraw){
            duplication["free_draw_spline"] = SplinePath.generate(List.from(pathsCollection[currentEditingCurveIndex!]["free_draw_spline"].points));
          }
          duplication["control_points"] = dupControlPoints;
          duplication["restricted_control_points"] = [
            for(Offset restrictedPoint in pathsCollection[currentEditingCurveIndex!]["restricted_control_points"])
              Offset(restrictedPoint.dx, restrictedPoint.dy),
            ];
          duplication["stroke"] = copyPaint(pathsCollection[currentEditingCurveIndex!]["stroke"]);
          duplication["fill"] = copyPaint(pathsCollection[currentEditingCurveIndex!]["fill"]);
          actionStack.add(
              {DrawAction.duplicateCurve: {
                "duplicated_curve": duplication,
                "editing_curve_index": currentEditingCurveIndex!,
              }
              });
          setState(() {
            pathsCollection.insert(currentEditingCurveIndex!, duplication);
          });
          if(currentMode == EditingMode.FreeDraw){
            setState((){
              pathsCollection[currentEditingCurveIndex!] = updateFreeDrawPath(pathsCollection[currentEditingCurveIndex!], translate(const Offset(5,5)));
            });
          } else if (currentMode == EditingMode.GroupCurve){
            setState((){
              pathsCollection[currentEditingCurveIndex!] = updateGroupPath(
                  pathsCollection[currentEditingCurveIndex!], {"translate_x": 5, "translate_y":5}, translate(const Offset(5,5))
              );
            });
          } else if (currentMode != EditingMode.None){
            readyToTransform = true;
            transformation = TransformCurve.Translate;
            setState(() {
              pathsCollection[currentEditingCurveIndex!] = updateBasePath(pathsCollection[currentEditingCurveIndex!], {"translate_x":5, "translate_y":5});
            });
            readyToTransform = false;
            transformation = TransformCurve.None;
          }
        }
      ),
      getActionButton(context, EditingMode.None, false, toolTipMessage: "Flip Horizontal", widget: const FlipHorizontalIcon(widthSize: 28,),
          customOnPressed: (){
            if(boundingRect != null){
              Offset center = boundingRect!.center;
              if (currentMode == EditingMode.FreeDraw){
                setState((){
                  pathsCollection[currentEditingCurveIndex!] = updateFreeDrawPath(pathsCollection[currentEditingCurveIndex!], horizontalFlip(center));
                });
              } else if (currentMode == EditingMode.GroupCurve){
                List<Offset> rcp = getFlipHorizontal(pathsCollection[currentEditingCurveIndex!]["restricted_control_points"], descalePoint(center));
                setState(() {
                  updateGroupCurveControlPoints(getFlipHorizontal(pathsCollection[currentEditingCurveIndex!]["control_points"], center), pathsCollection[currentEditingCurveIndex!]);
                  updateGroupCurveRestrictedControlPoints(rcp, pathsCollection[currentEditingCurveIndex!]);
                });
              } else if(currentMode != EditingMode.None){
                List<Offset> rcp = getFlipHorizontal(pathsCollection[currentEditingCurveIndex!]["restricted_control_points"], descalePoint(center));
                setState((){
                  pathsCollection[currentEditingCurveIndex!] = updateAllControlPoints(
                      getFlipHorizontal(pathsCollection[currentEditingCurveIndex!]["control_points"], descalePoint(center)),
                      rcp,
                      pathsCollection[currentEditingCurveIndex!], unZoomed : true);
                });
              }
            }
          }),
      getActionButton(context, EditingMode.None, false, toolTipMessage: "Flip Vertical", widget: const FlipVerticalIcon(widthSize: 28,),
          customOnPressed: (){
            if(boundingRect != null){
              Offset center = boundingRect!.center;
              if (currentMode == EditingMode.FreeDraw){
                setState((){
                  pathsCollection[currentEditingCurveIndex!] = updateFreeDrawPath(pathsCollection[currentEditingCurveIndex!], verticalFlip(center));
                });
              } else if (currentMode == EditingMode.GroupCurve){
                List<Offset> rcp = getFlipVertical(pathsCollection[currentEditingCurveIndex!]["restricted_control_points"], descalePoint(center));
                setState(() {
                  updateGroupCurveControlPoints(getFlipVertical(pathsCollection[currentEditingCurveIndex!]["control_points"], center), pathsCollection[currentEditingCurveIndex!]);
                  // activePathPoints = pathsCollection[currentEditingCurveIndex!]["control_points"];
                  updateGroupCurveRestrictedControlPoints(rcp, pathsCollection[currentEditingCurveIndex!]);
                  // activeRestrictedPathPoints = pathsCollection[currentEditingCurveIndex!]["restricted_control_points"];
                  // activePath.reset();
                  // for(Offset point in activePathPoints){
                  //   activePath.addOval(Rect.fromCenter(center: point, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
                  // }
                  // for(Offset restrictedPoint in activeRestrictedPathPoints){
                  //   activePath.addRect(Rect.fromCenter(center: restrictedPoint, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
                  // }
                });
              } else if(currentMode != EditingMode.None){
                List<Offset> rcp = getFlipVertical(pathsCollection[currentEditingCurveIndex!]["restricted_control_points"], descalePoint(center));
                setState((){
                  pathsCollection[currentEditingCurveIndex!] = updateAllControlPoints(
                      getFlipVertical(pathsCollection[currentEditingCurveIndex!]["control_points"], descalePoint(center)),
                      rcp,
                      pathsCollection[currentEditingCurveIndex!], unZoomed : true);
                });
              }
            }
          }),
      getActionButton(context, EditingMode.None, pathsCollection[currentEditingCurveIndex!]["outlined"], toolTipMessage: "Toggle Outline", widget: const Icon(Icons.format_paint, size: 18, color: Colors.white),
          // (widthSize: 28,),
          customOnPressed: (){
            setState((){
              pathsCollection[currentEditingCurveIndex!]["outlined"] = !pathsCollection[currentEditingCurveIndex!]["outlined"];
            });
          }),
      getActionButton(context, EditingMode.None, pathsCollection[currentEditingCurveIndex!]["filled"], toolTipMessage: "Toggle Filled", widget: const FillIcon(widthSize: 28),
          customOnPressed: (){
            setState((){
              pathsCollection[currentEditingCurveIndex!]["filled"] = !pathsCollection[currentEditingCurveIndex!]["filled"];
            });
          }),
    ];
  }

  void updateGroupCurveControlPoints(List<Offset> newControlPoints, Map<String, dynamic> groupCurve){
    assert(newControlPoints.length == groupCurve["control_points"].length, "New set of control points must have the same number of points in the group curve");
    groupCurve["control_points"] = newControlPoints;
    List<Map<String, dynamic>> curves = groupCurve["curves"];
    int from = 0;
    int to;
    for(Map<String, dynamic> curve in curves){
      to = int.parse((from + curve["control_points"].length).toString());
      curve["control_points"] = newControlPoints.sublist(from, to);
      if(curve["mode"] == EditingMode.GroupCurve){
        updateGroupCurveControlPoints(curve["control_points"], curve);
      }
      from = to;
    }
  }

  void updateGroupCurveRestrictedControlPoints(List<Offset> newRestrictedControlPoints, Map<String, dynamic> groupCurve){
    assert(newRestrictedControlPoints.length == groupCurve["restricted_control_points"].length, "New set of restricted control points must have the same number of restricted points in the group curve");
    groupCurve["restricted_control_points"] = newRestrictedControlPoints;
    List<Map<String, dynamic>> curves = groupCurve["curves"];
    int from = 0;
    int to;
    for(Map<String, dynamic> curve in curves){
      to = int.parse((from + curve["restricted_control_points"].length).toString());
      curve["restricted_control_points"] = newRestrictedControlPoints.sublist(from, to);
      if(curve["mode"] == EditingMode.GroupCurve){
        updateGroupCurveControlPoints(curve["restricted_control_points"], curve);
      }
      from = to;
    }
  }

  Offset descalePoint(Offset offset){
    return offset / zoomFactor;
  }

  List<Offset> descalePointsList(List<Offset> pointsList){
    return pointsList.map((p) => p / zoomFactor).toList();
  }

  Widget optionBox(EditingMode mode){
    assert(currentEditingCurveIndex != null, "Non-none editing mode must correspond to a non-null current editing curve index");
    List<Widget> modeSpecificOptions = [];
    if(isShapeMode(mode)){
      modeSpecificOptions.add(
        getActionButton(
          context,
          mode,
          false,
          widget: const RegulariseIcon(widthSize: 28,),
          customOnPressed: (){
            List<Offset>? regularisedPoints = getRegularisedPoints(pathsCollection[currentEditingCurveIndex!]["control_points"], mode);
            // shapes mode has not introduced restricted control points (yet)
            if(regularisedPoints != null){
              setState((){
                pathsCollection[currentEditingCurveIndex!] = updateAllControlPoints(regularisedPoints, pathsCollection[currentEditingCurveIndex!]["restricted_control_points"], pathsCollection[currentEditingCurveIndex!], unZoomed: true);
              });
            }
          },
          toolTipMessage: "Convert to regular shape"
        )
      );
    }
    if(isLineOrCurve(mode)){
      modeSpecificOptions.add(
          getActionButton(
              context,
              mode,
              pathsCollection[currentEditingCurveIndex!]["close"],
              widget: const CloseCurveIcon(widthSize: 28,),
              customOnPressed: (){
                setState(() {
                  pathsCollection[currentEditingCurveIndex!]["close"] = !pathsCollection[currentEditingCurveIndex!]["close"];
                });
              },
              toolTipMessage: "Join start and end points of curve"
          )
      );
      if(mode == EditingMode.Line){
        modeSpecificOptions.add(
          getActionButton(
              context,
              mode,
              pathsCollection[currentEditingCurveIndex!]["polygonal"],
              widget: const PolygonalLineIcon(widthSize: 28,),
              customOnPressed: (){
                setState(() {
                  pathsCollection[currentEditingCurveIndex!]["polygonal"] = !pathsCollection[currentEditingCurveIndex!]["polygonal"];
                });
              },
              toolTipMessage: "Polygonal line"
          )
        );
      }
      if(mode == EditingMode.QuadraticBezier || mode == EditingMode.CubicBezier){
        modeSpecificOptions.add(
            getActionButton(
                context,
                mode,
                pathsCollection[currentEditingCurveIndex!]["chained"],
                widget: const ChainBezierIcon(widthSize: 28,),
                customOnPressed: (){
                  setState(() {
                    pathsCollection[currentEditingCurveIndex!]["chained"] = !pathsCollection[currentEditingCurveIndex!]["chained"];
                  });
                },
                toolTipMessage: "Chain Bezier curves"
            )
        );
      }
    }
    if(mode == EditingMode.FreeDraw){
      modeSpecificOptions.addAll([
        getActionButton(context, EditingMode.FreeDraw, readyToTransform && transformation == TransformCurve.Translate, customOnPressed: (){
          setState(() {
            readyToTransform = !readyToTransform;
            if(readyToTransform){
              transformation = TransformCurve.Translate;
            } else {
              transformation = TransformCurve.None;
            }
          });
        }, widget: const ReadyToShiftIcon(widthSize: 28,), toolTipMessage: "Toggle shift free draw" ),
        getActionButton(context, EditingMode.FreeDraw, false, customOnPressed: (){
          actionStack.add(
              {
                DrawAction.transformFreeDraw: {
                  "editing_curve_index": currentEditingCurveIndex,
                  "free_draw_spline": Path.from(pathsCollection[currentEditingCurveIndex!]["free_draw_spline"].splinePath),
                  "control_points": List<Offset>.from(pathsCollection[currentEditingCurveIndex!]["free_draw_spline"].points),
                }
              });
          setState(() {
            pathsCollection[currentEditingCurveIndex!]["free_draw_spline"].smoothen();
          });
        }, widget: const SmoothenIcon(widthSize: 28), toolTipMessage:  "Smoothen free draw curve"),
        getActionButton(context, EditingMode.FreeDraw, false, customOnPressed: (){
          actionStack.add(
              {
                DrawAction.transformFreeDraw: {
                  "editing_curve_index": currentEditingCurveIndex,
                  "free_draw_spline": Path.from(pathsCollection[currentEditingCurveIndex!]["free_draw_spline"].splinePath),
                  "control_points": List<Offset>.from(pathsCollection[currentEditingCurveIndex!]["free_draw_spline"].points),
                }
              });
          setState(() {
            pathsCollection[currentEditingCurveIndex!]["free_draw_spline"].irregThicken();
          });
        }, widget: const IrregEnthickenIcon(widthSize: 28), toolTipMessage:  "Thicken free draw curve irregularly"),
        getActionButton(context, EditingMode.FreeDraw, false, customOnPressed: (){
          actionStack.add(
              {
                DrawAction.transformFreeDraw: {
                  "editing_curve_index": currentEditingCurveIndex,
                  "free_draw_spline": Path.from(pathsCollection[currentEditingCurveIndex!]["free_draw_spline"].splinePath),
                  "control_points": List<Offset>.from(pathsCollection[currentEditingCurveIndex!]["free_draw_spline"].points),
                }
              });
          setState(() {
            pathsCollection[currentEditingCurveIndex!]["free_draw_spline"].taper();
          });
        }, widget: const TaperIcon(widthSize: 28), toolTipMessage:  "Taper a thickened free draw curve"),
      ]);
    }
    if(mode == EditingMode.Leaf){
      modeSpecificOptions.addAll([
        getActionButton(context, EditingMode.Leaf, pathsCollection[currentEditingCurveIndex!]["symmetric"], customOnPressed: (){
          actionStack.add(
              {
                DrawAction.changeCurveAttribute: {
                  "editing_curve_index": currentEditingCurveIndex,
                  "curve": Map<String, dynamic>.from(pathsCollection[currentEditingCurveIndex!]),
                  "symmetric": pathsCollection[currentEditingCurveIndex!]["symmetric"],
                }
              });
          setState(() {
            pathsCollection[currentEditingCurveIndex!]["symmetric"] = !pathsCollection[currentEditingCurveIndex!]["symmetric"];
          });
        }, widget: const SymmetryIcon(widthSize: 28), toolTipMessage:  "Toggle symmetric"),
        getActionButton(context, EditingMode.Leaf, pathsCollection[currentEditingCurveIndex!]["orthogonal_symmetric"], customOnPressed: (){
          actionStack.add(
              {
                DrawAction.changeCurveAttribute: {
                  "editing_curve_index": currentEditingCurveIndex,
                  "curve": Map<String, dynamic>.from(pathsCollection[currentEditingCurveIndex!]),
                  "orthogonal_symmetric": pathsCollection[currentEditingCurveIndex!]["orthogonal_symmetric"],
                }
              });
          setState(() {
            pathsCollection[currentEditingCurveIndex!]["orthogonal_symmetric"] = !pathsCollection[currentEditingCurveIndex!]["orthogonal_symmetric"];
          });
        }, widget: const SymmetryIcon2(widthSize: 28), toolTipMessage:  "Toggle orthogonal symmetric"),
      ]);
    }
    return Material(
      elevation: 10.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.0),
      ),
      clipBehavior: Clip.hardEdge,
      child: Container(
          height: 148,
          width: 300,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                GestureDetector(
                  onPanUpdate: (dt){
                    setState((){
                      optionBoxTopPosition += dt.delta.dy;
                      optionBoxLeftPosition += dt.delta.dx;
                    });
                  },
                  child: Material(
                    color: Colors.orange,
                    child: Container(
                      width: 300,
                      height: 20,
                      constraints: const BoxConstraints(
                        minWidth: 200
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text("Mode: ${getModeString(mode)}", style: const TextStyle(fontSize: 16, color: Colors.white)
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal:6),
                  height: 20,
                  child: const Text("General tools", style:  TextStyle(fontSize: 16, color: Colors.black)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal:4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: generalTools(),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal:6),
                  height: 28,
                  child: Text("${getModeString(mode)} tools", style: const TextStyle(fontSize: 16, color: Colors.black)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal:4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    primary: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: modeSpecificOptions,
                    ),
                  ),
                )
              ]
          )
      ),
    );
  }

  Widget colorTab(Rect paletteRect, String colorReceiver){
    return Material(
      elevation: 10.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.0),
      ),
      clipBehavior: Clip.hardEdge,
      child: Container(
          width: 268,
          padding: EdgeInsets.zero,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                GestureDetector(
                  onPanUpdate: (dt){
                    if(colorReceiver == "Stroke"){
                      setState((){
                        strokeColorTabTopPosition += dt.delta.dy;
                        strokeColorTabRightPosition -= dt.delta.dx;
                      });
                    } else if (colorReceiver == "Fill"){
                      setState((){
                        fillColorTabTopPosition += dt.delta.dy;
                        fillColorTabRightPosition -= dt.delta.dx;
                      });
                    }
                  },
                  child: Material(
                    color: Colors.orange,
                    child: Container(
                      width: 268,
                      height: 20,
                      constraints: const BoxConstraints(
                          minWidth: 200
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text("$colorReceiver color", style: const TextStyle(fontSize: 16, color: Colors.white)
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 3.0),
                      width: 262,
                      height: 260,
                      child: GestureDetector(
                        onTapDown:(dt){
                          if(paletteRect.contains(dt.localPosition)){
                            int red, green, blue;
                            switch (colorReceiver == "Stroke" ? strokeAnchorColor : fillAnchorColor) {
                              case AnchorColor.red:
                                red = colorReceiver == "Stroke" ? strokeRedInt : fillRedInt;
                                green = (dt.localPosition.dy - 1) ~/ 1;
                                blue = (dt.localPosition.dx - 1) ~/ 1;
                                break;
                              case AnchorColor.green:
                                green = colorReceiver == "Stroke" ? strokeGreenInt : fillGreenInt;
                                red = (dt.localPosition.dy - 1) ~/ 1;
                                blue = (dt.localPosition.dx - 1) ~/ 1;
                                break;
                              case AnchorColor.blue:
                                blue = colorReceiver == "Stroke" ? strokeBlueInt : fillBlueInt;
                                red = (dt.localPosition.dy - 1) ~/ 1;
                                green = (dt.localPosition.dx - 1) ~/ 1;
                                break;
                              default:
                                if(colorReceiver == "Stroke"){
                                  red = strokeRedInt;
                                  green = strokeGreenInt;
                                  blue = strokeBlueInt;
                                } else {
                                  red = fillRedInt;
                                  green = fillGreenInt;
                                  blue = fillBlueInt;
                                }
                                break;
                            }
                            moveColorPickerCursor(colorReceiver, tapDownDetails: dt);
                            if(colorReceiver == "Stroke"){
                              setState((){
                                strokeRedInt = red;
                                strokeGreenInt = green;
                                strokeBlueInt = blue;
                                strokePendingColor = Color.fromARGB(strokeAlphaInt, strokeRedInt, strokeGreenInt, strokeBlueInt);
                              });
                            } else if (colorReceiver == "Fill") {
                              setState(() {
                                fillRedInt = red;
                                fillGreenInt = green;
                                fillBlueInt = blue;
                                fillPendingColor = Color.fromARGB(
                                    fillAlphaInt, fillRedInt, fillGreenInt,
                                    fillBlueInt);
                              });
                            }
                          }
                        },
                        onPanUpdate: (dt){
                          if(paletteRect.contains(dt.localPosition)){
                            int red, green, blue;
                            switch (colorReceiver == "Stroke" ? strokeAnchorColor : fillAnchorColor) {
                              case AnchorColor.red:
                                red = colorReceiver == "Stroke" ? strokeRedInt : fillRedInt;
                                green = (dt.localPosition.dy - 1) ~/ 1;
                                blue = (dt.localPosition.dx - 1) ~/ 1;
                                break;
                              case AnchorColor.green:
                                green = colorReceiver == "Stroke" ? strokeGreenInt : fillGreenInt;
                                red = (dt.localPosition.dy - 1) ~/ 1;
                                blue = (dt.localPosition.dx - 1) ~/ 1;
                                break;
                              case AnchorColor.blue:
                                blue = colorReceiver == "Stroke" ? strokeBlueInt : fillBlueInt;
                                red = (dt.localPosition.dy - 1) ~/ 1;
                                green = (dt.localPosition.dx - 1) ~/ 1;
                                break;
                              default:
                                red = colorReceiver == "Stroke" ? strokeRedInt : fillRedInt;
                                green = colorReceiver == "Stroke" ? strokeGreenInt : fillGreenInt;
                                blue = colorReceiver == "Stroke" ? strokeBlueInt : fillBlueInt;
                                break;
                            }
                            moveColorPickerCursor(colorReceiver, dragDetails: dt);
                            if(colorReceiver == "Stroke"){
                              setState((){
                                strokeRedInt = red;
                                strokeGreenInt = green;
                                strokeBlueInt = blue;
                                strokePendingColor = Color.fromARGB(strokeAlphaInt, strokeRedInt, strokeGreenInt, strokeBlueInt);
                              });
                            } else if (colorReceiver == "Fill"){
                              setState((){
                                fillRedInt = red;
                                fillGreenInt = green;
                                fillBlueInt = blue;
                                fillPendingColor = Color.fromARGB(fillAlphaInt, fillRedInt, fillGreenInt, fillBlueInt);
                              });
                            }
                          }
                        },
                        child: CustomPaint(
                          child: colorReceiver == "Stroke" ? ThreeDimColorPalette(256, 256, strokeAnchorColor, strokeAnchorColorValue, 255) : ThreeDimColorPalette(256, 256, fillAnchorColor, fillAnchorColorValue, 255),
                          foregroundPainter: FastDraw(
                            drawer: (Canvas canvas, Size size){
                              canvas.clipRect(Offset.zero & size);
                              Path cursor = Path();
                              if(colorReceiver == "Stroke"){
                                cursor.addRect(Rect.fromCenter(center: strokeColorPickerCursor - Offset(0, _controlPointSize), width: _controlPointSize / 2, height: _controlPointSize));
                                cursor.addRect(Rect.fromCenter(center: strokeColorPickerCursor + Offset(0, _controlPointSize), width: _controlPointSize / 2, height: _controlPointSize));
                                cursor.addRect(Rect.fromCenter(center: strokeColorPickerCursor - Offset(_controlPointSize, 0), width: _controlPointSize, height: _controlPointSize / 2));
                                cursor.addRect(Rect.fromCenter(center: strokeColorPickerCursor + Offset(_controlPointSize, 0), width: _controlPointSize, height: _controlPointSize / 2));
                              } else if (colorReceiver == "Fill"){
                                cursor.addRect(Rect.fromCenter(center: fillColorPickerCursor - Offset(0, _controlPointSize), width: _controlPointSize / 2, height: _controlPointSize));
                                cursor.addRect(Rect.fromCenter(center: fillColorPickerCursor + Offset(0, _controlPointSize), width: _controlPointSize / 2, height: _controlPointSize));
                                cursor.addRect(Rect.fromCenter(center: fillColorPickerCursor - Offset(_controlPointSize, 0), width: _controlPointSize, height: _controlPointSize / 2));
                                cursor.addRect(Rect.fromCenter(center: fillColorPickerCursor + Offset(_controlPointSize, 0), width: _controlPointSize, height: _controlPointSize / 2));
                              }
                              canvas.drawPath(cursor, fillPaint);
                            },
                            shouldRedraw: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical:3.0),
                    width: 262,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Radio(value: AnchorColor.red, groupValue: colorReceiver == "Stroke" ? strokeAnchorColor : fillAnchorColor, onChanged: (AnchorColor? val){
                                    if(colorReceiver == "Stroke"){
                                      setState((){
                                        strokeAnchorColor = val ?? strokeAnchorColor;
                                        strokeAnchorColorValue = strokeAnchorColor == AnchorColor.red ? strokeRedInt : (strokeAnchorColor == AnchorColor.green ? strokeGreenInt : strokeBlueInt);
                                      });
                                    } else if (colorReceiver == "Fill"){
                                      setState((){
                                        fillAnchorColor = val ?? fillAnchorColor;
                                        fillAnchorColorValue = fillAnchorColor == AnchorColor.red ? fillRedInt : (fillAnchorColor == AnchorColor.green ? fillGreenInt : fillBlueInt);
                                      });
                                    }
                                  }),
                                  Container(
                                      padding: const EdgeInsets.symmetric(horizontal:8),
                                      width: 60,
                                      child: const Text("Red: ")
                                  ),
                                  Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      width: 42,
                                      child: colorReceiver == "Stroke" ? Text("$strokeRedInt",) : Text("$fillRedInt",)
                                  ),
                                  PlusMinusButton(
                                    incrementCall: (dt){
                                      if(colorReceiver == "Stroke" && strokeRedInt < 255){setState((){strokeRedInt++;});}
                                      if(colorReceiver == "Fill" && fillRedInt < 255){setState((){fillRedInt++;});}
                                    },
                                    longIncrementCall:(){
                                      startChangeColorValues(AnchorColor.red, true, colorReceiver);
                                    },
                                    longIncrementCallEnd:(){setState((){colorChangeTimer.cancel();});},
                                    decrementCall: (dt){
                                      if(colorReceiver == "Stroke" && strokeRedInt > 0){setState((){strokeRedInt--;});}
                                      if(colorReceiver == "Fill" && fillRedInt > 0){setState((){fillRedInt--;});}
                                    },
                                    longDecrementCall:(){
                                      startChangeColorValues(AnchorColor.red, false, colorReceiver);
                                    },
                                    longDecrementCallEnd:(){setState((){colorChangeTimer.cancel();});},
                                  ),
                                ]
                            ),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Radio(value: AnchorColor.green, groupValue: colorReceiver == "Stroke" ? strokeAnchorColor : fillAnchorColor, onChanged: (AnchorColor? val){
                                    if(colorReceiver == "Stroke"){
                                      setState((){
                                        strokeAnchorColor = val ?? strokeAnchorColor;
                                        strokeAnchorColorValue = strokeAnchorColor == AnchorColor.red ? strokeRedInt : (strokeAnchorColor == AnchorColor.green ? strokeGreenInt : strokeBlueInt);
                                      });
                                    } else if (colorReceiver == "Fill"){
                                      setState((){
                                        fillAnchorColor = val ?? fillAnchorColor;
                                        fillAnchorColorValue = fillAnchorColor == AnchorColor.red ? fillRedInt : (fillAnchorColor == AnchorColor.green ? fillGreenInt : fillBlueInt);
                                      });
                                    }
                                  }),
                                  Container(
                                      padding: const EdgeInsets.symmetric(horizontal:8),
                                      width: 60,
                                      child: const Text("Green: ")
                                  ),
                                  Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      width: 42,
                                      child: colorReceiver == "Stroke" ? Text("$strokeGreenInt",) : Text("$fillGreenInt",)
                                  ),
                                  PlusMinusButton(
                                    incrementCall: (dt){
                                      if(colorReceiver == "Stroke" && strokeGreenInt < 255){setState((){strokeGreenInt++;});}
                                      if(colorReceiver == "Fill" && fillGreenInt < 255){setState((){fillGreenInt++;});}
                                    },
                                    longIncrementCall:(){
                                      startChangeColorValues(AnchorColor.green, true, colorReceiver);
                                    },
                                    longIncrementCallEnd:(){setState((){colorChangeTimer.cancel();});},
                                    decrementCall: (dt){
                                      if(colorReceiver == "Stroke" && strokeGreenInt > 0){setState((){strokeGreenInt--;});}
                                      if(colorReceiver == "Fill" && fillGreenInt > 0){setState((){fillGreenInt--;});}
                                    },
                                    longDecrementCall:(){
                                      startChangeColorValues(AnchorColor.green, false, colorReceiver);
                                    },
                                    longDecrementCallEnd:(){setState((){colorChangeTimer.cancel();});},
                                  ),
                                ]
                            ),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Radio(value: AnchorColor.blue, groupValue: colorReceiver == "Stroke" ? strokeAnchorColor : fillAnchorColor, onChanged: (AnchorColor? val){
                                    if(colorReceiver == "Stroke"){
                                      setState((){
                                        strokeAnchorColor = val ?? strokeAnchorColor;
                                        strokeAnchorColorValue = strokeAnchorColor == AnchorColor.red ? strokeRedInt : (strokeAnchorColor == AnchorColor.green ? strokeGreenInt : strokeBlueInt);
                                      });
                                    } else if (colorReceiver == "Fill"){
                                      setState((){
                                        fillAnchorColor = val ?? fillAnchorColor;
                                        fillAnchorColorValue = fillAnchorColor == AnchorColor.red ? fillRedInt : (fillAnchorColor == AnchorColor.green ? fillGreenInt : fillBlueInt);
                                      });
                                    }
                                  }),
                                  Container(
                                      padding: const EdgeInsets.symmetric(horizontal:8),
                                      width: 60,
                                      child: const Text("Blue: ")
                                  ),
                                  Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      width: 42,
                                      child: colorReceiver == "Stroke" ? Text("$strokeBlueInt",) : Text("$fillBlueInt",)
                                  ),
                                  PlusMinusButton(
                                    incrementCall: (dt){
                                      if(colorReceiver == "Stroke" && strokeBlueInt < 255){setState((){strokeBlueInt++;});}
                                      if(colorReceiver == "Fill" && fillBlueInt < 255){setState((){fillBlueInt++;});}
                                    },
                                    longIncrementCall:(){
                                      startChangeColorValues(AnchorColor.blue, true, colorReceiver);
                                    },
                                    longIncrementCallEnd:(){setState((){colorChangeTimer.cancel();});},
                                    decrementCall: (dt){
                                      if(colorReceiver == "Stroke" && strokeBlueInt > 0){setState((){strokeBlueInt--;});}
                                      if(colorReceiver == "Fill" && fillBlueInt > 0){setState((){fillBlueInt--;});}
                                    },
                                    longDecrementCall:(){
                                      startChangeColorValues(AnchorColor.blue, false, colorReceiver);
                                    },
                                    longDecrementCallEnd:(){setState((){colorChangeTimer.cancel();});},
                                  ),
                                ]
                            ),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                      width:32,
                                      height:30
                                  ),
                                  Container(
                                      padding: const EdgeInsets.symmetric(horizontal:8),
                                      width: 60,
                                      child: const Text("Alpha: ")
                                  ),
                                  Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      width: 42,
                                      child: colorReceiver == "Stroke" ? Text("$strokeAlphaInt",) : Text("$fillAlphaInt",)
                                  ),
                                  PlusMinusButton(
                                    incrementCall: (dt){
                                      if(colorReceiver == "Stroke" && strokeAlphaInt < 255){setState((){strokeAlphaInt++;});}
                                      if(colorReceiver == "Fill" && fillAlphaInt < 255){setState((){fillAlphaInt++;});}
                                    },
                                    longIncrementCall:(){
                                      startChangeColorValues(AnchorColor.alpha, true, colorReceiver);
                                    },
                                    longIncrementCallEnd:(){setState((){colorChangeTimer.cancel();});},
                                    decrementCall: (dt){
                                      if(colorReceiver == "Stroke" && strokeAlphaInt > 0){setState((){strokeAlphaInt--;});}
                                      if(colorReceiver == "Fill" && fillAlphaInt > 0){setState((){fillAlphaInt--;});}
                                    },
                                    longDecrementCall:(){
                                      startChangeColorValues(AnchorColor.alpha, false, colorReceiver);
                                    },
                                    longDecrementCallEnd:(){setState((){colorChangeTimer.cancel();});},
                                  ),
                                ]
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            SizedBox(
                                width: 50,
                                height: 50,
                                child: Material(
                                    shape: const CircleBorder(),
                                    color: colorReceiver == "Stroke" ? strokePendingColor : fillPendingColor,
                                )
                            ),
                            Container(
                                height: 32,
                                margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                                child: MaterialButton(
                                    onPressed:(){
                                      if(colorReceiver == "Stroke"){
                                        if(actionStack.isEmpty || !(actionStack.last).containsKey(DrawAction.changePaintColor)){
                                          actionStack.add({
                                            DrawAction.changePaintColor: {
                                              "original_paint_color": currentStrokeColor.color,
                                              "editing_curve_index": currentEditingCurveIndex,
                                            }
                                          });
                                          if(currentEditingCurveIndex != null){
                                            actionStack.last[DrawAction.changePaintColor]["original_curve_paint_color"] = pathsCollection[currentEditingCurveIndex!]["stroke"].color;
                                          }
                                        }
                                        setState((){
                                          currentStrokeColor.color = strokePendingColor;
                                          if(currentEditingCurveIndex != null){
                                            pathsCollection[currentEditingCurveIndex!]["stroke"].color = strokePendingColor;
                                          }
                                          showColorSelector = false;
                                          colorReceiver = "";
                                        });
                                      } else if (colorReceiver == "Fill"){
                                        actionStack.add({
                                          DrawAction.changeFillColor: {
                                            "original_fill_color": currentFillColor.color,
                                            "editing_curve_index": currentEditingCurveIndex,
                                          }
                                        });
                                        if(currentEditingCurveIndex != null){
                                          actionStack.last[DrawAction.changeFillColor]["original_curve_fill_color"] = pathsCollection[currentEditingCurveIndex!]["fill"].color;
                                          actionStack.last[DrawAction.changeFillColor]["original_filled_attribute"] = pathsCollection[currentEditingCurveIndex!]["filled"];
                                        }
                                        setState((){
                                          currentFillColor.color = fillPendingColor;
                                          if(currentEditingCurveIndex != null){
                                            pathsCollection[currentEditingCurveIndex!]["fill"].color = strokePendingColor;
                                            pathsCollection[currentEditingCurveIndex!]["filled"] = true;
                                          }
                                          showColorSelector = false;
                                        });
                                      }
                                    },
                                    color: Colors.black,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6.0)
                                    ),
                                    elevation: 10.0,
                                    padding: EdgeInsets.zero,
                                    child: const Text("Pick color", style: TextStyle(fontSize:16, color: Colors.white))
                                )
                            ),
                          ],
                        )
                      ],
                    )
                ),
              ]
          )
      ),
    );
  }

  Map<String, int>? resolveControlPointDetection(Offset tapLocation){
    Rect tapLocationRect = Rect.fromCenter(center: tapLocation, width: _tapSensitivityDistance, height: _tapSensitivityDistance);
    if (pathsCollection[currentEditingCurveIndex!]["control_points"].isNotEmpty){
      for(int index = 0; index < pathsCollection[currentEditingCurveIndex!]["control_points"].length; index++){
        if(tapLocationRect.contains(pathsCollection[currentEditingCurveIndex!]["control_points"][index] * zoomFactor + panOffset)){
          if(currentMode == EditingMode.GroupCurve){
            Map<String, dynamic> result = Map<String, dynamic>.from(pathsCollection[currentEditingCurveIndex!]["curve_finder_function"](cpIndex: index));
            indexOfGroupedControlPointFrom = result["from"];
            indexOfGroupedControlPointTo = result["to"];
            indexOfGroupedRestrictedControlPointFrom = result["restricted_from"];
            indexOfGroupedRestrictedControlPointTo = result["restricted_to"];
            indexOfGroupedDataControlPointFrom = result["data_from"];
            indexOfGroupedDataControlPointTo = result["data_to"];
            selectedGroupedCurve = result["curve"];
          }
          return {"control_point": index};
        }
      }
    }
    if(pathsCollection[currentEditingCurveIndex!]["restricted_control_points"].isNotEmpty){
      for(int index = 0; index < pathsCollection[currentEditingCurveIndex!]["restricted_control_points"].length; index++){
        if(tapLocationRect.contains(pathsCollection[currentEditingCurveIndex!]["restricted_control_points"][index] * zoomFactor + panOffset)){
          if(currentMode == EditingMode.GroupCurve){
            Map<String, dynamic> result = Map<String, dynamic>.from(pathsCollection[currentEditingCurveIndex!]["curve_finder_function"](rcpIndex: index));
            indexOfGroupedControlPointFrom = result["from"];
            indexOfGroupedControlPointTo = result["to"];
            indexOfGroupedRestrictedControlPointFrom = result["restricted_from"];
            indexOfGroupedRestrictedControlPointTo = result["restricted_to"];
            indexOfGroupedDataControlPointFrom = result["data_from"];
            indexOfGroupedDataControlPointTo = result["data_to"];
            selectedGroupedCurve = result["curve"];
          }
          return {
            "restricted_control_point": index,
          };
        }
      }
    }
    if(pathsCollection[currentEditingCurveIndex!]["data_control_points"].isNotEmpty){
      for(int index = 0; index < pathsCollection[currentEditingCurveIndex!]["data_control_points"].length; index++){
        if(tapLocationRect.contains(pathsCollection[currentEditingCurveIndex!]["data_control_points"][index] * zoomFactor + panOffset)){
          if(currentMode == EditingMode.GroupCurve){
            Map<String, dynamic> result = Map<String, dynamic>.from(pathsCollection[currentEditingCurveIndex!]["curve_finder_function"](rcpIndex: index));
            indexOfGroupedControlPointFrom = result["from"];
            indexOfGroupedControlPointTo = result["to"];
            indexOfGroupedRestrictedControlPointFrom = result["restricted_from"];
            indexOfGroupedRestrictedControlPointTo = result["restricted_to"];
            indexOfGroupedDataControlPointFrom = result["data_from"];
            indexOfGroupedDataControlPointTo = result["data_to"];
            selectedGroupedCurve = result["curve"];
          }
          return {
            "data_control_point": index,
          };
        }
      }
    }
    if(rotationControlPoint != null && tapLocationRect.contains(rotationControlPoint! + Offset(_controlPointSize, -_controlPointSize))){
      return {"rotation_control_point": 0};
    } else if(horizontalScaleControlPoint != null && tapLocationRect.contains(horizontalScaleControlPoint! + Offset(_controlPointSize, 0))){
      return {"horizontal_scale_control_point": 0};
    } else if(verticalScaleControlPoint != null && tapLocationRect.contains(verticalScaleControlPoint! + Offset(0, _controlPointSize))){
      return {"vertical_scale_control_point": 0};
    } else if(scaleControlPoint != null && tapLocationRect.contains(scaleControlPoint! + Offset(_controlPointSize, _controlPointSize))){
      return {"scale_control_point": 0};
    }
  }

  Map<int, EditingMode>? resolvePathDetection(Offset tapLocation){
    for(int i = 0; i < pathsCollection.length; i++){
      if(pathsCollection[i]["bounding_rect"].contains(tapLocation)){
        return {i: pathsCollection[i]["mode"]};
      }
    }
    return null;
  }

  List<Map<int, EditingMode>> resolvePathsInSelectionRect(Rect selectionRect){
    List<Map<int, EditingMode>> selectedPath = [];
    for(int i = 0; i < pathsCollection.length; i++){
      if(selectionRect.contains(pathsCollection[i]["bounding_rect"].center)){
        selectedPath.add({i: pathsCollection[i]["mode"]});
      }
    }
    return selectedPath;
  }

  Paint copyPaint(Paint paint){
    return Paint()
        ..color = paint.color
        ..strokeWidth = paint.strokeWidth
        ..strokeCap = paint.strokeCap
        ..style = paint.style
        ..strokeJoin = StrokeJoin.round
        ..shader = paint.shader;
  }

  void drawGrid(Canvas canvas, Size size, double zoom, Offset offset){
    Paint gridPaint = Paint()
        ..color = Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;
    double x = gridHorizontalGap * zoom + offset.dx;
    double y = gridVerticalGap * zoom + offset.dy;
    double horizontalGap = gridHorizontalGap * zoom;
    double verticalGap = gridVerticalGap * zoom;
    size = size * zoom;
    do {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      x += horizontalGap;
    } while (x < size.width - (2.0 * zoom));
    do {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      y += verticalGap;
    } while (y < size.height);
  }

  void drawInactivePaths(Canvas canvas, Size size, List<Map<String, dynamic>> collection, int? index){
    bool toTransform, toDraw;
    for(int i = 0; i < collection.length; i++){
      if(i != index){
        EditingMode thisMode = collection[i]["mode"];
        Path path = Path();
        Paint pathPaint = collection[i]["stroke"];
        Paint pathFill = collection[i]["fill"];
        toDraw = true;
        toTransform = true;
        if(isPathMode(thisMode)){
          switch(thisMode){
            case EditingMode.Line:
              if(collection[i]["control_points"].length >= 2){
                path.addPath(getLinePath(collection[i]["control_points"], close: collection[i]["close"]), Offset.zero);
              }
              break;
            case EditingMode.Arc:
              if(collection[i]["control_points"].length == 1){
                path.addPath(getArcPath(
                    collection[i]["control_points"],
                    collection[i]["restricted_control_points"],
                    collection[i]["width"],
                    collection[i]["height"],
                    close: collection[i]["close"],
                ), Offset.zero);
              }
              break;
            case EditingMode.SplineCurve:
              if(collection[i]["control_points"].length >= 4){
                path.addPath(getCMRPath(
                  collection[i]["control_points"],
                  close: collection[i]["close"],
                ), Offset.zero);
              }
              break;
            case EditingMode.QuadraticBezier:
              if(collection[i]["control_points"].length >= 3){
                path.addPath(getQuadraticBezierPath(
                  collection[i]["control_points"],
                  close: collection[i]["close"],
                ), Offset.zero);
              }
              break;
            case EditingMode.CubicBezier:
              if(collection[i]["control_points"].length >= 4){
                path.addPath(getCubicBezierPath(
                  collection[i]["control_points"],
                  close: collection[i]["close"],
                ), Offset.zero);
              }
              break;
            case EditingMode.Triangle:
              if(collection[i]["control_points"].length == 3){
                path.addPath(getPolygonPath(collection[i]["control_points"]), Offset.zero);
              }
              break;
            case EditingMode.Rectangle:
              if(collection[i]["control_points"].length == 4){
                path.addPath(getPolygonPath(collection[i]["control_points"]), Offset.zero);
              }
              break;
            case EditingMode.Pentagon:
              if(collection[i]["control_points"].length == 5){
                path.addPath(getPolygonPath(collection[i]["control_points"]), Offset.zero);
              }
              break;
            case EditingMode.Polygon:
              if(collection[i]["control_points"].length >= 3){
                path.addPath(getPolygonPath(collection[i]["control_points"]), Offset.zero);
              }
              break;
            case EditingMode.Conic:
              if(collection[i]["control_points"].length >= 1){
                path.addPath(getConicPath(collection[i]["control_points"], collection[i]["width"], collection[i]["height"], collection[i]["restricted_control_points"][0]), Offset.zero);
              }
              break;
            case EditingMode.Leaf:
              if(collection[i]["control_points"].length >= 3){
                path.addPath(getLeafPath(collection[i]["control_points"], symmetric: collection[i]["symmetric"], orthSymmetric: collection[i]["orthogonal_symmetric"]), Offset.zero);
              }
              break;
            case EditingMode.Star:
              if(collection[i]["control_points"].length == 2){
                Offset point1 = collection[i]["control_points"][0];
                Offset point2 = collection[i]["control_points"][1];
                path.addPath(getStarPath([point1, point2]), Offset.zero);
              }
              break;
            case EditingMode.Heart:
              if(collection[i]["control_points"].length == 3){
                Offset point1 = collection[i]["control_points"][0];
                Offset point2 = collection[i]["control_points"][1];
                Offset point3 = collection[i]["control_points"][2];
                path.addPath(getHeartShapePath([point1, point2, point3]), Offset.zero);
              }
              break;
            case EditingMode.Arrow:
              if(collection[i]["control_points"].length == 2){
                path.addPath(getArrowShapePath(collection[i]["control_points"], collection[i]["restricted_control_points"], collection[i]["directional_gap"], collection[i]["orthogonal_gap"]), Offset.zero);
              }
              break;
            case EditingMode.FreeDraw:
              path.addPath(collection[i]["free_draw_spline"].splinePath, Offset.zero);
              break;
            case EditingMode.DirectedLine:
              if(collection[i]["control_points"].length == 2){
                path.addPath(getDirectedLinePath(collection[i]["control_points"]), Offset.zero);
                canvas.drawPath(getEndArrow(collection[i]["control_points"]).transform(scaleThenTranslateMatrix), collection[i]["fill"]);
              }
              break;
            case EditingMode.CurveDirectedLine:
              if(collection[i]["control_points"].length == 2){
                path.addPath(getCurveDirectedLinePath(collection[i]["control_points"]), Offset.zero);
                canvas.drawPath(getEndArrow(collection[i]["control_points"]).transform(scaleThenTranslateMatrix), collection[i]["fill"]);
              }
              break;
            case EditingMode.GroupCurve:
              List<Map<String, dynamic>> curves = collection[i]["curves"];
              List<Offset> controlPoints = collection[i]["control_points"];
              int sum = 0;
              for(Map<String, dynamic> c in curves){
                int len = int.parse((sum + c["control_points"].length).toString());
                path.addPath(drawActivePath(canvas, c, cp: controlPoints.sublist(sum, len), drawControlPoints: false), Offset.zero);
                sum = len;
              }
              toTransform = false;
              toDraw = false;
              break;
            default:
              print("Unimplemented path painter while drawing inactive paths");
              break;
          }
          if(toTransform){
            path = path.transform(scaleThenTranslateMatrix);
          }
          if(toDraw){
            if(collection[i]["outlined"]){
              canvas.drawPath(path, pathPaint);
            }
            if(isLineOrCurve(thisMode)){
              if(collection[i]["filled"] && collection[i]["close"]){
                canvas.drawPath(path, pathFill);
              }
            } else {
              if(collection[i]["filled"]){
                canvas.drawPath(path, pathFill);
              }
            }
          }
        } else if (thisMode == EditingMode.Image){
          canvas.drawImage(currentImage!, Offset.zero, Paint());
        } else if (thisMode == EditingMode.Fill){
          print("Unimplemented fill painter while drawing inactive paths");
        } else {
          print("Unimplemented unknown object painting while drawing inactive paths. $thisMode");
        }
      }
    }
  }

  void curvePanDown(Size canvasSize, DragDownDetails dt){
    if(ctrlKeyPressed && !(currentMode == EditingMode.None || currentMode == EditingMode.FreeDraw)){
      setState(() {
        pendingOffset = dt.localPosition;
      });
      return;
    }
    Map<String, int>? nearestControlPoint = currentEditingCurveIndex != null ? resolveControlPointDetection(dt.localPosition) : null;
    if(nearestControlPoint != null){
      if(currentMode == EditingMode.FreeDraw){
        actionStack.add(
            {
              DrawAction.transformFreeDraw: {
                "free_draw_spline": Path.from(pathsCollection[currentEditingCurveIndex!]["free_draw_spline"].splinePath),
                "control_points": List<Offset>.from(pathsCollection[currentEditingCurveIndex!]["free_draw_spline"].points),
                "editing_curve_index": currentEditingCurveIndex,
              }
              // Free draw curves has no restricted control points (yet)
            });
      } else {
        actionStack.add(
            {
              DrawAction.transformControlPoints: {
                "control_points": List<Offset>.from(pathsCollection[currentEditingCurveIndex!]["control_points"]),
                "restricted_control_points": List<Offset>.from(pathsCollection[currentEditingCurveIndex!]["restricted_control_points"]),
                "data_control_points": List<Offset>.from(pathsCollection[currentEditingCurveIndex!]["data_control_points"]),
                "editing_curve_index": currentEditingCurveIndex,
              }
            });
      }
      if(nearestControlPoint.containsKey("control_point")){
        if(indexOfSelectedControlPoint != nearestControlPoint["control_point"]){
          readyToTransform = true;
          transformation = TransformCurve.moveControlPoint;
          setState(() {
            indexOfSelectedControlPoint = nearestControlPoint["control_point"];
          });
        }
      } else if (nearestControlPoint.containsKey("restricted_control_point")){
        if(indexOfSelectedRestrictedControlPoint != nearestControlPoint["restricted_control_point"]){
          readyToTransform = true;
          transformation = TransformCurve.moveRestrictedControlPoint;
          setState(() {
            indexOfSelectedRestrictedControlPoint = nearestControlPoint["restricted_control_point"];
          });
        }
      } else if (nearestControlPoint.containsKey("data_control_point")){
        if(indexOfSelectedRestrictedControlPoint != nearestControlPoint["data_control_point"]){
          readyToTransform = true;
          transformation = TransformCurve.moveDataControlPoint;
          setState(() {
            indexOfSelectedDataControlPoint = nearestControlPoint["data_control_point"];
          });
        }
      } else if(nearestControlPoint.containsKey("rotation_control_point")){
        readyToTransform = true;
        indexOfSelectedControlPoint = null;
        indexOfSelectedRestrictedControlPoint = null;
        indexOfSelectedDataControlPoint = null;
        transformation = TransformCurve.Rotate;
        transformationReferenceOffset = boundingRect!.center;
        panReference = (dt.localPosition - boundingRect!.center).direction;
      } else if (nearestControlPoint.containsKey("horizontal_scale_control_point")){
        readyToTransform = true;
        indexOfSelectedControlPoint = null;
        indexOfSelectedRestrictedControlPoint = null;
        indexOfSelectedDataControlPoint = null;
        transformation = TransformCurve.ScaleHorizontal;
        transformationReferenceOffset = boundingRect!.centerLeft ;
        panReference = boundingRect!.width;
      } else if (nearestControlPoint.containsKey("vertical_scale_control_point")){
        readyToTransform = true;
        indexOfSelectedControlPoint = null;
        indexOfSelectedRestrictedControlPoint = null;
        indexOfSelectedDataControlPoint = null;
        transformation = TransformCurve.ScaleVertical;
        transformationReferenceOffset = boundingRect!.topCenter ;
        panReference = boundingRect!.height;
      } else if (nearestControlPoint.containsKey("scale_control_point")){
        readyToTransform = true;
        indexOfSelectedControlPoint = null;
        indexOfSelectedRestrictedControlPoint = null;
        indexOfSelectedDataControlPoint = null;
        transformation = TransformCurve.Scale;
        transformationReferenceOffset = boundingRect!.topLeft ;
        panReference = boundingRect!.width;
        panSecondReference = boundingRect!.height;
      } else {
        // Unimplemented case;
      }
    } else {
      indexOfSelectedDataControlPoint = null;
      indexOfSelectedRestrictedControlPoint = null;
      indexOfSelectedControlPoint = null;
      if(currentMode == EditingMode.FreeDraw){
        if(readyToTransform){
          if(boundingRect != null && boundingRect!.contains(dt.localPosition)){
            transformation = TransformCurve.Translate;
            actionStack.add(
                {
                  DrawAction.transformFreeDraw: {
                    "free_draw_spline": Path.from(pathsCollection[currentEditingCurveIndex!]["free_draw_spline"].splinePath),
                    "control_points": List<Offset>.from(pathsCollection[currentEditingCurveIndex!]["free_draw_spline"].points),
                    "editing_curve_index": currentEditingCurveIndex,
                  }
                  // Free draw curves has no restricted control points (yet)
                });
          }
        } else if(pathsCollection[currentEditingCurveIndex!]["free_draw_spline"].isNotEmpty){
          setState(() {
            pathsCollection.add({
              "mode": EditingMode.FreeDraw,
              "free_draw_spline": SplinePath([]),
              "control_points": <Offset>[],
              "restricted_control_points": <Offset>[],
              "data_control_points": <Offset>[],
              "outlined": true,
              "stroke": copyPaint(currentStrokeColor),
              "filled": false,
              "fill": copyPaint(currentFillColor),
              "draw_end": false,
              "close": false,
              "bounding_rect": Rect.zero,
            });
            pathsCollection.last["free_draw_spline"].addSingleStartPoint((dt.localPosition - panOffset) / zoomFactor);
            currentEditingCurveIndex = pathsCollection.length - 1;
          });
          actionStack.add({
            DrawAction.addFreeDraw: {
              "editing_curve_index": currentEditingCurveIndex
            }
          });
        } else {
          setState((){
            // activePath.reset();
            pathsCollection[currentEditingCurveIndex!]["free_draw_spline"].addSingleStartPoint((dt.localPosition - panOffset) / zoomFactor);
          });
        }
        return;
      } else if (boundingRect != null && boundingRect!.contains(dt.localPosition) && groupSelection.isEmpty){
        readyToTransform = true;
        transformation = TransformCurve.Translate;
        actionStack.add(
            {
              DrawAction.transformControlPoints: {
                "control_points": List<Offset>.from(pathsCollection[currentEditingCurveIndex!]["control_points"]),
                "restricted_control_points": List<Offset>.from(pathsCollection[currentEditingCurveIndex!]["restricted_control_points"]),
                "editing_curve_index": currentEditingCurveIndex,
              }
            });
        return;
      } else {
        // Unimplemented case;
      }
      Map<int, EditingMode>? pathDetected = resolvePathDetection(dt.localPosition);
      if(pathDetected != null){
        activatePath(pathDetected.keys.first, pathDetected.values.first);
      } else {
        deactivateCurrentActivePath();
        setState(() {
          pendingOffset = dt.localPosition;
        });
      }
    }
  }

  void curvePanUpdate(Size canvasSize, DragUpdateDetails dt) {
    if(ctrlKeyPressed && !(currentMode == EditingMode.None || currentMode == EditingMode.FreeDraw)) {
      setState(() {
        pendingOffset = dt.localPosition;
      });
      return;
    } else if (readyToTransform) {
      assert(currentEditingCurveIndex != null && currentMode != EditingMode.None, "When ready to transform, there must be a currently active curve");
      Map<String, dynamic> transformedPath;
      Map<String, dynamic> args = updateTransformationReferences(dt.localPosition, dt.delta);
      if(transformation != TransformCurve.moveControlPoint && transformation != TransformCurve.moveRestrictedControlPoint && transformation != TransformCurve.moveDataControlPoint){
        transformedPath = transformPath(pathsCollection[currentEditingCurveIndex!], args);
      } else if (transformation == TransformCurve.moveControlPoint){
        transformedPath = moveControlPoint(dt.localPosition, dt.delta, pathsCollection[currentEditingCurveIndex!], args);
      } else if (transformation == TransformCurve.moveDataControlPoint){
        transformedPath = moveDataControlPoint(dt.localPosition, dt.delta, pathsCollection[currentEditingCurveIndex!]);
      } else {
        transformedPath = moveRestrictedControlPoint(dt.localPosition, dt.delta, pathsCollection[currentEditingCurveIndex!], args: args);
      }
      setState((){
        pathsCollection[currentEditingCurveIndex!] = transformedPath;
      });
    } else if (currentMode == EditingMode.FreeDraw && !pathsCollection[currentEditingCurveIndex!]["draw_end"]){
      setState(() {
        pathsCollection[currentEditingCurveIndex!]["free_draw_spline"].addSinglePoint((dt.localPosition - panOffset) / zoomFactor);
        // activePath.reset();
      });
    } else if (pendingOffset != null){
      setState((){
        selectionOffset = dt.localPosition;
      });
    } else {
      // Unimplemented case;
    }
  }

  void curvePanEnd(Size canvasSize, DragEndDetails dt){
    if(ctrlKeyPressed && !(currentMode == EditingMode.GroupCurve || currentMode == EditingMode.FreeDraw || currentMode == EditingMode.None)){
      if(pendingOffset != null){
        if(validNewPoint(pathsCollection[currentEditingCurveIndex!]["control_points"])){
          actionStack.add({
            DrawAction.addControlPoint : {
              "control_points": List.from(pathsCollection[currentEditingCurveIndex!]["control_points"]),
              "restricted_control_points": List<Offset>.from(pathsCollection[currentEditingCurveIndex!]["restricted_control_points"]),
              "editing_curve_index": currentEditingCurveIndex,
            }
          });
          if(snapToGridNode && gridEnabled){
            Offset gridNode = Offset(((pendingOffset!.dx - panOffset.dx) / gridHorizontalGap / zoomFactor).round() * gridHorizontalGap, ((pendingOffset!.dy - panOffset.dy) / gridVerticalGap / zoomFactor).round() * gridVerticalGap);
            setState(() {
              pathsCollection[currentEditingCurveIndex!]["control_points"].add(gridNode);
              // pathsCollection[currentEditingCurveIndex!]["control_points"] = activePathPoints;
              // activePath.addOval(Rect.fromCenter(center: gridNode, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
              pendingOffset = null;
            });
          } else {
            setState(() {
              pathsCollection[currentEditingCurveIndex!]["control_points"].add((pendingOffset! - panOffset) / zoomFactor);
              // pathsCollection[currentEditingCurveIndex!]["control_points"] = activePathPoints;
              // activePath.addOval(Rect.fromCenter(center: (pendingOffset! - panOffset) / zoomFactor, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
              pendingOffset = null;
            });
          }
        }
      }
    } else if (pendingOffset != null && selectionOffset != null){
      // To implement group selection
      List<Map<int, EditingMode>> indicesOfSelectedPaths = resolvePathsInSelectionRect(Rect.fromPoints(pendingOffset!, selectionOffset ?? pendingOffset!));
      if(indicesOfSelectedPaths.isNotEmpty){
        deactivateCurrentActivePath();
        setState(() {
          for(int i = 0; i < indicesOfSelectedPaths.length; i++){
            activatePath(indicesOfSelectedPaths[i].keys.first, indicesOfSelectedPaths[i].values.first, deactivateCurrentPathFirst: false);
          }
          groupSelection = indicesOfSelectedPaths.map((e) => e.keys.first).toList();
        });
      }
    } else if (readyToTransform && transformation == TransformCurve.moveControlPoint && indexOfSelectedControlPoint != null){
      if(snapToGridNode && gridEnabled){
        Offset gridOffset = Offset((pathsCollection[currentEditingCurveIndex!]["control_points"][indexOfSelectedControlPoint!].dx / gridHorizontalGap).round() * gridHorizontalGap, (pathsCollection[currentEditingCurveIndex!]["control_points"][indexOfSelectedControlPoint!].dy / gridVerticalGap).round() * gridVerticalGap);
        // Use transform to update this control point.
        // Only unrestricted control points may be snapped to grid nodes.
      }
    } else if (currentMode == EditingMode.FreeDraw){
      setState((){
        pathsCollection[currentEditingCurveIndex!]["draw_end"] = true;
      });
    } else if (readyToTransform || panReference != null){
      panReference = null;
      panSecondReference = null;
      transformationReferenceOffset = null;
      readyToTransform = false;
      indexOfSelectedControlPoint = null;
      indexOfSelectedRestrictedControlPoint = null;
      indexOfSelectedDataControlPoint = null;
    } else {
      // Unimplemented case;
    }
    pendingOffset = null;
    selectionOffset = null;
  }

  Map<String, dynamic> updateRCPWhenCPMoved(EditingMode mode, Map<String, dynamic> curve, Offset localPosition, Offset delta, {Map<String, dynamic>? args}){
    // Called when change in control points lead to a need for all restricted control points to be updated
    switch(mode){
      case EditingMode.Arc:
        // Rect rect = Rect.fromCenter(center: curve["control_points"][0], width: curve["width"], height: curve["height"]);
        curve["restricted_control_points"][0] = curve["restricted_control_points"][0] + delta;
        curve["restricted_control_points"][1] = curve["restricted_control_points"][1] + delta;
        curve["restricted_control_points"][2] = curve["restricted_control_points"][2] + delta;;
        curve["data_control_points"][0] = curve["data_control_points"][0] + delta;
        return curve;
      case EditingMode.Conic:
        curve["restricted_control_points"][0] = curve["restricted_control_points"][0] + delta;
        return curve;
      case EditingMode.Arrow:
        double direction = (curve["control_points"][1] - curve["control_points"][0]).direction;
        double normal = direction + pi / 2;
        double dist = (curve["restricted_control_points"][0] - curve["restricted_control_points"][1]).distance;
        Offset lerpPoint = curve["control_points"][0] + Offset.fromDirection(direction, curve["directional_gap"]);
        curve["restricted_control_points"][0] = lerpPoint + Offset.fromDirection(normal, curve["orthogonal_gap"]);
        curve["restricted_control_points"][1] = lerpPoint + Offset.fromDirection(normal, curve["orthogonal_gap"] - dist);
        return curve;
      default:
        // assume no restricted control points
        return curve;
    }
  }

  Offset updateRestrictedControlPoint(EditingMode mode, Map<String, dynamic> curve, Offset localPosition, Offset delta, Offset originalRestriction, {List<Offset>? newControlPoints, Map<String, dynamic>? args}){
    assert(mode != EditingMode.GroupCurve, "updateRestrictedControlPoint updates base curves only");
    switch(mode){
      case EditingMode.Arc:
        Rect rect = Rect.fromCenter(center: curve["control_points"][0], width: curve["width"], height: curve["height"]);
        double direction = (localPosition - curve["control_points"][0]).direction;
        double rotationAdjustedAngle = (curve["restricted_control_points"][2] - rect.center).direction;
        if(args!["restriction_index"] != 2){
          return matrixApply(rotateZAbout(rotationAdjustedAngle, rect.center), getConicOffset(rect, getConicDirection(rect, (localPosition - rect.center).direction - rotationAdjustedAngle)));
        } else {
          curve["restricted_control_points"][0] = matrixApply(rotateZAbout(direction, rect.center), getConicOffset(rect, getConicDirection(rect, (curve["restricted_control_points"][0] - rect.center).direction - rotationAdjustedAngle)));
          curve["restricted_control_points"][1] = matrixApply(rotateZAbout(direction, rect.center), getConicOffset(rect, getConicDirection(rect, (curve["restricted_control_points"][1] - rect.center).direction - rotationAdjustedAngle)));
          return rect.center + Offset.fromDirection(direction, (rect.bottomRight - rect.center).distance);
        }
      case EditingMode.Arrow:
        if(args!["restriction_index"] == 0){
          double direction = (curve["control_points"][1] - curve["control_points"][0]).direction;
          double dist = (curve["restricted_control_points"][1] - curve["restricted_control_points"][0]).distance;
          curve["directional_gap"] = lengthOfProjection(localPosition, direction, curve["control_points"][0]);
          curve["restricted_control_points"][1] = curve["control_points"][0] + Offset.fromDirection(direction, curve["directional_gap"]) + Offset.fromDirection(direction + pi / 2, curve["orthogonal_gap"] - dist);
          return curve["control_points"][0] + Offset.fromDirection(direction, curve["directional_gap"]) + Offset.fromDirection(direction + pi / 2, curve["orthogonal_gap"]);
        } else {
          double direction = (curve["control_points"][1] - curve["control_points"][0]).direction;
          double dist = distanceFromLine(localPosition, direction + pi / 2, curve["restricted_control_points"][0]);
          return curve["control_points"][0] + Offset.fromDirection(direction, curve["directional_gap"]) + Offset.fromDirection(direction + pi / 2, curve["orthogonal_gap"] - dist);
        }
      case EditingMode.GroupCurve:
        throw Exception("Handle transformation of moving restricted or unrestricted control points separately");
      case EditingMode.Conic:
        Rect rect = Rect.fromCenter(center: curve["control_points"][0], width: curve["width"], height: curve["height"]);
        return rect.center + Offset.fromDirection((localPosition - rect.center).direction, (rect.center - rect.bottomRight).distance);
      default:
        // return restrictedOffset itself will mean this point is in fact unrestricted.
        return originalRestriction;
    }
  }

  bool validNewPoint(List<Offset> activePathPoints){
    //Unrestricted control points
    switch(currentMode){
      case EditingMode.SplineCurve:
        return true;
      case EditingMode.QuadraticBezier:
        if(pathsCollection[currentEditingCurveIndex!]["chained"]){
          return true;
        }
        return activePathPoints.length < 3;
      case EditingMode.CubicBezier:
        if(pathsCollection[currentEditingCurveIndex!]["chained"]){
          return true;
        }
        return activePathPoints.length < 4;
      case EditingMode.Line:
        if(pathsCollection[currentEditingCurveIndex!]["polygonal"]){
          return true;
        }
        return activePathPoints.length < 2;
      case EditingMode.Arc:
        return activePathPoints.isEmpty;
      case EditingMode.Triangle:
        return activePathPoints.length < 3;
      case EditingMode.Rectangle:
        return activePathPoints.length < 2;
      case EditingMode.Pentagon:
        return activePathPoints.length < 5;
      case EditingMode.Polygon:
        return true;
      case EditingMode.Conic:
        return activePathPoints.length < 1;
      case EditingMode.Star:
        return activePathPoints.length < 2;
      case EditingMode.Heart:
        return activePathPoints.length < 3;
      case EditingMode.Arrow:
        return activePathPoints.length < 2;
      case EditingMode.DirectedLine:
        return activePathPoints.length < 2;
      case EditingMode.CurveDirectedLine:
        return activePathPoints.length < 2;
      default:
        return true;
    }
  }

  void defaultTapUp(Size canvasSize, TapUpDetails dt){
    print("Default tap up detected. No implementation for this event.");
    return;
  }

  void defaultPanUpdate(Size canvasSize, DragUpdateDetails dt){
    print("Default pan update detected. No implementation for this event.");
    return;
  }

  void defaultPanEnd(Size canvasSize, DragEndDetails dt){
    print("Default pan end detected. No implementation for this event.");
    return;
  }

  void _keyboardCallBack(RawKeyEvent event){
    if(event.physicalKey == PhysicalKeyboardKey.escape){
      deactivateCurrentActivePath();
      closeMenus();
      if(showColorSelector){
        setState(() {
          showColorSelector = false;
        });
      }
      if(showStrokeWidthSelector){
        setState(() {
          showStrokeWidthSelector = false;
        });
      }
      if(showAddCurveMenu){
        setState(() {
          showAddCurveMenu = false;
        });
      }
    }
    if(event.isControlPressed){
      setState(() {
        ctrlKeyPressed = true;
      });
      if(event.character == "z"){
        undoLastAction();
      }
    } else {
      setState(() {
        ctrlKeyPressed = false;
      });
    }
    if(event.isShiftPressed){
      setState(() {
        shiftKeyPressed = true;
      });
    } else {
      setState(() {
        shiftKeyPressed = false;
      });
    }
  }

  Path drawActivePath(Canvas canvas, Map<String, dynamic> curve, {bool toTransform = true, toDraw = true, List<Offset>? cp, List<Offset>? rcp, List<Offset>? dcp, bool drawControlPoints = true}){
    Path path = Path();
    Path restrictedAndUnrestrictedPoints = Path();
    Path dataPoints = Path();
    EditingMode mode = curve["mode"];
    List<Offset> controlPoints = cp ?? curve["control_points"];
    List<Offset> restrictedControlPoints = rcp ?? List<Offset>.from(curve["restricted_control_points"]);
    List<Offset> dataControlPoints = dcp ?? List<Offset>.from(curve["data_control_points"]);
    if(drawControlPoints){
      for(Offset point in controlPoints){
        restrictedAndUnrestrictedPoints.addOval(Rect.fromCenter(center: point, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
      }
      for(Offset point in restrictedControlPoints){
        restrictedAndUnrestrictedPoints.addRect(Rect.fromCenter(center: point, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
      }
      for(Offset point in dataControlPoints){
        dataPoints.addOval(Rect.fromCenter(center: point, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
      }
    }
    Paint stroke = curve["stroke"];
    Paint fill = curve["fill"];
    switch(mode){
      case EditingMode.Line:
        if(controlPoints.length >= 2){
          path.addPath(getLinePath(
              controlPoints,
              close: curve["close"]
          ), Offset.zero);
        }
        break;
      case EditingMode.Arc:
        if(controlPoints.length == 1 && restrictedControlPoints.isEmpty){
          Rect rect = Rect.fromCenter(center: controlPoints[0], width: 100, height: 100);
          Offset directionPoint = rect.center + Offset.fromDirection(0, sqrt2 * 50);
          curve["restricted_control_points"] = [rect.centerRight, rect.centerLeft, directionPoint];
          curve["data_control_points"] = [rect.bottomRight];
          curve["width"] = 100;
          curve["height"] = 100;
          curve["bounding_rect"] = rect;
          restrictedAndUnrestrictedPoints.addRect(Rect.fromCenter(center:rect.centerRight, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
          restrictedAndUnrestrictedPoints.addRect(Rect.fromCenter(center: rect.centerLeft, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
          restrictedAndUnrestrictedPoints.addRect(Rect.fromCenter(center: directionPoint, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
          dataPoints.addOval(Rect.fromCenter(center: rect.bottomRight, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
          path.addPath(getArcPath(controlPoints, curve["restricted_control_points"], 100, 100, close: curve["close"],), Offset.zero);
        } else if (controlPoints.length == 1 && dataControlPoints.length == 1 && restrictedControlPoints.length == 3){
          curve["bounding_rect"] = Rect.fromCenter(center: controlPoints[0], width: curve["width"], height: curve["height"]);
          path.addPath(getArcPath(
            controlPoints,
            restrictedControlPoints,
            curve["width"],
            curve["height"],
            close: curve["close"],
          ), Offset.zero);
        }
        break;
      case EditingMode.SplineCurve:
        if(controlPoints.length >= 4){
          path.addPath(getCMRPath(
            controlPoints,
            close: curve["close"],
          ), Offset.zero);
        }
        break;
      case EditingMode.QuadraticBezier:
        if(controlPoints.length >= 3){
          path.addPath(getQuadraticBezierPath(
            controlPoints,
            close: curve["close"],
          ), Offset.zero);
        }
        break;
      case EditingMode.CubicBezier:
        if(controlPoints.length >= 4){
          path.addPath(getCubicBezierPath(
            controlPoints,
            close: curve["close"],
          ), Offset.zero);
        }
        break;
      case EditingMode.Triangle:
        if(controlPoints.length == 3){
          path.addPath(getPolygonPath(controlPoints), Offset.zero);
        }
        break;
      case EditingMode.Rectangle:
        if(controlPoints.length == 2){
          Offset cp1 = Offset(controlPoints.first.dx, controlPoints.last.dy);
          Offset cp2 = Offset(controlPoints.last.dx, controlPoints.first.dy);
          controlPoints.insert(1, cp1);
          controlPoints.add(cp2);
          restrictedAndUnrestrictedPoints.addOval(Rect.fromCenter(center: cp1, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
          restrictedAndUnrestrictedPoints.addOval(Rect.fromCenter(center: cp2, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
          path.addPath(getPolygonPath(controlPoints), Offset.zero);
        } else if (controlPoints.length == 4){
          path.addPath(getPolygonPath(controlPoints), Offset.zero);
        }
        break;
      case EditingMode.Pentagon:
        if(controlPoints.length == 5){
          path.addPath(getPolygonPath(controlPoints), Offset.zero);
        }
        break;
      case EditingMode.Polygon:
        if(controlPoints.length >= 3){
          path.addPath(getPolygonPath(controlPoints), Offset.zero);
        }
        break;
      case EditingMode.Conic:
        if(controlPoints.length == 1){
          Offset restrictedPoint;
          if(restrictedControlPoints.isEmpty){
            Rect rect = Rect.fromCenter(center: controlPoints[0], width: 100, height: 100);
            restrictedPoint = controlPoints[0] + Offset.fromDirection(0, (rect.center - rect.bottomRight).distance);
            curve["restricted_control_points"] = [restrictedPoint];
            curve["data_control_points"] = [rect.bottomRight];
            curve["width"] = 100;
            curve["height"] = 100;
            restrictedAndUnrestrictedPoints.addRect(Rect.fromCenter(center: restrictedPoint, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
            dataPoints.addOval(Rect.fromCenter(center: rect.bottomRight, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
          } else {
            restrictedPoint = restrictedControlPoints.first;
          }
          path.addPath(getConicPath(controlPoints, curve["width"], curve["height"], restrictedPoint), Offset.zero);
        }
        break;
      case EditingMode.Leaf:
        if(controlPoints.length == 2){
          Offset displacement = controlPoints[1] - controlPoints[0];
          Offset center = Rect.fromPoints(controlPoints[0], controlPoints[1]).center;
          Offset cubicCP1, cubicCP2, cubicCP3, cubicCP4;
          double cp1Direction = displacement.direction - 3 * pi / 4;
          double cp1Distance = displacement.distance / 2;
          cubicCP1 = center + Offset.fromDirection(cp1Direction, cp1Distance);
          cubicCP2 = center + Offset.fromDirection(cp1Direction + pi / 2, cp1Distance);
          cubicCP3 = center + Offset.fromDirection(cp1Direction + pi, cp1Distance);
          cubicCP4 = center + Offset.fromDirection(cp1Direction + 3 * pi / 2, cp1Distance);
          restrictedAndUnrestrictedPoints.addOval(Rect.fromCenter(center: cubicCP1, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
          restrictedAndUnrestrictedPoints.addOval(Rect.fromCenter(center: cubicCP2, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
          restrictedAndUnrestrictedPoints.addOval(Rect.fromCenter(center: cubicCP3, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
          restrictedAndUnrestrictedPoints.addOval(Rect.fromCenter(center: cubicCP4, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
          curve["control_points"].addAll([cubicCP1, cubicCP2, cubicCP3, cubicCP4]);
          path.addPath(getLeafPath(curve["control_points"], symmetric: true, orthSymmetric: true), Offset.zero);
        } else if (controlPoints.length >= 3){
          path.addPath(getLeafPath(controlPoints, symmetric: curve["symmetric"], orthSymmetric: curve["orthogonal_symmetric"]), Offset.zero);
        }
        break;
      case EditingMode.Star:
        if(controlPoints.length == 2){
          path.addPath(getStarPath(controlPoints), Offset.zero);
        }
        break;
      case EditingMode.Heart:
        if(controlPoints.length == 2){
          Offset controlPoint = Rect.fromPoints(controlPoints[0], controlPoints[1]).centerLeft + Offset(0, (controlPoints[0] - controlPoints[1]).dy.abs() * 0.2);
          controlPoints.add(controlPoint);
          restrictedAndUnrestrictedPoints.addOval(Rect.fromCenter(center: controlPoint, width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
          path.addPath(getHeartShapePath(controlPoints), Offset.zero);
        } else if (controlPoints.length == 3){
          path.addPath(getHeartShapePath(controlPoints), Offset.zero);
        }
        break;
      case EditingMode.Arrow:
        if(controlPoints.length == 2 && restrictedControlPoints.isEmpty){
          Offset displacement = controlPoints[1] - controlPoints[0];
          double dist = displacement.distance / 4;
          double normal = displacement.direction + pi / 2;
          Offset lerpPoint = Offset.lerp(controlPoints[0], controlPoints[1], 0.66667)!;
          curve["directional_gap"] = (lerpPoint - controlPoints[0]).distance;
          curve["orthogonal_gap"] = dist;
          curve["restricted_control_points"] = [lerpPoint + Offset.fromDirection(normal, dist), lerpPoint + Offset.fromDirection(normal, dist / 2)];
          restrictedAndUnrestrictedPoints.addRect(Rect.fromCenter(center: curve["restricted_control_points"][0], width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
          restrictedAndUnrestrictedPoints.addRect(Rect.fromCenter(center: curve["restricted_control_points"][1], width: _controlPointSize / zoomFactor, height: _controlPointSize / zoomFactor));
          path.addPath(getArrowShapePath(controlPoints, curve["restricted_control_points"], curve["directional_gap"], curve["orthogonal_gap"]), Offset.zero);
        } else if (controlPoints.length == 2){
          path.addPath(getArrowShapePath(controlPoints, restrictedControlPoints, curve["directional_gap"], curve["orthogonal_gap"]), Offset.zero);
        }
        break;
      case EditingMode.FreeDraw:
        path.addPath(curve["free_draw_spline"].splinePath, Offset.zero);
        break;
      case EditingMode.DirectedLine:
        if(controlPoints.length == 2){
          path.addPath(getDirectedLinePath(controlPoints), Offset.zero);
          canvas.drawPath(getEndArrow(controlPoints), currentFillColor);
        }
        break;
      case EditingMode.CurveDirectedLine:
        if(controlPoints.length == 2){
          path.addPath(getCurveDirectedLinePath(controlPoints), Offset.zero);
          canvas.drawPath(getEndArrow(controlPoints), currentFillColor);
        }
        break;
      case EditingMode.GroupCurve:
        int sum = 0;
        for(Map<String, dynamic> c in curve["curves"]){
          int len = int.parse((sum + c["control_points"].length).toString());
          path.addPath(drawActivePath(canvas, c, cp: controlPoints.sublist(sum, len)), Offset.zero);
          sum = len;
        }
        toDraw = false;
        toTransform = false;
        break;
      default:
        break;
    }
    if(toTransform){
      path = path.transform(scaleThenTranslateMatrix);
      if(drawControlPoints){
        restrictedAndUnrestrictedPoints = restrictedAndUnrestrictedPoints.transform(scaleThenTranslateMatrix);
        dataPoints = dataPoints.transform(scaleThenTranslateMatrix);
        canvas.drawPath(restrictedAndUnrestrictedPoints, fillPaint);
        canvas.drawPath(dataPoints, dataPaint);
      }
    }
    if(toDraw){
      if(curve["outlined"]){
        canvas.drawPath(path, stroke);
      }
      if(!isLineOrCurve(mode) && curve["filled"]){
        canvas.drawPath(path, fill);
      } else if(curve["filled"] && curve["close"]){
        canvas.drawPath(path, fill);
      }
    }
    return path;
  }

  void drawBoundingRect(Canvas canvas, Path path, {Rect? rect}){
    if(rect == null){
      boundingRect = path.getBounds();
    } else {
      boundingRect = rect;
    }
    if(boundingRect != Rect.zero){
      Rect inflatedRect = boundingRect!.inflate(_controlPointSize);
      rotationControlPoint = boundingRect!.topRight;
      scaleControlPoint = boundingRect!.bottomRight;
      horizontalScaleControlPoint = boundingRect!.centerRight;
      verticalScaleControlPoint = boundingRect!.bottomCenter;
      canvas.drawRect(inflatedRect, boundingPaint);
      canvas.drawOval(
          Rect.fromCenter(center: rotationControlPoint! + Offset(_controlPointSize, -_controlPointSize), width: _controlPointSize, height: _controlPointSize), boundingPaint
      );
      canvas.drawOval(
          Rect.fromCenter(center: scaleControlPoint! + Offset(_controlPointSize, _controlPointSize), width: _controlPointSize, height: _controlPointSize), boundingPaint
      );
      canvas.drawOval(
          Rect.fromCenter(center: horizontalScaleControlPoint! + Offset(_controlPointSize, 0), width: _controlPointSize, height: _controlPointSize), boundingPaint
      );
      canvas.drawOval(
          Rect.fromCenter(center: verticalScaleControlPoint! + Offset(0, _controlPointSize), width: _controlPointSize, height: _controlPointSize), boundingPaint
      );
    }
  }

  void _mouseHoverCallBack(PointerHoverEvent event){
    setState(() {
      pointerHoveringPoint = event.localPosition;
    });
  }

  ui.Picture getCurrentPicture(List<Map<String, dynamic>> collection){
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Size canvasSize = Size(_standardCanvasWidth, _standardCanvasHeight);
    Canvas canvas = Canvas(recorder, Offset.zero & canvasSize);
    for(int i = 0; i < collection.length; i++){
      EditingMode thisMode = collection[i]["mode"];
      Paint pathPaint = collection[i]["stroke"];
      Paint pathFill = collection[i]["fill"];
      if(isPathMode(thisMode)){
        switch(thisMode){
          case EditingMode.Line:
            if(collection[i]["control_points"].length >= 2){
              Path path = getLinePath(collection[i]["control_points"], close: collection[i]["close"]);
              canvas.drawPath(path, pathPaint);
              if(collection[i]["filled"] && collection[i]["close"]){
                canvas.drawPath(path, pathFill);
              }
            }
            break;
          case EditingMode.Arc:
            if(collection[i]["control_points"].length == 1 ){
              Path path = getArcPath(
                collection[i]["control_points"],
                collection[i]["restricted_control_points"],
                collection[i]["width"],
                collection[i]["height"],
                close: collection[i]["close"],
              );
              canvas.drawPath(path, pathPaint);
              if(collection[i]["filled"] && collection[i]["close"]){
                canvas.drawPath(path, pathFill);
              }
            }
            break;
          case EditingMode.SplineCurve:
            if(collection[i]["control_points"].length >= 4){
              Path path = getCMRPath(
                collection[i]["control_points"],
                close: collection[i]["close"],
              );
              canvas.drawPath(path, pathPaint);
              if(collection[i]["filled"] && collection[i]["close"]){
                canvas.drawPath(path, pathFill);
              }
            }
            break;
          case EditingMode.QuadraticBezier:
            if(collection[i]["control_points"].length == 3){
              Path path = getQuadraticBezierPath(
                collection[i]["control_points"],
                close: collection[i]["close"],
              );
              canvas.drawPath(path, pathPaint);
              if(collection[i]["filled"] && collection[i]["close"]){
                canvas.drawPath(path, pathFill);
              }
            }
            break;
          case EditingMode.CubicBezier:
            if(collection[i]["control_points"].length == 4){
              Path path = getCubicBezierPath(
                collection[i]["control_points"],
                close: collection[i]["close"],
              );
              canvas.drawPath(path, pathPaint);
              if(collection[i]["filled"] && collection[i]["close"]){
                canvas.drawPath(path, pathFill);
              }
            }
            break;
          case EditingMode.Triangle:
            if(collection[i]["control_points"].length == 3){
              Path path = getPolygonPath(collection[i]["control_points"]);
              canvas.drawPath(path, pathPaint);
              if(collection[i]["filled"]){
                canvas.drawPath(path, pathFill);
              }
            }
            break;
          case EditingMode.Rectangle:
            if(collection[i]["control_points"].length == 4){
              Path path = getPolygonPath(collection[i]["control_points"]);
              canvas.drawPath(path, pathPaint);
              if(collection[i]["filled"]){
                canvas.drawPath(path, pathFill);
              }
            }
            break;
          case EditingMode.Pentagon:
            if(collection[i]["control_points"].length == 5){
              Path path = getPolygonPath(collection[i]["control_points"]);
              canvas.drawPath(path, pathPaint);
              if(collection[i]["filled"]){
                canvas.drawPath(path, pathFill);
              }
            }
            break;
          case EditingMode.Polygon:
            if(collection[i]["control_points"].length >= 3){
              Path path = getPolygonPath(collection[i]["control_points"]);
              canvas.drawPath(path, pathPaint);
              if(collection[i]["filled"]){
                canvas.drawPath(path, pathFill);
              }
            }
            break;
          case EditingMode.Conic:
            if(collection[i]["control_points"].length == 2){
              Offset point1 = collection[i]["control_points"][0];
              Offset point2 = collection[i]["control_points"][1];
              canvas.drawOval(Rect.fromPoints(point1, point2), pathPaint);
              if(collection[i]["filled"]){
                canvas.drawOval(Rect.fromPoints(point1, point2), pathFill);
              }
            }
            break;
          case EditingMode.Star:
            if(collection[i]["control_points"].length == 2){
              Offset point1 = collection[i]["control_points"][0];
              Offset point2 = collection[i]["control_points"][1];
              Path path = getStarPath([point1, point2]);
              canvas.drawPath(path, pathPaint);
              if(collection[i]["filled"]){
                canvas.drawPath(path, pathFill);
              }
            }
            break;
          case EditingMode.Heart:
            if(collection[i]["control_points"].length == 3){
              Offset point1 = collection[i]["control_points"][0];
              Offset point2 = collection[i]["control_points"][1];
              Offset point3 = collection[i]["control_points"][2];
              Path path = getHeartShapePath([point1, point2, point3]);
              canvas.drawPath(path, pathPaint);
              if(collection[i]["filled"]){
                canvas.drawPath(path, pathFill);
              }
            }
            break;
          case EditingMode.Arrow:
            if(collection[i]["control_points"].length == 2){
              Path path = getArrowShapePath(collection[i]["control_points"], collection[i]["restricted_control_points"], collection[i]["directional_gap"], collection[i]["orthogonal_gap"]);
              canvas.drawPath(path, pathPaint);
              if(collection[i]["filled"]){
                canvas.drawPath(path, pathFill);
              }
            }
            break;
          case EditingMode.FreeDraw:
            Paint pathPaint = collection[i]["stroke"];
            Path path = collection[i]["free_draw_spline"].splinePath;
            canvas.drawPath(path, pathPaint);
            break;
          case EditingMode.DirectedLine:
            if(collection[i]["control_points"].length == 2){
              Path path = getDirectedLinePath(collection[i]["control_points"]);
              Path arrow = getEndArrow(collection[i]["control_points"]);
              canvas.drawPath(arrow, pathFill);
              canvas.drawPath(path, pathPaint);
            }
            break;
          case EditingMode.CurveDirectedLine:
            if(collection[i]["control_points"].length == 2){
              Path path = getCurveDirectedLinePath(collection[i]["control_points"]);
              Path arrow = getEndArrow(collection[i]["control_points"]);
              canvas.drawPath(arrow, pathFill);
              canvas.drawPath(path, pathPaint);
            }
            break;
          default:
            print("Unimplemented path painter while drawing inactive paths");
            break;
        }
      } else if (thisMode == EditingMode.Image){
        canvas.drawImage(currentImage!, Offset.zero, Paint());
      } else if (thisMode == EditingMode.Fill){
        print("Unimplemented fill painter while drawing inactive paths");
      } else {
        print("Unimplemented unknown object painting while drawing inactive paths. $thisMode");
      }
    }
    return recorder.endRecording();
  }
}

class HorizontalRuler extends StatefulWidget {
  final double zoomFactor;
  final Offset panOffset;
  const HorizontalRuler(this.zoomFactor, this.panOffset, {Key? key}) : super(key: key);

  @override
  _HorizontalRulerState createState() => _HorizontalRulerState();
}

class _HorizontalRulerState extends State<HorizontalRuler> {
  @override
  Widget build(BuildContext context) {
    double xOffset = widget.panOffset.dx;
    double factor = widget.zoomFactor;
    double tickGap = 10 * factor;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Container(
            width: _standardCanvasWidth + 22,
            height: 26,
            padding: EdgeInsets.zero,
            alignment: Alignment.bottomRight,
        ),
        for(int i = 0; i < (_standardCanvasWidth + 2) / 10; i += 10)
          Positioned(
            top: 0,
            left: i * tickGap + xOffset + 11 - ((i * 10).toString().length * 2),
            child: getRulerMark((i * 10).toString())
          ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: _standardCanvasWidth + 22,
            height: 10,
            padding: const EdgeInsets.fromLTRB(15, 0, 5, 0,),
            child: CustomPaint(
                painter: FastDraw(
                    drawer: (canvas, size){
                      double x;
                      canvas.clipRect(Offset.zero & size);
                      for(int i = 0; i < (_standardCanvasWidth + 2)/ 10; i++ ){
                        x = i * tickGap + xOffset;
                        if(i % 10 == 0){
                          canvas.drawLine(Offset(x, 0), Offset(x, 10), rulerMarkerPaint);
                        } else if (i % 5 == 0){
                          canvas.drawLine(Offset(x, 3), Offset(x, 10), rulerMarkerPaint);
                        } else {
                          canvas.drawLine(Offset(x, 5), Offset(x, 10), rulerMarkerPaint);
                        }
                      }
                      canvas.drawLine(const Offset(1, 10), Offset(size.width - 2, 10), rulerMarkerPaint);
                    },
                    shouldRedraw: false
                )
            ),
          ),
        )
      ],
    );
  }
}

class VerticalRuler extends StatefulWidget {
  final double zoomFactor;
  final Offset panOffset;
  const VerticalRuler(this.zoomFactor, this.panOffset, {Key? key}) : super(key: key);

  @override
  _VerticalRulerState createState() => _VerticalRulerState();
}

class _VerticalRulerState extends State<VerticalRuler> {
  @override
  Widget build(BuildContext context) {
    double yOffset = widget.panOffset.dy;
    double factor = widget.zoomFactor;
    double tickGap = 10 * factor;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        SizedBox(
            height: _standardCanvasHeight + 20,
            width: 50,
        ),
        for(int i = 0; i < (_standardCanvasHeight + 2) / 10; i += 10)
          Positioned(
              top: i * tickGap + yOffset,
              left: 0,
              child: getRulerMark((i * 10).toString())
          ),
        Positioned(
          right: 10,
          bottom: 0,
          child: SizedBox(
            height: _standardCanvasHeight + 20,
            width: 10,
            child: CustomPaint(
                painter: FastDraw(
                    drawer: (canvas, size){
                      canvas.clipRect(Offset(0, 10) & Size(size.width, size.height - 20));
                      double y;
                      for(int i = 0; i < (_standardCanvasHeight + 2) / 10; i++ ){
                        y = i * tickGap + yOffset + 10;
                        if(i % 10 == 0){
                          canvas.drawLine(Offset(0, y), Offset(10, y), rulerMarkerPaint);
                        } else if (i % 5 == 0){
                          canvas.drawLine(Offset(3, y), Offset(10, y), rulerMarkerPaint);
                        } else {
                          canvas.drawLine(Offset(5, y), Offset(10, y), rulerMarkerPaint);
                        }
                      }
                      canvas.drawLine(const Offset(10, 10), Offset(10, size.height - 10), rulerMarkerPaint);
                    },
                    shouldRedraw: false
                )
            ),
          ),
        )
      ],
    );
  }
}


