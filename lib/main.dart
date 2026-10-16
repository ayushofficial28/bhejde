import 'dart:async';

import 'package:apks_manager/apks_manager.dart';
import 'package:bhejde/core/share_intent_service.dart';
import 'package:bhejde/features/discovery/discovery_modal.dart';
import 'package:bhejde/features/discovery/home_screen.dart';
import 'package:bhejde/features/file_selection/selection_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApksManager.cleanUpTempDirectory();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<List<SharedMediaFile>>? _shareSubscription;
  bool _isDiscoveryOpen = false;

  @override
  void initState() {
    super.initState();

    // Delay initial share execution until the widget tree and navigator are fully mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialShare();
    });

    _shareSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((
      files,
    ) {
      debugPrint('BACKGROUND SHARE: ${files.length} file(s)');
      _handleSharedFiles(files);
    });
  }

  Future<void> _handleInitialShare() async {
    final files = await ShareIntentService.getInitialFiles();
    debugPrint('INITIAL SHARE: ${files.length} file(s)');
    
    if (files.isNotEmpty) {
      _handleSharedFiles(files);
      ReceiveSharingIntent.instance.reset();
    }
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    if (files.isEmpty || _isDiscoveryOpen) return;

    ShareIntentService.addToSelection(ref, files);
    _isDiscoveryOpen = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final navContext = navigatorKey.currentContext;
      if (navContext == null) {
        _isDiscoveryOpen = false;
        return;
      }

      final shouldClear = await showModalBottomSheet<bool>(
        context: navContext,
        isScrollControlled: true,
        builder: (_) => const DiscoveryModal(),
        isDismissible: false,
        enableDrag: false,
      );

      _isDiscoveryOpen = false;

      if (shouldClear == true) {
        ref.invalidate(selectedFilesProvider);
      }
    });
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'BhejDe',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}