import 'package:flutter/material.dart';
import '../../widgets/common/wr_logo.dart';
import '../../config/app_router.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          WRLogo(size: 24, onTap: () => Navigator.pushNamed(context, AppRouter.home)),
          const SizedBox(width: 8),
          const Text('Bản đồ căn hộ'),
        ]),
      ),
      body: const Center(
        child: Text('Tính năng bản đồ Google Maps đang tạm thời bảo trì.\nVui lòng sử dụng bản đồ Mapbox hoặc OSM.'),
      ),
    );
  }
}
