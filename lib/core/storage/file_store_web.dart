/// Web 平台 FileStore 存根 — 文件系统操作在 Web 上不可用
class FileStore {
  FileStore._();

  static final FileStore instance = FileStore._();

  Future<void> init() async {}

  Future<String> outputPathForId(String id) async => '/web/$id.avif';

  Future<void> deleteFile(String path) async {}

  Future<int> totalCompressedSize() async => 0;
}
