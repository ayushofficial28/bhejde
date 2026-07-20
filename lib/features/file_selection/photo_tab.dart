import 'dart:typed_data';
import 'package:bhejde/features/file_selection/photo_provider.dart';
import 'package:bhejde/features/file_selection/selection_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';


class PhotosTab extends ConsumerStatefulWidget {
  const PhotosTab({super.key});

  @override
  ConsumerState<PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends ConsumerState<PhotosTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Fetch the next page of photos when the user scrolls near the bottom
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(photosProvider(RequestType.image).notifier).loadMorePhotos();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch the master list of photos from the device
    final photosAsync = ref.watch(photosProvider(RequestType.image));
    
    // 2. Watch the List of selected files
    final selectedFilesList = ref.watch(selectedFilesProvider);

    return photosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (photos) {
        if (photos.isEmpty) {
          return const Center(child: Text('No photos found.'));
        }

        return GridView.builder(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final asset = photos[index];
            
            // 3. Check if the item is in the List by matching the ID
            final isSelected = selectedFilesList.any((item) => item.id == asset.id);

            return GestureDetector(
              onTap: () {
                // 4. Wrap the data in your unified model and send it to the list
                final item = SelectedItem(
                  id: asset.id, 
                  asset: asset, // Pass the raw entity to extract the path later
                );
                ref.read(selectedFilesProvider.notifier).toggleFileSelection(item);
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // --- The Base Thumbnail ---
                  FutureBuilder<Uint8List?>(
                    future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                    builder: (context, thumbSnapshot) {
                      if (!thumbSnapshot.hasData || thumbSnapshot.data == null) {
                        return Container(color: Colors.grey[200]);
                      }
                      return Image.memory(
                        thumbSnapshot.data!,
                        fit: BoxFit.cover,
                      );
                    },
                  ),

                  // --- The Selection Overlay ---
                  if (isSelected)
                    Container(
                      color: Colors.black.withOpacity(0.4),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}