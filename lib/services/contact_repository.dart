import 'package:memo_places_mobile/services/api_client.dart';

class ContactRepository {
  final ApiClient _api;

  ContactRepository(this._api);

  /// Submits a contact-form message. Anonymous endpoint; emails are sent
  /// verbatim — the legacy `.` → `&` mangling is gone with the Django API.
  Future<void> send({
    required String email,
    required String title,
    required String description,
  }) =>
      _api.post('/api/v1/contact', body: {
        'email': email,
        'title': title,
        'description': description,
      });
}
