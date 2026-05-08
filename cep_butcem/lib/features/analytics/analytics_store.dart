import 'package:flutter/foundation.dart';

import '../../data/models/analytics_data.dart';
import '../../data/models/analytics_params.dart';
import '../../data/repositories/analytics_repository.dart';

class AnalyticsStore extends ChangeNotifier {
  AnalyticsStore({AnalyticsRepository? repository})
    : _repository = repository ?? AnalyticsRepository();

  final AnalyticsRepository _repository;

  bool _isLoading = false;
  String? _error;
  AnalyticsData _data = AnalyticsData.empty();

  bool get isLoading => _isLoading;
  String? get error => _error;
  AnalyticsData get data => _data;

  Future<void> load(AnalyticsParams params) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _repository.getAnalytics(params);
    } catch (e, st) {
      debugPrint('AnalyticsStore.load error: $e');
      debugPrintStack(stackTrace: st);
      _error = 'Analiz verileri yüklenemedi.';
      _data = AnalyticsData.empty();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
