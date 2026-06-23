import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/library_controller.dart';
import '../models/photo_asset.dart';
import 'photo_grid_cell.dart';

/// 图片网格视图
///
/// - 非选择模式：点击 → 全屏查看器；长按 → 进入选择模式
/// - 选择模式：点击 → 切换选中状态；长按 → 无效果（已在选择模式）
class PhotoGrid extends GetView<LibraryController> {
  const PhotoGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.photos.isEmpty) return const SizedBox.shrink();

      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 400) {
            controller.loadMore();
          }
          return false;
        },
        child: GridView.builder(
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
                isSelectionMode: controller.isSelectionMode.value,
                isCompressed: controller.isCompressed(asset.id),
                onTap: () => _onTap(asset, index),
                onLongPress: () => _onLongPress(asset),
              ),
            );
          },
        ),
      );
    });
  }

  void _onTap(PhotoAsset asset, int index) {
    if (controller.isSelectionMode.value) {
      controller.toggleSelection(asset.id);
    } else {
      controller.openViewer(index);
    }
  }

  void _onLongPress(PhotoAsset asset) {
    if (!controller.isSelectionMode.value) {
      controller.enterSelectionMode(asset.id);
    }
  }
}
