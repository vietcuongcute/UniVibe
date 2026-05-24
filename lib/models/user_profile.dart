class UserProfile {
  final String id;
  final String nickname;
  final String avatarUrl;
  final String university;
  final String major;
  final int year;
  final String gender;
  final List<String> interests;
  final List<String> goals;
  final List<String> vibeTags;
  final String bio;

  UserProfile({
    required this.id,
    required this.nickname,
    required this.avatarUrl,
    required this.university,
    required this.major,
    required this.year,
    required this.gender,
    required this.interests,
    required this.goals,
    required this.vibeTags,
    required this.bio,
  });
}

class MatchResult {
  final UserProfile user;
  final int compatibilityScore;

  MatchResult({required this.user, required this.compatibilityScore});
}
