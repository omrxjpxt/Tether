import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tether/core/utils/date_utils.dart';
import 'package:tether/features/review/domain/models/weekly_review.dart';
import 'package:tether/features/review/domain/repositories/review_repository.dart';
import 'package:tether/features/review/data/repositories/shared_prefs_review_repository.dart';
import 'package:tether/features/habits/presentation/providers/habit_providers.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefsReviewRepository(prefs);
});

final reviewWeekProvider = NotifierProvider<ReviewWeekNotifier, DateTime>(() {
  return ReviewWeekNotifier();
});

class ReviewWeekNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    return DateUtilsLocal.startOfWeek(DateTime.now());
  }

  @override
  set state(DateTime value) {
    super.state = value;
  }
}

final currentWeeklyReviewProvider = AsyncNotifierProvider<CurrentWeeklyReviewNotifier, WeeklyReview?>(() {
  return CurrentWeeklyReviewNotifier();
});

class CurrentWeeklyReviewNotifier extends AsyncNotifier<WeeklyReview?> {
  late ReviewRepository _repository;
  late DateTime _weekStart;

  @override
  Future<WeeklyReview?> build() async {
    _repository = ref.watch(reviewRepositoryProvider);
    _weekStart = ref.watch(reviewWeekProvider);
    return await _repository.getReview(_weekStart);
  }

  Future<void> saveNotes(String notes, int habitsExpected, int habitsCompleted, int focusSessions) async {
    WeeklyReview? existing;
    if (state is AsyncData) {
      existing = state.value;
    }
    
    final review = WeeklyReview(
      weekStartDate: _weekStart,
      weekEndDate: DateUtilsLocal.endOfWeek(_weekStart),
      habitsCompleted: habitsCompleted,
      habitsExpected: habitsExpected,
      focusSessions: focusSessions,
      notes: notes,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    state = AsyncValue.data(review);
    await _repository.saveReview(review);
  }
}
