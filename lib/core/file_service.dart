import 'dart:io';
import 'package:nearby_connections/nearby_connections.dart'; 

class FileService {
  static Future<void> moveFileToDownloads(String cacheFilePath, String originalFileName) async {
    try {
      final Directory downloadsDir = Directory('/storage/emulated/0/Download/Bhejde');
      
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Handle Duplicate File Names (e.g., video.mp4 -> video (1).mp4)
      String fileName = originalFileName;
      File destinationFile = File('${downloadsDir.path}/$fileName');
      int counter = 1;

      while (await destinationFile.exists()) {
        final int dotIndex = originalFileName.lastIndexOf('.');
        if (dotIndex != -1) {
          final String nameWithoutExt = originalFileName.substring(0, dotIndex);
          final String ext = originalFileName.substring(dotIndex);
          fileName = '$nameWithoutExt ($counter)$ext';
        } else {
          fileName = '$originalFileName ($counter)';
        }
        destinationFile = File('${downloadsDir.path}/$fileName');
        counter++;
      }

      await Nearby().copyFileAndDeleteOriginal(cacheFilePath, destinationFile.path); 
      
      print("✅ SUCCESS: File natively saved to ${destinationFile.path}");
      
    } catch (e) {
      print("❌ ERROR saving file natively: $e");
    }
  }
}