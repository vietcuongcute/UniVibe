class DailyPollOption {
  final String id;
  final String text;
  final int votes;

  DailyPollOption({required this.id, required this.text, required this.votes});

  DailyPollOption copyWith({String? id, String? text, int? votes}) {
    return DailyPollOption(
      id: id ?? this.id,
      text: text ?? this.text,
      votes: votes ?? this.votes,
    );
  }
}

class DailyPoll {
  final String id;
  final String question;
  final List<DailyPollOption> options;
  final DateTime createdAt;

  DailyPoll({
    required this.id,
    required this.question,
    required this.options,
    required this.createdAt,
  });

  DailyPoll copyWith({
    String? id,
    String? question,
    List<DailyPollOption>? options,
    DateTime? createdAt,
  }) {
    return DailyPoll(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  int get totalVotes {
    int total = 0;

    for (final option in options) {
      total += option.votes;
    }

    return total;
  }
}
