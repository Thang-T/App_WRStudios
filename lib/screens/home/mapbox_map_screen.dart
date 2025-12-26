import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../providers/post_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/common/wr_logo.dart';
import '../../config/app_router.dart';
import '../../config/map_config.dart';

class MapboxMapScreen extends StatefulWidget {
  const MapboxMapScreen({super.key});

  @override
  State<MapboxMapScreen> createState() => _MapboxMapScreenState();
}

class _MapboxMapScreenState extends State<MapboxMapScreen> {
  final MapController _controller = MapController();
  LatLng _center = const LatLng(10.776889, 106.700806);
  double _radiusKm = 3.0;
  bool _nearbyOnly = false;

  Future<void> _locateMe() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos == null) return;
    setState(() {
      _center = LatLng(pos.latitude, pos.longitude);
    });
    _controller.move(_center, 14);
  }

  double _distanceKm(LatLng a, LatLng b) {
    const R = 6371.0;
    final dLat = (b.latitude - a.latitude) * (3.1415926535 / 180.0);
    final dLon = (b.longitude - a.longitude) * (3.1415926535 / 180.0);
    final aa = (math.sin(dLat / 2) * math.sin(dLat / 2)) + math.cos(a.latitude * (3.1415926535 / 180.0)) * math.cos(b.latitude * (3.1415926535 / 180.0)) * (math.sin(dLon / 2) * math.sin(dLon / 2));
    final c = 2 * math.atan2(math.sqrt(aa), math.sqrt(1 - aa));
    return R * c;
  }

  @override
  Widget build(BuildContext context) {
    final token = MapConfig.mapboxToken;
    final styleId = MapConfig.mapboxStyleId;
    final posts = context.watch<PostProvider>().posts;
    final markers = <Marker>[];
    for (final p in posts) {
      if (p.lat != null && p.lng != null) {
        final ll = LatLng(p.lat!, p.lng!);
        if (_nearbyOnly) {
          final d = _distanceKm(_center, ll);
          if (d > _radiusKm) continue;
        }
        markers.add(Marker(width: 40, height: 40, point: ll, child: GestureDetector(onTap: () => Navigator.pushNamed(context, AppRouter.postDetail, arguments: p.id), child: const Icon(Icons.location_on, color: Colors.blue))));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Row(children: [WRLogo(size: 24, onTap: () => Navigator.pushNamed(context, AppRouter.home)), const SizedBox(width: 8), const Text('Bản đồ (Mapbox)')])),
      body: Stack(children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(initialCenter: _center, initialZoom: 12),
          children: [
            TileLayer(
              urlTemplate: 'https://api.mapbox.com/styles/v1/{styleId}/tiles/256/{z}/{x}/{y}?access_token={accessToken}',
              additionalOptions: {'styleId': styleId, 'accessToken': token},
              retinaMode: true,
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          right: 12,
          top: 12,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Text('Chỉ quanh tôi'), Switch(value: _nearbyOnly, onChanged: (v) => setState(() => _nearbyOnly = v))]),
                const SizedBox(height: 8),
                const Text('Bán kính (km)'),
                Slider(value: _radiusKm, min: 1, max: 10, divisions: 9, label: '${_radiusKm.toStringAsFixed(0)} km', onChanged: (v) => setState(() => _radiusKm = v)),
                ElevatedButton(onPressed: _locateMe, child: const Text('Định vị tôi')),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

