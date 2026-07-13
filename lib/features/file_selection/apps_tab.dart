import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_provider.dart';
import 'selection_provider.dart';

class AppsTab extends ConsumerWidget {
  const AppsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsyncValue = ref.watch(appProvider);
    final selectedFiles = ref.watch(selectedFilesProvider);

    return appsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stack) => Center(child: Text('Error loading apps: $e')),
      data: (apps) {
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, 
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: apps.length,
          itemBuilder: (context, index) {
            final app = apps[index];
            
            final isSelected = selectedFiles.contains(app.apkPath);

            return GestureDetector(
              onTap: () {
                // We pass the raw .apk path to the Riverpod cart
                ref.read(selectedFilesProvider.notifier).toggleFileSelection(app.apkPath);
              },
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (app.iconBytes != null)
                        Image.memory(app.iconBytes, width: 50, height: 50)
                      else
                        const Icon(Icons.android, size: 50), // Fallback
                      
                      const SizedBox(height: 8),
                      Text(
                        app.appName, // The new package uses 'name' instead of 'appName'
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis, 
                        maxLines: 1,
                      ),
                    ],
                  ),
                  
                  if (isSelected)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 20),
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