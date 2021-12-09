import 'package:flutter/material.dart';
import 'package:objects_draw_kit/static_assets/ui_parameters.dart';

Widget getButton(
    BuildContext context,
    double buttonSize,
    IconData iconData,
    String label,
    void Function()? handler,
    {bool enable : true, Widget? iconWidget, Color? iconColor}){
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        padding:EdgeInsets.zero,
        width: buttonSize,
        height: buttonSize,
        margin: EdgeInsets.symmetric(horizontal: 10),
        alignment:Alignment.center,
        child: Opacity(
          opacity: enable ? 1 : 0.5,
          child: Material(
            shape: CircleBorder(),
            color: Colors.black,
            clipBehavior: Clip.hardEdge,
            elevation: 4.0,
            child: IconButton(
              icon: iconWidget ?? Icon(iconData, color: iconColor,),
              alignment: Alignment.center,
              onPressed: enable ? handler : null,
            ),
          ),
        ),
      ),
      Container(
          height: buttonLabelHeight,
          alignment: Alignment.center,
          padding: buttonLabelEdgeInsets,
          child:Text(label, softWrap: true, textAlign: TextAlign.center,)
      ),
    ],
  );
}