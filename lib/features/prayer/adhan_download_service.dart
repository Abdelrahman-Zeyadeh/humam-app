import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'adhan_voices.dart';

final adhanDownloadServiceProvider = Provider<AdhanDownloadService>((ref) {
  return AdhanDownloadService.instance;
});

final adhanDownloadedVoicesProvider = NotifierProvider<AdhanDownloadedNotifier, Set<String>>(
  AdhanDownloadedNotifier.new,
);

class AdhanDownloadedNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    refresh();
    return {};
  }

  Future<void> refresh() async {
    final downloaded = <String>{};
    for (final voice in kAdhanVoices) {
      if (voice.assetPath != null) {
        downloaded.add(voice.id);
        continue;
      }
      final file = await AdhanDownloadService.instance.getLocalFile(voice.id);
      if (file != null && await file.exists() && await file.length() > 1000) {
        downloaded.add(voice.id);
      }
    }
    state = downloaded;
  }
}

class AdhanDownloadService {
  AdhanDownloadService._();
  static final AdhanDownloadService instance = AdhanDownloadService._();

  final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 30)));
  final ValueNotifier<Map<String, double>> downloadProgress = ValueNotifier({});

  Future<Directory> _getAdhanDir() async {
    final docDir = await getApplicationDocumentsDirectory();
    final adhanDir = Directory(p.join(docDir.path, 'adhan_voices'));
    if (!await adhanDir.exists()) {
      await adhanDir.create(recursive: true);
    }
    return adhanDir;
  }

  Future<File?> getLocalFile(String voiceId) async {
    try {
      final dir = await _getAdhanDir();
      return File(p.join(dir.path, '$voiceId.mp3'));
    } catch (_) {
      return null;
    }
  }

  Future<bool> isDownloaded(String voiceId) async {
    final voice = adhanVoiceById(voiceId);
    if (voice.assetPath != null) return true;
    final file = await getLocalFile(voiceId);
    return file != null && await file.exists() && await file.length() > 1000;
  }

  Future<String?> getEffectiveAudioPath(AdhanVoice voice) async {
    final file = await getLocalFile(voice.id);
    if (file != null && await file.exists() && await file.length() > 1000) {
      return file.path;
    }
    if (voice.assetPath != null) {
      return voice.assetPath;
    }
    return voice.remoteUrl;
  }

  Future<bool> downloadVoice(AdhanVoice voice, {void Function(double progress)? onProgress}) async {
    if (voice.remoteUrl == null) return false;
    final file = await getLocalFile(voice.id);
    if (file == null) return false;

    try {
      final tempFile = File('${file.path}.tmp');
      if (await tempFile.exists()) await tempFile.delete();

      await _dio.download(
        voice.remoteUrl!,
        tempFile.path,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final pRatio = received / total;
            onProgress?.call(pRatio);
            final currentMap = Map<String, double>.from(downloadProgress.value);
            currentMap[voice.id] = pRatio;
            downloadProgress.value = currentMap;
          }
        },
      );

      if (await tempFile.exists() && await tempFile.length() > 1000) {
        if (await file.exists()) await file.delete();
        await tempFile.rename(file.path);
        final currentMap = Map<String, double>.from(downloadProgress.value);
        currentMap.remove(voice.id);
        downloadProgress.value = currentMap;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Adhan download error for ${voice.id}: $e');
      final currentMap = Map<String, double>.from(downloadProgress.value);
      currentMap.remove(voice.id);
      downloadProgress.value = currentMap;
      return false;
    }
  }

  Future<void> deleteVoice(String voiceId) async {
    final file = await getLocalFile(voiceId);
    if (file != null && await file.exists()) {
      await file.delete();
    }
  }
}
