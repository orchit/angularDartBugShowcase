library dartUtil;
import 'package:angular/angular.dart';
import 'package:angular/directive/module.dart';
import 'package:angular/utils.dart';
import 'dart:html';
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';

typedef String OptionItemNameGenerator(Map data);

String DefaultOptionItemNameGenerator(Map data) => data['name'];

void handleOptionItemResult(collection, String jsonResult,
                            {idName:'id', captionGenerator:DefaultOptionItemNameGenerator}) {
  List<Map> data = JSON.decode(jsonResult);
  collection.clear();
  if (data != null) {
    data.forEach((Map map) {
      collection.add(new OptionItem(int.parse(map[idName]), captionGenerator(map)));
    });
  }else{
    window.console.error("COULD NOT DECODE LIST, DATA WAS NULL! $jsonResult");
  }
}

@Decorator(selector: 'input[type=file][ng-model]')
class InputFileDirective {
  final InputElement inputElement;
  final NgModel ngModel;
  final Scope scope;

  InputFileDirective(Element this.inputElement, this.ngModel, this.scope) {
    ngModel.render = (value) {
      scope.rootScope.domWrite(() {
        inputElement.files = value;
      });
    };
    inputElement
      ..onChange.listen(relaxFnArgs(processValue))
      ..onInput.listen(relaxFnArgs(processValue))
      ..onBlur.listen((e) {
      ngModel.markAsTouched();
    });
  }

  void processValue() {
    var value = inputElement.files;
    if (value != ngModel.viewValue) {
      scope.eval(() => ngModel.viewValue = value);
    }
    ngModel.validate();
  }
}

@Decorator(selector: '[ng-bind-html-unsafe]', map: const {
    'ng-bind-html-unsafe': '=>value'
})
class NgBindHtmlUnsafeDirective {
  final Element element;

  NgBindHtmlUnsafeDirective(this.element);

  set value(value) => element.setInnerHtml(value == null ? '' : value.toString(), validator: new NodeValidatorBuilder()
    ..allowHtml5()
    ..allowImages()
    ..allowNavigation(new _PermissiveUriPolicy())
    ..allowInlineStyles()
    ..allowTextElements()
    ..allowElement('a', attributes: ['href'])
    ..allowElement('img', attributes: ['src']));
}

/**
 * Allows any http/https/mailto/tel URIs
 */
class _PermissiveUriPolicy implements UriPolicy {

  bool allowsUri(String uriString) {
    Uri uri = Uri.parse(uriString);
    List<String> allowedProtocols = ['http', 'https', 'mailto', 'tel'];
    if (uri.scheme == null)return true;
    for (String protocol in allowedProtocols) {
      if (protocol == uri.scheme)return true;
    }
    return false;
  }
}


@Decorator(selector: '[absolutify][ng-bind-html-unsafe]', map: const {
    'ng-bind-html-unsafe': '=>newHtml'
})
class AbsolutifyDirective {
  final Element element;
  List<String> allowedLinkPrefixes = ['http://', 'https://', 'mailto://', 'tel://', '/'];
  Map<String, String> itemsToCheck = {
      'a':'href', 'img':'src'
  };

  AbsolutifyDirective(this.element);

  set newHtml(value) {
    if (value != null) {
      //timer necessary due to http://code.google.com/p/dart/issues/detail?id=16574
//      new Timer(new Duration(milliseconds:10), () {
      itemsToCheck.forEach((elementName, attrib) {
        for (Element el in element.querySelectorAll(elementName)) {
          if (!allowedLinkPrefixes.any((prefix) => el.attributes[attrib].startsWith(prefix))) {
            el.attributes[attrib] = '/${el.attributes[attrib]}';
          }
        }
      });
      //});
    }
  }
}


@Formatter(name: 'formatText')
class FormatText implements Function {
  call(String input) {
    if (input == null) return input;
    return input
    //replace possible line breaks.
    .replaceAll("\r\n", '<br/>').replaceAll("\r", '<br/>').replaceAll("\n", '<br/>')
    //replace tabs
    .replaceAll("\t", '&nbsp;&nbsp;&nbsp;')
    //replace spaces.
    .replaceAll(" ", '&ensp;');
  }
}

@Formatter(name: 'yesNo')
class YesNoFilter implements Function {
  call(value) {
    if (value is bool) {
      return value ? 'Ja' : 'Nein';
    }
    return value == 1 ? 'Ja' : 'Nein';
  }
}

@Decorator(selector: '[focus]')
class FocusDirective {
  Element element;

  FocusDirective(this.element) {
    element.focus();
  }
}

/**
 * https://github.com/angular/angular.dart/issues/335
 * https://github.com/angular/angular.dart/issues/864
 */
@Decorator(selector: 'a[externalLink]')
class ExternalLinkDirective {
  Element element;

  ExternalLinkDirective(this.element) {
    element.onClick.listen((Event event) {
      String target = "_SELF";
      if (isValidTarget()) {
        window.open(element.attributes["href"], element.attributes['target']);
      } else window.location.assign(element.attributes["href"]);
    });
  }

  bool isValidTarget() {
    return element.attributes.containsKey("target") && element.attributes['target'].toLowerCase() != '_self';
  }
}


/**
 * The ngShow directive shows or hides the given HTML element based on the
 * expression provided to the ngHide attribute. The element is shown or hidden
 * by changing the removing or adding the ng-hide CSS class onto the element.
 */
@Decorator(selector: '[fixModalHeight][ng-show]', map: const {
    'ng-show': '=>show'
})
class FixModalHeightDirective {
  final Element element;

  FixModalHeightDirective(this.element);

  set show(value) {
    if (toBool(value)) {
      //timer necessary due to http://code.google.com/p/dart/issues/detail?id=16574
      new Timer(new Duration(milliseconds:10), () {
        var header = element.querySelector(".modal-header");
        int maxH = (window.innerHeight - header.borderEdge.height - header.borderEdge.top * 2 - 10).round();
        element.querySelector('.modal_body').style.maxHeight = "${maxH}px";
      });
    }
  }
}

@Decorator(selector: '[toggleScrollbar][ng-show]', map: const {
    'ng-show': '=>show'
})
class HideScrollbarDirective {
  final Element element;

  HideScrollbarDirective(this.element);

  set show(value) {
    if (toBool(value)) {
      //timer necessary due to http://code.google.com/p/dart/issues/detail?id=16574
      new Timer(new Duration(milliseconds:10), () {
        querySelector('html').classes.add("disableScroll");
        querySelector('body').classes.add("disableScroll");
      });
    } else {
      new Timer(new Duration(milliseconds:10), () {
        querySelector('html').classes.remove("disableScroll");
        querySelector('body').classes.remove("disableScroll");
      });
    }
  }
}

void handleHttpErrorGeneric(ProgressEvent error) {
  if (error.currentTarget is HttpRequest) {
    HttpRequest req = error.currentTarget;
    switch (req.status) {
      case 401: //	Unauthorized 	Die Anfrage kann nicht ohne gültige Authentifizierung durchgeführt werden. Wie die Authentifizierung durchgeführt werden soll, wird im „WWW-Authenticate“-Header-Feld der Antwort übermittelt.
      case 403: //	Forbidden 	Die Anfrage wurde mangels Berechtigung des Clients nicht durchgeführt. Diese Entscheidung wurde – anders als im Fall des Statuscodes 401 – unabhängig von Authentifizierungsinformationen getroffen, auch etwa wenn eine als HTTPS konfigurierte URL nur mit HTTP aufgerufen wurde.
        window.alert("Der Server meldet: Fehlende Berechtigung!");
        break;
      case 404: //	Not Found 	Die angeforderte Ressource wurde nicht gefunden. Dieser Statuscode kann ebenfalls verwendet werden, um eine Anfrage ohne näheren Grund abzuweisen. Links, welche auf solche Fehlerseiten verweisen, werden auch als Tote Links bezeichnet.
        window.alert("Element nicht gefunden!");
        break;
      case 408: //	Request Time-out 	Innerhalb der vom Server erlaubten Zeitspanne wurde keine vollständige Anfrage des Clients empfangen.
        window.alert("Fehler durch Zeitüberschreitung!");
        break;

      case 400:// 	Bad Request 	Die Anfrage-Nachricht war fehlerhaft aufgebaut.
      case 402: //	Payment Required 	Übersetzt: Bezahlung benötigt. Dieser Status ist für zukünftige HTTP-Protokolle reserviert.
      case 405: //	Method Not Allowed 	Die Anfrage darf nur mit anderen HTTP-Methoden (zum Beispiel GET statt POST) gestellt werden. Gültige Methoden für die betreffende Ressource werden im „Allow“-Header-Feld der Antwort übermittelt.
      case 406: //	Not Acceptable 	Die angeforderte Ressource steht nicht in der gewünschten Form zur Verfügung. Gültige „Content-Type“-Werte können in der Antwort übermittelt werden.
      case 407: //	Proxy Authentication Required 	Analog zum Statuscode 401 ist hier zunächst eine Authentifizierung des Clients gegenüber dem verwendeten Proxy erforderlich. Wie die Authentifizierung durchgeführt werden soll, wird im „Proxy-Authenticate“-Header-Feld der Antwort übermittelt.
      case 409: //	Conflict 	Die Anfrage wurde unter falschen Annahmen gestellt. Im Falle einer PUT-Anfrage kann dies zum Beispiel auf eine zwischenzeitliche Veränderung der Ressource durch Dritte zurückgehen.
      case 410: //	Gone 	Die angeforderte Ressource wird nicht länger bereitgestellt und wurde dauerhaft entfernt.
      case 411: //	Length Required 	Die Anfrage kann ohne ein „Content-Length“-Header-Feld nicht bearbeitet werden.
      case 412: //	Precondition Failed 	Eine in der Anfrage übertragene Voraussetzung, zum Beispiel in Form eines „If-Match“-Header-Felds, traf nicht zu.
      case 413: //	Request Entity Too Large 	Die gestellte Anfrage war zu groß, um vom Server bearbeitet werden zu können. Ein „Retry-After“-Header-Feld in der Antwort kann den Client darauf hinweisen, dass die Anfrage eventuell zu einem späteren Zeitpunkt bearbeitet werden könnte.
      case 414: //	Request-URL Too Long 	Die URL der Anfrage war zu lang. Ursache ist oft eine Endlosschleife aus Redirects.
      case 415: //	Unsupported Media Type 	Der Inhalt der Anfrage wurde mit ungültigem oder nicht erlaubtem Medientyp übermittelt.
      case 416: //	Requested range not satisfiable 	Der angeforderte Teil einer Ressource war ungültig oder steht auf dem Server nicht zur Verfügung.
      case 417: //	Expectation Failed 	Verwendet im Zusammenhang mit einem „Expect“-Header-Feld. Das im „Expect“-Header-Feld geforderte Verhalten des Servers kann nicht erfüllt werden.
      case 418: //	I’m a teapot 	Dieser Code ist als Aprilscherz der IETF zu verstehen, welcher näher unter RFC 2324, Hyper Text Coffee Pot Control Protocol, beschrieben ist. Innerhalb eines scherzhaften Protokolls zum Kaffeekochen zeigt er an, dass fälschlicherweise eine Teekanne anstatt einer Kaffeekanne verwendet wurde. Dieser Statuscode ist allerdings kein Bestandteil von HTTP, sondern lediglich von HTCPCP[5] (Hyper Text Coffee Pot Control Protocol). Trotzdem ist dieser Scherz-Statuscode auf einigen Webseiten zu finden, real wird aber der Statuscode 200 gesendet.[6]
      case 420: //	Policy Not Fulfilled 	In W3C PEP (Working Draft 21. November 1997)[7] wird dieser Code vorgeschlagen, um mitzuteilen, dass eine Bedingung nicht erfüllt wurde.
      case 421: //	There are too many connections from your internet address 	Verwendet, wenn die Verbindungshöchstzahl überschritten wird. Ursprünglich wurde dieser Code in W3C PEP (Working Draft 21. November 1997)[7] vorgeschlagen, um auf den Fehler „Bad Mapping“ hinzuweisen.
      case 422: //	Unprocessable Entity 	Verwendet, wenn weder die Rückgabe von Statuscode 415 noch 400 gerechtfertigt wäre, eine Verarbeitung der Anfrage jedoch zum Beispiel wegen semantischer Fehler abgelehnt wird.[8]
      case 423: //	Locked 	Die angeforderte Ressource ist zurzeit gesperrt.[8]
      case 424: //	Failed Dependency 	Die Anfrage konnte nicht durchgeführt werden, weil sie das Gelingen einer vorherigen Anfrage voraussetzt.[8]
      case 425: //	Unordered Collection 	In den Entwürfen von WebDav Advanced Collections definiert, aber nicht im „Web Distributed Authoring and Versioning (WebDAV) Ordered Collections Protocol“.[8]
      case 426: //	Upgrade Required 	Der Client sollte auf Transport Layer Security (TLS/1.0) umschalten.[9]
      case 428: //	Precondition Required 	Für die Anfrage sind nicht alle Vorbedingungen erfüllt gewesen. Dieser Statuscode soll Probleme durch Race Conditions verhindern, indem eine Manipulation oder Löschen nur erfolgt, wenn der Client dies auf Basis einer aktuellen Ressource anfordert (Beispielsweise durch Mitliefern eines aktuellen ETag-Header).[10]
      case 429: //	Too Many Requests 	Der Client hat zu viele Anfragen in einem bestimmten Zeitraum gesendet.[10]
      case 431: //Request Header Fields Too Large 	Die Maximallänge eines Headerfelds oder des Gesamtheaders wurde überschritten
        window.alert("Anfrage fehlerhaft!");
        break;
      case 500: //	Internal Server Error 	Dies ist ein „Sammel-Statuscode“ für unerwartete Serverfehler.
      case 501: //	Not Implemented 	Die Funktionalität, um die Anfrage zu bearbeiten, wird von diesem Server nicht bereitgestellt. Ursache ist zum Beispiel eine unbekannte oder nicht unterstützte HTTP-Methode.
      case 502: //	Bad Gateway 	Der Server konnte seine Funktion als Gateway oder Proxy nicht erfüllen, weil er seinerseits eine ungültige Antwort erhalten hat.
      case 503: //	Service Unavailable 	Der Server steht temporär nicht zur Verfügung, zum Beispiel wegen Überlastung oder Wartungsarbeiten. Ein „Retry-After“-Header-Feld in der Antwort kann den Client auf einen Zeitpunkt hinweisen, zu dem die Anfrage eventuell bearbeitet werden könnte.
      case 504: //	Gateway Time-out 	Der Server konnte seine Funktion als Gateway oder Proxy nicht erfüllen, weil er innerhalb einer festgelegten Zeitspanne keine Antwort von seinerseits benutzten Servern oder Diensten erhalten hat.
      case 505: //	HTTP Version not supported 	Die benutzte HTTP-Version (gemeint ist die Zahl vor dem Punkt) wird vom Server nicht unterstützt oder abgelehnt.
      case 506: //	Variant Also Negotiates[13] 	Die Inhaltsvereinbarung der Anfrage ergibt einen Zirkelbezug.
      case 507: //	Insufficient Storage 	Die Anfrage konnte nicht bearbeitet werden, weil der Speicherplatz des Servers dazu zurzeit nicht mehr ausreicht.[8]
      case 508: //	Loop Detected 	Die Operation wurde nicht ausgeführt, weil die Ausführung in eine Endlosschleife gelaufen wäre. Definiert in der Binding-Erweiterung für WebDAV gemäß RFC 5842, weil durch Bindings zyklische Pfade zu WebDAV-Ressourcen entstehen können.
      case 509: //	Bandwidth Limit Exceeded 	Die Anfrage wurde verworfen, weil sonst die verfügbare Bandbreite überschritten würde (inoffizielle Erweiterung einiger Server).
      case 510: //	Not Extended 	Die Anfrage enthält nicht alle Informationen, die die angefragte Server-Extension zwingend erwartet.[14]
        window.alert("Serverfehler!");
    }
  } else window.alert("Es ist ein Fehler aufgetreten! " + error.currentTarget.toString());
}

class OptionItem {
  int id;
  String name;

  OptionItem(this.id, this.name);

  @override
  operator == (dynamic item){
    if (item is OptionItem) {
      return item.id == id && item.name == name;
    }
    return false;
  }

  @override
  int get hashCode {
    int result = 37;
    result = 13 * result + id.hashCode;
    result = 13 * result + name.hashCode;
    return result;
  }
}
