import 'package:flutter/foundation.dart';

import '../data/models/profile.dart';
import '../data/repositories/profile_repository.dart';

/// Backs the profile screen: the profile row, per-metric latest values and
/// histories, and targets. All local, all canonical-metric under the hood.
class ProfileProvider extends ChangeNotifier {
  ProfileProvider({ProfileRepository? repository})
    : _repository = repository ?? ProfileRepository();

  final ProfileRepository _repository;

  Profile? profile;
  Map<String, Measurement> latest = {};
  Map<String, double> targets = {};
  bool loading = true;

  Future<void> load() async {
    profile = await _repository.getProfile();
    latest = await _repository.latestByMetric();
    targets = await _repository.targets();
    loading = false;
    notifyListeners();
  }

  Future<List<Measurement>> history(String metric) => _repository.history(metric);

  Future<void> saveDetails({
    required String name,
    String? birthDate,
    double? heightCm,
  }) async {
    await _repository.updateProfile(
      name: name,
      birthDate: birthDate,
      heightCm: heightCm,
      units: profile?.units ?? Units.metric,
    );
    await load();
  }

  Future<void> toggleUnits() async {
    final next =
        (profile?.units ?? Units.metric) == Units.metric ? Units.imperial : Units.metric;
    await _repository.setUnits(next);
    await load();
  }

  Future<void> addMeasurement(String metric, double canonicalValue) async {
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    await _repository.addMeasurement(metric, canonicalValue, today);
    await load();
  }

  Future<void> deleteMeasurement(int id) async {
    await _repository.deleteMeasurement(id);
    await load();
  }

  Future<void> setTarget(String metric, double canonicalValue) async {
    await _repository.setTarget(metric, canonicalValue);
    await load();
  }

  Future<void> clearTarget(String metric) async {
    await _repository.clearTarget(metric);
    await load();
  }
}
