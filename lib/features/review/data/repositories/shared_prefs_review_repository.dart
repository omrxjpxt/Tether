import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tether/core/utils/date_utils.dart';
import 'package:tether/features/review/domain/models/weekly_review.dart';
import 'package:tether/features/review/domain/repositories/review_repository.dart';

class SharedPrefsReviewRepository implements ReviewRepository {
  final SharedPreferences _prefs;
  static const _prefix = 'weekly_review_v1_';

  SharedPrefsReviewRepository(this._prefs);

  String _getKey(DateTime date) => '$_prefix${DateUtilsLocal.todayKey(date)}';

  @override
  Future<WeeklyReview?> getReview(DateTime weekStartDate) async {
    final jsonString = _prefs.getString(_getKey(weekStartDate));
    if (jsonString == null) return null;
    try {
      return WeeklyReview.fromJson(jsonDecode(jsonString));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveReview(WeeklyReview review) async {
    await _prefs.setString(_getKey(review.weekStartDate), jsonEncode(review.toJson()));
  }
}
