import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Owns the profile photo on disk: picking one from the gallery, copying it
/// into a stable app-documents folder, resolving a stored file name back to an
/// absolute [File], and deleting it. Only the file *name* is persisted (in the
/// profile row) — the absolute path is rebuilt here, so photos survive the app
/// sandbox path moving between launches/updates.
class ProfilePhotoService {
  ProfilePhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const _subdir = 'profile_photos';

  Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _subdir));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Resolve a stored file name to an absolute [File] (which may not exist).
  Future<File> fileFor(String fileName) async =>
      File(p.join((await _dir()).path, fileName));

  /// Prompt the gallery, copy the chosen image into the profile folder under a
  /// fresh unique name (so the image cache never shows a stale picture), delete
  /// [previous] if given, and return the new file name — or null if the user
  /// cancelled.
  Future<String?> pickFromGallery({String? previous}) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final dir = await _dir();
    final ext = p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path);
    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}$ext';
    await File(picked.path).copy(p.join(dir.path, fileName));
    if (previous != null) await deleteQuietly(previous);
    return fileName;
  }

  /// Best-effort delete of a stored photo; never throws.
  Future<void> deleteQuietly(String fileName) async {
    try {
      final f = await fileFor(fileName);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // A missing or unremovable file is fine — the DB pointer is the source
      // of truth and is cleared separately.
    }
  }
}
