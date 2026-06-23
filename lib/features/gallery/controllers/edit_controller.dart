import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/logger_util.dart';
import '../../library/models/photo_asset.dart';

/// 图片编辑控制器
class EditController extends GetxController {
  EditController({required this.asset, required this.sourcePath});

  final PhotoAsset asset;

  /// 当前编辑使用的源文件路径（crop 后为临时 crop 路径，否则为原始路径）
  final String sourcePath;

  final brightness = 1.0.obs; // 0.5 – 1.5，1.0 = 无变化
  final contrast = 1.0.obs; // 0.5 – 1.5，1.0 = 无变化
  final saturation = 1.0.obs; // 0.0 – 2.0，1.0 = 无变化
  final isSaving = false.obs;

  String? _croppedPath;

  String get currentSourcePath => _croppedPath ?? sourcePath;

  bool get hasChanges =>
      brightness.value != 1.0 ||
      contrast.value != 1.0 ||
      saturation.value != 1.0 ||
      _croppedPath != null;

  @override
  void onInit() {
    super.onInit();
    _cleanupOldEditedFiles();
  }

  void resetAdjustments() {
    brightness.value = 1.0;
    contrast.value = 1.0;
    saturation.value = 1.0;
  }

  void resetAll() {
    resetAdjustments();
    _croppedPath = null;
  }

  Future<void> crop() async {
    final result = await ImageCropper().cropImage(
      sourcePath: currentSourcePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁剪',
          toolbarColor: const Color(0xFF000000),
          toolbarWidgetColor: const Color(0xFFFFFFFF),
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: '裁剪',
          doneButtonTitle: '完成',
          cancelButtonTitle: '取消',
        ),
      ],
    );
    if (result != null) {
      _croppedPath = result.path;
    }
  }

  /// 保存编辑结果。
  ///
  /// [overwriteOriginal] = true 时将编辑后文件写入系统相册并删除原始照片。
  /// 返回保存后的文件路径，失败返回 null。
  Future<String?> save({required bool overwriteOriginal}) async {
    if (isSaving.value) return null;
    isSaving.value = true;
    try {
      final bytes = await File(currentSourcePath).readAsBytes();
      final outputBytes = await compute(
        _applyAdjustmentsIsolate,
        _AdjustParams(
          bytes: bytes,
          brightness: brightness.value,
          contrast: contrast.value,
          saturation: saturation.value,
        ),
      );

      final savedPath = await _writeEditedFile(outputBytes);

      if (overwriteOriginal) {
        await _replaceInSystemLibrary(savedPath);
      }

      return savedPath;
    } catch (e, stack) {
      LoggerUtil.e('Edit save failed', e, stack);
      return null;
    } finally {
      isSaving.value = false;
    }
  }

  Future<String> _writeEditedFile(Uint8List bytes) async {
    final docDir = await getApplicationDocumentsDirectory();
    final editedDir = Directory('${docDir.path}/edited');
    await editedDir.create(recursive: true);
    final path = '${editedDir.path}/${const Uuid().v4()}.jpg';
    await File(path).writeAsBytes(bytes);
    return path;
  }

  /// 保存到系统相册并删除原始图片（"覆盖原图"语义）
  Future<void> _replaceInSystemLibrary(String editedPath) async {
    try {
      await PhotoManager.editor.saveImageWithPath(editedPath, title: 'edited');
      await PhotoManager.editor.deleteWithIds([asset.id]);
    } catch (e) {
      LoggerUtil.w('Replace in system library failed: $e');
    }
  }

  /// 启动时清理 7 天前的临时编辑文件
  Future<void> _cleanupOldEditedFiles() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final editedDir = Directory('${docDir.path}/edited');
      if (!editedDir.existsSync()) return;
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      await for (final entity in editedDir.list()) {
        if (entity is File) {
          final stat = entity.statSync();
          if (stat.modified.isBefore(cutoff)) {
            await entity.delete().catchError((_) => entity);
          }
        }
      }
    } catch (_) {}
  }
}

// ─── isolate 处理函数（顶层，compute 要求）──────────────────────

class _AdjustParams {
  const _AdjustParams({
    required this.bytes,
    required this.brightness,
    required this.contrast,
    required this.saturation,
  });

  final Uint8List bytes;
  final double brightness; // 0.5–1.5，1.0=无变化
  final double contrast; // 0.5–1.5，1.0=无变化
  final double saturation; // 0.0–2.0，1.0=无变化
}

/// 在独立 Isolate 中对图片应用亮度 / 对比度 / 饱和度调整
Uint8List _applyAdjustmentsIsolate(_AdjustParams params) {
  final src = img.decodeImage(params.bytes);
  if (src == null) return params.bytes;

  // 亮度偏移量（-1 到 1，转 0-255 范围）
  final bOffset = (params.brightness - 1.0) * 255.0;

  // 对比度
  final c = params.contrast;
  // 对比度中心偏移：使对比度调整以 128（灰） 为基准
  final cOffset = 128.0 * (1.0 - c);

  // 合并亮度 + 对比度后的总偏移
  final combinedOffset = c * bOffset + cOffset;

  // 饱和度（使用 Rec.709 亮度权重）
  const rw = 0.2126;
  const gw = 0.7152;
  const bw = 0.0722;
  final s = params.saturation;

  // 最终变换矩阵系数（含饱和度 × 对比度缩放）
  final rr = c * (s + rw * (1 - s));
  final rg = c * gw * (1 - s);
  final rb = c * bw * (1 - s);
  final gr = c * rw * (1 - s);
  final gg = c * (s + gw * (1 - s));
  final gb = c * bw * (1 - s);
  final br = c * rw * (1 - s);
  final bg = c * gw * (1 - s);
  final bb = c * (s + bw * (1 - s));

  final dst = img.Image(
    width: src.width,
    height: src.height,
    numChannels: src.numChannels,
  );

  for (final pixel in src) {
    final r = pixel.r.toDouble();
    final g = pixel.g.toDouble();
    final b = pixel.b.toDouble();

    final nr = (rr * r + rg * g + rb * b + combinedOffset).clamp(0.0, 255.0);
    final ng = (gr * r + gg * g + gb * b + combinedOffset).clamp(0.0, 255.0);
    final nb = (br * r + bg * g + bb * b + combinedOffset).clamp(0.0, 255.0);

    dst.setPixelRgb(pixel.x, pixel.y, nr.round(), ng.round(), nb.round());
  }

  return Uint8List.fromList(img.encodeJpg(dst, quality: 90));
}
