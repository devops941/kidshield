import '../models/child_model.dart';
import '../models/restriction_model.dart';
import 'api_service.dart';

class ChildService {
  final ApiService _api = ApiService();

  static List<ChildModel> _localChildren = [];

  ChildService();

  Future<List<ChildModel>> getChildren(String parentId) async {
    try {
      final list = await _api.getChildren();
      final Map<String, ChildModel> uniqueMap = {};
      for (final item in list) {
        final id = (item['_id'] ?? item['id'] ?? 'child_1').toString();
        final child = ChildModel.fromMap(item as Map<String, dynamic>, id);
        final key = child.id.isNotEmpty ? child.id : child.pairingCode;
        uniqueMap[key] = child;
      }
      _localChildren = uniqueMap.values.toList();
      return List.from(_localChildren);
    } catch (_) {
      final Map<String, ChildModel> uniqueMap = {};
      for (final c in _localChildren) {
        final key = c.id.isNotEmpty ? c.id : c.pairingCode;
        uniqueMap[key] = c;
      }
      _localChildren = uniqueMap.values.toList();
      return List.from(_localChildren);
    }
  }

  Future<ChildModel> addChild({
    required String parentId,
    required String name,
    required int age,
    String gender = 'boy',
    String? photoUrl,
    String? phoneNumber,
    int dailyLimitMinutes = 180,
    String bedtimeStart = '21:30',
    String bedtimeEnd = '06:30',
  }) async {
    final res = await _api.addChild(
      name: name,
      age: age,
      gender: gender,
      phoneNumber: phoneNumber,
      dailyLimitMinutes: dailyLimitMinutes,
      bedtimeStart: bedtimeStart,
      bedtimeEnd: bedtimeEnd,
    );

    if (res['success'] == true && res['child'] != null) {
      final c = res['child'] as Map<String, dynamic>;
      final child = ChildModel.fromMap(c, c['_id'] ?? c['id']);
      final idx = _localChildren.indexWhere((item) =>
          (item.id.isNotEmpty && item.id == child.id) ||
          (item.pairingCode.isNotEmpty && item.pairingCode == child.pairingCode));
      if (idx != -1) {
        _localChildren[idx] = child;
      } else {
        _localChildren.add(child);
      }
      return child;
    }

    final errorMsg = res['message'] ?? 'Failed to create child profile';
    throw Exception(errorMsg);
  }

  Future<void> updateChildRestrictions({
    required String childId,
    required RestrictionModel restrictions,
  }) async {
    try {
      await _api.updateRestrictions(childId, restrictions.toMap());
    } catch (_) {}

    final index = _localChildren.indexWhere((c) => c.id == childId);
    if (index != -1) {
      _localChildren[index] = _localChildren[index].copyWith(
        dailyScreenTimeLimitMinutes: restrictions.dailyScreenTimeMinutes,
        bedtimeStart: restrictions.bedtimeStart,
        bedtimeEnd: restrictions.bedtimeEnd,
        studyTimeStart: restrictions.studyTimeStart,
        studyTimeEnd: restrictions.studyTimeEnd,
      );
    }
  }

  Future<void> removeChild(String childId) async {
    await _api.removeChild(childId);
    _localChildren.removeWhere((c) => c.id == childId);
  }

  Future<String?> regeneratePairingCode(String childId) async {
    final res = await _api.regeneratePairingCode(childId);
    if (res['success'] == true && res['pairingCode'] != null) {
      final newCode = res['pairingCode'].toString();
      final index = _localChildren.indexWhere((c) => c.id == childId);
      if (index != -1) {
        _localChildren[index] = _localChildren[index].copyWith(pairingCode: newCode);
      }
      return newCode;
    }
    return null;
  }

  Future<bool> unpairDevice(String childId) async {
    final success = await _api.unpairDevice(childId);
    if (success) {
      final index = _localChildren.indexWhere((c) => c.id == childId);
      if (index != -1) {
        _localChildren[index] = _localChildren[index].copyWith(isPaired: false, isOnline: false);
      }
    }
    return success;
  }

  Future<ChildModel?> updateChild(
    String childId, {
    String? name,
    int? age,
    String? gender,
    String? phoneNumber,
    int? dailyLimitMinutes,
    String? bedtimeStart,
    String? bedtimeEnd,
  }) async {
    try {
      final res = await _api.updateChild(
        childId,
        name: name,
        age: age,
        gender: gender,
        phoneNumber: phoneNumber,
        dailyLimitMinutes: dailyLimitMinutes,
        bedtimeStart: bedtimeStart,
        bedtimeEnd: bedtimeEnd,
      );

      if (res['success'] == true && res['child'] != null) {
        final c = res['child'] as Map<String, dynamic>;
        final updatedChild = ChildModel.fromMap(c, c['_id'] ?? c['id']);
        final idx = _localChildren.indexWhere((item) => item.id == childId);
        if (idx != -1) {
          _localChildren[idx] = updatedChild;
        }
        return updatedChild;
      }
    } catch (_) {}
    return null;
  }

  Future<void> updateChildProfile(ChildModel child) async {
    final index = _localChildren.indexWhere((c) => c.id == child.id);
    if (index != -1) {
      _localChildren[index] = child;
    }
  }
}
