import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/apiConstants.dart';
import 'package:memo_places_mobile/placeDetails.dart';
import 'package:memo_places_mobile/Objects/place.dart';
import 'package:memo_places_mobile/services/dataService.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

class PreviewPlace extends StatefulWidget {
  final void Function() closePreview;
  final Place place;

  const PreviewPlace(this.closePreview, this.place, {super.key});

  @override
  State<PreviewPlace> createState() => _PreviewPlaceState();
}

class _PreviewPlaceState extends State<PreviewPlace>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPlaceImages(context, widget.place.id.toString()).then((value) {
      widget.place.images = value;
      setState(() {
        _isLoading = false;
      });
    });
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  void _closePreview() {
    _controller.reverse().then((_) {
      widget.closePreview();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          _closePreview();
        } else if (details.primaryVelocity! < 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => PlaceDetails(widget.place.id.toString()),
            ),
          );
        }
      },
      child: SlideTransition(
        position: _offsetAnimation,
        child: Center(
          child: SizedBox(
            height: 190,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              child: Container(
                color: Theme.of(context).colorScheme.background,
                child: Column(
                  children: [
                    const Center(
                      child: Icon(Icons.drag_handle),
                    ),
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.scrim),
                              ),
                            )
                          : Row(
                              children: [
                                widget.place.images!.isNotEmpty
                                    ? Container(
                                        margin: const EdgeInsets.fromLTRB(
                                            10, 5, 10, 5),
                                        child: Image.network(
                                          ApiConstants.displayImageEndpoint(
                                              widget.place.images![0]),
                                          width: 150,
                                          height: 150,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const SizedBox(
                                        width: 10,
                                      ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.place.placeName,
                                        style: const TextStyle(
                                          overflow: TextOverflow.ellipsis,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        LocaleKeys.found_by.tr(namedArgs: {
                                          'username': widget.place.username
                                        }),
                                        style: const TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        LocaleKeys.found.tr(namedArgs: {
                                          'date': widget.place.creationDate
                                        }),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
