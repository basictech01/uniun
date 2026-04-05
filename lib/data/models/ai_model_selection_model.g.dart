// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_model_selection_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAIModelSelectionModelCollection on Isar {
  IsarCollection<AIModelSelectionModel> get aIModelSelectionModels =>
      this.collection();
}

const AIModelSelectionModelSchema = CollectionSchema(
  name: r'AIModelSelection',
  id: -2992553459244753625,
  properties: {
    r'downloadedAt': PropertySchema(
      id: 0,
      name: r'downloadedAt',
      type: IsarType.dateTime,
    ),
    r'isActive': PropertySchema(id: 1, name: r'isActive', type: IsarType.bool),
    r'modelId': PropertySchema(
      id: 2,
      name: r'modelId',
      type: IsarType.string,
      enumMap: _AIModelSelectionModelmodelIdEnumValueMap,
    ),
    r'modelName': PropertySchema(
      id: 3,
      name: r'modelName',
      type: IsarType.string,
    ),
    r'modelPath': PropertySchema(
      id: 4,
      name: r'modelPath',
      type: IsarType.string,
    ),
  },

  estimateSize: _aIModelSelectionModelEstimateSize,
  serialize: _aIModelSelectionModelSerialize,
  deserialize: _aIModelSelectionModelDeserialize,
  deserializeProp: _aIModelSelectionModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'modelId': IndexSchema(
      id: -1910745378942518156,
      name: r'modelId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'modelId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'isActive': IndexSchema(
      id: 8092228061260947457,
      name: r'isActive',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isActive',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _aIModelSelectionModelGetId,
  getLinks: _aIModelSelectionModelGetLinks,
  attach: _aIModelSelectionModelAttach,
  version: '3.3.2',
);

int _aIModelSelectionModelEstimateSize(
  AIModelSelectionModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.modelId.name.length * 3;
  bytesCount += 3 + object.modelName.length * 3;
  bytesCount += 3 + object.modelPath.length * 3;
  return bytesCount;
}

void _aIModelSelectionModelSerialize(
  AIModelSelectionModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.downloadedAt);
  writer.writeBool(offsets[1], object.isActive);
  writer.writeString(offsets[2], object.modelId.name);
  writer.writeString(offsets[3], object.modelName);
  writer.writeString(offsets[4], object.modelPath);
}

AIModelSelectionModel _aIModelSelectionModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AIModelSelectionModel();
  object.downloadedAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.isActive = reader.readBool(offsets[1]);
  object.modelId =
      _AIModelSelectionModelmodelIdValueEnumMap[reader.readStringOrNull(
        offsets[2],
      )] ??
      AIModelId.qwen25_05b;
  object.modelName = reader.readString(offsets[3]);
  object.modelPath = reader.readString(offsets[4]);
  return object;
}

P _aIModelSelectionModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (_AIModelSelectionModelmodelIdValueEnumMap[reader.readStringOrNull(
                offset,
              )] ??
              AIModelId.qwen25_05b)
          as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _AIModelSelectionModelmodelIdEnumValueMap = {
  r'qwen25_05b': r'qwen25_05b',
  r'deepseekR1': r'deepseekR1',
  r'gemma4E2b': r'gemma4E2b',
  r'gemma4E4b': r'gemma4E4b',
};
const _AIModelSelectionModelmodelIdValueEnumMap = {
  r'qwen25_05b': AIModelId.qwen25_05b,
  r'deepseekR1': AIModelId.deepseekR1,
  r'gemma4E2b': AIModelId.gemma4E2b,
  r'gemma4E4b': AIModelId.gemma4E4b,
};

Id _aIModelSelectionModelGetId(AIModelSelectionModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _aIModelSelectionModelGetLinks(
  AIModelSelectionModel object,
) {
  return [];
}

void _aIModelSelectionModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  AIModelSelectionModel object,
) {
  object.id = id;
}

extension AIModelSelectionModelByIndex
    on IsarCollection<AIModelSelectionModel> {
  Future<AIModelSelectionModel?> getByModelId(AIModelId modelId) {
    return getByIndex(r'modelId', [modelId]);
  }

  AIModelSelectionModel? getByModelIdSync(AIModelId modelId) {
    return getByIndexSync(r'modelId', [modelId]);
  }

  Future<bool> deleteByModelId(AIModelId modelId) {
    return deleteByIndex(r'modelId', [modelId]);
  }

  bool deleteByModelIdSync(AIModelId modelId) {
    return deleteByIndexSync(r'modelId', [modelId]);
  }

  Future<List<AIModelSelectionModel?>> getAllByModelId(
    List<AIModelId> modelIdValues,
  ) {
    final values = modelIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'modelId', values);
  }

  List<AIModelSelectionModel?> getAllByModelIdSync(
    List<AIModelId> modelIdValues,
  ) {
    final values = modelIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'modelId', values);
  }

  Future<int> deleteAllByModelId(List<AIModelId> modelIdValues) {
    final values = modelIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'modelId', values);
  }

  int deleteAllByModelIdSync(List<AIModelId> modelIdValues) {
    final values = modelIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'modelId', values);
  }

  Future<Id> putByModelId(AIModelSelectionModel object) {
    return putByIndex(r'modelId', object);
  }

  Id putByModelIdSync(AIModelSelectionModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'modelId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByModelId(List<AIModelSelectionModel> objects) {
    return putAllByIndex(r'modelId', objects);
  }

  List<Id> putAllByModelIdSync(
    List<AIModelSelectionModel> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'modelId', objects, saveLinks: saveLinks);
  }
}

extension AIModelSelectionModelQueryWhereSort
    on QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QWhere> {
  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterWhere>
  anyIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isActive'),
      );
    });
  }
}

extension AIModelSelectionModelQueryWhere
    on
        QueryBuilder<
          AIModelSelectionModel,
          AIModelSelectionModel,
          QWhereClause
        > {
  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterWhereClause>
  modelIdEqualTo(AIModelId modelId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'modelId', value: [modelId]),
      );
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterWhereClause>
  modelIdNotEqualTo(AIModelId modelId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'modelId',
                lower: [],
                upper: [modelId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'modelId',
                lower: [modelId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'modelId',
                lower: [modelId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'modelId',
                lower: [],
                upper: [modelId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterWhereClause>
  isActiveEqualTo(bool isActive) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'isActive', value: [isActive]),
      );
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterWhereClause>
  isActiveNotEqualTo(bool isActive) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isActive',
                lower: [],
                upper: [isActive],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isActive',
                lower: [isActive],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isActive',
                lower: [isActive],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isActive',
                lower: [],
                upper: [isActive],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension AIModelSelectionModelQueryFilter
    on
        QueryBuilder<
          AIModelSelectionModel,
          AIModelSelectionModel,
          QFilterCondition
        > {
  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  downloadedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'downloadedAt', value: value),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  downloadedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'downloadedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  downloadedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'downloadedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  downloadedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'downloadedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isActive', value: value),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelIdEqualTo(AIModelId value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'modelId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelIdGreaterThan(
    AIModelId value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'modelId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelIdLessThan(
    AIModelId value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'modelId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelIdBetween(
    AIModelId lower,
    AIModelId upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'modelId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'modelId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'modelId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'modelId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'modelId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'modelId', value: ''),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'modelId', value: ''),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'modelName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'modelName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'modelName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'modelName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'modelName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'modelName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'modelName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'modelName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'modelName', value: ''),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'modelName', value: ''),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelPathEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'modelPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'modelPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'modelPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'modelPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'modelPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'modelPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'modelPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'modelPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'modelPath', value: ''),
      );
    });
  }

  QueryBuilder<
    AIModelSelectionModel,
    AIModelSelectionModel,
    QAfterFilterCondition
  >
  modelPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'modelPath', value: ''),
      );
    });
  }
}

extension AIModelSelectionModelQueryObject
    on
        QueryBuilder<
          AIModelSelectionModel,
          AIModelSelectionModel,
          QFilterCondition
        > {}

extension AIModelSelectionModelQueryLinks
    on
        QueryBuilder<
          AIModelSelectionModel,
          AIModelSelectionModel,
          QFilterCondition
        > {}

extension AIModelSelectionModelQuerySortBy
    on QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QSortBy> {
  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  sortByDownloadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedAt', Sort.asc);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  sortByDownloadedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedAt', Sort.desc);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  sortByModelId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.asc);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  sortByModelIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.desc);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  sortByModelName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.asc);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  sortByModelNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.desc);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  sortByModelPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelPath', Sort.asc);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  sortByModelPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelPath', Sort.desc);
    });
  }
}

extension AIModelSelectionModelQuerySortThenBy
    on QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QSortThenBy> {
  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  thenByDownloadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedAt', Sort.asc);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  thenByDownloadedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedAt', Sort.desc);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  thenByModelId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.asc);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  thenByModelIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.desc);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  thenByModelName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.asc);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  thenByModelNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.desc);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  thenByModelPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelPath', Sort.asc);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QAfterSortBy>
  thenByModelPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelPath', Sort.desc);
    });
  }
}

extension AIModelSelectionModelQueryWhereDistinct
    on QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QDistinct> {
  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QDistinct>
  distinctByDownloadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'downloadedAt');
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QDistinct>
  distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QDistinct>
  distinctByModelId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modelId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QDistinct>
  distinctByModelName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modelName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelSelectionModel, QDistinct>
  distinctByModelPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modelPath', caseSensitive: caseSensitive);
    });
  }
}

extension AIModelSelectionModelQueryProperty
    on
        QueryBuilder<
          AIModelSelectionModel,
          AIModelSelectionModel,
          QQueryProperty
        > {
  QueryBuilder<AIModelSelectionModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AIModelSelectionModel, DateTime, QQueryOperations>
  downloadedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'downloadedAt');
    });
  }

  QueryBuilder<AIModelSelectionModel, bool, QQueryOperations>
  isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<AIModelSelectionModel, AIModelId, QQueryOperations>
  modelIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modelId');
    });
  }

  QueryBuilder<AIModelSelectionModel, String, QQueryOperations>
  modelNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modelName');
    });
  }

  QueryBuilder<AIModelSelectionModel, String, QQueryOperations>
  modelPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modelPath');
    });
  }
}
