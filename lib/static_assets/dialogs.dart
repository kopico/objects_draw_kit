import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'dart:core';

import 'package:objects_draw_kit/tools/utils.dart';

void showInformationMessage(BuildContext context, String info){
  showDialog(
    context: context,
    builder: (context){
      return SimpleDialog(
        title: Text(info, textAlign: TextAlign.center,),
        titleTextStyle: TextStyle(fontSize: 16,),
        titlePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          MaterialButton(
            shape: CircleBorder(),
            onPressed:(){
              Navigator.pop(context);
            },
            padding:EdgeInsets.zero,
            color: Colors.black,
            child: const Text("Ok", style: TextStyle(fontSize: 16, color: Colors.white))
          )
        ],
      );
    }
  );
}

Future<bool?> showConfirmDialog(BuildContext context, String confirmMessage, void Function() confirmCall, void Function() cancelCall) async {
  return await showDialog<bool>(
      context: context,
      builder: (context){
        return SimpleDialog(
          title: Text("$confirmMessage", textAlign: TextAlign.center,),
          titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          titleTextStyle: const TextStyle(fontSize:16, fontWeight: FontWeight.bold),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:[
                  MaterialButton(
                      onPressed: confirmCall,
                      child: const Icon(Icons.check, size: 24, color: Colors.white),
                      color: Colors.black,
                      shape: const CircleBorder()
                  ),
                  MaterialButton(
                      onPressed: cancelCall,
                      child: const Icon(Icons.close, size: 24, color: Colors.white),
                      color: Colors.black,
                      shape: const CircleBorder()
                  ),
                ]
            )
          ],
        );
      }
  );
}

Future<Map<String, String>?> getFilenameDialog(BuildContext context, List<String> existingFolders) async {
  String today = getDateString(DateTime.now());
  TextEditingController filename = TextEditingController();
  String selectedDirectory = today;
  return await showDialog(
      context: context,
      builder: (context){
        return SizedBox(
          width: 800,
          height: 200,
          child: SimpleDialog(
            title: const Text("Save drawing to cloud", textAlign: TextAlign.left,),
            titlePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            titleTextStyle: const TextStyle(fontSize:16, fontWeight: FontWeight.bold),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            children: [
              Container(
                width: 800,
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children:[
                      Container(
                        width: 100,
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                        child: const Text("File name: ", style:TextStyle(fontSize:16, color: Colors.black))
                      ),
                      Expanded(
                        child: Material(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9.0),
                          ),
                          child: Container(
                            height: 32,
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: TextField(
                              controller: filename,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[200],
                                contentPadding: const EdgeInsets.fromLTRB(6,0,0,15 ),
                                border: InputBorder.none,
                              ),
                              onChanged: (val){

                              },
                              style: const TextStyle(fontSize:16),
                            ),
                          ),
                        ),
                      )
                    ]
                ),
              ),
              Container(
                width: 800,
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Container(
                      width: 100,
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      child:  Text("Folder: ", style:TextStyle(fontSize:16, color: Colors.black))
                    ),
                    Expanded(
                      child: Material(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9.0),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: DropdownButton<String>(
                            items: [
                              for(String folder in existingFolders)
                                DropdownMenuItem(child: Text(folder), value: folder),
                              DropdownMenuItem(child: Text(today), value: today,)
                            ],
                            value: selectedDirectory,
                            onChanged: (String? val){
                              selectedDirectory = val ?? "Invalid directory";
                            },
                            style: const TextStyle(fontSize:16),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 15, 6, 6),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children:[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: MaterialButton(
                            onPressed: (){
                              Navigator.pop(context, {
                                "file_name": filename.text,
                                "folder": selectedDirectory,
                              });
                            },
                            child: const Text("Save", style:TextStyle(fontSize:16, color: Colors.white)),
                            color: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9.0)
                            ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: MaterialButton(
                            onPressed: (){
                              Navigator.pop(context);
                            },
                            child: const Text("Cancel", style:TextStyle(fontSize:16, color: Colors.white)),
                            color: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9.0)
                            )
                        ),
                      ),
                    ]
                ),
              )
            ],
          ),
        );
      }
  );
}

Future<String?> showGetDrawingNameDialog(BuildContext context) async {
  TextEditingController drawingName = TextEditingController();
  return await showDialog<String>(
    context: context,
    builder: (context){
      double screenWidth = MediaQuery.of(context).size.width;
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
        child: Container(
            width: screenWidth * 0.6,
            height: 100,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                            width: 120,
                            height: 30,
                            alignment: Alignment.centerLeft,
                            child: const Text("Drawing name:", style: TextStyle(fontSize: 16,))
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 30,
                            child: TextField(
                              controller: drawingName,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[200],
                                contentPadding: const EdgeInsets.fromLTRB(6,0,0,18),
                                border: InputBorder.none,
                              ),
                              onChanged: (val){

                              },
                              style: const TextStyle(fontSize:16),
                            ),
                          ),
                        )
                      ]
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal:0, vertical: 6),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 100,
                          margin:EdgeInsets.symmetric(horizontal:6),
                          child: MaterialButton(
                            onPressed: (){
                              Navigator.pop(context, drawingName.text);
                            },
                            child: const Text("Confirm", style: TextStyle(fontSize:16, color: Colors.white)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 10.0,
                            color: Colors.black,
                          ),
                        ),
                        Container(
                          width: 100,
                          margin:EdgeInsets.symmetric(horizontal:6),
                          child: MaterialButton(
                            onPressed:(){
                              Navigator.pop(context);
                            },
                            child: const Text("Cancel", style: TextStyle(fontSize:16, color: Colors.white)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            color: Colors.black,
                            elevation: 10.0,
                          ),
                        )
                      ]
                  ),
                ),
              ],
            )
        ),
      );
    }
  );
}

Future<String?> showLoadDrawingDialog(BuildContext context, List<Map<String, dynamic>> odkDrawings) async {
  return await showDialog(
      context: context,
      builder: (context){
        return LoadDrawingDialog(odkDrawings);
      }
  );
}

class LoadDrawingDialog extends StatefulWidget {
  final List<Map<String, dynamic>> odk;
  const LoadDrawingDialog(this.odk, {Key? key}) : super(key: key);

  @override
  _LoadDrawingDialogState createState() => _LoadDrawingDialogState();
}

class _LoadDrawingDialogState extends State<LoadDrawingDialog> {

  Map<String, Reference> directoriesRef = {};
  Map<String, dynamic> itemsRef = {};
  Reference? folderReference;
  String? selectedFileReference;

  Future<void> getDirInRef({Reference? ref}) async {
    if(ref != null){
      var res = await ref.listAll().then((listing){
        return {
          for(Reference ref in listing.prefixes)
            ref.name: ref,
        };
      });
      setState(() {
        directoriesRef = res;
      });
    }
  }

  Future<void> getItemsInRef(Reference? ref, List<Map<String, dynamic>>? drawings) async {
    Map<String, dynamic> res;
    if(ref != null){
      res = await ref.listAll().then((listing){
        return {
          for(Reference ref in listing.items)
            ref.name: ref,
        };
      });
      setState(() {
        itemsRef = res;
      });
    } else if (drawings != null){
      res = {
        for(Map<String, dynamic> drawing in drawings)
          drawing["doc_name"]: drawing["doc_id"],
      };
      setState(() {
        itemsRef = res;
      });
    }
  }

  @override
  void initState(){
    super.initState();
    getDirInRef();
    getItemsInRef(folderReference, widget.odk);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 800,
      height: 200,
      child: SimpleDialog(
        title: const Text("Load drawing from cloud", textAlign: TextAlign.left,),
        titlePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        titleTextStyle: const TextStyle(fontSize:16, fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        children: [
          Container(
            width: 800,
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              children: [
                Container(
                    width: 100,
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: const Text("Folder: ", style:TextStyle(fontSize:16, color: Colors.black))
                ),
                Expanded(
                  child: Material(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9.0),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: DropdownButton<Reference>(
                        items: [
                          for(String folder in directoriesRef.keys)
                            DropdownMenuItem(
                              child: SizedBox(
                                height: 32,
                                width: 700,
                                child: Text("/$folder/"),
                              ),
                              value: directoriesRef[folder],),
                        ],
                        value: folderReference,
                        onChanged: (Reference? val) async {
                          folderReference = val;
                          if(folderReference != null){
                            await getItemsInRef(folderReference!, widget.odk);
                            context.findRenderObject()!.markNeedsPaint();
                          }
                        },
                        style: const TextStyle(fontSize:16),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          Container(
            width: 800,
            height: 300,
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Container(
                      width: 100,
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      child: const Text("File: ", style:TextStyle(fontSize:16, color: Colors.black))
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal:8.0),
                      child: Material(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9.0),
                        ),
                        color: Colors.black12,
                        child: Container(
                          height: 32,
                          width: 830,
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
                          child: Column(
                              children: [
                                for(String filename in itemsRef.keys)
                                  MaterialButton(
                                    onPressed: (){
                                      setState(() {
                                        if(selectedFileReference == itemsRef[filename]){
                                          selectedFileReference = null;
                                        } else {
                                          selectedFileReference = itemsRef[filename];
                                        }
                                      });
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Icon(Icons.file_copy, size: 18, color: Colors.grey),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal:8.0),
                                          child: Text(filename, textAlign: TextAlign.start, style: TextStyle(fontSize:16, )),
                                        ),
                                      ],
                                    ),
                                    elevation: 0.0,
                                    hoverColor: Colors.cyanAccent,
                                    color: selectedFileReference == itemsRef[filename] ? Colors.cyanAccent : Colors.black12,
                                  ),
                              ]
                          ),
                        ),
                      ),
                    ),
                  )
                ]
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 15, 6, 6),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children:[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MaterialButton(
                      onPressed: (){
                        Navigator.pop(context, selectedFileReference);
                      },
                      child: const Text("Load", style:TextStyle(fontSize:16, color: Colors.white)),
                      color: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9.0)
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MaterialButton(
                        onPressed: (){
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel", style:TextStyle(fontSize:16, color: Colors.white)),
                        color: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9.0)
                        )
                    ),
                  ),
                ]
            ),
          )
        ],
      ),
    );
  }
}

Future<Reference?> showLoadFileDialog(BuildContext context, Reference storageRef) async {
  print("Running load file dialog");
  return await showDialog(
      context: context,
      builder: (context){
        return LoadFileDialog(storageRef);
      }
  );
}

class LoadFileDialog extends StatefulWidget {
  final Reference storage;
  const LoadFileDialog(this.storage, {Key? key}) : super(key: key);

  @override
  _LoadFileDialogState createState() => _LoadFileDialogState();
}

class _LoadFileDialogState extends State<LoadFileDialog> {

  Map<String, Reference> directoriesRef = {};
  Map<String, dynamic> itemsRef = {};
  Reference? folderReference;
  var selectedFileReference;

  Future<void> getDirInRef({Reference? ref}) async {
    if(ref != null){
      var res = await ref.listAll().then((listing){
        return {
          for(Reference ref in listing.prefixes)
            ref.name: ref,
        };
      });
      setState(() {
        directoriesRef = res;
      });
    }
  }

  Future<void> getItemsInRef(Reference? ref) async {
    ref ??= widget.storage;
    Map<String, dynamic> res;
    res = await ref.listAll().then((listing){
      return {
        for(Reference ref in listing.items)
          ref.name: ref,
      };
    });
    setState(() {
      itemsRef = res;
    });
  }

  @override
  void initState(){
    super.initState();
    getDirInRef(ref: widget.storage);
    getItemsInRef(folderReference);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 800,
      height: 200,
      child: SimpleDialog(
        title: const Text("Load drawing from cloud", textAlign: TextAlign.left,),
        titlePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        titleTextStyle: const TextStyle(fontSize:16, fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        children: [
          Container(
            width: 800,
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              children: [
                Container(
                    width: 100,
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: const Text("Folder: ", style:TextStyle(fontSize:16, color: Colors.black))
                ),
                Expanded(
                  child: Material(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9.0),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: DropdownButton<Reference>(
                        items: [
                          for(String folder in directoriesRef.keys)
                            DropdownMenuItem(
                              child: SizedBox(
                                height: 32,
                                width: 700,
                                child: Text("/$folder/"),
                              ),
                              value: directoriesRef[folder],),
                        ],
                        value: folderReference,
                        onChanged: (Reference? val) async {
                          folderReference = val;
                          if(folderReference != null){
                            await getItemsInRef(folderReference!);
                            context.findRenderObject()!.markNeedsPaint();
                          }
                        },
                        style: const TextStyle(fontSize:16),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          Container(
            width: 800,
            height: 300,
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Container(
                      width: 100,
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      child: const Text("File: ", style:TextStyle(fontSize:16, color: Colors.black))
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal:8.0),
                      child: Material(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9.0),
                        ),
                        color: Colors.black12,
                        child: Container(
                          height: 32,
                          width: 830,
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
                          child: Column(
                              children: [
                                for(String filename in itemsRef.keys)
                                  MaterialButton(
                                    onPressed: (){
                                      setState(() {
                                        if(selectedFileReference == itemsRef[filename]){
                                          selectedFileReference = null;
                                        } else {
                                          selectedFileReference = itemsRef[filename];
                                        }
                                      });
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Icon(Icons.file_copy, size: 18, color: Colors.grey),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal:8.0),
                                          child: Text(filename, textAlign: TextAlign.start, style: TextStyle(fontSize:16, )),
                                        ),
                                      ],
                                    ),
                                    elevation: 0.0,
                                    hoverColor: Colors.cyanAccent,
                                    color: selectedFileReference == itemsRef[filename] ? Colors.cyanAccent : Colors.black12,
                                  ),
                              ]
                          ),
                        ),
                      ),
                    ),
                  )
                ]
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 15, 6, 6),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children:[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MaterialButton(
                      onPressed: (){
                        Navigator.pop(context, selectedFileReference);
                      },
                      child: const Text("Load", style:TextStyle(fontSize:16, color: Colors.white)),
                      color: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9.0)
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MaterialButton(
                        onPressed: (){
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel", style:TextStyle(fontSize:16, color: Colors.white)),
                        color: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9.0)
                        )
                    ),
                  ),
                ]
            ),
          )
        ],
      ),
    );
  }
}