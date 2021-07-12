import 'package:mjcoffee/helpers/is_debug.dart';
import 'package:mjcoffee/models/auth0_user.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

const API_KEY = String.fromEnvironment('STREAM_API_KEY');

class ChatService {
  static final ChatService instance = ChatService._internal();

  factory ChatService() {
    return instance;
  }

  ChatService._internal();

  final StreamChatClient client = StreamChatClient(
    API_KEY,
    logLevel: isInDebugMode ? Level.INFO : Level.OFF,
  );

  Future<void> disconnect() {
    return client.disconnectUser(
      flushChatPersistence: true,
    );
  }

  String? _currentSupportChatId;
  String? currentCustomerServiceId;

  Future<Auth0User> connectUser(Auth0User? user) async {
    if (user == null) {
      throw Exception('User was not received');
    }
    print('connect user ${user.id}');

    await client.connectUser(
      User(
        id: user.id,
        extraData: {
          'image': user.picture,
          'name': user.name,
        },
      ),
      user.getStreamToken,
    );

    return user;
  }

  bool shouldCreateChat() {
    return currentCustomerServiceId == null &&
        client.state.user?.id != null &&
        _currentSupportChatId == null;
  }

  bool shouldReconnectChat() {
    return currentCustomerServiceId != null &&
        client.state.user?.id != null &&
        _currentSupportChatId != null;
  }

  Channel createSupportChat(String? customerServiceId) {
    if (shouldCreateChat()) {
      currentCustomerServiceId = customerServiceId;
      final userId = client.state.user?.id;

      final channel = client.channel(
        'support',
        // Stream will assign an ID automatically
        // id: '$userId$customerServiceId',
        extraData: {
          'name': 'MJCoffee Support',
          'members': [
            customerServiceId,
            userId,
          ]
        },
      );
      // channel.addMembers([
      //   customerServiceId,
      //   client.state.user!.id,
      // ]);
      channel.watch().then((_) => _currentSupportChatId = channel.id);
      return channel;
    }

    if (shouldReconnectChat()) {
      print(
        'connecting chat $_currentSupportChatId with $currentCustomerServiceId',
      );
      final userId = client.state.user?.id;

      final channel = client.channel(
        'support',
        id: _currentSupportChatId,
        extraData: {
          'name': 'MJCoffee Support',
          'members': [
            currentCustomerServiceId,
            userId,
          ]
        },
      );
      channel.watch();
      return channel;
    }

    return client.channel('messaging');
  }

  Future<void> archiveSupportChat() async {
    // client.channel('suppport', id: _currentSupportChatId).delete();
    // _currentSupportChatId = null;
    // currentCustomerServiceId = null;
  }

  Future<Channel> createCommunityChat(
    String id,
    String name,
    List<String> members,
  ) async {
    final channel = client.channel(
      'messaging',
      id: id,
      extraData: {
        'name': name,
        'members': [client.state.user?.id, ...members],
      },
    );
    await channel.watch();
    return channel;
  }
}
