enum InstallState { pending, installing, installed, failed }

class CompletedFile {
  final String name;
  final String path;

  CompletedFile({
    required this.name,
    required this.path,
  });
}

class CompletedAppFile extends CompletedFile {
  final InstallState installState;

  CompletedAppFile({
    required super.name,
    required super.path,
    this.installState = InstallState.pending,
  });

  CompletedAppFile copyWith({
    String? name,
    String? path,
    InstallState? installState,
  }) {
    return CompletedAppFile(
      name: name ?? this.name,
      path: path ?? this.path,
      installState: installState ?? this.installState,
    );
  }
}