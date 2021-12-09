import 'package:flutter/material.dart';

class ErrorPopupMessage extends StatefulWidget {
  final String errorMessage;
  final List<void Function()> actionCalls;
  final List<String> callNames;
  const ErrorPopupMessage(this.errorMessage, {Key? key, this.actionCalls : const [], this.callNames: const []})
      : assert(actionCalls.length == callNames.length, "Must have same number of action calls and call names"),
        super(key: key);

  @override
  _ErrorPopupMessageState createState() => _ErrorPopupMessageState();
}

class _ErrorPopupMessageState extends State<ErrorPopupMessage> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.errorMessage),
      titleTextStyle: TextStyle(fontSize: 16),
      titlePadding: EdgeInsets.symmetric(horizontal: 20),
      actions: [
        Container(
          width: 30,
          height: 30,
          child: MaterialButton(
            onPressed: (){
              Navigator.pop(context);
            },
            child: Text("Ok", style: TextStyle(color: Colors.white)),
            color: Colors.black,
            shape: CircleBorder(),
            padding: EdgeInsets.zero,
          ),
        ),
        if(widget.actionCalls.isNotEmpty)
          for(int i = 0; i < widget.actionCalls.length; i++)
            Container(
              width: 30,
              height: 30,
              child: MaterialButton(
                onPressed: (){
                  widget.actionCalls[i]();
                },
                child: Text(widget.callNames[i], style: TextStyle(color: Colors.white)),
                color: Colors.black,
                shape: CircleBorder(),
                padding: EdgeInsets.zero,
              ),
            ),
      ],
    );
  }
}

void showErrorMessage(BuildContext context, String message, List<void Function()> actionCalls){
  showDialog(
    context: context,
    builder:(context){
      return ErrorPopupMessage(message, actionCalls: actionCalls);
    }
  );
}
