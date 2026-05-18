import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  // Check if running on Simulator
  static Future<bool> _isSimulator() async {
    if (kIsWeb) return false;
    if (Platform.isIOS) {
      final deviceInfo = DeviceInfoPlugin();
      final iosInfo = await deviceInfo.iosInfo;
      return !iosInfo.isPhysicalDevice;
    }
    return false;
  }

  // Decide whether to use Files picker on iOS (Simulator or iOS 18+ unstable PHPicker)
  // iOS Files picker fallback helper decision removed; we fallback inline in methods

  // Files picker helpers removed

  // Request camera permission
  static Future<bool> requestCameraPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Request gallery permission
  static Future<bool> requestGalleryPermission() async {
    // Web không cần permission
    if (kIsWeb) return true;
    // Trên iOS (iOS 14+), PHPicker tự xử lý quyền — tránh can thiệp thủ công
    if (Platform.isIOS) return true;

    final status = await Permission.photos.request();
    return status.isGranted;
  }

  // Pick single image from gallery
  static Future<XFile?> pickImageFromGallery() async {
    try {
      // Web: dùng image_picker (hỗ trợ web tốt hơn)
      if (kIsWeb) {
        final image = await _picker.pickImage(source: ImageSource.gallery);
        return image;
      }
      // Note: On iOS 14+, PHPicker handles permissions automatically.
      if (!Platform.isIOS) {
        final hasPermission = await requestGalleryPermission();
        if (!hasPermission) {
          return null;
        }
      }

      // iOS: dùng PHPicker (image_picker) để chọn từ Photos
      if (Platform.isIOS) {
         // FORCE FILE PICKER ON IOS TEMPORARILY
         // This is to solve the Simulator freeze issue immediately for the user.
         // Even on physical device, this will just open Files app which is fine for now.
         return await _pickSingleWithFilePicker();
      }

      // Keep simulator check for sizing parameters below
      final isSim = await _isSimulator();

      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: isSim ? null : 85, // No resize on Simulator
        maxWidth: isSim ? null : 1024,
        maxHeight: isSim ? null : 1024,
        requestFullMetadata: !isSim, // Optimize for Simulator
      );

      return image;
    } catch (e) {
      debugPrint('Pick image error: $e');
      return null;
    }
  }

  // Take photo with camera
  static Future<XFile?> takePhotoWithCamera() async {
    try {
      // Camera không hỗ trợ trên web
      if (kIsWeb) {
        debugPrint('Camera not supported on web');
        return null;
      }
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        return null;
      }

      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      return image;
    } catch (e) {
      debugPrint('Take photo error: $e');
      return null;
    }
  }

  // Pick multiple images from gallery
  static Future<List<XFile>> pickMultipleImages({int maxImages = 10}) async {
    try {
      // Web: dùng image_picker (hỗ trợ web tốt hơn)
      if (kIsWeb) {
        final images = await _picker.pickMultiImage(
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 70,
        );
        return images.take(maxImages).toList();
      }
      // Note: On iOS 14+, PHPicker handles permissions automatically.
      // We only request permission explicitly on Android or Web if needed.
      if (!Platform.isIOS) {
           final hasPermission = await requestGalleryPermission();
           if (!hasPermission) return [];
      }

      // iOS: dùng PHPicker để chọn nhiều ảnh từ Photos
      if (Platform.isIOS) {
         // FORCE FILE PICKER ON IOS TEMPORARILY
         return await _pickMultipleWithFilePicker(maxImages);
      }

      final images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
        limit: maxImages,
      );

      return images;
    } catch (e) {
      debugPrint('Pick multiple images error: $e');
      return [];
    }
  }

  // Files picker helpers
  static Future<XFile?> _pickSingleWithFilePicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Đọc bytes để hỗ trợ cả web và mobile
      );
      if (result == null || result.files.isEmpty) return null;
      final file = result.files.first;
      if (kIsWeb && file.bytes != null) {
        // Web: tạo XFile từ bytes
        return XFile.fromData(
          file.bytes!,
          name: file.name,
          mimeType: _getMimeType(file.extension),
        );
      } else if (file.path != null) {
        // Mobile: dùng path trực tiếp
        return XFile(file.path!);
      }
      return null;
    } catch (e) {
      debugPrint('FilePicker single error: $e');
      return null;
    }
  }

  static Future<List<XFile>> _pickMultipleWithFilePicker(int maxImages) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true, // Đọc bytes để hỗ trợ cả web và mobile
      );
      if (result == null) return [];
      final files = result.files
          .where((f) => kIsWeb ? f.bytes != null : f.path != null)
          .map((f) {
            if (kIsWeb && f.bytes != null) {
              return XFile.fromData(
                f.bytes!,
                name: f.name,
                mimeType: _getMimeType(f.extension),
              );
            }
            return XFile(f.path!);
          })
          .toList();
      return files.take(maxImages).toList();
    } catch (e) {
      debugPrint('FilePicker multiple error: $e');
      return [];
    }
  }

  static String? _getMimeType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'heic':
        return 'image/heic';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  // Public helpers for fallback
  static Future<List<XFile>> pickMultipleImagesFromFiles({int maxImages = 10}) async {
    return await _pickMultipleWithFilePicker(maxImages);
  }

  static Future<XFile?> pickImageFromFiles() async {
    return await _pickSingleWithFilePicker();
  }

  // Show image source dialog
  static Future<XFile?> showImageSourceDialog(BuildContext context) async {
    return await showDialog<XFile?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn ảnh từ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () async {
                try {
                  final image = await takePhotoWithCamera();
                  if (!context.mounted) return;
                  Navigator.pop(context, image);
                } catch (e) {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi camera: $e'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () async {
                try {
                  final image = await pickImageFromGallery();
                  if (!context.mounted) return;
                  Navigator.pop(context, image);
                } catch (e) {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi thư viện: $e'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }
}
