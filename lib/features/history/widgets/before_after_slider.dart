import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/codec/android/android_avif_encoder.dart'
    if (dart.library.html) '../../../core/codec/web/web_avif_encoder_stub.dart';
import '../../../core/platform/platform_file.dart' as pf;
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loading.dart';

/// 前后对比滑动控件
///
/// 左侧显示原图（通过 photo_manager 缓存路径），右侧显示压缩后 AVIF 图片。
/// 用户拖拽中央 divider 改变显示比例。
class BeforeAfterSlider extends StatefulWidget {
  const BeforeAfterSlider({
    required this.originalPath,
    required this.compressedPath,
    this.initialPosition = 0.5,
    super.key,
  });

  /// 原图文件路径（null 时显示占位）
  final String? originalPath;

  /// 压缩后 AVIF 路径
  final String compressedPath;

  /// 初始分割位置（0.0-1.0）
  final double initialPosition;

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  late double _position;
  late final Future<Uint8List?> _compressedFuture;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _compressedFuture = _loadCompressed();
  }

  Future<Uint8List?> _loadCompressed() {
    // Android 不支持原生 AVIF 解码（API < 31），通过 JNI dav1d 解码后转 JPEG
    if (defaultTargetPlatform != TargetPlatform.android)
      return Future<Uint8List?>.value();
    return AndroidAvifEncoder.decode(widget.compressedPath, maxSide: 2048);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return GestureDetector(
          onHorizontalDragUpdate: (d) {
            setState(() {
              _position = (_position + d.delta.dx / width).clamp(0.02, 0.98);
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 右侧：压缩后 AVIF（Android 异步解码，iOS 直接显示）
              _buildCompressedImage(),
              // 左侧：原图（clip 到 position 以左）
              ClipRect(
                clipper: _LeftClipper(_position),
                child: _buildOriginalImage(),
              ),
              // 分割线
              Positioned(
                left: width * _position - 1,
                top: 0,
                bottom: 0,
                child: _buildDivider(),
              ),
              // 标签
              _buildLabel(Alignment.topLeft, 'BEFORE'),
              _buildLabel(Alignment.topRight, 'AFTER'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompressedImage() {
    if (defaultTargetPlatform != TargetPlatform.android) {
      // iOS：系统原生支持 AVIF，直接读文件
      return pf.buildFileImage(widget.compressedPath);
    }
    // Android：通过 dav1d JNI 解码 AVIF → JPEG bytes
    return FutureBuilder<Uint8List?>(
      future: _compressedFuture,
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return _imagePlaceholder();
        }
        return const AppLoading();
      },
    );
  }

  Widget _buildOriginalImage() {
    if (widget.originalPath == null) {
      return _imagePlaceholder();
    }
    return pf.buildFileImage(widget.originalPath!);
  }

  Widget _imagePlaceholder() => Container(
    color: Colors.grey[400],
    child: const Center(
      child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
    ),
  );

  Widget _buildDivider() {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(width: 2, color: Colors.white),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.swap_horiz,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(Alignment alignment, String text) {
    return Positioned(
      top: 16,
      left: alignment == Alignment.topLeft ? 16 : null,
      right: alignment == Alignment.topRight ? 16 : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  const _LeftClipper(this.position);

  final double position;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * position, size.height);

  @override
  bool shouldReclip(_LeftClipper old) => old.position != position;
}
