import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:memo_places_mobile/MyPlacesAndTrailsWidgets/empty_list_state.dart';
import 'package:memo_places_mobile/MyPlacesAndTrailsWidgets/memory_card.dart';
import 'package:memo_places_mobile/Objects/short_trail.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/catalog_repository.dart';
import 'package:memo_places_mobile/services/data_service.dart';
import 'package:memo_places_mobile/services/trails_repository.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/trail_details.dart';
import 'package:memo_places_mobile/trail_edit_form.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

class MyTrails extends StatefulWidget {
  const MyTrails({super.key});

  @override
  State<MyTrails> createState() => _MyTrailsState();
}

class _MyTrailsState extends State<MyTrails> {
  late Future<(List<ShortTrail>, Map<int, String>)> _future = _load();

  Future<(List<ShortTrail>, Map<int, String>)> _load() async {
    final userId = await fetchBackendUserId(context);
    if (!mounted) throw const ApiException('disposed');
    final trails = await context.read<TrailsRepository>().getByUser(userId);
    if (!mounted) throw const ApiException('disposed');
    final periods = await context.read<CatalogRepository>().periodValues();
    return (trails, periods);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next.catchError((_) => (const <ShortTrail>[], const <int, String>{}));
  }

  Future<void> _deleteTrail(ShortTrail trail) async {
    try {
      await context.read<TrailsRepository>().delete(trail.id);
      showSuccessToast(LocaleKeys.trail_deleted.tr());
      await _refresh();
    } on ApiException catch (error) {
      showErrorToast(error.message);
    }
  }

  void _confirmDelete(ShortTrail trail) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.confirm.tr()),
        content: Text(
            LocaleKeys.delete_warning.tr(namedArgs: {'name': trail.trailName})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteTrail(trail);
            },
            child: Text(LocaleKeys.delete.tr()),
          ),
        ],
      ),
    );
  }

  void _confirmEdit(ShortTrail trail) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.confirm.tr()),
        content: Text(LocaleKeys.edit_info.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        TrailEditForm(trail.id.toString())),
              );
            },
            child: Text(LocaleKeys.ok.tr()),
          ),
        ],
      ),
    );
  }

  void _openDetails(ShortTrail trail) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => TrailDetails(trail.id.toString())),
    );
  }

  Widget _list(List<ShortTrail> trails, Map<int, String> periods) {
    if (trails.isEmpty) {
      return EmptyListState(
        message: LocaleKeys.no_trails_added.tr(),
        ctaLabel: LocaleKeys.record_first_trail.tr(),
        icon: Icons.route_outlined,
        // The record flow lives behind the map shell's + FAB.
        onCta: () => Navigator.popUntil(context, (route) => route.isFirst),
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: trails.length,
      itemBuilder: (context, index) {
        final trail = trails[index];
        return Slidable(
          key: ValueKey(trail.id),
          endActionPane: trail.verified
              ? null
              : ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) => _confirmEdit(trail),
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      icon: Icons.edit_location_alt_outlined,
                      label: LocaleKeys.edit.tr(),
                    ),
                    SlidableAction(
                      onPressed: (_) => _confirmDelete(trail),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Colors.white,
                      icon: Icons.delete_outlined,
                      label: LocaleKeys.delete.tr(),
                    ),
                  ],
                ),
          child: MemoryCard(
            title: trail.trailName,
            periodLabel: periods[trail.period],
            verified: trail.verified,
            fallbackIcon: Icons.route_outlined,
            imagesFuture:
                context.read<TrailsRepository>().fetchImageUrls(trail.id),
            onTap: () => _openDetails(trail),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.your_trails.tr())),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<(List<ShortTrail>, Map<int, String>)>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        error is ApiException
                            ? error.message
                            : LocaleKeys.alert_error.tr(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    TextButton(
                      onPressed: _refresh,
                      child: Text(LocaleKeys.refresh.tr()),
                    ),
                  ],
                ),
              );
            }
            final data = snapshot.data;
            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: _list(data.$1, data.$2),
            );
          },
        ),
      ),
    );
  }
}
