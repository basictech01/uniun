// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'followed_note_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFollowedNoteModelCollection on Isar {
  IsarCollection<FollowedNoteModel> get followedNoteModels => this.collection();
}

const FollowedNoteModelSchema = CollectionSchema(
  name: r'FollowedNote',
  id: -4140967884360152270,
  properties: {
    r'contentPreview': PropertySchema(
      id: 0,
      name: r'contentPreview',
      type: IsarType.string,
    ),
    r'eventId': PropertySchema(id: 1, name: r'eventId', type: IsarType.string),
    r'followedAt': PropertySchema(
      id: 2,
      name: r'followedAt',
      type: IsarType.dateTime,
    ),
    r'newReferenceCount': PropertySchema(
      id: 3,
      name: r'newReferenceCount',
      type: IsarType.long,
    ),
  },

  estimateSize: _followedNoteModelEstimateSize,
  serialize: _followedNoteModelSerialize,
  deserialize: _followedNoteModelDeserialize,
  deserializeProp: _followedNoteModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'eventId': IndexSchema(
      id: -2707901133518603130,
      name: r'eventId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'eventId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _followedNoteModelGetId,
  getLinks: _followedNoteModelGetLinks,
  attach: _followedNoteModelAttach,
  version: '3.3.2',
);

int _followedNoteModelEstimateSize(
  FollowedNoteModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.contentPreview.length * 3;
  bytesCount += 3 + object.eventId.length * 3;
  return bytesCount;
}

void _followedNoteModelSerialize(
  FollowedNoteModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.contentPreview);
  writer.writeString(offsets[1], object.eventId);
  writer.writeDateTime(offsets[2], object.followedAt);
  writer.writeLong(offsets[3], object.newReferenceCount);
}

FollowedNoteModel _followedNoteModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FollowedNoteModel();
  object.contentPreview = reader.readString(offsets[0]);
  object.eventId = reader.readString(offsets[1]);
  object.followedAt = reader.readDateTime(offsets[2]);
  object.id = id;
  object.newReferenceCount = reader.readLong(offsets[3]);
  return object;
}

P _followedNoteModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _followedNoteModelGetId(FollowedNoteModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _followedNoteModelGetLinks(
  FollowedNoteModel object,
) {
  return [];
}

void _followedNoteModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  FollowedNoteModel object,
) {
  object.id = id;
}

extension FollowedNoteModelByIndex on IsarCollection<FollowedNoteModel> {
  Future<FollowedNoteModel?> getByEventId(String eventId) {
    return getByIndex(r'eventId', [eventId]);
  }

  FollowedNoteModel? getByEventIdSync(String eventId) {
    return getByIndexSync(r'eventId', [eventId]);
  }

  Future<bool> deleteByEventId(String eventId) {
    return deleteByIndex(r'eventId', [eventId]);
  }

  bool deleteByEventIdSync(String eventId) {
    return deleteByIndexSync(r'eventId', [eventId]);
  }

  Future<List<FollowedNoteModel?>> getAllByEventId(List<String> eventIdValues) {
    final values = eventIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'eventId', values);
  }

  List<FollowedNoteModel?> getAllByEventIdSync(List<String> eventIdValues) {
    final values = eventIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'eventId', values);
  }

  Future<int> deleteAllByEventId(List<String> eventIdValues) {
    final values = eventIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'eventId', values);
  }

  int deleteAllByEventIdSync(List<String> eventIdValues) {
    final values = eventIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'eventId', values);
  }

  Future<Id> putByEventId(FollowedNoteModel object) {
    return putByIndex(r'eventId', object);
  }

  Id putByEventIdSync(FollowedNoteModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'eventId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEventId(List<FollowedNoteModel> objects) {
    return putAllByIndex(r'eventId', objects);
  }

  List<Id> putAllByEventIdSync(
    List<FollowedNoteModel> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'eventId', objects, saveLinks: saveLinks);
  }
}

extension FollowedNoteModelQueryWhereSort
    on QueryBuilder<FollowedNoteModel, FollowedNoteModel, QWhere> {
  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FollowedNoteModelQueryWhere
    on QueryBuilder<FollowedNoteModel, FollowedNoteModel, QWhereClause> {
  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterWhereClause>
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

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterWhereClause>
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

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterWhereClause>
  eventIdEqualTo(String eventId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'eventId', value: [eventId]),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterWhereClause>
  eventIdNotEqualTo(String eventId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventId',
                lower: [],
                upper: [eventId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventId',
                lower: [eventId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventId',
                lower: [eventId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventId',
                lower: [],
                upper: [eventId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension FollowedNoteModelQueryFilter
    on QueryBuilder<FollowedNoteModel, FollowedNoteModel, QFilterCondition> {
  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  contentPreviewEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'contentPreview',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  contentPreviewGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'contentPreview',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  contentPreviewLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'contentPreview',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  contentPreviewBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'contentPreview',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  contentPreviewStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'contentPreview',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  contentPreviewEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'contentPreview',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  contentPreviewContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'contentPreview',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  contentPreviewMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'contentPreview',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  contentPreviewIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'contentPreview', value: ''),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  contentPreviewIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'contentPreview', value: ''),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  eventIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'eventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  eventIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'eventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  eventIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'eventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  eventIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'eventId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  eventIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'eventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  eventIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'eventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  eventIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'eventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  eventIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'eventId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  eventIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'eventId', value: ''),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  eventIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'eventId', value: ''),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  followedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'followedAt', value: value),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  followedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'followedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  followedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'followedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  followedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'followedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
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

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
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

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
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

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  newReferenceCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'newReferenceCount', value: value),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  newReferenceCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'newReferenceCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  newReferenceCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'newReferenceCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterFilterCondition>
  newReferenceCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'newReferenceCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension FollowedNoteModelQueryObject
    on QueryBuilder<FollowedNoteModel, FollowedNoteModel, QFilterCondition> {}

extension FollowedNoteModelQueryLinks
    on QueryBuilder<FollowedNoteModel, FollowedNoteModel, QFilterCondition> {}

extension FollowedNoteModelQuerySortBy
    on QueryBuilder<FollowedNoteModel, FollowedNoteModel, QSortBy> {
  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterSortBy>
  sortByContentPreview() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentPreview', Sort.asc);
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterSortBy>
  sortByContentPreviewDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentPreview', Sort.desc);
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterSortBy>
  sortByEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.asc);
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterSortBy>
  sortByEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.desc);
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterSortBy>
  sortByFollowedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followedAt', Sort.asc);
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterSortBy>
  sortByFollowedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followedAt', Sort.desc);
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterSortBy>
  sortByNewReferenceCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newReferenceCount', Sort.asc);
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterSortBy>
  sortByNewReferenceCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newReferenceCount', Sort.desc);
    });
  }
}

extension FollowedNoteModelQuerySortThenBy
    on QueryBuilder<FollowedNoteModel, FollowedNoteModel, QSortThenBy> {
  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterSortBy>
  thenByContentPreview() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentPreview', Sort.asc);
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterSortBy>
  thenByContentPreviewDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentPreview', Sort.desc);
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterSortBy>
  thenByEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.asc);
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterSortBy>
  thenByEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.desc);
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterSortBy>
  thenByFollowedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followedAt', Sort.asc);
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterSortBy>
  thenByFollowedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followedAt', Sort.desc);
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterSortBy>
  thenByNewReferenceCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newReferenceCount', Sort.asc);
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QAfterSortBy>
  thenByNewReferenceCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newReferenceCount', Sort.desc);
    });
  }
}

extension FollowedNoteModelQueryWhereDistinct
    on QueryBuilder<FollowedNoteModel, FollowedNoteModel, QDistinct> {
  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QDistinct>
  distinctByContentPreview({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'contentPreview',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QDistinct>
  distinctByEventId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QDistinct>
  distinctByFollowedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'followedAt');
    });
  }

  QueryBuilder<FollowedNoteModel, FollowedNoteModel, QDistinct>
  distinctByNewReferenceCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'newReferenceCount');
    });
  }
}

extension FollowedNoteModelQueryProperty
    on QueryBuilder<FollowedNoteModel, FollowedNoteModel, QQueryProperty> {
  QueryBuilder<FollowedNoteModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FollowedNoteModel, String, QQueryOperations>
  contentPreviewProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contentPreview');
    });
  }

  QueryBuilder<FollowedNoteModel, String, QQueryOperations> eventIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventId');
    });
  }

  QueryBuilder<FollowedNoteModel, DateTime, QQueryOperations>
  followedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'followedAt');
    });
  }

  QueryBuilder<FollowedNoteModel, int, QQueryOperations>
  newReferenceCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'newReferenceCount');
    });
  }
}
