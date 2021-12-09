import 'package:flutter/material.dart';

import 'package:objects_draw_kit/tools/utils.dart';

enum ModifierParameterType{Any}

class ModifierButton extends StatefulWidget {
  final EditingMode mode;
  final void Function()? actionCall;
  final Widget? iconWidget;
  final List<ModifierParameterType>? arguments;
  final bool state;
  const ModifierButton({this.mode: EditingMode.None, this.actionCall, this.iconWidget, this.state : false, this.arguments: const [], Key? key}) : super(key: key);

  @override
  _ModifierButtonState createState() => _ModifierButtonState();
}

class _ModifierButtonState extends State<ModifierButton> {
  @override
  Widget build(BuildContext context) {
    return MaterialButton(
        onPressed: widget.actionCall,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0)
        ),
        color: Colors.black,
        elevation: 4.0,
        padding: const EdgeInsets.symmetric(horizontal:4),
        child: widget.iconWidget ?? Container()
    );
  }
}
