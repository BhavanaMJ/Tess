/// Abstract Base Class demonstrating inheritance and interfaces in Dart.
/// Every TESS entity possesses a unique ID and creation timestamp.
abstract class BaseEntity {
  final String id;
  final DateTime createdAt;

  BaseEntity({
    required this.id,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Abstract method that subclasses MUST implement.
  Map<String, dynamic> toJson();
}

/// Interface definition in Dart.
/// Dart does not have an 'interface' keyword; every class implicitly defines an interface.
/// Classes use 'implements' to adhere to the contract.
abstract class Displayable {
  String get displayTitle;
  String get displaySubtitle;
}

