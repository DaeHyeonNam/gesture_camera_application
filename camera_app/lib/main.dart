import 'package:daehyeoncameraapp/pages/preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import './pages/camera_screen.dart';

void main(){
  runApp(GetMaterialApp(
    initialRoute: '/',
    namedRoutes: {
      '/': GetRoute(page: CameraScreen()),
      '/preview': GetRoute(page: PreviewScreen())
    },
  ));
}