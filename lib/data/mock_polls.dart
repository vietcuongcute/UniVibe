import '../models/daily_poll.dart';

DailyPoll mockDailyPoll = DailyPoll(
  id: 'poll_001',
  question: 'Hôm nay bạn muốn tìm người cùng vibe để làm gì?',
  createdAt: DateTime.now(),
  options: [
    DailyPollOption(id: 'option_1', text: 'Học bài chung', votes: 12),
    DailyPollOption(id: 'option_2', text: 'Đi ăn', votes: 18),
    DailyPollOption(id: 'option_3', text: 'Chơi game', votes: 9),
    DailyPollOption(id: 'option_4', text: 'Tìm crush', votes: 15),
  ],
);
