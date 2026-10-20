import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/t_button.dart';
import '../../domain/entities/listing.dart';
import '../category_ui.dart';
import '../cubit/map_cubit.dart';
import '../widgets/filters_sheet.dart';

/// Map tab. Until a map SDK is added this draws a stylised city and places
/// pins at each listing's approximate area centre.
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<MapCubit>()..load(), child: const _MapView());
  }
}

/// Pin colours from the MapView design.
class _PinColors {
  const _PinColors(this.found, this.lost, this.ring, this.halo);

  final Color found, lost, ring, halo;

  static _PinColors of(BuildContext context) => Theme.of(context).brightness == Brightness.dark
      ? const _PinColors(Color(0xFF4CBF85), Color(0xFFE88A57), Color(0xFF0F1420), Color(0x338DB0FF))
      : const _PinColors(Color(0xFF1E8E5A), Color(0xFFD9692F), Color(0xFFFFFFFF), Color(0x2E2B5FD9));
}

class _MapView extends StatefulWidget {
  const _MapView();

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  late final _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  Animation<Matrix4>? _zoom;

  // Rough bounding box of Tashkent used to project lat/lng onto the canvas.
  static const _north = 41.375, _south = 41.215, _west = 69.175, _east = 69.355;

  @override
  void initState() {
    super.initState();
    _transform.addListener(() => setState(() {}));
    _anim.addListener(() {
      if (_zoom != null) _transform.value = _zoom!.value;
    });
  }

  @override
  void dispose() {
    _transform.dispose();
    _anim.dispose();
    super.dispose();
  }

  /// Projects into the area between the top controls and the preview card.
  Offset _project(double lat, double lng, Size size) {
    const left = 28.0, right = 28.0, top = 170.0, bottom = 260.0;
    final w = size.width - left - right;
    final h = math.max(1.0, size.height - top - bottom);
    return Offset(left + (lng - _west) / (_east - _west) * w, top + (_north - lat) / (_north - _south) * h);
  }

  void _animateTo(Matrix4 target) {
    _zoom = Matrix4Tween(
      begin: _transform.value,
      end: target,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward(from: 0);
  }

  void _zoomInto(Offset canvasPoint, Size size) {
    final scale = (_transform.value.getMaxScaleOnAxis() * 2).clamp(1.0, 4.0);
    final target = Matrix4.identity()
      ..translateByDouble(size.width / 2 - canvasPoint.dx * scale, size.height / 2 - canvasPoint.dy * scale, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
    _animateTo(target);
  }

  Future<void> _openFilters(BuildContext context) async {
    final cubit = context.read<MapCubit>();
    final picked = await showFiltersSheet(
      context,
      filter: cubit.state.filter,
      type: ListingType.found,
      search: cubit.state.search,
    );
    if (picked != null) cubit.setFilter(picked);
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final cubit = context.read<MapCubit>();

    return Scaffold(
      backgroundColor: ts.map,
      body: BlocBuilder<MapCubit, MapState>(
        builder: (context, state) {
          if (state.view case ViewError(:final isOffline)) {
            return SafeArea(
              child: isOffline ? OfflineState(onRetry: cubit.load) : ErrorState(onRetry: cubit.load),
            );
          }
          return LayoutBuilder(
            builder: (context, c) {
              final size = c.biggest;
              final matrix = _transform.value;
              final selected = state.selected;
              final pins = _clusters(state.visible, size, matrix, keepApart: selected?.id);
              return Stack(
                children: [
                  Positioned.fill(
                    child: InteractiveViewer(
                      transformationController: _transform,
                      minScale: 1,
                      maxScale: 4,
                      child: SizedBox.fromSize(size: size, child: const _CityDrawing()),
                    ),
                  ),
                  // "You are here".
                  _positioned(
                    MatrixUtils.transformPoint(matrix, _project(MapCubit.myLat, MapCubit.myLng, size)),
                    18,
                    Semantics(
                      label: 'Siz shu yerdasiz',
                      child: _MeDot(colors: _PinColors.of(context)),
                    ),
                  ),
                  for (final p in pins)
                    if (p.items.first.id == selected?.id)
                      _positioned(
                        p.screen,
                        52,
                        _Pin(
                          listing: p.items.first,
                          selected: true,
                          hiddenNearby: p.items.length - 1,
                          onTap: () => p.items.length > 1 ? _zoomInto(p.canvas, size) : null,
                        ),
                      )
                    else
                      _positioned(
                        p.screen,
                        p.items.length > 1 ? 44 : 40,
                        p.items.length > 1
                            ? _ClusterBubble(count: p.items.length, onTap: () => _zoomInto(p.canvas, size))
                            : _Pin(
                                listing: p.items.first,
                                selected: false,
                                onTap: () => cubit.select(p.items.first.id),
                              ),
                      ),
                  if (state.view is ViewLoading) const Center(child: _LoadingPill()),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(TSpace.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TopBar(
                            onBack: () => context.go(Routes.home),
                            onSearch: cubit.setSearch,
                            onFilters: () => _openFilters(context),
                            filtersActive: !state.filter.isDefault,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: TSpace.xs,
                            runSpacing: TSpace.xs,
                            children: [
                              _TypeToggle(
                                label: 'Topilgan · ${state.count(ListingType.found)}',
                                color: context.tc.found,
                                dot: _PinColors.of(context).found,
                                on: state.showFound,
                                onTap: cubit.toggleFound,
                              ),
                              _TypeToggle(
                                label: 'Yoʻqolgan · ${state.count(ListingType.lost)}',
                                color: context.tc.lost,
                                dot: _PinColors.of(context).lost,
                                on: state.showLost,
                                onTap: cubit.toggleLost,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _FloatingButton(
                              icon: Symbols.my_location_rounded,
                              tooltip: 'Mening joylashuvim',
                              onTap: () {
                                _animateTo(Matrix4.identity());
                                cubit.selectNearest();
                              },
                            ),
                          ),
                          const SizedBox(height: TSpace.md),
                          if (selected != null)
                            _PreviewCard(listing: selected, onTap: () => context.push(Routes.listing(selected.id)))
                          else if (state.view is ViewEmpty || (state.view is ViewLoaded && state.visible.isEmpty))
                            _EmptyCard(
                              onWiden: () {
                                cubit.setFilter(const ListingFilter());
                                if (!state.showFound) cubit.toggleFound();
                                if (!state.showLost) cubit.toggleLost();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      resizeToAvoidBottomInset: false,
    );
  }

  Widget _positioned(Offset center, double size, Widget child) =>
      Positioned(left: center.dx - size / 2, top: center.dy - size / 2, width: size, height: size, child: child);

  /// Screen-space clustering: groups closer than [radius] keep merging
  /// until none overlap. The selected listing never joins a cluster and is
  /// returned last so it draws on top.
  List<_PinGroup> _clusters(List<Listing> items, Size size, Matrix4 m, {String? keepApart}) {
    const radius = 52.0;
    _PinGroup group(Listing l) {
      final canvas = _project(l.lat, l.lng, size);
      return _PinGroup(MatrixUtils.transformPoint(m, canvas), canvas, [l]);
    }

    final selected = [
      for (final l in items)
        if (l.id == keepApart) group(l),
    ];
    final groups = [
      for (final l in items)
        if (l.id != keepApart) group(l),
    ];
    var merged = true;
    while (merged) {
      merged = false;
      for (var i = 0; i < groups.length && !merged; i++) {
        for (var j = i + 1; j < groups.length; j++) {
          if ((groups[i].screen - groups[j].screen).distance < radius) {
            groups[i] = groups[i].merge(groups[j]);
            groups.removeAt(j);
            merged = true;
            break;
          }
        }
      }
    }
    // Anything hidden under the selected pin is folded into it as "+N".
    if (selected.isNotEmpty) {
      final sel = selected.first;
      final under = groups.where((g) => (g.screen - sel.screen).distance < radius).toList();
      for (final g in under) {
        groups.remove(g);
        sel.items.addAll(g.items);
      }
    }
    return [...groups, ...selected];
  }
}

class _PinGroup {
  _PinGroup(this.screen, this.canvas, this.items);

  final Offset screen, canvas;
  final List<Listing> items;

  /// Centroid weighted by item count.
  _PinGroup merge(_PinGroup o) {
    final n = items.length, k = o.items.length;
    Offset mid(Offset a, Offset b) => (a * n.toDouble() + b * k.toDouble()) / (n + k).toDouble();
    return _PinGroup(mid(screen, o.screen), mid(canvas, o.canvas), [...items, ...o.items]);
  }
}

class _CityDrawing extends StatelessWidget {
  const _CityDrawing();

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth, h = c.maxHeight;
          Widget block(double l, double t, double bw, double bh, Color color, {double r = 0, double angle = 0}) =>
              Positioned(
                left: l * w,
                top: t * h,
                width: bw * w,
                height: bh,
                child: Transform.rotate(
                  angle: angle,
                  child: Container(
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(r)),
                  ),
                ),
              );
          Widget vRoad(double l, double width, {double angle = 0}) => Positioned(
            left: l * w,
            top: -40,
            bottom: -40,
            width: width,
            child: Transform.rotate(
              angle: angle,
              child: ColoredBox(color: ts.road),
            ),
          );
          return Container(
            color: ts.map,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                block(-0.1, 0.56, 1.3, 70, ts.water, angle: -0.21),
                block(0.08, 0.30, 0.33, 110, ts.park, r: 28),
                block(0.64, 0.70, 0.31, 90, ts.park, r: 24),
                block(-0.05, 0.24, 1.1, 14, ts.road, angle: 0.14),
                block(-0.05, 0.47, 1.1, 10, ts.road),
                block(-0.05, 0.73, 1.1, 10, ts.road, angle: -0.07),
                vRoad(0.31, 12),
                vRoad(0.69, 10, angle: 0.1),
                vRoad(0.5, 8),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.listing, required this.selected, required this.onTap, this.hiddenNearby = 0});

  final Listing listing;
  final bool selected;
  final VoidCallback onTap;

  /// Listings drawn under this pin; shown as a "+N" badge.
  final int hiddenNearby;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pc = _PinColors.of(context);
    final base = listing.isFound ? pc.found : pc.lost;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${listing.isFound ? 'Topilgan' : 'Yoʻqolgan'}: ${listing.title}'
          '${hiddenNearby > 0 ? ', yana $hiddenNearby ta yaqin atrofda' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Badge(
          isLabelVisible: hiddenNearby > 0,
          label: Text('+$hiddenNearby'),
          backgroundColor: cs.primaryContainer,
          textColor: cs.onPrimaryContainer,
          offset: const Offset(-2, -2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: selected ? cs.primary : base,
              shape: BoxShape.circle,
              border: Border.all(color: pc.ring, width: 3),
              boxShadow: [
                BoxShadow(color: cs.scrim.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Center(
              child: Icon(
                listing.category.icon,
                size: selected ? 24 : 18,
                color: selected ? cs.onPrimary : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClusterBubble extends StatelessWidget {
  const _ClusterBubble({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '$count ta eʼlon, yaqinlashtirish',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            shape: BoxShape.circle,
            border: Border.all(color: _PinColors.of(context).ring, width: 3),
          ),
          child: Text(
            '$count',
            textScaler: TextScaler.noScaling,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}

class _MeDot extends StatelessWidget {
  const _MeDot({required this.colors});

  final _PinColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: colors.ring, width: 3),
        boxShadow: [BoxShadow(color: colors.halo, spreadRadius: 10)],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.onSearch, required this.onFilters, required this.filtersActive});

  final VoidCallback onBack, onFilters;
  final ValueChanged<String> onSearch;
  final bool filtersActive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        _FloatingButton(icon: Symbols.list_rounded, tooltip: 'Roʻyxatga qaytish', onTap: onBack, color: cs.onSurface),
        const SizedBox(width: TSpace.xs),
        Expanded(
          child: _Floating(
            child: SizedBox(
              height: TSize.tapTarget,
              child: TextField(
                onChanged: onSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Shu hududda qidirish',
                  fillColor: cs.surfaceContainerLowest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  prefixIcon: Icon(Symbols.search_rounded, size: 20, color: cs.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: TSpace.xs),
        Badge(
          isLabelVisible: filtersActive,
          smallSize: 10,
          backgroundColor: cs.primary,
          child: _FloatingButton(icon: Symbols.tune_rounded, tooltip: 'Filtrlar', onTap: onFilters),
        ),
      ],
    );
  }
}

class _Floating extends StatelessWidget {
  const _Floating({required this.child, this.radius = TRadius.md});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLowest,
      elevation: 3,
      shadowColor: cs.scrim.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _FloatingButton extends StatelessWidget {
  const _FloatingButton({required this.icon, required this.tooltip, required this.onTap, this.color});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return _Floating(
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({
    required this.label,
    required this.color,
    required this.dot,
    required this.on,
    required this.onTap,
  });

  final String label;
  final Color color, dot;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      toggled: on,
      child: _Floating(
        radius: 18,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: on ? dot : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: dot, width: 2),
                    ),
                  ),
                  const SizedBox(width: TSpace.xs),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: on ? color : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  static String _distance(double m) {
    if (m < 1000) return '${(m / 50).round() * 50} m';
    return '${(m / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final meta =
        '${listing.areaName.split(',').first} · ${TDate.relative(listing.happenedAt)} · '
        '${_distance(MapCubit.distanceTo(listing))}';
    return _Floating(
      radius: TRadius.lg,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhotoPlaceholder(
                icon: listing.category.icon,
                tint: listing.tint,
                width: 132,
                height: 132,
                radius: 10,
                iconSize: 44,
              ),
              const SizedBox(width: TSpace.sm),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 132),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      TypeBadge(isFound: listing.isFound, size: BadgeSize.small),
                      const SizedBox(height: 6),
                      Text(
                        listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meta,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: TSpace.xs),
                      Row(
                        children: [
                          Text(
                            'Batafsil',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary),
                          ),
                          const SizedBox(width: 4),
                          Icon(Symbols.arrow_forward_rounded, size: 16, color: cs.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onWiden});

  final VoidCallback onWiden;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _Floating(
      radius: TRadius.lg,
      child: Padding(
        padding: const EdgeInsets.all(TSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Yaqin atrofda eʼlon yoʻq', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Xaritani suring yoki qidiruv hududini kengaytiring.',
              style: TextStyle(fontSize: 14, color: cs.secondary),
            ),
            const SizedBox(height: TSpace.sm),
            TButton.secondary(label: 'Hududni kengaytirish', onPressed: onWiden),
          ],
        ),
      ),
    );
  }
}

class _LoadingPill extends StatelessWidget {
  const _LoadingPill();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Xarita yuklanmoqda',
      child: _Floating(
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary)),
              const SizedBox(width: 10),
              const Text('Eʼlonlar yuklanmoqda', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
