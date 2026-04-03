// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_queue_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEventQueueModelCollection on Isar {
  IsarCollection<EventQueueModel> get eventQueueModels => this.collection();
}

const EventQueueModelSchema = CollectionSchema(
  name: r'EventQueue',
  id: 8017143989177430287,
  properties: {
    r'enqueuedAt': PropertySchema(
      id: 0,
      name: r'enqueuedAt',
      type: IsarType.dateTime,
    ),
    r'eventId': PropertySchema(id: 1, name: r'eventId', type: IsarType.string),
    r'sentCount': PropertySchema(
      id: 2,
      name: r'sentCount',
      type: IsarType.long,
    ),
    r'serializedRelayMessage': PropertySchema(
      id: 3,
      name: r'serializedRelayMessage',
      type: IsarType.string,
    ),
  },

  estimateSize: _eventQueueModelEstimateSize,
  serialize: _eventQueueModelSerialize,
  deserialize: _eventQueueModelDeserialize,
  deserializeProp: _eventQueueModelDeserializeProp,
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

  getId: _eventQueueModelGetId,
  getLinks: _eventQueueModelGetLinks,
  attach: _eventQueueModelAttach,
  version: '3.3.2',
);

int _eventQueueModelEstimateSize(
  EventQueueModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.eventId.length * 3;
  bytesCount += 3 + object.serializedRelayMessage.length * 3;
  return bytesCount;
}

void _eventQueueModelSerialize(
  EventQueueModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.enqueuedAt);
  writer.writeString(offsets[1], object.eventId);
  writer.writeLong(offsets[2], object.sentCount);
  writer.writeString(offsets[3], object.serializedRelayMessage);
}

EventQueueModel _eventQueueModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EventQueueModel();
  object.enqueuedAt = reader.readDateTime(offsets[0]);
  object.eventId = reader.readString(offsets[1]);
  object.id = id;
  object.sentCount = reader.readLong(offsets[2]);
  object.serializedRelayMessage = reader.readString(offsets[3]);
  return object;
}

P _eventQueueModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _eventQueueModelGetId(EventQueueModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _eventQueueModelGetLinks(EventQueueModel object) {
  return [];
}

void _eventQueueModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  EventQueueModel object,
) {
  object.id = id;
}

extension EventQueueModelByIndex on IsarCollection<EventQueueModel> {
  Future<EventQueueModel?> getByEventId(String eventId) {
    return getByIndex(r'eventId', [eventId]);
  }

  EventQueueModel? getByEventIdSync(String eventId) {
    return getByIndexSync(r'eventId', [eventId]);
  }

  Future<bool> deleteByEventId(String eventId) {
    return deleteByIndex(r'eventId', [eventId]);
  }

  bool deleteByEventIdSync(String eventId) {
    return deleteByIndexSync(r'eventId', [eventId]);
  }

  Future<List<EventQueueModel?>> getAllByEventId(List<String> eventIdValues) {
    final values = eventIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'eventId', values);
  }

  List<EventQueueModel?> getAllByEventIdSync(List<String> eventIdValues) {
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

  Future<Id> putByEventId(EventQueueModel object) {
    return putByIndex(r'eventId', object);
  }

  Id putByEventIdSync(EventQueueModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'eventId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEventId(List<EventQueueModel> objects) {
    return putAllByIndex(r'eventId', objects);
  }

  List<Id> putAllByEventIdSync(
    List<EventQueueModel> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'eventId', objects, saveLinks: saveLinks);
  }
}

extension EventQueueModelQueryWhereSort
    on QueryBuilder<EventQueueModel, EventQueueModel, QWhere> {
  QueryBuilder<EventQueueModel, EventQueueModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension EventQueueModelQueryWhere
    on QueryBuilder<EventQueueModel, EventQueueModel, QWhereClause> {
  QueryBuilder<EventQueueModel, EventQueueModel, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterWhereClause>
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

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterWhereClause>
  eventIdEqualTo(String eventId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'eventId', value: [eventId]),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterWhereClause>
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

extension EventQueueModelQueryFilter
    on QueryBuilder<EventQueueModel, EventQueueModel, QFilterCondition> {
  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  enqueuedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'enqueuedAt', value: value),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  enqueuedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'enqueuedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  enqueuedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'enqueuedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  enqueuedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'enqueuedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
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

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
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

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
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

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
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

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
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

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
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

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
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

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
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

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eventIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'eventId', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eventIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'eventId', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
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

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
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

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
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

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  sentCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sentCount', value: value),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  sentCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sentCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  sentCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sentCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  sentCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sentCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  serializedRelayMessageEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'serializedRelayMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  serializedRelayMessageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'serializedRelayMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  serializedRelayMessageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'serializedRelayMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  serializedRelayMessageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'serializedRelayMessage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  serializedRelayMessageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'serializedRelayMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  serializedRelayMessageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'serializedRelayMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  serializedRelayMessageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'serializedRelayMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  serializedRelayMessageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'serializedRelayMessage',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  serializedRelayMessageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'serializedRelayMessage', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  serializedRelayMessageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'serializedRelayMessage',
          value: '',
        ),
      );
    });
  }
}

extension EventQueueModelQueryObject
    on QueryBuilder<EventQueueModel, EventQueueModel, QFilterCondition> {}

extension EventQueueModelQueryLinks
    on QueryBuilder<EventQueueModel, EventQueueModel, QFilterCondition> {}

extension EventQueueModelQuerySortBy
    on QueryBuilder<EventQueueModel, EventQueueModel, QSortBy> {
  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortByEnqueuedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enqueuedAt', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortByEnqueuedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enqueuedAt', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy> sortByEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortByEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortBySentCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentCount', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortBySentCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentCount', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortBySerializedRelayMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serializedRelayMessage', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortBySerializedRelayMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serializedRelayMessage', Sort.desc);
    });
  }
}

extension EventQueueModelQuerySortThenBy
    on QueryBuilder<EventQueueModel, EventQueueModel, QSortThenBy> {
  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenByEnqueuedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enqueuedAt', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenByEnqueuedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enqueuedAt', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy> thenByEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenByEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenBySentCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentCount', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenBySentCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentCount', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenBySerializedRelayMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serializedRelayMessage', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenBySerializedRelayMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serializedRelayMessage', Sort.desc);
    });
  }
}

extension EventQueueModelQueryWhereDistinct
    on QueryBuilder<EventQueueModel, EventQueueModel, QDistinct> {
  QueryBuilder<EventQueueModel, EventQueueModel, QDistinct>
  distinctByEnqueuedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enqueuedAt');
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QDistinct> distinctByEventId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QDistinct>
  distinctBySentCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sentCount');
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QDistinct>
  distinctBySerializedRelayMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'serializedRelayMessage',
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension EventQueueModelQueryProperty
    on QueryBuilder<EventQueueModel, EventQueueModel, QQueryProperty> {
  QueryBuilder<EventQueueModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<EventQueueModel, DateTime, QQueryOperations>
  enqueuedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enqueuedAt');
    });
  }

  QueryBuilder<EventQueueModel, String, QQueryOperations> eventIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventId');
    });
  }

  QueryBuilder<EventQueueModel, int, QQueryOperations> sentCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sentCount');
    });
  }

  QueryBuilder<EventQueueModel, String, QQueryOperations>
  serializedRelayMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serializedRelayMessage');
    });
  }
}
