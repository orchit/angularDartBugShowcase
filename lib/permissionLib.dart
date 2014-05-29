library permissions;

import 'package:angular/angular.dart';
import 'package:angular/directive/module.dart';
import 'dart:html';
import 'dart:convert';
import 'dart:async';

typedef ChangedItemCallback();
typedef PermissionListChangedCallback(List<String> permissions);

void processHttpRequestError(Event error){
  HttpRequest target = error.currentTarget;
  if(target.status==401){
    window.alert("Sie haben nicht die erforderlichen Berechtigungen oder sind nicht mehr angemeldet!");
    window.location.assign("/");
  }
  else window.alert("Leider ist bei einer Abfrage etwas schief gelaufen. Fehlercode: ${target.status} ${target.responseText}");
}

@Controller(selector: '[permissions]', publishAs: 'permissionsCtrl')
class PermissionsController {
  List<String> allowedItems = new List();
  List<PermissionListChangedCallback> _listener=new List();
  PermissionsController(){
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=43";
    // call the web server asynchronously
    var request = HttpRequest.getString(url)
    .then(_permissionsLoaded)
    .catchError(processHttpRequestError);
  }

  void addListener(PermissionListChangedCallback callback){
    _listener.add(callback);
    callback(allowedItems);
  }
  void _permissionsLoaded(String dataString) {
    allowedItems = JSON.decode(dataString);
    _listener.forEach((callback)=>callback(allowedItems));
  }
}

@Decorator(selector: '[permissionCheck]')
class PermissionCheckDirective {
  final Element element;
  PermissionsController ctrl;
  @NgAttr('permissionCheck')
  String idOverride=null;

  PermissionCheckDirective(Element this.element, PermissionsController this.ctrl){
    ctrl.addListener(handlePermissionChange);
    element.classes.add("attached");
  }

  void handlePermissionChange(List<String> newPermissions){
    String permissionKey=(idOverride==""||idOverride==null)?element.id:idOverride;
    if (permissionKey == null) {
      print("permissionKey is null! $idOverride - ${element.id}");
      element.classes.add("permissionKeyNull");
      return;
    }
    if (newPermissions.contains(permissionKey)) {
      element.classes.remove("ng-hide");
      element.classes.add("permissionChecked");
    } else {
      element.classes.add("ng-hide");
      element.classes.add("permissionDenied");
    }
  }
}

@Decorator(selector: '[sortDashboard]')
class SortDashboardDirective {
  final Element element;
  SortDashboardDirective(Element this.element){
      sortDashboard();
  }

  sortDashboard() {
    if(element.querySelector('.permissionChecked') != null) {
      List<Element> elements = element.children;
      elements.forEach((Element item){
        int i = 0;
        List<Element> innerElements = item.children;
        innerElements.forEach((Element innerItem) {
          if(!innerItem.classes.contains('ng-hide')) {
            i++;
          }
        });
        while(i < 3) {
          Element newChild = extractNextVisibleItem(item.nextElementSibling);
          if(newChild == null)
            break;
          item.children.add(newChild);
          i++;
        }
      });
    } else {
      new Timer(new Duration(milliseconds:30), () {
        sortDashboard();
      });
    }
  }

  Element extractNextVisibleItem(Element element) {
    if(element == null)
      return null;
    List<Element> childrenList = element.children;
    Element item;
    for(var child in childrenList) {
      if(!child.classes.contains('ng-hide')) {
        item = child;
        break;
      }
    }
    if(item != null) {
      item.remove();
      return item;
    }
    if(element.nextElementSibling != null)
      extractNextVisibleItem(element.nextElementSibling);
    else
      return null;
  }
}