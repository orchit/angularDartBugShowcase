part of commonEntityAdmin;


@Component(selector: 'zipCodeAssignment', publishAs: 'cmp', cssUrl: 'packages/admin/zipCodeAssignment/style.css', templateUrl: 'packages/admin/zipCodeAssignment/zipCodeAssignment.html',  applyAuthorStyles:true)
class ZipCodeAssignmentComponent {
  List<OptionItem> counties = new List();
  List<OptionItem> states = new List();
  List<OptionItem> zipCodes = new List();
  List<OptionItem> selectedZipCodes = new List();
  List<OptionItem> connections = new List();
  MessageConfig messageConfig = new MessageConfig();
  @NgAttr("saveType")
  String saveType = "58";
  @NgAttr("getConnectionsType")
  String getConnectionsType = "59";
  int _parentId;

  int get parentId => _parentId;

  @NgOneWay("parentId")
  set parentId(newId) {
    if (newId == null || newId == '') {
      _parentId = null;
    } else if (newId is int) {
      _parentId = newId;
    } else {
      _parentId = int.parse(newId.toString());
    }
    _loadParentConnections();
  }

  String zipCodeSearchTerm;
  Timer searchTimer;

  int _selectedState;

  int get selectedState => _selectedState;

  set selectedState(int newState) {
    _selectedState = newState;
    _loadCountiesByState();
  }

  int _selectedCounty;

  int get selectedCounty => _selectedCounty;

  set selectedCounty(int newCounty) {
    _selectedCounty = newCounty;
    _loadZipCodesByCounty();
  }

  ZipCodeAssignmentComponent() {
    _loadStates();
  }

  void addZipCodes() {
    connections.addAll(selectedZipCodes);
  }

  void removeConnection(OptionItem connection) {
    connections.remove(connection);
  }

  void saveConnections() {
    FormData data = new FormData();
    data.append('type', saveType.toString());
    data.append('parentId', parentId.toString());
    var list = new List();
    connections.forEach((OptionItem item) => list.add(item.id));
    data.append('zipCodeList', JSON.encode(list));

    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php";
    HttpRequest.request(url, method: 'POST', mimeType:"application/json", sendData: data).then((_) {
      messageConfig.headerMessage="Erfolgreich gespeichert!";
      messageConfig.message="Verbindung über Postleitzahlen erfolgreich gespeichert.";
      messageConfig.actions.clear();
      messageConfig.type = 'success';
      messageConfig.showMessage=true;
    }).catchError(handleHttpErrorGeneric);
  }


  void _loadStates() {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=56";
    //HttpRequest.getString(url).then((String result) => handleOptionItemResult(states, result)).catchError(handleHttpErrorGeneric);
    //Mock server
    new Timer(new Duration(milliseconds:10), () {
      handleOptionItemResult(states,'[{"id":"13","name":"Baden-W\u00fcrttemberg"},{"id":"11","name":"Bayern"},{"id":"14","name":"Berlin"},{"id":"24","name":"Brandenburg"},{"id":"17","name":"Bremen"},{"id":"25","name":"Hamburg"},{"id":"23","name":"Hessen"},{"id":"19","name":"Mecklenburg-Vorpommern"},{"id":"12","name":"Niedersachsen"},{"id":"21","name":"Nordrhein-Westfalen"},{"id":"15","name":"Rheinland-Pfalz"},{"id":"16","name":"Saarland"},{"id":"18","name":"Sachsen"},{"id":"20","name":"Sachsen-Anhalt"},{"id":"10","name":"Schleswig-Holstein"},{"id":"22","name":"Th\u00fcringen"}]');
    });
  }

  void _loadCountiesByState() {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput.php?type=11&stateId=${selectedState}";
    //HttpRequest.getString(url).then((String result) => handleOptionItemResult(counties, result)).catchError(handleHttpErrorGeneric);
  }

  void _loadZipCodesByCounty() {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=57&countyId=${selectedCounty}";
    //HttpRequest.getString(url).then((String result) => handleOptionItemResult(zipCodes, result)).catchError(handleHttpErrorGeneric);
  }

  void _loadParentConnections() {
    selectedZipCodes.clear();
    if (parentId == null) {
      connections.clear();
      return;
    }
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=${getConnectionsType}&parentId=${parentId}";
   // HttpRequest.getString(url).then((String result) => handleOptionItemResult(connections, result)).catchError(handleHttpErrorGeneric);
  }

  void updateSearchTerm() {
    if (searchTimer != null && searchTimer.isActive)searchTimer.cancel();
    searchTimer = new Timer(new Duration(milliseconds:400), () {
      String value = this.zipCodeSearchTerm;
      if (value == null || value.isEmpty) {
        zipCodes.clear();
      } else {
        value = Uri.encodeFull(value);
        var url = "/modules/mod_orchit_baumodul/ajax/getByInput.php?type=38&searched=${value}";
        //HttpRequest.getString(url).then((String result) => handleOptionItemResult(zipCodes, result)).catchError(handleHttpError);
      }
    });
  }

  void handleHttpError(error) {
    if (error is Event) {
      Event event = error;
      print("Error Event: " + event.type + ((event.currentTarget != null) ? " " + event.currentTarget.toString() : ""));
    } else print("Error: " + error.toString());
  }
}
