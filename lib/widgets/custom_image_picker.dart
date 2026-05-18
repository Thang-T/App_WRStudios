import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'dart:io' show Platform, File;

class CustomImagePicker extends StatefulWidget {
  final int maxImages;

  const CustomImagePicker({Key? key, this.maxImages = 10}) : super(key: key);

  @override
  State<CustomImagePicker> createState() => _CustomImagePickerState();
}

class _CustomImagePickerState extends State<CustomImagePicker> {
  List<AssetEntity> _mediaList = [];
  final List<AssetEntity> _selectedList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _fetchAssets();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAssets() async {
    if (kIsWeb) return;
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có quyền truy cập thư viện ảnh')),
        );
      }
      return;
    }

    List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (albums.isNotEmpty) {
      List<AssetEntity> photos = await albums[0].getAssetListPaged(page: 0, size: 100);
      if (mounted) {
        setState(() {
          _mediaList = photos;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onAssetTap(AssetEntity asset) {
    setState(() {
      if (_selectedList.contains(asset)) {
        _selectedList.remove(asset);
      } else {
        if (_selectedList.length < widget.maxImages) {
          _selectedList.add(asset);
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chỉ được chọn tối đa ${widget.maxImages} ảnh')),
          );
        }
      }
    });
  }

  Future<void> _done() async {
    List<File> files = [];
    for (var asset in _selectedList) {
      final file = await asset.file;
      if (file != null) {
        files.add(file);
      }
    }
    if (mounted) {
      Navigator.pop(context, files);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chọn ảnh')),
        body: const Center(
          child: Text('Image picker không hỗ trợ trên web. Vui lòng dùng ứng dụng di động.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn ảnh'),
        actions: [
          TextButton(
            onPressed: _selectedList.isNotEmpty ? _done : null,
            child: Text(
              'Xong (${_selectedList.length})',
              style: TextStyle(
                color: _selectedList.isNotEmpty ? Colors.blue : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mediaList.isEmpty
              ? const Center(child: Text('Không tìm thấy ảnh nào'))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: _mediaList.length,
                  itemBuilder: (context, index) {
                    final asset = _mediaList[index];
                    final isSelected = _selectedList.contains(asset);

                    return GestureDetector(
                      onTap: () => _onAssetTap(asset),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image(
                            image: AssetEntityImageProvider(
                              asset,
                              isOriginal: false,
                              thumbnailSize: const ThumbnailSize.square(200),
                            ),
                            fit: BoxFit.cover,
                          ),
                          if (isSelected)
                            Container(
                              color: Colors.black45,
                              child: const Center(
                                child: Icon(Icons.check_circle, color: Colors.blue, size: 30),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
