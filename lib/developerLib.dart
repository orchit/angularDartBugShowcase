library developer;

import 'dart:html';
import 'dart:convert';
import 'dartUtilLib.dart';
import 'dart:async';
import 'package:angular/angular.dart';
import 'CommonEntityAdminLib.dart';

@Controller(selector: '[developer-admin]', publishAs: 'devCtrl')
class DeveloperAdminController extends AbstractEntityAdminController {
  List<OptionItem> developers = new List();
  List<OptionItem> salesStructures = new List();
  List<PartnerConnectionItem> partnersForPremium = new List();
  List<PartnerConnectionItem> partnersForBoth = new List();
  int _currentId;

  get currentId => _currentId;

  MessageConfig messageConfig = new MessageConfig();

  bool showDeleteMessage = false;

  set currentId(newId) {
    if (newId != null) {
      if (newId is String)newId = int.parse(newId);
      _loadDeveloper(newId);
      _currentId = newId;
    } else {
      _resetForm(resetId:true);
    }
  }

  DeveloperData currentDeveloper = new DeveloperData();

  set images(List<File> images) {
    _images = images;
    if (images.length > 0) {
      _image = images[0];
      _updatePreviewImage();
    } else {
      _image = null;
      previewUrl = null;
    }
  }

  get images => _images;

  List<File> _images;
  File _image;
  String previewUrl;

  List<OptionItem> styles = [
      new OptionItem(1,"Massivbau"),
      new OptionItem(2,"Holzstäbewerk"),
      new OptionItem(3,"Gasbeton"),
      new OptionItem(4,"Holzbau")
  ];

  void _resetForm({resetId:false}) {
    if (resetId) {
      _currentId = null;
      currentDeveloper = new DeveloperData();
      if (salesStructures.length > 0) {
        currentDeveloper.salesStructureId = salesStructures[0].id;
      }
    }
    previewUrl = null;
    _images = null;
    _image = null;
  }

  get image => _image;

  void _updatePreviewImage() {
    var reader = new FileReader();
    reader.onLoad.listen((e) {
      previewUrl = e.target.result;
    });
    reader.readAsDataUrl(image);
  }

  DeveloperAdminController() {
    _loadDeveloperList();
    _loadSalesStructures();
  }

  void _loadPartnerList() {
    if (currentDeveloper.id == null) {
      partnersForBoth.clear();
      partnersForPremium.clear();
    } else {
      var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=60&developerId=${currentDeveloper.id}";
      HttpRequest.getString(url).then((String result) {
        List<Map> data = JSON.decode(result);
        partnersForBoth.clear();
        partnersForPremium.clear();
        data.forEach((Map map) {
          var optionItem = new PartnerConnectionItem(int.parse(map['id']), map['name'], map['showInNonPremium'] == '1');
          if (optionItem.showInNonPremium)partnersForBoth.add(optionItem); else partnersForPremium.add(optionItem);
        });
      }).catchError(handleHttpErrorGeneric);
    }
  }

  void _loadDeveloperList() {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=53";
    HttpRequest.getString(url).then((
        String result) => handleOptionItemResult(developers, result)).catchError(handleHttpErrorGeneric);
  }

  void _loadSalesStructures() {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=48";
    HttpRequest.getString(url).then(_saleStructuresLoaded).catchError(handleHttpErrorGeneric);
  }

  void _saleStructuresLoaded(String dataString) {
    List<Map> data = JSON.decode(dataString);
    salesStructures.clear();
    int bestId = null;
    data.forEach((Map map) {
      var optionItem = new OptionItem(int.parse(map['id']), map['name']);
      salesStructures.add(optionItem);
      //check if x-optimax is in the list and favor that
      if (bestId == null || bestId != 1)bestId = optionItem.id;
    });
    if (salesStructures.length > 0 && currentDeveloper.salesStructureId == null) {
      currentDeveloper.salesStructureId = bestId;
    }
  }

  void _loadDeveloper(int newId) {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=44&developerId=${newId}";
    var request = HttpRequest.getString(url).then((result) {
      List<Map> data = JSON.decode(result);
      _resetForm();
      if (data.length > 0) {
        data.forEach((Map map) {
          currentDeveloper = new DeveloperData.fromMap(map);
        });
      } else currentDeveloper = new DeveloperData();
      _loadPartnerList();
    }).catchError((error) => window.alert(error.toString()));
  }

  void updateConnections(){
    List<Map> result = new List();
    partnersForPremium.forEach((PartnerConnectionItem item){
      result.add({'partnerId':item.id,'showInNonPremium':0});
    });
    partnersForBoth.forEach((PartnerConnectionItem item){
      result.add({'partnerId':item.id,'showInNonPremium':1});
    });
    var formData = new FormData();
    formData.append('type', "61");
    formData.append('developerId', currentDeveloper.id.toString());
    formData.append('data', JSON.encode(result));
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php";
    HttpRequest.request(url, method: 'POST', sendData: formData).then((_)=>print("SUCCESS!")).catchError((
        error) => _showFailedMessage());
  }

  void save() {
    var formData = new FormData();
    if (currentDeveloper.id != null) {
      formData.append('id', currentDeveloper.id.toString());
      formData.append('type', 21.toString());
    } else {
      formData.append('type', 20.toString());
    }
    if (currentDeveloper.dataId != null) {
      formData.append('dataId', currentDeveloper.dataId.toString());
    }
    formData.append('name', currentDeveloper.name);
    formData.append('streetName', currentDeveloper.streetName);
    formData.append('streetNumber', currentDeveloper.streetNumber);
    formData.append('zipCode', currentDeveloper.zipCode);
    formData.append('city', currentDeveloper.city);
    formData.append('tel', currentDeveloper.telephone);
    formData.append('fax', currentDeveloper.fax);
    formData.append('mobile', currentDeveloper.mobile);
    formData.append('mail', currentDeveloper.mail);
    formData.append('uri', currentDeveloper.uri);
    formData.append('status', currentDeveloper.status.toString());
    formData.append('showGlobals', currentDeveloper.showGlobals ? "1" : "0");
    if (previewUrl != null)formData.append('file', previewUrl);
    formData.append('descr', currentDeveloper.description);
    formData.append('contactName', currentDeveloper.contactName);
    formData.append('contactTelephone', currentDeveloper.contactTelephone);
    formData.append('contactEmail', currentDeveloper.contactEmail);
    formData.append('style', currentDeveloper.style.toString());
    formData.append('salesStructureId', currentDeveloper.salesStructureId.toString());
    formData.append('salesStructureContactName', currentDeveloper.salesStructureContactName);
    formData.append('salesStructureContactEmail', currentDeveloper.salesStructureContactEmail);
    formData.append('salesStructureContactTelephone', currentDeveloper.salesStructureContactTelephone);

    var url = "/modules/mod_orchit_baumodul/ajax/AjaxMultipartForm.php";
    HttpRequest.request(url, method: 'POST', sendData: formData).then(_developerSaved).catchError((
        error) => _showFailedMessage());
  }

  void _developerSaved(HttpRequest result) {
    _loadDeveloperList();
    currentId = int.parse(result.responseText);
    _showSavedMessage();
  }

  void _showSavedMessage() {
    messageConfig.headerMessage = "Erfolgreich gespeichert";
    messageConfig.message = "Das Bauunternehmen wurde erfolgreich gespeichert!";
    messageConfig.actions.clear();
    messageConfig.type = 'success';
    messageConfig.showMessage = true;
  }

  void _showFailedMessage() {
    messageConfig.headerMessage = "Fehler";
    messageConfig.message = "Beim Speichern des Bauunternehmens ist ein Fehler aufgetreten!";
    messageConfig.actions.clear();
    messageConfig.type = 'error';
    messageConfig.showMessage = true;
  }

  void updateImage() {
    print("noes!");
  }
}

class PartnerConnectionItem extends OptionItem {
  bool showInNonPremium;

  PartnerConnectionItem(int id, String name, this.showInNonPremium):super(id, name);
}


class DeveloperData {
  int id;
  String name;
  String description;
  String streetName;
  String streetNumber;
  String zipCode;
  String city;
  String telephone;
  String fax;
  String mobile;
  String mail;
  String uri;
  String image;
  String contactName;
  String contactTelephone;
  String contactEmail;
  int salesStructureId;
  String salesStructureContactName;
  String salesStructureContactEmail;
  String salesStructureContactTelephone;
  int style;
  bool isGlobal = false;
  bool showGlobals = false;
  int dataId;
  int linkId;
  int status = 4;
  List<OptionItem> availableStatuses = [new OptionItem(4, "Wartet auf Bestätigung")];

  DeveloperData() {
  }

  DeveloperData.fromMap(Map map){
    id = int.parse(map['id']);
    name = map['name'];
    description = map['description'];
    streetName = map['streetName'];
    streetNumber = map['streetNumber'];
    zipCode = map['zipcode'];
    city = map['city'];
    telephone = map['tel'];
    mobile = map['mobile'];
    fax = map['fax'];
    mail = map['mail'];
    uri = map['uri'];
    image = map['image'];
    isGlobal = map['isGlobal'] == '1';
    showGlobals = map['showGlobals'] == '1';
    status = int.parse(map['status']);
    availableStatuses = new List();
    List statuses = map['availableStatuses'];
    statuses.forEach((Map mapItem) => availableStatuses.add(new OptionItem(mapItem['id'], mapItem['name'])));
    contactName = map['contactName'];
    contactTelephone = map['contactTelephone'];
    contactEmail = map['contactEmail'];
    salesStructureId = int.parse(map['salesStructureId']);
    salesStructureContactName = map['salesStructureContactName'];
    salesStructureContactEmail = map['salesStructureContactEmail'];
    salesStructureContactTelephone = map['salesStructureContactTelephone'];
    if(map['style']!=null)style = int.parse(map['style']);
    if (map.containsKey('dataId'))dataId = int.parse(map['dataId']);
    if (map.containsKey('linkId'))linkId = int.parse(map['linkId']);
  }
}