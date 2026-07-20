import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotosNotifier extends AsyncNotifier<List<AssetEntity>> {
  int _currentPage = 0;
  bool _hasMore = true;
  AssetPathEntity? _recentAlbum;
  RequestType requestType;
  PhotosNotifier(this.requestType) : super();

  @override
  Future<List<AssetEntity>> build() async {
    await PhotoManager.requestPermissionExtend();
    
    // Fetch the master list of image albums
    final albums = await PhotoManager.getAssetPathList(type: requestType);
    
    if (albums.isEmpty) return [];
    
    // Grab the "Recent" master album and fetch the first page
    _recentAlbum = albums.first;
    return _fetchPage(_currentPage);
  }

  // Internal helper to handle the specific OS request
  Future<List<AssetEntity>> _fetchPage(int page) async {
    if (_recentAlbum == null) return [];
    
    final newPhotos = await _recentAlbum!.getAssetListPaged(
      page: page,
      size: 100, // Hardcoded page size
    );

    // If the OS returns fewer than 100, we hit the end of the camera roll
    if (newPhotos.length < 100) {
      _hasMore = false;
    }

    return newPhotos;
  }

  // The function your UI will trigger when scrolling to the bottom
  Future<void> loadMorePhotos() async {
    // Prevent fetching if we are already loading or at the end
    if (!_hasMore || state.isLoading || state.hasError) return;

    _currentPage++;
    
    // Grab the next 100 photos
    final nextPhotos = await _fetchPage(_currentPage);
    
    // Unpack the current memory and merge it with the new photos
    if (state.hasValue) {
      state = AsyncData([...state.value!, ...nextPhotos]);
    }
  }
}

// Expose the notifier to the rest of the app
final photosProvider = AsyncNotifierProvider.family<PhotosNotifier, List<AssetEntity>, RequestType>(
  PhotosNotifier.new,
);