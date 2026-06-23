import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/photo_asset.dart';

/// 相册网格中的单个图片单元格
class PhotoGridCell extends StatelessWidget {
  const PhotoGridCell({
    required this.asset,
    required this.isSelected,
    required this.isSelectionMode,
    required this.isCompressed,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  final PhotoAsset asset;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isCompressed;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildThumbnail(),
          if (isSelectionMode) _buildSelectionOverlay(),
          _buildBadges(),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: FutureBuilder<Uint8List?>(
        future: _loadThumbnail(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return Container(
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }

  Future<Uint8List?> _loadThumbnail() async {
    final entity = await AssetEntity.fromId(asset.id);
    if (entity == null) return null;
    return entity.thumbnailDataWithSize(const ThumbnailSize(200, 200));
  }

  Widget _buildSelectionOverlay() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 3)
            : null,
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.2)
            : Colors.transparent,
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: isSelected
                ? const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 22,
                    key: ValueKey('checked'),
                  )
                : Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      color: Colors.black26,
                    ),
                    key: const ValueKey('unchecked'),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadges() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                asset.displaySize,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
            if (isCompressed) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'AVIF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
