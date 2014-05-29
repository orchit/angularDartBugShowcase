library articles;

import "dart:html";
import "dart:async";
import "dart:convert";
import "dart:mirrors";
import "package:angular/angular.dart";
import 'dartUtilLib.dart';
import 'CommonEntityAdminLib.dart';

abstract class ArticleController {
  List<OptionItem> existingArticles = new List();
  List<OptionItem> contentList = new List();
  List<OptionItem> authorList = new List();

  int articleType;

  MessageConfig messageConfig = new MessageConfig();

  bool isDevPartner = true;

  int _selectedArticleId;

  get selectedArticleId => _selectedArticleId;

  set selectedArticleId(int id) {
    _selectedArticleId = id;
    if (id == null) {
      article = new Article();
      _loadAuthorList();
    } else _loadArticle();
  }

  Article article = new Article();

  ArticleContent articleContent;

  ArticleAuthor articleAuthor = new ArticleAuthor.empty();


  ArticleController(this.articleType) {
    _loadArticleList();
    _loadContentList();
    changeAuthorType();
  }

  void _loadArticleList() {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=39&articleType=${articleType}}";
    // call the web server asynchronously
    var request = HttpRequest.getString(url).then(_articlesLoaded).catchError((
        error) => window.alert(error.toString()));
  }

  void _articlesLoaded(String dataString) {
    existingArticles.clear();
    List<Map> data = JSON.decode(dataString);
    data.forEach((Map map) {
      existingArticles.add(new OptionItem(int.parse(map['id']), map['name']));
    });
  }

  String getAuthorTypeDescription() {
    if (article.authorType == 0)return "Bauunternehmen";
    return "Werbepartner";
  }

  void changeAuthorType() {
    article.authorId = null;
    new Timer(new Duration(milliseconds:30), () {
      if (article.authorType < 2) {
        _loadAuthorList();
      } else {
        changeAuthorId();
      }
    });
  }

  void _loadAuthorList() {
    int type = article.authorType == 0 ? 3 : 4;
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=${type}";
    // call the web server asynchronously
    var request = HttpRequest.getString(url).then(_authorsLoaded).catchError(handleHttpErrorGeneric);
  }

  void _authorsLoaded(String dataString) {
    authorList.clear();
    List<Map> data = JSON.decode(dataString);
    data.forEach((Map map) {
      authorList.add(new OptionItem(int.parse(map['id']), map['name']));
    });
  }

  void _loadContentList() {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=37&contentType=${articleType}";
    // call the web server asynchronously
    var request = HttpRequest.getString(url).then(_contentListLoaded).catchError((
        error) => window.alert(error.toString()));
  }

  void _contentListLoaded(String dataString) {
    contentList.clear();
    List<Map> data = JSON.decode(dataString);
    data.forEach((Map map) {
      contentList.add(new OptionItem(int.parse(map['id']), map['name']));
    });
  }

  void _loadArticle() {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=40&articleId=${_selectedArticleId}";
    // call the web server asynchronously
    var request = HttpRequest.getString(url).then(_articleLoaded).catchError(handleHttpErrorGeneric);
  }

  void _articleLoaded(String dataString) {
    article = new Article.fromMap(JSON.decode(dataString));
    changeAuthorId();
    _loadArticleContent();
    _loadAuthorList();
  }

  void saveArticle() {
    FormData data = new FormData();
    data.append("type", "38");
    if(article.id == null) data.append("articleId", '0');
    else data.append("articleId", article.id.toString());
    data.append("author", article.authorId.toString());
    data.append("authorType", article.authorType.toString());
    data.append("content", article.contentId.toString());
    data.append("articleType", articleType.toString());
    data.append("link", article.readMoreLink);
    HttpRequest.request("/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php", method : "POST", sendData: data).then((
        _) => showSuccessMessage()).catchError((_) => showFailureMessage());
  }

  void deleteArticle() {
    FormData data = new FormData();
    data.append("type", "41");
    data.append("articleId", article.id.toString());
    HttpRequest.request("/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php", method : "POST", sendData: data).then((
        _) => showDeleteSuccessMessage()).catchError((_) => showDeleteFailureMessage());
  }

  void showSuccessMessage() {
    _loadArticleList();

    messageConfig.headerMessage = "Erfolgreich gespeichert!";
    messageConfig.message = "Der Artikel wurde erfolgreich gespeichert.";
    messageConfig.actions.clear();
    messageConfig.type = 'success';
    messageConfig.showMessage = true;
  }

  void showFailureMessage() {
    messageConfig.headerMessage = "Fehler beim Speichern!";
    messageConfig.message = "Die markierten Felder müssen noch ausgefüllt werden.";
    messageConfig.actions.clear();
    messageConfig.type = 'error';
    messageConfig.showMessage = true;
  }

  void showDeleteSuccessMessage() {
    selectedArticleId = null;
    _loadArticleList();

    messageConfig.headerMessage = "Der Artikel wurde erfolgreich gelöscht!";
    messageConfig.message = "Die Daten gehen dabei nicht verloren.";
    messageConfig.actions.clear();
    messageConfig.type = 'success';
    messageConfig.showMessage = true;
  }

  void showDeleteFailureMessage() {
    messageConfig.headerMessage = "Fehler beim Löschen!";
    messageConfig.message = "Es ist ein Fehler beim Löschen aufgetreten.";
    messageConfig.actions.clear();
    messageConfig.type = 'error';
    messageConfig.showMessage = true;
  }

  void hideMessage() {
    messageConfig.showMessage = false;
  }

  void openDeleteMessage() {
    messageConfig.headerMessage = 'Wirklich löschen?';
    messageConfig.message = '';
    messageConfig.actions.clear();
    Action yes = new Action();
    yes.caption = 'Ja';
    yes.actionHandler = deleteArticle;
    messageConfig.actions.add(yes);
    Action no = new Action();
    no.caption = 'Nein';
    no.actionHandler = hideMessage;
    messageConfig.actions.add(no);
    messageConfig.type = 'info';
    messageConfig.showMessage = true;
  }

  void changeArticleContent() {
    new Timer(new Duration(milliseconds:10), () {
      _loadArticleContent();
    });
  }

  void _loadArticleContent() {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput_Admin.php?type=42&contentId=${article.contentId}";
    // call the web server asynchronously
    var request = HttpRequest.getString(url).then(_articleContentLoaded).catchError((
        error) => window.alert(error.toString()));
  }

  void _articleContentLoaded(String dataString) {
    List<Map> data = JSON.decode(dataString);
    data.forEach((Map map) {
      String message = map['message'];
      articleContent = new ArticleContent(map['title'], map['author'], message, map['start']);
    });
  }

  void changeAuthorId() {
    new Timer(new Duration(milliseconds:10), () {
      switch (article.authorType) {
        case 0:
          isDevPartner = true;
          _loadDeveloperAuthor();
          break;
        case 1:
          isDevPartner = true;
          _loadPartnerAuthor();
          break;
        case 2:
          isDevPartner = false;
          articleAuthor = new ArticleAuthor('BAUmyHAUS', '', '', '', '', '', '', 'http://www.baumyhaus.de', '/modules/mod_orchit_baumodul/images/baumyhaus_logo_mail.png');
          break;
        case 3:
          isDevPartner = false;
          articleAuthor = new ArticleAuthor('X-OPTIMAX-Media GmbH', '', '', '', '', '', '', 'http://www.x-optimax.de', '/modules/mod_orchit_baumodul/images/developer/xoptimax.png');
          break;
      }
    });
  }

  void _loadDeveloperAuthor() {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput.php?type=19&developerId=${article.authorId}";
    // call the web server asynchronously
    var request = HttpRequest.getString(url).then(_authorLoaded).catchError(handleHttpErrorGeneric);
  }

  void _loadPartnerAuthor() {
    var url = "/modules/mod_orchit_baumodul/ajax/getByInput.php?type=15&partnerId=${article.authorId}";
    // call the web server asynchronously
    var request = HttpRequest.getString(url).then(_authorLoaded).catchError(handleHttpErrorGeneric);
  }

  void _authorLoaded(String dataString) {
    List<Map> data = JSON.decode(dataString);
    data.forEach((Map map) {
      articleAuthor = new ArticleAuthor(map['name'], map['streetName'], map['streetNumber'], map['zipcode'], map['city'], map['tel'], map['mail'], map['uri'], map['image']);
    });
  }
}


class Article {
  int id;
  int authorType = 0;
  int authorId = null;
  int contentId;
  String readMoreLink;

  Article() {
  }

  Article.fromMap(Map data){
    id = int.parse(data['id']);
    authorType = int.parse(data['authorType']);
    if (data.containsKey('author')) {
      authorId = int.parse(data['author']);
    }
    contentId = int.parse(data['contentId']);
    readMoreLink = data['link'];
  }

  bool needsAuthor() {
    return authorType < 2;
  }

  bool isInvalid() {
    return needsAuthor() && authorId == null;
  }

  bool hasReadMoreLink() {
    return readMoreLink != '' && readMoreLink != null;
  }
}

class ArticleContent {
  String title;
  String author;
  String message;
  String start;

  ArticleContent(this.title, this.author, this.message, this.start);

  bool hasAuthor() {
    return author != '' && author != null;
  }
}

class ArticleAuthor {
  String name;
  String streetName;
  String streetNumber;
  String zipcode;
  String city;
  String tel;
  String mail;
  String uri;
  String image = '/modules/mod_orchit_baumodul/images/dummy-logo.jpg';

  ArticleAuthor(this.name, this.streetName, this.streetNumber, this.zipcode, this.city, this.tel, this.mail, this.uri,
                this.image);
  ArticleAuthor.empty();

  bool hasAddress() {
    return zipcode != '' && city != '';
  }

  bool hasTelephone() {
    return tel != '';
  }

  bool hasMailUri() {
    return mail != '' && uri != '';
  }
}