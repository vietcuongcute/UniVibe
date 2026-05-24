import '../models/user_profile.dart';

int calculateCompatibilityScore(
  UserProfile currentUser,
  UserProfile otherUser,
) {
  int score = 0;

  final commonGoals = _countCommonItems(currentUser.goals, otherUser.goals);

  final commonInterests = _countCommonItems(
    currentUser.interests,
    otherUser.interests,
  );

  final commonVibeTags = _countCommonItems(
    currentUser.vibeTags,
    otherUser.vibeTags,
  );

  score += commonGoals * 25;
  score += commonInterests * 10;
  score += commonVibeTags * 15;

  if (currentUser.university == otherUser.university) {
    score += 15;
  }

  if (currentUser.major == otherUser.major) {
    score += 15;
  }

  if (currentUser.year == otherUser.year) {
    score += 10;
  }

  if (score > 100) {
    score = 100;
  }

  return score;
}

int _countCommonItems(List<String> listA, List<String> listB) {
  return listA.where((item) => listB.contains(item)).length;
}

List<MatchResult> generateDailyMatches({
  required UserProfile currentUser,
  required List<UserProfile> users,
}) {
  final results = users.map((user) {
    final score = calculateCompatibilityScore(currentUser, user);

    return MatchResult(user: user, compatibilityScore: score);
  }).toList();

  results.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));

  return results;
}
