library partner;

import 'dart:html';
import 'dart:convert';
import 'dart:async';
import 'dartUtilLib.dart';
import 'package:angular/angular.dart';
import 'CommonEntityAdminLib.dart';

@Controller(selector: '[partner-admin]', publishAs: 'ctrl')
class PartnerAdminController {
  List<OptionItem> partners = new List();
  List<OptionItem> developers = new List();
  Set<OptionItem> partnerConnections = new Set();
  Set<OptionItem> developerConnections = new Set();
  List<OptionItem> states = new List();
  List<OptionItem> counties = new List();
  int _currentId;
  OptionItem currentCounty;
  List<OptionItem> categories = [
      new OptionItem(1,"Handwerk"),
      new OptionItem(2,"Dienstleistung"),
      new OptionItem(3,"Produkt- & Fachberatung"),
      new OptionItem(4,"Handel & Industrie")
  ];
  OptionItem initialDeveloper;

  MessageConfig messageConfig = new MessageConfig();

  get currentId => _currentId;
  set currentId(newId) {
    if(newId!=_currentId)initialDeveloper=null;
    if (newId != null) {
      if (newId is String)newId = int.parse(newId);
      _loadPartner(newId);
      _currentId = newId;
      _loadDeveloperConnections();
    } else {
      _resetForm(resetId:true);
    }
  }

  int _selectedState;

  get selectedState => _selectedState;

  set selectedState(int newState) {
    _selectedState = newState;
    currentCounty = null;
    _loadCountiesByState();
  }

  PartnerData currentPartner = new PartnerData();

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

  void _resetForm({resetId:false}) {
    if (resetId) {
      _currentId = null;
      currentPartner = new PartnerData();
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

  PartnerAdminController() {
    _loadPartnerList();
    _loadDeveloperList();
    _loadStates();
  }

  void addCounty() {
    partnerConnections.add(currentCounty);
  }

  void addDeveloper(OptionItem dev) {
    developerConnections.add(dev);
  }

  void removeDeveloper(OptionItem dev) {
    developerConnections.remove(dev);

  }

  void _statesLoaded(String dataString) {
    List<Map> data = JSON.decode(dataString);
    states.clear();
    data.forEach((Map map) {
      states.add(new OptionItem(int.parse(map['id']), map['name']));
    });

  }
  void _loadStates() {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=56";
    // call the web server asynchronously
    //HttpRequest.getString(url).then(_statesLoaded).catchError(handleHttpErrorGeneric);
    //Mock server
    new Timer(new Duration(milliseconds:10), () {
      _statesLoaded('[{"id":"13","name":"Baden-W\u00fcrttemberg"},{"id":"11","name":"Bayern"},{"id":"14","name":"Berlin"},{"id":"24","name":"Brandenburg"},{"id":"17","name":"Bremen"},{"id":"25","name":"Hamburg"},{"id":"23","name":"Hessen"},{"id":"19","name":"Mecklenburg-Vorpommern"},{"id":"12","name":"Niedersachsen"},{"id":"21","name":"Nordrhein-Westfalen"},{"id":"15","name":"Rheinland-Pfalz"},{"id":"16","name":"Saarland"},{"id":"18","name":"Sachsen"},{"id":"20","name":"Sachsen-Anhalt"},{"id":"10","name":"Schleswig-Holstein"},{"id":"22","name":"Th\u00fcringen"}]');
    });
  }


  void _loadPartnerList() {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=54";
    // call the web server asynchronously
    //HttpRequest.getString(url).then(_partnersLoaded).catchError(handleHttpErrorGeneric);
    //Mock server
    new Timer(new Duration(milliseconds:10), () {
      _partnersLoaded('[{"id":"65","name":"zzzzzzzzzzzzzzz"},{"id":"66","name":"ttttttttttttt"},{"id":"67","name":"ssssssssss"},{"id":"68","name":"uuuu"},{"id":"69","name":"fdsfdsfsd"},{"id":"70","name":"fdsfds"}]');
    });
  }

  void _loadDeveloperList() {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=53";
    // call the web server asynchronously
//    HttpRequest.getString(url).then(_developersLoaded).catchError(handleHttpErrorGeneric);
    //Mock server
    new Timer(new Duration(milliseconds:10), () {
      _developersLoaded('[{"id":"38","name":"1"},{"id":"39","name":"2"},{"id":"41","name":"4"},{"id":"42","name":"5"},{"id":"43","name":"gggggggggg"},{"id":"44","name":"gdgfdgsdfg"}]');
    });
  }

  void _loadPartnerConnections() {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=55&partnerId=${currentId}";
    // call the web server asynchronously
//    HttpRequest.getString(url).then((result)=>handleOptionItemResult(partnerConnections,result)).catchError(handleHttpErrorGeneric);
    //Mock server
    new Timer(new Duration(milliseconds:10), () {
      handleOptionItemResult(partnerConnections,'[]');
    });
  }

  void _loadDeveloperConnections() {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=34&partnerId=${currentId}";
    // call the web server asynchronously
//    HttpRequest.getString(url).then((result)=> handleOptionItemResult(developerConnections,result)).catchError(handleHttpErrorGeneric);
    //Mock server
    new Timer(new Duration(milliseconds:10), () {
      handleOptionItemResult(developerConnections,'[{"id":"23","name":"IQ-rrrr GmbH"},{"id":"42","name":"5fxf"}]');
    });
  }

  void _loadCountiesByState() {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput.php?type=11&stateId=${selectedState}";
    // call the web server asynchronously
    //HttpRequest.getString(url).then(_countiesLoaded).catchError(handleHttpErrorGeneric);
  }

  void _countiesLoaded(String dataString) {
    List<Map> data = JSON.decode(dataString);
    counties.clear();
    data.forEach((Map map) {
      counties.add(new OptionItem(int.parse(map['id']), map['name']));
    });

  }

  void removeConnection(OptionItem connection) {
    partnerConnections.remove(connection);
  }

  void savePartnerConnections() {
    FormData data = new FormData();
    data.append('type', '32');
    data.append('partnerId', currentPartner.id.toString());
    var list = new List();
    partnerConnections.forEach((OptionItem item) => list.add(item.id));
    data.append('zipCodeList', JSON.encode(list));

    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php";
    // call the web server asynchronously
    HttpRequest.request(url, method: 'POST', mimeType:"application/json", sendData: data).then(_partnerConnectionSaved).catchError((
        error) => _showFailedMessage());
  }

  void _partnerConnectionSaved(HttpRequest response) {
    _showPartnerConnectionSavedMessage();
  }

  void _showPartnerConnectionSavedMessage() {
    messageConfig.headerMessage = "Landkreis/e erfolgreich zugeordnet";
    messageConfig.message = "Der/die Landkreis/e wurde/n dem Werbepartner erfolgreich zugeordnet!";
    messageConfig.actions.clear();
    messageConfig.type = 'success';
    messageConfig.showMessage = true;
  }

  void saveDeveloperConnections() {
    FormData data = new FormData();
    data.append('type', '35');
    data.append('partnerId', currentPartner.id.toString());
    var list = new List();
    developerConnections.forEach((OptionItem item) => list.add(item.id));
    data.append('developerList', JSON.encode(list));

    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php";
    // call the web server asynchronously
    HttpRequest.request(url, method: 'POST', mimeType:"application/json", sendData: data).then(_developerConnectionSaved).catchError((
        error) => _showFailedMessage());
  }

  void _developerConnectionSaved(HttpRequest response) {
    _showConnectionSavedMessage();
  }

  void _showConnectionSavedMessage() {
    messageConfig.headerMessage = "Erfolgreich an Bauunternehmen geheftet";
    messageConfig.message = "Der/die Bauunternehmen wurde/n dem Werbepartner erfolgreich zugeordnet!";
    messageConfig.actions.clear();
    messageConfig.type = 'success';
    messageConfig.showMessage = true;
  }

  void _partnersLoaded(String dataString) {
    partners.clear();
    List<Map> data = JSON.decode(dataString);
    data.forEach((Map map) {
      partners.add(new OptionItem(int.parse(map['id']), map['name']));
    });
  }

  void _developersLoaded(String dataString) {
    developers.clear();
    List<Map> data = JSON.decode(dataString);
    data.forEach((Map map) {
      developers.add(new OptionItem(int.parse(map['id']), map['name']));
    });
  }

  void _loadPartner(int newId) {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=46&partnerId=${newId}";
    // call the web server asynchronously
//    var request = HttpRequest.getString(url).then(_partnerLoaded).catchError(handleHttpErrorGeneric);
    //Mock server
    new Timer(new Duration(milliseconds:10), () {
      _partnerLoaded('[{"id":"42","name":"FgfgdfgdfmbH","image":"\/modules\/mod_orchit_baumodul\/ajax\/getData.php?dataId=34","mail":"info@dachdeggdfr.de","uri":"http:\/\/www.dacgdfgdfr.de","tel":"+49 (0)44ffff 43","fax":"","description":"","paidAtTime":"0","lastEditFrom":"SQL","lastEditTime":"0","isGlobal":"0","mainCathegory":"0","subCathegory":"0","city":"Oldenburg","department":"Dachdecker","streetName":"Hoffftr.","streetNumber":"23","zipcode":"261435","mobile":"","dataId":"34","mainCategoryId":"1","deleted":"0","contactName":"Rgdfdfgster","contactEmail":"info@dachdgdfgfer.de","contactTelephone":"+49 (0)43 3 43","status":"0","availableStatuses":[{"id":0,"name":"Freigeschaltet"},{"id":1,"name":"Inaktiv"},{"id":2,"name":"Gel\u00f6scht"},{"id":4,"name":"Wartet auf Best\u00e4tigung"},{"id":8,"name":"Wartet auf Freischaltung"}]}]');
    });

  }

  void _partnerLoaded(String dataString) {
    List<Map> data = JSON.decode(dataString);
    _resetForm();
    if (data.length > 0) {
      data.forEach((Map map) {
        currentPartner = new PartnerData.fromMap(map);
        _loadPartnerConnections();
      });
    } else currentPartner = new PartnerData();
  }

  void save() {
    var formData = new FormData();
    if (currentPartner.id != null) {
      formData.append('id', currentPartner.id.toString());
      formData.append('type', 24.toString());
    } else {
      formData.append('type', 23.toString());
    }
    if (currentPartner.dataId != null) {
      formData.append('dataId', currentPartner.dataId.toString());
    }
    formData.append('name', currentPartner.name);
    formData.append('streetName', currentPartner.streetName);
    formData.append('streetNumber', currentPartner.streetNumber);
    formData.append('zipCode', currentPartner.zipCode);
    formData.append('city', currentPartner.city);
    formData.append('tel', currentPartner.telephone);
    formData.append('fax', currentPartner.fax);
    formData.append('mobile', currentPartner.mobile);
    formData.append('mail', currentPartner.mail);
    formData.append('status', currentPartner.status.toString());
    formData.append('uri', currentPartner.uri);
    if(initialDeveloper!=null)formData.append('initialDeveloper', initialDeveloper.id.toString());
    formData.append('department', currentPartner.department);
    formData.append('mainCategoryId', currentPartner.mainCategoryId.toString());
    formData.append('isGlobal', currentPartner.isGlobal?'1':'0');
    if (previewUrl != null)formData.append('file', previewUrl);
    formData.append('descr', currentPartner.description);
    formData.append('contactName', currentPartner.contactName);
    formData.append('contactTelephone', currentPartner.contactTelephone);
    formData.append('contactEmail', currentPartner.contactEmail);

    var url = "/modules/mod_orchit_baumodul/ajax/AjaxMultipartForm.php";
    // call the web server asynchronously
    HttpRequest.request(url, method: 'POST', sendData: formData).then(_partnerSaved).catchError((
        error) => _showFailedMessage());
  }

  void _partnerSaved(HttpRequest result) {
    _loadPartnerList();
    currentId = result.responseText;
    _showSavedMessage();
  }

  void _showSavedMessage() {
    messageConfig.headerMessage = "Erfolgreich gespeichert";
    messageConfig.message = "Der Werbepartner wurde erfolgreich gespeichert!";
    messageConfig.actions.clear();
    messageConfig.type = 'success';
    messageConfig.showMessage = true;
  }

  void _showFailedMessage() {
    messageConfig.headerMessage = "Fehler";
    messageConfig.message = "Beim Speichern des Werbepartners ist ein Fehler aufgetreten!";
    messageConfig.actions.clear();
    messageConfig.type = 'error';
    messageConfig.showMessage = true;
  }

  void hideMessage() {
    messageConfig.showMessage = false;
  }
}

class PartnerData {
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
  String department;
  String contactName;
  String contactTelephone;
  String contactEmail;
  bool isGlobal = false;
  int dataId;
  int linkId;
  int mainCategoryId;
  int status=4;
  List<OptionItem> availableStatuses=[new OptionItem(4,"Wartet auf Bestätigung")];


  PartnerData() {
  }

  PartnerData.fromMap(Map map){
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
    department = map['department'];
    isGlobal = map['isGlobal'] == '1';
    contactName = map['contactName'];
    contactTelephone = map['contactTelephone'];
    contactEmail = map['contactEmail'];
    status = int.parse(map['status']);
    availableStatuses = new List();
    List statuses = map['availableStatuses'];
    statuses.forEach(
            (Map mapItem)=>availableStatuses.add(new OptionItem(mapItem['id'],mapItem['name']))
    );
    if(map['mainCategoryId']!=null)mainCategoryId = int.parse(map['mainCategoryId']);
    if (map.containsKey('dataId'))dataId = int.parse(map['dataId']);
    if (map.containsKey('linkId'))linkId = int.parse(map['linkId']);
  }
}