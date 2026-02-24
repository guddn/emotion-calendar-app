// GENERATED CODE - MANUAL CHECK-IN FOR OFFLINE ENVIRONMENT

part of 'diary.dart';

const DiarySchema = CollectionSchema(
  name: r'Diary',
  id: 1238732987412309874,
  properties: {
    r'colorHex': PropertySchema(
      id: 0,
      name: r'colorHex',
      type: IsarType.string,
    ),
    r'content': PropertySchema(
      id: 1,
      name: r'content',
      type: IsarType.string,
    ),
    r'date': PropertySchema(
      id: 2,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'emotion': PropertySchema(
      id: 3,
      name: r'emotion',
      type: IsarType.string,
    ),
    r'summary': PropertySchema(
      id: 4,
      name: r'summary',
      type: IsarType.string,
    ),
  },
  estimateSize: _diaryEstimateSize,
  serialize: _diarySerialize,
  deserialize: _diaryDeserialize,
  deserializeProp: _diaryDeserializeProp,
  idName: r'id',
  indexes: {
    r'date': IndexSchema(
      id: 389472893472,
      name: r'date',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _diaryGetId,
  getLinks: _diaryGetLinks,
  attach: _diaryAttach,
  version: '3.1.0+1',
);

int _diaryEstimateSize(
  Diary object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.colorHex.length * 3;
  bytesCount += 3 + object.content.length * 3;
  bytesCount += 3 + object.emotion.length * 3;
  bytesCount += 3 + object.summary.length * 3;
  return bytesCount;
}

void _diarySerialize(
  Diary object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.colorHex);
  writer.writeString(offsets[1], object.content);
  writer.writeDateTime(offsets[2], object.date);
  writer.writeString(offsets[3], object.emotion);
  writer.writeString(offsets[4], object.summary);
}

Diary _diaryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Diary();
  object.colorHex = reader.readString(offsets[0]);
  object.content = reader.readString(offsets[1]);
  object.date = reader.readDateTime(offsets[2]);
  object.emotion = reader.readString(offsets[3]);
  object.id = id;
  object.summary = reader.readString(offsets[4]);
  return object;
}

P _diaryDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _diaryGetId(Diary object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _diaryGetLinks(Diary object) {
  return [];
}

void _diaryAttach(IsarCollection<dynamic> col, Id id, Diary object) {
  object.id = id;
}