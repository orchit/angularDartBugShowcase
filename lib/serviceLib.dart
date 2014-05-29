library service;

import "dart:html";
import "dart:async";
import "dart:convert";
import "dart:mirrors";
import "package:angular/angular.dart";
import 'dartUtilLib.dart';
import 'articleLib.dart';

@Controller (selector:"[service-controller]", publishAs: "ctrl")
class ServiceController extends ArticleController {

  ServiceController():super(1);
}
