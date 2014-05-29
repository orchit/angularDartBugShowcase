library contacts;

import "dart:html";
import "dart:async";
import "dart:convert";
import "dart:mirrors";
import "package:angular/angular.dart";
import "dartUtilLib.dart";

@Controller (selector:"[devmail-controller]", publishAs: "ctrl")
class ContactsController {
  final GETBYINPUT_ADMIN = "/modules/mod_orchit_baumodul/ajax/getDeveloperMails.php?";

  List<Option> radioShowAll = [new Option("showall", "Ja"), new Option("filtered", "Nein")];
  List<Option> selectableMonths = [new Option("1", "Januar"), new Option("2", "Februar"), new Option("3", "März"), new Option("4", "April"), new Option("5", "Mai"), new Option("6", "Juni"), new Option("7", "Juli"), new Option("8", "August"), new Option("9", "September"), new Option("10", "Oktober"), new Option("11", "November"), new Option("12", "Dezember")];
  List<int> selectableYears = new List();
  List<ContactData> contactMails = new List();
  List<ContactData> filteredContactMails = new List();
  List<Filter> filterList = new List();
  List<Filter> availableFilters = new List();
  ContactData detailContact;

  String showAll = null;
  String sortByField = "created";
  bool sortAscending = true;
  String csvLinkData;

  /* dont show all mails, auto select this month */
  String selectedMonth = new DateTime.now().month.toString();

  /* auto select this month */
  String selectedYear = new DateTime.now().year.toString();

  Filter currentFilter;

  ContactsController() {
    int thisYear = new DateTime.now().year;
    ContactData.fieldDescriptions.forEach((description, field) {
      availableFilters.add(new Filter(description, field, this._updateFilteredList));
    });
    currentFilter = availableFilters[0];

    for (int i = 2014; i <= thisYear; i++) {
      selectableYears.add(i);
    }
    fetchMails();
    new Timer(new Duration(milliseconds:10), () {
      showAll = "filtered";
    });
  }

  void changeSortBy(String field) {
    if (sortByField == field) {
      sortAscending = !sortAscending;
    } else {
      sortByField = field;
      sortAscending = true;
    }
    _updateFilteredList();
  }

  void fetchMails() {
    String url = GETBYINPUT_ADMIN;
    if (showAll == 'filtered') {
      url += "month=${selectedMonth}&year=${selectedYear}";
    }
    HttpRequest.getString(url).then(_handleContactsResult).catchError(handleHttpErrorGeneric);
  }

  _updateFilteredList() {
    List copy = contactMails.where((element) {
      for (var i = 0; i < filterList.length; i++) {
        if (filterList[i].matches(element) == false) {
          return false;
        }
      }
      return true;
    }).toList();
    copy.sort((ContactData a, ContactData b) {
      String valA=a.getFieldByName(sortByField);
      String valB=b.getFieldByName(sortByField);
      int sortOrder = sortAscending ? 1 : -1;
      if (valA == null)return -1 * sortOrder;
      if (valB == null)return 1 * sortOrder;
      return valA.compareTo(valB) * sortOrder;
    });
    filteredContactMails = copy;
  }

  void addFilter(Filter filter) {
    filterList.add(filter);
    _updateFilteredList();
  }

  void removeFilter(Filter filter) {
    filterList.remove(filter);
    _updateFilteredList();
  }

  void openContactDetail(ContactData mail) {
    detailContact = mail;
  }

  void closeDetails() {
    detailContact = null;
  }

  void _handleContactsResult(String dataString) {
    List<Map> data = JSON.decode(dataString);
    contactMails.clear();
    data.forEach((Map input) {
      contactMails.add(new ContactData.fromMap(input));
    });
    _updateFilteredList();
  }

  void prepareExport() {
    String data = "";
    //create header
    data += "\"" + ContactData.fieldDescriptions.keys.join("\", \"") + '\"\n';
    //add data
    filteredContactMails.forEach((ContactData contact) {
      bool addComma = false;
      ContactData.fieldDescriptions.forEach((description, fieldName) {
        String fieldValue = contact.getFieldByName(fieldName);
        if (addComma)data += ", "; else addComma = true;
        //mask value
        fieldValue = fieldValue == null ? "" : fieldValue;
        fieldValue = fieldValue.replaceAll('"', '""');//replace " with ""!
        data += "\"${fieldValue}\"";
      });
      data += '\n';
    });
    data = new String.fromCharCode(UNICODE_BOM_CHARACTER_RUNE) + data;
    //important! otherwise we have problems with spaces, line endings etc.
    data = Uri.encodeFull(data);
    this.csvLinkData = "data:attachment/csv;charset=utf-8;content-disposition:attachment;filename=export.csv;download=export.csv,${data}";
  }
}

typedef

void FilterChangeHook();

class

Filter {
  String name, _value, field;
  FilterChangeHook hook;

  get value => _value;

  set value(val) {
    _value = val;
    hook();
  }

  Filter(this.name, this.field, FilterChangeHook this.hook);

  bool nullOrEmpty(String val) {
    return val == null || val.trim() == "";
  }

  bool matches(ContactData mail) {

    String fieldValue = mail.getFieldByName(field);

    if (nullOrEmpty(value)) {
      return nullOrEmpty(fieldValue);
    }
    if (!nullOrEmpty(value) && nullOrEmpty(fieldValue)) {
      return false;
    }
    return fieldValue.toLowerCase().contains(value.toLowerCase());
  }
}

class ContactData {
  String id, developerId, salutation, fullName, telephone, email, street, city, timeToBuild, placeToBuild, availability, comment, requestCallback, requestAppointment, hasBuildingGround, wantsNewsletter, getCopy, intermediary, intermediaryEmail, houseImageUrl, houseName, houseVariant, created, developer, link;

  static Map<String, String> fieldDescriptions = {
      "E-Mail Adresse":"email", "Bauort":"placeToBuild", "Voller Name":"fullName", "Telefon":"telephone", "Straße & HausNr.":"street", "PLZ & Ort":"city", "Baubeginn":"timeToBuild", "Rückruf erwünscht":"requestCallback", "Terminwunsch":"requestAppointment", "Bauplatz vorhanden":"hasBuildingGround", "Newsletter gewünscht":"wantsNewsletter", "Tippgeber":"intermediary", "Tippgeber E-Mail":"intermediaryEmail", "Abgesendet":"created", "Bauunternehmen":"developer", "Kommentar":"comment", "Erreichbarkeit":"availability", "Anrede":"salutation", "Hausname":"houseName", "Hausvariante":"houseVariant", "Hauslink":"link"
  };

  ContactData.fromMap(Map input){
    id = input['id'];
    developerId = input['developerId'];
    salutation = input['salutation'];
    fullName = input['fullName'];
    telephone = input['telephone'];
    email = input['email'];
    street = input['street'];
    city = input['city'];
    timeToBuild = input['timeToBuild'];
    placeToBuild = input['placeToBuild'];
    availability = input['availability'];
    comment = input['comment'];
    requestCallback = input['requestCallback'];
    requestAppointment = input['requestAppointment'];
    hasBuildingGround = input['hasBuildingGround'];
    wantsNewsletter = input['wantsNewsletter'];
    getCopy = input['getCopy'];
    intermediary = input['intermediary'];
    intermediaryEmail = input['intermediaryEmail'];
    houseImageUrl = input['houseImageUrl'];
    created = input['created'];
    link = input['link'];
    houseVariant = input['houseVariant'];
    houseName = input['houseName'];
    developer = input['developer'];
  }

  String getFieldByName(String name) {
    switch (name) {
      case "id":
        return id;
      case "developerId":
        return developerId;
      case "salutation":
        return salutation;
      case "fullName":
        return fullName;
      case "telephone":
        return telephone;
      case "email":
        return email;
      case "street":
        return street;
      case "city":
        return city;
      case "timeToBuild":
        return timeToBuild;
      case "placeToBuild":
        return placeToBuild;
      case "availability":
        return availability;
      case "comment":
        return comment;
      case "requestCallback":
        return requestCallback;
      case "requestAppointment":
        return requestAppointment;
      case "hasBuildingGround":
        return hasBuildingGround;
      case "wantsNewsletter":
        return wantsNewsletter;
      case "getCopy":
        return getCopy;
      case "intermediary":
        return intermediary;
      case "intermediaryEmail":
        return intermediaryEmail;
      case "houseImageUrl":
        return houseImageUrl;
      case "houseName":
        return houseName;
      case "houseVariant":
        return houseVariant;
      case "created":
        return created;
      case "developer":
        return developer;
      case "link":
        return link;
      default:
        print("ERROR: unknown field $name");
        return null;
    }
  }
}

class Option {
  String value, text;

  Option(this.value, this.text);
}
