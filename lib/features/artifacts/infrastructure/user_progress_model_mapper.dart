import '../../../core/models/user_progress_model.dart';
import 'artifact_dto.dart';

UserProgressModel userProgressModelFromJson(Map<String, dynamic> json) {
  final progress = UserProgressDto.fromJson(json).toDomain();
  return UserProgressModel.fromDomain(progress);
}

Map<String, dynamic> userProgressModelToRow(UserProgressModel model) {
  return UserProgressDto.fromDomain(model).toRow();
}
