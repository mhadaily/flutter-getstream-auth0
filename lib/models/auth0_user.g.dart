// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth0_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Auth0User _$Auth0UserFromJson(Map<String, dynamic> json) {
  return Auth0User(
    nickname: json['nickname'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    picture: json['picture'] as String,
    updatedAt: json['updated_at'] as String,
    sub: json['sub'] as String,
    getStreamToken: json['getStreamToken'] as String,
    permissions: (json['permissions'] as List<dynamic>)
        .map((e) => Auth0Permission.fromJson(e as Map<String, dynamic>))
        .toList(),
    roles: (json['roles'] as List<dynamic>)
        .map((e) => Auth0Role.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$Auth0UserToJson(Auth0User instance) => <String, dynamic>{
      'nickname': instance.nickname,
      'name': instance.name,
      'picture': instance.picture,
      'updated_at': instance.updatedAt,
      'sub': instance.sub,
      'email': instance.email,
      'getStreamToken': instance.getStreamToken,
      'permissions': instance.permissions,
      'roles': instance.roles,
    };
