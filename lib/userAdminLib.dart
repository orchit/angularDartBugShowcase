library userAdmin;

import "dart:html";
import "dart:convert";
import "dart:async";
import 'dartUtilLib.dart';
import "package:angular/angular.dart";
import 'CommonEntityAdminLib.dart';

@Controller (selector:"[user-controller]", publishAs: "ctrl")
class UserAdminPage {
  final GETBYINPUT_ADMIN = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?";
  int _selectedDeveloper;
  int _messageDeveloper;
  int _selectedUser;
  bool showMessage = false;
  bool modifiedUsers = false;
  bool showCloseBtn = true;
  bool showModifiedBtns = false;
  bool protected = false;
  String messageHeadline;
  String messageContent;
  String messageClass;
  Developer developerInfo ;

  MessageConfig messageConfig = new MessageConfig();

  List<OptionItem> developers = new List();
  List<OptionItem> users = new List();
  ExtendedUser userInfo;

  String _userSearchTerm;
  Timer searchRequestTimer;

  get userSearchTerm => _userSearchTerm;

  set userSearchTerm(String newTerm) {
    _userSearchTerm = newTerm;
    updateSearchTerm();
  }

  Set<User> userList = new Set();

  get selectedUser => _selectedUser;

  set selectedUser(int newId) {
    _selectedUser = newId;
    if (newId == null) {
      userInfo = null;
    } else {
      HttpRequest.getString(GETBYINPUT_ADMIN + "type=5&userId=${newId}").then(_userData).catchError(handleHttpErrorGeneric);
    }
  }

  get selectedDeveloper => _selectedDeveloper;

  set selectedDeveloper(int newId) {
    if (modifiedUsers) {
      _messageDeveloper = newId;
      //FIXME: reset selected element when change is denied

      showModifiedMessage();
      return;
    }
    _selectedDeveloper = newId;
    if (newId == null) {
      developerInfo = null;
    } else {
      getDeveloperData(newId);
    }
  }

  void updateSearchTerm() {
    if (searchRequestTimer != null) {
      searchRequestTimer.cancel();
    }
    String newTerm = _userSearchTerm;
    if (newTerm == null || newTerm.isEmpty) {
      users.clear();
    } else {
      var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=50&term=" + Uri.encodeComponent(newTerm);
      // call the web server asynchronously
      searchRequestTimer = new Timer(new Duration(milliseconds:400), () {
        HttpRequest.getString(url).then(_usersLoaded).catchError(handleHttpErrorGeneric);
      });
    }
  }

  void getDeveloperData(newId) {
    HttpRequest.getString(GETBYINPUT_ADMIN + "type=7&devId=${newId}").then(_developerUserList).catchError(handleHttpErrorGeneric);
    HttpRequest.getString(GETBYINPUT_ADMIN + "type=6&devId=${newId}").then(_devData).catchError(handleHttpErrorGeneric);
  }

  UserAdminPage() {
    _loadDeveloperList();
    //userSearchTerm="";
  }

  void _loadDeveloperList() {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=53";
    // call the web server asynchronously
    var request = HttpRequest.getString(url).then(_developersLoaded).catchError(handleHttpErrorGeneric);
  }

  void _usersLoaded(String dataString) {
    users.clear();
    List<Map> data = JSON.decode(dataString);
    data.forEach((Map map) {
      users.add(new OptionItem(int.parse(map['id']), map['name']));
    });
  }

  void _developersLoaded(String dataString) {
    developers.clear();
    List<Map> data = JSON.decode(dataString);
    data.forEach((Map map) {
      developers.add(new OptionItem(int.parse(map['id']), map['name']));
    });
  }

  String time() {
    return new DateTime.now().toString();
  }

  void _developerUserList(String dataString) {
    List<Map> data = JSON.decode(dataString);
    userList.clear();
    data.forEach((Map input) {
      userList.add(new User.fromMap(input));
    });
  }

  void _devData(String dataString) {
    List<Map> data = JSON.decode(dataString);
    developerInfo = new Developer.fromMap(data[0]);
  }

  void _userData(String dataString) {
    List<Map> data = JSON.decode(dataString);
    userInfo = new ExtendedUser.fromMap(data[0]);

    users.clear();
  }

  void addUser() {
    userList.add(userInfo);
    modifiedUsers = true;
  }

  void dropUser(User user) {
    userList.remove(user);
    modifiedUsers = true;
  }

  List<int> userListToMap() {
    List result = new List();
    userList.forEach((User user) {
      result.add(user.id);
    });
    return result;
  }

  void saveList() {
    FormData data = new FormData();
    data.append("type", "8");
    data.append("developerId", selectedDeveloper.toString());

    data.append("userList", JSON.encode(userListToMap()));
    HttpRequest.request(GETBYINPUT_ADMIN, method : "POST", sendData: data).then((_) => showSuccessMessage()).catchError((_) => showFailureMessage());
  }

  void continueDevSelect() {
    messageConfig.showMessage = false;
    modifiedUsers = false;
    selectedDeveloper = _messageDeveloper;
    getDeveloperData(_selectedDeveloper);
  }

  void showModifiedMessage() {
    messageHeadline = 'Achtung!';
    messageContent = 'Es wurden Benutzer hinzugefügt oder entfernt. Möchten Sie ohne Speichern fortfahren?';
    messageClass = 'info';
    messageConfig.headerMessage = "Achtung!";
    messageConfig.message = "Es wurden Benutzer hinzugefügt oder entfernt. Möchten Sie ohne Speichern fortfahren?";
    messageConfig.actions.clear();
    Action yes = new Action();
    yes.caption = 'Ja';
    yes.actionHandler = continueDevSelect;
    messageConfig.actions.add(yes);
    Action no = new Action();
    no.caption = 'Nein';
    no.actionHandler = hideMessagePrevDev;
    messageConfig.actions.add(no);
    messageConfig.type = 'info';
    modified();
  }

  void showFailureMessage() {
    messageConfig.headerMessage = "Fehler beim Speichern";
    messageConfig.message = "Wenden Sie sich an den Administrator.";
    messageConfig.actions.clear();
    messageConfig.type = 'error';
    notModified();
  }

  void showSuccessMessage() {
    messageConfig.headerMessage = "Erfolgreich gespeichert";
    messageConfig.message = "Die Benutzer wurden dem Bauunternehmen zugeordnet.";
    messageConfig.actions.clear();
    messageConfig.type = 'success';
    notModified();
  }

  void hideMessagePrevDev() {
    messageConfig.showMessage = false;
    _messageDeveloper = null;
  }

  void hideMessage() {
    messageConfig.showMessage = false;
  }

  void modified() {
    showCloseBtn = false;
    showModifiedBtns = true;
    messageConfig.showMessage = true;
    modifiedUsers = false;
  }

  void notModified() {
    showCloseBtn = true;
    showModifiedBtns = false;
    messageConfig.showMessage = true;
    modifiedUsers = false;
  }

  void leaveUserList() {
    if (!protected)users.clear();
  }
}

@Controller (selector:"[sales-user-controller]", publishAs: "ctrl")
class SalesUserAdminPage {
  final GETBYINPUT_ADMIN = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?";
  int _selectedEntity;
  int _messageEntity;
  int _selectedUser;
  bool showMessage = false;
  bool modifiedUsers = false;
  bool showCloseBtn = true;
  bool showModifiedBtns = false;
  bool protected = false;
  String messageHeadline;
  String messageContent;
  String messageClass;
  OptionItem entityInfo ;

  MessageConfig messageConfig = new MessageConfig();

  List<OptionItem> entities = new List();
  List<OptionItem> users = new List();
  ExtendedUser userInfo;

  String _userSearchTerm;
  Timer searchRequestTimer;

  get userSearchTerm => _userSearchTerm;

  set userSearchTerm(String newTerm) {
    _userSearchTerm = newTerm;

    updateSearchTerm();
  }

  Set<User> userList = new Set();

  get selectedUser => _selectedUser;

  set selectedUser(int newId) {
    _selectedUser = newId;
    if (newId == null) {
      userInfo = null;
    } else {
      HttpRequest.getString(GETBYINPUT_ADMIN + "type=5&userId=${newId}").then(_userData).catchError(handleHttpErrorGeneric);
    }
  }

  get selectedEntity => _selectedEntity;

  set selectedEntity(int newId) {
    if (modifiedUsers) {
      _messageEntity = newId;
      //FIXME: reset selected element when change is denied

      showModifiedMessage();
      return;
    }
    _selectedEntity = newId;
    if (newId == null) {
      entityInfo = null;
    } else {
      getEntityData(newId);
    }
  }

  void updateSearchTerm() {
    if (searchRequestTimer != null) {
      searchRequestTimer.cancel();
    }
    String newTerm = _userSearchTerm;
    if (newTerm.isEmpty) {
      users.clear();
    } else {
      var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=50&term=" + Uri.encodeComponent(newTerm);
      // call the web server asynchronously
      searchRequestTimer = new Timer(new Duration(milliseconds:400), () {
        HttpRequest.getString(url).then(_usersLoaded).catchError(handleHttpErrorGeneric);
      });
    }
  }

  void getEntityData(newId) {
    HttpRequest.getString(GETBYINPUT_ADMIN + "type=52&entityId=${newId}").then(_entityUserList).catchError(handleHttpErrorGeneric);
    HttpRequest.getString(GETBYINPUT_ADMIN + "type=49&salesStructureId=${newId}").then(_entityData).catchError(handleHttpErrorGeneric);
  }

  SalesUserAdminPage() {
    _loadEntityList();
    userSearchTerm = "";
  }

  void _loadEntityList() {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=48";
    // call the web server asynchronously
    var request = HttpRequest.getString(url).then(_entitiesLoaded).catchError(handleHttpErrorGeneric);
  }

  void _usersLoaded(String dataString) {
    users.clear();
    List<Map> data = JSON.decode(dataString);
    data.forEach((Map map) {
      users.add(new OptionItem(int.parse(map['id']), map['name']));
    });
  }

  void _entitiesLoaded(String dataString) {
    entities.clear();
    List<Map> data = JSON.decode(dataString);
    data.forEach((Map map) {
      entities.add(new OptionItem(int.parse(map['id']), map['name']));
    });
  }

  String time() {
    return new DateTime.now().toString();
  }

  void _entityUserList(String dataString) {
    List<Map> data = JSON.decode(dataString);
    userList.clear();
    data.forEach((Map input) {
      userList.add(new User.fromMap(input));
    });
  }

  void _entityData(String dataString) {
    List<Map> data = JSON.decode(dataString);
    entityInfo = new OptionItem(int.parse(data[0]['id']), data[0]['name']);
  }

  void _userData(String dataString) {
    List<Map> data = JSON.decode(dataString);
    userInfo = new ExtendedUser.fromMap(data[0]);

    users.clear();
  }

  void addUser() {
    userList.add(userInfo);
    modifiedUsers = true;
  }

  void dropUser(User user) {
    userList.remove(user);
    modifiedUsers = true;
  }

  List<int> userListToMap() {
    List result = new List();
    userList.forEach((User user) {
      result.add(user.id);
    });
    return result;
  }

  void saveList() {
    FormData data = new FormData();
    data.append("type", "51");
    data.append("entityId", selectedEntity.toString());

    data.append("userList", JSON.encode(userListToMap()));
    HttpRequest.request(GETBYINPUT_ADMIN, method : "POST", sendData: data).then((_) => showSuccessMessage()).catchError((_) => showFailureMessage());
  }

  void continueDevSelect() {
    showMessage = false;
    modifiedUsers = false;
    selectedEntity = _messageEntity;
    getEntityData(_selectedEntity);
  }

  void showModifiedMessage() {
    messageHeadline = 'Achtung!';
    messageContent = 'Es wurden Benutzer hinzugefügt oder entfernt. Möchten Sie ohne Speichern fortfahren?';
    messageClass = 'info';
    messageConfig.headerMessage = "Achtung!";
    messageConfig.message = "Es wurden Benutzer hinzugefügt oder entfernt. Möchten Sie ohne Speichern fortfahren?";
    messageConfig.actions.clear();
    Action yes = new Action();
    yes.caption = 'Ja';
    yes.actionHandler = continueDevSelect;
    messageConfig.actions.add(yes);
    Action no = new Action();
    no.caption = 'Nein';
    no.actionHandler = hideMessagePrevDev;
    messageConfig.actions.add(no);
    messageConfig.type = 'info';
    modified();
  }

  void showFailureMessage() {
    messageConfig.headerMessage = "Fehler beim Speichern";
    messageConfig.message = "Wenden Sie sich an den Administrator.";
    messageConfig.actions.clear();
    messageConfig.type = 'error';
    notModified();
  }

  void showSuccessMessage() {
    messageConfig.headerMessage = "Erfolgreich gespeichert";
    messageConfig.message = "Die Benutzer wurden dem Bauunternehmen zugeordnet.";
    messageConfig.actions.clear();
    messageConfig.type = 'success';
    notModified();
  }

  void hideMessagePrevDev() {
    messageConfig.showMessage = false;
    _messageEntity = null;
  }

  void hideMessage() {
    messageConfig.showMessage = false;
  }

  void modified() {
    showCloseBtn = false;
    showModifiedBtns = true;
    messageConfig.showMessage = true;
    modifiedUsers = false;
  }

  void notModified() {
    showCloseBtn = true;
    showModifiedBtns = false;
    messageConfig.showMessage = true;
    modifiedUsers = false;
  }

  void leaveUserList() {
    if (!protected)users.clear();
  }
}

class User {
  int id;
  String name;

  User(this.id, this.name);

  User.fromMap(Map input){
    id = int.parse(input['id']);
    name = input['name'];
  }

  @override
  operator == (User usr){
    if (usr is User) {
      return usr.id == id && usr.name == name;
    }
    return false;
  }

  @override
  int get hashCode {
    int result = 23;
    result = 11 * result + id.hashCode;
    result = 11 * result + name.hashCode;
    return result;
  }
}

class ExtendedUser extends User {
  String userName;
  String mail;

  ExtendedUser.fromMap(Map input):super.fromMap(input){
    userName = input['username'];
    mail = input['email'];
  }

  User toUser() {
    return new User(id, name);
  }
}

class Developer {
  int id;
  String name;
  String imageUrl;

  Developer.fromMap(Map input){
    id = int.parse(input['id']);
    name = input['name'];
    imageUrl = input['image'];
  }
}

