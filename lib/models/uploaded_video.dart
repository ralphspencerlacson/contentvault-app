part of '../main.dart';

class UploadedVideo {
  const UploadedVideo({
    required this.creator,
    required this.title,
    required this.description,
    required this.filename,
    required this.playbackId,
    required this.uploadedAt,
  });

  final String creator;
  final String title;
  final String description;
  final String filename;
  final String playbackId;
  final DateTime uploadedAt;

  Uri get playbackUri => Uri.parse('https://stream.mux.com/$playbackId.m3u8');

  String get thumbnailUrl =>
      'https://image.mux.com/$playbackId/thumbnail.jpg?time=1&width=240';

  String get displayTitle => title;

  String get displayDescription => description.isEmpty
      ? 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer vitae arcu vel justo facilisis volutpat. Donec feugiat, mi et pretium laoreet, nibh erat aliquet arcu, at posuere lorem neque vitae erat.'
      : description;

  String get formattedUploadDate {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final localDate = uploadedAt.toLocal();
    return '${months[localDate.month - 1]} ${localDate.day}, ${localDate.year}';
  }

  String get viewsLabel => '1.2K views';

  String get heartsLabel => '248';

  List<MockComment> get mockComments => [
    MockComment(
      author: 'Mia Santos',
      body: 'This was really clear and easy to follow.',
      replies: [
        MockReply(
          author: creator,
          body: 'Glad it helped. More like this soon.',
        ),
        MockReply(
          author: 'Lena Cruz',
          body: 'Same here, the pacing was great.',
        ),
      ],
    ),
    MockComment(
      author: 'Jay Rivera',
      body: 'Saved this one so I can watch it again later.',
      replies: [
        MockReply(author: 'Nico Reyes', body: 'The replay value is solid.'),
      ],
    ),
    MockComment(
      author: creator,
      body: 'Thanks for watching. More videos soon.',
      replies: [
        MockReply(
          author: 'Mia Santos',
          body: 'Looking forward to the next upload.',
        ),
        MockReply(author: 'Jay Rivera', body: 'Drop the next one this week.'),
        MockReply(author: 'Ava Lim', body: 'This format works really well.'),
      ],
    ),
  ];
}

class MockComment {
  const MockComment({
    required this.author,
    required this.body,
    this.replies = const [],
  });

  final String author;
  final String body;
  final List<MockReply> replies;

  String get authorInitial => author.isEmpty ? '?' : author[0].toUpperCase();
}

class MockReply {
  const MockReply({required this.author, required this.body});

  final String author;
  final String body;

  String get authorInitial => author.isEmpty ? '?' : author[0].toUpperCase();
}
