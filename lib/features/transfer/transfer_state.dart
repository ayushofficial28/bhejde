import 'completed_file.dart';

enum TransferStatus { idle, preparing, transferring, completed, error }
enum TransferRole { sender, receiver, none } 

class TransferState {
  final TransferStatus status;
  final TransferRole role;              
  final String connectedDeviceName;     
  
  // File Counts
  final int totalFiles;
  final int filesTransferred;
  final String currentFileName;

  // Byte Progress (For smooth progress bars)
  final double currentFileProgress;     // 0.0 to 1.0
  final int totalBytesToTransfer;       
  final int totalBytesTransferred;    

  List<CompletedFile> completedFiles; // List to hold completed files  
  
  final String? errorMessage;           

  TransferState({
    this.status = TransferStatus.idle,
    this.role = TransferRole.none,
    this.connectedDeviceName = 'Unknown Device',
    this.totalFiles = 0,
    this.filesTransferred = 0,
    this.currentFileName = '',
    this.currentFileProgress = 0.0,
    this.totalBytesToTransfer = 0,
    this.totalBytesTransferred = 0,
    this.errorMessage,
    this.completedFiles = const [],
  });

  TransferState copyWith({
    TransferStatus? status,
    TransferRole? role,
    String? connectedDeviceName,
    int? totalFiles,
    int? filesTransferred,
    String? currentFileName,
    double? currentFileProgress,
    int? totalBytesToTransfer,
    int? totalBytesTransferred,
    String? errorMessage,
    List<CompletedFile>? completedFiles,
  }) {
    return TransferState(
      status: status ?? this.status,
      role: role ?? this.role,
      connectedDeviceName: connectedDeviceName ?? this.connectedDeviceName,
      totalFiles: totalFiles ?? this.totalFiles,
      filesTransferred: filesTransferred ?? this.filesTransferred,
      currentFileName: currentFileName ?? this.currentFileName,
      currentFileProgress: currentFileProgress ?? this.currentFileProgress,
      totalBytesToTransfer: totalBytesToTransfer ?? this.totalBytesToTransfer,
      totalBytesTransferred: totalBytesTransferred ?? this.totalBytesTransferred,
      errorMessage: errorMessage ?? this.errorMessage,
      completedFiles: completedFiles ?? this.completedFiles,
    );
  }
}