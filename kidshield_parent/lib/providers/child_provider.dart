import 'package:flutter/material.dart';
import '../models/child_model.dart';
import '../models/restriction_model.dart';
import '../services/child_service.dart';

class ChildProvider extends ChangeNotifier {
  final ChildService _childService = ChildService();

  List<ChildModel> _children = [];
  ChildModel? _selectedChild;
  bool _isLoading = false;
  String? _errorMessage;

  List<ChildModel> get children => _children;
  ChildModel? get selectedChild => _selectedChild;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ChildProvider();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void selectChild(ChildModel child) {
    _selectedChild = child;
    notifyListeners();
  }

  void selectChildById(String id) {
    try {
      _selectedChild = _children.firstWhere((c) => c.id == id);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadChildren(String parentId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final fetched = await _childService.getChildren(parentId);
      final Map<String, ChildModel> uniqueMap = {};
      for (final c in fetched) {
        final key = c.id.isNotEmpty ? c.id : c.pairingCode;
        if (!uniqueMap.containsKey(key)) {
          uniqueMap[key] = c;
        }
      }
      _children = uniqueMap.values.toList();
      if (_children.isNotEmpty) {
        if (_selectedChild == null || !_children.any((c) => c.id == _selectedChild!.id)) {
          _selectedChild = _children.first;
        } else {
          _selectedChild = _children.firstWhere((c) => c.id == _selectedChild!.id);
        }
      } else {
        _selectedChild = null;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<ChildModel?> addChild({
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
    _setLoading(true);
    try {
      final newChild = await _childService.addChild(
        parentId: parentId,
        name: name,
        age: age,
        gender: gender,
        photoUrl: photoUrl,
        phoneNumber: phoneNumber,
        dailyLimitMinutes: dailyLimitMinutes,
        bedtimeStart: bedtimeStart,
        bedtimeEnd: bedtimeEnd,
      );
      final existingIndex = _children.indexWhere((c) =>
          (c.id.isNotEmpty && c.id == newChild.id) ||
          (c.pairingCode.isNotEmpty && c.pairingCode == newChild.pairingCode));
      if (existingIndex != -1) {
        _children[existingIndex] = newChild;
      } else {
        _children.add(newChild);
      }
      _selectedChild = newChild;
      _setLoading(false);
      return newChild;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return null;
    }
  }

  Future<bool> updateChild(
    String childId, {
    String? name,
    int? age,
    String? gender,
    String? phoneNumber,
    int? dailyLimitMinutes,
    String? bedtimeStart,
    String? bedtimeEnd,
  }) async {
    _setLoading(true);
    try {
      final updated = await _childService.updateChild(
        childId,
        name: name,
        age: age,
        gender: gender,
        phoneNumber: phoneNumber,
        dailyLimitMinutes: dailyLimitMinutes,
        bedtimeStart: bedtimeStart,
        bedtimeEnd: bedtimeEnd,
      );

      if (updated != null) {
        final index = _children.indexWhere((c) => c.id == childId);
        if (index != -1) {
          _children[index] = updated;
        }
        if (_selectedChild?.id == childId) {
          _selectedChild = updated;
        }
        notifyListeners();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<void> removeChild(String childId) async {
    _setLoading(true);
    try {
      await _childService.removeChild(childId);
      _children.removeWhere((c) => c.id == childId);
      if (_selectedChild?.id == childId) {
        _selectedChild = _children.isNotEmpty ? _children.first : null;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateRestrictions(RestrictionModel restrictions) async {
    if (_selectedChild == null) return;
    _setLoading(true);
    try {
      await _childService.updateChildRestrictions(
        childId: _selectedChild!.id,
        restrictions: restrictions,
      );
      _selectedChild = _selectedChild!.copyWith(
        dailyScreenTimeLimitMinutes: restrictions.dailyScreenTimeMinutes,
        bedtimeStart: restrictions.bedtimeStart,
        bedtimeEnd: restrictions.bedtimeEnd,
        studyTimeStart: restrictions.studyTimeStart,
        studyTimeEnd: restrictions.studyTimeEnd,
      );
      final index = _children.indexWhere((c) => c.id == _selectedChild!.id);
      if (index != -1) {
        _children[index] = _selectedChild!;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> regeneratePairingCode(String childId) async {
    _setLoading(true);
    try {
      final res = await _childService.regeneratePairingCode(childId);
      if (res != null) {
        final index = _children.indexWhere((c) => c.id == childId);
        if (index != -1) {
          _children[index] = _children[index].copyWith(pairingCode: res);
          if (_selectedChild?.id == childId) {
            _selectedChild = _children[index];
          }
        }
        notifyListeners();
        return res;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
    return null;
  }

  Future<bool> unpairDevice(String childId) async {
    _setLoading(true);
    try {
      final success = await _childService.unpairDevice(childId);
      if (success) {
        final index = _children.indexWhere((c) => c.id == childId);
        if (index != -1) {
          _children[index] = _children[index].copyWith(isPaired: false, isOnline: false);
          if (_selectedChild?.id == childId) {
            _selectedChild = _children[index];
          }
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
    return false;
  }
}


