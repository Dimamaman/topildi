import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/tr.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/returned_item.dart';
import '../category_ui.dart';

/// What the feed's returned strip hands the stories screen: the row it is
/// showing, which item was tapped, and where that item sat on screen so the
/// circle can grow out of it.
class ReturnedStoriesArgs {
  const ReturnedStoriesArgs({required this.items, this.index = 0, this.source, this.onSeen});

  final List<ReturnedItem> items;
  final int index;

  /// The tapped avatar in global coordinates; null falls back to a fade.
  final Rect? source;

  /// Called with an item's id the moment its story comes up, so the row
  /// behind can let that ring go quiet.
  final void Function(String id)? onSeen;
}

/// "Egasiga qaytdi" as stories: the returned items one after another, five
/// seconds each, and nothing to do in them.
///
/// There is deliberately no reply box, no heart, no share and no way through
/// to a profile: a returned listing is over, and the screen is only proof
/// that it ended well. The one tap it takes is the one that moves between
/// items.
class ReturnedStoriesPage extends StatefulWidget {
  const ReturnedStoriesPage({super.key, required this.args});

  final ReturnedStoriesArgs args;

  /// At most this many, as in the strip itself.
  static const maxItems = 10;

  /// How long one item stays up.
  static const itemDuration = Duration(seconds: 5);

  @override
  State<ReturnedStoriesPage> createState() => _ReturnedStoriesPageState();
}

class _ReturnedStoriesPageState extends State<ReturnedStoriesPage> with SingleTickerProviderStateMixin {
  late final List<ReturnedItem> _items = widget.args.items.take(ReturnedStoriesPage.maxItems).toList();
  late final AnimationController _progress =
      AnimationController(vsync: this, duration: ReturnedStoriesPage.itemDuration)..addStatusListener((s) {
        if (s == AnimationStatus.completed) _next();
      });

  late int _index = widget.args.index.clamp(0, math.max(0, _items.length - 1));

  /// Held down: the bars stop and the text leaves until the finger does.
  bool _held = false;

  /// How far the screen has been dragged down, in logical pixels.
  double _drag = 0;

  /// Backgrounds already measured, by item id: nothing is shown and the bar
  /// does not move until the current one is in.
  final _media = <String, _Media>{};

  @override
  void initState() {
    super.initState();
    _seen();
    _load(_index);
    _prefetch(_index + 1);
  }

  /// Watched is watched the moment it is on screen, not once the five
  /// seconds are up: whoever moves on early has still seen it.
  ///
  /// Reported at the end of the frame, never inside it: the row behind this
  /// screen rebuilds on the news, and the first story says it from
  /// [initState] — while that row is still being built.
  void _seen() {
    if (_items.isEmpty) return;
    final id = _item.id;
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.args.onSeen?.call(id));
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  ReturnedItem get _item => _items[_index];

  bool get _ready => _items.isEmpty || _media.containsKey(_item.id);

  /// Reads the item's photo once: its proportions decide the layout, its two
  /// main colours the background behind a photo that does not fill the screen.
  Future<void> _load(int i) async {
    if (i < 0 || i >= _items.length) return;
    final item = _items[i];
    if (_media.containsKey(item.id)) return;
    final media = await _Media.of(item);
    if (!mounted) return;
    setState(() => _media[item.id] = media);
    if (i == _index) _restart();
  }

  void _prefetch(int i) => _load(i);

  void _restart() {
    _progress.value = 0;
    if (!_held) _progress.forward();
  }

  void _go(int i) {
    if (i >= _items.length) {
      _close();
      return;
    }
    setState(() => _index = i.clamp(0, _items.length - 1));
    _seen();
    _progress.stop();
    _progress.value = 0;
    if (_ready) _restart();
    _prefetch(_index + 1);
  }

  void _next() => _go(_index + 1);

  /// Back on the first item only rewinds it: there is nothing before it.
  void _previous() => _index == 0 ? _restart() : _go(_index - 1);

  void _close() {
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  void _hold(bool down) {
    if (_held == down) return;
    setState(() => _held = down);
    if (down) {
      _progress.stop();
    } else if (_ready) {
      _progress.forward();
    }
  }

  void _tap(TapUpDetails d, double width) => d.localPosition.dx < width / 3 ? _previous() : _next();

  void _dragUpdate(DragUpdateDetails d) {
    final next = math.max(0.0, _drag + d.delta.dy);
    setState(() => _drag = next);
    _hold(next > 0);
  }

  void _dragEnd(DragEndDetails d) {
    // A long pull or a quick flick closes; anything less springs back.
    if (_drag > 120 || d.velocity.pixelsPerSecond.dy > 700) {
      _close();
      return;
    }
    setState(() => _drag = 0);
    _hold(false);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final size = MediaQuery.sizeOf(context);
    // Dragging shrinks the whole screen a little, as it does in stories
    // everywhere: it says the screen is about to leave for the row below.
    final shrink = 1 - (_drag / size.height).clamp(0.0, 1.0) * 0.15;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Transform.translate(
          offset: Offset(0, _drag),
          child: Transform.scale(
            scale: shrink,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_drag > 0 ? 28 : 0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _tap(d, size.width),
                onLongPressStart: (_) => _hold(true),
                onLongPressEnd: (_) => _hold(false),
                onLongPressCancel: () => _hold(false),
                onVerticalDragUpdate: _dragUpdate,
                onVerticalDragEnd: _dragEnd,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _StoryBackground(item: _item, media: _media[_item.id]),
                    if (!_ready) const Center(child: _Spinner()),
                    // Screen-reader users get the two halves as buttons; the
                    // story itself is read out by [_Caption].
                    Positioned.fill(
                      child: Row(
                        children: [
                          Expanded(
                            child: _Zone(label: tr('Oldingi'), onTap: _previous),
                          ),
                          Expanded(
                            flex: 2,
                            child: _Zone(label: tr('Keyingi'), onTap: _next),
                          ),
                        ],
                      ),
                    ),
                    // The chrome leaves while the finger is down, so the
                    // photo is unobstructed.
                    AnimatedOpacity(
                      opacity: _held ? 0 : 1,
                      duration: const Duration(milliseconds: 150),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _TopBar(
                            count: _items.length,
                            index: _index,
                            progress: _progress,
                            returnedAt: _item.returnedAt,
                            onClose: _close,
                          ),
                          _Caption(item: _item),
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

/// A tap half, for semantics only: the real taps are read from the position
/// on the screen above, so these must not take the gesture themselves.
class _Zone extends StatelessWidget {
  const _Zone({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      Semantics(button: true, label: label, onTap: onTap, child: const SizedBox.expand());
}

/// Photo, proportions and the two colours behind it, read once per item.
class _Media {
  const _Media({this.image, this.aspect = 1, this.top, this.bottom});

  final ImageProvider? image;

  /// Width / height of the photo.
  final double aspect;

  /// Background gradient for a photo that leaves the screen's ends bare.
  final Color? top, bottom;

  /// Tall enough to fill the screen on its own (height ≥ 1.5 × width).
  bool get isTall => aspect <= 1 / 1.5;

  static Future<_Media> of(ReturnedItem item) async {
    final url = item.photo;
    if (url == null) return const _Media();
    final provider = NetworkImage(url);
    try {
      final info = await _resolve(provider);
      try {
        final image = info.image;
        final aspect = image.height == 0 ? 1.0 : image.width / image.height;
        if (aspect <= 1 / 1.5) return _Media(image: provider, aspect: aspect);
        // A square or landscape photo cannot fill the screen, so its own two
        // main colours fill what is left — darkened, so the white text on top
        // keeps its contrast.
        final (top, bottom) = await _twoColours(image);
        return _Media(image: provider, aspect: aspect, top: top, bottom: bottom);
      } finally {
        info.dispose();
      }
    } catch (_) {
      // A photo that cannot be read is simply a story without one.
      return const _Media();
    }
  }

  /// The photo's main colour and its darkest well-used one, for the top and
  /// the bottom of the gradient behind it.
  ///
  /// The photo is drawn once into a 48 × 48 canvas first: a phone photo holds
  /// millions of pixels, and a background gradient does not need them. The
  /// colours are then counted in 4-bit-per-channel bins, which groups shades
  /// of the same colour together instead of letting noise win.
  static Future<(Color, Color)> _twoColours(ui.Image image) async {
    const n = 48;
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, n.toDouble(), n.toDouble()),
      Paint()..filterQuality = FilterQuality.medium,
    );
    final picture = recorder.endRecording();
    final small = await picture.toImage(n, n);
    picture.dispose();
    final data = await small.toByteData(format: ui.ImageByteFormat.rawRgba);
    small.dispose();

    final counts = <int, int>{};
    final sums = <int, List<int>>{};
    final bytes = data?.buffer.asUint8List() ?? Uint8List(0);
    for (var i = 0; i + 3 < bytes.length; i += 4) {
      if (bytes[i + 3] < 128) continue;
      final key = (bytes[i] >> 4) << 8 | (bytes[i + 1] >> 4) << 4 | (bytes[i + 2] >> 4);
      counts[key] = (counts[key] ?? 0) + 1;
      final sum = sums.putIfAbsent(key, () => [0, 0, 0]);
      for (var c = 0; c < 3; c++) {
        sum[c] += bytes[i + c];
      }
    }
    if (counts.isEmpty) return (_darken(const Color(0xFF3A3A3A)), _darken(const Color(0xFF1A1A1A)));

    Color colourOf(int key) {
      final count = counts[key]!;
      final sum = sums[key]!;
      return Color.fromARGB(255, sum[0] ~/ count, sum[1] ~/ count, sum[2] ~/ count);
    }

    final ranked = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final common = ranked.take(8).toList()
      ..sort((a, b) => colourOf(a).computeLuminance().compareTo(colourOf(b).computeLuminance()));
    return (_darken(colourOf(ranked.first)), _darken(colourOf(common.first)));
  }

  static Color _darken(Color c) => Color.lerp(c, Colors.black, 0.25)!;

  static Future<ImageInfo> _resolve(ImageProvider provider) {
    final completer = Completer<ImageInfo>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (completer.isCompleted) {
          info.dispose();
        } else {
          completer.complete(info);
        }
        stream.removeListener(listener);
      },
      onError: (e, s) {
        if (!completer.isCompleted) completer.completeError(e, s);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }
}

/// The photo and what is behind it: full bleed when the photo is tall, the
/// photo at ~45% of the height between its own colours when it is not, and a
/// blue gradient with the category icon when there is none.
class _StoryBackground extends StatelessWidget {
  const _StoryBackground({required this.item, required this.media});

  final ReturnedItem item;
  final _Media? media;

  /// Behind a story without a photo: the app's blue, at 170°.
  static const _blue = LinearGradient(
    colors: [Color(0xFF2B5FD9), Color(0xFF1D45A8)],
    begin: Alignment(-0.17, -1),
    end: Alignment(0.17, 1),
  );

  @override
  Widget build(BuildContext context) {
    final m = media;
    if (m?.image == null) {
      return DecoratedBox(
        decoration: const BoxDecoration(gradient: _blue),
        child: m == null ? const SizedBox.expand() : Center(child: _GlassTile(icon: item.category.icon)),
      );
    }
    if (m!.isTall) return Image(image: m.image!, fit: BoxFit.cover, excludeFromSemantics: true);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [m.top ?? Colors.black, m.bottom ?? Colors.black],
        ),
      ),
      child: Align(
        // Slightly above the middle, clear of the caption below.
        alignment: const Alignment(0, -0.1),
        child: Image(image: m.image!, fit: BoxFit.fitWidth, width: double.infinity, excludeFromSemantics: true),
      ),
    );
  }
}

/// 200 × 200 glass plate with the category icon, for a story without a photo.
class _GlassTile extends StatelessWidget {
  const _GlassTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 200,
    height: 200,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(60),
      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
    ),
    child: Icon(icon, size: 96, color: Colors.white),
  );
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));
}

/// Progress bars, the verified "Egasiga qaytdi" line with the time, and ✕,
/// over a scrim that keeps them readable on a bright photo.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.count,
    required this.index,
    required this.progress,
    required this.returnedAt,
    required this.onClose,
  });

  final int count, index;
  final Animation<double> progress;
  final DateTime returnedAt;
  final VoidCallback onClose;

  /// "Hozirgina" · "2 soat" · "Kecha" · "3 kun".
  static String when(DateTime d, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final days = DateTime(n.year, n.month, n.day).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (days == 1) return tr('Kecha');
    return TDate.agoShort(d, now: n);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final top = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      // Only ✕ takes a tap here; the rest of the band belongs to the
      // "previous"/"next" zones underneath.
      child: Container(
        constraints: const BoxConstraints(minHeight: 150),
        alignment: Alignment.topCenter,
        padding: EdgeInsets.only(top: top + 8),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x59000000), Color(0x00000000)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  for (var i = 0; i < count; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      child: _Bar(progress: progress, past: i < index, current: i == index),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 4, 10),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 30,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const DecoratedBox(
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: SizedBox(width: 18, height: 18),
                        ),
                        Icon(Symbols.verified_rounded, size: 30, fill: 1, color: cs.primary),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // The line keeps the whole row to itself, so ✕ stays at the
                  // right edge instead of following the end of the text.
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            tr('Egasiga qaytdi'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, color: Colors.white).inter(FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '· ${when(returnedAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.75),
                            ).inter(FontWeight.w400),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: tr('Yopish'),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onClose,
                      child: const SizedBox.square(
                        dimension: 44,
                        child: Icon(Symbols.close_rounded, size: 28, color: Colors.white),
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

/// One progress line: filled for an item already seen, filling for the one on
/// screen, dim for the ones still to come.
class _Bar extends StatelessWidget {
  const _Bar({required this.progress, required this.past, required this.current});

  final Animation<double> progress;
  final bool past, current;

  @override
  Widget build(BuildContext context) {
    final track = Colors.white.withValues(alpha: 0.35);
    final fill = Colors.white.withValues(alpha: 0.95);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 2.5,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: past ? fill : track)),
            if (current)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: progress,
                  builder: (context, _) => FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: progress.value.clamp(0.0, 1.0),
                    child: ColoredBox(color: fill),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Title, the finder's name when they allowed it, and the category and
/// district chips, over a scrim rising from the bottom edge.
class _Caption extends StatelessWidget {
  const _Caption({required this.item});

  final ReturnedItem item;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final finder = item.finderName;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Semantics(
        label: [
          item.title,
          item.category.label,
          item.district,
          tr('{time} egasiga qaytdi', {'time': _TopBar.when(item.returnedAt)}),
          if (finder != null) tr('Topuvchi: {name}', {'name': finder}),
        ].join(', '),
        excludeSemantics: true,
        child: Container(
          constraints: const BoxConstraints(minHeight: 300),
          alignment: Alignment.bottomLeft,
          padding: EdgeInsets.fromLTRB(16, 24, 16, bottom + 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00000000), Color(0xA6000000)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 22, height: 28 / 22, color: Colors.white).inter(FontWeight.w700),
              ),
              if (finder != null) ...[const SizedBox(height: 10), _Finder(name: finder)],
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _Chip(icon: item.category.icon, label: item.category.label),
                  _Chip(icon: Symbols.location_on_rounded, label: item.district),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Topuvchi: Ism F." with an initial disc. Only the person who returned the
/// item is ever named here, and only after they asked to be.
class _Finder extends StatelessWidget {
  const _Finder({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final white = Colors.white.withValues(alpha: 0.9);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), shape: BoxShape.circle),
          child: Text(
            name.characters.isEmpty ? '' : name.characters.first.toUpperCase(),
            style: const TextStyle(fontSize: 12, color: Colors.white).inter(FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                for (final (i, part) in tr('Topuvchi: {name}').split('{name}').indexed) ...[
                  if (i > 0)
                    TextSpan(
                      text: name,
                      style: const TextStyle(color: Colors.white).inter(FontWeight.w700),
                    ),
                  TextSpan(text: part),
                ],
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: white).inter(FontWeight.w400),
          ),
        ),
      ],
    );
  }
}

/// Frosted pill with an icon and a word.
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 30),
        padding: const EdgeInsets.fromLTRB(10, 4, 12, 4),
        color: Colors.white.withValues(alpha: 0.2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.white).inter(FontWeight.w600)),
          ],
        ),
      ),
    ),
  );
}

/// Opening and closing: the tapped circle grows into the screen and shrinks
/// back into it. With "Kamroq harakat" on, or when the row did not say where
/// it was tapped, it is a plain fade.
class ReturnedStoriesTransition extends StatelessWidget {
  const ReturnedStoriesTransition({super.key, required this.animation, required this.source, required this.child});

  final Animation<double> animation;
  final Rect? source;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final from = source;
    if (from == null || MediaQuery.disableAnimationsOf(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    final size = MediaQuery.sizeOf(context);
    final centre = Offset(size.width / 2, size.height / 2);
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final v = curved.value;
        final scale = ui.lerpDouble(size.width == 0 ? 1 : from.width / size.width, 1, v)!;
        final offset = Offset.lerp(from.center - centre, Offset.zero, v)!;
        return Opacity(
          opacity: math.min(1, v * 2.5),
          child: Transform.translate(
            offset: offset,
            child: Transform.scale(
              scale: scale,
              // Scales with the child, so at the start this is a circle the
              // size of the avatar in the row.
              child: ClipRRect(borderRadius: BorderRadius.circular((1 - v) * size.width / 2), child: child),
            ),
          ),
        );
      },
      child: child,
    );
  }
}
