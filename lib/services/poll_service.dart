import '../data/mock_polls.dart';
import '../models/daily_poll.dart';

class PollService {
  static DailyPoll _todayPoll = mockDailyPoll;

  static String? _selectedOptionId;

  static DailyPoll getTodayPoll() {
    return _todayPoll;
  }

  static String? getSelectedOptionId() {
    return _selectedOptionId;
  }

  static bool hasVoted() {
    return _selectedOptionId != null;
  }

  static void vote(String optionId) {
    if (hasVoted()) {
      return;
    }

    final updatedOptions = _todayPoll.options.map((option) {
      if (option.id == optionId) {
        return option.copyWith(votes: option.votes + 1);
      }

      return option;
    }).toList();

    _todayPoll = _todayPoll.copyWith(options: updatedOptions);

    _selectedOptionId = optionId;
  }

  static void resetVoteForTesting() {
    _todayPoll = mockDailyPoll;
    _selectedOptionId = null;
  }
}
