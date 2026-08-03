import 'dart:async';
import 'package:bhejde/core/permission_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_document_fetcher/android_document_fetcher.dart';

class DocumentNotifier extends AsyncNotifier<List<DocumentFile>> {
    int _offset=0;
    bool _hasMore=true;
    final int _limit=100;
    final _fetcher=AndroidDocumentFetcher();
    @override
    Future<List<DocumentFile>> build() async {
      await PermissionService.requestPermissions();
        return _fetchPage(_offset);
    }

    Future<List<DocumentFile>> _fetchPage(int offset) async {
        final newDocuments = await _fetcher.getDocuments(offset: _offset, limit: _limit, typeFilters:[DocumentType.pdf, DocumentType.word, DocumentType.excel, DocumentType.powerpoint, DocumentType.text]);
    
        // If the OS returns fewer than 100, we hit the end of the document list
        if (newDocuments.length < _limit) {
        _hasMore = false;
        }
    
        return newDocuments;
    }

    Future<void> loadMoreDocuments() async {
    // Prevent fetching if we are already loading or at the end
    if (!_hasMore || state.isLoading || state.hasError) return;

    _offset += _limit;
    
    // Grab the next batch
    final nextDocs = await _fetchPage(_offset);
    
    // Unpack the current memory and merge it with the new documents
    if (state.hasValue) {
      state = AsyncData([...state.value!, ...nextDocs]);
    }
  }
}

final documentsProvider = AsyncNotifierProvider<DocumentNotifier, List<DocumentFile>>(
  DocumentNotifier.new,
);