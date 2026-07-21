import 'dart:typed_data';
import 'package:bhejde/features/file_selection/photo_provider.dart';
import 'package:bhejde/features/file_selection/selection_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class VideosTab extends ConsumerStatefulWidget {
  const VideosTab({super.key});

  @override
  ConsumerState<VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends ConsumerState<VideosTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Fetch the next page of videos when the user scrolls near the bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(photosProvider(RequestType.video).notifier).loadMorePhotos();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Helper method to format video duration
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch the master list of videos from the device
    final videosAsync = ref.watch(photosProvider(RequestType.video));

    // 2. Watch the List of selected files
    final selectedFilesList = ref.watch(selectedFilesProvider);

    return videosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (videos) {
        if (videos.isEmpty) {
          return const Center(child: Text('No videos found.'));
        }

        return GridView.builder(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final asset = videos[index];

            // 3. Check if the item is in the List by matching the ID
            final isSelected = selectedFilesList.any(
              (item) => item.id == asset.id,
            );

            return GestureDetector(
              onTap: () {
                // 4. Wrap the data in your unified model and send it to the list
                final item = SelectedItem(id: asset.id, asset: asset);
                ref
                    .read(selectedFilesProvider.notifier)
                    .toggleFileSelection(item);
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // --- The Base Thumbnail ---
                  AssetEntityImage(
                    asset,
                    isOriginal: false,
                    thumbnailSize: const ThumbnailSize.square(200),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),

                  // --- Video UI: Play Icon ---
                  const Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Colors.white70,
                      size:
                          32, // Slightly smaller than the checkmark to fit nicely
                    ),
                  ),

                  // --- Video UI: Duration Badge ---
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(asset.videoDuration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
