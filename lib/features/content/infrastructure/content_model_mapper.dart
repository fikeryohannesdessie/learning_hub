import '../../../core/models/content_model.dart';
import '../domain/content_domain.dart';
import 'content_dto.dart';

ContentModel contentModelFromJson(Map<String, dynamic> json) {
  final content = ContentDto.fromJson(json).toDomain();
  return ContentModel.fromDomain(content);
}

Map<String, dynamic> contentModelToJson(LearningContent model) {
  return ContentDto.fromDomain(model).toJson();
}
