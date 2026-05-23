import '../../../core/models/user_model.dart';
import 'auth_dto.dart';

UserModel userModelFromJson(Map<String, dynamic> json) {
  final user = AuthUserDto.fromJson(json).toDomain();
  return UserModel.fromDomain(user);
}

Map<String, dynamic> userModelToJson(UserModel model) {
  return AuthUserDto.fromDomain(model).toJson();
}
