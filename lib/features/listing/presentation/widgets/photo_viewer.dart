import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/t_text.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../domain/entities/listing.dart';
import '../category_ui.dart';

/// Full-screen, zoomable listing photos. Swipe between them; returns the
/// index that was showing when closed.
class PhotoViewer extends StatefulWidget {
  const PhotoViewer({super.key, required this.listing, required this.count, required this.initial});

  final Listing listing;
  final int count, initial;

  static Future<int?> open(
    BuildContext context, {
    required Listing listing,
    required int count,
    required int initial,
  }) => Navigator.of(context).push(
    PageRouteBuilder<int>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) => PhotoViewer(listing: listing, count: count, initial: initial),
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    ),
  );

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final _controller = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = widget.listing;
    final pad = MediaQuery.paddingOf(context);
    final width = MediaQuery.sizeOf(context).width;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _index);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.count,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => Semantics(
                image: true,
                label: '${l.title}, ${i + 1}-rasm, jami ${widget.count}',
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Center(
                    child: PhotoPlaceholder(
                      icon: l.category.icon,
                      tint: l.tint + i,
                      path: l.photoAt(i),
                      width: width,
                      height: width,
                      iconSize: 96,
                      radius: 0,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: pad.top < 30 ? pad.top + 8 : pad.top,
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Yopish',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, _index),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox.square(
                        dimension: 44,
                        child: GlassSurface(child: Icon(Symbols.close_rounded, size: 22, color: cs.onSurface)),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (widget.count > 1)
                    SizedBox(
                      height: 32,
                      child: GlassSurface(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            '${_index + 1} / ${widget.count}',
                            style: Theme.of(context).textTheme.labelLarge!
                                .copyWith(fontSize: 13, height: 1.2, color: cs.onSurface)
                                .inter(FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
