import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/library_controller.dart';
import '../models/photo_asset.dart';
import 'photo_grid_cell.dart';

/// 图片网格视图（支持多选模式）
class PhotoGrid extends GetView<LibraryController> {
  const PhotoGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.photos.isEmpty) return const SizedBox.shrink();

      return GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: controller.photos.length,
        itemBuilder: (context, index) {
          final asset = controller.photos[index];
          return Obx(
            () => PhotoGridCell(
              asset: asset,
              isSelected: controller.isSelected(asset.id),
              isSelectionMode: controller.selectedIds.isNotEmpty,
              onTap: () => _onCellTap(asset),
            ),
          );
        },
      );
    });
  }

  void _onCellTap(PhotoAsset asset) {
    controller.toggleSelection(asset.id);
  }
}
