import 'package:json_annotation/json_annotation.dart';
import 'package:mjcoffee/models/auth0_permissions.dart';
import 'package:mjcoffee/models/auth0_roles.dart';

part 'auth0_user.g.dart';

@JsonSerializable()
class Auth0User {
  Auth0User({
    required this.nickname,
    required this.name,
    required this.email,
    required this.picture,
    required this.updatedAt,
    required this.sub,
    required this.getStreamToken,
    required this.permissions,
    required this.roles,
  });

  // keep only digits
  String get id => '${sub.replaceAll(RegExp(r'[^\d]'), '')}';

  bool get hasImage => picture.isNotEmpty;

  bool can(String permission) => permissions
      .where(
        (p) => p.permissionName == permission,
      )
      .isNotEmpty;

  get isAdmin => roles.where((role) => role.name == Role.Admin).isNotEmpty;
  get isEmployee =>
      roles.where((role) => role.name == Role.Employee).isNotEmpty;
  get isCustomer =>
      roles.where((role) => role.name == Role.Customer).isNotEmpty;

  final String nickname;
  final String name;
  final String picture;

  @JsonKey(name: 'updated_at')
  final String updatedAt;

  final String sub;
  final String email;

  final String getStreamToken;
  final List<Auth0Permission> permissions;

  final List<Auth0Role> roles;

  factory Auth0User.fromJson(Map<String, dynamic> json) =>
      _$Auth0UserFromJson(json);

  Map<String, dynamic> toJson() => _$Auth0UserToJson(this);

  @override
  String toString() {
    return '''
        id: $id,
        nickname: $nickname,
        name: $name,
        email: $email,
        picture: $picture,
        updatedAt: $updatedAt,
        sub: $sub,
        getStreamToken: $getStreamToken,
        permissions: $permissions,
        roles: $roles,
        isEmployee: $isEmployee
        isCustomer: $isCustomer
        isAdmin: $isAdmin
      ''';
  }
}
