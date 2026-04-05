// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_note_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSavedNoteModelCollection on Isar {
  IsarCollection<SavedNoteModel> get savedNoteModels => this.collection();
}

const SavedNoteModelSchema = CollectionSchema(
  name: r'SavedNote',
  id: 4936521837079823218,
  properties: {
    r'authorPubkey': PropertySchema(
      id: 0,
      name: r'authorPubkey',
      type: IsarType.string,
    ),
    r'content': PropertySchema(id: 1, name: r'content', type: IsarType.string),
    r'created': PropertySchema(
      id: 2,
      name: r'created',
      type: IsarType.dateTime,
    ),
    r'eTagRefs': PropertySchema(
      id: 3,
      name: r'eTagRefs',
      type: IsarType.stringList,
    ),
    r'eventId': PropertySchema(id: 4, name: r'eventId', type: IsarType.string),
    r'pTagRefs': PropertySchema(
      id: 5,
      name: r'pTagRefs',
      type: IsarType.stringList,
    ),
    r'replyToEventId': PropertySchema(
      id: 6,
      name: r'replyToEventId',
      type: IsarType.string,
    ),
    r'rootEventId': PropertySchema(
      id: 7,
      name: r'rootEventId',
      type: IsarType.string,
    ),
    r'savedAt': PropertySchema(
      id: 8,
      name: r'savedAt',
      type: IsarType.dateTime,
    ),
    r'sig': PropertySchema(id: 9, name: r'sig', type: IsarType.string),
    r'tTags': PropertySchema(id: 10, name: r'tTags', type: IsarType.stringList),
    r'type': PropertySchema(
      id: 11,
      name: r'type',
      type: IsarType.string,
      enumMap: _SavedNoteModeltypeEnumValueMap,
    ),
  },

  estimateSize: _savedNoteModelEstimateSize,
  serialize: _savedNoteModelSerialize,
  deserialize: _savedNoteModelDeserialize,
  deserializeProp: _savedNoteModelDeserializeProp,
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
    r'rootEventId': IndexSchema(
      id: 4630125266856525042,
      name: r'rootEventId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'rootEventId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'replyToEventId': IndexSchema(
      id: -8252228501288249794,
      name: r'replyToEventId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'replyToEventId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'savedAt': IndexSchema(
      id: -5998206549842823851,
      name: r'savedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'savedAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _savedNoteModelGetId,
  getLinks: _savedNoteModelGetLinks,
  attach: _savedNoteModelAttach,
  version: '3.3.2',
);

int _savedNoteModelEstimateSize(
  SavedNoteModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.authorPubkey.length * 3;
  bytesCount += 3 + object.content.length * 3;
  bytesCount += 3 + object.eTagRefs.length * 3;
  {
    for (var i = 0; i < object.eTagRefs.length; i++) {
      final value = object.eTagRefs[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.eventId.length * 3;
  bytesCount += 3 + object.pTagRefs.length * 3;
  {
    for (var i = 0; i < object.pTagRefs.length; i++) {
      final value = object.pTagRefs[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.replyToEventId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.rootEventId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sig.length * 3;
  bytesCount += 3 + object.tTags.length * 3;
  {
    for (var i = 0; i < object.tTags.length; i++) {
      final value = object.tTags[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.type.name.length * 3;
  return bytesCount;
}

void _savedNoteModelSerialize(
  SavedNoteModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.authorPubkey);
  writer.writeString(offsets[1], object.content);
  writer.writeDateTime(offsets[2], object.created);
  writer.writeStringList(offsets[3], object.eTagRefs);
  writer.writeString(offsets[4], object.eventId);
  writer.writeStringList(offsets[5], object.pTagRefs);
  writer.writeString(offsets[6], object.replyToEventId);
  writer.writeString(offsets[7], object.rootEventId);
  writer.writeDateTime(offsets[8], object.savedAt);
  writer.writeString(offsets[9], object.sig);
  writer.writeStringList(offsets[10], object.tTags);
  writer.writeString(offsets[11], object.type.name);
}

SavedNoteModel _savedNoteModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SavedNoteModel();
  object.authorPubkey = reader.readString(offsets[0]);
  object.content = reader.readString(offsets[1]);
  object.created = reader.readDateTime(offsets[2]);
  object.eTagRefs = reader.readStringList(offsets[3]) ?? [];
  object.eventId = reader.readString(offsets[4]);
  object.id = id;
  object.pTagRefs = reader.readStringList(offsets[5]) ?? [];
  object.replyToEventId = reader.readStringOrNull(offsets[6]);
  object.rootEventId = reader.readStringOrNull(offsets[7]);
  object.savedAt = reader.readDateTime(offsets[8]);
  object.sig = reader.readString(offsets[9]);
  object.tTags = reader.readStringList(offsets[10]) ?? [];
  object.type =
      _SavedNoteModeltypeValueEnumMap[reader.readStringOrNull(offsets[11])] ??
      NoteType.text;
  return object;
}

P _savedNoteModelDeserializeProp<P>(
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
      return (reader.readStringList(offset) ?? []) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringList(offset) ?? []) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringList(offset) ?? []) as P;
    case 11:
      return (_SavedNoteModeltypeValueEnumMap[reader.readStringOrNull(
                offset,
              )] ??
              NoteType.text)
          as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _SavedNoteModeltypeEnumValueMap = {
  r'text': r'text',
  r'image': r'image',
  r'link': r'link',
  r'reference': r'reference',
};
const _SavedNoteModeltypeValueEnumMap = {
  r'text': NoteType.text,
  r'image': NoteType.image,
  r'link': NoteType.link,
  r'reference': NoteType.reference,
};

Id _savedNoteModelGetId(SavedNoteModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _savedNoteModelGetLinks(SavedNoteModel object) {
  return [];
}

void _savedNoteModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  SavedNoteModel object,
) {
  object.id = id;
}

extension SavedNoteModelByIndex on IsarCollection<SavedNoteModel> {
  Future<SavedNoteModel?> getByEventId(String eventId) {
    return getByIndex(r'eventId', [eventId]);
  }

  SavedNoteModel? getByEventIdSync(String eventId) {
    return getByIndexSync(r'eventId', [eventId]);
  }

  Future<bool> deleteByEventId(String eventId) {
    return deleteByIndex(r'eventId', [eventId]);
  }

  bool deleteByEventIdSync(String eventId) {
    return deleteByIndexSync(r'eventId', [eventId]);
  }

  Future<List<SavedNoteModel?>> getAllByEventId(List<String> eventIdValues) {
    final values = eventIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'eventId', values);
  }

  List<SavedNoteModel?> getAllByEventIdSync(List<String> eventIdValues) {
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

  Future<Id> putByEventId(SavedNoteModel object) {
    return putByIndex(r'eventId', object);
  }

  Id putByEventIdSync(SavedNoteModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'eventId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEventId(List<SavedNoteModel> objects) {
    return putAllByIndex(r'eventId', objects);
  }

  List<Id> putAllByEventIdSync(
    List<SavedNoteModel> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'eventId', objects, saveLinks: saveLinks);
  }
}

extension SavedNoteModelQueryWhereSort
    on QueryBuilder<SavedNoteModel, SavedNoteModel, QWhere> {
  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhere> anySavedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'savedAt'),
      );
    });
  }
}

extension SavedNoteModelQueryWhere
    on QueryBuilder<SavedNoteModel, SavedNoteModel, QWhereClause> {
  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhereClause>
  eventIdEqualTo(String eventId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'eventId', value: [eventId]),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhereClause>
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

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhereClause>
  rootEventIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'rootEventId', value: [null]),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhereClause>
  rootEventIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'rootEventId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhereClause>
  rootEventIdEqualTo(String? rootEventId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'rootEventId',
          value: [rootEventId],
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhereClause>
  rootEventIdNotEqualTo(String? rootEventId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'rootEventId',
                lower: [],
                upper: [rootEventId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'rootEventId',
                lower: [rootEventId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'rootEventId',
                lower: [rootEventId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'rootEventId',
                lower: [],
                upper: [rootEventId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhereClause>
  replyToEventIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'replyToEventId', value: [null]),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhereClause>
  replyToEventIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'replyToEventId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhereClause>
  replyToEventIdEqualTo(String? replyToEventId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'replyToEventId',
          value: [replyToEventId],
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhereClause>
  replyToEventIdNotEqualTo(String? replyToEventId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'replyToEventId',
                lower: [],
                upper: [replyToEventId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'replyToEventId',
                lower: [replyToEventId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'replyToEventId',
                lower: [replyToEventId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'replyToEventId',
                lower: [],
                upper: [replyToEventId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhereClause>
  savedAtEqualTo(DateTime savedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'savedAt', value: [savedAt]),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhereClause>
  savedAtNotEqualTo(DateTime savedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'savedAt',
                lower: [],
                upper: [savedAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'savedAt',
                lower: [savedAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'savedAt',
                lower: [savedAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'savedAt',
                lower: [],
                upper: [savedAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhereClause>
  savedAtGreaterThan(DateTime savedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'savedAt',
          lower: [savedAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhereClause>
  savedAtLessThan(DateTime savedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'savedAt',
          lower: [],
          upper: [savedAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterWhereClause>
  savedAtBetween(
    DateTime lowerSavedAt,
    DateTime upperSavedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'savedAt',
          lower: [lowerSavedAt],
          includeLower: includeLower,
          upper: [upperSavedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SavedNoteModelQueryFilter
    on QueryBuilder<SavedNoteModel, SavedNoteModel, QFilterCondition> {
  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  authorPubkeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'authorPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  authorPubkeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'authorPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  authorPubkeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'authorPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  authorPubkeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'authorPubkey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  authorPubkeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'authorPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  authorPubkeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'authorPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  authorPubkeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'authorPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  authorPubkeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'authorPubkey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  authorPubkeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'authorPubkey', value: ''),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  authorPubkeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'authorPubkey', value: ''),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  contentEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  contentGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  contentLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  contentBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'content',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  contentStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  contentEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  contentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  contentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'content',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'content', value: ''),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'content', value: ''),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  createdEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'created', value: value),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  createdGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'created',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  createdLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'created',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  createdBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'created',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  eTagRefsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'eTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  eTagRefsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'eTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  eTagRefsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'eTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  eTagRefsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'eTagRefs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  eTagRefsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'eTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  eTagRefsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'eTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  eTagRefsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'eTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  eTagRefsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'eTagRefs',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  eTagRefsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'eTagRefs', value: ''),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  eTagRefsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'eTagRefs', value: ''),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  eTagRefsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'eTagRefs', length, true, length, true);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  eTagRefsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'eTagRefs', 0, true, 0, true);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  eTagRefsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'eTagRefs', 0, false, 999999, true);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  eTagRefsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'eTagRefs', 0, true, length, include);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  eTagRefsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'eTagRefs', length, include, 999999, true);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  eTagRefsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'eTagRefs',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
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

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
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

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
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

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
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

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
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

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
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

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
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

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
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

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  eventIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'eventId', value: ''),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  eventIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'eventId', value: ''),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
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

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
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

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  pTagRefsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'pTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  pTagRefsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  pTagRefsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  pTagRefsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pTagRefs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  pTagRefsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'pTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  pTagRefsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'pTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  pTagRefsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'pTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  pTagRefsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'pTagRefs',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  pTagRefsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pTagRefs', value: ''),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  pTagRefsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'pTagRefs', value: ''),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  pTagRefsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'pTagRefs', length, true, length, true);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  pTagRefsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'pTagRefs', 0, true, 0, true);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  pTagRefsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'pTagRefs', 0, false, 999999, true);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  pTagRefsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'pTagRefs', 0, true, length, include);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  pTagRefsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'pTagRefs', length, include, 999999, true);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  pTagRefsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'pTagRefs',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  replyToEventIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'replyToEventId'),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  replyToEventIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'replyToEventId'),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  replyToEventIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'replyToEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  replyToEventIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'replyToEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  replyToEventIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'replyToEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  replyToEventIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'replyToEventId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  replyToEventIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'replyToEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  replyToEventIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'replyToEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  replyToEventIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'replyToEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  replyToEventIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'replyToEventId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  replyToEventIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'replyToEventId', value: ''),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  replyToEventIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'replyToEventId', value: ''),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  rootEventIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'rootEventId'),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  rootEventIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'rootEventId'),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  rootEventIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'rootEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  rootEventIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'rootEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  rootEventIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'rootEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  rootEventIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'rootEventId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  rootEventIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'rootEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  rootEventIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'rootEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  rootEventIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'rootEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  rootEventIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'rootEventId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  rootEventIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'rootEventId', value: ''),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  rootEventIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'rootEventId', value: ''),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  savedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'savedAt', value: value),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  savedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'savedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  savedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'savedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  savedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'savedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  sigEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sig',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  sigGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sig',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  sigLessThan(String value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sig',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  sigBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sig',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  sigStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sig',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  sigEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sig',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  sigContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sig',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  sigMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sig',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  sigIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sig', value: ''),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  sigIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sig', value: ''),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  tTagsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'tTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  tTagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  tTagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  tTagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tTags',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  tTagsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'tTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  tTagsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'tTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  tTagsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'tTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  tTagsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'tTags',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  tTagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tTags', value: ''),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  tTagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'tTags', value: ''),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  tTagsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tTags', length, true, length, true);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  tTagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tTags', 0, true, 0, true);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  tTagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tTags', 0, false, 999999, true);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  tTagsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tTags', 0, true, length, include);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  tTagsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tTags', length, include, 999999, true);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  tTagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tTags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  typeEqualTo(NoteType value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  typeGreaterThan(
    NoteType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  typeLessThan(
    NoteType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  typeBetween(
    NoteType lower,
    NoteType upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'type',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  typeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  typeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'type',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterFilterCondition>
  typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'type', value: ''),
      );
    });
  }
}

extension SavedNoteModelQueryObject
    on QueryBuilder<SavedNoteModel, SavedNoteModel, QFilterCondition> {}

extension SavedNoteModelQueryLinks
    on QueryBuilder<SavedNoteModel, SavedNoteModel, QFilterCondition> {}

extension SavedNoteModelQuerySortBy
    on QueryBuilder<SavedNoteModel, SavedNoteModel, QSortBy> {
  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy>
  sortByAuthorPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorPubkey', Sort.asc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy>
  sortByAuthorPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorPubkey', Sort.desc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy> sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy>
  sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy> sortByCreated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created', Sort.asc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy>
  sortByCreatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created', Sort.desc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy> sortByEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.asc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy>
  sortByEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.desc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy>
  sortByReplyToEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyToEventId', Sort.asc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy>
  sortByReplyToEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyToEventId', Sort.desc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy>
  sortByRootEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rootEventId', Sort.asc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy>
  sortByRootEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rootEventId', Sort.desc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy> sortBySavedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedAt', Sort.asc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy>
  sortBySavedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedAt', Sort.desc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy> sortBySig() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sig', Sort.asc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy> sortBySigDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sig', Sort.desc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension SavedNoteModelQuerySortThenBy
    on QueryBuilder<SavedNoteModel, SavedNoteModel, QSortThenBy> {
  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy>
  thenByAuthorPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorPubkey', Sort.asc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy>
  thenByAuthorPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorPubkey', Sort.desc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy> thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy>
  thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy> thenByCreated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created', Sort.asc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy>
  thenByCreatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created', Sort.desc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy> thenByEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.asc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy>
  thenByEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.desc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy>
  thenByReplyToEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyToEventId', Sort.asc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy>
  thenByReplyToEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyToEventId', Sort.desc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy>
  thenByRootEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rootEventId', Sort.asc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy>
  thenByRootEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rootEventId', Sort.desc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy> thenBySavedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedAt', Sort.asc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy>
  thenBySavedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedAt', Sort.desc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy> thenBySig() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sig', Sort.asc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy> thenBySigDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sig', Sort.desc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension SavedNoteModelQueryWhereDistinct
    on QueryBuilder<SavedNoteModel, SavedNoteModel, QDistinct> {
  QueryBuilder<SavedNoteModel, SavedNoteModel, QDistinct>
  distinctByAuthorPubkey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'authorPubkey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QDistinct> distinctByContent({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QDistinct> distinctByCreated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'created');
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QDistinct> distinctByETagRefs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eTagRefs');
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QDistinct> distinctByEventId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QDistinct> distinctByPTagRefs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pTagRefs');
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QDistinct>
  distinctByReplyToEventId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'replyToEventId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QDistinct>
  distinctByRootEventId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rootEventId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QDistinct> distinctBySavedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'savedAt');
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QDistinct> distinctBySig({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sig', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QDistinct> distinctByTTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tTags');
    });
  }

  QueryBuilder<SavedNoteModel, SavedNoteModel, QDistinct> distinctByType({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }
}

extension SavedNoteModelQueryProperty
    on QueryBuilder<SavedNoteModel, SavedNoteModel, QQueryProperty> {
  QueryBuilder<SavedNoteModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SavedNoteModel, String, QQueryOperations>
  authorPubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'authorPubkey');
    });
  }

  QueryBuilder<SavedNoteModel, String, QQueryOperations> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<SavedNoteModel, DateTime, QQueryOperations> createdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'created');
    });
  }

  QueryBuilder<SavedNoteModel, List<String>, QQueryOperations>
  eTagRefsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eTagRefs');
    });
  }

  QueryBuilder<SavedNoteModel, String, QQueryOperations> eventIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventId');
    });
  }

  QueryBuilder<SavedNoteModel, List<String>, QQueryOperations>
  pTagRefsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pTagRefs');
    });
  }

  QueryBuilder<SavedNoteModel, String?, QQueryOperations>
  replyToEventIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'replyToEventId');
    });
  }

  QueryBuilder<SavedNoteModel, String?, QQueryOperations>
  rootEventIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rootEventId');
    });
  }

  QueryBuilder<SavedNoteModel, DateTime, QQueryOperations> savedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'savedAt');
    });
  }

  QueryBuilder<SavedNoteModel, String, QQueryOperations> sigProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sig');
    });
  }

  QueryBuilder<SavedNoteModel, List<String>, QQueryOperations> tTagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tTags');
    });
  }

  QueryBuilder<SavedNoteModel, NoteType, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}
