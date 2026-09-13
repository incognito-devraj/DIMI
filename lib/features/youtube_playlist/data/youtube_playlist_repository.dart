import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/supabase_config.dart';
import '../models/youtube_playlist.dart';

class YouTubePlaylistException implements Exception {
  const YouTubePlaylistException(this.message);
  final String message;
  @override
  String toString() => message;
}

const _requestTimeout = Duration(seconds: 25);
const _maxAttempts = 2;

class YouTubePlaylistRepository {
  // Extracts a playlist ID from a full URL or accepts a bare playlist ID.
  static String? _extractId(String input) {
    final trimmed = input.trim();
    // Try parsing as a URL first
    final uri = Uri.tryParse(trimmed);
    if (uri != null &&
        {
          'youtube.com',
          'www.youtube.com',
          'm.youtube.com',
          'youtu.be',
        }.contains(uri.host.toLowerCase())) {
      final id = uri.queryParameters['list'];
      if (id != null && id.isNotEmpty) return id;
    }
    // Accept a bare playlist ID — YouTube playlist IDs start with PL, UU, FL,
    // RD, OL, or LL and are 13–34 chars.
    if (RegExp(r'^[A-Za-z0-9_-]{13,}$').hasMatch(trimmed) &&
        RegExp(r'^(PL|UU|FL|RD|OL|LL)').hasMatch(trimmed)) {
      return trimmed;
    }
    return null;
  }

  Future<YouTubePlaylist> fetchPlaylist(String playlistUrl) async {
    final id = _extractId(playlistUrl);
    if (id == null) throw const YouTubePlaylistException('invalid');
    final client = SupabaseBootstrap.client;
    if (client == null) throw const YouTubePlaylistException('no_supabase');
    // Normalise to a canonical playlist URL so the Edge Function always
    // receives a consistent format regardless of what the user pasted.
    final canonicalUrl = 'https://www.youtube.com/playlist?list=$id';
    Object? lastError;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await client.functions
            .invoke('youtube-playlist', body: {'playlistUrl': canonicalUrl})
            .timeout(_requestTimeout);
        if (response.status != 200) {
          throw YouTubePlaylistException(_classifyStatus(response.status));
        }
        if (response.data is! Map) {
          throw const YouTubePlaylistException('invalid_response');
        }
        final playlist = YouTubePlaylist.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
        if (playlist.playlistId != id ||
            playlist.title.isEmpty ||
            playlist.videos.any(
              (video) => video.videoId.isEmpty || video.title.isEmpty,
            )) {
          throw const YouTubePlaylistException('invalid_response');
        }
        return playlist;
      } on YouTubePlaylistException catch (error) {
        if (!_isTransient(error.message) || attempt == _maxAttempts) {
          rethrow;
        }
        lastError = error;
      } on FunctionException catch (error) {
        final classified = _classifyStatus(error.status);
        if (!_isTransient(classified) || attempt == _maxAttempts) {
          throw YouTubePlaylistException(classified);
        }
        lastError = error;
      } on TimeoutException catch (error) {
        if (attempt == _maxAttempts) {
          throw const YouTubePlaylistException('timeout');
        }
        lastError = error;
      } on SocketException catch (error) {
        if (attempt == _maxAttempts) {
          throw const YouTubePlaylistException('network');
        }
        lastError = error;
      } on FormatException {
        throw const YouTubePlaylistException('invalid_response');
      } catch (error) {
        if (attempt == _maxAttempts) {
          throw const YouTubePlaylistException('network');
        }
        lastError = error;
      }
      await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
    }
    throw YouTubePlaylistException(
      lastError is TimeoutException ? 'timeout' : 'network',
    );
  }

  static String _classifyStatus(int? status) {
    if (status == null) return 'network';
    return switch (status) {
      400 || 401 || 403 || 404 || 422 => 'unavailable',
      408 || 429 || >= 500 => 'network',
      _ => 'unavailable',
    };
  }

  static bool _isTransient(String value) => value == 'network';
}
