
import 'dart:io';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PreviewScreen extends StatefulWidget{

  @override
  _PreviewScreenState createState() => _PreviewScreenState();

}


class _PreviewScreenState extends State<PreviewScreen>{
  List args = Get.arguments;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          color: Colors.black,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                  child: Transform.scale(scale: args[1]== 1.01? args[1]+0.03 : args[1],
                    child: Center(
                        child: Image.file(File(args[0]),fit: BoxFit.cover,)
                    ),)
              ),
              Container(
                color:Colors.black,
                alignment: Alignment.center,
                height:40,
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<ByteData> getBytesFromFile() async{
    Uint8List bytes = File(args[0]).readAsBytesSync() as Uint8List;
    return ByteData.view(bytes.buffer);
  }
}