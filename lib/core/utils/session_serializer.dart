/// Serializer for converting session data between JSON and typed objects
abstract class SessionSerializer<T> {
  /// Deserializes JSON data to a session object
  T? fromJson(dynamic json);
  
  /// Serializes a session object to JSON
  Map<String, dynamic> toJson(T session);
}
