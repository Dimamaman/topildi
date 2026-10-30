import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/location/geo_point.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/map/map_tiles.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/t_button.dart';
import '../../../../core/widgets/t_feedback.dart';
import '../../domain/entities/listing.dart';
import '../category_ui.dart';
import '../cubit/map_cubit.dart';
import '../widgets/filters_sheet.dart';
import '../../../../core/l10n/tr.dart';

/// Map tab: OpenStreetMap tiles, pins at each listing's approximate area
/// centre (never the exact spot), screen-space clustering.
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
      ? const _PinColors(Color(0xFF4D7FFF), Color(0xFFFF9F6E), Color(0xFF000000), Color(0x334D7FFF))
      : const _PinColors(Color(0xFF1E8E5A), Color(0xFFD9692F), Color(0xFFFFFFFF), Color(0x2E2B5FD9));
}

LatLng _ll(GeoPoint g) => LatLng(g.lat, g.lng);

class _MapView extends StatefulWidget {
  const _MapView();

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  final _map = MapController();
  MapCamera? _camera;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate(initial: true));
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  Future<void> _locate({bool initial = false}) async {
    final cubit = context.read<MapCubit>();
    final g = await cubit.locate();
    if (!mounted) return;
    if (g != null) {
      if (_camera != null) _map.move(_ll(g), initial ? 14 : math.max(_camera!.zoom, 14));
      return;
    }
    // On first open stay quiet and show the city; explain only when asked.
    final problem = cubit.state.locationProblem;
    if (initial || problem == null) return;
    TFeedback.error(
      context,
      problem.message,
      action: problem == LocationProblem.deniedForever || problem == LocationProblem.serviceOff ? tr('Sozlamalar') : null,
      onAction: cubit.openLocationSettings,
    );
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
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<MapCubit>();
    final pc = _PinColors.of(context);

    return Scaffold(
      backgroundColor: ts.map,
      resizeToAvoidBottomInset: false,
      body: BlocBuilder<MapCubit, MapState>(
        builder: (context, state) {
          if (state.view case ViewError(:final isOffline)) {
            return SafeArea(
              child: isOffline ? OfflineState(onRetry: cubit.load) : ErrorState(onRetry: cubit.load),
            );
          }
          final selected = state.selected;
          final groups = _camera == null
              ? const <_PinGroup>[]
              : _clusters(state.visible, _camera!, keepApart: selected?.id);
          return Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _ll(GeoPoint.tashkent),
                    initialZoom: 12.5,
                    minZoom: 9,
                    maxZoom: 18,
                    backgroundColor: ts.map,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                    onMapReady: () => setState(() => _camera = _map.camera),
                    onPositionChanged: (camera, _) => setState(() => _camera = camera),
                  ),
                  children: [
                    const TopildiTileLayer(),
                    if (selected != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _ll(selected.area),
                            radius: GeoPoint.areaMeters / 2,
                            useRadiusInMeter: true,
                            color: cs.primary.withValues(alpha: 0.12),
                            borderColor: cs.primary.withValues(alpha: 0.5),
                            borderStrokeWidth: 1.5,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (state.hasFix)
                          Marker(
                            point: _ll(state.me),
                            width: 18,
                            height: 18,
                            child: Semantics(
                              label: tr('Siz shu yerdasiz'),
                              child: _MeDot(colors: pc),
                            ),
                          ),
                        for (final g in groups)
                          if (g.items.first.id == selected?.id)
                            Marker(
                              point: g.point,
                              width: 52,
                              height: 52,
                              child: _Pin(
                                listing: g.items.first,
                                selected: true,
                                hiddenNearby: g.items.length - 1,
                                onTap: () => g.items.length > 1 ? _zoomInto(g.point) : null,
                              ),
                            )
                          else if (g.items.length > 1)
                            Marker(
                              point: g.point,
                              width: 44,
                              height: 44,
                              child: _ClusterBubble(count: g.items.length, onTap: () => _zoomInto(g.point)),
                            )
                          else
                            Marker(
                              point: g.point,
                              width: 40,
                              height: 40,
                              child: _Pin(
                                listing: g.items.first,
                                selected: false,
                                onTap: () => cubit.select(g.items.first.id),
                              ),
                            ),
                      ],
                    ),
                  ],
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
                            label: tr('Topilgan · {n}', {'n': state.count(ListingType.found)}),
                            color: context.tc.found,
                            dot: pc.found,
                            on: state.showFound,
                            onTap: cubit.toggleFound,
                          ),
                          _TypeToggle(
                            label: tr('Yoʻqolgan · {n}', {'n': state.count(ListingType.lost)}),
                            color: context.tc.lost,
                            dot: pc.lost,
                            on: state.showLost,
                            onTap: cubit.toggleLost,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Expanded(child: OsmAttribution()),
                          _FloatingButton(
                            icon: Symbols.my_location_rounded,
                            tooltip: tr('Mening joylashuvim'),
                            onTap: _locate,
                          ),
                        ],
                      ),
                      const SizedBox(height: TSpace.md),
                      if (selected != null)
                        _PreviewCard(
                          listing: selected,
                          distance: state.distanceTo(selected),
                          onTap: () => context.push(Routes.listing(selected.id)),
                        )
                      else if (state.view is ViewEmpty || (state.view is ViewLoaded && state.visible.isEmpty))
                        _EmptyCard(
                          onWiden: () {
                            cubit.setFilter(const ListingFilter());
                            if (!state.showFound) cubit.toggleFound();
                            if (!state.showLost) cubit.toggleLost();
                            _map.move(_ll(state.me), 12);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _zoomInto(LatLng point) => _map.move(point, math.min(18, (_camera?.zoom ?? 12) + 2));

  /// Screen-space clustering: groups closer than [radius] keep merging until
  /// none overlap. The selected listing never joins a cluster; anything
  /// hidden under it is folded in as "+N". It is returned last (drawn on top).
  List<_PinGroup> _clusters(List<Listing> items, MapCamera camera, {String? keepApart}) {
    const radius = 52.0;
    _PinGroup group(Listing l) => _PinGroup(camera.latLngToScreenOffset(_ll(l.area)), [l]);

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
  _PinGroup(this.screen, this.items);

  final Offset screen;
  final List<Listing> items;

  /// Average of the members' area centres.
  LatLng get point {
    final first = items.first;
    if (items.length == 1) return _ll(first.area);
    final lat = items.map((l) => l.lat).reduce((a, b) => a + b) / items.length;
    final lng = items.map((l) => l.lng).reduce((a, b) => a + b) / items.length;
    return LatLng(lat, lng);
  }

  _PinGroup merge(_PinGroup o) {
    final n = items.length, k = o.items.length;
    return _PinGroup((screen * n.toDouble() + o.screen * k.toDouble()) / (n + k).toDouble(), [...items, ...o.items]);
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
          '${listing.isFound ? tr('Topilgan') : tr('Yoʻqolgan')}: ${listing.title}'
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
      label: tr('{count} ta eʼlon, yaqinlashtirish', {'count': count}),
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
        _FloatingButton(icon: Symbols.list_rounded, tooltip: tr('Roʻyxatga qaytish'), onTap: onBack, color: cs.onSurface),
        const SizedBox(width: TSpace.xs),
        Expanded(
          child: _Floating(
            child: SizedBox(
              height: TSize.tapTarget,
              child: TextField(
                onChanged: onSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: tr('Shu hududda qidirish'),
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
          child: _FloatingButton(icon: Symbols.tune_rounded, tooltip: tr('Filtrlar'), onTap: onFilters),
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
  const _PreviewCard({required this.listing, required this.distance, required this.onTap});

  final Listing listing;
  final double distance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final meta =
        '${listing.areaName.split(',').first} · ${TDate.relative(listing.happenedAt)} · '
        '${formatDistance(distance)}';
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
                path: listing.photoAt(0),
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
                            tr('Batafsil'),
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
            Text(tr('Yaqin atrofda eʼlon yoʻq'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              tr('Xaritani suring yoki qidiruv hududini kengaytiring.'),
              style: TextStyle(fontSize: 14, color: cs.secondary),
            ),
            const SizedBox(height: TSpace.sm),
            TButton.secondary(label: tr('Hududni kengaytirish'), onPressed: onWiden),
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
      label: tr('Xarita yuklanmoqda'),
      child: _Floating(
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary)),
              const SizedBox(width: 10),
              Text(tr('Eʼlonlar yuklanmoqda'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
