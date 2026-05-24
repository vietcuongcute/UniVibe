import '../models/user_profile.dart';
import 'user_profile_service.dart';

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

  if (_isSameText(currentUser.university, otherUser.university)) {
    score += 15;
  }

  if (_isSameText(currentUser.major, otherUser.major)) {
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

List<MatchResult> generateDailyMatches({
  required UserProfile currentUser,
  required List<UserProfile> users,
  bool hideZeroScore = false,
}) {
  final results = users
      .map((user) {
        final score = calculateCompatibilityScore(currentUser, user);

        return MatchResult(user: user, compatibilityScore: score);
      })
      .where((match) {
        if (!hideZeroScore) return true;

        return match.compatibilityScore > 0;
      })
      .toList();

  results.sort((a, b) {
    return b.compatibilityScore.compareTo(a.compatibilityScore);
  });

  return results;
}

Future<List<MatchResult>> generateDailyMatchesFromFirestore({
  bool hideZeroScore = false,
}) async {
  final currentUser = await UserProfileService.getCurrentUserProfile();

  if (currentUser == null) {
    throw Exception('Không tìm thấy profile hiện tại');
  }

  final otherUsers = await UserProfileService.getOtherUsers();

  return generateDailyMatches(
    currentUser: currentUser,
    users: otherUsers,
    hideZeroScore: hideZeroScore,
  );
}

int _countCommonItems(List<String> listA, List<String> listB) {
  final normalizedA = listA.map(_normalizeText).toSet();
  final normalizedB = listB.map(_normalizeText).toSet();

  return normalizedA.where((item) => normalizedB.contains(item)).length;
}

bool _isSameText(String a, String b) {
  return _normalizeText(a) == _normalizeText(b);
}

String _normalizeText(String value) {
  return value.trim().toLowerCase();
}
