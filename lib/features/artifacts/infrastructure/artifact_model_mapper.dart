import '../../../core/models/artifact_model.dart';
import 'artifact_dto.dart';

ArtifactModel artifactModelFromJson(Map<String, dynamic> json) {
  final artifact = ArtifactDto.fromJson(json).toDomain();
  return ArtifactModel.fromDomain(artifact);
}

Map<String, dynamic> artifactModelToJson(ArtifactModel model) {
  return ArtifactDto.fromDomain(model).toJson();
}

HeritageSectionModel heritageSectionModelFromJson(Map<String, dynamic> json) {
  final section = HeritageSectionDto.fromJson(json).toDomain();
  return HeritageSectionModel.fromDomain(section);
}

Map<String, dynamic> heritageSectionModelToJson(HeritageSectionModel model) {
  return HeritageSectionDto.fromDomain(model).toJson();
}

HeritagePartModel heritagePartModelFromJson(Map<String, dynamic> json) {
  final part = HeritagePartDto.fromJson(json).toDomain();
  return HeritagePartModel.fromDomain(part);
}

Map<String, dynamic> heritagePartModelToJson(HeritagePartModel model) {
  return HeritagePartDto.fromDomain(model).toJson();
}

ArtifactDetailModel artifactDetailModelFromJson(Map<String, dynamic> json) {
  final detail = ArtifactDetailDto.fromJson(json).toDomain();
  return ArtifactDetailModel.fromDomain(detail);
}

Map<String, dynamic> artifactDetailModelToJson(ArtifactDetailModel model) {
  return ArtifactDetailDto.fromDomain(model).toJson();
}

ArtifactContentItem artifactContentItemModelFromJson(Map<String, dynamic> json) {
  final item = ArtifactContentItemDto.fromJson(json).toDomain();
  return ArtifactContentItem.fromDomain(item);
}

Map<String, dynamic> artifactContentItemModelToJson(ArtifactContentItem model) {
  return ArtifactContentItemDto.fromDomain(model).toJson();
}

AnalysisModel analysisModelFromJson(Map<String, dynamic> json) {
  final analysis = AnalysisDto.fromJson(json).toDomain();
  return AnalysisModel.fromDomain(analysis);
}

Map<String, dynamic> analysisModelToJson(AnalysisModel model) {
  return AnalysisDto.fromDomain(model).toJson();
}

EvidenceModel evidenceModelFromJson(Map<String, dynamic> json) {
  final evidence = EvidenceDto.fromJson(json).toDomain();
  return EvidenceModel.fromDomain(evidence);
}

Map<String, dynamic> evidenceModelToJson(EvidenceModel model) {
  return EvidenceDto.fromDomain(model).toJson();
}

AnalysisResultModel analysisResultModelFromJson(Map<String, dynamic> json) {
  final result = AnalysisResultDto.fromJson(json).toDomain();
  return AnalysisResultModel.fromDomain(result);
}

Map<String, dynamic> analysisResultModelToJson(AnalysisResultModel model) {
  return AnalysisResultDto.fromDomain(model).toJson();
}
