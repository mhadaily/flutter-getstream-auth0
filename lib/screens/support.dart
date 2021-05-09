import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mjcoffee/models/auth0_permissions.dart';
import 'package:mjcoffee/models/auth0_user.dart';
import 'package:mjcoffee/services/auth_service.dart';
import 'package:mjcoffee/services/chat_service.dart';
import 'package:mjcoffee/widgets/button.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ChatView extends StatefulWidget {
  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  String? availableCustomerServiceId;
  Auth0User? profile;

  @override
  void initState() {
    super.initState();
    profile = AuthService.instance.profile;
    getAvailableCustomerServer();
  }

  getAvailableCustomerServer() async {
    final String? id = ChatService.instance.currentCustomerServiceId;
    if (id != null) {
      setState(() {
        availableCustomerServiceId = id;
      });
    } else {
      final id = await AuthService.instance.availableCustomerService();
      setState(() {
        availableCustomerServiceId = id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return availableCustomerServiceId == null
        ? Center(
            child: Text('You are int he queue!, please wait...'),
          )
        : StreamChannel(
            channel: ChatService.instance
                .createSupportChat(availableCustomerServiceId),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: MessageListView(),
                ),
                MessageInput(
                  actions: [_closeChat()],
                  disableAttachments: !profile!.can(UserPermissions.upload),
                  sendButtonLocation: SendButtonLocation.inside,
                  actionsLocation: ActionsLocation.leftInside,
                  showCommandsButton: !profile?.isCustomer,
                ),
              ],
            ),
          );
  }

  CommonButton _closeChat() {
    return CommonButton(
      padding: EdgeInsets.all(0),
      onPressed: () {
        ChatService.instance.archiveSupportChat();
      },
      child: Icon(
        Icons.close,
        color: Colors.red,
      ),
    );
  }
}
