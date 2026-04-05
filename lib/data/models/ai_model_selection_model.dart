import 'package:isar_community/isar.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';

part 'ai_model_selection_model.g.dart';

@Collection(ignore: {'copyWith'})
@Name('AIModelSelection')
class AIModelSelectionModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  @Enumerated(EnumType.name)
  late AIModelId modelId;

  late String modelName;

  /// Marker path — flutter_gemma manages actual file storage.
  late String modelPath;

  late DateTime downloadedAt;

  /// Only one row should have isActive = true at a time.
  @Index()
  late bool isActive;
}
