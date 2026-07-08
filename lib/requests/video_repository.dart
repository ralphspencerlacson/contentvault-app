part of '../main.dart';

String creatorIdForUsername(String username) {
  if (username == 'creator1') return '1';
  if (username == 'creator2') return '2';
  return '0';
}

class VideoRepository {
  VideoRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _videos =>
      _firestore.collection('videos');

  Future<List<UploadedVideo>> fetchVideos() async {
    final snapshot = await _videos.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => UploadedVideo.fromFirestore(doc.data()))
        .where((video) => video.playbackId.isNotEmpty)
        .toList();
  }

  Future<void> saveVideo(UploadedVideo video) async {
    await _videos.doc(video.playbackId).set(video.toFirestore());
  }
}

final videoRepository = VideoRepository(FirebaseFirestore.instance);

Future<void> loadPersistedVideos() async {
  try {
    final videos = await videoRepository.fetchVideos();
    uploadedVideos
      ..clear()
      ..addAll(videos);
  } on FirebaseException {
    // Firestore can be unavailable during local setup; keep mock/in-memory mode.
  }
}

Future<void> savePersistedVideo(UploadedVideo video) async {
  try {
    await videoRepository.saveVideo(video);
  } on FirebaseException {
    // TODO: Persist failed Firestore writes to a retry queue when DB logging exists.
  }
}
