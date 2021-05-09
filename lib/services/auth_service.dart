import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mjcoffee/models/auth0_id_token.dart';
import 'package:mjcoffee/models/auth0_user.dart';
import 'package:http/http.dart' as http;

const AUTH0_DOMAIN = 'mhadaily.eu.auth0.com';
const AUTH0_CLIENT_ID = 'WVxxKrTG6ostyBKFGQ43lNkb3ism8YoN';

const BUNDLE_IDENTIFIER = 'mj.coffee.app';
const AUTH0_REDIRECT_URI = '$BUNDLE_IDENTIFIER://login-callback';
const AUTH0_ISSUER = 'https://$AUTH0_DOMAIN';
const REFRESH_TOKEN_KEY = 'refresh_token';
const FIREBASE_BASE_API = 'us-central1-mj-coffee-9f1ef.cloudfunctions.net';

class AuthService {
  static final AuthService instance = AuthService._internal();

  factory AuthService() {
    return instance;
  }

  AuthService._internal();

  final FlutterAppAuth appAuth = FlutterAppAuth();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  Auth0User? profile;
  Auth0IdToken? idToken;
  String? auth0AccessToken;

  Future<bool> init() async {
    final storedRefreshToken = await secureStorage.read(key: REFRESH_TOKEN_KEY);
    print('storedRefreshToken $storedRefreshToken');
    if (storedRefreshToken == null) {
      return false;
    }

    try {
      final result = await appAuth.token(
        TokenRequest(
          AUTH0_CLIENT_ID,
          AUTH0_REDIRECT_URI,
          issuer: AUTH0_ISSUER,
          refreshToken: storedRefreshToken,
        ),
      );
      final String setResult = await setProfileAndIdToken(result);
      return setResult == 'Success';
    } catch (e, s) {
      print('error on refresh token: $e - stack: $s');
      logout();
      return false;
    }
  }

  Future<String> login() async {
    try {
      final authorizationTokenRequest = AuthorizationTokenRequest(
        AUTH0_CLIENT_ID, AUTH0_REDIRECT_URI,
        issuer: 'https://$AUTH0_DOMAIN',
        scopes: ['openid', 'profile', 'offline_access', 'email'],
        promptValues: [
          'login'
        ], // ignore any existing session; force interactive login prompt
      );

      final AuthorizationTokenResponse? result =
          await appAuth.authorizeAndExchangeCode(authorizationTokenRequest);

      return await setProfileAndIdToken(result);
    } on PlatformException {
      return 'User has cancelled or no internet!';
    } catch (e) {
      return 'Unkown Error!';
    }
  }

  Future<String> setProfileAndIdToken(result) async {
    final bool isValidResult =
        result != null && result.accessToken != null && result.idToken != null;

    if (isValidResult) {
      //
      print('idToken ${result.idToken}');
      //
      auth0AccessToken = result.accessToken;
      idToken = parseIdToken(result.idToken);
      profile = await getUserDetails(auth0AccessToken);

      await secureStorage.write(
        key: REFRESH_TOKEN_KEY,
        value: result.refreshToken,
      );

      return 'Success';
    } else {
      return 'Something is Wrong!';
    }
  }

  Future<bool> logout() async {
    await secureStorage.delete(key: REFRESH_TOKEN_KEY);

    final url = Uri.https(
      AUTH0_DOMAIN,
      '/v2/logout',
      {
        // 'client_id': AUTH0_CLIENT_ID,
        'federated': '',
      },
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $auth0AccessToken'},
    );

    print(
      'logout: ${response.request} ${response.statusCode} ${response.body}',
    );

    return response.statusCode == 200;
  }

  Auth0IdToken parseIdToken(String idToken) {
    final parts = idToken.split(r'.');
    assert(parts.length == 3);

    final Map<String, dynamic> json = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));

    return Auth0IdToken.fromJson(json);
  }

  Future<Auth0User> getUserDetails(String? accessToken) async {
    final url = Uri.https(
      FIREBASE_BASE_API,
      '/userProfile',
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    print('getUserDetails ${response.body}');

    if (response.statusCode == 200) {
      return Auth0User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get user details');
    }
  }

  Future<String> availableCustomerService() async {
    final url = Uri.https(
      FIREBASE_BASE_API,
      '/availableCustomerService',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return '${jsonDecode(response.body)}';
    } else {
      throw Exception('Failed to get user details');
    }
  }

  // Future<List<ChatUser>> getChatUsers() async {
  //   final result = await _client.queryUsers();
  //   final chatUsers = result.users
  //       .where((element) => element.id != _client.state.user.id)
  //       .map(
  //         (e) => ChatUser(
  //           id: e.id,
  //           name: e.name,
  //           image: e.extraData['image'],
  //         ),
  //       )
  //       .toList();
  //   return chatUsers;
  // }
}
