import 'package:flutter/material.dart';

import 'package:objects_draw_kit/tools/utils.dart';

class PreferencesPage extends StatefulWidget {
  bool gridEnabled;
  bool rulerEnabled;
  bool snapToGridNode;
  String horizontalGridGap;
  String verticalGridGap;
  PreferencesPage(this.gridEnabled, this.rulerEnabled, this.snapToGridNode, this.horizontalGridGap, this.verticalGridGap, {Key? key}) : super(key: key);

  @override
  _PreferencesPageState createState() => _PreferencesPageState(gridEnabled, rulerEnabled, snapToGridNode, horizontalGridGap, verticalGridGap);
}

class _PreferencesPageState extends State<PreferencesPage> {

  _PreferencesPageState(this.enableGridLines, this.enableRuler, this.snapToGridNode, this.horizontalGridGap, this.verticalGridGap);

  TextEditingController horizontalGridGapController = TextEditingController();
  TextEditingController verticalGridGapController = TextEditingController();

  String horizontalGridGap;

  String verticalGridGap;

  bool snapToGridNode;

  bool enableGridLines;

  bool enableRuler;

  Map<String, dynamic> changes = {};

  String horizontalGridGapErrorMessage = "";

  String verticalGridGapErrorMessage = "";

  @override
  void initState(){
    super.initState();
    horizontalGridGapController.text = horizontalGridGap;
    verticalGridGapController.text = verticalGridGap;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double appBarHeight = 50;

    return SizedBox(
      width: screenWidth,
      height: screenHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: screenWidth,
            height: appBarHeight,
            child: AppBar(
              title: const Text("Preferences"),
              leading: MaterialButton(
                onPressed: (){
                  Navigator.pop(context, changes);
                },
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_back, size: 24, color: Colors.white),
                )
              ),
              actions: const [],
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Material(
            elevation: 10.0,
            child: Container(
              width: screenWidth / 2,
              height: screenHeight - appBarHeight - 50,
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                shape:  RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                  side: const BorderSide(width: 1.0, color: Colors.black)
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PreferenceHeader("General"),
                  const SizedBox(
                    height: 20,
                  ),
                  getCheckBoxPreferenceItem(
                    screenWidth / 2,
                    "Show grid lines",
                    enableGridLines,
                    (bool? val){
                        setState(() {
                          enableGridLines = !enableGridLines;
                          changes["grid_lines"] = enableGridLines;
                        });
                      }
                  ),
                  if(enableGridLines)
                    getTextFieldPreferenceItem(screenWidth / 2, "Horizontal grid gap", horizontalGridGapController, (String val){
                      if(!isNumeric(val)){
                        setState(() {
                          horizontalGridGap = "";
                          horizontalGridGapErrorMessage = "Invalid value";
                        });
                        return;
                      }
                      setState(() {
                        horizontalGridGap = val;
                        horizontalGridGapErrorMessage = "";
                        changes["horizontal_grid_gap"] = double.parse(horizontalGridGap);
                      });
                    },
                      horizontalGridGapErrorMessage
                    ),
                  if(enableGridLines)
                    getTextFieldPreferenceItem(screenWidth / 2, "Vertical grid gap", verticalGridGapController, (String val){
                      if(!isNumeric(val)){
                        setState(() {
                          verticalGridGap = "";
                          verticalGridGapErrorMessage = "Invalid value";
                        });
                        return;
                      }
                      setState(() {
                        verticalGridGap = val;
                        verticalGridGapErrorMessage = "";
                        changes["vertical_grid_gap"] = double.parse(verticalGridGap);
                      });
                    },
                      verticalGridGapErrorMessage
                    ),
                  getCheckBoxPreferenceItem(
                      screenWidth / 2,
                      "Snap to grid node when adding a new control point",
                      snapToGridNode,
                          enableGridLines ? (bool? val){
                        setState(() {
                          snapToGridNode = !snapToGridNode;
                          changes["snap_to_grid_node"] = snapToGridNode;
                        });
                      } : null,
                  ),
                  getCheckBoxPreferenceItem(
                      screenWidth / 2,
                      "Show ruler",
                      enableRuler,
                          (bool? val){
                        setState(() {
                          enableRuler = !enableRuler;
                          changes["ruler"] = enableRuler;
                        });
                      }
                  )

                ],
              )
            ),
          )
        ],
      ),
    );
  }

  Widget getCheckBoxPreferenceItem(double width, String text, variable, void Function(bool?)? callBack){
    return Container(
        width: width,
        height: 60,
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          color: Colors.black12,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(text, style: const TextStyle(fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Checkbox(
                  value: variable,
                  onChanged: callBack
              ),
            )
          ],
        )
    );
  }

  Widget getTextFieldPreferenceItem(double width, String text, TextEditingController cont, void Function(String)? callBack, String errorMessage){
    return Container(
        width: width,
        height: 60,
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          color: Colors.black12,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(text, style: const TextStyle(fontSize: 16)),
            ),
            Expanded(
              child: Container()
            ),
            errorMessage != "" ? Text(errorMessage, style: const TextStyle(fontSize: 16, color: Colors.red)) : Container(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9.0)
                ),
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4
                  ),
                  child: TextField(
                    textDirection: TextDirection.ltr,
                      controller: cont,
                      autofocus: false,
                      onChanged: callBack
                  ),
                ),
              ),
            )
          ],
        )
    );
  }
}

class PreferenceHeader extends StatelessWidget {
  final String header;
  const PreferenceHeader(this.header, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal:12),
            child: Text(header, textAlign: TextAlign.left, style: const TextStyle(fontSize:20, fontWeight: FontWeight.bold))
          ),
          const Divider(
            height: 10,
            thickness: 2.0,
            indent: 12.0,
          )
        ],
      ),
    );
  }
}
