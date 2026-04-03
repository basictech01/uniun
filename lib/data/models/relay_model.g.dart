// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relay_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRelayModelCollection on Isar {
  IsarCollection<RelayModel> get relayModels => this.collection();
}

const RelayModelSchema = CollectionSchema(
  name: r'Relay',
  id: -6541783426875531135,
  properties: {
    r'lastConnectedAt': PropertySchema(
      id: 0,
      name: r'lastConnectedAt',
      type: IsarType.dateTime,
    ),
    r'read': PropertySchema(id: 1, name: r'read', type: IsarType.bool),
    r'status': PropertySchema(
      id: 2,
      name: r'status',
      type: IsarType.string,
      enumMap: _RelayModelstatusEnumValueMap,
    ),
    r'url': PropertySchema(id: 3, name: r'url', type: IsarType.string),
    r'write': PropertySchema(id: 4, name: r'write', type: IsarType.bool),
  },

  estimateSize: _relayModelEstimateSize,
  serialize: _relayModelSerialize,
  deserialize: _relayModelDeserialize,
  deserializeProp: _relayModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'url': IndexSchema(
      id: -5756857009679432345,
      name: r'url',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'url',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _relayModelGetId,
  getLinks: _relayModelGetLinks,
  attach: _relayModelAttach,
  version: '3.3.2',
);

int _relayModelEstimateSize(
  RelayModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.status.name.length * 3;
  bytesCount += 3 + object.url.length * 3;
  return bytesCount;
}

void _relayModelSerialize(
  RelayModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.lastConnectedAt);
  writer.writeBool(offsets[1], object.read);
  writer.writeString(offsets[2], object.status.name);
  writer.writeString(offsets[3], object.url);
  writer.writeBool(offsets[4], object.write);
}

RelayModel _relayModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RelayModel();
  object.id = id;
  object.lastConnectedAt = reader.readDateTimeOrNull(offsets[0]);
  object.read = reader.readBool(offsets[1]);
  object.status =
      _RelayModelstatusValueEnumMap[reader.readStringOrNull(offsets[2])] ??
      RelayStatus.connected;
  object.url = reader.readString(offsets[3]);
  object.write = reader.readBool(offsets[4]);
  return object;
}

P _relayModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (_RelayModelstatusValueEnumMap[reader.readStringOrNull(offset)] ??
              RelayStatus.connected)
          as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _RelayModelstatusEnumValueMap = {
  r'connected': r'connected',
  r'disconnected': r'disconnected',
  r'reconnecting': r'reconnecting',
};
const _RelayModelstatusValueEnumMap = {
  r'connected': RelayStatus.connected,
  r'disconnected': RelayStatus.disconnected,
  r'reconnecting': RelayStatus.reconnecting,
};

Id _relayModelGetId(RelayModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _relayModelGetLinks(RelayModel object) {
  return [];
}

void _relayModelAttach(IsarCollection<dynamic> col, Id id, RelayModel object) {
  object.id = id;
}

extension RelayModelByIndex on IsarCollection<RelayModel> {
  Future<RelayModel?> getByUrl(String url) {
    return getByIndex(r'url', [url]);
  }

  RelayModel? getByUrlSync(String url) {
    return getByIndexSync(r'url', [url]);
  }

  Future<bool> deleteByUrl(String url) {
    return deleteByIndex(r'url', [url]);
  }

  bool deleteByUrlSync(String url) {
    return deleteByIndexSync(r'url', [url]);
  }

  Future<List<RelayModel?>> getAllByUrl(List<String> urlValues) {
    final values = urlValues.map((e) => [e]).toList();
    return getAllByIndex(r'url', values);
  }

  List<RelayModel?> getAllByUrlSync(List<String> urlValues) {
    final values = urlValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'url', values);
  }

  Future<int> deleteAllByUrl(List<String> urlValues) {
    final values = urlValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'url', values);
  }

  int deleteAllByUrlSync(List<String> urlValues) {
    final values = urlValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'url', values);
  }

  Future<Id> putByUrl(RelayModel object) {
    return putByIndex(r'url', object);
  }

  Id putByUrlSync(RelayModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'url', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUrl(List<RelayModel> objects) {
    return putAllByIndex(r'url', objects);
  }

  List<Id> putAllByUrlSync(List<RelayModel> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'url', objects, saveLinks: saveLinks);
  }
}

extension RelayModelQueryWhereSort
    on QueryBuilder<RelayModel, RelayModel, QWhere> {
  QueryBuilder<RelayModel, RelayModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RelayModelQueryWhere
    on QueryBuilder<RelayModel, RelayModel, QWhereClause> {
  QueryBuilder<RelayModel, RelayModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<RelayModel, RelayModel, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<RelayModel, RelayModel, QAfterWhereClause> urlEqualTo(
    String url,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'url', value: [url]),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterWhereClause> urlNotEqualTo(
    String url,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'url',
                lower: [],
                upper: [url],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'url',
                lower: [url],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'url',
                lower: [url],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'url',
                lower: [],
                upper: [url],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension RelayModelQueryFilter
    on QueryBuilder<RelayModel, RelayModel, QFilterCondition> {
  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition>
  lastConnectedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastConnectedAt'),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition>
  lastConnectedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastConnectedAt'),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition>
  lastConnectedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastConnectedAt', value: value),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition>
  lastConnectedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastConnectedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition>
  lastConnectedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastConnectedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition>
  lastConnectedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastConnectedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> readEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'read', value: value),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> statusEqualTo(
    RelayStatus value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> statusGreaterThan(
    RelayStatus value, {
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

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> statusLessThan(
    RelayStatus value, {
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

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> statusBetween(
    RelayStatus lower,
    RelayStatus upper, {
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

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> statusContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> statusMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition>
  statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> urlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> urlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> urlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> urlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'url',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> urlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> urlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> urlContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> urlMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'url',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'url', value: ''),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'url', value: ''),
      );
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterFilterCondition> writeEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'write', value: value),
      );
    });
  }
}

extension RelayModelQueryObject
    on QueryBuilder<RelayModel, RelayModel, QFilterCondition> {}

extension RelayModelQueryLinks
    on QueryBuilder<RelayModel, RelayModel, QFilterCondition> {}

extension RelayModelQuerySortBy
    on QueryBuilder<RelayModel, RelayModel, QSortBy> {
  QueryBuilder<RelayModel, RelayModel, QAfterSortBy> sortByLastConnectedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastConnectedAt', Sort.asc);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterSortBy>
  sortByLastConnectedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastConnectedAt', Sort.desc);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterSortBy> sortByRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'read', Sort.asc);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterSortBy> sortByReadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'read', Sort.desc);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterSortBy> sortByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterSortBy> sortByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterSortBy> sortByWrite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'write', Sort.asc);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterSortBy> sortByWriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'write', Sort.desc);
    });
  }
}

extension RelayModelQuerySortThenBy
    on QueryBuilder<RelayModel, RelayModel, QSortThenBy> {
  QueryBuilder<RelayModel, RelayModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterSortBy> thenByLastConnectedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastConnectedAt', Sort.asc);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterSortBy>
  thenByLastConnectedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastConnectedAt', Sort.desc);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterSortBy> thenByRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'read', Sort.asc);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterSortBy> thenByReadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'read', Sort.desc);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterSortBy> thenByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterSortBy> thenByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterSortBy> thenByWrite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'write', Sort.asc);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QAfterSortBy> thenByWriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'write', Sort.desc);
    });
  }
}

extension RelayModelQueryWhereDistinct
    on QueryBuilder<RelayModel, RelayModel, QDistinct> {
  QueryBuilder<RelayModel, RelayModel, QDistinct> distinctByLastConnectedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastConnectedAt');
    });
  }

  QueryBuilder<RelayModel, RelayModel, QDistinct> distinctByRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'read');
    });
  }

  QueryBuilder<RelayModel, RelayModel, QDistinct> distinctByStatus({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QDistinct> distinctByUrl({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'url', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RelayModel, RelayModel, QDistinct> distinctByWrite() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'write');
    });
  }
}

extension RelayModelQueryProperty
    on QueryBuilder<RelayModel, RelayModel, QQueryProperty> {
  QueryBuilder<RelayModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RelayModel, DateTime?, QQueryOperations>
  lastConnectedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastConnectedAt');
    });
  }

  QueryBuilder<RelayModel, bool, QQueryOperations> readProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'read');
    });
  }

  QueryBuilder<RelayModel, RelayStatus, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<RelayModel, String, QQueryOperations> urlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'url');
    });
  }

  QueryBuilder<RelayModel, bool, QQueryOperations> writeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'write');
    });
  }
}
