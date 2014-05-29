library news;

import "dart:html";
import "dart:async";
import "dart:convert";
import "dart:mirrors";
import "package:angular/angular.dart";
import 'dartUtilLib.dart';
import 'articleLib.dart';

@Controller (selector:"[news-controller]", publishAs: "ctrl")
class NewsController extends ArticleController {

  NewsController():super(0);
}
