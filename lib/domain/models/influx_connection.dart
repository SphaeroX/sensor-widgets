/// Configuration metadata for an InfluxDB connection.
///
/// NOTE: The authentication token is deliberately NOT stored in this object or
/// in JSON serialized data; tokens are strictly stored in secure platform storage.
class InfluxConnection {
  final String id;
  final String name;
  final String url;
  final String database;
  final String? organization;

  const InfluxConnection({
    required this.id,
    required this.name,
    required this.url,
    required this.database,
    this.organization,
  });

  bool get isValid {
    if (id.trim().isEmpty || name.trim().isEmpty || database.trim().isEmpty) {
      return false;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return false;
    }
    return true;
  }

  factory InfluxConnection.fromJson(Map<String, dynamic> json) {
    return InfluxConnection(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      database: json['database'] as String,
      organization: json['organization'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'url': url,
      'database': database,
    };
    if (organization != null) map['organization'] = organization;
    return map;
  }

  InfluxConnection copyWith({
    String? id,
    String? name,
    String? url,
    String? database,
    String? organization,
  }) {
    return InfluxConnection(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      database: database ?? this.database,
      organization: organization ?? this.organization,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InfluxConnection &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          url == other.url &&
          database == other.database &&
          organization == other.organization;

  @override
  int get hashCode => Object.hash(id, name, url, database, organization);

  @override
  String toString() =>
      'InfluxConnection(id: $id, name: $name, url: $url, db: $database)';
}
