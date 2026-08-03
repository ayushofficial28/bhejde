import 'package:bhejde/features/file_selection/document_provider.dart';
import 'package:bhejde/features/file_selection/selection_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class DocumentsTab extends ConsumerStatefulWidget {
  const DocumentsTab({super.key});

  @override
  ConsumerState<DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends ConsumerState<DocumentsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Fetch the next page of docs when the user scrolls near the bottom
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(documentsProvider.notifier).loadMoreDocuments();
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
    // 1. Watch the master list of documents from the native plugin
    final docsAsync = ref.watch(documentsProvider);
    
    // 2. Watch the List of selected files (Single Source of Truth)
    final selectedFilesList = ref.watch(selectedFilesProvider);

    return docsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (docs) {
        if (docs.isEmpty) {
          return const Center(child: Text('No documents found.'));
        }

        // We use ListView instead of GridView because document names are long
        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            
            // 3. Check if the item is in the List by matching the ID
            // Assuming we use the document's file path as its unique ID
            final isSelected = selectedFilesList.any((item) => item.id == doc.path);

            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description, color: Colors.blue),
              ),
              title: Text(
                doc.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Convert raw bytes to MB
              subtitle: Text('${(doc.sizeMb).toStringAsFixed(2)} MB'),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.blue, size: 28)
                  : const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 28),
              onTap: () {
                // 4. Wrap the data in your unified model and send it to the list
                final item = SelectedItem(
                  id: doc.path, 
                  path: doc.path, // We pass path directly instead of 'asset'
                );
                
                ref.read(selectedFilesProvider.notifier).toggleFileSelection(item);
              },
            );
          },
        );
      },
    );
  }
}