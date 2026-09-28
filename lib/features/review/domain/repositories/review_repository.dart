import 'package:tether/features/review/domain/models/weekly_review.dart';

abstract class ReviewRepository {
  Future<WeeklyReview?> getReview(DateTime weekStartDate);
  Future<void> saveReview(WeeklyReview review);
}
