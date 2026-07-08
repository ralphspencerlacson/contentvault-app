part of '../main.dart';

class MuxClient {
  MuxClient(this.tokenId, this.tokenSecret);

  final String tokenId;
  final String tokenSecret;

  static const _apiBase = 'https://api.mux.com/video/v1';

  Map<String, String> get _headers => {
    'Authorization':
        'Basic ${base64Encode(utf8.encode('$tokenId:$tokenSecret'))}',
    'Content-Type': 'application/json',
  };

  Future<MuxDirectUpload> createDirectUpload({required String title}) async {
    final safeTitle = title.trim().replaceAll(RegExp(r'[^A-Za-z0-9 ._-]'), ' ');
    final muxTitle = safeTitle.isEmpty
        ? 'Untitled video'
        : safeTitle.length <= 120
        ? safeTitle
        : safeTitle.substring(0, 120);
    final response = await http.post(
      Uri.parse('$_apiBase/uploads'),
      headers: _headers,
      body: jsonEncode({
        'cors_origin': 'https://content-vault.local',
        'new_asset_settings': {
          'playback_policy': ['public'],
          'passthrough': muxTitle,
          'meta': {'title': muxTitle},
        },
      }),
    );

    final data = _decodeResponse(response);
    final upload = data['data'] as Map<String, dynamic>;
    return MuxDirectUpload(
      id: upload['id'] as String,
      url: Uri.parse(upload['url'] as String),
    );
  }

  Future<void> uploadVideo(
    Uri url,
    Uint8List bytes, {
    required ValueChanged<UploadProgress> onProgress,
  }) async {
    final request = http.StreamedRequest('PUT', url)
      ..headers['Content-Type'] = 'video/mp4'
      ..contentLength = bytes.length;

    final responseFuture = request.send();

    const chunkSize = 1024 * 1024;
    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = (offset + chunkSize).clamp(0, bytes.length);
      request.sink.add(bytes.sublist(offset, end));
      onProgress(UploadProgress(sentBytes: end, totalBytes: bytes.length));
      await Future<void>.delayed(Duration.zero);
    }
    await request.sink.close();

    final response = await responseFuture;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Mux upload returned HTTP ${response.statusCode}.');
    }
  }

  Future<String> waitForPlaybackId(String uploadId) async {
    for (var attempt = 0; attempt < 30; attempt++) {
      final upload = await _get('$_apiBase/uploads/$uploadId');
      final assetId = upload['data']?['asset_id'] as String?;

      if (assetId != null) {
        final asset = await _get('$_apiBase/assets/$assetId');
        final playbackIds = asset['data']?['playback_ids'] as List<dynamic>?;
        if (playbackIds != null && playbackIds.isNotEmpty) {
          return playbackIds.first['id'] as String;
        }
      }

      await Future<void>.delayed(const Duration(seconds: 5));
    }

    throw Exception('Timed out waiting for Mux playback ID.');
  }

  Future<Map<String, dynamic>> _get(String url) async {
    return _decodeResponse(await http.get(Uri.parse(url), headers: _headers));
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decodedBody = response.body.isEmpty
        ? null
        : jsonDecode(response.body);
    final body = decodedBody is Map<String, dynamic>
        ? decodedBody
        : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          body['error']?['message'] ??
          body['message'] ??
          (response.body.isEmpty ? null : response.body) ??
          response.reasonPhrase ??
          'Request failed';
      throw Exception('Mux HTTP ${response.statusCode}: $message');
    }
    return body;
  }
}

class MuxDirectUpload {
  const MuxDirectUpload({required this.id, required this.url});

  final String id;
  final Uri url;
}

class UploadProgress {
  const UploadProgress({required this.sentBytes, required this.totalBytes});

  final int sentBytes;
  final int totalBytes;

  double? get fraction => totalBytes == 0 ? null : sentBytes / totalBytes;

  String get label {
    if (totalBytes == 0) return 'Preparing upload...';
    final percent = ((sentBytes / totalBytes) * 100).toStringAsFixed(0);
    return '$percent% uploaded';
  }
}
