/// The single error type surfaced to UI code. [message] is already localized
/// and safe to show in a toast or error state.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}
