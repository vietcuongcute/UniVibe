# UniVibe Roadmap

## App concept

UniVibe là app nội bộ cho sinh viên cùng trường, giúp tìm người hợp vibe, gửi Signal, Mutual Signal thì mở Chat, Confession nội bộ trường, UniMoment kiểu Locket/Story 24h, Market mua bán đồ cũ/tài liệu/phòng trọ, CLB/Sự kiện và Admin kiểm duyệt.

## Bottom navigation

Vibe | Confession | UniMoment | Market | Chat

## Tech stack

- Flutter
- Dart
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Firebase Messaging later
- Dev bằng Chrome trước
- Build Android APK/AAB
- iOS TestFlight sau

## Main modules

1. Auth + Profile
2. Main Navigation
3. Chat
4. Vibe + Signal + Match
5. Blind Chat
6. Confession
7. UniMoment
8. Market
9. Club/Event
10. Admin + Report + Role
11. Notification
12. Build APK/TestFlight

## Firestore collections

- users
- signals
- matches
- chatRooms
- messages
- confessions
- comments
- moments
- marketPosts
- clubs
- clubPosts
- events
- reports
- notifications
- badges
- dailyQuestions

## Roles

- student
- moderator
- clubLeader
- eventManager
- admin

## Feature details

### Vibe

- Tạo profile sinh viên
- Chọn vibe cá nhân
- Chọn mục đích: học chung, chơi game, tìm người yêu, cafe, roommate
- Daily Match
- Gửi Signal
- Mutual Signal thì tạo ChatRoom
- Blind Chat bóc túi mù

### Confession

- Đăng confession ẩn danh hoặc hiện danh
- Category: confession, hỏi đáp, tìm đồ, teammate, học tập, CLB tuyển người, cảnh báo
- Like/comment/report
- Moderator/Admin có thể ẩn bài vi phạm

### UniMoment

- Đăng ảnh/story 24h
- Reaction nhanh
- Moment theo khoa/CLB/sự kiện
- Check-in hoặc album sự kiện sau này

### Market

- Đăng đồ cũ/tài liệu/đồng phục/đồ phòng trọ/vé sự kiện
- Tìm phòng trọ/tìm bạn ở ghép
- Chat với người bán
- Đánh dấu đã bán
- Report bài bán

### Chat

- Chat 1-1 realtime
- Chat từ mutual signal
- Chat từ blind chat
- Chat từ market
- Sau này có chat nhóm/CLB

### Admin

- Xem report
- Ẩn bài vi phạm
- Khóa user
- Gán role
- Quản lý user, confession, moment, market, club, event
