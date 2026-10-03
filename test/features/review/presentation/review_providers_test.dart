import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tether/features/habits/presentation/providers/habit_providers.dart';
import 'package:tether/features/review/presentation/providers/review_providers.dart';

void main() {
  test('ReviewProvider loads null initially when no review saved', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    
    final state = container.read(currentWeeklyReviewProvider);
    expect(state, isA<AsyncLoading>());
    
    final review = await container.read(currentWeeklyReviewProvider.future);
    expect(review, isNull);
  });

  test('CurrentWeeklyReviewNotifier saveNotes persists review and updates state', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    // Wait for initial load
    await container.read(currentWeeklyReviewProvider.future);

    // Save reflection notes
    await container.read(currentWeeklyReviewProvider.notifier).saveNotes(
      'Great focus this week!',
      7, // expected
      5, // completed
      3, // focus sessions
    );

    final updated = container.read(currentWeeklyReviewProvider).value;
    expect(updated, isNotNull);
    expect(updated!.notes, 'Great focus this week!');
    expect(updated.habitsExpected, 7);
    expect(updated.habitsCompleted, 5);
    expect(updated.focusSessions, 3);

    // Verify it was persisted to repo
    final repo = container.read(reviewRepositoryProvider);
    final weekStart = container.read(reviewWeekProvider);
    final fromRepo = await repo.getReview(weekStart);
    expect(fromRepo, isNotNull);
    expect(fromRepo!.notes, 'Great focus this week!');
  });

  test('ReviewWeekNotifier changes active week', () {
    final container = ProviderContainer();
    final initialWeek = container.read(reviewWeekProvider);
    final previousWeek = initialWeek.subtract(const Duration(days: 7));
    
    container.read(reviewWeekProvider.notifier).state = previousWeek;
    expect(container.read(reviewWeekProvider), previousWeek);
  });
}
