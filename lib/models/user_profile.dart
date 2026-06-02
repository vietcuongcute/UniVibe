class UserProfile {
  final String id;
  final String nickname;
  final String avatarUrl;
  final String coverUrl;
  final String university;
  final String major;
  final int year;
  final String gender;
  final List<String> interests;
  final List<String> goals;
  final List<String> vibeTags;
  final List<String> featuredImageUrls;
  final String bio;

  UserProfile({
    required this.id,
    required this.nickname,
    this.avatarUrl = '',
    this.coverUrl = '',
    required this.university,
    required this.major,
    required this.year,
    this.gender = '',
    this.interests = const [],
    this.goals = const [],
    this.vibeTags = const [],
    this.featuredImageUrls = const [],
    this.bio = '',
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id']?.toString() ?? '',
      nickname: map['nickname']?.toString() ?? '',
      avatarUrl: map['avatarUrl']?.toString() ?? '',
      coverUrl: map['coverUrl']?.toString() ?? '',
      university: map['university']?.toString() ?? '',
      major: map['major']?.toString() ?? '',
      year: _parseYear(map['year']),
      gender: map['gender']?.toString() ?? '',
      interests: _parseStringList(map['interests']),
      goals: _parseStringList(map['goals']),
      vibeTags: _parseStringList(map['vibeTags']),
      featuredImageUrls: _parseStringList(map['featuredImageUrls']),
      bio: map['bio']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'coverUrl': coverUrl,
      'university': university,
      'major': major,
      'year': year,
      'gender': gender,
      'interests': interests,
      'goals': goals,
      'vibeTags': vibeTags,
      'featuredImageUrls': featuredImageUrls,
      'bio': bio,
    };
  }

  static int _parseYear(dynamic value) {
    if (value is int) return value;

    if (value is String) {
      return int.tryParse(value) ?? 1;
    }

    return 1;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    return [];
  }
}

class MatchResult {
  final UserProfile user;
  final int compatibilityScore;

  MatchResult({required this.user, required this.compatibilityScore});
}
