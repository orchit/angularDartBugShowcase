part of commonEntityAdmin;

typedef void MessageClickActionHandler();

class Action {
  String caption;
  MessageClickActionHandler actionHandler;
}

class MessageConfig {
  String headerMessage;
  String message;
  String type;
  bool showMessage = false;
  List<Action> actions = new List();
}

@Component(selector: 'messages', publishAs: 'cmp', templateUrl: 'packages/admin/messages/messages.html', applyAuthorStyles:true)
class MessagesComponent {
  @NgOneWay("config")
  MessageConfig config;

  void hideMessage() {
    config.showMessage = false;
  }

  void execute(Action action) {
    action.actionHandler();
  }
}
