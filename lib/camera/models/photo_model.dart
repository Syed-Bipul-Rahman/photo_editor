import '../utils/db_helper.dart';

class Photo implements DatabaseModel {
  final int? id;
  final String path;
  final DateTime takenDate;
  final String? location;
  final int? fileSize;
  final String? resolution;

  const Photo({
    this.id,
    required this.path,
    required this.takenDate,
    this.location,
    this.fileSize,
    this.resolution,
  });

  @override
  String get tableName => 'photos';

  @override
  String get primaryKey => 'id';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'taken_date': takenDate.millisecondsSinceEpoch,
      'location': location,
      'file_size': fileSize,
      'resolution': resolution,
    };
  }

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'],
      path: map['path'],
      takenDate: DateTime.fromMillisecondsSinceEpoch(map['taken_date']),
      location: map['location'],
      fileSize: map['file_size'],
      resolution: map['resolution'],
    );
  }

  Photo copyWith({
    int? id,
    String? path,
    DateTime? takenDate,
    String? location,
    int? fileSize,
    String? resolution,
  }) {
    return Photo(
      id: id ?? this.id,
      path: path ?? this.path,
      takenDate: takenDate ?? this.takenDate,
      location: location ?? this.location,
      fileSize: fileSize ?? this.fileSize,
      resolution: resolution ?? this.resolution,
    );
  }

  @override
  String toString() {
    return 'Photo{id: $id, path: $path, takenDate: $takenDate, location: $location, fileSize: $fileSize, resolution: $resolution}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Photo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          path == other.path &&
          takenDate == other.takenDate &&
          location == other.location &&
          fileSize == other.fileSize &&
          resolution == other.resolution;

  @override
  int get hashCode =>
      id.hashCode ^
      path.hashCode ^
      takenDate.hashCode ^
      location.hashCode ^
      fileSize.hashCode ^
      resolution.hashCode;
}
