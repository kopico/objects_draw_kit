import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart' as fBaseStorage;
import 'package:cloud_firestore/cloud_firestore.dart' as fCloud;
import 'package:firebase_auth/firebase_auth.dart' as fBaseAuth;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'dart:io' as io;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:html';
import 'dart:async';

import 'package:objects_draw_kit/tools/utils.dart';
import 'package:objects_draw_kit/tools/spline_path.dart';
import 'package:objects_draw_kit/static_assets/dialogs.dart';
import 'package:objects_draw_kit/io/authentication.dart';

class WebIO {

  fBaseAuth.User? user;

  Authentication? authInstance;

  WebIO(this.user){
    authInstance = Authentication(user: user);
  }

  FileReader reader = FileReader();

  fBaseStorage.Reference storageRef = fBaseStorage
      .FirebaseStorage
      .instance
      .ref();

  fCloud.FirebaseFirestore fCloudRef = fCloud.FirebaseFirestore.instance;

  Future<fBaseStorage.UploadTask> uploadFile(String folderName, io.File file, String extension, String uniqueId,
      {Map<String, String>? metas}) async {
    fBaseStorage.Reference ref = storageRef
        .child(folderName) // "profilepictures", "teamicons" etc
        .child("/$uniqueId -- ${file.path}");
    fBaseStorage.UploadTask fileUploadTask;
    final metaData = fBaseStorage.SettableMetadata(
        contentType: 'file/$extension',
        customMetadata: metas
    );
    fileUploadTask = storageRef.putFile(io.File(file.path), metaData);
    return Future.value(fileUploadTask);
  }

  Future<fBaseStorage.UploadTask> uploadImage(String folderName, io.File pickedImage, String uniqueId, Map<String, String> metas) async {
    String fileType = pickedImage.path.split(".").last;
    if(!['png','jpg','jpeg'].contains(fileType)){
      throw Exception("Upload photo error. File type $fileType not recognised.");
    }
    metas.addAll({'picked-file-path':pickedImage.path});
    fBaseStorage.Reference ref = storageRef
        .child(folderName) // "profilepictures", "teamicons" etc
        .child("/$uniqueId -- ${pickedImage.path}");
    fBaseStorage.UploadTask profilePhotoUploadTask;
    final metaData = fBaseStorage.SettableMetadata(
        contentType: 'image/$fileType',
        customMetadata: metas
    );
    if (kIsWeb){
      profilePhotoUploadTask = ref.putData(await pickedImage.readAsBytes(), metaData);
    } else {
      profilePhotoUploadTask = ref.putFile(io.File(pickedImage.path), metaData);
    }
    return Future.value(profilePhotoUploadTask);
  }

  Future<Map<String, dynamic>?> uploadDrawing(BuildContext context, ui.Image image, Map<String, String> metas, {String extension = "png", String? currentFilename, fBaseStorage.Reference? currentFileRef}) async {
    ByteData? imageByteData = await image.toByteData(format: ui.ImageByteFormat.png);
    List<fBaseStorage.Reference> dir = await storageRef.child("${user!.uid}").listAll().then((listResult){
      return listResult.prefixes;
    });
    List<String> existingFolders = dir.map((element) => element.name).toList();
    if(currentFilename == null || currentFileRef == null){
      Map<String, String>? fileLoc = await getFilenameDialog(context,  existingFolders);
      if(fileLoc != null){
        fBaseStorage.Reference ref = storageRef
            .child("${user!.uid}")
            .child("drawings")
            .child(fileLoc["folder"]!)// "profilepictures", "teamicons" etc
            .child(fileLoc["file_name"]!);
        metas.addAll({
          'extension': extension,
          'folder': fileLoc["folder"]!,
          'file_name': fileLoc["file_name"]!,
          'date': getDateString(DateTime.now()),
          'time': getTimeString(DateTime.now()),
        });
        final metaData = fBaseStorage.SettableMetadata(
            contentType: 'image/$extension',
            customMetadata: metas
        );
        if(imageByteData != null){
          var data = Uint8List.view(imageByteData.buffer);
          fBaseStorage.UploadTask uploadDrawing = await Future.value(ref.putData(data, metaData));
          return await uploadDrawing.then((snapshot){
            if(snapshot.state == fBaseStorage.TaskState.success){
              showInformationMessage(context, "Drawing saved!");
              return {
                "status":"Success",
                "reference": ref,
                "filename": ref.name,
              };
            } else {
              showInformationMessage(context, "Error encountered while saving drawing.");
              return {
                "status":"Unsuccessful",
              };
            }
          });
        }
      }
    } else {
      metas.addAll({
        'extension': extension,
        'folder': currentFileRef.parent?.name ?? "/",
        'file_name': currentFileRef.name,
        'date': getDateString(DateTime.now()) ,
        'time': getTimeString(DateTime.now()),
      });
      final metaData = fBaseStorage.SettableMetadata(
          contentType: 'image/$extension',
          customMetadata: metas
      );
      if(imageByteData != null){
        var data = Uint8List.view(imageByteData.buffer);
        fBaseStorage.UploadTask uploadDrawing = await Future.value(currentFileRef.putData(data, metaData));
        await uploadDrawing.then((snapshot){
          if(snapshot.state == fBaseStorage.TaskState.success){
            showInformationMessage(context, "Drawing saved!");
            return {
              "status":"Success",
              "reference": currentFileRef,
              "filename": currentFileRef.name,
            };
          } else {
            showInformationMessage(context, "Error encountered while saving drawing.");
            return {
              "status":"Unsuccessful",
            };
          }
        });
      }
    }
  }

  Future<ui.Image?> loadDrawingPNG(BuildContext context, String defaultFolder) async {
    print("Showing load file dialog");
    fBaseStorage.Reference? ref = await showLoadFileDialog(context, storageRef.child("drawings"));
    var credential = authInstance!.credential;
    if(ref == null || credential == null || credential.user == null){
      print("Invalid reference or credentials. Ref is null: ${ref == null}, credential is null: ${credential == null}, user is null: ${credential?.user == null}");
      return null;
    } else {
      var req = await ref.getDownloadURL().then((url) async {
        http.Request req = http.Request('GET', Uri.parse(url));
        req.headers.addAll({
          'Accept': "image/png",
          'Origin': "com.kopico.objects_draw_kit",
        });
        return req;
      }).catchError((error){
        return error.target;
      });
      Completer<ui.Image> completer = Completer();
      List<int> data = [];
      var resp = await req.send();
      var sub = await resp.stream.listen((List<int> value) {
        data.addAll(value);
      }, onDone:(){
        ui.decodeImageFromList(Uint8List.fromList(data), (ui.Image img){
          return completer.complete(img);
        });
      });
      return completer.future;
    }
  }

  Future<Map<String, dynamic>?> loadODKDrawing(BuildContext context, String defaultFolder) async {
    List<Map<String, dynamic>> odkDrawings = await queryDrawings();
    String? docId = await showLoadDrawingDialog(context, odkDrawings);
    var credential = authInstance!.credential;
    if(docId == null || credential == null || credential.user == null){
      throw Exception("Invalid document id or credentials");
    } else{
      fCloud.DocumentSnapshot<Map<String, dynamic>> doc = await fCloudRef.collection("objects_drawings").doc(docId).get();
      if(doc.exists){
        Map<String, dynamic> odkObject = {};
        List<Map<String, dynamic>> jsonData = List<Map<String, dynamic>>.from(doc.get("paths_collection"));
        odkObject["paths_collection"] = toODKPaths(jsonData);
        odkObject["drawing_name"] = doc.get("drawing_name");
        odkObject["doc_id"] = doc.id;
        return odkObject;
      }
    }
  }

  void updateUserCredential(fBaseAuth.UserCredential? credential){
    authInstance!.setCredential = credential;
  }

  Future<String> createNewDrawing(String drawingName, List<Map<String, dynamic>> paths) async {
    fCloud.DocumentReference docRef = await fCloudRef.collection("objects_drawings").add(
        {
          "drawing_name": drawingName,
          "user_id": user!.uid,
          "date_created": getDateString(DateTime.now()),
          "time_created": getTimeString(DateTime.now()),
          "paths_collection": toJson(paths),
        }).catchError((error){
      throw Exception("Error creating new drawing on cloud. Error: $error");
    });
    return docRef.id;
  }

  Future<void> renameDrawing() async {

  }

  Future<String?> autosave(List<Map<String, dynamic>> paths, String? docId, String drawingName) async {
    if(docId != null){
      fCloudRef.collection("objects_drawings").doc(docId).update({
        "doc_name": drawingName,
        "date_updated": getDateString(DateTime.now()),
        "time_updated": getTimeString(DateTime.now()),
        "paths_collection": toJson(paths),
      }).catchError((error){
        throw Exception("Error updating drawing on cloud while auto-saving");
      });
    } else {
      return await createNewDrawing(drawingName, paths);
    }
  }

  Future<List<Map<String, dynamic>>> queryDrawings() async {
    return await fCloudRef.collection("objects_drawings").where("user_id", isEqualTo: user!.uid).get().then((fCloud.QuerySnapshot queryResult){
      return queryResult.docs.map((docSnapshot){
        return {
          "doc_id": docSnapshot.id.toString(),
          "doc_name": docSnapshot.get("drawing_name")
        };
      }).toList();
    }).catchError((error){
      throw Exception("Error querying drawing on cloud while loading current list of drawings on cloud.");
    });
  }

  Future<Map<String, dynamic>> getDrawingData(String docId) async {
    return await fCloudRef.collection("objects_drawings").doc(docId).get().then((doc){
      return doc.data() ?? {};
    });
  }

  List<Map<String, dynamic>> toJson(List<Map<String, dynamic>> paths){
    List<Map<String, dynamic>> jsonData = List.filled(paths.length, {});
    for(int i = 0; i < paths.length; i++){
      jsonData[i]["control_points"] = [for(Offset p in paths[i]["control_points"]) {"x": p.dx, "y": p.dy}];
      jsonData[i]["restricted_control_points"] = [for(Offset p in paths[i]["restricted_control_points"]) {"x": p.dx, "y": p.dy}];
      jsonData[i]["data_control_points"] = [for(Offset p in paths[i]["data_control_points"]) {"x": p.dx, "y": p.dy}];
      Color fColor = paths[i]["fill"].color;
      jsonData[i]["fill_color"] = [fColor.alpha, fColor.red, fColor.green, fColor.blue];
      jsonData[i]["fill_shader_data"] = [];
      jsonData[i]["filled"] = paths[i]["filled"];
      Color sColor = paths[i]["stroke"].color;
      jsonData[i]["stroke_color"] = [sColor.alpha, sColor.red, sColor.green, sColor.blue];
      jsonData[i]["stroke_width"] = paths[i]["stroke"].strokeWidth;
      jsonData[i]["outlined"] = paths[i]["outlined"];
      Rect rect = paths[i]["bounding_rect"];
      jsonData[i]["bounding_rect"] = [{
        "x": rect.topLeft.dx,
        "y": rect.topLeft.dy
      }, {
        "x": rect.bottomRight.dx,
        "y": rect.bottomRight.dy
      }];
      switch(paths[i]["mode"]){
        case EditingMode.GroupCurve:
          jsonData[i]["curves"] = toJson(paths[i]["curves"]);
          break;
        case EditingMode.Line:
          jsonData[i]["close"] = paths[i]["close"];
          jsonData[i]["polygonal"] = paths[i]["polygonal"];
          break;
        case EditingMode.Arc:
          jsonData[i]["close"] = paths[i]["close"];
          break;
        case EditingMode.SplineCurve:
          jsonData[i]["close"] = paths[i]["close"];
          break;
        case EditingMode.QuadraticBezier:
          jsonData[i]["close"] = paths[i]["close"];
          jsonData[i]["chained"] = paths[i]["chained"];
          break;
        case EditingMode.CubicBezier:
          jsonData[i]["close"] = paths[i]["close"];
          jsonData[i]["chained"] = paths[i]["chained"];
          break;
        case EditingMode.FreeDraw:
          SplinePath splinePath = paths[i]["free_draw_spline"];
          jsonData[i]["control_points"] = [for(Offset p in splinePath.points) {"x": p.dx, "y": p.dy}];
          jsonData[i]["close"] = paths[i]["close"];
          jsonData[i]["draw_end"] = paths[i]["draw_end"];
          break;
        case EditingMode.Triangle:
          jsonData[i]["is_regular"] = paths[i]["is_regular"];
          break;
        case EditingMode.Rectangle:
          jsonData[i]["is_regular"] = paths[i]["is_regular"];
          break;
        case EditingMode.Pentagon:
          jsonData[i]["is_regular"] = paths[i]["is_regular"];
          break;
        case EditingMode.Polygon:
          jsonData[i]["is_regular"] = paths[i]["is_regular"];
          break;
        case EditingMode.Conic:
          break;
        case EditingMode.Heart:
          break;
        case EditingMode.Arrow:
          break;
        case EditingMode.Star:
          jsonData[i]["is_regular"] = paths[i]["is_regular"];
          break;
        case EditingMode.Leaf:
          jsonData[i]["symmetric"] = paths[i]["symmetric"];
          jsonData[i]["orthogonal_symmetric"] = paths[i]["orthogonal_symmetric"];
          break;
        default:
          break;
      }
      jsonData[i]["mode"] = paths[i]["mode"].toString();
    }
    return jsonData;
  }

  List<Map<String, dynamic>> toODKPaths(List<Map<String, dynamic>> jsonData){
    for(int i = 0; i < jsonData.length; i++){
      jsonData[i]["control_points"] = [for(Map<String, dynamic> p in List<Map<String, dynamic>>.from(jsonData[i]["control_points"])) Offset(p["x"], p["y"])];
      jsonData[i]["restricted_control_points"] = [for(Map<String, dynamic> p in List<Map<String, dynamic>>.from(jsonData[i]["restricted_control_points"])) Offset(p["x"], p["y"])];
      jsonData[i]["data_control_points"] = [for(Map<String, dynamic> p in List<Map<String, dynamic>>.from(jsonData[i]["data_control_points"])) Offset(p["x"], p["y"])];
      List<int> fColor = List<int>.from(jsonData[i]["fill_color"]);
      jsonData[i]["fill"] = Paint()
          ..color = Color.fromARGB(fColor[0], fColor[1], fColor[2], fColor[3])
          ..style = PaintingStyle.fill;
      // jsonData[i]["fill_shader_data"] = [];
      List<int> sColor = List<int>.from(jsonData[i]["stroke_color"]);;
      jsonData[i]["stroke"] = Paint()
          ..color = Color.fromARGB(sColor[0], sColor[1], sColor[2], sColor[3])
          ..strokeWidth = jsonData[i]["stroke_width"]
          ..style = PaintingStyle.stroke;
      Offset boundingRectCorner1 = Offset(jsonData[i]["bounding_rect"][0]["x"], jsonData[i]["bounding_rect"][0]["y"]);
      Offset boundingRectCorner2 = Offset(jsonData[i]["bounding_rect"][1]["x"], jsonData[i]["bounding_rect"][1]["y"]);
      jsonData[i]["bounding_rect"] = Rect.fromPoints(boundingRectCorner1, boundingRectCorner2);
      jsonData[i]["mode"] = getMode(jsonData[i]["mode"]);
      switch(jsonData[i]["mode"]){
        case EditingMode.GroupCurve:
          jsonData[i]["curves"] = toODKPaths(jsonData[i]["curves"]);
          break;
        case EditingMode.FreeDraw:
          jsonData[i]["free_draw_spline"] = SplinePath.generate(jsonData[i]["control_points"]);
          jsonData[i]["control_points"] = <Offset>[];
          break;
        default:
          break;
      }
    }
    return jsonData;
  }
}