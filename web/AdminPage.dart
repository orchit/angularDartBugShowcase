// Temporary, please follow https://github.com/angular/angular.dart/issues/476
//@MirrorsUsed(
//    targets: const ['contacts', 'partner', 'articles', 'developer', 'dartUtil','news','permissions','userAdmin'],
//    override: '*')
//import 'dart:mirrors';

import 'package:angular/angular.dart';
import 'package:angular/application_factory.dart';
import 'package:angular_ui/angular_ui.dart';

import 'package:logging/logging.dart';
import 'dart:html';
import 'package:admin/partnerLib.dart';
import 'package:admin/dartUtilLib.dart';
import 'package:admin/permissionLib.dart';
import 'package:admin/userAdminLib.dart';
import 'package:admin/CommonEntityAdminLib.dart';

typedef RouteChangedCallback(String oldVal, String newVal);

void adminRouteInitializer(Router router, RouteViewFactory view) {
  Map<String, NgRouteCfg> routes = new Map();
  routes['dashboardLink'] = ngRoute(path: '/dashboard', view: 'views/dashboard.html');
  routes['partnerLink'] = ngRoute(path: '/partner', view: 'views/partner.html');
  routes['userAdminLink'] = ngRoute(path: '/userAdmin', view: 'views/userAdmin.html');
  routes['view_default'] = ngRoute(defaultRoute: true, enter: (RouteEnterEvent e) => router.go('dashboardLink', {
  }, replace: true));
  view.configure(routes);
}

@Controller(selector: '[admin-base]', publishAs: 'baseCtrl')
class AdminPageController {
  final currentYear = new DateTime.now().year;
  Router router;
  String baseUri;
  String _currentRouteName;
  List<RouteChangedCallback> listener = new List();

  String get currentRouteName => _currentRouteName;

  set currentRouteName(String newRoute) {
    String old = _currentRouteName;
    _currentRouteName = newRoute;
    listener.forEach((callback) => callback(old, newRoute));
  }

  AdminPageController(Router this.router) {
    baseUri = window.location.origin;
    router.onRouteStart.listen((RouteStartEvent event) {
      event.completed.then((_) {
        if (router.activePath.length > 0) {
          currentRouteName = router.activePath[0].name;
        } else {
          currentRouteName = null;
        }
      });
    });
  }
}

@Decorator(selector: '[menuItem]')
class MenuSelectDirective{
  final Element element;

  MenuSelectDirective(Element this.element, AdminPageController adminCtrl) {
    adminCtrl.listener.add(handleRouteChange);
  }

  void handleRouteChange(String changeRecordOld, String changeRecord) {
    if (changeRecordOld == element.id) {
      element.classes.remove("current-admin");
    }
    if (changeRecord == element.id) {
      element.classes.add("current-admin");
    }
  }
}

class AdminPage extends Module {
  AdminPage() {
    value(PermissionsController, new PermissionsController());
    value(RouteInitializerFn, adminRouteInitializer);
    factory(NgRoutingUsePushState, (_) => new NgRoutingUsePushState.value(false));
    type(AdminPageController);
    type(PartnerAdminController);
    type(UserAdminPage);
    type(SalesUserAdminPage);
    type(MenuSelectDirective);
    type(FocusDirective);
    type(FormatText);
    type(YesNoFilter);
    type(AbsolutifyDirective);
    type(NgBindHtmlUnsafeDirective);
    type(ExternalLinkDirective);
    type(FixModalHeightDirective);
    type(HideScrollbarDirective);
    type(PermissionCheckDirective);
    type(InputFileDirective);
    type(SortDashboardDirective);
    type(ZipCodeAssignmentComponent);
    type(MessagesComponent);
  }
}

void main() {
  Logger.root.level = Level.FINEST;
  Logger.root.onRecord.listen((LogRecord r) {
    print(r.message);
  });

  applicationFactory().addModule(new AdminPage()).addModule(new AngularUIModule()).run();
}
