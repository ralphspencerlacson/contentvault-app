part of '../main.dart';

const targetUploadAspectRatio = 16 / 9;
const minUploadAspectRatio = 1.70;
const maxUploadAspectRatio = 1.85;

String formatUploadLabel({
  required String username,
  required String title,
  required String filename,
  required DateTime uploadedAt,
}) {
  final timestamp = uploadedAt.toIso8601String().replaceAll(
    RegExp(r'[:.]'),
    '-',
  );
  final safeUsername = _safeUploadLabelValue(username, maxLength: 32);
  final safeTitle = _safeUploadLabelValue(title, maxLength: 72);
  final safeFilename = _safeUploadLabelValue(filename, maxLength: 72);
  return 'creator=$safeUsername|title=$safeTitle|timestamp=$timestamp|filename=$safeFilename';
}

String _safeUploadLabelValue(String value, {required int maxLength}) {
  final safeValue = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  if (safeValue.length <= maxLength) return safeValue;
  return safeValue.substring(0, maxLength);
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  return '${(mb / 1024).toStringAsFixed(1)} GB';
}

bool isSupportedUploadAspectRatio(double aspectRatio) {
  return aspectRatio >= minUploadAspectRatio &&
      aspectRatio <= maxUploadAspectRatio;
}

String formatAspectRatio(double aspectRatio) {
  if (aspectRatio <= 0) return 'unknown';
  if (aspectRatio < 1) return '9:16';
  return aspectRatio.toStringAsFixed(2);
}
