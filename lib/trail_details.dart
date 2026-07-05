import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/Objects/trail.dart';
import 'package:memo_places_mobile/map/memory_detail_content.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/trails_repository.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

/// Thin wrapper over [MemoryDetailContent] — the same content the Memory
/// Sheet renders, for flows that open a trail outside the map (My Trails).
class TrailDetails extends StatefulWidget {
  final String trailId;
  const TrailDetails(this.trailId, {super.key});

  @override
  State<TrailDetails> createState() => _TrailDetailsState();
}

class _TrailDetailsState extends State<TrailDetails> {
  late Future<Trail> _trailFuture = _load();

  Future<Trail> _load() =>
      context.read<TrailsRepository>().getById(int.parse(widget.trailId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Trail>(
      future: _trailFuture,
      builder: (context, snapshot) {
        final trail = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: Text(trail?.trailName ?? '')),
          body: SafeArea(
            bottom: false,
            child: Builder(builder: (context) {
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
                        onPressed: () => setState(() {
                          _trailFuture = _load();
                        }),
                        child: Text(LocaleKeys.refresh.tr()),
                      ),
                    ],
                  ),
                );
              }
              if (trail == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child:
                    MemoryDetailContent(detail: MemoryDetail.fromTrail(trail)),
              );
            }),
          ),
        );
      },
    );
  }
}
