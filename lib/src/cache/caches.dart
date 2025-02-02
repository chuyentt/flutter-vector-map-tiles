import 'dart:io';

import 'package:path_provider/path_provider.dart';
import '../grid/renderer_pipeline.dart';
import 'memory_image_cache.dart';
import 'storage_cache.dart';
import 'tile_image_cache.dart';
import 'vector_tile_loading_cache.dart';

import '../vector_tile_provider.dart';
import 'byte_storage.dart';
import 'image_tile_loading_cache.dart';

class Caches {
  final ByteStorage _storage = ByteStorage(
      pather: () => getTemporaryDirectory()
          .then((value) => Directory('${value.path}/.vector_map')));
  late final StorageCache _cache;
  late final VectorTileLoadingCache vectorTileCache;
  late final ImageTileLoadingCache imageTileCache;
  late final MemoryImageCache memoryImageCache;

  Caches(
      {required VectorTileProvider provider,
      required RendererPipeline pipeline,
      required Duration ttl,
      required int maxImagesInMemory,
      required int maxSizeInBytes}) {
    _cache = StorageCache(_storage, ttl, maxSizeInBytes);
    vectorTileCache = VectorTileLoadingCache(_cache, provider);
    imageTileCache = ImageTileLoadingCache(TileImageCache(_cache), pipeline);
    memoryImageCache = MemoryImageCache(maxImagesInMemory);
  }

  Future<void> applyConstraints() => _cache.applyConstraints();

  void dispose() {
    memoryImageCache.dispose();
  }

  void didHaveMemoryPressure() {
    memoryImageCache.didHaveMemoryPressure();
    imageTileCache.delegate.memoryCache.didHaveMemoryPressure();
  }

  String stats() {
    final cacheStats = <String>[];
    cacheStats
        .add('Storage cache hit ratio:           ${_cache.hitRatio.asPct()}%');
    cacheStats.add(
        'Image tile cache hit ratio:        ${imageTileCache.hitRatio.asPct()}%');
    cacheStats.add(
        'Image byte memory cache hit ratio: ${imageTileCache.delegate.memoryCache.hitRatio.asPct()}%');
    cacheStats.add(
        'Image cache hit ratio:             ${memoryImageCache.hitRatio.asPct()}%');
    return cacheStats.join('\n');
  }
}

extension _PctExtension on double {
  double asPct() => (this * 1000).roundToDouble() / 10;
}
