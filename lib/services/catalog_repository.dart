import 'package:memo_places_mobile/Objects/period.dart';
import 'package:memo_places_mobile/Objects/sortof.dart';
import 'package:memo_places_mobile/Objects/type.dart';
import 'package:memo_places_mobile/services/api_client.dart';

/// Types / sortofs / periods from the .NET Categories endpoints, cached in
/// memory for the app session (they change only via the admin panel).
class CatalogRepository {
  final ApiClient _api;

  List<Type>? _types;
  List<Sortof>? _sortofs;
  List<Period>? _periods;

  CatalogRepository(this._api);

  Future<List<Type>> getTypes() async {
    return _types ??= ((await _api.get('/api/v1/types')) as List)
        .map((json) => Type.fromJson(json as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<List<Sortof>> getSortofs() async {
    return _sortofs ??= ((await _api.get('/api/v1/sortofs')) as List)
        .map((json) => Sortof.fromJson(json as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<List<Period>> getPeriods() async {
    return _periods ??= ((await _api.get('/api/v1/periods')) as List)
        .map((json) => Period.fromJson(json as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Localization-key lookup tables used to enrich place/trail models.
  Future<Map<int, String>> typeValues() async =>
      {for (final t in await getTypes()) t.id: t.value};

  Future<Map<int, String>> sortofValues() async =>
      {for (final s in await getSortofs()) s.id: s.value};

  Future<Map<int, String>> periodValues() async =>
      {for (final p in await getPeriods()) p.id: p.value};
}
