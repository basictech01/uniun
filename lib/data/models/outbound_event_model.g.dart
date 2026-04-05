// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbound_event_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOutboundEventModelCollection on Isar {
  IsarCollection<OutboundEventModel> get outboundEventModels =>
      this.collection();
}

const OutboundEventModelSchema = CollectionSchema(
  name: r'OutboundEvent',
  id: -2070003636047133594,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'retryCount': PropertySchema(
      id: 1,
      name: r'retryCount',
      type: IsarType.long,
    ),
    r'serializedEvent': PropertySchema(
      id: 2,
      name: r'serializedEvent',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 3,
      name: r'status',
      type: IsarType.string,
      enumMap: _OutboundEventModelstatusEnumValueMap,
    ),
  },

  estimateSize: _outboundEventModelEstimateSize,
  serialize: _outboundEventModelSerialize,
  deserialize: _outboundEventModelDeserialize,
  deserializeProp: _outboundEventModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _outboundEventModelGetId,
  getLinks: _outboundEventModelGetLinks,
  attach: _outboundEventModelAttach,
  version: '3.3.2',
);

int _outboundEventModelEstimateSize(
  OutboundEventModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.serializedEvent.length * 3;
  bytesCount += 3 + object.status.name.length * 3;
  return bytesCount;
}

void _outboundEventModelSerialize(
  OutboundEventModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeLong(offsets[1], object.retryCount);
  writer.writeString(offsets[2], object.serializedEvent);
  writer.writeString(offsets[3], object.status.name);
}

OutboundEventModel _outboundEventModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OutboundEventModel();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.retryCount = reader.readLong(offsets[1]);
  object.serializedEvent = reader.readString(offsets[2]);
  object.status =
      _OutboundEventModelstatusValueEnumMap[reader.readStringOrNull(
        offsets[3],
      )] ??
      OutboundStatus.pending;
  return object;
}

P _outboundEventModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (_OutboundEventModelstatusValueEnumMap[reader.readStringOrNull(
                offset,
              )] ??
              OutboundStatus.pending)
          as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _OutboundEventModelstatusEnumValueMap = {
  r'pending': r'pending',
  r'broadcasting': r'broadcasting',
  r'sent': r'sent',
  r'failed': r'failed',
};
const _OutboundEventModelstatusValueEnumMap = {
  r'pending': OutboundStatus.pending,
  r'broadcasting': OutboundStatus.broadcasting,
  r'sent': OutboundStatus.sent,
  r'failed': OutboundStatus.failed,
};

Id _outboundEventModelGetId(OutboundEventModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _outboundEventModelGetLinks(
  OutboundEventModel object,
) {
  return [];
}

void _outboundEventModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  OutboundEventModel object,
) {
  object.id = id;
}

extension OutboundEventModelQueryWhereSort
    on QueryBuilder<OutboundEventModel, OutboundEventModel, QWhere> {
  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension OutboundEventModelQueryWhere
    on QueryBuilder<OutboundEventModel, OutboundEventModel, QWhereClause> {
  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterWhereClause>
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

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterWhereClause>
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
}

extension OutboundEventModelQueryFilter
    on QueryBuilder<OutboundEventModel, OutboundEventModel, QFilterCondition> {
  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
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

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
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

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
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

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  retryCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'retryCount', value: value),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  retryCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'retryCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  retryCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'retryCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  retryCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'retryCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  serializedEventEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'serializedEvent',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  serializedEventGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'serializedEvent',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  serializedEventLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'serializedEvent',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  serializedEventBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'serializedEvent',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  serializedEventStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'serializedEvent',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  serializedEventEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'serializedEvent',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  serializedEventContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'serializedEvent',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  serializedEventMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'serializedEvent',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  serializedEventIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'serializedEvent', value: ''),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  serializedEventIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'serializedEvent', value: ''),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  statusEqualTo(OutboundStatus value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  statusGreaterThan(
    OutboundStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  statusLessThan(
    OutboundStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  statusBetween(
    OutboundStatus lower,
    OutboundStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  statusStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  statusEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'status',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterFilterCondition>
  statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'status', value: ''),
      );
    });
  }
}

extension OutboundEventModelQueryObject
    on QueryBuilder<OutboundEventModel, OutboundEventModel, QFilterCondition> {}

extension OutboundEventModelQueryLinks
    on QueryBuilder<OutboundEventModel, OutboundEventModel, QFilterCondition> {}

extension OutboundEventModelQuerySortBy
    on QueryBuilder<OutboundEventModel, OutboundEventModel, QSortBy> {
  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterSortBy>
  sortByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.asc);
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterSortBy>
  sortByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.desc);
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterSortBy>
  sortBySerializedEvent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serializedEvent', Sort.asc);
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterSortBy>
  sortBySerializedEventDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serializedEvent', Sort.desc);
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterSortBy>
  sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterSortBy>
  sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension OutboundEventModelQuerySortThenBy
    on QueryBuilder<OutboundEventModel, OutboundEventModel, QSortThenBy> {
  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterSortBy>
  thenByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.asc);
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterSortBy>
  thenByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.desc);
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterSortBy>
  thenBySerializedEvent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serializedEvent', Sort.asc);
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterSortBy>
  thenBySerializedEventDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serializedEvent', Sort.desc);
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterSortBy>
  thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QAfterSortBy>
  thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension OutboundEventModelQueryWhereDistinct
    on QueryBuilder<OutboundEventModel, OutboundEventModel, QDistinct> {
  QueryBuilder<OutboundEventModel, OutboundEventModel, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QDistinct>
  distinctByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'retryCount');
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QDistinct>
  distinctBySerializedEvent({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'serializedEvent',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<OutboundEventModel, OutboundEventModel, QDistinct>
  distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }
}

extension OutboundEventModelQueryProperty
    on QueryBuilder<OutboundEventModel, OutboundEventModel, QQueryProperty> {
  QueryBuilder<OutboundEventModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OutboundEventModel, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<OutboundEventModel, int, QQueryOperations> retryCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'retryCount');
    });
  }

  QueryBuilder<OutboundEventModel, String, QQueryOperations>
  serializedEventProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serializedEvent');
    });
  }

  QueryBuilder<OutboundEventModel, OutboundStatus, QQueryOperations>
  statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }
}
