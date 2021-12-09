import 'package:flutter/material.dart';
import 'package:objects_draw_kit/tools/draw_pad.dart';

Paint rulerMarkerPaint = Paint()
  ..color = Colors.black38
  ..strokeWidth = 1.0
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.stroke;

class TopRulerWidget extends StatelessWidget {
  final double _standardCanvasWidth;
  const TopRulerWidget(this._standardCanvasWidth, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: _standardCanvasWidth + 20,
        height: 26,
        padding: EdgeInsets.zero,
        alignment: Alignment.centerRight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: _standardCanvasWidth + 20,
              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:[
                    for(int i = 0; i <= _standardCanvasWidth; i += 100)
                      getRulerMark(i.toString()),
                  ]
              ),
            ),
            Container(
              width: _standardCanvasWidth + 20,
              height: 10,
              padding: const EdgeInsets.fromLTRB(15, 0, 5, 0,),
              child: CustomPaint(
                  painter: FastDraw(
                      drawer: (canvas, size){
                        double x = 1;
                        do {
                          if (x % 100 == 1){
                            canvas.drawLine(Offset(x, 0), Offset(x, 10), rulerMarkerPaint);
                          } else if (x % 50 == 1){
                            canvas.drawLine(Offset(x, 3), Offset(x, 10), rulerMarkerPaint);
                          } else {
                            canvas.drawLine(Offset(x, 5), Offset(x, 10), rulerMarkerPaint);
                          }
                          x += 10;
                        } while (x < size.width + 2);
                        canvas.drawLine(const Offset(1, 10), Offset(size.width + 1, 10), rulerMarkerPaint);
                      },
                      shouldRedraw: false
                  )
              ),
            ),
          ],
        )
    );
  }
}

class LeftRulerWidget extends StatelessWidget {
  final double _standardCanvasHeight;
  const LeftRulerWidget(this._standardCanvasHeight,{Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: _standardCanvasHeight + 20,
        width: 33,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: _standardCanvasHeight + 20,
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:[
                    for(int i = 0; i <= _standardCanvasHeight; i += 100)
                      getRulerMark(i.toString())
                  ]
              ),
            ),
            SizedBox(
              height: _standardCanvasHeight + 20,
              width: 10,
              child: CustomPaint(
                  painter: FastDraw(
                      drawer: (canvas, size){
                        double y = 10;
                        do {
                          if (y % 100 == 10){
                            canvas.drawLine(Offset(0, y), Offset(10, y), rulerMarkerPaint);
                          } else if (y % 50 == 10){
                            canvas.drawLine(Offset(3, y), Offset(10, y), rulerMarkerPaint);
                          } else {
                            canvas.drawLine(Offset(5, y), Offset(10, y), rulerMarkerPaint);
                          }
                          y += 10;
                        } while (y < size.height );
                        canvas.drawLine(const Offset(10, 10), Offset(10, size.height - 10), rulerMarkerPaint);
                      },
                      shouldRedraw: false
                  )
              ),
            ),
          ],
        )
    );
  }
}


Widget getRulerMark(String mark, {double? width, double? height}){
  if(mark == "0"){
    mark = " 0 ";
  }
  if(width != null){
    return Material(
      type: MaterialType.card,
      child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(0,0,0,0),
          child: Text(mark, style: const TextStyle(fontSize:10, color: Colors.grey), textAlign: TextAlign.left, overflow: TextOverflow.clip,)
      ),
    );
  } else if(height != null){
    return Material(
      type: MaterialType.card,
      child: SizedBox(
          height: height,
          child: Text(mark, style: const TextStyle(fontSize:10, color: Colors.grey), overflow: TextOverflow.clip,)
      ),
    );
  } else {
    return Material(
        type: MaterialType.card,
        child: Text(mark, style: const TextStyle(fontSize:10, color: Colors.grey), overflow: TextOverflow.clip,)
    );
  }
}
